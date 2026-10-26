#!/bin/bash
# Acompanha uma rodada no Colab e sai no FIM ou em erro.
# Uso: bash colab_watch.sh <sessão do colab> <rodada>   (ex.: train3 r3)
export MSYS_NO_PATHCONV=1 PYTHONIOENCODING=utf-8
SESSAO=${1:-train3}
RODADA=${2:-r3}
COLAB=${COLAB:-/c/modelo/colab_venv/Scripts/colab}
PY=$(mktemp --suffix=.py)
echo "import subprocess;print(subprocess.run('grep -E \"Passos|val loss|concluído|AVALIADO|FIM|Traceback|Error|memory\" /content/$RODADA.log | tail -4',shell=True,capture_output=True,text=True).stdout)" > "$PY"
seen=""
while true; do
  out=$(timeout 90 "$COLAB" exec -s "$SESSAO" -f "$(cygpath -w "$PY")" 2>/dev/null | grep -E "Passos|val loss|concluído|AVALIADO|FIM|Traceback|Error|memory" | grep -vE "│|Connection was lost|colab_cli|RuntimeError")
  while IFS= read -r l; do [ -z "$l" ] && continue; grep -qxF "$l" <<<"$seen" || { echo "$l"; seen="$seen"$'\n'"$l"; }; done <<<"$out"
  grep -qE "FIM|Traceback|Error|memory" <<<"$out" && exit 0
  sleep 90
done
