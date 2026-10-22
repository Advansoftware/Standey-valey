import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre e ajustes')),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, scope.ai, scope.search]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Card(
                title: 'Aparência',
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                  ],
                  selected: {store.themeMode},
                  onSelectionChanged: (s) => store.setThemeMode(s.first),
                ),
              ),
              _Card(
                title: 'Assistente (IA local)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scope.ai.engineReady ? 'Motor de IA: disponível neste aparelho.' : 'Motor de IA: indisponível (${scope.ai.engineError ?? 'inicializando…'}).'),
                    const SizedBox(height: 4),
                    Text(store.aiModelInstalled ? 'Modelo baixado: sim.' : 'Modelo baixado: não (baixe na aba Assistente).'),
                    const SizedBox(height: 4),
                    Text(scope.search.wikiAvailable ? 'Wiki offline: incluída.' : 'Wiki offline: não incluída nesta versão.'),
                  ],
                ),
              ),
              _Card(
                title: 'Progresso',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Zerar progresso (itens marcados)'),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Zerar progresso?'),
                          content: const Text('Isso desmarca tudo que você marcou como pescado, plantado, entregue etc. Favoritos continuam.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Zerar')),
                          ],
                        ),
                      );
                      if (ok == true) store.resetProgress();
                    },
                  ),
                ),
              ),
              const _Card(
                title: 'Créditos e avisos',
                child: Text(
                  'Guia do Vale é um app de fã, não oficial e sem fins comerciais.\n\n'
                  '• Stardew Valley e seus personagens, imagens e sprites pertencem a ConcernedApe.\n'
                  '• Dados estruturados: pacote "stardew-valley-data" (licença MIT).\n'
                  '• Textos opcionais da wiki: Stardew Valley Wiki, licença CC BY-NC-SA 3.0.\n'
                  '• Valores baseados na versão 1.6 do jogo e podem mudar em atualizações.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: parchment(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
