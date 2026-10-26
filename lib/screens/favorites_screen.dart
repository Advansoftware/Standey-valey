import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/common.dart';
import 'search_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: ContentWidth(child: ListenableBuilder(
        listenable: scope.store,
        builder: (context, _) {
          final list = entriesByIds(context, scope.store.favorites).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '⭐ Nada por aqui ainda.\nToque na estrela de qualquer item para guardá-lo.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: list.length,
            itemBuilder: (context, i) => EntryTile(
              entry: list[i],
              color: scope.repo.category(list[i].cat).color,
            ),
          );
        },
      )),
    );
  }
}
