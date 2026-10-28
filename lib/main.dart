import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ai_models.dart';
import 'ai_service.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'game_api.dart';
import 'repository.dart';
import 'screens/shell.dart';
import 'search.dart';
import 'store.dart';
import 'updater_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.load();
  final repo = await Repository.load();
  final search = SearchService(repo);
  final ai = AiService();
  final api = GameApi(store, repo);
  final updater = UpdaterService();

  runApp(StardewGuiaApp(store: store, repo: repo, search: search, ai: ai, api: api, updater: updater));

  // Em segundo plano: motor de IA local, API do jogo e verificação de atualizações.
  updater.checkForUpdates(silent: true);
  ai.init().then((_) {
    // Retoma o download interrompido quando o app foi fechado.
    final model = aiModelById(store.aiDownloadingId);
    if (model != null) ai.install(store, model);
  });
  api.init();
  WidgetsBinding.instance.addPostFrameCallback((_) => search.loadWiki());
}

class StardewGuiaApp extends StatelessWidget {
  final Store store;
  final Repository repo;
  final SearchService search;
  final AiService ai;
  final GameApi api;
  final UpdaterService updater;

  const StardewGuiaApp({
    super.key,
    required this.store,
    required this.repo,
    required this.search,
    required this.ai,
    required this.api,
    required this.updater,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      repo: repo,
      search: search,
      ai: ai,
      api: api,
      updater: updater,
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
