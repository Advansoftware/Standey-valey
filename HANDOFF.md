# HANDOFF — Guia do Vale (enciclopédia de Stardew Valley, Flutter/Android)

> Arquivo de continuação para qualquer IA/pessoa que pegar o projeto. **Atualize este arquivo
> a cada etapa concluída** (marque `[x]`, ajuste "Próximos passos") e faça commit + push.
> Última atualização: 2026-10-22 (sessão 1, parada por falta de tokens do dono).

## 1. Objetivo (pedido do dono, Bruno)
App Android em **Flutter**, **100% em português do Brasil**, que funcione como uma **enciclopédia/Pokédex de
Stardew Valley** para quem **começou a jogar hoje**: saber *o que é o quê* e *como progredir*.

Requisitos explícitos do dono:
- UX/UI "perfeitos", intuitivo, completo. Estilo **Pokédex** (cartões numerados com sprite, nome, tipo, progresso).
- **Todas as entradas com imagem — os sprites/assets reais do jogo** (ex.: saber qual árvore é carvalho e qual é pinheiro).
- **Tudo embutido no projeto, nada online em runtime** (sem baixar imagem/dado da internet).
- **IA local com RAG** sobre todo o conteúdo (busca no conteúdo + LLM no aparelho). Única coisa online aceitável: baixar o modelo da IA uma vez.
- Repositório: https://github.com/Advansoftware/Standey-valey (nome com o typo "Standey" é o do dono; manter).
- **Subir no GitHub a cada etapa.** Build do APK é feito pelo dono no **Codemagic** a partir do git → deixar pronto (`codemagic.yaml`).
- Comunicação do dono: direta e concisa.

## 2. Descobertas importantes sobre o ambiente (economiza tempo)
- O sandbox da sessão **não tem Flutter/Dart** e a rede só alcança registries de pacotes e GitHub
  (`storage.googleapis.com`, `pub.dev`, wiki do Stardew etc. são bloqueados no shell). **Nada do Flutter foi compilado/testado ainda.**
  → Rodar `flutter analyze` / `flutter test` / build é a **primeira coisa** a fazer em um ambiente com Flutter (ou no Codemagic) e corrigir erros.
- O **npm funciona**: o pacote **`stardew-valley-data@1.1.1`** (MIT) traz **JSON estruturado + ~1.900 imagens PNG do jogo**
  (culturas, peixes, moradores+retratos, árvores com estágios, minerais, monstros, culinária, artefatos, construções, ferramentas, pacotes, festivais…).
  É a fonte oficial de dados/imagens deste projeto. Baixar com `bash tools/seed/fetch_dataset.sh` (cai em `tools/seed/.cache/package`, ignorado pelo git).
  Observação legal: código/dados MIT; as imagens são arte do jogo (© ConcernedApe), uso de fã não comercial. Citar créditos no app.
- WebFetch da wiki PT (`pt.stardewvalleywiki.com`) é instável (muitas páginas falham) → não depender dele. A wiki é CC BY-NC-SA 3.0.
- `git push` funciona para este repositório; o repo foi anexado à sessão. `gh api` fora de `repos/{owner}/{repo}` é bloqueado.
- Pacote de IA local: `flutter_edge_ai ^2.5.0` + `flutter_edge_ai_litertlm ^1.16.0` (substitui o descontinuado `flutter_gemma`).
  Exige **Dart >=3.12 / Flutter >=3.44**, **minSdk 30**, **só arm64-v8a**, e permissão **INTERNET** no manifest de release (para baixar o modelo).
  Modelo padrão sem login: Qwen3 0.6B (~345 MB) — URL em `lib/ai_service.dart`.

## 3. Comandos para fazer tudo funcionar (na ordem)
```bash
git clone https://github.com/Advansoftware/Standey-valey.git && cd Standey-valey

# 1) Dados + imagens do jogo (precisa de node/npm e python3)
bash tools/seed/fetch_dataset.sh              # baixa stardew-valley-data -> tools/seed/.cache/package
python3 tools/seed/build_seed.py              # gera assets/data/*.json  (hoje: versão v1 manual; ver TODO A)
#   (após o TODO A, este script também copia as imagens para assets/img/)

# 2) Gerar a pasta android/ (não está versionada ainda) e aplicar ajustes  [TODO C: criar tools/setup_android.sh]
flutter create . --platforms=android --org com.advansoftware --project-name stardew_guia
#   depois: minSdk 30, permissão INTERNET no AndroidManifest principal, nome do app "Guia do Vale"

# 3) Dependências, análise, testes
flutter pub get
flutter analyze            # corrigir tudo que aparecer (o código nunca foi compilado!)
flutter test

# 4) APK (local) — no Codemagic o codemagic.yaml faz isto
flutter build apk --release --target-platform android-arm64
```
Texto/nomes oficiais PT-BR da wiki (opcional, rodar com internet; via GitHub Actions ou na máquina do dono):
```bash
python3 tools/scrape_wiki.py     # [TODO D] gera assets/data/names_pt.json e assets/wiki/pages.json.gz
```

## 4. Estado atual do repositório
```
pubspec.yaml                 OK (deps: shared_preferences, url_launcher, flutter_edge_ai, flutter_edge_ai_litertlm)
lib/models.dart              OK  Category, Entry, CalendarEvent (precisa: campo `gallery`)
lib/repository.dart          OK  carrega assets/data/*.json (+ names_pt.json opcional)
lib/store.dart               OK  favoritos, "coletados", checklist, data do jogo, tema, flags da IA (SharedPreferences)
lib/search.dart              OK  BM25 local (acentos, stopwords PT, prefixo) + carga opcional de assets/wiki/pages.json.gz
lib/ai_service.dart          OK  wrapper flutter_edge_ai (install/ask streaming) + buildPrompt (RAG) + cleanAnswer
lib/app_theme.dart           OK  tema "pergaminho" claro/escuro + parchment()
lib/app_scope.dart           OK  InheritedWidget com store/repo/search/ai
lib/widgets/common.dart      OK* EntryImage, DexCard (estilo Pokédex), EntryTile, TagPill, SectionTitle (*remover fallback de rede)
lib/screens/detail_screen.dart    OK* detalhe + checklist + BodyView (*remover botões/links da wiki; adicionar galeria)
lib/screens/category_screen.dart  OK  grade/lista Pokédex, filtros por tag, progresso, tela Enciclopédia
lib/screens/home_screen.dart      OK  "Hoje na fazenda", guia, culturas lucrativas, atalhos
lib/screens/calendar_screen.dart  OK  calendário 4x28 com aniversários/festivais
tools/seed/data_core.py, data_guia.py, build_seed.py   v1 (dados escritos à mão, 66 peixes etc.) — será substituída pelo v2 (TODO A)
tools/seed/pt_names.py       OK  ~730 nomes EN→PT-BR (melhor esforço) para o dataset
tools/seed/fetch_dataset.sh  OK
assets/data/*.json           v1 gerado (funciona, mas sem imagens reais)
```
**Faltam telas/arquivos que `lib/` já referencia** (o app NÃO compila sem eles): `lib/main.dart`,
`lib/screens/search_screen.dart` (classe `SearchScreen`), `lib/screens/assistant_screen.dart` (classe `AssistantScreen({initialQuestion})`),
`lib/screens/about_screen.dart` (classe `AboutScreen`), `lib/screens/favorites_screen.dart`, `lib/screens/shell.dart`.

## 5. Próximos passos (em ordem de prioridade)
- [ ] **A. Gerador v2 com imagens reais** — reescrever `tools/seed/build_seed.py` para ler `tools/seed/.cache/package/data/*.json`:
  - Para cada categoria abaixo, gerar `assets/data/<cat>.json` no formato de `Entry` (campos: `id,en,pt,emoji,sub,tags,img,gallery,fields,desc,body,checklist,meta,n,cat`),
    com `pt = pt_names.pt(nome_en)`, rótulos em PT-BR, valores traduzidos (estações, clima, horário 24h "6h–19h", locais) e **descrições geradas em PT** (não exibir o texto em inglês do dataset).
  - **Copiar as imagens referenciadas para `assets/img/` (pasta PLANA)**: nome = slug do caminho (`images/crops/parsnip/crop.png` → `crops_parsnip_crop.png`).
    Motivo: `pubspec.yaml` lista `assets/img/` e diretórios de assets **não são recursivos**. `img` = arquivo principal; `gallery` = lista `[arquivo, rótulo]` (estágios de crescimento, semente, variantes).
  - Categorias (arquivo do dataset → categoria): `crops`→culturas (estágios+semente, lucro/dia, treliça, gigante, XP), `fish`→peixes (regular/lendário/Mercado Noturno/armadilha),
    `villagers`→aldeoes (retrato+retrato de cônjuge, ama/gosta/não gosta/odeia, aniversário, casável, onde mora; `universal-gifts.json` vira entrada do guia),
    `forageables`→coletaveis, `trees`→arvores (**estágios 1–5 + semente + produto da torneira** → resolve "qual é carvalho/pinheiro/bordo"; ensinar a identificar pela semente: Bolota=Carvalho, Semente de bordo=Bordo, Pinha=Pinheiro),
    `minerals`→minerais, `monsters`+`monster-loot`→monstros (variantes na galeria), `cooking`→culinaria (ingredientes, buffs, como obter a receita),
    `artifacts`→artefatos, `animals`→animais (fazenda + pets agrupados), `buildings`→construcoes, `tools`→ferramentas (níveis e custos de melhoria),
    `bundles` (só `remixBundle:false`)→pacotes (checklist), `seasons`(festivais)→festivais (reaproveitar textos de `data_core.FEST`), `skills`+`professions`→habilidades (reaproveitar `data_core.SKILLS`).
  - Manter o **guia do iniciante** (`data_guia.py`, 15 artigos) e associar imagens reais a cada artigo (ex.: Pastinaca, estações em `images/seasons/`, Mina em `images/locations/The Mines.png`, Pesca com `images/tools/fishing-rod/`…).
  - Atualizar `CATS` (id, título, emoji, cor, descrição, rótulo de "coletado") com as novas categorias: guia, culturas, peixes, aldeoes, coletaveis, arvores, minerais, monstros, culinaria, artefatos, animais, construcoes, ferramentas, pacotes, festivais, habilidades.
  - Verificação: script que lista entradas sem `img`, textos ainda em inglês e IDs duplicados.
- [ ] **B. Telas e ajustes Flutter**
  - `lib/models.dart`: adicionar `final List<List<String>> gallery` em `Entry` (ler de `j['gallery']`).
  - `lib/widgets/common.dart`: `EntryImage` só `Image.asset('assets/img/<img>')` com `FilterQuality.none` (pixel art) + emoji se faltar; **remover `Image.network`** e a opção `networkImages` (store/about).
  - `lib/screens/detail_screen.dart`: **remover `openWiki`/botões "Wiki"/ícone open_in_new** (nada online); adicionar **galeria horizontal** (`gallery`) logo abaixo do cabeçalho (estágios com rótulos "Estágio 1…").
  - Criar `lib/screens/search_screen.dart`: campo de busca, resultados BM25 (`SearchService.search`), filtro Tudo/Enciclopédia/Wiki offline, chama `search.loadWiki()` ao abrir; resultado de wiki abre uma tela de leitura (`WikiPageScreen`).
  - Criar `lib/screens/assistant_screen.dart`: chat. Fluxo: `hits = search.search(pergunta, limit: 6)` → se `store.aiModelInstalled && ai.engineReady` usa `buildPrompt` + `ai.ask` (stream, `cleanAnswer`); senão responde só com os trechos recuperados ("busca inteligente").
    Cartão para **baixar o modelo** (progresso de `ai.progress`, URL editável salva em `store.aiModelUrl`, padrão `defaultModelUrl`); mostrar fontes (títulos dos hits). Parâmetro `initialQuestion` envia automaticamente.
  - Criar `lib/screens/favorites_screen.dart` (lista de `EntryTile` dos favoritos, estado vazio amigável) e `lib/screens/about_screen.dart` (tema claro/escuro/sistema, resetar progresso, status da IA/wiki offline, **créditos**: dados `stardew-valley-data` (MIT), imagens © ConcernedApe, textos da wiki CC BY-NC-SA 3.0, app não oficial e sem fins comerciais).
  - Criar `lib/screens/shell.dart`: `NavigationBar` com 5 abas — Início, Enciclopédia (`EncyclopediaScreen`), Calendário, Assistente, Favoritos — em `IndexedStack`.
  - Criar `lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `Store.load()`, `Repository.load()`, `SearchService(repo)`, `AiService()`; `runApp` com `AppScope` + `ListenableBuilder` no `MaterialApp` (tema `buildTheme`, `themeMode: store.themeMode`, `locale pt_BR`);
    `ai.init()` **sem await** e `search.loadWiki()` em segundo plano depois do primeiro frame. Título "Guia do Vale".
  - Ícone do app e nome ("Guia do Vale") — opcional: pacote `flutter_launcher_icons` (verificar versão no pub.dev) com um sprite do jogo (ex.: `crops_parsnip_crop.png`).
- [ ] **C. Android + Codemagic**
  - `tools/setup_android.sh`: roda `flutter create . --platforms=android --org com.advansoftware --project-name stardew_guia` se `android/` não existir; aplica `minSdk = 30` (sed em `android/app/build.gradle.kts`: `minSdk = flutter.minSdkVersion` → `minSdk = 30`; versão groovy também), insere `<uses-permission android:name="android.permission.INTERNET"/>` em `android/app/src/main/AndroidManifest.xml`, `android:label="Guia do Vale"`.
  - `codemagic.yaml` (workflow `android-apk`, `instance_type: linux_x2`, `flutter: stable`, `java: 17`): `bash tools/setup_android.sh` → `flutter pub get` → `flutter analyze` (não bloquear) → `flutter test` (não bloquear) → `flutter build apk --release --target-platform android-arm64 --build-name $BUILD_NAME --build-number $PROJECT_BUILD_NUMBER`; `artifacts: build/**/outputs/**/*.apk`.
    APK sai assinado com chave de debug (instalável). Assinatura de release: configurar no Codemagic se o dono quiser publicar.
  - Se preferir versionar `android/`, gerar uma vez com Flutter e remover as linhas de `android` do `.gitignore`.
- [ ] **D. Scraper opcional da wiki PT** — `tools/scrape_wiki.py` (só stdlib; User-Agent identificável; ~1 req/s; cache em `tools/.cache`):
  (1) `names_pt.json` {nome EN → nome PT} via `prop=langlinks&lllang=pt` na wiki EN (`https://stardewvalleywiki.com/api.php`) ou lendo a PT; `Repository` já aplica esse arquivo por cima de `pt_names.py`.
  (2) `assets/wiki/pages.json.gz` = lista JSON `[{"t": título, "u": url, "c": [trechos ~700 chars]}]` gzip, de `https://pt.stardewvalleywiki.com/api.php` (`list=allpages` + `action=parse&prop=text`, converter HTML→texto mantendo linhas de tabela como `a | b | c`). É o corpus extra do RAG.
  Workflow `.github/workflows/fetch-assets.yml` (`workflow_dispatch`) que roda o scraper e faz commit dos arquivos gerados. *Pode não ser possível dar push de workflow com o token da sessão; se falhar, deixar o YAML em `docs/` e avisar o dono.*
- [ ] **E. Testes e README**: `test/search_test.dart` (tokenize/BM25 puro Dart), `README.md` (visão geral, comandos acima, créditos). Rodar `flutter analyze` e corrigir tudo.
- [ ] **F. Revisão de conteúdo**: conferir nomes PT-BR dos itens (melhor esforço em `pt_names.py`), textos do guia (`data_guia.py`), valores sensíveis a versão do jogo (1.6).

## 6. Ideia de design (UX/UI) — manter e evoluir
- **Conceito**: "caderno do fazendeiro" + **Pokédex**. Fundo de **pergaminho** quente (`#FBF3DA` claro / `#1F1B13` escuro), cartões com borda cor-de-papel e sombra suave, cantos 20 dp, tipografia peso 800 nos nomes.
- **Cada categoria tem uma cor** (ver `CATS`): verde culturas, azul peixes, rosa moradores, laranja festivais, roxo pacotes, ouro habilidades, marrom coletáveis… usada em chips, progresso e halo do sprite.
- **Cartão Pokédex** (`DexCard`): número `#012` no canto, **sprite do jogo grande dentro de um círculo translúcido da cor da categoria**, nome (PT) em negrito + subtítulo curto, estrela de favorito e ✔ de "coletado". Grade de 2 colunas; botão para alternar lista/grade.
- **Pixel art nítida**: `FilterQuality.none` e `BoxFit.contain` em todos os sprites (nunca suavizar).
- **Detalhe**: cabeçalho com sprite grande + nome PT + nome original em itálico (ajuda a achar no jogo em inglês) + tags; **galeria de estágios** (ex.: árvore estágios 1→5, planta crescendo); ficha de dados em cartão; switch "Já pesquei/plantei…" que alimenta o **progresso** da categoria; checklist com barra para pacotes do Centro Comunitário; botão "Perguntar à IA".
- **Início**: saudação, busca grande, cartão **"Hoje na fazenda"** (escolhe estação/dia → aniversários, festivais, próximos eventos), carrossel **"Comece aqui"** (guia), **culturas mais lucrativas da estação**, atalhos de categorias, botão do assistente.
- **Navegação**: `NavigationBar` inferior (Início · Enciclopédia · Calendário · Assistente · Favoritos). Busca global sempre a um toque.
- **Linguagem**: tudo em PT-BR claro para iniciante; sempre mostrar o nome original (EN) ao lado quando diferente.
- **Micro-interações a considerar**: `Hero` do sprite da lista para o detalhe, animação de preenchimento da barra de progresso, haptics leve ao marcar "coletado", `SliverAppBar` colapsável no detalhe.
- **Acessibilidade**: contraste AA nos dois temas, alvos ≥48 dp, `Semantics` nos cartões, respeitar tamanho de fonte do sistema.
- **Opcional (futuro)**: modo "Primeiro ano" com checklist de metas por estação; conquistas (`achievements.json` tem imagens); receitas de fabricação (`crafting.json`); armas/anéis/chapéus; missões (`quests.json`).

## 7. Convenções
- Commits pequenos e frequentes; mensagem em PT-BR; push em `main`. Terminar mensagens de commit feitas pelo Claude com os trailers pedidos pela plataforma.
- Nunca commitar `tools/seed/.cache/`, chaves, tokens.
- IDs de entrada estáveis (`crop_parsnip`, `fish_pufferfish`…) porque favoritos/progresso são guardados por ID.


## ATUALIZAÇÃO (passo 2)
Feito: search/favorites/about/assistant/shell/main.dart; rede removida de EntryImage/Store/detalhe;
`tools/setup_android.sh` e `codemagic.yaml`. Código AINDA não compilado: rodar `flutter pub get && flutter analyze` e corrigir.
Falta: gerador v2 com imagens reais (A), galeria `gallery` em Entry/detalhe, scraper wiki (D), testes/README (E), revisão (F).
