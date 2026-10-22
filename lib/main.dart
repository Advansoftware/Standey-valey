import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ai_service.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'repository.dart';
import 'screens/shell.dart';
import 'search.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.load();
  final repo = await Repository.load();
  final search = SearchService(repo);
  final ai = AiService();

  runApp(StardewGuiaApp(store: store, repo: repo, search: search, ai: ai));

  // Em segundo plano: motor de IA local e wiki offline (se existir).
  ai.init();
  WidgetsBinding.instance.addPostFrameCallback((_) => search.loadWiki());
}

class StardewGuiaApp extends StatelessWidget {
  final Store store;
  final Repository repo;
  final SearchService search;
  final AiService ai;

  const StardewGuiaApp({
    super.key,
    required this.store,
    required this.repo,
    required this.search,
    required this.ai,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      repo: repo,
      search: search,
      ai: ai,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: 'Guia do Vale',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: store.themeMode,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        ),
      ),
    );
  }
}
