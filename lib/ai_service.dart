import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import 'ai_cloud.dart';
import 'ai_models.dart';
import 'ai_rag.dart';
import 'search.dart';
import 'store.dart';

/// IA do assistente. Responde com um modelo local (roda no aparelho) ou com
/// um provedor web (OpenAI, Gemini, Anthropic). Se qualquer parte falhar, o
/// app continua funcionando com a busca inteligente (RAG sem modelo).
class AiService extends ChangeNotifier {
  bool engineReady = false;
  String? engineError;
  bool downloading = false;
  double progress = 0;
  String? installError;

  /// Modelo local que está sendo ativado (troca de modelo), ou null.
  String? switchingId;

  /// Modelo local ativo no motor nesta execução do app.
  String? _activeId;
  Future<void>? _activation;

  /// Estado da tela de cada provedor web.
  final Map<AiProvider, bool> loadingModels = {};
  final Map<AiProvider, String?> modelsError = {};
  final Map<AiProvider, bool> testing = {};

  /// Resultado do último teste: (deu certo, mensagem).
  final Map<AiProvider, (bool, String)> testResult = {};

  Future<void> init() async {
    try {
      await FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()]);
      engineReady = true;
    } catch (e) {
      engineError = '$e';
    }
    notifyListeners();
  }

  /// Se a IA escolhida pode responder agora.
  bool available(Store store) =>
      store.aiProvider.isCloud ? store.aiConfigured : store.aiModelInstalled && engineReady;

  // ---------------- Modelos locais ----------------

  /// Baixa o modelo e o deixa ativo. Retorna true se deu certo.
  ///
  /// Instala sempre pelo endereço do arquivo: assim a instalação é idempotente
  /// e voltar para um modelo já baixado não precisa de internet (a resolução
  /// pelo repositório do Hugging Face consulta a rede toda vez).
  Future<bool> install(Store store, AiModel model, {String? urlOverride}) async {
    if (!engineReady) {
      installError = 'O motor de IA não está disponível neste aparelho.';
      notifyListeners();
      return false;
    }
    final custom = (urlOverride ?? '').trim();
    final url = custom.isEmpty ? model.url : custom;
    downloading = true;
    progress = 0;
    installError = null;
    store.setAiDownloadingId(model.id);
    notifyListeners();
    try {
      await _installFile(model, url);
      _activeId = model.id;
      store.addLocalModel(model.id, url);
      store.setAiModelId(model.id);
      return true;
    } catch (e) {
      installError = '$e';
      return false;
    } finally {
      downloading = false;
      store.setAiDownloadingId('');
      notifyListeners();
    }
  }

  Future<void> _installFile(AiModel model, String url) async {
    int lastTick = 0;
    void onProgress(dynamic p) {
      final v = double.tryParse('$p');
      if (v == null) return;
      progress = v > 1 ? v / 100 : v;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastTick > 250 || progress >= 1.0) {
        lastTick = now;
        notifyListeners();
      }
    }

    await FlutterEdgeAi.installModel(
      modelType: model.type,
      fileType: ModelFileType.litertlm,
    ).fromNetwork(url).withProgress(onProgress).install();
  }

  /// Troca o modelo local em uso por outro já baixado.
  Future<bool> useLocalModel(Store store, String id) async {
    store.setAiModelId(id);
    if (!store.aiLocalModels.containsKey(id)) return false;
    try {
      await ensureLocalActive(store);
      return true;
    } catch (e) {
      installError = 'Não consegui ativar o modelo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Garante que o motor está com o modelo escolhido no [Store]. O plugin
  /// guarda um único modelo ativo; reinstalar um arquivo já baixado só o
  /// reativa, sem baixar de novo.
  Future<void> ensureLocalActive(Store store) async {
    while (_activation != null) {
      await _activation;
    }
    final id = store.aiModelId;
    if (_activeId == id) return;
    final url = store.aiLocalModels[id];
    final model = aiModelById(id);
    if (url == null || model == null) throw StateError('Modelo não baixado.');
    switchingId = id;
    installError = null;
    notifyListeners();
    final run = _installFile(model, url);
    _activation = run;
    try {
      await run;
      _activeId = id;
    } finally {
      _activation = null;
      switchingId = null;
      notifyListeners();
    }
  }

  /// Apaga o arquivo de um modelo baixado.
  Future<void> uninstall(Store store, String id) async {
    final url = store.aiLocalModels[id];
    if (url == null) return;
    final file = Uri.tryParse(url)?.pathSegments.lastOrNull ?? '';
    try {
      await FlutterEdgeAi.uninstallModel(file);
    } catch (e) {
      debugPrint('Falha ao apagar o modelo $file: $e');
    }
    if (_activeId == id) _activeId = null;
    store.removeLocalModel(id);
  }

  // ---------------- Provedores web ----------------

  /// Busca na API do provedor os modelos que a chave pode usar.
  Future<void> fetchModels(Store store, AiProvider p) async {
    final key = store.aiKey(p);
    if (key.isEmpty) return;
    loadingModels[p] = true;
    modelsError[p] = null;
    notifyListeners();
    try {
      final models = await CloudAiClient.listModels(p, key);
      store.setAiCloudModels(p, models);
      if (models.isEmpty) {
        modelsError[p] = 'A chave não tem nenhum modelo de texto liberado.';
      } else if (!models.any((m) => m.id == store.aiCloudModel(p))) {
        store.setAiCloudModel(p, _suggested(p, models).id);
      }
    } catch (e) {
      modelsError[p] = '$e';
    } finally {
      loadingModels[p] = false;
      notifyListeners();
    }
  }

  /// Modelo sugerido quando ainda não há escolha: um rápido e barato.
  CloudModel _suggested(AiProvider p, List<CloudModel> models) {
    if (p == AiProvider.openai) {
      // O "mini" mais novo (gpt-5.4-mini antes de gpt-5-mini): rápido e barato.
      final minis = models.where((m) => RegExp(r'^gpt-[\d.]+-mini$').hasMatch(m.id)).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      if (minis.isNotEmpty) return minis.first;
    }
    final prefs = switch (p) {
      AiProvider.openai => ['gpt-4.1-mini', 'gpt-4o-mini'],
      AiProvider.gemini => ['gemini-2.5-flash', 'gemini-flash-latest', 'gemini-2.0-flash'],
      AiProvider.anthropic => ['haiku', 'sonnet'],
      AiProvider.local => const <String>[],
    };
    for (final want in prefs) {
      for (final m in models) {
        if (m.id == want || (p == AiProvider.anthropic && m.id.contains(want))) return m;
      }
    }
    return models.first;
  }

  /// Faz uma pergunta curta ao modelo escolhido para ver se ele responde.
  Future<void> testModel(Store store, AiProvider p) async {
    testing[p] = true;
    testResult.remove(p);
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      final buf = StringBuffer();
      await for (final t in CloudAiClient.stream(p, store.aiKey(p), store.aiCloudModel(p),
          system: 'Responda em português do Brasil, com no máximo 8 palavras.',
          messages: const [ChatTurn(true, 'Diga olá para um fazendeiro de Stardew Valley.')])) {
        buf.write(t);
      }
      final text = buf.toString().trim();
      final secs = (watch.elapsedMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',');
      testResult[p] = text.isEmpty
          ? (false, 'O modelo respondeu vazio. Tente outro modelo.')
          : (true, 'Funcionando ($secs s): "$text"');
    } catch (e) {
      testResult[p] = (false, '$e');
    } finally {
      testing[p] = false;
      notifyListeners();
    }
  }

  // ---------------- Respostas ----------------

  /// Resposta do chat do Assistente, com o provedor escolhido.
  Stream<String> reply(
    Store store,
    SearchService search,
    String question,
    List<Hit> hits,
    List<ChatTurn> history, {
    String? save,
  }) async* {
    final p = store.aiProvider;
    if (p.isCloud) {
      final context = buildCloudContext(search, hits);
      yield* CloudAiClient.stream(p, store.aiKey(p), store.aiCloudModel(p),
          system: cloudSystemPrompt,
          messages: [
            ...history.length > 8 ? history.sublist(history.length - 8) : history,
            ChatTurn(true, buildCloudQuestion(question, context, save: save)),
          ]);
      return;
    }
    await ensureLocalActive(store);
    final model = aiModelById(store.aiModelId) ?? defaultAiModel;
    yield* ask(buildPrompt(question, hits, isFineTuned: model.isFineTuned, save: save), exact: model.isFineTuned);
  }

  /// Resposta para um prompt pronto (Conselheiro do Meu Status).
  Stream<String> complete(Store store, String prompt) async* {
    final p = store.aiProvider;
    if (p.isCloud) {
      yield* CloudAiClient.stream(p, store.aiKey(p), store.aiCloudModel(p),
          system: 'Você é o conselheiro do Guia do Vale, de Stardew Valley. Siga exatamente o formato pedido.',
          messages: [ChatTurn(true, prompt)]);
      return;
    }
    await ensureLocalActive(store);
    yield* ask(prompt, exact: (aiModelById(store.aiModelId) ?? defaultAiModel).isFineTuned);
  }

  /// Gera a resposta em streaming, token a token.
  ///
  /// [exact]: modelo próprio (Espírito do Vale). Decodificação gulosa, igual à
  /// avaliação do treino, para repetir os fatos exatamente como aprendidos.
  Stream<String> ask(String prompt, {bool exact = false}) async* {
    final model = await FlutterEdgeAi.getActiveModel(maxTokens: 2048);
    try {
      final chat = await model.createChat(
        maxOutputTokens: exact ? 360 : 220,
        temperature: exact ? 0.0 : 0.2,
        topP: exact ? 1.0 : 0.85,
        topK: exact ? 1 : 40,
      );
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      final lines = <String>[];
      var currentLine = StringBuffer();
      final fullOutput = StringBuffer();

      await for (final r in chat.generateChatResponseAsync()) {
        if (r is TextResponse) {
          final tok = r.token;
          if (tok.contains('<|im_end|>') || tok.contains('<|endoftext|>')) {
            break;
          }
          currentLine.write(tok);
          fullOutput.write(tok);

          // 1. Detector de repetição de frase contínua (ex: 'e comprar da Marnie e comprar da Marnie')
          final full = fullOutput.toString();
          if (full.length > 50) {
            final tail = full.substring(full.length - 20);
            if (RegExp(RegExp.escape(tail)).allMatches(full).length >= 3) {
              break;
            }
          }

          if (tok.contains('\n')) {
            final lineText = currentLine.toString().trim();
            currentLine = StringBuffer();
            if (lineText.isNotEmpty) {
              final clean = lineText.replaceAll(RegExp(r'^\s*(\d+[\.\)]|\-|\*)\s*'), '').trim().toLowerCase();
              lines.add(clean);
              // 2. Proteção contra repetição de linhas semelhantes
              if (lines.length >= 3) {
                final last = lines.last;
                if (last.length > 8) {
                  final prev1 = lines[lines.length - 2];
                  final prev2 = lines[lines.length - 3];
                  if (prev1 == last || prev2 == last ||
                      (prev1.length > 15 && last.startsWith(prev1.substring(0, 15)))) {
                    break;
                  }
                }
              }
            }
          }
          yield tok;
        }
      }
    } finally {
      await model.close();
    }
  }
}

/// Monta o prompt para a IA.
///
/// - Modelo próprio ([isFineTuned], Espírito do Vale): recebe só a pergunta, sem
///   RAG. Os fatos do jogo estão nos pesos do modelo; o dataset de treino
///   (C:\modelo\v2\closed) usa exatamente este formato.
/// - Modelos generalistas (Gemma, etc.): RAG com os trechos recuperados.
String buildPrompt(String question, List<Hit> hits, {bool isFineTuned = false, String? save}) {
  if (isFineTuned) return question.trim();

  final b = StringBuffer();
  b.writeln('Você é o assistente do Guia do Vale, um guia de Stardew Valley em português do Brasil para iniciantes.');
  b.writeln('Responda em português do Brasil, de forma curta (até 6 frases), clara e amigável.');
  b.writeln('Termine quando a resposta acabar: não faça perguntas de volta nem ofereça mais ajuda.');
  b.writeln('Use SOMENTE as informações do contexto abaixo. Não invente preços, nomes ou mecânicas.');
  b.writeln('Quando o contexto tiver "Utilidade" ou "Preço de venda", use esses dados: diga para que serve e quanto rende.');
  b.writeln('Se a pergunta pedir uma recomendação ("devo...", "vale a pena...", "quais as vantagens..."), '
      'responda com os prós e contras que estão no contexto e termine com uma sugestão prática.');
  b.writeln('Se o contexto tiver informação relacionada, use-a para responder mesmo que não seja a resposta exata. '
      'Só diga que não encontrou se realmente não houver nada útil.');
  b.writeln('Formate com parágrafos curtos e listas com hífen quando ajudar; use **negrito** para nomes e valores. '
      'Não use tabelas, HTML nem blocos de código.');
  b.writeln();
  if (save != null && save.trim().isNotEmpty) {
    b.writeln('Situação atual do jogo da pessoa (use se a pergunta for sobre o jogo dela):');
    b.writeln(save.trim());
    b.writeln();
  }
  b.writeln('Contexto:');
  var total = 0;
  var i = 1;
  for (final h in hits) {
    var t = h.doc.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 900) t = '${t.substring(0, 900)}…';
    if (total + t.length > 4500) break;
    total += t.length;
    b.writeln('[$i] ${h.doc.title}: $t');
    i++;
  }
  b.writeln();
  b.writeln('Pergunta: $question');
  b.writeln('Resposta:');
  return b.toString();
}

/// Remove o raciocínio interno (`<think>...</think>`) que alguns modelos emitem.
String cleanAnswer(String s) {
  var t = s.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
  final open = t.indexOf('<think>');
  if (open >= 0) t = t.substring(0, open);
  // Tokens especiais que alguns modelos .litertlm deixam escapar.
  t = t.replaceAll(RegExp(r'<\|?/?[a-zA-Z0-9_]+\|?>'), '');
  t = t.replaceAll(RegExp(r'<end_of_turn>|<start_of_turn>|<eos>|<bos>|</s>', caseSensitive: false), '');
  t = t.replaceAll(RegExp(r'\[\/?INST\]'), '');
  // Não repete o rótulo do prompt.
  t = t.replaceFirst(RegExp(r'^\s*Resposta:\s*', caseSensitive: false), '');
  // Espaços em excesso no começo/fim de cada linha.
  return t.split('\n').map((l) => l.trimRight()).join('\n').trim();
}
