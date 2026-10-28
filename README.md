# Guia do Vale

Um app de Android com tudo sobre Stardew Valley, em português. Comecei a jogar e vivia abrindo a wiki
no navegador pra descobrir qual árvore era qual, o que plantar na primavera ou o que a Abigail gosta de ganhar.
Resolvi juntar isso num app só. O conteúdo funciona sem internet, e o assistente de IA pode rodar no
próprio celular ou usar um provedor web (OpenAI, Gemini ou Anthropic) com a sua chave.

Projeto de fã, sem fins comerciais, sem ligação com a ConcernedApe.

## O que tem

São 565 entradas em 16 categorias: guia do iniciante, culturas, peixes, moradores, festivais, Centro Comunitário,
coletáveis, habilidades, animais, árvores, minerais, monstros, culinária, artefatos, construções e ferramentas.
As entradas de guia incluem um roteiro por estação, um guia de árvores e um guia de lavoura que explica rega,
espantalho, treliça e o fim da estação sem repetir as fichas de culturas.

Todas têm o desenho do jogo. Nas árvores e culturas dá pra ver a semente e cada fase de crescimento, então
carvalho, bordo e pinheiro deixam de ser um mistério (bolota, semente de bordo e pinha, respectivamente).

Também tem:

- **Busca offline** em português, com acentos e sinônimos, que varre a enciclopédia e a wiki embutida.
- **Wiki offline**: 1.300 páginas da wiki em português, dentro do app, para ler sem internet.
- **Calendário** com aniversários e festivais, e a data do jogo que você está acompanhando.
- **Favoritos** e **progresso**: marque o que já pescou, plantou ou entregou.
- **Integração opcional com o jogo no PC**: conecte o app à Stardew Web API na mesma rede e ele
  traz a data, a mochila e as amizades do save aberto. Sem a API, tudo continua funcionando offline.
- **Meu Status**: quando a API está conectada, o item central do menu abre um painel imersivo
  (tela cheia, deitada, com a tela ligada) que reúne localização, vitais, mochila, missões,
  amizades, habilidades, conquistas e o próximo passo do dia. O plano do guia funciona sem IA;
  o botão **AJUDA** pede até 3 objetivos ao conselheiro, com lugar e motivo. Tocar num passo, na
  missão ou numa dica abre um quadro, sem sair da tela, que explica por que aquele é o próximo passo,
  como fazer e o que você ganha, com base na wiki e no seu save. As explicações dos passos ficam
  prontas junto com o plano, então o quadro abre já completo. Tocar num item da mochila mostra para
  que serve, o preço, onde achar e quanto vale a pilha.
- **Mapa do Vale** com orientação norte/sul, pinos por região, zoom e uma ficha curta de cada lugar
  (fazenda, vila, montanha, minas, praia, floresta, deserto e Ilha Gengibre), com atalho para a wiki offline.
- **Checklist** dos pacotes do Centro Comunitário, com barra de progresso.
- **Tema claro e escuro**, seguindo o sistema.
- **Assistente com IA**: você pergunta ("o que faço no primeiro dia?") e escolhe quem responde: um
  modelo **no celular** (offline) ou um provedor **web** (OpenAI, Google Gemini ou Anthropic, com a sua
  chave de API). O modelo local padrão é o **Espírito do Vale**, uma IA treinada só com Stardew Valley.
  Com o jogo conectado, o assistente também enxerga o seu save (data, dinheiro, mochila, missões,
  amizades) e responde sobre o seu jogo. Sem IA configurada, mostra os trechos do app mais parecidos
  com a pergunta.

### Modelos de IA

A tela **Configurar IA** (ícone no topo do Assistente, ou em Sobre e ajustes) define quem responde.
Dá para trocar a qualquer momento, e a tela muda na hora.

**Provedores web**: OpenAI, Google Gemini e Anthropic. Cole a sua chave de API; o app busca na API do
provedor os modelos de texto que a chave pode usar e mostra numa lista para escolher. O botão **Testar
modelo** faz uma pergunta curta e mostra se respondeu e em quanto tempo. A chave fica salva só no
celular e o uso é cobrado na sua conta do provedor. Os provedores web entendem melhor perguntas longas
e difíceis.

**No celular**: baixe um ou mais modelos e escolha qual usar. Trocar para um modelo já baixado não
baixa de novo nem precisa de internet, e dá para apagar o que não usa:

| Modelo | Download | RAM indicada | Quando usar |
|---|---|---|---|
| **Espírito do Vale** (padrão) | 620 MB | 2 GB+ | Treinado com a wiki inteira; responde sem RAG e roda em qualquer celular |
| Gemma 4 E4B | 3,7 GB | 8 GB+ | Modelo genérico com RAG; celulares com 8 GB ou mais |
| Gemma 4 E2B | 2,6 GB | 4 GB+ | Mais leve e rápido, um pouco menos esperto |
| Qwen3 4B | 2,7 GB | 6 GB+ | Alternativa rápida, muito boa em português |
| LFM2.5 1.2B | 740 MB | 3 GB+ | Aparelhos fracos ou internet lenta |
| Qwen3 0.6B | 340 MB | 2 GB+ | O menor de todos, roda em qualquer aparelho |
| Gemma 4 12B | 6,9 GB | 16 GB+ | Só para celulares muito fortes |

Também dá para colar o endereço de qualquer outro arquivo `.litertlm`.

## Integração com o jogo (opcional)

Se você joga no PC, dá para ligar o app ao save aberto pela
[Stardew Web API](https://github.com/Advansoftware/StardewWebApi) — um fork do
[projeto original do zunderscore](https://github.com/zunderscore/StardewWebApi), com licença MIT.
A integração é opcional: ela só acrescenta dados e o app continua funcionando sem ela.

Na versão 0.7.0 do fork, a API anuncia o serviço `_stardewapi._tcp` na rede local e aceita conexões
na porta 7882 sem precisar de URLACL nem rodar o jogo como administrador. Os endpoints e os dados
do mod original não mudaram.

### Como ativar

1. Instale a API no PC (Stardew Valley 1.6 e a [última versão do SMAPI](https://github.com/Pathoschild/SMAPI/releases/latest); testado com a 4.5.2), em `Mods/StardewWebApi/`.
2. Abra o jogo e **carregue um save**. A API só responde os dados do mundo com um save aberto.
3. No celular, na mesma rede Wi-Fi: toque na engrenagem → **Sobre e ajustes** →
   **Servidor do jogo (API)**.
4. Toque em **Procurar na rede**. O app procura o anúncio `_stardewapi._tcp` por alguns segundos.
5. Se não encontrar, digite o endereço do PC (por exemplo, `http://192.168.0.10:7882`) e toque em
   **Conectar**.
6. Deixe o **Modo automático** ligado. Ele atualiza a data e o progresso a cada minuto e quando você
   volta para o app. A tela mostra o status e a hora da última sincronização.

A busca automática usa o `NsdManager` do Android; a URL manual funciona em qualquer Android.
A API 0.7.0 está publicada em
https://github.com/Advansoftware/StardewWebApi/releases/tag/0.7.0 — o zip inclui um `INSTALL.md`
com os links e os caminhos de instalação. O app 1.3.0 está em
https://github.com/Advansoftware/Standey-valey/releases/tag/v1.3.0.

### O que sincroniza

- **Data do jogo**: estação, dia, clima e nome da fazenda vêm de `/api/v1/world` e atualizam
  a data que o app acompanha.
- **Mochila**: os itens de `/api/v1/players/main/inventory` marcam automaticamente fichas de
  **peixes, coletáveis, minerais, culinária e ferramentas** que estão com você.
- **Amizades**: quem está em `/api/v1/players/main` com o coração máximo (10, ou 14 para cônjuge)
  tem a ficha de aldeão marcada.

A sincronização **nunca desmarca** o que você marcou à mão. Ela só acrescenta progresso. Se a API
ficar indisponível, o app segue com os dados offline e as marcações manuais intactas.

### O que continua manual

A API não expõe histórico nem eventos do save, então estas coisas continuam sendo marcadas por você:

- peixes que você já pescou e não estão mais na mochila (não há histórico de pesca);
- "já plantei" e histórico de colheitas;
- museu e doações ("já doei");
- monstros derrotados ("já derrotei");
- pacotes do Centro Comunitário concluídos;
- qualquer ficha que você queira marcar sem ter o item na mochila.

### Requisitos e rede

- Jogo aberto com um save carregado.
- Stardew Web API 0.7.0 instalada no PC.
- Celular e PC na mesma rede local. Redes de convidados com isolamento de clientes e VPNs podem
  impedir a descoberta e a conexão.
- Porta **7882** liberada no firewall do PC. No Windows, permita o acesso em redes privadas quando o
  sistema perguntar.
- Não precisa de administrador nem de URLACL: o fork encaminha a porta 7882 da rede local para o
  servidor que escuta em `localhost`.
- No Android, o app usa HTTP local (`usesCleartextTraffic`) para falar com a API.

### Privacidade e offline

A conexão é direta entre o celular e o seu PC, dentro da sua rede, sem conta nem nuvem. O app só manda
dados de jogo para a internet se você escolher um provedor web de IA: nesse caso, a pergunta, os trechos
do guia e o resumo do save vão para a API do provedor escolhido. Com o modelo no celular, nada sai do
aparelho. O tráfego é HTTP simples, sem TLS, e a API fica acessível a quem
estiver na mesma rede: use em rede confiável e não exponha a porta 7882 na internet. Sem a API, ou
com o jogo fechado, o app abre e funciona normalmente com o conteúdo embutido.

## IA: como funciona

Com um modelo **no celular**, o assistente não manda a pergunta para nenhum servidor. Com um provedor
**web**, a pergunta, os trechos do guia e (se o jogo estiver conectado) o resumo do save vão para a API
escolhida, direto do celular. Há três modos:

- **Provedores web (OpenAI, Gemini, Anthropic) com RAG**: recebem uma instrução de sistema pedindo
  respostas diretas, sem perguntas de volta, e a pergunta com até 24 mil caracteres de trechos (veja
  abaixo), o save ao vivo e as últimas falas da conversa, para entender continuações como "e quanto
  carvão ela gasta?". OpenAI usa a API Responses; Gemini, `streamGenerateContent`; Anthropic, Messages.
  Todos em streaming.

- **Espírito do Vale (sem RAG)**: o modelo recebe só a pergunta. Os fatos do jogo estão nos pesos do
  modelo, aprendidos no fine-tuning (veja a próxima seção). O mesmo modelo faz o Conselheiro do
  **Meu Status**: recebe o resumo do save e devolve até 3 linhas `AÇÃO | LUGAR | MOTIVO`, que viram cartões.
- **Modelos genéricos (Gemma, Qwen3, LFM) com RAG**, descrito abaixo.

No modo com RAG, o app combina técnicas simples e verificáveis:

- **RAG local** (`lib/ai_rag.dart`): a pergunta vira uma busca BM25 no conteúdo do app (fichas + cerca de
  9.900 trechos da wiki), com quatro ajustes para perguntas escritas como se fala:
  - palavras de conversa ("estou tentando", "faz tempo", "não consigo") saem da busca;
  - se a pergunta cita o nome de uma página ou ficha ("fornalha", "argila", "galinheiro"), o começo da
    página e o trecho dela que mais combina entram primeiro;
  - trechos de falas de moradores perdem peso, a menos que o morador seja citado;
  - na continuação de uma conversa, a pergunta anterior e as páginas citadas nela também entram.
  Nos provedores web, as páginas mais relevantes entram com os trechos vizinhos, e as tabelas da wiki
  mantêm as células separadas para o modelo não misturar colunas. `test/rag_test.dart` confere as
  perguntas reais que a busca antiga errava.
- **Prompt com papel e formato**: o modelo recebe instruções para responder em português, dizer para que serve,
  quanto rende e prós/contras quando esses dados existirem, usar listas com hífen e **negrito**, e não inventar
  o que não está no contexto.
- **Inferência no aparelho**: o arquivo `.litertlm` roda via `flutter_edge_ai`; o download é único e pode
  continuar em segundo plano com notificação. Sem modelo instalado, o app não trava: mostra os trechos mais
  parecidos com a pergunta (fallback extrativo).
- **Pós-processamento**: a resposta é limpa de tokens especiais e renderizada por um Markdown leve feito no
  projeto (negrito, itálico, código e listas), sem pacote externo e sem mostrar `*asteriscos*` literais.

A tela Configurar IA permite trocar de modelo, apagar modelos baixados ou colar a URL de outro `.litertlm`.

`test/ai_cloud_test.dart` simula as três APIs num servidor local. Para testar contra a OpenAI de
verdade: `OPENAI_API_KEY=sk-... flutter test test/ai_cloud_live_test.dart` (sem a variável, o teste é
pulado; no app a chave é sempre digitada na tela).

## Espírito do Vale: o modelo treinado

O Espírito do Vale é o **Qwen3-0.6B** com fine-tuning completo (todos os pesos) para Stardew Valley, em
português. Ele foi escolhido por ser pequeno o bastante para qualquer celular (620 MB em int8, cerca de
5 s por resposta na GPU de um Galaxy S20 FE) e bom em português.

### Como foi feito

1. **Dados gerados do próprio app** (`tools/modelo/`). Nada foi escrito à mão: os scripts leem as 565 fichas
   da enciclopédia, os guias e as 1.300 páginas da wiki offline e montam cerca de 24 mil pares
   pergunta → resposta:
   - perguntas sobre cada campo de cada ficha (estação, preço, onde achar, presentes, horário de pesca…),
     em várias formas de perguntar, com e sem acento;
   - a ficha completa de cada item, cada seção dos guias e trechos da wiki;
   - recusas para perguntas fora do jogo ("Qual a capital da França?") e para itens que não existem;
   - 1.500 cenários sintéticos do Conselheiro: o script replica o prompt do Meu Status e as regras de
     prioridade do app (missão, aniversário, festival, energia, clima…) para ensinar o formato
     `AÇÃO | LUGAR | MOTIVO`.
2. **Treino no Google Colab** (GPU L4): 4 épocas, bf16, taxa de aprendizado 2e-5, lote efetivo 32,
   gradient checkpointing, cerca de 2h45 por rodada. O melhor checkpoint pela perda de validação é o que fica.
3. **Avaliação antes de ir para o celular** (`evaluate.py`), com perguntas reformuladas que o modelo nunca
   viu. Rodada 2: 99,3% dos fatos corretos, 206/208 respostas perfeitas, 13/15 perguntas reais,
   nenhuma resposta em loop e 60/60 no formato e na prioridade do Conselheiro.
4. **Conversão para LiteRT-LM** (`litert-torch export_hf`, pesos int8) e **troca do template de conversa**
   (`patch_template.py`). O template original do Qwen3 só lê texto puro; o plugin do app manda a
   mensagem em partes, e a pergunta chegava vazia. O template novo gera exatamente o prompt do treino.
5. **Teste no celular** (chat e Conselheiro com a API simulada) e só então publicação no
   [Hugging Face](https://huggingface.co/brunoantunes100/stardew-guia-qwen-0.5b). O modelo não vai dentro
   do APK: o app baixa uma vez e roda offline.

### Como treinar de novo

O passo a passo completo está na skill [`.claude/skills/treinar-ia`](.claude/skills/treinar-ia/SKILL.md).
Em resumo:

```bash
cd tools/modelo
python build_status_dataset.py && python build_dataset_closed.py   # dados em closed/ e status/
# envie train.py, evaluate.py, closed/ e status/ para o Colab e rode colab_rodada.py
python patch_template.py modelo.litertlm modelo_fix.litertlm        # obrigatório depois da conversão
HF_TOKEN=... python upload_model.py modelo_fix.litertlm "mensagem"  # substitui o modelo publicado
```

Para corrigir uma resposta errada, corrija a fonte (os assets do app ou o gerador de perguntas) e treine
de novo. Não edite o dataset à mão: ele é regenerado a cada rodada.

## Como o projeto foi construído (com IA)

O app, os scripts de dados e os testes foram desenvolvidos em pair programming com IA, com o autor definindo
os requisitos, revisando cada mudança e validando o resultado no emulador e no celular. Foram usadas:

- **OpenCode com DeepSeek V4.1 Flash Free** (gratuito) nas primeiras versões: enciclopédia, wiki offline,
  busca, RAG, mapa e integração com a API.
- **Claude Code com Claude Opus** (pago) a partir da v1.5: redesenho no estilo do jogo, Meu Status ao vivo
  via WebSocket, atualizador do app e o fine-tuning do Espírito do Vale.
- **Google Colab com GPU L4** (unidades de computação pagas) para treinar e converter o modelo.

O app em si não usa API paga nem manda dados para a internet.

Não foi "pedir um app pronto": o trabalho foi dividido em etapas pequenas, com verificação automática e
manual em cada uma.

- **Pipeline de dados reproduzível**: `fetch_dataset.sh` → `build_seed.py` → `verify.py`, com checagem de IDs,
  imagens e campos obrigatórios. O mesmo script gera as 16 categorias e as fichas de guia.
- **Wiki offline própria**: scraper em Python com `curl` e User-Agent de navegador, corpus dividido em trechos
  para a busca. O app não depende da wiki estar no ar.
- **Busca testável**: BM25 com stop words em português, boost de título e expansão por prefixo. Os testes cobrem
  perguntas naturais ("me explique sobre pinheiro", "vantagens de plantar um pinheiro").
- **Prompt e chat testados**: testes garantem que o prompt pede utilidade, preço e prós/contras, e que o chat
  não mostra asteriscos literais.
- **QA no emulador e no celular**: cada tela foi aberta no Pixel 7 API 35 e o fluxo da API foi testado
  em um Samsung SM-G781B físico, na mesma rede do PC, com capturas e correções de layout e reatividade.
  A skill `.opencode/skills/android-phone-test` guarda o passo a passo do ADB sem fio.
- **Registro de decisões**: `PROGRESSO.md` e `HANDOFF.md` guardam o estado, os comandos e as armadilhas
  (por exemplo: `.litertlm` não roda no emulador x86_64; é preciso testar a busca nele).
- **Builds otimizados**: Gradle com 10 GB de heap, cache, configuração sob demanda e 16 workers, para usar
  a máquina de 16 núcleos.

## Rodando

Precisa do Flutter 3.44+ (Dart 3.12+) instalado.

```bash
bash tools/setup_android.sh        # cria a pasta android/ (minSdk 30, permissão de internet)
bash tools/setup_android_visual.sh # cor do splash e ícone (o ícone em si: python3 tools/make_icon.py)
flutter pub get
flutter run
```

A API não é necessária para rodar o app. Se for mexer nela, o submódulo vem junto com
`git submodule update --init --recursive`; os comandos de build estão no `HANDOFF.md`.

Pra gerar o APK: `flutter build apk --release --target-platform android-arm64`.
O build é local; o GitHub Actions do fork não é usado.

Testes: `flutter test` (49 testes que percorrem as telas, o mapa, a busca, os guias e a API) e `flutter analyze`.

Para testar no celular físico via ADB sem fio, use a skill
`.opencode/skills/android-phone-test` (passo a passo e helper `phone.sh`).

## De onde vêm os dados

Os dados e os sprites vêm do pacote npm [stardew-valley-data](https://www.npmjs.com/package/stardew-valley-data) (MIT).
Os scripts em `tools/seed` traduzem os nomes e geram os JSON que o app lê:

```bash
bash tools/seed/fetch_dataset.sh
python3 tools/seed/build_seed.py
python3 tools/seed/verify.py
```

O texto de referência vem da [wiki em português](https://pt.stardewvalleywiki.com) (CC BY-NC-SA 3.0).
O mapa do vale em `assets/img/map_valley.png` veio da wiki em inglês (mesma licença) e é usado só para
orientação; os pinos e os textos curtos de cada lugar são do app.
O `tools/scrape_wiki.py` baixa as páginas e monta o corpus offline que o app lê:

```bash
python3 tools/scrape_wiki.py       # gera assets/wiki/pages.json.gz e assets/data/names_pt.json
```

## Pastas

- `lib/`: o app (telas, busca, IA, tema)
- `lib/game_api.dart`: cliente e sincronização com a Stardew Web API (opcional)
- `StardewWebApi/`: submódulo com o fork da API do jogo (mDNS + porta 7882)
- `assets/`: JSON, sprites do jogo e a wiki offline
- `tools/seed/`: scripts que geram o conteúdo
- `tools/scrape_wiki.py`: baixa a wiki em português
- `tools/make_icon.py`: gera o ícone do app
- `tools/modelo/`: dataset, treino, avaliação e publicação do Espírito do Vale
- `HANDOFF.md` e `PROGRESSO.md`: notas do desenvolvimento

## Créditos

Stardew Valley e a arte do jogo são de ConcernedApe; os sprites estão aqui só como guia de fã.
O texto de referência vem da [wiki](https://pt.stardewvalleywiki.com) (CC BY-NC-SA 3.0).
A [Stardew Web API](https://github.com/zunderscore/StardewWebApi) é de zunderscore e contribuidores
(licença MIT); o fork com descoberta local é o
[Advansoftware/StardewWebApi](https://github.com/Advansoftware/StardewWebApi).
App por Bruno Antunes, Advansoftware.
