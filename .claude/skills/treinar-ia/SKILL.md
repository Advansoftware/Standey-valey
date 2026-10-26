---
name: treinar-ia
description: Treinar de novo o Espírito do Vale (IA própria do Guia do Vale, Qwen3-0.6B sem RAG), avaliar, converter para .litertlm, corrigir o template, testar no celular e substituir o modelo publicado no Hugging Face. Use quando pedirem para treinar, melhorar, corrigir ou republicar a IA do app.
---

# Treinar e substituir o Espírito do Vale

O Espírito do Vale é um **Qwen3-0.6B com fine-tuning completo** que responde **sem RAG**: os fatos do
jogo ficam nos pesos. O app manda só a pergunta (`buildPrompt` com `isFineTuned`) e o Conselheiro do
Meu Status manda o prompt de `buildStatusPrompt`, esperando linhas `AÇÃO | LUGAR | MOTIVO`.
Os outros modelos (Gemma etc.) continuam com RAG.

O modelo **não vai dentro do APK**. O app baixa
`https://huggingface.co/brunoantunes100/stardew-guia-qwen-0.5b/resolve/main/stardew_qwen_0.5b.litertlm`.
O repositório e o nome do arquivo **não mudam** (o "0.5b" é histórico): versões já instaladas baixam
esse arquivo. Para trocar o modelo, basta substituir esse arquivo; o app só precisa de versão nova
se o formato do prompt mudar.

## Arquivos

| Onde | O quê |
|---|---|
| `tools/modelo/build_dataset_closed.py` | Dataset do chat (enciclopédia + guias por seção + wiki + conselheiro). Saída em `tools/modelo/closed/` |
| `tools/modelo/build_status_dataset.py` | Dataset do Conselheiro; replica `buildStatusPrompt` e as regras de prioridade. Rode **antes** do anterior. Saída em `tools/modelo/status/` |
| `tools/modelo/app_replica.py`, `build_dataset_v2.py` | Leitura dos assets do app e geradores de perguntas usados pelo dataset |
| `tools/modelo/train.py` | Treino (`--full`, bf16, gradient checkpointing, guarda o melhor checkpoint em `out/merged`) |
| `tools/modelo/evaluate.py` | Avaliação: paráfrases inéditas, amostra do treino, perguntas reais, loops e `--status` |
| `tools/modelo/colab_rodada.py` | Dispara treino → avaliação → conversão no Colab em segundo plano (edite `RODADA` e `BASE`) |
| `tools/modelo/colab_watch.sh` | Acompanha a rodada e sai no `FIM` ou em erro |
| `tools/modelo/patch_template.py` | **Obrigatório** depois da conversão (ver abaixo) |
| `tools/modelo/upload_model.py` | Publica no Hugging Face com `HF_TOKEN` do ambiente |
| `C:\modelo\colab_venv` | venv com a Colab CLI (`googlecolab/google-colab-cli`) |
| `C:\modelo\rodadas\` | Resultados de cada rodada: `rN_model.litertlm`, `rN_model_fix.litertlm`, `rN_merged.tgz`, `eval_rN.*` |

## Passo a passo

1. **Corrigir os dados.** Erro de fato → ajuste a geração em `build_dataset_closed.py` (ou os assets do
   app, que são a fonte). Erro do Conselheiro → ajuste `build_status_dataset.py` e, se a regra mudou no
   app, mantenha o espelho de `recommendedNextStep`/`buildStatusTips`/`buildStatusPrompt` em dia.
   ```sh
   cd tools/modelo && python build_status_dataset.py && python build_dataset_closed.py
   ```
2. **Subir para o Colab** (GPU L4). No Windows/Git Bash use sempre
   `MSYS_NO_PATHCONV=1 PYTHONIOENCODING=utf-8` e caminhos Windows em `-f`.
   ```sh
   C=/c/modelo/colab_venv/Scripts/colab
   $C new -s train3 --gpu L4
   tar czf v2.tgz -C tools/modelo train.py evaluate.py app_replica.py closed status
   $C upload -s train3 v2.tgz /content/v2.tgz
   # extraia: um .py com subprocess.run('mkdir -p /content/v2 && tar xzf /content/v2.tgz -C /content/v2', shell=True)
   $C exec -s train3 -f 'C:\...\tools\modelo\colab_rodada.py'
   bash tools/modelo/colab_watch.sh train3 r3   # rode em segundo plano; ~3 h no total
   ```
   O treino leva ~2h45 (4 épocas, ~24 mil exemplos), a avaliação ~5 min e a conversão ~15 min.
   Rodar com `subprocess.Popen(start_new_session=True)` é o que deixa o processo vivo se a conexão cair.
3. **Ler a avaliação** (`/content/eval_rN.log`). Metas: fatos em paráfrases inéditas ≥ 99%,
   perguntas reais 15/15, 0 loops, Conselheiro 60/60 em formato e prioridade. Abaixo disso, volte ao 1.
4. **Baixar e desligar a sessão** (cada hora parada gasta créditos):
   ```sh
   $C download -s train3 /content/conv_r3/model.litertlm 'C:\modelo\rodadas\r3_model.litertlm'
   $C download -s train3 /content/eval_r3.log 'C:\modelo\rodadas\eval_r3.log'
   # checkpoint para a próxima rodada: tar czf /content/r3_merged.tgz -C /content/out_r3 merged
   $C stop -s train3
   ```
5. **Corrigir o template (obrigatório).** O conversor embute o template original do Qwen3, que lê
   `message.content` como texto. O `flutter_edge_ai` manda o conteúdo em partes
   (`[{type: text, text: ...}]`), então a pergunta chegava **vazia** e o modelo respondia qualquer
   coisa. O script troca o template, mantendo o tamanho em bytes, por um que gera exatamente o
   prompt do treino: `<|im_start|>user\n{pergunta}<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n`.
   ```sh
   python tools/modelo/patch_template.py C:/modelo/rodadas/r3_model.litertlm C:/modelo/rodadas/r3_model_fix.litertlm
   ```
6. **Testar no celular antes de publicar** (skill `android-phone-test` para conectar o ADB):
   - `python -m http.server 8765 --bind 127.0.0.1` em `C:\modelo\rodadas` e `adb reverse tcp:8765 tcp:8765`.
   - App de debug → Assistente → "Usar outro arquivo (.litertlm)" →
     `http://127.0.0.1:8765/r3_model_fix.litertlm` → Baixar. Para trocar um modelo já instalado,
     limpe os dados do app (`adb shell pm clear br.com.advansoftware.stardew_guia`).
   - Pergunte: "O que a Abigail ama?", "Onde pescar o baiacu?", "Qual árvore é o carvalho?",
     "como conseguir uma galinha", "Qual a capital da França?" (deve recusar).
   - Conselheiro: suba o mock (`.opencode/skills/android-phone-test/scripts/mock_api.py`),
     `adb reverse tcp:7882 tcp:7882`, Ajustes → endereço `127.0.0.1:7882` → Meu Status → AJUDA.
     Devem sair até 3 cartões.
   - Desligue o servidor, o mock e `adb reverse --remove-all` no fim.
7. **Publicar** (substitui o modelo de todos os usuários — confirme com o dono antes):
   ```sh
   HF_TOKEN=... python tools/modelo/upload_model.py C:/modelo/rodadas/r3_model_fix.litertlm "Espírito do Vale rodada 3: ..."
   ```
   Nunca grave o token em arquivo, commit ou documentação. Confira o SHA-256 publicado
   (`HfApi().get_paths_info(...)[0].lfs.sha256`) e faça um download limpo no celular pelo botão
   padrão (sem URL personalizada).
8. Atualize `HANDOFF.md` (rodada, métricas, SHA-256) e, se mudou algo no app, a versão em
   `pubspec.yaml` + `currentAppVersion` e a release no GitHub.

## Armadilhas já resolvidas

- **`ModelType.qwen`, não `qwen3`**: com `qwen3` o plugin acrescenta " /no_think" a toda pergunta.
- **Template**: ver passo 5. Sintoma: respostas bem escritas sobre outro assunto ("O que é a Fazenda…").
- **GPU funciona**: a resposta na GPU (fp16) é igual à da CPU e sai em ~5 s em vez de ~13 s.
- **Decodificação**: o app usa `ask(..., exact: true)` para o modelo próprio (topK 1, temperatura 0),
  como na avaliação. Respostas longas cabem em 360 tokens.
- **OOM no Colab** com `max_len` 1024: mantenha `--bs 4 --accum 8` e gradient checkpointing.
- **Conversão só no Linux**: `litert-torch` não tem wheel para Windows; converta no Colab.
