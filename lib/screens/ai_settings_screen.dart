import 'package:flutter/material.dart';

import '../ai_cloud.dart';
import '../ai_models.dart';
import '../app_scope.dart';
import '../app_theme.dart';
import '../store.dart';
import '../widgets/ai_cloud_panel.dart';
import '../widgets/assistant_install_card.dart';
import '../widgets/common.dart';

/// Escolha de quem responde no Assistente (modelo local ou provedor web) e
/// configuração de cada um. Tudo redesenha na hora: a tela escuta o [Store] e
/// o [AiService].
class AiSettingsScreen extends StatelessWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar IA')),
      body: ContentWidth(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.store, scope.ai]),
          builder: (context, _) {
            final store = scope.store;
            final p = store.aiProvider;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Parchment(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quem responde', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        'Os provedores web entendem melhor perguntas difíceis; o modelo no celular funciona sem internet. '
                        'Todos usam os trechos da wiki do app como base.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      RadioGroup<AiProvider>(
                        groupValue: p,
                        onChanged: (v) {
                          if (v != null) store.setAiProvider(v);
                        },
                        child: Column(
                          children: [
                            for (final prov in AiProvider.values)
                              RadioListTile<AiProvider>(
                                key: ValueKey('prov-${prov.id}'),
                                value: prov,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Row(
                                  children: [
                                    Flexible(child: Text(prov.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                                    const SizedBox(width: 6),
                                    _StatusBadge(provider: prov, store: store),
                                  ],
                                ),
                                subtitle: Text(_subtitle(prov, store), style: Theme.of(context).textTheme.bodySmall),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (p.isCloud)
                  AiCloudPanel(key: ValueKey('cloud-${p.id}'), provider: p)
                else
                  const AssistantInstallCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  String _subtitle(AiProvider p, Store store) {
    if (p == AiProvider.local) {
      final m = aiModelById(store.aiModelId);
      return store.aiModelInstalled && m != null ? 'Modelo: ${m.name}' : p.note;
    }
    final model = store.aiCloudModel(p);
    return store.aiKey(p).isNotEmpty && model.isNotEmpty ? 'Modelo: $model' : p.note;
  }
}

class _StatusBadge extends StatelessWidget {
  final AiProvider provider;
  final Store store;
  const _StatusBadge({required this.provider, required this.store});

  @override
  Widget build(BuildContext context) {
    final ready = provider.isCloud
        ? store.aiKey(provider).isNotEmpty && store.aiCloudModel(provider).isNotEmpty
        : store.aiModelInstalled;
    final (text, color) = store.aiProvider == provider && ready
        ? ('Em uso', const Color(0xFF2E7D32))
        : ready
            ? ('Pronto', const Color(0xFF1565C0))
            : (provider.isCloud ? 'Falta a chave' : 'Falta baixar', const Color(0xFF8D6E63));
    return AiBadge(text, color);
  }
}
