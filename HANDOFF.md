# HANDOFF — Guia do Vale (enciclopédia de Stardew Valley, Flutter/Android)

> Arquivo de continuação para qualquer IA/pessoa que pegar o projeto. **Atualize este arquivo
> a cada etapa concluída** (marque `[x]`, ajuste "Próximos passos") e faça commit + push.
> Última atualização: 2026-10-22 (sessão 4 — mapa do vale, guia de lavoura e release v1.1.0).

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

## 2. Estado atual (sessão 4)

Tudo abaixo já está **funcionando e testado**:

| Item | Situação |
|---|---|
| `flutter analyze` | ✅ sem avisos |
| `flutter test` | ✅ 30 testes (telas, mapa, busca e guias) |
| `flutter build apk --release --target-platform android-arm64` | ✅ gera APK instalável |
| Emulador Android (Pixel 7 API 35) | ✅ app instalado e testado a mão |
| Pasta `android/` | ✅ versionada (minSdk 30, permissão INTERNET, ícone próprio, splash) |
| Conteúdo | ✅ 565 entradas, 16 categorias, **todas com imagem do jogo** |
| Wiki offline | ✅ ~1.300 páginas da wiki PT dentro do app (`assets/wiki/pages.json.gz`) |
| Mapa do Vale | ✅ 16 lugares, norte/sul, zoom, filtros e ficha por lugar |
| IA local | ✅ 6 modelos na tela do Assistente; **Gemma 4 E4B** como padrão (RAM 8 GB+) |
| GitHub | ✅ `main` atualizado + release `v1.1.0` com o APK |

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

# 5) APK (local) — o codemagic.yaml faz isto no CI
flutter build apk --release --target-platform android-arm64
```

## 4. Mapa do repositório

```
pubspec.yaml                    deps: shared_preferences, flutter_edge_ai, flutter_edge_ai_litertlm
lib/main.dart                   monta o app (AppScope + MaterialApp, tema do store)
lib/models.dart                 Category, Entry (com gallery), CalendarEvent
lib/repository.dart             lê assets/data/*.json e aplica os nomes da wiki
lib/store.dart                  favoritos, coletados, checklist, data do jogo, tema, modelo da IA
lib/search.dart                 BM25 local (acentos, stopwords, prefixo) + índice da wiki
lib/ai_service.dart             wrapper flutter_edge_ai (install/ask) + prompt RAG + cleanAnswer
lib/ai_models.dart              catálogo dos 6 modelos de IA (nome, tamanho, RAM, URL)
lib/app_theme.dart              tema "pergaminho" claro/escuro + parchment() + widget Parchment
lib/app_scope.dart              InheritedWidget com store/repo/search/ai
lib/widgets/common.dart         EntryImage, DexCard, EntryTile, TagPill, SectionTitle
lib/widgets/markdown_lite.dart  Markdown leve para o chat (negrito, itálico, listas, código)
lib/widgets/assistant_*.dart    cartão de download do modelo e balões do chat
lib/map_data.dart               16 lugares do mapa, regiões, coordenadas e textos curtos
lib/screens/                    home, encyclopedia/category, detail, calendar, search,
                                map, assistant, favorites, about, shell (NavigationBar)
assets/data/*.json              16 categorias + index.json + names_pt.json
assets/img/                     920+ sprites do jogo (nome achatado) + map_valley.png
assets/wiki/pages.json.gz       corpus da wiki PT para o RAG
tools/seed/                     geradores de conteúdo (data_core, data_guia, enrich, utility…)
tools/seed/utility.py           gera "Utilidade" e preços nas fichas
tools/scrape_wiki.py            baixa a wiki PT
tools/make_icon.py              gera o ícone do app
tools/setup_android*.sh         preparação do projeto Android
test/app_test.dart              testes de interface (todas as telas)
test/search_test.dart           testes da busca
codemagic.yaml                  build do APK no CI
```

## 5. Regras do dono (obedecer)

1. **Nenhum arquivo Dart acima de 1000 linhas.** Quebrar widgets em arquivos próprios.
2. **Não perguntar nada** — decidir e seguir, e registrar o progresso em `PROGRESSO.md`.
3. **Nada online em runtime.** Só o download do modelo de IA (uma vez).
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

## 7. Ideias para as próximas versões (opcional)

- Modo "Primeiro ano": checklist de metas por estação.
- Conquistas (`achievements.json` tem imagens), receitas de fabricação (`crafting.json`),
  armas/anéis/chapéus, missões (`quests.json`), monetário e karma.
- Comparador de lucro por cultura considerando irrigação e fertilizante.
- Busca por voz no assistente.
