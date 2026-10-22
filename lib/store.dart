import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_models.dart';

/// Estado do usuário: favoritos, progresso, data do jogo e preferências.
class Store extends ChangeNotifier {
  final SharedPreferences _p;
  Set<String> favorites;
  Set<String> collected;
  Set<String> checks;
  int season;
  int day;
  ThemeMode themeMode;
  bool aiModelInstalled;
  String aiModelUrl;
  String aiModelId;

  Store._(this._p)
      : favorites = (_p.getStringList('fav') ?? const <String>[]).toSet(),
        collected = (_p.getStringList('col') ?? const <String>[]).toSet(),
        checks = (_p.getStringList('chk') ?? const <String>[]).toSet(),
        season = _p.getInt('season') ?? 0,
        day = _p.getInt('day') ?? 1,
        themeMode = ThemeMode.values[(_p.getInt('theme') ?? 0).clamp(0, 2)],
        aiModelInstalled = _p.getBool('aiok') ?? false,
        aiModelUrl = _p.getString('aiurl') ?? '',
        aiModelId = _p.getString('aimodel') ?? defaultAiModel.id;

  /// Cria o estado a partir de preferências já carregadas (usado nos testes).
  factory Store.withPrefs(SharedPreferences p) => Store._(p);

  static Future<Store> load() async => Store._(await SharedPreferences.getInstance());

  bool isFav(String id) => favorites.contains(id);
  bool isCollected(String id) => collected.contains(id);
  bool isChecked(String entryId, String item) => checks.contains('$entryId|$item');

  void toggleFav(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    _p.setStringList('fav', favorites.toList());
    notifyListeners();
  }

  void toggleCollected(String id) {
    collected.contains(id) ? collected.remove(id) : collected.add(id);
    _p.setStringList('col', collected.toList());
    notifyListeners();
  }

  void toggleCheck(String entryId, String item) {
    final k = '$entryId|$item';
    checks.contains(k) ? checks.remove(k) : checks.add(k);
    _p.setStringList('chk', checks.toList());
    notifyListeners();
  }

  int checkedCount(String entryId, List<String> items) =>
      items.where((i) => checks.contains('$entryId|$i')).length;

  void setDate(int s, int d) {
    season = s % 4;
    day = d.clamp(1, 28);
    _p.setInt('season', season);
    _p.setInt('day', day);
    notifyListeners();
  }

  void nextDay() {
    var s = season;
    var d = day + 1;
    if (d > 28) {
      d = 1;
      s = (s + 1) % 4;
    }
    setDate(s, d);
  }

  void prevDay() {
    var s = season;
    var d = day - 1;
    if (d < 1) {
      d = 28;
      s = (s + 3) % 4;
    }
    setDate(s, d);
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _p.setInt('theme', m.index);
    notifyListeners();
  }

  void setAiInstalled(bool v) {
    aiModelInstalled = v;
    _p.setBool('aiok', v);
    notifyListeners();
  }

  void setAiUrl(String v) {
    aiModelUrl = v;
    _p.setString('aiurl', v);
    notifyListeners();
  }

  void setAiModelId(String v) {
    aiModelId = v;
    _p.setString('aimodel', v);
    notifyListeners();
  }

  void resetProgress() {
    collected.clear();
    checks.clear();
    _p.setStringList('col', const []);
    _p.setStringList('chk', const []);
    notifyListeners();
  }
}
