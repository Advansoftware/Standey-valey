# Guia do Vale (Stardew Valley) — enciclopédia em PT-BR

App Flutter/Android: Pokédex do Stardew Valley, 100% offline, com sprites do jogo e IA local (RAG).
Veja `HANDOFF.md` para comandos e o que falta. Build: `bash tools/setup_android.sh && flutter pub get && flutter build apk --release --target-platform android-arm64` (ou Codemagic via `codemagic.yaml`).
Dados/imagens: pacote npm `stardew-valley-data` (MIT); arte © ConcernedApe, uso fã não comercial.
Regenerar dados: `bash tools/seed/fetch_dataset.sh && python3 tools/seed/build_seed.py && python3 tools/seed/verify.py`.
