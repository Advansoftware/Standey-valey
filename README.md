# 🌾 Guia do Vale

Enciclopédia de **Stardew Valley** em **português do Brasil**, no estilo Pokédex, para Android.
Pensada para quem começou a jogar hoje e quer saber *o que é o quê* e *como progredir*.

> Projeto de fã, sem fins comerciais. Não é afiliado à ConcernedApe.

## ✨ Recursos

- **563 entradas em 16 categorias:** guia do iniciante, culturas, peixes, moradores, festivais, Centro Comunitário, coletáveis, habilidades, animais, árvores, minerais, monstros, culinária, artefatos, construções e ferramentas.
- **Sprites reais do jogo** em todas as entradas, com galeria de fases (sementes e estágios de crescimento das culturas e árvores). Dá para distinguir carvalho, bordo e pinheiro pela semente e pelo desenho.
- **100% offline:** dados e imagens ficam dentro do app.
- **Assistente com IA local (RAG):** busca no conteúdo do app (BM25 no próprio aparelho) e, se você baixar o modelo uma vez, gera as respostas com um LLM que roda no celular. Sem o modelo, mostra os trechos mais parecidos com a pergunta.
- Calendário com aniversários e festivais, favoritos, checklists (pacotes do Centro Comunitário), progresso por categoria e tema claro/escuro.

## 🧱 Tecnologia

Flutter (Material 3), `shared_preferences`, `flutter_edge_ai` + LiteRT-LM (modelo Qwen3 0.6B). Android arm64, minSdk 30.

## 🛠️ Como rodar

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) estável.

```bash
bash tools/setup_android.sh      # gera a pasta android/ (minSdk 30, permissão de internet)
flutter pub get
flutter run                      # ou:
flutter build apk --release --target-platform android-arm64
```

O repositório também traz `codemagic.yaml` para gerar o APK no [Codemagic](https://codemagic.io).

## 🗂️ Regenerar os dados

Os dados e os sprites vêm do pacote npm [`stardew-valley-data`](https://www.npmjs.com/package/stardew-valley-data) (MIT).

```bash
bash tools/seed/fetch_dataset.sh   # baixa o pacote para tools/seed/.cache
python3 tools/seed/build_seed.py   # gera assets/data/*.json e copia os sprites para assets/img/
python3 tools/seed/verify.py       # confere imagens ausentes e ids duplicados
```

## 📁 Estrutura

```
lib/         app Flutter (telas, busca BM25, serviço de IA, tema)
assets/      data/ (JSON), img/ (sprites)
tools/seed/  geradores de conteúdo e tradução de nomes
HANDOFF.md   estado atual e pendências do projeto
```

## ⚠️ Status

Em desenvolvimento. O código ainda precisa passar por `flutter analyze` e testes em aparelho. Veja as pendências no [HANDOFF.md](HANDOFF.md).

## 📜 Créditos e licenças

- Stardew Valley e toda a arte do jogo © ConcernedApe. Os sprites são usados aqui apenas em um guia de fã, sem fins comerciais.
- Dados e imagens extraídos do pacote `stardew-valley-data` (MIT).
- Referência de conteúdo: [Stardew Valley Wiki](https://pt.stardewvalleywiki.com) (CC BY-NC-SA 3.0).
- O código do app é de Bruno Antunes (Advansoftware).
