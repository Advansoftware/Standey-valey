# -*- coding: utf-8 -*-
"""Troca o chat template embutido num .litertlm (Qwen3) por um que entende o
conteúdo em partes ([{type: text, text: ...}]) que o flutter_edge_ai envia.

O template original do Qwen3 só lê `message.content` como texto: a pergunta
chegava vazia no celular. O novo mantém exatamente o formato do treino:
<|im_start|>user\n{pergunta}<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n

Uso: python patch_template.py entrada.litertlm saida.litertlm
"""
import sys

import jinja2

TEMPLATE = r"""{%- macro text(c) -%}
{%- if c is string -%}{{- c -}}
{%- elif c is sequence -%}{%- for p in c -%}{%- if p['type'] == 'text' -%}{{- p['text'] -}}{%- endif -%}{%- endfor -%}
{%- endif -%}
{%- endmacro -%}
{%- for m in messages -%}
{%- if m['role'] in ['system', 'user', 'assistant'] -%}
{{- '<|im_start|>' + m['role'] + '\n' + text(m['content']) + '<|im_end|>\n' -}}
{%- endif -%}
{%- endfor -%}
{%- if add_generation_prompt -%}
{{- '<|im_start|>assistant\n<think>\n\n</think>\n\n' -}}
{%- endif -%}"""


def main(src, dst):
    d = bytearray(open(src, 'rb').read())
    start = d.find(b'{%- if tools %}')
    assert start > 0 and d.count(b'{%- if tools %}') == 1, 'template original não encontrado'
    # Campo de texto do protobuf: termina no último endif antes do próximo campo.
    stop = d.find(b'thought', start)
    end = d.rfind(b'{%- endif %}', start, stop) + len(b'{%- endif %}')
    old = bytes(d[start:end])
    new = TEMPLATE.encode('utf-8')
    pad = len(old) - len(new) - len('{##}')
    assert pad >= 0, 'template novo maior que o antigo'
    new = new + b'{#' + b' ' * pad + b'#}'
    assert len(new) == len(old)
    d[start:end] = new
    open(dst, 'wb').write(d)

    # Confere como fica o prompt nos dois formatos de mensagem.
    t = jinja2.Environment().from_string(new.decode('utf-8'))
    for c in ['O que a Abigail ama?', [{'type': 'text', 'text': 'O que a Abigail ama?'}]]:
        print(repr(t.render(messages=[{'role': 'user', 'content': c}], add_generation_prompt=True, enable_thinking=False)))
    print('ok', len(old), 'bytes')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
