import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// De onde vem a resposta do assistente.
enum AiProvider {
  local('local', 'No celular', 'IA baixada no aparelho, funciona offline.'),
  openai('openai', 'OpenAI', 'Modelos GPT. Precisa de chave da API (platform.openai.com).'),
  gemini('gemini', 'Google Gemini', 'Modelos Gemini. Precisa de chave da API (aistudio.google.com).'),
  anthropic('anthropic', 'Anthropic', 'Modelos Claude. Precisa de chave da API (console.anthropic.com).');

  final String id;
  final String label;
  final String note;
  const AiProvider(this.id, this.label, this.note);

  bool get isCloud => this != AiProvider.local;

  static AiProvider byId(String id) =>
      AiProvider.values.firstWhere((p) => p.id == id, orElse: () => AiProvider.local);
}

/// Um modelo listado pela API do provedor.
class CloudModel {
  final String id;
  final String name;
  const CloudModel(this.id, this.name);
}

/// Uma fala da conversa (para o provedor web lembrar do que já foi dito).
class ChatTurn {
  final bool user;
  final String text;
  const ChatTurn(this.user, this.text);
}

/// Erro da API com a mensagem já pronta para mostrar.
class CloudAiException implements Exception {
  final String message;
  CloudAiException(this.message);
  @override
  String toString() => message;
}

/// Cliente HTTP dos provedores web. Sem estado: a chave e o modelo vêm de fora.
class CloudAiClient {
  // Endereços das APIs (os testes trocam por um servidor local).
  static String openaiBase = 'https://api.openai.com/v1';
  static String geminiBase = 'https://generativelanguage.googleapis.com/v1beta';
  static String anthropicBase = 'https://api.anthropic.com/v1';

  /// Lista os modelos de texto que a chave pode usar.
  static Future<List<CloudModel>> listModels(AiProvider p, String key) async {
    switch (p) {
      case AiProvider.openai:
        final j = await _getJson(Uri.parse('$openaiBase/models'), {'Authorization': 'Bearer $key'});
        final out = [
          for (final m in (j['data'] as List? ?? const []))
            if (_openAiChat('${m['id']}')) CloudModel('${m['id']}', '${m['id']}'),
        ]..sort((a, b) => b.id.compareTo(a.id));
        return out;
      case AiProvider.gemini:
        final j = await _getJson(Uri.parse('$geminiBase/models?pageSize=1000'), {'x-goog-api-key': key});
        final out = <CloudModel>[];
        for (final m in (j['models'] as List? ?? const [])) {
          final methods = (m['supportedGenerationMethods'] as List? ?? const []).map((e) => '$e');
          final id = '${m['name']}'.replaceFirst('models/', '');
          if (!methods.contains('generateContent') || !_geminiText(id)) continue;
          out.add(CloudModel(id, '${m['displayName'] ?? id}'));
        }
        out.sort((a, b) => b.id.compareTo(a.id));
        return out;
      case AiProvider.anthropic:
        final j = await _getJson(Uri.parse('$anthropicBase/models?limit=1000'), _anthropicHeaders(key));
        return [
          for (final m in (j['data'] as List? ?? const []))
            CloudModel('${m['id']}', '${m['display_name'] ?? m['id']}'),
        ];
      case AiProvider.local:
        return const [];
    }
  }

  /// Gera a resposta em streaming, pedaço a pedaço.
  static Stream<String> stream(
    AiProvider p,
    String key,
    String model, {
    required String system,
    required List<ChatTurn> messages,
  }) async* {
    final Uri url;
    final Map<String, String> headers;
    final Map<String, Object?> body;
    switch (p) {
      case AiProvider.openai:
        url = Uri.parse('$openaiBase/responses');
        headers = {'Authorization': 'Bearer $key'};
        body = {
          'model': model,
          'instructions': system,
          'stream': true,
          'input': [
            for (final m in messages) {'role': m.user ? 'user' : 'assistant', 'content': m.text},
          ],
        };
      case AiProvider.gemini:
        url = Uri.parse('$geminiBase/models/$model:streamGenerateContent?alt=sse');
        headers = {'x-goog-api-key': key};
        // Os modelos Gemma da API do Google não aceitam instrução de sistema.
        final gemma = model.startsWith('gemma');
        body = {
          if (!gemma) 'systemInstruction': {'parts': [{'text': system}]},
          'contents': [
            for (var i = 0; i < messages.length; i++)
              {
                'role': messages[i].user ? 'user' : 'model',
                'parts': [
                  {'text': gemma && i == 0 ? '$system\n\n${messages[i].text}' : messages[i].text},
                ],
              },
          ],
        };
      case AiProvider.anthropic:
        url = Uri.parse('$anthropicBase/messages');
        headers = _anthropicHeaders(key);
        body = {
          'model': model,
          'max_tokens': 2048,
          'system': system,
          'stream': true,
          'messages': [
            for (final m in messages) {'role': m.user ? 'user' : 'assistant', 'content': m.text},
          ],
        };
      case AiProvider.local:
        throw CloudAiException('O provedor local não usa a internet.');
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(url);
      req.headers.contentType = ContentType.json;
      headers.forEach(req.headers.set);
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(const Duration(seconds: 60));
      if (res.statusCode >= 300) {
        throw CloudAiException(_errorMessage(res.statusCode, await utf8.decodeStream(res)));
      }
      final lines = res.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines.timeout(const Duration(seconds: 90))) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        final Map<String, dynamic> j;
        try {
          j = jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        final piece = _piece(p, j);
        if (piece != null && piece.isNotEmpty) yield piece;
      }
    } on SocketException {
      throw CloudAiException('Sem conexão com a internet.');
    } on TimeoutException {
      throw CloudAiException('O provedor demorou demais para responder.');
    } finally {
      client.close(force: true);
    }
  }

  /// Extrai o pedaço de texto de um evento do streaming.
  static String? _piece(AiProvider p, Map<String, dynamic> j) {
    switch (p) {
      case AiProvider.openai:
        if (j['type'] == 'response.output_text.delta') return '${j['delta']}';
        if (j['type'] == 'error' || j['type'] == 'response.failed') {
          final err = j['error'] ?? (j['response'] as Map?)?['error'];
          throw CloudAiException('${(err as Map?)?['message'] ?? 'A OpenAI recusou o pedido.'}');
        }
        return null;
      case AiProvider.gemini:
        final cands = j['candidates'] as List?;
        if (cands == null || cands.isEmpty) return null;
        final parts = ((cands.first as Map)['content'] as Map?)?['parts'] as List?;
        if (parts == null) return null;
        return [
          for (final part in parts)
            if ((part as Map)['thought'] != true && part['text'] != null) '${part['text']}',
        ].join();
      case AiProvider.anthropic:
        if (j['type'] == 'content_block_delta') {
          final d = j['delta'] as Map?;
          if (d?['type'] == 'text_delta') return '${d!['text']}';
        }
        if (j['type'] == 'error') {
          throw CloudAiException('${(j['error'] as Map?)?['message'] ?? 'A Anthropic recusou o pedido.'}');
        }
        return null;
      case AiProvider.local:
        return null;
    }
  }

  static Map<String, String> _anthropicHeaders(String key) => {
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      };

  /// Só modelos de conversa em texto (fora áudio, imagem, embeddings etc.).
  static bool _openAiChat(String id) {
    if (!RegExp(r'^(gpt-|o\d)').hasMatch(id)) return false;
    // Versões com data (gpt-5-2025-08-07) repetem o modelo sem data.
    if (RegExp(r'-\d{4}-\d{2}-\d{2}$').hasMatch(id)) return false;
    const skip = ['audio', 'realtime', 'transcribe', 'tts', 'image', 'search', 'embedding',
        'moderation', 'instruct', 'deep-research', 'computer-use', 'live', 'whisper', 'translate',
        'codex', '-16k', '0125', '1106', '0613'];
    return !skip.any(id.contains);
  }

  static bool _geminiText(String id) {
    const skip = ['embedding', 'aqa', 'imagen', 'veo', 'tts', 'image', 'native-audio', 'live',
        'robotics', 'computer-use'];
    return !skip.any(id.contains);
  }

  static Future<Map<String, dynamic>> _getJson(Uri url, Map<String, String> headers) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(url);
      headers.forEach(req.headers.set);
      final res = await req.close().timeout(const Duration(seconds: 30));
      final text = await utf8.decodeStream(res);
      if (res.statusCode >= 300) throw CloudAiException(_errorMessage(res.statusCode, text));
      return jsonDecode(text) as Map<String, dynamic>;
    } on SocketException {
      throw CloudAiException('Sem conexão com a internet.');
    } on TimeoutException {
      throw CloudAiException('O provedor demorou demais para responder.');
    } finally {
      client.close(force: true);
    }
  }

  /// Os três provedores devolvem `{"error": {"message": ...}}`.
  static String _errorMessage(int status, String body) {
    String? detail;
    try {
      final j = jsonDecode(body);
      final err = j is List ? (j.first as Map)['error'] : (j as Map)['error'];
      detail = err is Map ? '${err['message']}' : err?.toString();
    } catch (_) {}
    final prefix = switch (status) {
      400 => 'Pedido recusado',
      401 || 403 => 'Chave da API inválida ou sem permissão',
      404 => 'Modelo não encontrado',
      429 => 'Limite de uso ou créditos esgotados',
      _ => 'Erro $status do provedor',
    };
    return detail == null || detail.isEmpty ? '$prefix.' : '$prefix: $detail';
  }
}
