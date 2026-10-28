import 'package:flutter/material.dart';

import '../ai_cloud.dart';
import '../app_scope.dart';
import '../app_theme.dart';

/// Configuração de um provedor web: chave da API, modelo (lista vinda da API)
/// e botão de teste.
class AiCloudPanel extends StatefulWidget {
  final AiProvider provider;
  const AiCloudPanel({super.key, required this.provider});

  @override
  State<AiCloudPanel> createState() => _AiCloudPanelState();
}

class _AiCloudPanelState extends State<AiCloudPanel> {
  final _key = TextEditingController();
  bool _show = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    final p = widget.provider;
    _key.text = scope.store.aiKey(p);
    // Já tem chave mas nunca listou os modelos: lista sozinho.
    if (_key.text.isNotEmpty && scope.store.aiCloudModels(p).isEmpty && scope.ai.loadingModels[p] != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => scope.ai.fetchModels(scope.store, p));
    }
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  void _saveKey() {
    final scope = AppScope.of(context);
    final p = widget.provider;
    FocusScope.of(context).unfocus();
    scope.store.setAiKey(p, _key.text);
    scope.ai.testResult.remove(p);
    if (_key.text.trim().isEmpty) {
      scope.store.setAiCloudModels(p, const []);
      scope.store.setAiCloudModel(p, '');
      return;
    }
    scope.ai.fetchModels(scope.store, p);
  }

  // O AppScope não avisa mudanças: o painel escuta o Store e a IA direto.
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.store, scope.ai]),
      builder: (context, _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final store = scope.store;
    final ai = scope.ai;
    final p = widget.provider;
    final savedKey = store.aiKey(p);
    final models = store.aiCloudModels(p);
    final selected = store.aiCloudModel(p);
    final loading = ai.loadingModels[p] == true;
    final error = ai.modelsError[p];
    final testing = ai.testing[p] == true;
    final result = ai.testResult[p];
    final errorColor = Theme.of(context).colorScheme.error;

    return Parchment(
      accent: const Color(0xFF1565C0),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌐 ${p.label}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(p.note, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            key: ValueKey('key-${p.id}'),
            controller: _key,
            obscureText: !_show,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _saveKey(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Chave da API',
              suffixIcon: IconButton(
                tooltip: _show ? 'Esconder' : 'Mostrar',
                icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.key_rounded),
            label: Text(savedKey.isNotEmpty && _key.text.trim() == savedKey ? 'Chave salva · listar modelos' : 'Salvar chave'),
            onPressed: loading ? null : _saveKey,
          ),
          const SizedBox(height: 4),
          Text(
            'A chave fica salva só neste aparelho. O uso é cobrado pelo provedor, na sua conta.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            const Text('Buscando os modelos na API…'),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: errorColor)),
          ],
          if (models.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('models-${p.id}-${models.length}'),
                    initialValue: models.any((m) => m.id == selected) ? selected : null,
                    isExpanded: true,
                    // Fonte comum: na fonte de pixel o "5" de gpt-5 parece um "S".
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(labelText: 'Modelo (${models.length} disponíveis)'),
                    items: [
                      for (final m in models)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name == m.id ? m.id : '${m.name} · ${m.id}', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      ai.testResult.remove(p);
                      store.setAiCloudModel(p, v);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar lista',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: loading || savedKey.isEmpty ? null : () => ai.fetchModels(store, p),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: testing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_circle_outline_rounded),
              label: Text(testing ? 'Testando…' : 'Testar modelo'),
              onPressed: testing || selected.isEmpty ? null : () => ai.testModel(store, p),
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(result.$1 ? Icons.check_circle_rounded : Icons.error_rounded,
                      size: 18, color: result.$1 ? const Color(0xFF2E7D32) : errorColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(result.$2)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
