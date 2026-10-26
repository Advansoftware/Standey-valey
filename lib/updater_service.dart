import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Versão instalada. Começa com a do pubspec e é confirmada pelo Android
/// (versionName do pacote) na primeira verificação de atualização.
String currentAppVersion = '1.5.2';
const String githubRepoOwner = 'Advansoftware';
const String githubRepoName = 'Standey-valey';

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  error,
}

class ReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final String apkName;

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    required this.apkName,
  });

  String get sizeLabel {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  factory ReleaseInfo.fromJson(Map<String, dynamic> j) {
    final assets = (j['assets'] as List?) ?? const [];
    var apkUrl = '';
    var apkSize = 0;
    var apkFilename = '';

    for (final a in assets) {
      if (a is Map) {
        final fname = (a['name'] as String?) ?? '';
        if (fname.toLowerCase().endsWith('.apk')) {
          apkUrl = (a['browser_download_url'] as String?) ?? '';
          apkSize = (a['size'] as num?)?.toInt() ?? 0;
          apkFilename = fname;
          break;
        }
      }
    }

    return ReleaseInfo(
      tagName: (j['tag_name'] as String?) ?? '',
      name: (j['name'] as String?) ?? (j['tag_name'] as String?) ?? '',
      body: (j['body'] as String?) ?? '',
      publishedAt: DateTime.tryParse((j['published_at'] as String?) ?? '') ??
          DateTime.now(),
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      apkName: apkFilename,
    );
  }
}

class UpdaterService extends ChangeNotifier {
  static const _channel = MethodChannel('guia_do_vale/updater');

  UpdateStatus status = UpdateStatus.idle;
  ReleaseInfo? latestRelease;
  ReleaseInfo? currentReleaseInfo;
  String? errorMessage;
  double downloadProgress = 0.0;
  int downloadedBytes = 0;
  int totalBytes = 0;
  String? downloadedApkPath;

  bool get isNewVersionAvailable =>
      status == UpdateStatus.available && latestRelease != null;

  bool _versionLoaded = false;

  /// Lê a versão real do app instalado (evita oferecer a mesma versão de novo).
  Future<void> _loadInstalledVersion() async {
    if (_versionLoaded) return;
    _versionLoaded = true;
    try {
      final v = await _channel.invokeMethod<String>('versionName');
      if (v != null && v.trim().isNotEmpty) currentAppVersion = v.trim();
    } catch (_) {
      // Testes e plataformas sem o canal nativo: fica a versão do pubspec.
    }
  }

  /// Verifica se há uma versão mais recente no GitHub Releases público.
  Future<bool> checkForUpdates({bool silent = false}) async {
    if (status == UpdateStatus.checking || status == UpdateStatus.downloading) {
      return false;
    }
    status = UpdateStatus.checking;
    errorMessage = null;
    if (!silent) notifyListeners();
    await _loadInstalledVersion();

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final url = Uri.parse(
        'https://api.github.com/repos/$githubRepoOwner/$githubRepoName/releases/latest',
      );
      final req = await client.getUrl(url);
      req.headers.set('User-Agent', 'GuiaDoVale-App');
      req.headers.set('Accept', 'application/vnd.github.v3+json');

      final res = await req.close();
      if (res.statusCode == 200) {
        final bodyStr = await res.transform(utf8.decoder).join();
        final json = jsonDecode(bodyStr) as Map<String, dynamic>;
        final release = ReleaseInfo.fromJson(json);
        latestRelease = release;

        final isNewer = _compareVersions(release.tagName, currentAppVersion);
        if (isNewer && release.apkDownloadUrl.isNotEmpty) {
          status = UpdateStatus.available;
          notifyListeners();
          return true;
        } else {
          status = UpdateStatus.upToDate;
          notifyListeners();
          return false;
        }
      } else {
        errorMessage = 'Servidor do GitHub respondeu com status ${res.statusCode}.';
        status = UpdateStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Não foi possível verificar atualizações: $e';
      status = UpdateStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Busca informações da release atual (para exibir o que tem na versão atual ao clicar).
  Future<ReleaseInfo?> fetchReleaseNotes(String tagName) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final tag = tagName.startsWith('v') ? tagName : 'v$tagName';
      final url = Uri.parse(
        'https://api.github.com/repos/$githubRepoOwner/$githubRepoName/releases/tags/$tag',
      );
      final req = await client.getUrl(url);
      req.headers.set('User-Agent', 'GuiaDoVale-App');
      req.headers.set('Accept', 'application/vnd.github.v3+json');

      final res = await req.close();
      if (res.statusCode == 200) {
        final bodyStr = await res.transform(utf8.decoder).join();
        final json = jsonDecode(bodyStr) as Map<String, dynamic>;
        final rel = ReleaseInfo.fromJson(json);
        if (tag == 'v$currentAppVersion' || tag == currentAppVersion) {
          currentReleaseInfo = rel;
          notifyListeners();
        }
        return rel;
      }
    } catch (_) {}
    return null;
  }

  /// Baixa o APK da nova versão com acompanhamento de progresso.
  Future<bool> downloadAndInstallUpdate() async {
    final release = latestRelease;
    if (release == null || release.apkDownloadUrl.isEmpty) {
      errorMessage = 'Nenhum APK disponível para download nesta versão.';
      status = UpdateStatus.error;
      notifyListeners();
      return false;
    }

    status = UpdateStatus.downloading;
    downloadProgress = 0.0;
    downloadedBytes = 0;
    totalBytes = release.apkSizeBytes;
    errorMessage = null;
    notifyListeners();

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse(release.apkDownloadUrl));
      req.headers.set('User-Agent', 'GuiaDoVale-App');
      final res = await req.close();

      if (res.statusCode == 302 || res.statusCode == 301) {
        final redirectUrl = res.headers.value('location');
        if (redirectUrl != null) {
          final redirectedReq = await client.getUrl(Uri.parse(redirectUrl));
          return await _streamDownload(redirectedReq, release);
        }
      }

      return await _streamDownload(req, release, response: res);
    } catch (e) {
      errorMessage = 'Falha no download da atualização: $e';
      status = UpdateStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _streamDownload(
    HttpClientRequest req,
    ReleaseInfo release, {
    HttpClientResponse? response,
  }) async {
    try {
      final res = response ?? await req.close();
      if (res.statusCode != 200) {
        errorMessage = 'Download falhou com código ${res.statusCode}';
        status = UpdateStatus.error;
        notifyListeners();
        return false;
      }

      final contentLength = res.contentLength;
      if (contentLength > 0) {
        totalBytes = contentLength;
      }

      // Precisa ser a pasta cache do app: é a liberada no FileProvider.
      final cacheDir = await _channel.invokeMethod<String>('cacheDir') ?? Directory.systemTemp.path;
      final targetFile = File('$cacheDir/${release.apkName.isNotEmpty ? release.apkName : 'guia-do-vale-update.apk'}');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final sink = targetFile.openWrite();
      var received = 0;
      var lastTick = 0;

      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        downloadedBytes = received;
        if (totalBytes > 0) {
          downloadProgress = (received / totalBytes).clamp(0.0, 1.0);
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastTick > 150 || downloadProgress >= 1.0) {
          lastTick = now;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();

      downloadProgress = 1.0;
      downloadedApkPath = targetFile.path;
      status = UpdateStatus.readyToInstall;
      notifyListeners();

      // Dispara a instalação automaticamente ao concluir
      return await installDownloadedApk();
    } catch (e) {
      errorMessage = 'Erro ao salvar o arquivo: $e';
      status = UpdateStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Dispara a instalação do APK baixado pelo sistema nativo do Android.
  Future<bool> installDownloadedApk() async {
    final path = downloadedApkPath;
    if (path == null || !File(path).existsSync()) {
      errorMessage = 'Arquivo de instalação não encontrado no celular.';
      status = UpdateStatus.error;
      notifyListeners();
      return false;
    }

    try {
      errorMessage = null;
      final ok = await _channel.invokeMethod<bool>('installApk', {'path': path});
      return ok == true;
    } on PlatformException catch (e) {
      errorMessage = e.message ?? 'Falha ao abrir o instalador de pacotes.';
      // Sem permissão o APK continua baixado: basta permitir e tocar em Instalar.
      status = e.code == 'needs_permission' ? UpdateStatus.readyToInstall : UpdateStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Erro ao instalar: $e';
      status = UpdateStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Compara duas tags de versão (ex: 'v1.3.3' > '1.3.2' -> true).
  static bool _compareVersions(String remoteTag, String localTag) {
    try {
      final r = _parseVersion(remoteTag);
      final l = _parseVersion(localTag);
      for (var i = 0; i < 3; i++) {
        final rv = i < r.length ? r[i] : 0;
        final lv = i < l.length ? l[i] : 0;
        if (rv > lv) return true;
        if (rv < lv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parseVersion(String tag) {
    var clean = tag.trim().toLowerCase();
    if (clean.startsWith('v')) clean = clean.substring(1);
    final plus = clean.indexOf('+');
    if (plus >= 0) clean = clean.substring(0, plus);
    return clean.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }
}
