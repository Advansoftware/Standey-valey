import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai_rag.dart';
import '../ai_service.dart';
import '../app_scope.dart';
import '../game_api.dart';
import '../game_status.dart';
import '../map_data.dart';
import '../models.dart';
import '../search.dart';
import '../game_events.dart';
import '../widgets/common.dart';
import '../widgets/markdown_lite.dart';
import '../widgets/stardew_ui.dart';

part 'status_widgets.dart';
part 'status_tiles.dart';
part 'status_dialogs.dart';
part 'status_hud.dart';
part 'status_live_map.dart';
part 'status_menu.dart';
part 'status_entity_dialogs.dart';
part 'status_ai_explain.dart';

const _ink = Color(0xFF3A2414);
const _paper2 = Color(0xFFF0DDAF);
const _wood = Color(0xFF4A2B16);
const _woodDark = Color(0xFF1D120B);
const _gold = Color(0xFFE6B34A);
const _goldSoft = Color(0xFFF3D58B);
const _green = Color(0xFF3F7A2A);
const _blue = Color(0xFF3F7FBF);
const _red = Color(0xFFB5483D);

/// Abre a tela master em modo imersivo, cobrindo o app e as barras do sistema.
Future<void> openStatusScreen(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      opaque: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const StatusScreen(),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with WidgetsBindingObserver {
  static const _display = MethodChannel('guia_do_vale/display');

  final _entryCache = <String, Entry>{};
  String _aiText = '';
  String? _aiError;

  /// Explicações do Meu Status já pedidas à IA (ver status_ai_explain.dart).
  final _explanations = <String, Future<String>>{};
  Future<void> _localQueue = Future.value();
  bool _aiBusy = false;
  bool _askedSync = false;
  Timer? _liveTimer;
  _Tab _tab = _Tab.advisor;
  int _quest = 0;

  void _selectTab(_Tab t) => setState(() => _tab = t);
  void _selectQuest(int i) => setState(() => _quest = i);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _immersive(true);
    _keepScreenOn(true);
    _startLiveSync();
  }

  /// Com o WebSocket ativo os eventos do jogo já atualizam tudo; o timer só
  /// faz o polling de reserva e apaga as mensagens antigas da HUD.
  void _startLiveSync() {
    _liveTimer?.cancel();
    var ticks = 0;
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      final api = AppScope.of(context).api;
      ticks++;
      if (api.connected && (!api.wsConnected || ticks % 10 == 0)) {
        api.sync(silent: true);
      }
      if (api.hud.isNotEmpty) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (_entryCache.isEmpty) {
      for (final e in scope.repo.all) {
        for (final raw in [e.en, e.name]) {
          final k = normalize(raw.trim());
          if (k.isNotEmpty) _entryCache.putIfAbsent(k, () => e);
        }
      }
    }
    if (scope.api.connected && scope.api.snapshot == null && !_askedSync) {
      _askedSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scope.api.sync(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _immersive(false);
    _keepScreenOn(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _immersive(true);
      _keepScreenOn(true);
    }
  }

  /// Só é chamada pelo botão AJUDA. Nada de IA automática nesta tela.
  Future<void> _askAi() async {
    if (_aiBusy) return;
    final scope = AppScope.of(context);
    final snap = scope.api.snapshot;
    if (snap == null) return;
    if (!scope.ai.available(scope.store)) {
      _showAiUnavailable();
      return;
    }

    final loc = locationInfo(snap.player.location);
    final next = recommendedNextStep(snap, scope.repo);
    final tips = buildStatusTips(snap, scope.repo);
    final prompt = buildStatusPrompt(
      snap: snap,
      location: loc,
      next: next,
      tips: tips,
      repo: scope.repo,
    );

    setState(() {
      _aiBusy = true;
      _aiError = null;
      _aiText = '';
    });

    try {
      final buf = StringBuffer();
      await for (final token in scope.ai.complete(scope.store, prompt)) {
        buf.write(token);
      }
      if (!mounted) return;
      final answer = cleanAnswer(buf.toString()).trim();
      // O AJUDA só libera o plano com as explicações prontas: ao tocar num
      // passo, o modal já abre com o texto completo.
      _explanations.clear();
      await _preloadExplanations(parseAiObjectives(answer), next);
      if (!mounted) return;
      setState(() {
        _aiText = answer;
        if (parseAiObjectives(answer).isEmpty) {
          _aiError =
              'O conselheiro não devolveu um plano desta vez. Tente de novo.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _aiError =
            'O conselheiro não respondeu. Tente de novo em instantes.',
      );
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  void _showAiUnavailable() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Material(
                color: Colors.transparent,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: _ink,
                    decoration: TextDecoration.none,
                  ),
                  child: _GamePanel(
                    accent: _gold,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PanelLabel(
                          'CONSELHEIRO DO VALE',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A IA local ainda não está pronta neste aparelho.',
                          style: TextStyle(
                            fontFamily: 'PixelifySans',
                            fontSize: 18,
                            height: 1.1,
                            color: _ink,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Abra o Assistente, configure a IA (no celular ou web) e volte para pedir um plano feito para o seu save. '
                          'Sem IA, o plano do guia acima continua valendo.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Color(0xFF4E3926),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _ink,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('ENTENDI'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _immersive(bool on) {
    if (on) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  Future<void> _keepScreenOn(bool on) async {
    try {
      await _display.invokeMethod<void>('keepScreenOn', {'on': on});
    } catch (_) {
      // Em testes e em plataformas sem o canal nativo, só ignora.
    }
  }

  void _close() => Navigator.of(context).maybePop();

  Entry? _entryFor(ApiItem item) {
    final key = normalize(
      (item.displayName.isNotEmpty ? item.displayName : item.name).trim(),
    );
    return _entryCache[key];
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ListenableBuilder(
          listenable: Listenable.merge([scope.api, scope.store, scope.ai]),
          builder: (context, _) {
            final snap = scope.api.snapshot;
            final live = scope.api.connected && snap != null;
            return Stack(
              fit: StackFit.expand,
              children: [
                _Backdrop(snap: snap),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                    child: live
                        ? _buildGame(scope, snap, scope.api)
                        : _NoSnapshot(api: scope.api, onClose: _close),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
