import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre e ajustes')),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, scope.ai, scope.search, scope.api]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Card(
                title: 'Aparência',
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                  ],
                  selected: {store.themeMode},
                  onSelectionChanged: (s) => store.setThemeMode(s.first),
                ),
              ),
              _Card(
                title: 'Servidor do jogo (API)',
                child: _ApiCard(initialUrl: store.apiUrl),
              ),
              _Card(
                title: 'Assistente (IA local)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scope.ai.engineReady ? 'Motor de IA: disponível neste aparelho.' : 'Motor de IA: indisponível (${scope.ai.engineError ?? 'inicializando…'}).'),
                    const SizedBox(height: 4),
                    Text(store.aiModelInstalled ? 'Modelo baixado: sim.' : 'Modelo baixado: não (baixe na aba Assistente).'),
                    const SizedBox(height: 4),
                    Text(scope.search.wikiAvailable ? 'Wiki offline: incluída.' : 'Wiki offline: não incluída nesta versão.'),
                  ],
                ),
              ),
              _Card(
                title: 'Progresso',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Zerar progresso (itens marcados)'),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Zerar progresso?'),
                          content: const Text('Isso desmarca tudo que você marcou como pescado, plantado, entregue etc. Favoritos continuam.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Zerar')),
                          ],
                        ),
                      );
                      if (ok == true) store.resetProgress();
                    },
                  ),
                ),
              ),
              const _Card(
                title: 'Créditos e avisos',
                child: Text(
                  'Guia do Vale é um app de fã, não oficial e sem fins comerciais.\n\n'
                  '• Stardew Valley e seus personagens, imagens e sprites pertencem a ConcernedApe.\n'
                  '• Dados estruturados: pacote "stardew-valley-data" (licença MIT).\n'
                  '• Textos opcionais da wiki: Stardew Valley Wiki, licença CC BY-NC-SA 3.0.\n'
                  '• Stardew Web API, de zunderscore e contribuidores (licença MIT): integração opcional com o jogo, com o fork de descoberta local do Guia do Vale.\n'
                  '• Valores baseados na versão 1.6 do jogo e podem mudar em atualizações.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApiCard extends StatefulWidget {
  final String initialUrl;
  const _ApiCard({required this.initialUrl});

  @override
  State<_ApiCard> createState() => _ApiCardState();
}

class _ApiCardState extends State<_ApiCard> {
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = AppScope.of(context).api;
    final store = AppScope.of(context).store;
    final theme = Theme.of(context);
    final snap = api.snapshot;
    final busy = api.linking || api.scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conecte a Stardew Web API para trazer automaticamente a data do jogo, '
          'os itens da mochila e as amizades que já chegaram ao máximo. '
          'A API é local e opcional: sem ela, o app continua funcionando como antes.',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              api.connected ? Icons.check_circle_rounded : Icons.link_off_rounded,
              color: api.connected ? Colors.green : theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    api.linking
                        ? 'Conectando…'
                        : api.connected
                            ? 'Conectado${api.baseUrl.isNotEmpty ? ' a ${api.baseUrl}' : ''}'
                            : 'Não conectado. O app continua funcionando com os dados offline.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (api.connected && snap != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'No jogo: ${seasonEmojis[snap.world.season]} '
                      '${seasonNames[snap.world.season]} ${snap.world.day}'
                      '${snap.world.weather.isNotEmpty ? ' · ${snap.world.weather}' : ''}'
                      '${snap.world.farmName.isNotEmpty ? ' · ${snap.world.farmName}' : ''}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (api.error != null && snap == null) ...[
          const SizedBox(height: 8),
          Text(api.error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : _scan,
              icon: api.scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find_rounded),
              label: Text(api.scanning ? 'Procurando…' : 'Procurar na rede'),
            ),
            if (api.connected)
              OutlinedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Desconectar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          enabled: !busy,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _connect(),
          decoration: const InputDecoration(
            labelText: 'Endereço manual da API',
            hintText: 'http://192.168.0.10:7882',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.dns_rounded),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: busy ? null : _connect,
            icon: const Icon(Icons.cable_rounded),
            label: const Text('Conectar'),
          ),
        ),
        if (api.connected) ...[
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: store.apiAuto,
            onChanged: (v) => api.setAuto(v),
            title: const Text('Modo automático'),
            subtitle: const Text('Atualiza a data e o progresso a cada minuto e ao voltar ao app.'),
          ),
          if (api.lastSync != null)
            Text(
              'Última sincronização: ${_formatDate(api.lastSync!)}',
              style: theme.textTheme.bodySmall,
            ),
          if (api.lastAutoMarked > 0)
            Text(
              '${api.lastAutoMarked} ficha(s) marcada(s) automaticamente nesta sincronização.',
              style: theme.textTheme.bodySmall,
            ),
        ],
        if (!api.connected && !busy) ...[
          const SizedBox(height: 4),
          Text(
            'Dica: a API anuncia o serviço "_stardewapi._tcp" na rede local. '
            'Se a busca não encontrar, informe o IP do computador e a porta 7882.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _scan() async {
    final api = AppScope.of(context).api;
    final servers = await api.discover();
    if (!mounted) return;

    if (servers.isEmpty) {
      _snack(api.error ?? 'Nenhum servidor encontrado. Confira se o jogo está aberto e a API instalada.');
      return;
    }

    final server = servers.first;
    _url.text = server.url;
    final ok = await api.connect(server.url, name: server.name);
    if (!mounted) return;
    if (!ok) {
      _snack(api.error ?? 'Encontrei o servidor, mas não consegui conectar.');
    } else if (api.error != null) {
      _snack(api.error!);
    } else {
      _snack('API conectada. Progresso sincronizado.');
    }
  }

  Future<void> _connect() async {
    final api = AppScope.of(context).api;
    final raw = _url.text.trim();
    if (raw.isEmpty) {
      _snack('Informe o endereço da API ou use "Procurar na rede".');
      return;
    }

    final ok = await api.connect(raw);
    if (!mounted) return;
    if (!ok) {
      _snack(api.error ?? 'Não foi possível conectar.');
    } else {
      _url.text = api.baseUrl;
      if (api.error != null) {
        _snack(api.error!);
      } else {
        _snack('API conectada. Progresso sincronizado.');
      }
    }
  }

  void _disconnect() {
    AppScope.of(context).api.disconnect();
    _url.clear();
    _snack('API desconectada. O app segue com os dados offline.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: parchment(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
