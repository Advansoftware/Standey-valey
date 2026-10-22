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

Também tem:

- **Busca offline** em português, com acentos e sinônimos, que varre a enciclopédia e a wiki embutida.
- **Wiki offline**: 1.300 páginas da wiki em português, dentro do app, para ler sem internet.
- **Calendário** com aniversários e festivais, e a data do jogo que você está acompanhando.
- **Favoritos** e **progresso**: marque o que já pescou, plantou ou entregou.
- **Checklist** dos pacotes do Centro Comunitário, com barra de progresso.
- **Tema claro e escuro**, seguindo o sistema.
- **Assistente com IA local**: você pergunta ("o que faço no primeiro dia?") e ele procura no conteúdo do app.
  Baixando um modelo uma única vez, ele passa a escrever a resposta no próprio celular, sem enviar nada
  para a internet. Sem o modelo, mostra os trechos mais parecidos com a pergunta.

### Modelos de IA

O assistente deixa você escolher o modelo (o botão fica na aba Assistente):

| Modelo | Download | RAM indicada | Quando usar |
|---|---|---|---|
| **Gemma 4 E4B** (padrão) | 3,7 GB | 8 GB+ | Melhor resposta;celulares com 8 GB ou mais |
| Gemma 4 E2B | 2,6 GB | 4 GB+ | Mais leve e rápido, um pouco menos esperto |
| Qwen3 4B | 2,7 GB | 6 GB+ | Alternativa rápida, muito boa em português |
| LFM2.5 1.2B | 740 MB | 3 GB+ | Aparelhos fracos ou internet lenta |
| Qwen3 0.6B | 340 MB | 2 GB+ | O menor de todos, roda em qualquer aparelho |
| Gemma 4 12B | 6,9 GB | 16 GB+ | Só para celulares muito fortes |

Também dá para colar o endereço de qualquer outro arquivo `.litertlm`.

## Rodando

Precisa do Flutter 3.44+ (Dart 3.12+) instalado.

```bash
bash tools/setup_android.sh        # cria a pasta android/ (minSdk 30, permissão de internet)
bash tools/setup_android_visual.sh # cor do splash e ícone (o ícone em si: python3 tools/make_icon.py)
flutter pub get
flutter run
```

Pra gerar o APK: `flutter build apk --release --target-platform android-arm64`.
O `codemagic.yaml` faz isso no Codemagic.

Testes: `flutter test` (20 testes que percorrem todas as telas) e `flutter analyze`.

## De onde vêm os dados

Os dados e os sprites vêm do pacote npm [stardew-valley-data](https://www.npmjs.com/package/stardew-valley-data) (MIT).
Os scripts em `tools/seed` traduzem os nomes e geram os JSON que o app lê:

```bash
bash tools/seed/fetch_dataset.sh
python3 tools/seed/build_seed.py
python3 tools/seed/verify.py
```

O texto de referência vem da [wiki em português](https://pt.stardewvalleywiki.com) (CC BY-NC-SA 3.0).
O `tools/scrape_wiki.py` baixa as páginas e monta o corpus offline que o app lê:

```bash
python3 tools/scrape_wiki.py       # gera assets/wiki/pages.json.gz e assets/data/names_pt.json
```

## Pastas

- `lib/`: o app (telas, busca, IA, tema)
- `assets/`: JSON, sprites do jogo e a wiki offline
- `tools/seed/`: scripts que geram o conteúdo
- `tools/scrape_wiki.py`: baixa a wiki em português
- `tools/make_icon.py`: gera o ícone do app
- `HANDOFF.md` e `PROGRESSO.md`: notas do desenvolvimento

## Créditos

Stardew Valley e a arte do jogo são de ConcernedApe; os sprites estão aqui só como guia de fã.
O texto de referência vem da [wiki](https://pt.stardewvalleywiki.com) (CC BY-NC-SA 3.0).
App por Bruno Antunes, Advansoftware.
