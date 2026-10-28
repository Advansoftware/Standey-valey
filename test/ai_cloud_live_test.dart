import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/ai_cloud.dart';
import 'package:stardew_guia/ai_rag.dart';
import 'package:stardew_guia/repository.dart';
import 'package:stardew_guia/search.dart';

/// Teste com a API de verdade. Só roda com a chave no ambiente:
/// `OPENAI_API_KEY=sk-... flutter test test/ai_cloud_live_test.dart`
/// (opcional: `OPENAI_MODEL=gpt-5.4-mini`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // o binding de teste bloqueia a rede
  final key = Platform.environment['OPENAI_API_KEY'] ?? '';

  test('OpenAI responde as perguntas reais com o RAG do app', () async {
    final models = await CloudAiClient.listModels(AiProvider.openai, key);
    expect(models, isNotEmpty);
    final model = Platform.environment['OPENAI_MODEL'] ??
        (models.map((m) => m.id).where((id) => RegExp(r'^gpt-[\d.]+-mini$').hasMatch(id)).toList()..sort()).last;
    final search = SearchService(await Repository.load());
    await search.loadWiki();
    const qs = [
      'estou tentando fazer uma fornalha no stardew valley mas não consigo o que faço para forçar acontecer?',
      'estou no festival do vale do orvalho la pedia para eu levar 9 itens bons mas o que eu faço com eles? estou aqui e não sei onde levar',
      'onde consigo argila, to travado com 5 faz tempo mesmo mineirando',
      'eu tenho um galinheiro com até 4 galinhas, quero comprar um que caiba 8 da pra demolir e comprar? demolir teria algum retorno?',
      'como colocar isca na vara',
    ];
    for (final q in qs) {
      final hits = retrieveForChat(search, q, const [], limit: 12);
      final watch = Stopwatch()..start();
      final answer = await CloudAiClient.stream(AiProvider.openai, key, model,
          system: cloudSystemPrompt,
          messages: [ChatTurn(true, buildCloudQuestion(q, buildCloudContext(search, hits)))]).join();
      // ignore: avoid_print
      print('\n### [$model ${watch.elapsedMilliseconds} ms] $q\n$answer');
      expect(answer.trim(), isNotEmpty);
    }
  }, skip: key.isEmpty ? 'sem OPENAI_API_KEY' : false, timeout: const Timeout(Duration(minutes: 5)));
}
