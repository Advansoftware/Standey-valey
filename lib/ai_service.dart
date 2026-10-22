import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import 'ai_models.dart';
import 'search.dart';

/// Modelo padrão: Gemma 4 E4B (boa qualidade, roda bem em celulares com 8 GB+).
/// Os demais modelos ficam na lista de [aiModels] e podem ser escolhidos
/// pelo usuário na tela do Assistente.
String get defaultModelUrl => defaultAiModel.url;

/// IA local (roda no aparelho). Se qualquer parte falhar, o app continua
/// funcionando com a busca inteligente (RAG sem modelo de linguagem).
class AiService extends ChangeNotifier {
  bool engineReady = false;
  String? engineError;
  bool downloading = false;
  double progress = 0;
  String? installError;

  Future<void> init() async {
    try {
      await FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()]);
      engineReady = true;
    } catch (e) {
      engineError = '$e';
    }
    notifyListeners();
  }

  /// Baixa e instala o modelo escolhido. Retorna true se deu certo.
  ///
  /// Primeiro tenta a resolução automática do pacote no Hugging Face (o
  /// plugin escolhe a melhor variante para o aparelho: GPU, NPU ou CPU). Se a
  /// resolução falhar, cai para o download direto do arquivo.
  ///
  /// [urlOverride] permite usar um arquivo .litertlm escolhido pelo usuário.
  Future<bool> install(AiModel model, {String? urlOverride}) async {
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
    notifyListeners();

    void onProgress(dynamic p) {
      final v = double.tryParse('$p');
      if (v != null) {
        progress = v > 1 ? v / 100 : v;
        notifyListeners();
      }
    }

    try {
      if (custom.isEmpty) {
        try {
          await FlutterEdgeAi.installModel(
            modelType: model.type,
            fileType: ModelFileType.litertlm,
          ).fromHuggingFace(model.repo).withProgress(onProgress).install();
        } catch (_) {
          await FlutterEdgeAi.installModel(
            modelType: model.type,
            fileType: ModelFileType.litertlm,
          ).fromNetwork(url).withProgress(onProgress).install();
        }
      } else {
        await FlutterEdgeAi.installModel(
          modelType: model.type,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(url).withProgress(onProgress).install();
      }
      downloading = false;
      notifyListeners();
      return true;
    } catch (e) {
      downloading = false;
      installError = '$e';
      notifyListeners();
      return false;
    }
  }

  /// Diz se já existe um modelo instalado no aparelho.
  Future<bool> hasModel() async {
    try {
      final model = await FlutterEdgeAi.getActiveModel();
      await model.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gera a resposta em streaming, token a token.
  Stream<String> ask(String prompt) async* {
    final model = await FlutterEdgeAi.getActiveModel(maxTokens: 2048);
    try {
      final chat = await model.createChat();
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      await for (final r in chat.generateChatResponseAsync()) {
        if (r is TextResponse) yield r.token;
      }
    } finally {
      await model.close();
    }
  }
}

/// Monta o prompt RAG com os trechos recuperados.
String buildPrompt(String question, List<Hit> hits) {
  final b = StringBuffer();
  b.writeln('Você é o assistente de um guia do jogo Stardew Valley para iniciantes.');
  b.writeln('Responda em português do Brasil, de forma curta, clara e amigável.');
  b.writeln('Use SOMENTE as informações do contexto. Se a resposta não estiver no contexto, diga que não encontrou.');
  b.writeln();
  b.writeln('Contexto:');
  var total = 0;
  var i = 1;
  for (final h in hits) {
    var t = h.doc.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 700) t = '${t.substring(0, 700)}…';
    if (total + t.length > 3000) break;
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
  return t.trim();
}
