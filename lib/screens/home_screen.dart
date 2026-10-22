import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'assistant_screen.dart';
import 'calendar_screen.dart';
import 'category_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repo = scope.repo;
    final guide = repo.byCat['guia'] ?? const <Entry>[];
    final theme = Theme.of(context);

    // A tela em si é estática: cada pedaço que depende do estado tem o seu
    // próprio ListenableBuilder. Assim, arrastar o slider da data reconstrói
    // só o cartão "Hoje na fazenda" — nada de remontar a home inteira.
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guia do Vale',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sua enciclopédia de Stardew Valley',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Calendário',
                    icon: const Icon(Icons.calendar_month_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CalendarScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mapa do Vale',
                    icon: const Icon(Icons.map_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MapScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sobre e ajustes',
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
                ),
                child: const IgnorePointer(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar peixe, cultura, morador, dica…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
            ),
            const _MapCard(),
            const _TodayCard(),
            const SectionTitle('📖 Comece aqui'),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: guide.length,
                itemBuilder: (context, i) => _GuideCard(entry: guide[i]),
              ),
            ),
            const _SeasonCrops(),
            const SectionTitle('🗂️ Explorar'),
            const _CategoryStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Perguntar ao assistente'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AssistantScreen(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                '${repo.all.length} fichas na enciclopédia, com o que cada item faz e quanto rende. Tudo offline.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de entrada para o mapa: miniatura do vale + atalho.
class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Parchment(
        accent: const Color(0xFF2E7D32),
        radius: 18,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const MapScreen())),
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(17),
                ),
                child: SizedBox(
                  width: 118,
                  height: 104,
                  child: Image.asset(
                    'assets/img/map_valley.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Text('🗺️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            'Mapa do Vale',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Norte, sul e como chegar em cada lugar — do iniciante ao avançado.',
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Mais lucrativas agora": só esta seção se reconstrói quando a estação muda.
class _SeasonCrops extends StatelessWidget {
  const _SeasonCrops();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final crops = scope.repo.cropsFor(store.season).toList()
          ..sort(
            (a, b) => ((b.meta['profit'] as num?) ?? -1).compareTo(
              (a.meta['profit'] as num?) ?? -1,
            ),
          );
        final top = crops
            .where((e) => e.meta['profit'] != null)
            .take(8)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              '🌱 Mais lucrativas agora (${seasonNames[store.season]})',
            ),
            if (top.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Nada cresce ao ar livre nesta estação. Pesque, minere e socialize!',
                ),
              )
            else
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: top.length,
                  itemBuilder: (context, i) => SizedBox(
                    width: 130,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DexCard(
                        entry: top[i],
                        color: scope.repo.category('culturas').color,
                        showCollected: false,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GuideCard extends StatelessWidget {
  final Entry entry;
  const _GuideCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cat = AppScope.of(context).repo.category('guia');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 200,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => openEntry(context, entry),
            child: Ink(
              decoration: parchment(context, accent: cat.color),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          entry.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    entry.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cats = scope.repo.categories.where((c) => c.id != 'guia').toList();
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final c = cats[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => CategoryScreen(cat: c)),
              ),
              child: Ink(
                width: 92,
                decoration: parchment(context, accent: c.color),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Hoje na fazenda": escolha a data do jogo e veja o que acontece.
class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    // Escuta o Store aqui dentro: mudanças de dia/estação (slider, setas ou
    // chips) atualizam o cartão no mesmo frame, sem depender do pai.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final today = scope.repo.eventsOn(store.season, store.day);
        final next = scope.repo
            .upcoming(store.season, store.day, 7)
            .where((e) => e.key > 0)
            .toList();

        String when(int d) => d == 1 ? 'amanhã' : 'em $d dias';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: parchment(
            context,
            accent: const Color(0xFFF9A825),
            radius: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hoje na fazenda',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: store.prevDay,
                  ),
                  Text(
                    '${seasonEmojis[store.season]} ${seasonNames[store.season]} ${store.day}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: store.nextDay,
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var s = 0; s < 4; s++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${seasonEmojis[s]} ${seasonNames[s]}'),
                          selected: store.season == s,
                          onSelected: (_) => store.setDate(s, store.day),
                        ),
                      ),
                  ],
                ),
              ),
              Slider(
                value: store.day.toDouble(),
                min: 1,
                max: 28,
                divisions: 27,
                label: '${store.day}',
                onChanged: (v) => store.setDate(store.season, v.round()),
              ),
              if (today.isEmpty)
                const Text(
                  'Dia tranquilo: regue as plantas, colete itens e converse com os moradores.',
                )
              else
                for (final ev in today)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: () => openEntry(context, ev.entry),
                      child: Text(
                        '${ev.emoji} ${ev.label}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              if (next.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Nos próximos dias',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                for (final e in next.take(4))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: InkWell(
                      onTap: () => openEntry(context, e.value.entry),
                      child: Text(
                        '${e.value.emoji} ${e.value.label} — ${when(e.key)}',
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
