import 'package:flutter/material.dart';

import '../ai_models.dart';
import '../ai_service.dart';
import '../app_scope.dart';
import '../search.dart';
import '../widgets/assistant_bubble.dart';
import '../widgets/assistant_install_card.dart';

/// Assistente: busca (RAG) no conteúdo do app e, se o modelo estiver instalado,
/// gera a resposta com a IA local. Sem modelo, mostra os trechos encontrados.
class AssistantScreen extends StatefulWidget {
  final String? initialQuestion;
  const AssistantScreen({super.key, this.initialQuestion});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _msgs = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _started = false;
  bool _asking = false;
  String _modelId = defaultAiModel.id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    scope.search.loadWiki();
    _modelId = scope.store.aiModelId.isEmpty ? defaultAiModel.id : scope.store.aiModelId;
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask(q));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  /// Resposta sem modelo de linguagem: mostra os trechos encontrados.
  String _fallback(List<Hit> hits) {
    final search = AppScope.of(context).search;
    if (hits.isEmpty) return 'Não encontrei isso no guia. Tente outras palavras.';
    final entries = hits.where((h) => h.doc.entryId != null).take(2).toList();
    final wiki = hits.where((h) => h.doc.entryId == null).take(entries.isEmpty ? 3 : 2).toList();
    final b = StringBuffer('Encontrei isto no guia:\n');
    for (final h in [...entries, ...wiki]) {
      var t = h.doc.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (t.length > 280) t = '${t.substring(0, 280)}…';
      final name = search.entryOf(h.doc)?.name ?? (h.doc.pageTitle ?? h.doc.title);
      b.writeln('\n• $name — $t');
    }
    return b.toString();
  }

  Future<void> _ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || _asking) return;
    final scope = AppScope.of(context);
    final hits = scope.search.search(q, limit: 8);
    final answer = ChatMessage(user: false, sources: hits, busy: true);
    setState(() {
      _asking = true;
      _msgs
        ..add(ChatMessage(user: true, text: q))
        ..add(answer);
      _input.clear();
    });
    _toEnd();

    final useAi = scope.store.aiModelInstalled && scope.ai.engineReady;
    if (useAi) {
      try {
        final buf = StringBuffer();
        await for (final tok in scope.ai.ask(buildPrompt(q, hits))) {
          buf.write(tok);
          if (!mounted) return;
          setState(() => answer.text = cleanAnswer(buf.toString()));
          _toEnd();
        }
        if (answer.text.isEmpty) answer.text = _fallback(hits);
      } catch (e) {
        answer.text = '${_fallback(hits)}\n\n${_friendlyError(e)}';
      }
    } else {
      answer.text = _fallback(hits);
    }
    if (!mounted) return;
    setState(() {
      answer.busy = false;
      _asking = false;
    });
    _toEnd();
  }

  /// Traduz erros técnicos do motor de IA para uma mensagem que faz sentido.
  String _friendlyError(Object e) {
    final msg = '$e';
    if (msg.contains('arm64') || msg.contains('aarch64')) {
      return 'Este aparelho não consegue rodar o modelo de IA (o motor precisa de '
          'um celular arm64, como os de hoje). Os trechos acima são a resposta '
          'da busca inteligente do guia.';
    }
    if (msg.contains('Failed to load model') || msg.contains('load')) {
      return 'Não consegui abrir o modelo baixado. Tente baixá-lo de novo ou use '
          'outro modelo menor.';
    }
    return 'A IA local falhou: $msg';
  }

  Future<void> _install(String urlOverride) async {
    final scope = AppScope.of(context);
    final model = aiModelById(_modelId) ?? defaultAiModel;
    scope.store.setAiModelId(model.id);
    final custom = urlOverride.trim();
    if (custom.isNotEmpty) scope.store.setAiUrl(custom);
    scope.store.setAiDownloading(true);
    final ok = await scope.ai.install(model, urlOverride: custom);
    scope.store.setAiDownloading(false);
    if (ok) scope.store.setAiInstalled(true);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente')),
      body: ListenableBuilder(
        listenable: Listenable.merge([scope.store, scope.ai, scope.search]),
        builder: (context, _) {
          final installed = scope.store.aiModelInstalled;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    if (!installed)
                      AssistantInstallCard(
                        modelId: _modelId,
                        onModelChanged: (id) {
                          setState(() => _modelId = id);
                          scope.store.setAiModelId(id);
                        },
                        onInstall: _install,
                      ),
                    if (_msgs.isEmpty) AssistantSuggestions(onTap: _ask),
                    for (final m in _msgs) AssistantBubble(msg: m),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _ask,
                          decoration: InputDecoration(
                            hintText: installed ? 'Pergunte qualquer coisa do jogo…' : 'Pergunte (busca inteligente)…',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _asking ? null : () => _ask(_input.text),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
