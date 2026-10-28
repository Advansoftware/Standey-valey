import 'package:flutter/material.dart';

import '../widgets/common.dart';

import '../ai_cloud.dart';
import '../ai_rag.dart';
import '../ai_service.dart';
import '../app_scope.dart';
import '../game_status.dart';
import '../search.dart';
import '../widgets/assistant_bubble.dart';
import '../widgets/stardew_ui.dart';
import 'ai_settings_screen.dart';

/// Assistente: busca (RAG) no conteúdo do app e gera a resposta com a IA
/// escolhida (modelo local ou provedor web). Sem IA, mostra os trechos.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AppScope.of(context).search.loadWiki();
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

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AiSettingsScreen()));
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

  /// Conversa até aqui (perguntas e respostas prontas), para as continuações.
  List<ChatTurn> _history() => [
        for (final m in _msgs)
          if (!m.busy && m.text.trim().isNotEmpty) ChatTurn(m.user, m.text),
      ];

  /// Resumo do save quando o app está conectado ao jogo (Meu Status).
  String? _save(AppScope scope) {
    final snap = scope.api.snapshot;
    if (!scope.api.connected || snap == null) return null;
    return saveSummary(snap, scope.repo, inventoryLimit: 36);
  }

  Future<void> _ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || _asking) return;
    final scope = AppScope.of(context);
    final history = _history();
    final cloud = scope.store.aiProvider.isCloud;
    final hits = retrieveForChat(scope.search, q, history, limit: cloud ? 12 : 8);
    final answer = ChatMessage(user: false, sources: hits, busy: true);
    setState(() {
      _asking = true;
      _msgs
        ..add(ChatMessage(user: true, text: q))
        ..add(answer);
      _input.clear();
    });
    _toEnd();

    if (scope.ai.available(scope.store)) {
      try {
        final buf = StringBuffer();
        await for (final tok in scope.ai.reply(scope.store, scope.search, q, hits, history, save: _save(scope))) {
          buf.write(tok);
          if (!mounted) return;
          setState(() => answer.text = cleanAnswer(buf.toString()));
          _toEnd();
        }
        if (answer.text.isEmpty) answer.text = _fallback(hits);
      } catch (e) {
        answer.text = '${_fallback(hits)}\n\n${_friendlyError(e, cloud)}';
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

  /// Traduz erros técnicos da IA para uma mensagem que faz sentido.
  String _friendlyError(Object e, bool cloud) {
    final msg = '$e';
    if (cloud) return 'O provedor web falhou: $msg';
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

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente'),
        actions: [
          IconButton(tooltip: 'Configurar IA', icon: const Icon(Icons.tune_rounded), onPressed: _openSettings),
        ],
      ),
      body: ContentWidth(child: ListenableBuilder(
        listenable: Listenable.merge([scope.store, scope.ai, scope.search]),
        builder: (context, _) {
          final ready = scope.ai.available(scope.store);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
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
                            hintText: ready ? 'Pergunte qualquer coisa do jogo…' : 'Pergunte (busca inteligente)…',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SdvIconButton(
                        tooltip: 'Enviar',
                        size: 50,
                        icon: Icons.send_rounded,
                        onTap: _asking ? null : () => _ask(_input.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      )),
    );
  }
}
