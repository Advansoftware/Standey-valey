# -*- coding: utf-8 -*-
"""Publica o .litertlm do Espírito do Vale no Hugging Face.

O token vem SÓ da variável de ambiente HF_TOKEN (nunca escreva o token em arquivo).
O nome no repositório é fixo: as versões do app já publicadas baixam esse arquivo.

Uso: HF_TOKEN=... python upload_model.py arquivo.litertlm "mensagem do commit"
"""
import os
import sys

from huggingface_hub import HfApi

REPO_ID = 'brunoantunes100/stardew-guia-qwen-0.5b'
PATH_IN_REPO = 'stardew_qwen_0.5b.litertlm'


def main(path, message):
    token = os.environ.get('HF_TOKEN')
    if not token:
        sys.exit('Defina HF_TOKEN no ambiente.')
    print(f'Enviando {path} ({os.path.getsize(path) / 2**20:.1f} MB) para {REPO_ID}/{PATH_IN_REPO}...')
    info = HfApi(token=token).upload_file(path_or_fileobj=path, path_in_repo=PATH_IN_REPO,
                                          repo_id=REPO_ID, commit_message=message)
    print('ok', info)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
