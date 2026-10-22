#!/usr/bin/env bash
# Gera/ajusta a pasta android/ (não versionada). Rode na raiz do projeto.
set -euo pipefail
if [ ! -d android ]; then
  flutter create --platforms=android --org br.com.advansoftware --project-name stardew_guia .
fi
# minSdk 30 (exigido pela IA local)
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] || continue
  sed -i -E 's/minSdk(Version)?\s*=\s*(flutter\.minSdkVersion|[0-9]+)/minSdk = 30/; s/minSdkVersion\s+(flutter\.minSdkVersion|[0-9]+)/minSdkVersion 30/' "$f"
done
# permissão de internet (download do modelo) no manifest principal
M=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET' "$M" || sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
sed -i -E 's/android:label="[^"]*"/android:label="Guia do Vale"/' "$M"
echo "android/ pronto"
