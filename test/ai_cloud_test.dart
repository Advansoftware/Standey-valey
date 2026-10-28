import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/ai_cloud.dart';

/// Servidor local que responde no formato de cada provedor.
void main() {
  late HttpServer server;
  final seen = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final path = req.uri.path;
      final body = await utf8.decodeStream(req);
      if (body.isNotEmpty) seen[path] = jsonDecode(body) as Map<String, dynamic>;
      final res = req.response;
      void json(Object o) {
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(o));
      }

      void sse(List<Object> events) {
        res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
        for (final e in events) {
          res.write('data: ${jsonEncode(e)}\n\n');
        }
      }

      if (req.headers.value('authorization') == 'Bearer ruim' || req.headers.value('x-api-key') == 'ruim') {
        res.statusCode = 401;
        json({'error': {'message': 'Incorrect API key provided'}});
      } else if (path == '/openai/models') {
        json({'data': [
          {'id': 'gpt-4o-mini'}, {'id': 'gpt-5-mini'}, {'id': 'text-embedding-3-small'},
          {'id': 'gpt-4o-realtime-preview'}, {'id': 'dall-e-3'}, {'id': 'o4-mini'},
        ]});
      } else if (path == '/openai/responses') {
        sse([
          {'type': 'response.created'},
          {'type': 'response.output_text.delta', 'delta': 'Olá, '},
          {'type': 'response.output_text.delta', 'delta': 'fazendeiro!'},
          {'type': 'response.completed'},
        ]);
      } else if (path == '/gemini/models') {
        json({'models': [
          {'name': 'models/gemini-2.5-flash', 'displayName': 'Gemini 2.5 Flash', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/text-embedding-004', 'displayName': 'Embedding', 'supportedGenerationMethods': ['embedContent']},
          {'name': 'models/gemini-2.5-flash-preview-tts', 'displayName': 'TTS', 'supportedGenerationMethods': ['generateContent']},
        ]});
      } else if (path.startsWith('/gemini/models/') && path.endsWith(':streamGenerateContent')) {
        sse([
          {'candidates': [{'content': {'parts': [{'text': 'pensando', 'thought': true}, {'text': 'Olá, '}]}}]},
          {'candidates': [{'content': {'parts': [{'text': 'fazendeiro!'}]}}]},
        ]);
      } else if (path == '/anthropic/models') {
        json({'data': [{'id': 'claude-haiku-4-5', 'display_name': 'Claude Haiku 4.5'}]});
      } else if (path == '/anthropic/messages') {
        res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
        res.write('event: message_start\ndata: {"type":"message_start"}\n\n');
        res.write('event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Olá, "}}\n\n');
        res.write('event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"type":"text_delta","text":"fazendeiro!"}}\n\n');
        res.write('event: message_stop\ndata: {"type":"message_stop"}\n\n');
      } else {
        res.statusCode = 404;
        json({'error': {'message': 'not found'}});
      }
      await res.close();
    });
    final base = 'http://127.0.0.1:${server.port}';
    CloudAiClient.openaiBase = '$base/openai';
    CloudAiClient.geminiBase = '$base/gemini';
    CloudAiClient.anthropicBase = '$base/anthropic';
  });

  tearDownAll(() => server.close(force: true));

  Future<String> ask(AiProvider p, String model) => CloudAiClient.stream(p, 'boa', model,
      system: 'sistema', messages: const [ChatTurn(true, 'oi'), ChatTurn(false, 'olá'), ChatTurn(true, 'e aí?')]).join();

  test('lista só modelos de texto', () async {
    final openai = await CloudAiClient.listModels(AiProvider.openai, 'boa');
    expect(openai.map((m) => m.id), unorderedEquals(['gpt-4o-mini', 'gpt-5-mini', 'o4-mini']));
    final gemini = await CloudAiClient.listModels(AiProvider.gemini, 'boa');
    expect(gemini.map((m) => m.id), ['gemini-2.5-flash']);
    expect(gemini.single.name, 'Gemini 2.5 Flash');
    final anthropic = await CloudAiClient.listModels(AiProvider.anthropic, 'boa');
    expect(anthropic.single.name, 'Claude Haiku 4.5');
  });

  test('o streaming junta os pedaços dos três provedores', () async {
    expect(await ask(AiProvider.openai, 'gpt-5-mini'), 'Olá, fazendeiro!');
    expect(await ask(AiProvider.gemini, 'gemini-2.5-flash'), 'Olá, fazendeiro!');
    expect(await ask(AiProvider.anthropic, 'claude-haiku-4-5'), 'Olá, fazendeiro!');
  });

  test('a conversa e a instrução de sistema vão no formato de cada API', () async {
    await ask(AiProvider.openai, 'gpt-5-mini');
    expect(seen['/openai/responses']!['instructions'], 'sistema');
    expect((seen['/openai/responses']!['input'] as List).map((m) => m['role']), ['user', 'assistant', 'user']);
    await ask(AiProvider.gemini, 'gemini-2.5-flash');
    final g = seen['/gemini/models/gemini-2.5-flash:streamGenerateContent']!;
    expect(g['systemInstruction'], isNotNull);
    expect((g['contents'] as List).map((m) => m['role']), ['user', 'model', 'user']);
    await ask(AiProvider.anthropic, 'claude-haiku-4-5');
    expect(seen['/anthropic/messages']!['system'], 'sistema');
    expect(seen['/anthropic/messages']!['max_tokens'], greaterThan(0));
  });

  test('chave errada vira mensagem clara', () async {
    await expectLater(
      CloudAiClient.listModels(AiProvider.openai, 'ruim'),
      throwsA(isA<CloudAiException>().having((e) => e.message, 'message', contains('Chave da API inválida'))),
    );
    await expectLater(
      CloudAiClient.stream(AiProvider.anthropic, 'ruim', 'x', system: '', messages: const [ChatTurn(true, 'oi')]).join(),
      throwsA(isA<CloudAiException>()),
    );
  });
}
