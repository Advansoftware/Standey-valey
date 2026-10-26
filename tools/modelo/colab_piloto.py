# -*- coding: utf-8 -*-
"""Piloto no Colab: treino curto do Gemma 4 E2B -> avaliação -> conversão para .litertlm.

Confirma o caminho inteiro (treino, template, conversão) antes do treino grande.
Espera /content/v2 com train.py, evaluate.py, pilot/ e status/. Log em /content/p.log (termina em FIM).
"""
import subprocess

BASE = 'google/gemma-4-E2B-it'
cmd = rf"""cd /content/v2 && (pip install -q -U transformers accelerate litert-torch && pip list 2>/dev/null | grep -iE "^(torch|transformers|litert)") > /content/pip_p.log 2>&1 \
 && PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True python -u train.py --base {BASE} --data pilot --full --epochs 1 --lr 2e-5 --bs 8 --accum 4 --max_len 1024 --out /content/out_p > /content/p.log 2>&1 \
 && python evaluate.py --model /content/out_p/merged --data pilot --status status --out /content/eval_p.json > /content/eval_p.log 2>&1 \
 && echo AVALIADO >> /content/p.log \
 && cd /content && litert-torch export_hf --model=/content/out_p/merged --output_dir=/content/conv_p --externalize_embedder --jinja_chat_template_override=litert-community/gemma-4-E2B-it-litert-lm > /content/conv_p.log 2>&1 \
 ; echo FIM >> /content/p.log"""
subprocess.Popen(cmd, shell=True, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
print('piloto iniciado')
