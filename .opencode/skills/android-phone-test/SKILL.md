---
name: Celular Android de testes
description: Conectar, parear, instalar e testar o Guia do Vale no celular Android físico (Samsung SM-G781B) via ADB e depuração sem fio, em vez do emulador. Use sempre que precisar rodar o app, tirar screenshot, tocar na tela, ver logcat ou testar a API local no aparelho.
---

# Celular Android de testes

O aparelho **Samsung SM-G781B (Galaxy S20 FE), Android 13, tela 1080x2400**
é reservado para testes do Guia do Vale. Use ele em vez do emulador: o
emulador é lento e a rede dele não representa a rede real.

- Pacote: `br.com.advansoftware.stardew_guia`
- Activity principal: `.MainActivity`
- APK de release: `build/app/outputs/flutter-apk/app-release.apk`
- APK de debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Helper: `scripts/phone.sh` (na pasta desta skill)

## Regra de ouro

Sempre passe o serial com `-s`, ou use o helper, porque o emulador pode estar
ligado ao mesmo tempo. O serial do celular é o par `IP:porta` mostrado em
`adb devices -l`, por exemplo `192.168.3.17:43161`.

```sh
adb devices -l
# 192.168.3.17:43161  device  product:r8qxxx model:SM_G781B device:r8q
```

## Fluxo rápido

1. No celular, ative **Opções do desenvolvedor → Depuração sem fio** e deixe
   a tela de depuração aberta. Mantenha o aparelho desbloqueado.
2. No PC, confira o que o ADB enxerga:

   ```sh
   adb devices -l
   adb mdns services
   ```

3. Se o celular ainda não estiver pareado, toque em **Parear dispositivo com
   código**. A janela mostra um `IP:porta` **de pareamento** e um código de
   6 dígitos. Rode:

   ```sh
   adb pair 192.168.3.17:43819 123456
   ```

   O código é de uso único e expira. Não guarde o código em arquivo nem no
   repositório.

4. Depois de parear, volte à tela principal de **Depuração sem fio** e use o
   `IP:porta` que aparece ali. Essa é a porta de **conexão**, diferente da
   porta de pareamento:

   ```sh
   adb connect 192.168.3.17:43161
   adb devices -l
   ```

   O estado precisa ser `device`. Se aparecer `unauthorized`, aceite o
   diálogo de depuração no celular. Se aparecer `offline`, desconecte e
   conecte de novo.

5. Instale e abra o app:

   ```sh
   cd /home/bruno/git/Standey-valey
   flutter build apk --release --target-platform android-arm64
   adb -s 192.168.3.17:43161 install -r build/app/outputs/flutter-apk/app-release.apk
   adb -s 192.168.3.17:43161 shell am start -n br.com.advansoftware.stardew_guia/.MainActivity
   ```

## Use o helper

O helper evita repetir o serial e o caminho do APK. Ele procura primeiro um
aparelho `SM_G781B` e ignora emuladores.

```sh
S=.opencode/skills/android-phone-test/scripts/phone.sh

$S doctor          # serial, modelo, Android, tela e app instalado
$S devices         # lista dispositivos
$S mdns            # anúncios _adb-tls-connect._tcp
$S connect 192.168.3.17:43161
$S pair 192.168.3.17:43819 123456
$S install         # instala o APK de release
$S launch          # abre o app
$S restart         # fecha e abre
$S shot home       # salva em /tmp/opencode/shots/home.png
$S tap 360 1446    # toque em coordenadas reais (1080x2400)
$S swipe 540 1900 540 900 500
$S text "Fazenda Teste"
$S key 4           # voltar
$S stay-awake      # evita a tela apagar durante o teste
$S logcat          # log do Flutter (Ctrl+C para sair)
$S reset           # apaga os dados do app (teste limpo)
```

## Portas: não confunda

| Porta | Onde aparece | Para que serve |
| --- | --- | --- |
| Pareamento | Janela **Parear dispositivo com código** | `adb pair` |
| Conexão | Tela principal **Depuração sem fio** | `adb connect` |

A porta de pareamento muda a cada pareamento. A porta de conexão costuma
continuar a mesma enquanto a depuração sem fio não for desligada, mas pode
mudar depois de reiniciar o celular ou alternar a rede. Sempre confira na
tela do aparelho.

O IP também pode mudar por DHCP. O último visto foi `192.168.3.17`; o PC
estava em `192.168.3.7` (Wi-Fi) e `192.168.3.28` (Ethernet). Confirme com:

```sh
adb -s 192.168.3.17:43161 shell ip -f inet addr show wlan0
ip -brief addr show
```

## Testar a API local no celular

Para validar a descoberta mDNS e a sincronização sem abrir o Stardew Valley, use o mock e o
anunciador incluídos nesta skill:

```sh
# terminal 1: API falsa em 0.0.0.0:7882
python3 .opencode/skills/android-phone-test/scripts/mock_api.py

# terminal 2: anúncio _stardewapi._tcp por 20 minutos (precisa de .NET 6)
cd .opencode/skills/android-phone-test/scripts/mdtest
dotnet run
```

1. No app, abra **Sobre e ajustes → Servidor do jogo (API)** e toque em **Procurar na rede**.
   Se o mDNS falhar, informe `http://IP_DO_PC:7882` e toque em **Conectar**.
2. Confira no log do mock as chamadas `/api/v1/mods`, `/world`, `/players/main` e
   `/players/main/inventory`.
3. A data da tela inicial deve mudar para a data do mock. O modo automático sincroniza a cada
   60 segundos e ao voltar ao app.
4. O mock não substitui um teste com save real; ele só confirma o caminho de rede e o formato
   esperado dos dados.

## Coordenadas e screenshots

A tela real é **1080x2400**, mas a imagem lida pelo modelo pode aparecer
reduzida (por exemplo 900x2000). Converta antes de tocar:

```text
x_real = x_imagem * 1080 / largura_imagem
y_real = y_imagem * 2400 / altura_imagem
```

Para capturar sem criar arquivo no celular:

```sh
adb -s 192.168.3.17:43161 exec-out screencap -p > /tmp/opencode/shots/home.png
```

O helper `$S shot home` já faz isso.

## Quando der errado

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| `failed to connect` ou `Connection refused` | Porta de conexão mudou, depuração desligada ou IP mudou | Abra a tela de depuração sem fio, confira IP:porta e reconecte |
| `protocol fault (couldn't read status message): Success` | Usou a porta de pareamento errada/expirada | Reabra **Parear dispositivo com código** e use a porta e o código atuais |
| `more than one device/emulator` | Emulador e celular conectados | Use `-s SERIAL` ou o helper |
| `unauthorized` | Diálogo de RSA não aceito | Desbloqueie o celular e aceite **Permitir depuração USB** |
| `offline` | ADB perdeu a sessão | `adb disconnect SERIAL` e `adb connect IP:PORTA` |
| `adb mdns services` vazio | mDNS indisponível ou tela fechada | Use a porta mostrada no celular; mDNS é só atalho |
| App instala mas não abre | APK de arquitetura errada | Use `--target-platform android-arm64` |
| API não encontra o PC | Redes diferentes ou firewall | Confirme o mesmo Wi-Fi e teste `http://IP_DO_PC:7882/api/v1/mods` no navegador do celular |

## Encerramento

- `$S allow-sleep` para devolver a tela ao comportamento normal.
- `$S stop` para fechar o app.
- Não deixe mock, mDNS ou servidores de teste rodando sem necessidade.
- O celular é exclusivo para testes; não use o emulador para validar rede.
