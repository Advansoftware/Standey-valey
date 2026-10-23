# Guia do Vale 1.4.0 — Atualizador Próprio e Estabilidade Completa

Nesta versão 1.4.0, o Guia do Vale ganha seu **próprio sistema de atualização integrado**, permitindo baixar e instalar futuras versões diretamente pelo aplicativo!

### 🌟 Destaques da Versão 1.4.0

1. **Atualizador Automático In-App (`UpdateScreen`)**:
   - **Verificação Automática & Manual**: Checagem de novas releases no GitHub na inicialização ou pelo botão "Buscar Atualização".
   - **Tela Temática com Visual do Vale**: Design imersivo em pergaminho e madeira.
   - **Informações da Versão Atual**: Toque no cartão da sua versão para ler todos os detalhes e notas da versão em execução.
   - **Download com Progresso Circular**: Barra circular de progresso com ícone central temático mostrando porcentagem e megabytes transferidos.
   - **Instalação Direta**: Dispara o instalador nativo do Android via FileProvider seguro.
   - **Assinatura Fixa**: O app agora instala diretamente por cima das versões anteriores sem exigir desinstalação prévia!

2. **Correção de Navegação (`NavigationBar`)**:
   - Resolvido o desalinhamento de abas onde clicar em "Assistente" ou "Favoritos" acabava selecionando incorretamente "Meu Status".

3. **Sincronização Instantânea com o Jogo**:
   - Reconhecimento acelerado do carregamento do save (`SaveLoaded` / `SaveCreated`).
   - Eliminação da mensagem de erro que persistia mesmo após o jogo já estar conectado e sincronizado.

4. **Estabilidade no Download de IA**:
   - Download de modelos locais de IA (Gemma 2B, Qwen, etc.) estabilizado, prevenindo fechamentos inesperados do app em versões recentes do Android (13/14).

---

*Compatível com Android 8.0+ (arquitetura arm64-v8a).*
**SHA-256 (`guia-do-vale-1.4.0.apk`)**: `57c45f974744e5bd22420981c5640947fc383c59d406b7b73d20e754c72fe58e`
