part of 'status_screen.dart';

// ---------------------------------------------------------------------------
// Mapa ao vivo: minimapa fixo na HUD e mapa em tela cheia. Os dois leem a
// posição do jogador da API a cada evento PlayerWarped do WebSocket.
// ---------------------------------------------------------------------------

/// Mapa do vale com os lugares numerados e o pino "VOCÊ".
class _ValleyMap extends StatelessWidget {
  final LocationInfo loc;
  final bool numbered;
  const _ValleyMap({required this.loc, this.numbered = false});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 400 / 244,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final dot = (w / 40).clamp(10.0, 22.0);
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Image.asset('assets/img/map_valley.png', fit: BoxFit.fill, filterQuality: FilterQuality.none),
            if (numbered)
              for (var i = 0; i < mapPlaces.length; i++)
                if (mapPlaces[i].x != null && mapPlaces[i].y != null)
                  Positioned(
                    left: mapPlaces[i].x! * w - dot / 2,
                    top: mapPlaces[i].y! * h - dot / 2,
                    child: Container(
                      width: dot,
                      height: dot,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mapRegionColor(mapPlaces[i].region),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text('${i + 1}',
                          style: TextStyle(color: Colors.white, fontSize: dot * 0.48, fontWeight: FontWeight.w700)),
                    ),
                  ),
            if (loc.hasPin)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                left: (loc.x! * w - 18).clamp(-6.0, w - 30),
                top: (loc.y! * h - 30).clamp(-10.0, h - 30),
                child: _YouPin(label: loc.displayName),
              ),
          ],
        );
      }),
    );
  }
}

/// Minimapa fixo da HUD. Toque para abrir em tela cheia.
class _MiniMap extends StatelessWidget {
  final LocationInfo loc;
  final VoidCallback onTap;
  const _MiniMap({required this.loc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SdvFrame(
        style: SdvFrameStyle.wood,
        px: 2,
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRect(child: _ValleyMap(loc: loc)),
            const SizedBox(height: 4),
            Row(children: [
              Text(loc.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(loc.displayName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: sdvText(12.5, color: Colors.white, shadow: true)),
              ),
              Text('⛶', style: sdvText(12, color: SdvColors.gold)),
            ]),
          ],
        ),
      ),
    );
  }
}

extension _StatusLiveMap on _StatusScreenState {
  /// Mapa em tela cheia que continua acompanhando o jogador enquanto aberto.
  void _showFullMap(BuildContext context) {
    final api = AppScope.of(context).api;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar mapa',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) {
        return ListenableBuilder(
          listenable: api,
          builder: (context, _) {
            final snap = api.snapshot;
            final loc = locationInfo(snap?.player.location ?? '');
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text('Mapa do Vale', style: sdvText(20, color: Colors.white, shadow: true)),
                        ),
                        if (api.wsConnected) const _LivePill(),
                        const SizedBox(width: 8),
                        _RoundClose(onTap: () => Navigator.of(context).pop()),
                      ]),
                      const SizedBox(height: 8),
                      Expanded(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 5,
                          child: Center(
                            child: SdvFrame(
                              style: SdvFrameStyle.wood,
                              px: 3,
                              padding: const EdgeInsets.all(10),
                              child: _ValleyMap(loc: loc, numbered: true),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SdvFrame(
                        px: 2,
                        padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
                        child: Row(children: [
                          Text(loc.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Você está em ${loc.displayName} · ${loc.region}', style: sdvText(15)),
                                Text(loc.directions, style: sdvText(12, weight: FontWeight.w500, color: SdvColors.inkSoft)),
                              ],
                            ),
                          ),
                          if (api.gameTime != null)
                            Text(gameClockLabel(api.gameTime!), style: sdvText(15, color: SdvColors.woodDark)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
