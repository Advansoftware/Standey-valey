# PROGRESSO — Guia do Vale

Registro de progresso da sessão (continuação do HANDOFF.md).
Atualizado a cada etapa concluída — serve de rede de segurança se algo falhar.

## Sessão 6 — Meu Status imersivo (v1.3.0)

| Etapa | Situação |
|---|---|
| Novo item central “Meu Status” na navegação inferior | ✅ substitui o Calendário; só libera com a API conectada |
| Bloqueio sem conexão | ✅ cadeado + aviso com atalho para conectar |
| Calendário como atalho no cabeçalho da Home | ✅ removido da barra inferior |
| Tela imersiva em tela cheia, com fechar e tela ligada | ✅ `immersiveSticky` + canal nativo `guia_do_vale/display` |
| Layout de uma tela só, duas colunas no landscape e uma no portrait | ✅ rolagem por coluna, sem abas |
| Mapa com pin “VOCÊ”, vitais, local, fazenda, missões, agenda, mochila | ✅ dados de `/world`, `/players/main` e inventário |
| Habilidades, amizades, equipamento e conquistas | ✅ painéis próprios com dados da API |
| Próximo passo determinístico | ✅ regras de missão, aniversário, festival, energia/vida, estação, clima e amizades |
| IA local só no botão **AJUDA** | ✅ nunca automática, sem timer/polling |
| Resposta da IA como cartões de objetivo | ✅ até 3 cartões com ação, lugar e motivo |
| Prompt e parser da IA | ✅ formato `AÇÃO | LUGAR | MOTIVO`, tolerante a markdown |
| Correção de `npc.type` texto/número | ✅ sincronização com o mock `"Villager"` funcionando |
| Limite de 1000 linhas por arquivo Dart | ✅ tela dividida em `status_screen`, `status_panels`, `status_widgets` e `status_tiles` |
| `flutter analyze` / `flutter test` | ✅ limpo; 45 testes passando (8 novos) |
| Teste físico no SM-G781B | ✅ portrait e landscape, cadeado/liberação, fechar, diálogo AJUDA e top bar |
| Release do app 1.3.0+4 | ✅ publicada com APK arm64 |

### O que entrou nesta etapa

- **Meu Status**: dashboard imersivo com visual de madeira/pergaminho, fundo do jogo e fonte
  `PixelifySans`. Reúne topo com jogador/fazenda/data, mapa com pin, vitais, localização, fazenda,
  missões, agenda, mochila, habilidades, amizades, equipamento e conquistas.
- **Acesso condicionado**: o item central mostra cadeado e explica que é preciso conectar. Com a
  API conectada, abre em rota fullscreen e mantém a aba anterior ao fechar.
- **Próximo passo primeiro**: o painel principal recomenda o que fazer e para onde ir. A regra é
  local e funciona sem modelo de IA.
- **Conselheiro sob demanda**: o botão AJUDA envia um snapshot curto para a IA local e transforma
  a resposta em até 3 cartões de objetivo. Sem modelo instalado, mostra um diálogo explicativo e
  o plano do guia continua valendo.
- **Tela deitada**: o layout em landscape usa duas colunas independentes; em portrait vira uma
  coluna. A tela permanece ligada enquanto a rota está aberta.
- **Robustez da API**: `npc.type` agora aceita texto (`Villager`), número ou ausência, sem quebrar
  a sincronização de amizades.

### O que falta

1. Repetir o teste da tela com um **save real** do Stardew Valley.
2. Instalar um modelo de IA no aparelho e validar a resposta real do conselheiro (o fluxo com
   resposta simulada já está coberto por teste).

### Arquivos desta etapa

- `lib/screens/status_screen.dart` — rota, estado, IA, topo e dashboard.
- `lib/screens/status_panels.dart` — painéis da tela (vitais, mapa, local, missões, agenda etc.).
- `lib/screens/status_widgets.dart` — peças visuais (fundo, painéis, pills, mapa, pin).
- `lib/screens/status_tiles.dart` — cartões de objetivo, missão, item, habilidade, amizade e conquista.
- `lib/game_status.dart` — regras do próximo passo, clima, localização, prompt e parser da IA.
- `lib/screens/shell.dart` — item central, bloqueio e navegação.
- `lib/screens/home_screen.dart` — atalho do calendário no cabeçalho.
- `android/.../MainActivity.kt` — canal `guia_do_vale/display` (`keepScreenOn`).
- `assets/fonts/PixelifySans.ttf` + licença OFL.
- `test/app_test.dart`, `test/game_status_test.dart` e `test/game_api_test.dart` — novos testes.

## Sessão 5 — Stardew Web API (v1.2.0 concluída)

| Etapa | Situação |
|---|---|
| Submódulo `StardewWebApi/` no fork `Advansoftware/StardewWebApi` | ✅ |
| API 0.7.0: anúncio mDNS/DNS-SD do serviço `_stardewapi._tcp` | ✅ código e release |
| API 0.7.0: encaminhador TCP para a porta 7882 sem URLACL/admin | ✅ código e release |
| Endpoints e dados existentes da API | ✅ sem mudanças |
| App: card "Servidor do jogo (API)" em Sobre e ajustes | ✅ |
| Descoberta automática na rede (`NsdManager` nativo no Android) | ✅ testada no SM-G781B via mDNS |
| URL manual, conectar/desconectar, modo automático e último sync | ✅ |
| Sincronização de data, inventário e amizades | ✅ testada em aparelho com API mock; save real ainda recomendado |
| `flutter analyze` / `flutter test` | ✅ limpo; 37 testes passando (7 novos da API) |
| Commit e release 0.7.0 do fork da API | ✅ release publicada com zip e `INSTALL.md` |
| Teste em aparelho físico na mesma rede | ✅ descoberta, conexão, sync, timer de 60 s e offline |
| Release do app 1.2.0+3 | ✅ publicada com APK arm64 |

### O que entrou nesta etapa

- **API como submódulo**: `StardewWebApi/` aponta para o fork
  https://github.com/Advansoftware/StardewWebApi (original de zunderscore, MIT). A versão do
  manifesto é **0.7.0**; os endpoints e os dados existentes não mudaram.
- **Descoberta local**: a API anuncia `_stardewapi._tcp` via mDNS/DNS-SD e um encaminhador TCP expõe
  o servidor de `localhost:7882` para a rede local, sem URLACL e sem rodar o jogo como administrador.
- **Card no app**: "Servidor do jogo (API)" em Sobre e ajustes, com busca automática na rede, campo de
  URL manual, conectar/desconectar, modo automático e status da última sincronização.
- **Sincronização só com o que a API expõe**: `/api/v1/world` (data), `/api/v1/players/main/inventory`
  (mochila) e `/api/v1/players/main` (amizades). Marca fichas de peixes, coletáveis, minerais,
  culinária e ferramentas que estão na mochila, e aldeões com amizade máxima.
- **Nunca desmarca**: a sincronização só acrescenta progresso; marcações manuais continuam.
- **Offline preservado**: o app abre e funciona normalmente sem a API ou com o jogo fechado.
- **Créditos**: Stardew Web API (zunderscore e contribuidores, MIT) e o fork do Guia do Vale no
  README e na tela Sobre.

### O que falta

1. Validar a sincronização com um **save real** do Stardew Valley no PC (o teste em aparelho usou uma
   API mock com o mesmo formato; os endpoints reais e o firewall do PC ainda devem ser conferidos).
2. Opcional: repetir o teste em uma rede com isolamento de clientes para documentar o fallback manual.

### Releases publicadas

- **API 0.7.0** — https://github.com/Advansoftware/StardewWebApi/releases/tag/0.7.0
  - Asset: `StardewWebApi-0.7.0.zip`
  - SHA-256: `fb535d823751e17320164f63d13b67ad3bf276a62920d008b503a47ccd25839b`
  - O zip inclui `INSTALL.md` com requisitos, caminhos e link da última versão do SMAPI.
- **App 1.2.0+3** — https://github.com/Advansoftware/Standey-valey/releases/tag/v1.2.0
  - Asset: `guia-do-vale-1.2.0.apk` (arm64)
  - SHA-256: `a3973894a3d14ee5b749d7e5f0091603072fa99449b159c48d1e8a747da8c57b`

### Arquivos desta etapa

- `lib/game_api.dart` — cliente HTTP, descoberta, sincronização e regras de marcação automática.
- `lib/screens/about_screen.dart` — card "Servidor do jogo (API)" e créditos.
- `lib/store.dart` — URL, nome, modo automático e data da última sincronização.
- `lib/main.dart` e `lib/app_scope.dart` — injeção do `GameApi` no app.
- `android/app/src/main/kotlin/br/com/advansoftware/stardew_guia/MainActivity.kt` — canal
  `guia_do_vale/nsd` com `NsdManager` (serviço `_stardewapi._tcp`).
- `android/app/src/main/AndroidManifest.xml` — `usesCleartextTraffic` para HTTP na rede local.
- `test/app_test.dart` — ajuste do teste da tela Sobre.
- `test/game_api_test.dart` — 7 testes do cliente, descoberta e regras de marcação.
- `.opencode/skills/android-phone-test/` — skill e helper para conectar, instalar e testar no celular
  físico via ADB/depuração sem fio.
- `StardewWebApi/` — submódulo do fork (mDNS, encaminhador TCP e manifest 0.7.0).

## Sessão 4 — mapa, lavoura e v1.1.0

| Etapa | Situação |
|---|---|
| Conteúdo: 565 entradas, 16 categorias, todas com imagem | ✅ |
| Guia `Lavouras sem mistério` (rega, espantalho, treliça, fim de estação) | ✅ |
| Mapa do Vale com imagem real, 16 lugares, pinos por região e zoom | ✅ |
| Ficha do lugar com o que tem, como chegar, dica e atalhos | ✅ |
| Categorias abrem em lista por padrão; botão de grade continua | ✅ |
| Chat da IA renderiza Markdown sem asteriscos literais | ✅ |
| Download da IA em segundo plano, com retomada ao abrir | ✅ |
| Builds com 10 GB de heap, cache e 16 workers | ✅ |
| README com a seção de IA local e de como o projeto foi feito | ✅ |
| `flutter analyze` / `flutter test` | ✅ 30 testes passando |
| Release `v1.1.0` no GitHub com APK arm64 | ✅ |

### O que entrou nesta versão

- **Mapa do Vale**: norte/sul, rosa dos ventos, filtros por região/iniciante, zoom e uma ficha curta
  para cada lugar. O mapa usa a imagem da wiki e aponta para as páginas já embutidas no app.
- **Guia de lavoura**: extraído das dúvidas da página "A Fazenda" sem repetir as fichas de culturas;
  explica o que gasta energia, quando a planta morre, corvos, espantalho, treliça, árvores frutíferas,
  aspersores e fertilizante.
- **Lista por padrão**: ao abrir Moradores, Culturas etc., a lista vem primeiro; o botão de grade
  continua no topo.
- **Chat formatado**: `MarkdownLite` próprio para negrito, itálico, código e listas.
- **README transparente**: documenta as técnicas de IA (RAG local, BM25, prompt, fallback e Markdown),
  o modelo gratuito usado no desenvolvimento e o processo de dados/testes/QA.

## Sessão 3 — do zero ao app publicado

| Etapa | Situação |
|---|---|
| Ambiente (Flutter 3.47.6, Android SDK, emulador com KVM) | ✅ |
| `flutter pub get` / `flutter analyze` | ✅ sem avisos |
| `flutter test` | ✅ 22 testes passando |
| `android/` gerado e versionado (minSdk 30, INTERNET, label) | ✅ |
| Ícone próprio do app + splash na cor do pergaminho | ✅ |
| Conteúdo: 563 entradas, 16 categorias, todas com imagem | ✅ |
| Wiki offline (script + corpus + busca) | ✅ |
| IA local: catálogo de 6 modelos, Gemma 4 E4B como padrão | ✅ |
| Teste manual no emulador (todas as telas) | ✅ |
| Download e instalação de modelo de IA no emulador | ✅ (Qwen3 0.6B) |
| APK de release (arm64) assinado e testado | ✅ 69,8 MB |
| Release `v1.0.0` no GitHub com o APK anexado | ✅ |

## Bugs reais encontrados pelos testes (e corrigidos)

1. **ListTile dentro de cartão decorado** — o Flutter accuse erro de layout nas telas de detalhe
   (switch "coletado" e checklist). Criado o widget `Parchment` (Material + Ink) em `lib/app_theme.dart`.
2. **`Isolate.run` capturando o `SearchService` inteiro** — a wiki offline nunca carregava no app
   ("object is unsendable"). Agora as listas são copiadas para variáveis locais antes do isolate.
3. **Import `dart:typed_data` desnecessário** em `lib/search.dart`.
4. **`Store` com construtor privado** — impossibilitava testar; criado `Store.withPrefs`.
5. **`verify.py` quebrava** com o `names_pt.json` novo (não tem "entries").
6. **Textos da wiki com sobras de HTML** (`data-sort-value=...`, `id="mw-content-text"`) e páginas
   duplicadas ("Mina da pedreira" e "Mina_da_pedreira") — corrigido no scraper (título canônico).

## Arquivos novos desta sessão

- `lib/ai_models.dart` — catálogo dos modelos de IA.
- `lib/widgets/assistant_install_card.dart` — escolha do modelo e download.
- `lib/widgets/assistant_bubble.dart` — balão de chat e sugestões.
- `test/app_test.dart` — percorre todas as telas.
- `tools/scrape_wiki.py` — baixa a wiki PT (short URLs).
- `tools/make_icon.py` — ícone do app.
- `tools/setup_android_visual.sh` — cores do splash/fundo.
- `PROGRESSO.md` — este arquivo.

## Onde as coisas estão

- Conteúdo gerado: `tools/seed/build_seed.py` → `assets/data/*.json` + `assets/img/`.
- Wiki: `tools/scrape_wiki.py` → `assets/wiki/pages.json.gz` + `assets/data/names_pt.json`.
- Ícone: `tools/make_icon.py` → `android/app/src/main/res/mipmap-*/`.
- Build: `flutter build apk --release --target-platform android-arm64` (ou o `codemagic.yaml`).

## Release publicada

- Tag: `v1.0.0` — https://github.com/Advansoftware/Standey-valey/releases/tag/v1.0.0
- Arquivo: `guia-do-vale-1.0.0.apk` (arm64, minSdk 30, assinado com a chave de debug).
- O APK foi baixado de volta do GitHub e conferido (mesmo md5, pacote válido).
- Para publicar uma versão nova: subir a tag e o arquivo com
  `gh release create vX.Y.Z app-release.apk --notes-file notas.md`.

## Release v1.1.0

- Tag: `v1.1.0` — https://github.com/Advansoftware/Standey-valey/releases/tag/v1.1.0
- Arquivo: `guia-do-vale-1.1.0.apk` (arm64, 69,9 MB, minSdk 30, versionCode 2).
- SHA-256: `202fa5941e3e57ac8be146d216389ec78fec2307ce7d4c41a6d45ea5f5d4ac88`.
- O APK foi gerado de `main` limpo, com `flutter analyze` sem avisos e 30 testes passando.
- Notas da release: mapa do vale, guia de lavouras, lista padrão, chat formatado, IA em segundo plano.

## Revisão de textos (feita no fim da sessão)

As frases de "onde achar" do dataset vinham em inglês misturado com português
("Arando in Mines", "Ghost, Frost Bat… drop"). Foi criado um tradutor de frases
(`LOC_PHRASES` em `tools/seed/enrich.py`) e a lista de nomes em PT-BR foi ampliada
(mudas, gosmas, sementes, baús, presentes). Resultado: **nenhum campo das 563
entradas fica com texto em inglês**.
