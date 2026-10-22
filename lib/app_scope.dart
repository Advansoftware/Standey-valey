import 'package:flutter/widgets.dart';

import 'ai_service.dart';
import 'repository.dart';
import 'search.dart';
import 'store.dart';

class AppScope extends InheritedWidget {
  final Store store;
  final Repository repo;
  final SearchService search;
  final AiService ai;

  const AppScope({
    super.key,
    required this.store,
    required this.repo,
    required this.search,
    required this.ai,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
