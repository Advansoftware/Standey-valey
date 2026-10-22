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
| APK de release + release `v1.0.0` no GitHub | ✅ |

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
