import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../updater_service.dart';

const _ink = Color(0xFF3A2414);
const _paper = Color(0xFFF8EBCB);
const _wood = Color(0xFF4A2B16);
const _woodDark = Color(0xFF1D120B);
const _gold = Color(0xFFE6B34A);
const _green = Color(0xFF3F7A2A);

/// Tela completa de atualização do aplicativo com download e instalação direta.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _checkedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedOnce) {
      _checkedOnce = true;
      final updater = AppScope.of(context).updater;
      if (updater.status == UpdateStatus.idle) {
        updater.checkForUpdates();
      }
    }
  }

  void _showCurrentReleaseNotes(BuildContext context, UpdaterService updater) {
    showDialog<void>(
      context: context,
      builder: (c) {
        return AlertDialog(
          backgroundColor: _paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _woodDark, width: 2),
          ),
          title: Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Versão $currentAppVersion',
                  style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _green.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Instalada atualmente no seu celular',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  updater.currentReleaseInfo?.body.isNotEmpty == true
                      ? updater.currentReleaseInfo!.body
                      : '• Tela Meu Status interativa com inspeção em tempo real.\n'
                          '• Sincronização automática com a Stardew Web API.\n'
                          '• Sistema de atualização automática direto pelo GitHub.\n'
                          '• Enciclopédia 100% offline com 565 fichas ilustradas.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: _ink),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _ink,
              ),
              onPressed: () => Navigator.pop(c),
              child: const Text('FECHAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final updater = AppScope.of(context).updater;
    final isNew = updater.isNewVersionAvailable;
    final release = updater.latestRelease;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Atualizações',
          style: TextStyle(fontFamily: 'PixelifySans', letterSpacing: 1.1),
        ),
      ),
      body: ListenableBuilder(
        listenable: updater,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _buildCurrentVersionCard(context, updater),
              const SizedBox(height: 16),
              if (updater.status == UpdateStatus.checking)
                _buildCheckingCard()
              else if (isNew && release != null)
                _buildNewVersionCard(context, updater, release)
              else if (updater.status == UpdateStatus.upToDate)
                _buildUpToDateCard(context, updater)
              else if (updater.status == UpdateStatus.error)
                _buildErrorCard(context, updater),
              const SizedBox(height: 20),
              _buildManualCheckButton(updater),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentVersionCard(
    BuildContext context,
    UpdaterService updater,
  ) {
    return InkWell(
      onTap: () {
        if (updater.currentReleaseInfo == null) {
          updater.fetchReleaseNotes(currentAppVersion);
        }
        _showCurrentReleaseNotes(context, updater);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _woodDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _wood.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: const Center(
                child: Text('📱', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VERSÃO INSTALADA',
                    style: TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B5238),
                    ),
                  ),
                  Text(
                    'Guia do Vale v$currentAppVersion',
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toque para ver os detalhes desta versão',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5B4630)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline_rounded, color: _wood, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _wood.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, color: _gold),
          ),
          SizedBox(height: 12),
          Text(
            'Buscando novas versões no GitHub…',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateCard(BuildContext context, UpdaterService updater) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.6), width: 1.8),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_circle_rounded, color: _green, size: 36),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Seu aplicativo está atualizado!',
            style: TextStyle(
              fontFamily: 'PixelifySans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _green,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Você já está aproveitando os recursos mais recentes do Guia do Vale.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _buildNewVersionCard(
    BuildContext context,
    UpdaterService updater,
    ReleaseInfo release,
  ) {
    final isDownloading = updater.status == UpdateStatus.downloading;
    final isReady = updater.status == UpdateStatus.readyToInstall;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NOVA VERSÃO',
                  style: TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: _ink,
                  ),
                ),
              ),
              const Spacer(),
              if (release.sizeLabel.isNotEmpty)
                Text(
                  release.sizeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5238),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            release.name,
            style: const TextStyle(
              fontFamily: 'PixelifySans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: Text(
                release.body.isNotEmpty
                    ? release.body
                    : 'Melhorias de desempenho e correções.',
                style: const TextStyle(fontSize: 12, height: 1.35, color: _ink),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Área com barra de progresso circular e ícone no centro (pedido pelo usuário)
          if (isDownloading || isReady) ...[
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: isReady
                          ? 1.0
                          : (updater.downloadProgress > 0
                              ? updater.downloadProgress
                              : null),
                      strokeWidth: 7,
                      color: isReady ? _green : _gold,
                      backgroundColor: _wood.withValues(alpha: 0.12),
                    ),
                  ),
                  Icon(
                    isReady
                        ? Icons.check_circle_rounded
                        : Icons.downloading_rounded,
                    size: 38,
                    color: isReady ? _green : _gold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isReady
                  ? 'Download concluído!'
                  : 'Baixando… ${(updater.downloadProgress * 100).toStringAsFixed(0)}% '
                      '(${_formatBytes(updater.downloadedBytes)} / ${_formatBytes(updater.totalBytes)})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isReady)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.install_mobile_rounded),
              label: const Text(
                'INSTALAR ATUALIZAÇÃO AGORA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              onPressed: () => updater.installDownloadedApk(),
            )
          else if (!isDownloading)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                'BAIXAR E ATUALIZAR (${release.sizeLabel})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              onPressed: () => updater.downloadAndInstallUpdate(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, UpdaterService updater) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  updater.errorMessage ?? 'Ocorreu um erro ao verificar.',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualCheckButton(UpdaterService updater) {
    final busy = updater.status == UpdateStatus.checking ||
        updater.status == UpdateStatus.downloading;

    return Center(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _wood, width: 1.5),
          foregroundColor: _wood,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: busy ? null : () => updater.checkForUpdates(),
        icon: const Icon(Icons.sync_rounded),
        label: const Text(
          'BUSCAR ATUALIZAÇÃO',
          style: TextStyle(
            fontFamily: 'PixelifySans',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
