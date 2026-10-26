import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'about_screen.dart';
import 'assistant_screen.dart';
import 'category_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'status_screen.dart';
import '../widgets/sdv_notice.dart';
import '../widgets/stardew_ui.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openStatus(BuildContext context, bool connected) {
    if (connected) {
      openStatusScreen(context);
      return;
    }
    showSdvNotice(
      context,
      'Conecte ao servidor do jogo para abrir Meu Status.',
      actionLabel: 'Conectar',
      onAction: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.api,
      builder: (context, _) {
        final connected = scope.api.connected;
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final pages = IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            EncyclopediaScreen(),
            AssistantScreen(),
            FavoritesScreen(),
          ],
        );
        final nav = SdvNavBar(
          vertical: landscape,
          selected: _index >= 2 ? _index + 1 : _index,
          onTap: (i) {
            // O item central abre o painel imersivo e não vira aba: ao
            // fechar, a pessoa continua exatamente onde estava.
            if (i == 2) {
              _openStatus(context, connected);
              return;
            }
            setState(() => _index = i > 2 ? i - 1 : i);
          },
          items: [
            const SdvNavItem(Icons.home_rounded, 'Início'),
            const SdvNavItem(Icons.menu_book_rounded, 'Enciclopédia'),
            SdvNavItem(
              Icons.space_dashboard_rounded,
              'Meu Status',
              locked: !connected,
            ),
            const SdvNavItem(Icons.auto_awesome_rounded, 'Assistente'),
            const SdvNavItem(Icons.star_rounded, 'Favoritos'),
          ],
        );
        // Deitado, a barra vai para a lateral e a tela ganha altura.
        if (landscape) {
          return Scaffold(
            body: Row(
              children: [
                nav,
                Expanded(child: pages),
              ],
            ),
          );
        }
        return Scaffold(body: pages, bottomNavigationBar: nav);
      },
    );
  }
}
