import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'about_screen.dart';
import 'assistant_screen.dart';
import 'category_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'status_screen.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Conecte ao servidor do jogo para abrir Meu Status.',
        ),
        action: SnackBarAction(
          label: 'Conectar',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.api,
      builder: (context, _) {
        final connected = scope.api.connected;
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              EncyclopediaScreen(),
              AssistantScreen(),
              FavoritesScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              // O item central abre o painel imersivo e não vira aba: ao
              // fechar, a pessoa continua exatamente onde estava.
              if (i == 2) {
                _openStatus(context, connected);
                return;
              }
              setState(() => _index = i > 2 ? i - 1 : i);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Enciclopédia',
              ),
              NavigationDestination(
                icon: Icon(
                  connected
                      ? Icons.space_dashboard_outlined
                      : Icons.lock_outline_rounded,
                ),
                selectedIcon: Icon(
                  connected
                      ? Icons.space_dashboard_rounded
                      : Icons.lock_outline_rounded,
                ),
                label: 'Meu Status',
                tooltip: connected
                    ? 'Abrir Meu Status'
                    : 'Conecte ao servidor para liberar',
              ),
              const NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Assistente',
              ),
              const NavigationDestination(
                icon: Icon(Icons.star_outline_rounded),
                selectedIcon: Icon(Icons.star_rounded),
                label: 'Favoritos',
              ),
            ],
          ),
        );
      },
    );
  }
}
