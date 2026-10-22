#!/usr/bin/env bash
# Baixa o pacote npm "stardew-valley-data" (MIT) com dados e imagens do jogo
# para tools/seed/.cache/package. Só precisa rodar uma vez.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .cache
cd .cache
if [ ! -d package ]; then
  npm pack stardew-valley-data@1.1.1 >/dev/null
  tar -xzf stardew-valley-data-*.tgz
fi
echo "OK: $(pwd)/package"
