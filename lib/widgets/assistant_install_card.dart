import 'package:flutter/material.dart';

import '../ai_models.dart';
import '../app_scope.dart';
import '../app_theme.dart';

/// Modelos locais: qual está em uso, quais estão baixados, baixar, trocar e
/// apagar. A troca vale a qualquer momento, inclusive depois do primeiro
/// download.
class AssistantInstallCard extends StatefulWidget {
  const AssistantInstallCard({super.key});

  @override
  State<AssistantInstallCard> createState() => _AssistantInstallCardState();
}

class _AssistantInstallCardState extends State<AssistantInstallCard> {
  final _url = TextEditingController();
  bool _showAdvanced = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _delete(AiModel m) async {
    final scope = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Apagar ${m.name}?'),
        content: Text('Libera ${m.sizeLabel} do celular. Para usar de novo, é preciso baixar outra vez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) await scope.ai.uninstall(scope.store, m.id);
  }

  // O AppScope não avisa mudanças: o cartão escuta o Store e a IA direto,
  // senão a troca de modelo só apareceria ao reabrir a tela.
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.store, scope.ai]),
      builder: (context, _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final ai = scope.ai;
    final store = scope.store;
    final busy = ai.downloading || ai.switchingId != null;

    return Parchment(
      accent: const Color(0xFF8E24AA),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠 IA no seu celular', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Baixe um modelo uma vez (use Wi-Fi) e ele roda offline. Pode baixar mais de um e '
            'trocar quando quiser.',
          ),
          if (!ai.engineReady && ai.engineError != null) ...[
            const SizedBox(height: 6),
            Text(
              'Este aparelho não suporta o motor de IA: ${ai.engineError}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (ai.downloading) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pode sair do app: o download continua em segundo plano e aparece na notificação.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (ai.installError != null) ...[
            const SizedBox(height: 6),
            Text('Erro: ${ai.installError}', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          for (final m in aiModels)
            _ModelTile(
              model: m,
              active: store.aiModelInstalled && store.aiModelId == m.id,
              downloaded: store.aiLocalModels.containsKey(m.id),
              downloading: ai.downloading && store.aiDownloadingId == m.id,
              switching: ai.switchingId == m.id,
              progress: ai.progress,
              enabled: ai.engineReady && !busy,
              onUse: () => ai.useLocalModel(store, m.id),
              onDownload: () => ai.install(store, m),
              onDelete: () => _delete(m),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(_showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: const Text('Usar outro arquivo (.litertlm)'),
          ),
          if (_showAdvanced) ...[
            TextField(
              controller: _url,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(labelText: 'Endereço do modelo (.litertlm)'),
            ),
            const SizedBox(height: 6),
            Text(
              'O arquivo entra no lugar de "${(aiModelById(store.aiModelId) ?? defaultAiModel).name}" '
              '(usa o mesmo formato de conversa).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('Baixar deste endereço'),
              onPressed: !ai.engineReady || busy || _url.text.trim().isEmpty
                  ? null
                  : () => ai.install(store, aiModelById(store.aiModelId) ?? defaultAiModel, urlOverride: _url.text),
            ),
          ],
        ],
      ),
    );
  }
}

/// Um modelo da lista, com o que dá para fazer com ele agora.
class _ModelTile extends StatelessWidget {
  final AiModel model;
  final bool active;
  final bool downloaded;
  final bool downloading;
  final bool switching;
  final double progress;
  final bool enabled;
  final VoidCallback onUse;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _ModelTile({
    required this.model,
    required this.active,
    required this.downloaded,
    required this.downloading,
    required this.switching,
    required this.progress,
    required this.enabled,
    required this.onUse,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    final Widget action;
    if (switching) {
      action = const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (active) {
      action = const AiBadge('Em uso', Color(0xFF2E7D32));
    } else if (downloaded) {
      action = Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Apagar do celular',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: enabled ? onDelete : null,
        ),
        FilledButton.tonal(onPressed: enabled ? onUse : null, child: const Text('Usar')),
      ]);
    } else if (downloading) {
      action = Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700));
    } else {
      action = OutlinedButton(onPressed: enabled ? onDownload : null, child: const Text('Baixar'));
    }

    return Container(
      key: ValueKey('local-${model.id}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: active ? scheme.primary.withValues(alpha: 0.12) : scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? scheme.primary : scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(model.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(model.sizeLabel, style: small),
                    if (model.id == defaultAiModel.id) const AiBadge('Recomendado', Color(0xFF6A1B9A)),
                    if (downloaded && !active) const AiBadge('Baixado', Color(0xFF1565C0)),
                  ],
                ),
              ),
              action,
            ],
          ),
          const SizedBox(height: 2),
          Text('${model.ram} de RAM${model.note.isEmpty ? '' : ' · ${model.note}'}', style: small),
          if (downloading) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress > 0 ? progress.clamp(0.0, 1.0) : null),
          ],
        ],
      ),
    );
  }
}

/// Etiqueta colorida pequena (estado de um modelo ou provedor).
class AiBadge extends StatelessWidget {
  final String text;
  final Color color;
  const AiBadge(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
