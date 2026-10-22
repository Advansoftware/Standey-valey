#!/usr/bin/env bash
# Helper para o celular Android de testes (Samsung SM-G781B).
set -euo pipefail

ADB="${ADB:-adb}"
PACKAGE="br.com.advansoftware.stardew_guia"
ACTIVITY=".MainActivity"
MODEL="SM_G781B"
DEFAULT_APK="build/app/outputs/flutter-apk/app-release.apk"
SHOT_DIR="${SHOT_DIR:-/tmp/opencode/shots}"

die() {
  echo "erro: $*" >&2
  exit 1
}

require_adb() {
  command -v "$ADB" >/dev/null 2>&1 || die "adb não encontrado. Instale platform-tools ou defina ADB=/caminho/do/adb."
}

pick_serial() {
  local serial
  if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    printf '%s\n' "$ANDROID_SERIAL"
    return
  fi
  serial="$("$ADB" devices -l | awk -v model="model:$MODEL" '$2 == "device" && index($0, model) { print $1; exit }')"
  if [[ -z "$serial" ]]; then
    "$ADB" devices -l >&2
    die "celular $MODEL não encontrado. Ative a depuração sem fio e use 'connect IP:PORTA'."
  fi
  printf '%s\n' "$serial"
}

phone() {
  "$ADB" -s "$(pick_serial)" "$@"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  help|-h|--help)
    cat <<'EOF'
uso: phone.sh COMANDO [args]

Sem dispositivo:
  devices                 lista dispositivos do adb
  mdns                    lista anúncios de depuração sem fio
  pair IP:PORTA_PAREAMENTO CODIGO
                          pareia (o código expira e é de uso único)
  connect IP:PORTA_CONEXAO
                          conecta ao celular já pareado

Com dispositivo (escolhe o SM-G781B automaticamente):
  serial                  mostra o serial usado
  doctor                  modelo, Android, tela e app instalado
  install [APK]           instala o APK (padrão: release arm64)
  uninstall               remove o app
  launch                  abre o app
  stop                    fecha o app
  restart                 fecha e abre
  reset                   apaga os dados do app
  shot [NOME]             captura para /tmp/opencode/shots/NOME.png
  tap X Y                 toque
  swipe X1 Y1 X2 Y2 [MS]  arrasto
  text TEXTO              digita (espaços viram %s)
  key CODIGO              tecla (ex.: 4 = voltar)
  stay-awake              mantém a tela ligada
  allow-sleep             desfaz stay-awake
  ip                      IP do celular no Wi-Fi
  logcat                  log do Flutter (Ctrl+C para sair)

Variáveis: ADB, SHOT_DIR e ANDROID_SERIAL.
EOF
    ;;
  devices)
    require_adb
    "$ADB" devices -l
    ;;
  mdns)
    require_adb
    "$ADB" mdns services
    ;;
  pair)
    require_adb
    [[ $# -ge 2 ]] || die "uso: phone.sh pair IP:PORTA_PAREAMENTO CODIGO"
    "$ADB" pair "$1" "$2"
    ;;
  connect)
    require_adb
    [[ $# -ge 1 ]] || die "uso: phone.sh connect IP:PORTA_CONEXAO"
    "$ADB" connect "$1"
    sleep 1
    "$ADB" devices -l
    ;;
  serial)
    require_adb
    pick_serial
    ;;
  doctor)
    require_adb
    serial="$(pick_serial)"
    echo "serial: $serial"
    "$ADB" -s "$serial" shell getprop ro.product.model
    "$ADB" -s "$serial" shell getprop ro.build.version.release
    "$ADB" -s "$serial" shell wm size
    if "$ADB" -s "$serial" shell pm list packages | grep -qx "package:$PACKAGE"; then
      echo "app: instalado"
    else
      echo "app: não instalado"
    fi
    ;;
  install)
    require_adb
    apk="${1:-$DEFAULT_APK}"
    [[ -f "$apk" ]] || die "APK não encontrado: $apk"
    "$ADB" -s "$(pick_serial)" install -r "$apk"
    ;;
  uninstall)
    require_adb
    phone uninstall "$PACKAGE"
    ;;
  launch)
    require_adb
    phone shell am start -n "$PACKAGE/$ACTIVITY"
    ;;
  stop)
    require_adb
    phone shell am force-stop "$PACKAGE"
    ;;
  restart)
    require_adb
    phone shell am force-stop "$PACKAGE"
    sleep 1
    phone shell am start -n "$PACKAGE/$ACTIVITY"
    ;;
  reset)
    require_adb
    phone shell pm clear "$PACKAGE"
    ;;
  shot)
    require_adb
    name="${1:-shot-$(date +%Y%m%d-%H%M%S)}"
    name="${name%.png}"
    out="$SHOT_DIR/$name.png"
    mkdir -p "$SHOT_DIR"
    phone exec-out screencap -p > "$out"
    echo "$out"
    ;;
  tap)
    require_adb
    [[ $# -ge 2 ]] || die "uso: phone.sh tap X Y"
    phone shell input tap "$1" "$2"
    ;;
  swipe)
    require_adb
    [[ $# -ge 4 ]] || die "uso: phone.sh swipe X1 Y1 X2 Y2 [MS]"
    phone shell input swipe "$1" "$2" "$3" "$4" "${5:-300}"
    ;;
  text)
    require_adb
    [[ $# -ge 1 ]] || die "uso: phone.sh text TEXTO"
    escaped="$(printf '%s' "$*" | sed 's/ /%s/g')"
    phone shell input text "$escaped"
    ;;
  key)
    require_adb
    [[ $# -ge 1 ]] || die "uso: phone.sh key CODIGO"
    phone shell input keyevent "$1"
    ;;
  stay-awake)
    require_adb
    phone shell svc power stayon true
    ;;
  allow-sleep)
    require_adb
    phone shell svc power stayon false
    ;;
  ip)
    require_adb
    phone shell ip -f inet addr show wlan0
    ;;
  logcat)
    require_adb
    phone logcat -v time -s flutter
    ;;
  *)
    die "comando desconhecido: $cmd (use phone.sh help)"
    ;;
esac
