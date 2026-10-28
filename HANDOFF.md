# HANDOFF — Guia do Vale (enciclopédia de Stardew Valley, Flutter/Android)

> Arquivo de continuação para qualquer IA/pessoa que pegar o projeto. **Atualize este arquivo
> a cada etapa concluída** (marque `[x]`, ajuste "Próximos passos") e faça commit + push.
> Última atualização: 2026-10-28 (sessão 10 — provedores web de IA, troca de modelo, RAG melhor e release v1.6.0).

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

## 2. Estado atual (sessão 10)

**Sessão 10 (v1.6.0, IA web e troca de modelo):**
- **Provedores web**: OpenAI (API Responses), Google Gemini (`streamGenerateContent`) e Anthropic
  (Messages), em `lib/ai_cloud.dart`. A chave é digitada no app e fica nas preferências do celular;
  a lista de modelos vem da API do provedor (filtra áudio, imagem, embeddings, versões com data etc.)
  e fica salva. Botão "Testar modelo". Modelo sugerido: o "mini" mais novo da OpenAI, `gemini-2.5-flash`
  ou o Haiku.
- **Configurar IA** (`lib/screens/ai_settings_screen.dart`): escolhe o provedor (rádio) e configura
  cada um. Abre pelo ícone no topo do Assistente e por Sobre e ajustes. O chat não tem mais faixa de
  "IA em uso" (o dono pediu).
- **Troca de modelo local corrigida**: antes, o cartão de instalação sumia depois do primeiro download
  e o modelo nunca mais mudava. Agora o `Store` guarda vários modelos baixados (`ailocal`, id → URL,
  com migração de `aiok/aimodel/aiurl`) e o `AiService.ensureLocalActive` reativa o arquivo pelo
  `fromNetwork(url)` (idempotente: "Already installed", sem rede). Dá para apagar modelos.
- **Bug de tela que não redesenhava**: widgets `const` que leem o `AppScope` não reconstroem, porque
  o `AppScope` não notifica. Os painéis da IA escutam `Store` e `AiService` com `ListenableBuilder`
  próprio. Use o mesmo padrão em telas novas.
- **RAG do chat** (`lib/ai_rag.dart`): tira palavras de conversa, põe primeiro as páginas cujo nome
  aparece na pergunta, rebaixa falas de moradores, usa a pergunta anterior e as páginas dela nas
  continuações e, na web, manda até 24 mil caracteres com os trechos vizinhos e as células das
  tabelas separadas por " | ". `test/rag_test.dart` tem as perguntas reais do dono (fornalha,
  Feira, argila, galinheiro, isca).
- **Save no chat**: com a API do jogo conectada, `saveSummary` (extraído de `buildStatusPrompt`, mesmo
  texto) vai junto da pergunta para os provedores web e para os modelos locais genéricos. O Espírito
  do Vale continua recebendo só a pergunta.
- **Meu Status**: missão, dicas e passos do Conselheiro são tocáveis e abrem um quadro no estilo do
  jogo (`status_ai_explain.dart`), sem sair da tela e sem chat. O AJUDA só libera o plano depois de
  preparar a explicação de cada passo e da missão, então o quadro abre já completo. O diálogo do
  item mostra os campos da ficha (utilidade, preço, onde achar) e o valor da pilha, sem o "ID técnico".
- Respostas sem pergunta de volta nem oferta no final ("se quiser, me diga…"), a pedido do dono.
- Testado no SM-G781B com a chave real da OpenAI (`gpt-5.4-mini` e `gpt-5.4-nano`), com o mock do jogo
  e com o Espírito do Vale. Gemini e Anthropic só foram testados contra o servidor simulado
  (`test/ai_cloud_test.dart`), por falta de chave.

**Sessão 9 (resumo das partes abaixo):**

**Sessão 9, parte 4 (v1.5.4, celular deitado e tablet):** deitado (ou tablet), a barra de baixo vira
barra lateral (`SdvNavBar(vertical: true)` em `shell.dart`). As telas usam `ContentWidth`
(`widgets/common.dart`) para não esticar o texto; grades usam `SliverGridDelegateWithMaxCrossAxisExtent`
(Enciclopédia em 3 colunas deitado e 5 no tablet); listas de categoria viram 2–3 colunas a partir de
700 px; na Home, Mapa e "Hoje na fazenda" ficam lado a lado. Testado no SM-G781B deitado e no tablet
SM-P615 (inclusive Meu Status com o mock). Cartões das categorias e eventos do Calendário com
espaço interno.

**Sessão 9, parte 3 (v1.5.3, leitura da wiki):** a página da wiki deixou de ser texto corrido.
`lib/wiki_article.dart` entende a estrutura do texto raspado (títulos, índice, ficha "Informações",
listas, barras de navegação, tabelas achatadas) e `lib/screens/wiki_page_screen.dart` desenha no estilo
do jogo: cabeçalho com sprite e "Abrir ficha" quando a página é de algo da enciclopédia, índice clicável
(rola até a seção) e botão de voltar ao índice, seções em placa de madeira, presentes em etiquetas,
falas em caixa de diálogo com retrato, tabelas em cartões (sem rótulo por coluna, porque a tabela
achatada às vezes perde células), agendas como linha do tempo, valores por qualidade (energia,
preços por profissão) em grade com as estrelas normal/prata/ouro/irídio e o Lago de Peixes como tabela
de capacidade. Cartões da Home e da enciclopédia (`DexCard`, `EntryTile`, "Comece aqui") ganharam
espaço interno para o texto não encostar na moldura. Só muda a exibição: o texto do índice
de busca e do RAG é o mesmo. `test/wiki_article_test.dart` lê as 1.300 páginas e confere que nenhuma
palavra some.

**Sessão 9, parte 2 (correções do app; treino pausado a pedido do dono):**
- Aviso "Conecte ao servidor do jogo" virou `showSdvNotice` (`lib/widgets/sdv_notice.dart`): aviso no
  topo, no estilo do jogo, que some sozinho em 4 s. No Flutter 3.47 um `SnackBar` com ação fica preso
  na tela (`persist` vira true); todos os SnackBars do app foram trocados pelo aviso novo.
- Busca da wiki: o resultado mostra a frase que combina com a busca, com as palavras destacadas, e a
  página abre rolada até o trecho (`lib/search_snippet.dart`, testes em `test/search_snippet_test.dart`).
- Português: 47 nomes que estavam em inglês nas fichas (38 peixes, culturas, pratos, monstros) e 126
  termos dentro dos textos (varas de pesca, Omnigeodo, Minas Perigosas, Carne de Inseto…) foram
  traduzidos com os nomes da wiki em português. Animais ganharam "Onde comprar" (Rancho da Marnie) ou
  "Como conseguir". Nomes de moradores vindos da API passam pela ficha (Wizard → Mago).
- **Treino pausado.** Decisão para quando voltar: Gemma 4 E2B (o `litert-torch export_hf` suporta, com
  `--externalize_embedder` e o template do `litert-community`, que já aceita mensagem em partes),
  treinado com 100% da wiki. `tools/modelo/gen_wiki_qa.py` gera perguntas de todos os 9.581 trechos
  com um modelo professor (vLLM). O piloto (`colab_piloto.py`) deu OOM na A100 de 40 GB no treino
  completo do E2B: usar AdamW 8-bit ou a A100 80 GB (`--high-mem`). H100 não está liberada na conta.
  A rodada 2 (Qwen3-0.6B) continua publicada; ela só cobre fichas e guias, não os detalhes da wiki.


**Sessão 9 (v1.5.2, Espírito do Vale rodada 2):** o modelo padrão agora é um **Qwen3-0.6B com
fine-tuning completo, sem RAG**, publicado em
`brunoantunes100/stardew-guia-qwen-0.5b/stardew_qwen_0.5b.litertlm` (mesmo nome de antes; SHA-256
`77c0ff9096bfe2dc244f39e7fed2d9ebde8ede79505883a766f78f70767e0656`, 620.991.120 bytes).
- Avaliação da rodada 2 (antes do celular): 99,3% dos fatos em paráfrases inéditas, 206/208 respostas
  perfeitas, 13/15 perguntas reais, 0 loops, Conselheiro 60/60 em formato e prioridade.
- Testado no SM-G781B: chat (Abigail, baiacu, carvalho, recusa fora do jogo) e Conselheiro do Meu Status
  com o mock. Download limpo pelo botão padrão do Hugging Face também testado.
- **Bug achado no celular:** o template do Qwen3 embutido pelo conversor só lê `message.content` como
  texto, e o `flutter_edge_ai` manda em partes; a pergunta chegava vazia. `tools/modelo/patch_template.py`
  troca o template (obrigatório a cada conversão).
- App: `ask(prompt, exact: true)` para o modelo próprio (topK 1, temperatura 0, 360 tokens).
  O tipo fica `ModelType.qwen`: com `qwen3` o plugin acrescenta " /no_think" à pergunta.
- Scripts de treino versionados em `tools/modelo/`; passo a passo na skill `.claude/skills/treinar-ia`.
  Resultados e checkpoints em `C:/modelo/rodadas` (fora do Git).
- **Próxima rodada (r3):** "como conseguir uma galinha" deve citar a Marnie (hoje responde a seção do
  guia sem ela) e, no Conselheiro, o aniversário do dia deve entrar como segundo item quando já há
  missão (hoje cai num presente para o amigo mais próximo). README atualizado com o processo.


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
| App 1.5.4+12 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.5.4 | `guia-do-vale-1.5.4.apk` (arm64) | `d035fb54dce35cd53c0c2bf565efe9a1a25a2353d7ebf62ff55f100d9635427d` |
| App 1.5.3+11 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.5.3 | `guia-do-vale-1.5.3.apk` (arm64) | `2f6027daf9b06f32e616efb298687fee52b4867d08af27229de58d385e7f5e28` |
| App 1.5.2+10 | https://github.com/Advansoftware/Standey-valey/releases/tag/v1.5.2 | `guia-do-vale-1.5.2.apk` (arm64) | `5d60375e55bc23bce2162b33881ca5acf3ea22bfd1948d2974c81a55f10c9100` |
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
