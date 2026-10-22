# Guia do Vale

Um app de Android com tudo sobre Stardew Valley, em português. Comecei a jogar e vivia abrindo a wiki
no navegador pra descobrir qual árvore era qual, o que plantar na primavera ou o que a Abigail gosta de ganhar.
Resolvi juntar isso num app só, que funciona sem internet.

Projeto de fã, sem fins comerciais, sem ligação com a ConcernedApe.

## O que tem

São 563 entradas em 16 categorias: guia do iniciante, culturas, peixes, moradores, festivais, Centro Comunitário,
coletáveis, habilidades, animais, árvores, minerais, monstros, culinária, artefatos, construções e ferramentas.

Todas têm o desenho do jogo. Nas árvores e culturas dá pra ver a semente e cada fase de crescimento, então
carvalho, bordo e pinheiro deixam de ser um mistério (bolota, semente de bordo e pinha, respectivamente).

Também tem calendário com aniversários e festivais, favoritos, checklist dos pacotes do Centro Comunitário
e tema claro e escuro.

Existe ainda um assistente: você pergunta algo ("o que faço no primeiro dia?") e ele procura no conteúdo do app.
Se você baixar um modelo de IA uma única vez (uns 350 MB), ele passa a escrever a resposta no próprio celular.
Sem o modelo, mostra os trechos mais parecidos com a pergunta.

## Rodando

Precisa do Flutter instalado.

```bash
bash tools/setup_android.sh   # cria a pasta android/ (minSdk 30, permissão de internet)
flutter pub get
flutter run
```

Pra gerar o APK: `flutter build apk --release --target-platform android-arm64`.
O `codemagic.yaml` faz isso no Codemagic.

## De onde vêm os dados

Os dados e os sprites vêm do pacote npm [stardew-valley-data](https://www.npmjs.com/package/stardew-valley-data) (MIT).
Os scripts em `tools/seed` traduzem os nomes e geram os JSON que o app lê:

```bash
bash tools/seed/fetch_dataset.sh
python3 tools/seed/build_seed.py
python3 tools/seed/verify.py
```

## Pastas

- `lib/`: o app (telas, busca, IA, tema)
- `assets/`: JSON e imagens
- `tools/seed/`: scripts que geram o conteúdo
- `HANDOFF.md`: notas sobre o que falta fazer

## Estado atual

Ainda em construção. O código não passou por `flutter analyze` nem foi testado num aparelho, então pode ter erro.
O que falta está no `HANDOFF.md`.

## Créditos

Stardew Valley e a arte do jogo são de ConcernedApe; os sprites estão aqui só como guia de fã.
O texto de referência vem da [wiki](https://pt.stardewvalleywiki.com) (CC BY-NC-SA 3.0).
App por Bruno Antunes, Advansoftware.
