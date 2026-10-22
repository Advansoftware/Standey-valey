# PROGRESSO — Guia do Vale

Registro de progresso da sessão atual (continuação do HANDOFF.md).
Atualizado a cada etapa concluída.

## Como está agora (sessão 3)

| Etapa | Situação |
|---|---|
| Ambiente com Flutter 3.47.6 / Dart 3.13.5 | ✅ funcionando |
| `flutter pub get` | ✅ 80 dependências |
| `flutter analyze` | ✅ sem erros (1 import removido) |
| `flutter test` | ⚠️ testes de tela escritos; bugs reais encontrados e corrigidos |
| `android/` gerado (minSdk 30, permissão INTERNET, label "Guia do Vale") | ✅ |
| Emulador Android (Pixel 7 API 35) | ✅ rodando |
| Scraper da wiki PT (`tools/scrape_wiki.py`) | ✅ escrito e rodando (api.php bloqueado → usa short URLs) |
| Modelo de IA: Gemma 4 E4B como padrão + lista de 6 modelos | ✅ implementado |
| APK de release + GitHub Release v1.0.0 | ⏳ pendente |

## Correções encontradas pelos testes

1. **ListTile dentro de cartão decorado** — o Flutter accuse erro real
   ("ListTile background color or ink splashes may be invisible") nas telas
   de detalhe (switch "coletado" e checklist). Criado o widget `Parchment`
   (Material + Ink) em `lib/app_theme.dart` e usado nos cartões.
2. **`flutter analyze`** — import `dart:typed_data` desnecessário em `lib/search.dart`.
3. **`Store`** — construtor privado impedia testar; criado `Store.withPrefs`.

## Arquivos novos

- `lib/ai_models.dart` — catálogo de modelos de IA (Gemma 4 E4B, Gemma 4 E2B,
  Qwen3 4B, LFM2.5 1.2B, Qwen3 0.6B, Gemma 4 12B) com tamanho/RAM/URL.
- `lib/widgets/assistant_install_card.dart` — cartão de escolha e download do modelo.
- `lib/widgets/assistant_bubble.dart` — balão de chat e sugestões.
- `tools/scrape_wiki.py` — baixa a wiki PT (short URLs) → `assets/wiki/pages.json.gz`
  e `assets/data/names_pt.json`.
- `test/app_test.dart` — percorre todas as telas do app.

## Regras do dono

- Nunca criar arquivo Dart com mais de 1000 linhas; quebrar em vários arquivos.
- Não perguntar nada: decidir e seguir.
- Ao final: build local + release no GitHub com a descrição da v1.
