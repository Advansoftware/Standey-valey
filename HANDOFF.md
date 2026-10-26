# HANDOFF — Guia do Vale (enciclopédia de Stardew Valley, Flutter/Android)

> Arquivo de continuação para qualquer IA/pessoa que pegar o projeto. **Atualize este arquivo
> a cada etapa concluída** (marque `[x]`, ajuste "Próximos passos") e faça commit + push.
> Última atualização: 2026-10-26 (sessão 8 — redesenho completo no estilo do jogo, Meu Status com HUD ao vivo via WebSocket e release v1.5.0).

## 1. Objetivo (pedido do dono, Bruno)

App Android em **Flutter**, **100% em português do Brasil**, que funcione como uma **enciclopédia/Pokédex de
Stardew Valley** para quem **começou a jogar hoje**: saber *o que é o quê* e *como progredir*.

Requisitos explícitos do dono:
- UX/UI "perfeitos", intuitivo, completo. Estilo **Pokédex** (cartões numerados com sprite, nome, tipo, progresso).
- **Todas as entradas com imagem — os sprites/assets reais do jogo**.
- **Tudo embutido no projeto, nada online em runtime** (sem baixar imagem/dado da internet).
- **IA local com RAG** sobre todo o conteúdo. Única coisa online aceitável: baixar o modelo da IA uma vez.
- Repositório: https://github.com/Advansoftware/Standey-valey (nome com o typo "Standey" é o do dono; manter).
- **Subir no GitHub a cada etapa.** Build do APK pelo dono no **Codemagic** (`codemagic.yaml` pronto).
- Comunicação do dono: direta e concisa.
- Regras do dono nesta sessão: **nunca criar arquivo Dart com mais de 1000 linhas** (quebrar em vários
  arquivos); **não perguntar nada**, decidir e seguir; **deixar o app pronto e testado**; **publicar a
  release v1.0.0 no GitHub** com a descrição do que tem na primeira versão.

## 2. Estado atual (sessão 8)

**Sessão 8 (v1.5.0 e v1.5.1):** a v1.5.1 corrige o atualizador (APK salvo na pasta `cache`, que o
FileProvider libera; pedido da permissão "Instalar apps desconhecidos"; versão lida do Android;
notas da versão em Markdown). Versões até a 1.5.0 precisam instalar a 1.5.1 manualmente uma vez.

**Sessão 8 (v1.5.0):** o app inteiro foi redesenhado no estilo da interface do Stardew Valley.
- `lib/widgets/stardew_ui.dart` reúne as peças reutilizáveis: `SdvFrame` (moldura de madeira em
  pixel art), `SdvSlot`, `SdvHearts`, `SdvLevelBoxes`, `SdvVitalBar`, `SdvButton`, `SdvIconButton`,
  `SdvTitleBoard`, `SdvProgressBar` e `SdvNavBar`. Use sempre essas peças em telas novas.
- `app_theme.dart` aplica o tema (papel, madeira, fonte PixelifySans em títulos e botões); o modo
  escuro é a "noite" de madeira escura. `Parchment` desenha a moldura do jogo.
- **Meu Status** virou uma HUD de jogo (`status_hud.dart`, `status_menu.dart`, `status_live_map.dart`):
  relógio com mostrador e hora do jogo, contador de ouro, barras E/V, barra de ferramentas, minimapa
  ao vivo, mensagens dos eventos e menu com abas (Conselheiro, Inventário, Habilidades, Social,
  Diário, Conquistas, Mapa). Paisagem em 3 colunas; retrato em coluna única.
- **WebSocket corrigido**: o mod só aceita `/events` e envia `{"event","data"}` em camelCase
  (`lib/game_events.dart`). A hora do jogo só existe no evento `TimeChanged`.
- O mock da skill `android-phone-test` agora simula o WebSocket (`/events`) com relógio, troca de
  local, mochila, níveis e amizades.
- O modelo próprio (Espírito do Vale) recebe só a pergunta, sem RAG (`buildPrompt`); os outros
  modelos usam RAG. O treino do modelo fica em `C:/modelo/v2` (ver a skill `treinar-ia`).

### Sessão 6

O que existia até a sessão 5 está **funcionando e testado**. A sessão 6 entregou a tela
**Meu Status**, um dashboard imersivo para usar com o celular deitado ao lado do PC. O item central
da barra inferior só abre quando a API está conectada; sem conexão, mostra cadeado e um aviso com
atalho para conectar. O Calendário saiu da barra e virou atalho no cabeçalho da Home.

A tela usa dados de `/world`, `/players/main` e `/players/main/inventory`, tem duas colunas no
landscape, uma no portrait, mantém a tela ligada e restaura as barras do sistema ao fechar. O
próximo passo é calculado localmente; a IA local só roda no botão **AJUDA** e devolve até 3 cartões
de objetivo.

| Item | Situação |
|---|---|
| `flutter analyze` | ✅ sem avisos (sessão 6) |
| `flutter test` | ✅ 45 testes passando (37 anteriores + 8 novos) |
| `flutter build apk --release --target-platform android-arm64` | ✅ APK 1.3.0+4 (70 MB) |
| Celular físico Samsung SM-G781B (Android 13) | ✅ Meu Status testado em portrait e landscape |
| Limite de 1000 linhas por arquivo Dart | ✅ tela dividida em 4 arquivos, todos abaixo do limite |
| Conteúdo | ✅ 565 entradas, 16 categorias, **todas com imagem do jogo** |
| Wiki offline | ✅ ~1.300 páginas da wiki PT dentro do app (`assets/wiki/pages.json.gz`) |
| Mapa do Vale | ✅ 16 lugares, norte/sul, zoom, filtros e ficha por lugar |
| IA local | ✅ 6 modelos na tela do Assistente; **Gemma 4 E4B** como padrão (RAM 8 GB+) |
| Stardew Web API (fork 0.7.0) | ✅ release publicada com mDNS `_stardewapi._tcp` e encaminhador TCP na 7882 |
| App: card "Servidor do jogo (API)" | ✅ descoberta, URL manual, sincronização e offline validados no celular |
| GitHub | ✅ `main` com as releases `v1.1.0`, `v1.2.0` e a API `0.7.0`; `v1.3.0` nesta sessão |

Detalhe do ambiente: o sandbox **tem** Flutter 3.47.6 (snap), Dart 3.13.5, Android SDK 36,
emulador com KVM, Python 3, node/npm, PIL e ImageMagick. A **API da wiki** (`api.php`) é bloqueada pelo
Cloudflare, mas as *short URLs* (`https://pt.stardewvalleywiki.com/Cenoura`) funcionam — o scraper usa
essas.

## 3. Comandos para fazer tudo funcionar

```bash
git clone https://github.com/Advansoftware/Standey-valey.git && cd Standey-valey

# 1) Dados + imagens do jogo (precisa de node/npm e python3)
bash tools/seed/fetch_dataset.sh      # baixa stardew-valley-data -> tools/seed/.cache/package
python3 tools/seed/build_seed.py      # gera assets/data/*.json e copia as imagens para assets/img/
python3 tools/seed/verify.py          # confere ids duplicados, imagens ausentes e sobras de inglês

# 2) Wiki offline (usa as short URLs da wiki em português)
python3 tools/scrape_wiki.py          # assets/wiki/pages.json.gz + assets/data/names_pt.json

# 3) Android
bash tools/setup_android.sh           # cria android/ se não existir, minSdk 30, permissão INTERNET
bash tools/setup_android_visual.sh    # cor do splash/fundo (claro e escuro)
python3 tools/make_icon.py            # ícone do app a partir de um sprite do jogo

# 4) Dependências, análise, testes
flutter pub get
flutter analyze
flutter test

# 5) APK arm64 (build local; o GitHub Actions do fork não é usado)
flutter build apk --release --target-platform android-arm64

# 6) API (opcional) — só se for mexer no mod; build completo na seção 7
git submodule update --init --recursive

# 7) Celular físico de testes (skill/android-phone-test)
.opencode/skills/android-phone-test/scripts/phone.sh doctor
.opencode/skills/android-phone-test/scripts/phone.sh install
.opencode/skills/android-phone-test/scripts/phone.sh launch
```

## 4. Mapa do repositório

```
pubspec.yaml                    deps: shared_preferences, flutter_edge_ai, flutter_edge_ai_litertlm
lib/main.dart                   monta o app (AppScope + MaterialApp, tema do store)
lib/models.dart                 Category, Entry (com gallery), CalendarEvent
lib/repository.dart             lê assets/data/*.json e aplica os nomes da wiki
lib/store.dart                  favoritos, coletados, checklist, data do jogo, tema, IA, API
lib/search.dart                 BM25 local (acentos, stopwords, prefixo) + índice da wiki
lib/ai_service.dart             wrapper flutter_edge_ai (install/ask) + prompt RAG + cleanAnswer
lib/ai_models.dart              catálogo dos 6 modelos de IA (nome, tamanho, RAM, URL)
lib/game_api.dart               cliente da API local, descoberta NSD e sincronização
lib/game_status.dart            regras do próximo passo, clima, localização, prompt e parser da IA
lib/app_theme.dart              tema "pergaminho" claro/escuro + parchment() + widget Parchment
lib/app_scope.dart              InheritedWidget com store/repo/search/ai/api
lib/widgets/common.dart         EntryImage, DexCard, EntryTile, TagPill, SectionTitle
lib/widgets/markdown_lite.dart  Markdown leve para o chat (negrito, itálico, listas, código)
lib/widgets/assistant_*.dart    cartão de download do modelo e balões do chat
lib/map_data.dart               16 lugares do mapa, regiões, coordenadas e textos curtos
lib/screens/                    home, encyclopedia/category, detail, calendar, search,
                                map, assistant, favorites, about, shell (NavigationBar)
lib/screens/status_screen.dart  rota/estado da tela Meu Status
lib/screens/status_panels.dart  painéis do dashboard (vitais, mapa, local, missões, agenda…)
lib/screens/status_widgets.dart peças visuais (fundo, painéis, pills, mapa, pin)
lib/screens/status_tiles.dart   cartões de objetivo, missão, item, habilidade, amizade e conquista
assets/data/*.json              16 categorias + index.json + names_pt.json
assets/img/                     920+ sprites do jogo (nome achatado) + map_valley.png
assets/wiki/pages.json.gz       corpus da wiki PT para o RAG
assets/fonts/PixelifySans.ttf   fonte pixel da tela Meu Status (+ licença OFL)
tools/seed/                     geradores de conteúdo (data_core, data_guia, enrich, utility…)
tools/seed/utility.py           gera "Utilidade" e preços nas fichas
tools/scrape_wiki.py            baixa a wiki PT
tools/make_icon.py              gera o ícone do app
tools/setup_android*.sh         preparação do projeto Android
android/.../MainActivity.kt     canais guia_do_vale/nsd (NsdManager) e guia_do_vale/display (tela ligada)
android/.../AndroidManifest.xml INTERNET + usesCleartextTraffic (HTTP na rede local)
StardewWebApi/                  submódulo do fork da API 0.7.0 (mDNS + TCP 7882)
.opencode/skills/android-phone-test/
                                skill + helper ADB para o celular SM-G781B
test/app_test.dart              testes de interface (todas as telas)
test/search_test.dart           testes da busca
test/game_api_test.dart         testes do cliente/sincronização da API
test/game_status_test.dart      testes do próximo passo, parser e prompt do conselheiro
codemagic.yaml                  build do APK no CI (não usado no fork)
```

## 5. Regras do dono (obedecer)

1. **Nenhum arquivo Dart acima de 1000 linhas.** Quebrar widgets em arquivos próprios.
2. **Não perguntar nada** — decidir e seguir, e registrar o progresso em `PROGRESSO.md`.
3. **Nada online em runtime (internet).** Exceções: o download do modelo de IA (uma vez) e a
   integração **opcional** com a API local, na mesma rede. Sem ela, o app funciona offline.
4. **Commitar e subir no GitHub a cada etapa** concluída.
5. **Mensagens de commit em PT-BR.**

## 6. O que já está feito (marcar conforme for avançando)

- [x] **A. Gerador v2 com imagens reais** — 16 categorias, 565 entradas, sprites do jogo, galeria de estágios.
- [x] **B. Telas** — todas as telas existem, testadas e sem erros de layout.
- [x] **C. Android + Codemagic** — `android/` versionada, `codemagic.yaml` pronto, ícone e splash próprios.
- [x] **D. Wiki offline** — `tools/scrape_wiki.py` baixa ~1.300 páginas; o app lê e busca nelas.
- [x] **E. Testes e README** — 30 testes (telas, mapa, busca e guias); README reescrito.
- [x] **F. Revisão de conteúdo** — nomes sem tradução agora vêm da wiki; todas as entradas com imagem.
- [x] **G. IA local com escolha de modelo** — 6 modelos, Gemma 4 E4B como padrão.
- [x] **H. Release v1.0.0 no GitHub** — com o APK anexado e a descrição do que tem na primeira versão.
- [x] **I. Mapa do Vale** — imagem real, 16 lugares, norte/sul, zoom, filtros e ficha com atalhos.
- [x] **J. Guia de lavoura** — rega, espantalho, treliça, árvores frutíferas, aspersores e fim de estação.
- [x] **K. Lista padrão e chat formatado** — categorias em lista; Markdown no chat; README com a seção de IA.
- [x] **L. Release v1.1.0 no GitHub** — APK arm64 com mapa, guia de lavoura e correções.
- [x] **M. Stardew Web API (fork 0.7.0)** — mDNS `_stardewapi._tcp`, encaminhador TCP na 7882 e card
      "Servidor do jogo (API)" no app, com busca NSD, URL manual e sincronização.
- [x] **N. Publicar a API e o app** — API 0.7.0 e app 1.2.0+3 publicados; descoberta, sincronização,
      timer e offline validados no celular físico com API mock. Falta repetir com save real.
- [x] **O. Skill do celular de testes** — `.opencode/skills/android-phone-test` com passos de pareamento,
      conexão, instalação, screenshots e solução de problemas via ADB sem fio.
- [x] **P. Meu Status imersivo** — item central na barra (só com API conectada), tela cheia em
      landscape/portrait, mapa com pin, vitais, missões, mochila, habilidades, amizades e conquistas;
      próximo passo local e IA somente no botão AJUDA, com resposta em cartões.
- [x] **Q. Release v1.3.0** — APK arm64 publicado com a tela Meu Status.

## 7. Integração com a Stardew Web API (sessão 5)

Integração **opcional**: o app não depende da API para abrir nem para o conteúdo. A API só fornece
data, mochila e amizades; o resto continua manual. O app segue 100% funcional offline.

### Estrutura

- `StardewWebApi/` — submódulo Git apontando para `https://github.com/Advansoftware/StardewWebApi`
  (fork do original `https://github.com/zunderscore/StardewWebApi`, MIT). Manifest `0.7.0`.
  - `src/Server/MdnsAdvertiser.cs` — anuncia `_stardewapi._tcp` na porta 7882, com TXT `path`,
    `version` e `game`.
  - `src/Server/LanForwarder.cs` — aceita conexões nos IPv4 da rede na porta 7882 e encaminha para
    `127.0.0.1:7882`; evita URLACL e não exige rodar o jogo como administrador.
  - `src/ModEntry.cs` e `src/Server/WebServer.cs` — sobem o mDNS e o encaminhador junto com a API.
  - `src/StardewWebApi.csproj` — .NET 6, `Makaretu.Dns.Multicast` e `BundleExtraAssemblies` para
    incluir as DLLs de mDNS no zip.
- `lib/game_api.dart` — `GameApi` (ChangeNotifier): URL salva, descoberta, health check em
  `/api/v1/mods`, sincronização, timer de 60 s e retomada ao voltar ao app.
- `android/app/src/main/kotlin/br/com/advansoftware/stardew_guia/MainActivity.kt` — MethodChannel
  `guia_do_vale/nsd`, `NsdManager` com `_stardewapi._tcp.`, timeout de 5 s e resolução dos serviços.
- `android/app/src/main/AndroidManifest.xml` — `usesCleartextTraffic="true"` para HTTP local.
- `lib/store.dart` — `apiUrl`, `apiName`, `apiAuto` e `apiLastSyncMs` em `shared_preferences`.

### Como buildar a API

Precisa de **.NET 6 SDK**. Não precisa do jogo instalado: use as referências públicas. Nesta
máquina o SDK foi baixado em `/tmp/opencode/dotnet` e as referências em `/tmp/opencode/refasm`.
O GitHub Actions do fork **não é usado**; o zip da 0.7.0 foi gerado localmente.

```bash
# na raiz do app
git submodule update --init --recursive

# referências do jogo/SMAPI
git clone --depth 1 --branch SDV1.6.3-SMAPI4.0.2 \
  https://github.com/StardewModders/mod-reference-assemblies.git /tmp/opencode/refasm

export DOTNET_ROOT=/tmp/opencode/dotnet
export PATH="$DOTNET_ROOT:$PATH"

dotnet restore StardewWebApi/src/StardewWebApi.csproj -p:GamePath=/tmp/opencode/refasm
dotnet build StardewWebApi/src/StardewWebApi.csproj -c Release \
  -p:GamePath=/tmp/opencode/refasm
```

O zip sai em `StardewWebApi/src/bin/Release/net6.0/StardewWebApi 0.7.0.zip`. Descompacte em
`Mods/StardewWebApi/` (o zip já traz as DLLs de mDNS e o `INSTALL.md`).
A release publicada é
https://github.com/Advansoftware/StardewWebApi/releases/tag/0.7.0
(asset `StardewWebApi-0.7.0.zip`, SHA-256 `fb535d823751e17320164f63d13b67ad3bf276a62920d008b503a47ccd25839b`).

### Como rodar o app

A API não é necessária:

```bash
flutter pub get
flutter run
```

Para testar a integração, o app precisa estar em um Android (a descoberta usa `NsdManager`). Em
outras plataformas o canal não existe e o card mostra a mensagem de busca indisponível; a URL manual
continua sendo a saída. Com o jogo aberto, use a engrenagem → **Sobre e ajustes** → **Servidor do
jogo (API)**.

### Como testar a descoberta na rede

1. Suba o jogo com SMAPI e **carregue um save**. Confira no PC:
   `curl http://localhost:7882/api/v1/mods` (funciona sem save) e
   `curl http://localhost:7882/api/v1/world` (só com save).
2. De outro computador na mesma rede: `curl http://IP-DO-PC:7882/api/v1/mods`. Se falhar, veja o
   firewall (porta 7882, rede privada) e o isolamento de clientes do Wi-Fi.
3. Para ver o anúncio: `avahi-browse -rt _stardewapi._tcp` (Linux) ou
   `dns-sd -B _stardewapi._tcp` (macOS/Windows com Bonjour).
4. No celular, na mesma rede: **Procurar na rede**. A busca dura ~5 s. Se não achar, informe
   `http://IP-DO-PC:7882` e conecte.
5. Confirme a sincronização: a tela mostra a data do jogo, o status e "N ficha(s) marcada(s)".
   Coloque um peixe/mineral na mochila e um aldeão com 10 corações (14 se casado) e confira as fichas.
6. Teste o modo automático (espera de 1 min e volta ao app) e o disconnect/reconnect (a URL fica
   salva). Depois marque uma ficha à mão, sincronize sem o item e confirme que ela **continua marcada**.
7. Teste sem a API: feche o jogo, abra o app e confirme que ele funciona offline.

### Validação feita nesta sessão

- **Celular físico:** Samsung **SM-G781B**, Android 13, tela 1080x2400, na mesma rede do PC.
- **Descoberta:** `adb`/`NsdManager` encontrou o anúncio `_stardewapi._tcp` e o app mostrou
  `Conectado a http://192.168.3.7:7882`.
- **Sincronização:** com uma API mock em `0.0.0.0:7882`, o app chamou `/api/v1/mods`, `/world`,
  `/players/main` e `/players/main/inventory`, atualizou a data para **Verão 15**, mostrou
  `Sunny · Fazenda Teste` e marcou as fichas de inventário/amizades.
- **Timer:** uma segunda rodada de `/world`, `/players/main` e `/players/main/inventory` chegou
  após 60 segundos, confirmando o modo automático.
- **Offline:** o app continuou abrindo e navegando sem a API; as marcações manuais não foram desfeitas.

**Ainda recomendado:** repetir com um **save real** do Stardew Valley, conferindo o formato dos
endpoints reais e o firewall do PC. O emulador pode não enxergar o mDNS do host; use o celular.

### Como conectar o celular de testes

O passo a passo completo está na skill do projeto:

```text
.opencode/skills/android-phone-test/SKILL.md
.opencode/skills/android-phone-test/scripts/phone.sh
```

Resumo: ative **Depuração sem fio**, pareie com `adb pair IP:PORTA_CODIGO CODIGO`, conecte com
`adb connect IP:PORTA_CONEXAO` e use sempre `-s SERIAL`. A porta de pareamento muda a cada
pareamento; a de conexão é a mostrada na tela principal de depuração sem fio.

### Limitações (não tentar contornar sem mudar a API)

- A API expõe **data atual, jogador/inventário e relações**. Não há histórico de peixes (só o que
  está na mochila agora), colheitas plantadas, museu, monstros ou pacotes concluídos. Essas fichas
  continuam manuais.
- O inventário prova apenas o que está na mochila agora; por isso a sincronização só marca peixes,
  coletáveis, minerais, culinária e ferramentas.
- A sincronização **só acrescenta** progresso (`Store.addCollected`); nunca desmarca.
- Os endpoints de mundo/jogador/inventário exigem um save carregado (erro 400 "no save loaded").
- A porta é fixa em **7882** e o tráfego é HTTP sem TLS. Use só em rede confiável e não exponha a
  porta na internet.
- mDNS pode falhar com isolamento de clientes, VPN ou firewall. A URL manual é o fallback.
- Não há sincronização com o app fechado; o modo automático roda a cada 60 s e ao voltar ao app.

## 8. Releases publicadas

| Versão | Link | Asset | SHA-256 |
|---|---|---|---|
| App 1.5.1+9 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.5.1 | `guia-do-vale-1.5.1.apk` (arm64) | `879a865fbada2315e07fd5276cb4be7224daa7d54f4b10dcd8dafeef0b997186` |
| App 1.5.0+8 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.5.0 | `guia-do-vale-1.5.0.apk` (arm64) | `7358b9aba38cad3d71397d808f80012acf139c7d3c4c23f31c057aa476c0d981` |
| App 1.3.0+4 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.3.0 | `guia-do-vale-1.3.0.apk` (arm64) | `df81e2cc9c88308b47bf7083b4fa0bd3d42d1c3d3136806f290fbca5accd7bbf` |
| App 1.2.0+3 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.2.0 | `guia-do-vale-1.2.0.apk` (arm64) | `a3973894a3d14ee5b749d7e5f0091603072fa99449b159c48d1e8a747da8c57b` |
| API 0.7.0 | https://github.com/Advansoftware/StardewWebApi/releases/tag/0.7.0 | `StardewWebApi-0.7.0.zip` | `fb535d823751e17320164f63d13b67ad3bf276a62920d008b503a47ccd25839b` |

O APK é arm64 (Android 11+) e usa a assinatura de desenvolvimento do projeto. O zip da API inclui
`INSTALL.md` com requisitos, caminhos de instalação e o link da última versão do SMAPI.

## 9. Ideias para as próximas versões (opcional)

- Modo "Primeiro ano": checklist de metas por estação.
- Conquistas (`achievements.json` tem imagens), receitas de fabricação (`crafting.json`),
  armas/anéis/chapéus, missões (`quests.json`), monetário e karma.
- Comparador de lucro por cultura considerando irrigação e fertilizante.
- Busca por voz no assistente.
