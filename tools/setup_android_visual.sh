#!/usr/bin/env bash
# Ajusta o visual do app no Android: ícone, cores de fundo e splash.
# (o ícone em si é gerado por tools/make_icon.py)
set -euo pipefail
cd "$(dirname "$0")/.."

RES=android/app/src/main/res
PARCHMENT="#FBF3DA"
PARCHMENT_ESCURO="#1F1B13"

mkdir -p "$RES/values" "$RES/values-night"

# cor de fundo do app (usada no splash e na barra de status)
cat > "$RES/values/colors.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="guia_fundo">$PARCHMENT</color>
</resources>
EOF

cat > "$RES/values-night/colors.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="guia_fundo">$PARCHMENT_ESCURO</color>
</resources>
EOF

for f in "$RES/drawable/launch_background.xml" "$RES/drawable-v21/launch_background.xml"; do
  [ -f "$f" ] || continue
  python3 - "$f" "$PARCHMENT" <<'PY'
import re, sys
caminho, cor = sys.argv[1], sys.argv[2]
s = open(caminho, encoding="utf-8").read()
s = re.sub(r'<item android:drawable="[^"]*" />', f'<item android:drawable="@color/guia_fundo" />', s, count=1)
open(caminho, "w", encoding="utf-8").write(s)
PY
done

# styles: fundo do pergaminho + splash do Android 12 com o ícone do app
for styles in "$RES/values/styles.xml" "$RES/values-night/styles.xml"; do
  [ -f "$styles" ] || continue
  python3 - "$styles" <<'PY'
import re, sys
caminho = sys.argv[1]
s = open(caminho, encoding="utf-8").read()
s = s.replace(
    '<item name="android:windowBackground">?android:colorBackground</item>',
    '<item name="android:windowBackground">@color/guia_fundo</item>',
)
# acrescenta o splash do Android 12 dentro do estilo LaunchTheme existente
if "windowSplashScreenBackground" not in s:
    s = s.replace(
        """        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>""",
        """        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/guia_fundo</item>
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher_foreground</item>
    </style>""",
    )
open(caminho, "w", encoding="utf-8").write(s)
PY
done

echo "visual do Android ajustado"
