part of 'status_screen.dart';

// ---------------------------------------------------------------------------
// Explicação de uma dica, objetivo ou item com a IA, num modal por cima do
// Meu Status: a pessoa não sai da tela e não há conversa, só a resposta.
// A resposta chega inteira (nunca escrita na hora): os passos do Conselheiro
// já são preparados em segundo plano quando o AJUDA termina.
// ---------------------------------------------------------------------------

/// Pergunta que explica um passo: por que agora, como fazer e o que ganha.
String whyQuestion(String title, String detail) {
  final d = detail.trim();
  return 'Próximo passo no meu jogo: "$title"${d.isEmpty ? '' : ' ($d)'}. '
      'Explique curto: 1) por que isso é o próximo passo agora, olhando o meu save; '
      '2) como fazer: onde ir e o que levar; 3) o que eu ganho com isso.';
}

/// Pede a explicação à IA escolhida (wiki + save ao vivo) e devolve o texto
/// inteiro de uma vez.
Future<String> explainWithAi(AppScope scope, String question) async {
  final snap = scope.api.snapshot;
  final hits = retrieveForChat(scope.search, question, const [],
      limit: scope.store.aiProvider.isCloud ? 12 : 8);
  final buf = StringBuffer();
  await for (final tok in scope.ai.reply(scope.store, scope.search, question, hits, const [],
      save: snap == null ? null : saveSummary(snap, scope.repo, inventoryLimit: 36))) {
    buf.write(tok);
  }
  return cleanAnswer(buf.toString());
}

/// Abre o modal com a explicação. [answer] pode já estar pronta (pré-carregada)
/// ou ainda a caminho; o texto só aparece quando estiver completo.
void showAiExplainDialog(BuildContext context, {required String title, required Future<String>? answer}) {
  showStatusDetailDialog(
    context,
    title: title,
    emoji: '✨',
    content: _AiExplain(answer: answer),
  );
}

class _AiExplain extends StatelessWidget {
  final Future<String>? answer;
  const _AiExplain({required this.answer});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13.5, height: 1.35, color: _ink);
    if (answer == null) {
      return const Text(
        'Para explicar com detalhes, configure a IA no Assistente (no celular ou web). '
        'As dicas do guia continuam valendo.',
        style: style,
      );
    }
    return FutureBuilder<String>(
      future: answer,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Não consegui explicar agora: ${snap.error}', style: const TextStyle(fontSize: 12.5, color: _red));
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Row(children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
            SizedBox(width: 10),
            Expanded(child: Text('Preparando a explicação com a wiki e o seu save…', style: style)),
          ]);
        }
        final text = snap.data ?? '';
        return text.isEmpty
            ? const Text('A IA não respondeu desta vez. Tente de novo.', style: style)
            : MarkdownLite(text, style: style);
      },
    );
  }
}

/// Cache das explicações do Meu Status (uma por pergunta).
extension _StatusExplain on _StatusScreenState {
  /// Explicação da pergunta: a que já está pronta ou a caminho, ou uma nova.
  /// O modelo local roda uma de cada vez; os provedores web, em paralelo.
  Future<String>? _explanation(String question) {
    final scope = AppScope.of(context);
    if (!scope.ai.available(scope.store)) return null;
    return _explanations.putIfAbsent(question, () {
      Future<String> run() => explainWithAi(scope, question);
      final Future<String> f;
      if (scope.store.aiProvider.isCloud) {
        f = run();
      } else {
        f = _localQueue.then((_) => run());
        _localQueue = f.then((_) {}, onError: (_) {});
      }
      // Pré-carregada e nunca aberta: o erro não pode virar exceção solta.
      f.ignore();
      return f;
    });
  }

  /// Prepara em segundo plano a explicação de cada passo do plano e da missão.
  Future<void> _preloadExplanations(List<AiObjective> objectives, StatusTip next) async {
    final all = [
      for (final o in objectives) _explanation(whyQuestion(o.action, _objectiveDetail(o))),
      _explanation(whyQuestion(next.title, next.body)),
    ].whereType<Future<String>>();
    // Uma explicação que falhar não segura o plano: o modal dela mostra o erro.
    await Future.wait(all.map((f) => f.then((_) {}, onError: (_) {})));
  }

  /// Explica a dica ou o passo num modal por cima da tela.
  void _explain(String title, String detail) {
    showAiExplainDialog(context, title: title, answer: _explanation(whyQuestion(title, detail)));
  }
}

String _objectiveDetail(AiObjective o) =>
    [o.place, o.detail].whereType<String>().where((s) => s.isNotEmpty).join('. ');
