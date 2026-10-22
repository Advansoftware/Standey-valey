import 'package:flutter/material.dart';

import '../ai_service.dart';
import '../app_scope.dart';
import '../app_theme.dart';
import '../search.dart';
import '../widgets/common.dart';

class _Msg {
  final bool user;
  String text;
  List<Hit> sources;
  bool busy;
  _Msg({required this.user, this.text = '', this.sources = const [], this.busy = false});
}

/// Assistente: busca (RAG) no conteúdo do app e, se o modelo estiver instalado,
/// gera a resposta com a IA local. Sem modelo, mostra os trechos encontrados.
class AssistantScreen extends StatefulWidget {
  final String? initialQuestion;
  const AssistantScreen({super.key, this.initialQuestion});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _msgs = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _url = TextEditingController();
  bool _started = false;
  bool _asking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    scope.search.loadWiki();
    _url.text = scope.store.aiModelUrl.isNotEmpty ? scope.store.aiModelUrl : defaultModelUrl;
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask(q));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _url.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  String _fallback(List<Hit> hits) {
    final search = AppScope.of(context).search;
    if (hits.isEmpty) return 'Não encontrei isso no guia. Tente outras palavras.';
    final b = StringBuffer('Encontrei isto no guia:\n');
    for (final h in hits.take(3)) {
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
    final hits = scope.search.search(q, limit: 6);
    final answer = _Msg(user: false, sources: hits, busy: true);
    setState(() {
      _asking = true;
      _msgs
        ..add(_Msg(user: true, text: q))
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
        answer.text = '${_fallback(hits)}\n\n(A IA local falhou: $e)';
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

  Future<void> _install() async {
    final scope = AppScope.of(context);
    final url = _url.text.trim().isEmpty ? defaultModelUrl : _url.text.trim();
    scope.store.setAiUrl(url);
    final ok = await scope.ai.install(url);
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
                    if (!installed) _InstallCard(url: _url, onInstall: _install),
                    if (_msgs.isEmpty) _Suggestions(onTap: _ask),
                    for (final m in _msgs) _Bubble(msg: m),
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

class _InstallCard extends StatelessWidget {
  final TextEditingController url;
  final VoidCallback onInstall;
  const _InstallCard({required this.url, required this.onInstall});

  @override
  Widget build(BuildContext context) {
    final ai = AppScope.of(context).ai;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: parchment(context, accent: const Color(0xFF8E24AA)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠 IA no seu celular', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Sem o modelo, o assistente mostra os trechos mais parecidos com a sua pergunta. '
            'Para respostas escritas pela IA, baixe o modelo uma vez (cerca de 350 MB, use Wi-Fi). '
            'Depois disso tudo roda offline.',
          ),
          if (!ai.engineReady && ai.engineError != null) ...[
            const SizedBox(height: 6),
            Text('Este aparelho não suporta o motor de IA: ${ai.engineError}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 10),
          TextField(controller: url, maxLines: 2, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(labelText: 'Endereço do modelo (.litertlm)')),
          const SizedBox(height: 10),
          if (ai.downloading) ...[
            LinearProgressIndicator(value: ai.progress > 0 ? ai.progress.clamp(0.0, 1.0) : null),
            const SizedBox(height: 4),
            Text('Baixando… ${(ai.progress * 100).toStringAsFixed(0)}%'),
          ] else
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('Baixar modelo'),
              onPressed: ai.engineReady ? onInstall : null,
            ),
          if (ai.installError != null) ...[
            const SizedBox(height: 6),
            Text('Erro: ${ai.installError}', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final void Function(String) onTap;
  const _Suggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const qs = [
      'O que devo fazer no primeiro dia?',
      'Como ganhar dinheiro no começo?',
      'Qual árvore é o carvalho?',
      'O que a Abigail ama?',
      'Onde pescar o baiacu?',
      'O que plantar na primavera?',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final q in qs) ActionChip(label: Text(q), onPressed: () => onTap(q))],
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final search = AppScope.of(context).search;
    final entries = <dynamic>[];
    final seen = <String>{};
    for (final h in msg.sources) {
      final e = search.entryOf(h.doc);
      if (e != null && seen.add(e.id)) entries.add(e);
    }
    return Align(
      alignment: msg.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: msg.user
            ? BoxDecoration(color: scheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18))
            : parchment(context, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.text.isEmpty && msg.busy) const Text('pensando…') else SelectableText(msg.text),
            if (!msg.user && !msg.busy && entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in entries.take(4))
                    ActionChip(
                      avatar: Text(e.emoji as String),
                      label: Text(e.name as String),
                      onPressed: () => openEntry(context, e),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
