import 'dart:async';

import 'package:flutter/material.dart';

import 'stardew_ui.dart';

OverlayEntry? _current;

/// Aviso rápido no topo da tela, no estilo das mensagens do jogo.
///
/// Some sozinho depois de [duration] (ou ao tocar). Com [actionLabel], mostra um
/// botão que fecha o aviso e chama [onAction]. Só um aviso fica na tela por vez.
void showSdvNotice(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  _current?.remove();
  _current = null;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  void close() {
    if (_current == entry) _current = null;
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _SdvNotice(
      message: message,
      actionLabel: actionLabel,
      duration: duration,
      onClose: close,
      onAction: onAction == null
          ? null
          : () {
              close();
              onAction();
            },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _SdvNotice extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final Duration duration;
  final VoidCallback onClose;
  final VoidCallback? onAction;

  const _SdvNotice({
    required this.message,
    required this.actionLabel,
    required this.duration,
    required this.onClose,
    required this.onAction,
  });

  @override
  State<_SdvNotice> createState() => _SdvNoticeState();
}

class _SdvNoticeState extends State<_SdvNotice> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _hide);
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!mounted) return;
    await _anim.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -1.2), end: Offset.zero)
              .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: _hide,
                onVerticalDragEnd: (_) => _hide(),
                child: SdvFrame(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(widget.message, style: sdvText(14, height: 1.3)),
                      ),
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 10),
                        SdvButton(label: widget.actionLabel!, size: 13, onTap: widget.onAction),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
