import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_cloud.dart';
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
  /// Modelos locais baixados: id do modelo -> endereço de onde veio.
  Map<String, String> aiLocalModels;

  /// Modelo local em uso.
  String aiModelId;

  /// Modelo local sendo baixado ('' se nenhum). Fica salvo para retomar o
  /// download depois de fechar o app (o WorkManager continua baixando).
  String aiDownloadingId;

  AiProvider aiProvider;
  String apiUrl;
  String apiName;
  bool apiAuto;
  int apiLastSyncMs;

  Store._(this._p)
      : favorites = (_p.getStringList('fav') ?? const <String>[]).toSet(),
        collected = (_p.getStringList('col') ?? const <String>[]).toSet(),
        checks = (_p.getStringList('chk') ?? const <String>[]).toSet(),
        season = _p.getInt('season') ?? 0,
        day = _p.getInt('day') ?? 1,
        themeMode = ThemeMode.values[(_p.getInt('theme') ?? 0).clamp(0, 2)],
        aiLocalModels = _loadLocalModels(_p),
        aiModelId = _p.getString('aimodel') ?? defaultAiModel.id,
        aiDownloadingId = _p.getString('aidlid') ?? '',
        aiProvider = AiProvider.byId(_p.getString('aiprov') ?? 'local'),
        apiUrl = _p.getString('apiurl') ?? '',
        apiName = _p.getString('apiname') ?? '',
        apiAuto = _p.getBool('apiauto') ?? true,
        apiLastSyncMs = _p.getInt('apilast') ?? 0;

  /// Lê os modelos baixados. Versões até a 1.5.4 guardavam só um modelo
  /// ('aiok' + 'aimodel' + 'aiurl').
  static Map<String, String> _loadLocalModels(SharedPreferences p) {
    final raw = p.getString('ailocal');
    if (raw != null) {
      try {
        return Map<String, String>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    if (p.getBool('aiok') ?? false) {
      final id = p.getString('aimodel') ?? defaultAiModel.id;
      final url = p.getString('aiurl') ?? '';
      return {id: url.isNotEmpty ? url : (aiModelById(id) ?? defaultAiModel).url};
    }
    return {};
  }

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

  /// Se o modelo local em uso já está baixado.
  bool get aiModelInstalled => aiLocalModels.containsKey(aiModelId);

  bool get aiDownloading => aiDownloadingId.isNotEmpty;

  void addLocalModel(String id, String url) {
    aiLocalModels = {...aiLocalModels, id: url};
    _p.setString('ailocal', jsonEncode(aiLocalModels));
    notifyListeners();
  }

  void removeLocalModel(String id) {
    aiLocalModels = {...aiLocalModels}..remove(id);
    _p.setString('ailocal', jsonEncode(aiLocalModels));
    notifyListeners();
  }

  void setAiDownloadingId(String id) {
    aiDownloadingId = id;
    _p.setString('aidlid', id);
    notifyListeners();
  }

  void setAiModelId(String v) {
    aiModelId = v;
    _p.setString('aimodel', v);
    notifyListeners();
  }

  void setAiProvider(AiProvider p) {
    aiProvider = p;
    _p.setString('aiprov', p.id);
    notifyListeners();
  }

  /// Chave da API do provedor web (fica só neste aparelho).
  String aiKey(AiProvider p) => _p.getString('aikey_${p.id}') ?? '';

  void setAiKey(AiProvider p, String key) {
    _p.setString('aikey_${p.id}', key.trim());
    notifyListeners();
  }

  /// Modelo escolhido no provedor web.
  String aiCloudModel(AiProvider p) => _p.getString('aimod_${p.id}') ?? '';

  void setAiCloudModel(AiProvider p, String model) {
    _p.setString('aimod_${p.id}', model);
    notifyListeners();
  }

  /// Última lista de modelos que a API do provedor devolveu.
  List<CloudModel> aiCloudModels(AiProvider p) => [
        for (final s in _p.getStringList('ailist_${p.id}') ?? const <String>[])
          if (s.contains('|')) CloudModel(s.substring(0, s.indexOf('|')), s.substring(s.indexOf('|') + 1)),
      ];

  void setAiCloudModels(AiProvider p, List<CloudModel> models) {
    _p.setStringList('ailist_${p.id}', [for (final m in models) '${m.id}|${m.name}']);
    notifyListeners();
  }

  /// Se a IA escolhida tem tudo o que precisa para responder.
  bool get aiConfigured => aiProvider.isCloud
      ? aiKey(aiProvider).isNotEmpty && aiCloudModel(aiProvider).isNotEmpty
      : aiModelInstalled;

  void setApiUrl(String v) {
    apiUrl = v;
    _p.setString('apiurl', v);
    notifyListeners();
  }

  void setApiName(String v) {
    apiName = v;
    _p.setString('apiname', v);
    notifyListeners();
  }

  void setApiAuto(bool v) {
    apiAuto = v;
    _p.setBool('apiauto', v);
    notifyListeners();
  }

  void setApiLastSync(DateTime? when) {
    apiLastSyncMs = when?.millisecondsSinceEpoch ?? 0;
    _p.setInt('apilast', apiLastSyncMs);
    notifyListeners();
  }

  /// Marca várias fichas de uma vez (sincronização com a API). Nunca desmarca
  /// nada: o progresso manual do jogador é preservado.
  int addCollected(Iterable<String> ids) {
    var added = 0;
    for (final id in ids) {
      if (collected.add(id)) added++;
    }
    if (added > 0) {
      _p.setStringList('col', collected.toList());
      notifyListeners();
    }
    return added;
  }

  void resetProgress() {
    collected.clear();
    checks.clear();
    _p.setStringList('col', const []);
    _p.setStringList('chk', const []);
    notifyListeners();
  }
}
