import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../map_data.dart';
import '../search.dart';
import '../widgets/common.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapRegion? _region;
  bool _beginnerOnly = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AppScope.of(context).search.loadWiki();
  }

  List<MapPlace> get _filtered => mapPlaces
      .where((p) => (_region == null || p.region == _region) && (!_beginnerOnly || p.beginner))
      .toList();

  void _showPlace(MapPlace place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('🗺️ Mapa do Vale')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const _OrientationCard(),
          const SizedBox(height: 12),
          _MapCanvas(places: places, onTap: _showPlace),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pinch_rounded, size: 15),
              const SizedBox(width: 5),
              Text('Use dois dedos para dar zoom e arraste para explorar.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: 'Tudo',
                selected: _region == null && !_beginnerOnly,
                onTap: () => setState(() {
                  _region = null;
                  _beginnerOnly = false;
                }),
              ),
              for (final r in MapRegion.values)
                _FilterChip(
                  label: mapRegionNames[r]!,
                  color: mapRegionColor(r),
                  selected: _region == r,
                  onTap: () => setState(() {
                    _region = _region == r ? null : r;
                  }),
                ),
              _FilterChip(
                label: 'Só iniciante',
                selected: _beginnerOnly,
                onTap: () => setState(() => _beginnerOnly = !_beginnerOnly),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final region in MapRegion.values)
            if (places.any((p) => p.region == region)) ...[
              SectionTitle('${mapRegionNames[region]} · ${_regionHint(region)}'),
              for (final p in places.where((p) => p.region == region))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PlaceCard(place: p, onTap: () => _showPlace(p)),
                ),
            ],
          if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Nenhum lugar com esse filtro.')),
            ),
        ],
      ),
    );
  }

  static String _regionHint(MapRegion r) => switch (r) {
        MapRegion.norte => 'para cima no mapa',
        MapRegion.centro => 'o meio do vale',
        MapRegion.sul => 'para baixo no mapa',
        MapRegion.fora => 'precisa de transporte',
      };
}

/// Explica a orientação em quatro linhas, antes do mapa.
class _OrientationCard extends StatelessWidget {
  const _OrientationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Parchment(
      accent: const Color(0xFF2E7D32),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text('Como se orientar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No mapa do jogo, o norte é sempre para cima. Use a Rosa dos Ventos no canto do mapa.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          const _Direction(icon: Icons.arrow_upward_rounded, label: 'Norte', text: 'Montanha, Minas, Ferrovia e Pedreira.'),
          const _Direction(icon: Icons.arrow_back_rounded, label: 'Oeste', text: 'Sua fazenda. A Vila Pelicanos fica a leste dela.'),
          const _Direction(icon: Icons.arrow_downward_rounded, label: 'Sul', text: 'Praia. A Floresta Cinzaseiva fica a sudoeste.'),
          const _Direction(icon: Icons.directions_bus_rounded, label: 'Fora do vale', text: 'Deserto de Calico (ônibus) e Ilha Gengibre (barco).'),
        ],
      ),
    );
  }
}

class _Direction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _Direction({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Imagem do mapa com pinos numerados e uma rosa dos ventos.
class _MapCanvas extends StatelessWidget {
  final List<MapPlace> places;
  final void Function(MapPlace) onTap;
  const _MapCanvas({required this.places, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w * 244 / 400;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF33691E), width: 2)),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/img/map_valley.png', fit: BoxFit.fill, filterQuality: FilterQuality.none),
                    for (var i = 0; i < mapPlaces.length; i++)
                      if (mapPlaces[i].x != null && mapPlaces[i].y != null && places.contains(mapPlaces[i]))
                        Positioned(
                          left: mapPlaces[i].x! * w - 15,
                          top: mapPlaces[i].y! * h - 15,
                          child: _Pin(
                            number: i + 1,
                            place: mapPlaces[i],
                            onTap: () => onTap(mapPlaces[i]),
                          ),
                        ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _Compass(dark: dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Pin extends StatelessWidget {
  final int number;
  final MapPlace place;
  final VoidCallback onTap;
  const _Pin({required this.number, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = mapRegionColor(place.region);
    return Tooltip(
      message: place.name,
      child: Material(
        color: color,
        elevation: 3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Compass extends StatelessWidget {
  final bool dark;
  const _Compass({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: (dark ? Colors.black : Colors.white).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF33691E).withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation_rounded, size: 15, color: Color(0xFFC62828)),
          SizedBox(width: 2),
          Text('N', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: (color ?? const Color(0xFF2E7D32)).withValues(alpha: 0.20),
      avatar: color == null ? null : Icon(Icons.circle, size: 10, color: color),
      onSelected: (_) => onTap(),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final MapPlace place;
  final VoidCallback onTap;
  const _PlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = mapRegionColor(place.region);
    final n = mapPlaces.indexOf(place) + 1;
    return Parchment(
      accent: color,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Text(place.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$n. ', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                    Expanded(
                      child: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                    if (place.beginner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('iniciante', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(place.tagline, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// Ficha do lugar com o essencial e atalhos para o que já existe no app.
class _PlaceSheet extends StatelessWidget {
  final MapPlace place;
  const _PlaceSheet({required this.place});

  Future<void> _openWiki(BuildContext context) async {
    final search = AppScope.of(context).search;
    if (!search.wikiLoaded) await search.loadWiki();
    if (!context.mounted) return;
    final page = _findPage(search, place.wiki);
    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa página não está na wiki offline.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WikiPageScreen(page: page)));
  }

  static WikiPage? _findPage(SearchService search, String title) {
    if (title.isEmpty) return null;
    final direct = search.pages[title];
    if (direct != null) return direct;
    final want = normalize(title).replaceAll(' ', '_');
    for (final p in search.pages.values) {
      if (normalize(p.title).replaceAll(' ', '_') == want) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = mapRegionColor(place.region);
    final scope = AppScope.of(context);
    final guide = place.guideId.isEmpty ? null : scope.repo.byId[place.guideId];
    return Container(
      decoration: parchment(context, accent: color, radius: 24),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + MediaQuery.viewPaddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(place.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      Text('${mapRegionNames[place.region]} · ${place.beginner ? "bom para iniciante" : "conteúdo mais avançado"}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Section(icon: Icons.place_rounded, title: 'O que tem', text: place.what, color: color),
            _Section(icon: Icons.route_rounded, title: 'Como chegar', text: place.how, color: color),
            _Section(icon: Icons.lightbulb_rounded, title: 'Dica', text: place.tip, color: color),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (guide != null)
                  FilledButton.icon(
                    icon: Text(guide.emoji),
                    label: Text('Abrir ${guide.name}'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      openEntry(context, guide);
                    },
                  ),
                if (place.wiki.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Página da wiki'),
                    onPressed: () => _openWiki(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A wiki offline é a fonte dos detalhes. Aqui mostramos só o essencial para você se localizar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  const _Section({required this.icon, required this.title, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
