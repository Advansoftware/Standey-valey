# PROGRESSO — Guia do Vale

Registro de progresso da sessão (continuação do HANDOFF.md).
Atualizado a cada etapa concluída — serve de rede de segurança se algo falhar.

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

## Revisão de textos (feita no fim da sessão)

As frases de "onde achar" do dataset vinham em inglês misturado com português
("Arando in Mines", "Ghost, Frost Bat… drop"). Foi criado um tradutor de frases
(`LOC_PHRASES` em `tools/seed/enrich.py`) e a lista de nomes em PT-BR foi ampliada
(mudas, gosmas, sementes, baús, presentes). Resultado: **nenhum campo das 563
entradas fica com texto em inglês**.
