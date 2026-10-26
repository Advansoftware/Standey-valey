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

    int lastTick = 0;
    void onProgress(dynamic p) {
      final v = double.tryParse('$p');
      if (v != null) {
        progress = v > 1 ? v / 100 : v;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastTick > 250 || progress >= 1.0) {
          lastTick = now;
          notifyListeners();
        }
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
      final chat = await model.createChat(
        maxOutputTokens: 220,
        temperature: 0.2,
        topP: 0.85,
        topK: 40,
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
String buildPrompt(String question, List<Hit> hits, {bool isFineTuned = false}) {
  if (isFineTuned) return question.trim();

  final b = StringBuffer();
  b.writeln('Você é o assistente do Guia do Vale, um guia de Stardew Valley em português do Brasil para iniciantes.');
  b.writeln('Responda em português do Brasil, de forma curta (até 6 frases), clara e amigável.');
  b.writeln('Use SOMENTE as informações do contexto abaixo. Não invente preços, nomes ou mecânicas.');
  b.writeln('Quando o contexto tiver "Utilidade" ou "Preço de venda", use esses dados: diga para que serve e quanto rende.');
  b.writeln('Se a pergunta pedir uma recomendação ("devo...", "vale a pena...", "quais as vantagens..."), '
      'responda com os prós e contras que estão no contexto e termine com uma sugestão prática.');
  b.writeln('Se o contexto tiver informação relacionada, use-a para responder mesmo que não seja a resposta exata. '
      'Só diga que não encontrou se realmente não houver nada útil.');
  b.writeln('Formate com parágrafos curtos e listas com hífen quando ajudar; use **negrito** para nomes e valores. '
      'Não use tabelas, HTML nem blocos de código.');
  b.writeln();
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
