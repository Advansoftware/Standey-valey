# -*- coding: utf-8 -*-
"""Roda no Colab (via `colab exec -f`): treino -> avaliação -> conversão, em segundo plano.

Espera os scripts e os dados em /content/v2 (train.py, evaluate.py, closed/, status/).
Edite RODADA antes de enviar. Saídas:
  /content/rN.log           progresso do treino (termina com AVALIADO e FIM)
  /content/eval_rN.log/.json resultado da avaliação
  /content/out_rN/merged     checkpoint (base da próxima rodada)
  /content/conv_rN/model.litertlm  modelo para o celular (ainda SEM o template corrigido:
                             rode patch_template.py no PC antes de publicar)
"""
import subprocess

RODADA = 'r3'
BASE = 'Qwen/Qwen3-0.6B'  # ou /content/out_r2/merged para continuar de uma rodada anterior

cmd = rf"""cd /content/v2 && PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True python -u train.py --base {BASE} --data closed --full --epochs 4 --lr 2e-5 --bs 4 --accum 8 --max_len 1024 --out /content/out_{RODADA} > /content/{RODADA}.log 2>&1 \
 && python evaluate.py --model /content/out_{RODADA}/merged --data closed --train_sample 200 --status status --out /content/eval_{RODADA}.json > /content/eval_{RODADA}.log 2>&1 \
 && echo AVALIADO >> /content/{RODADA}.log \
 && pip install -q litert-torch > /content/pip_conv.log 2>&1 \
 && cd /content && litert-torch export_hf --model=/content/out_{RODADA}/merged --output_dir=/content/conv_{RODADA} --quantization_recipe=dynamic_wi8_afp32 --bundle_litert_lm=True --use_jinja_template=True --cache_length=2048 --prefill_lengths=128,512 > /content/conv_{RODADA}.log 2>&1 \
 ; echo FIM >> /content/{RODADA}.log"""
subprocess.Popen(cmd, shell=True, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
print(f'rodada {RODADA} iniciada')
