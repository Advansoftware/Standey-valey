import 'package:flutter/material.dart';

import '../ai_models.dart';
import '../app_scope.dart';
import '../app_theme.dart';

/// Cartão de instalação do modelo de IA: escolha do modelo, download e status.
class AssistantInstallCard extends StatefulWidget {
  final String modelId;
  final ValueChanged<String> onModelChanged;

  /// Recebe o endereço personalizado (vazio quando usa o modelo escolhido).
  final void Function(String urlOverride) onInstall;

  const AssistantInstallCard({
    super.key,
    required this.modelId,
    required this.onModelChanged,
    required this.onInstall,
  });

  @override
  State<AssistantInstallCard> createState() => _AssistantInstallCardState();
}

class _AssistantInstallCardState extends State<AssistantInstallCard> {
  final _url = TextEditingController();
  bool _showAdvanced = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final store = AppScope.of(context).store;
    _url.text = store.aiModelUrl.isNotEmpty ? store.aiModelUrl : defaultAiModel.url;
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = AppScope.of(context).ai;
    final store = AppScope.of(context).store;
    final model = aiModelById(widget.modelId) ?? defaultAiModel;

    return Parchment(
      accent: const Color(0xFF8E24AA),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠 IA no seu celular', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Sem o modelo, o assistente mostra os trechos mais parecidos com a sua pergunta. '
            'Para respostas escritas pela IA, baixe o modelo uma vez (use Wi-Fi). '
            'Depois disso tudo roda offline.',
          ),
          if (!ai.engineReady && ai.engineError != null) ...[
            const SizedBox(height: 6),
            Text(
              'Este aparelho não suporta o motor de IA: ${ai.engineError}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          _SelectedModel(model: model),
          const SizedBox(height: 10),
          if (ai.downloading) ...[
            LinearProgressIndicator(value: ai.progress > 0 ? ai.progress.clamp(0.0, 1.0) : null),
            const SizedBox(height: 4),
            Text('Baixando… ${(ai.progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
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
          ] else
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: Text('Baixar ${model.name} (${model.sizeLabel})'),
              onPressed: ai.engineReady ? () => widget.onInstall(_showAdvanced ? _url.text : '') : null,
            ),
          if (ai.installError != null) ...[
            const SizedBox(height: 6),
            Text('Erro: ${ai.installError}', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          _ModelList(
            selectedId: model.id,
            onChanged: (id) {
              widget.onModelChanged(id);
              final m = aiModelById(id);
              if (m != null) {
                _url.text = m.url;
                store.setAiUrl(m.url);
              }
            },
          ),
          TextButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(_showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: const Text('Usar outro arquivo (.litertlm)'),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _url,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(labelText: 'Endereço do modelo (.litertlm)'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Resumo do modelo que será baixado.
class _SelectedModel extends StatelessWidget {
  final AiModel model;
  const _SelectedModel({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🧩', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modelo escolhido: ${model.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${model.sizeLabel} · RAM ${model.ram}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de modelos conhecidos, com tamanho, RAM sugerida e observações.
class _ModelList extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _ModelList({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha o modelo', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        RadioGroup<String>(
          groupValue: selectedId,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          child: Column(
            children: [
              for (final m in aiModels)
                RadioListTile<String>(
                  value: m.id,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Flexible(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(width: 6),
                      Text(m.sizeLabel, style: Theme.of(context).textTheme.bodySmall),
                      if (m.id == defaultAiModel.id) ...[
                        const SizedBox(width: 6),
                        const _Badge('Recomendado', Color(0xFF2E7D32)),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${m.ram} de RAM${m.note.isEmpty ? '' : ' · ${m.note}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
