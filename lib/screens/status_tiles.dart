part of 'status_screen.dart';

/// Objetivo vindo do conselheiro, desenhado como entrada do diário de missões.
class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        height: 1.2,
        color: Color(0xFF6B5238),
      ),
    );
  }
}

class _NoSnapshot extends StatelessWidget {
  final GameApi api;
  final VoidCallback onClose;
  const _NoSnapshot({required this.api, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final message = !api.connected
        ? 'A conexão com o servidor caiu. Feche esta tela e conecte de novo em Sobre e ajustes.'
        : (api.error?.trim().isNotEmpty == true
              ? api.error!
              : 'Servidor conectado. Carregue um save no Stardew Valley para a API enviar os dados do jogador.');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _GamePanel(
          accent: _gold,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌾', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              const Text(
                'SINAL DO JOGO',
                style: TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.3, color: _ink),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (api.connected)
                    FilledButton.icon(
                      onPressed: () => api.sync(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar de novo'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Fechar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
