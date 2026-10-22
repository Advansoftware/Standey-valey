# PROGRESSO — Guia do Vale

Registro de progresso da sessão (continuação do HANDOFF.md).
Atualizado a cada etapa concluída — serve de rede de segurança se algo falhar.

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
