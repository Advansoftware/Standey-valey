#!/usr/bin/env python3
"""Baixa a wiki PT-BR do Stardew Valley para uso offline (RAG do assistente).

Saídas:
  assets/wiki/pages.json.gz   -> [{"t": titulo, "u": url, "c": [trechos]}]
  assets/data/names_pt.json   -> {"NomeEmIngles": "Nome em PT"} (extraído dos infoboxes)

Notas importantes sobre a wiki:
  * A API MediaWiki (api.php) e o index.php são bloqueados pelo Cloudflare em
    vários ambientes. Por isso o script usa as "short URLs" (ex.:
    https://pt.stardewvalleywiki.com/Cenoura), que funcionam.
  * Páginas inexistentes respondem 503 (erro do cache) e são ignoradas.
  * O texto extraído é do site da wiki (CC BY-NC-SA 3.0) — o app cita isso.

Uso:
  python3 tools/scrape_wiki.py [--max-pages 1500] [--delay 0.8] [--seed S]...
"""

from __future__ import annotations

import argparse
import gzip
import html
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIKI = "https://pt.stardewvalleywiki.com"
UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/155.0.0.0 Safari/537.36"
)

# Páginas-índice que já organizam o jogo por assunto.
SEEDS = [
    "Guia_de_Introdução", "Lavouras", "Árvores", "Árvores_frutíferas", "Coleta",
    "Peixes", "Aldeões", "Monstros", "Minerais", "Artefatos", "Culinária",
    "Animais", "Ferramentas", "Habilidades", "Festivais", "Entregas", "Conjuntos",
    "Estações", "Clima", "Ciclo_do_dia", "Amizade", "Casamento", "Saúde",
    "Energia", "Anéis", "Chapéus", "Armas", "Calçados", "Mobília", "Missões",
    "Conquistas", "Recados_Secretos", "Isca", "Anzóis", "Artesanato", "O_jogador",
    "Energia", "Ciclo_do_dia", "A_Fazenda", "As_Minas", "Pedreira", "A_Caverna",
    "A_Praia", "A_Montanha", "Vila_Pelicanos", "Centro_Comunitário", "Peixaria",
    "Ferreiro", "Carpintaria", "Armazém_do_Pierre", "Mercado_Joja", "Saloon_Fruta_Estrelar",
    "Floresta_Cinzaseiva", "Bosque_Secreto", "Caverna_do_Vulcão", "Cabana_da_Bruxa",
    "Oásis", "Ilha_Gengibre", "O_Deserto", "Torre_do_mago", "Clínica_do_Harvey",
    "Celeiro", "Granja", "Museu", "Teatro", "Café", "Livros", "Mapas_da_Fazenda",
    "Mina_da_pedreira", "Guilda_dos_Aventureiros", "Carnival", "Rodeo",
]

# Títulos que nunca devem virar corpus.
SKIP_PREFIX = (
    "Ficheiro:", "File:", "Categoria:", "Category:", "Especial:", "Special:",
    "Ajuda:", "Help:", "Discussão:", "Talk:", "Usuário:", "User:", "Anexo:",
    "Template:", "Predefinição:", "Mediawiki:", "Módulo:", "Module:",
    "Stardew_Valley_Wiki:", "Modificações:", "Media:", "wikipedia:",
)
SKIP_EXACT = {
    "Stardew_Valley_Wiki", "Stardew_Valley", "ConcernedApe", "Página_de_principal",
}

# Sufixos do nome do arquivo de imagem que não fazem parte do nome em inglês.
_IMG_SUFFIX = re.compile(
    r"(\s+(seeds?|seed|semente|sementes|stage\s*\d*|est[aá]gio\s*\d*|fruits?|fruta|"
    r"quality|qualidade|iridium|gold|pristine|golden|finger|juice|sprite|icon|"
    r"head|body|tail|wing|head|face|item|head|heart))\b",
    re.IGNORECASE,
)


# --------------------------------------------------------------------------- HTTP


def http_get(url: str, timeout: int = 40) -> tuple[int, bytes]:
    """GET simples. Usa curl quando disponível (o Cloudflare bloqueia urllib)."""
    if shutil.which("curl"):
        cmd = [
            "curl", "-sS", "-L", "--compressed", "--max-time", str(timeout),
            "-A", UA,
            "-H", "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "-H", "Accept-Language: pt-BR,pt;q=0.9,en;q=0.8",
            "-w", "\n%{http_code}", url,
        ]
        try:
            out = subprocess.run(cmd, capture_output=True, timeout=timeout + 15)
        except subprocess.TimeoutExpired:
            return 0, b""
        data = out.stdout
        idx = data.rfind(b"\n")
        if idx < 0:
            return 0, data
        try:
            code = int(data[idx + 1:].strip() or 0)
        except ValueError:
            code = 0
        return code, data[:idx]

    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "pt-BR,pt;q=0.9"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception:
        return 0, b""


# --------------------------------------------------------------------------- HTML


def page_title(raw: str) -> str:
    """Título canônico da página (h1) — evita duplicatas com '_' ou espaços."""
    m = re.search(r'<h1[^>]*id="firstHeading"[^>]*>(.*?)</h1>', raw, flags=re.S)
    if not m:
        return ""
    t = re.sub(r"<[^>]+>", "", m.group(1))
    return html.unescape(t).strip()


def html_to_text(raw: str) -> str:
    """Converte HTML da wiki em texto simples, preservando tabelas como 'a | b'."""
    s = raw
    s = re.sub(r"<!--.*?-->", " ", s, flags=re.S)
    s = re.sub(r"<(script|style|noscript)\b.*?</\1>", " ", s, flags=re.S | re.I)
    # começa depois da tag que contém o conteúdo principal
    i = s.find('id="mw-content-text"')
    if i > 0:
        j = s.find(">", i)
        s = s[j + 1:] if j > 0 else s[i:]
    else:
        i = s.find('class="mw-parser-output"')
        if i > 0:
            j = s.find(">", i)
            s = s[j + 1:] if j > 0 else s[i:]
    for fim in ('<div class="printfooter"', 'id="footer-info"', 'class="navbox"'):
        j = s.find(fim)
        if j > 0:
            s = s[:j]
    # tabelas -> linhas "a | b | c"
    s = re.sub(r"<t[dh][^>]*>(.*?)</t[dh]>", r"\1", s, flags=re.S | re.I)
    s = re.sub(r"</tr>", "\n", s, flags=re.I)
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.I)
    s = re.sub(r"</(p|div|li|h[1-6]|tr|table|ul|ol)>", "\n", s, flags=re.I)
    s = re.sub(r"<li[^>]*>", "• ", s, flags=re.I)
    s = re.sub(r"<h([1-6])[^>]*>", lambda m: "\n" + "#" * int(m.group(1)) + " ", s, flags=re.I)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    # sobras de atributos (ex.: data-sort-value="100">) e caracteres soltos
    s = re.sub(r"[a-zA-Z-]+\s*=\s*\"[^\"]*\"", " ", s)
    s = re.sub(r"[a-zA-Z-]+\s*=\s*'[^']*'", " ", s)
    s = s.replace("<", " ").replace(">", " ")
    s = re.sub(r"[ \t\xa0]+", " ", s)
    s = re.sub(r" *\n *", "\n", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def page_links(raw: str) -> list[str]:
    """Links internos (títulos) da página."""
    out = []
    for m in re.finditer(r'href="/([^"#?]+)"', raw):
        t = urllib.parse.unquote(m.group(1)).replace("_", " ")
        if t.startswith(("mediawiki", "//")):
            continue
        out.append(t)
    return out


def infobox_en_name(raw: str) -> str | None:
    """Nome em inglês do item, tirado da imagem principal do infobox.

    Só páginas com infobox têm nome confiável: nas páginas-índice a primeira
    imagem é aleatória.
    """
    i = raw.find('id="infoboxtable"')
    if i < 0:
        return None
    body = raw[i:i + 4000]
    m = re.search(r'<img[^>]*alt="([^"]+)"', body)
    if not m:
        return None
    alt = html.unescape(m.group(1))
    if not alt.lower().endswith((".png", ".jpg", ".gif", ".jpeg")):
        return None
    base = re.sub(r"\.(png|jpg|jpeg|gif)$", "", alt, flags=re.I)
    base = _IMG_SUFFIX.sub("", base).strip()
    return base or None


def chunk(text: str, size: int = 900) -> list[str]:
    """Divide o texto em trechos respeitando parágrafos/linhas."""
    if not text:
        return []
    parts = [p.strip() for p in text.split("\n\n") if p.strip()]
    chunks: list[str] = []
    cur = ""
    for p in parts:
        if len(p) > size:
            if cur:
                chunks.append(cur)
                cur = ""
            for i in range(0, len(p), size):
                chunks.append(p[i:i + size])
            continue
        if cur and len(cur) + len(p) + 2 > size:
            chunks.append(cur)
            cur = p
        else:
            cur = f"{cur}\n\n{p}" if cur else p
    if cur:
        chunks.append(cur)
    return chunks


# ------------------------------------------------------------------------ crawl


def wanted(title: str) -> bool:
    if title in SKIP_EXACT:
        return False
    if title.startswith(SKIP_PREFIX):
        return False
    if title.startswith("//"):
        return False
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-pages", type=int, default=1500)
    ap.add_argument("--delay", type=float, default=0.8)
    ap.add_argument("--seed", action="append", default=[], help="página extra (repetível)")
    ap.add_argument("--out", default=os.path.join(ROOT, "assets/wiki/pages.json.gz"))
    ap.add_argument("--names-out", default=os.path.join(ROOT, "assets/data/names_pt.json"))
    args = ap.parse_args()

    seeds = list(dict.fromkeys(SEEDS + args.seed))
    seen: set[str] = set()
    pages: list[dict] = []
    names: dict[str, str] = {}
    queue: list[tuple[str, int]] = [(s, 0) for s in seeds]
    errors = 0
    t0 = time.time()

    while queue and len(pages) < args.max_pages:
        title, depth = queue.pop(0)
        key = title.replace(" ", "_")
        if key in seen:
            continue
        seen.add(key)
        url = WIKI + "/" + urllib.parse.quote(key)
        code, body = http_get(url)
        if code != 200 or not body:
            errors += 1
            if depth == 0:
                print(f"  [seed falhou] {code} {title}", file=sys.stderr)
            continue
        raw = body.decode("utf-8", "replace")

        # título canônico (evita duplicatas como "Mina da pedreira" e
        # "Mina_da_pedreira")
        canon = page_title(raw) or title
        ckey = canon.replace(" ", "_")
        if ckey != key:
            if ckey in seen:
                continue
            seen.add(ckey)
            title = canon
            url = WIKI + "/" + urllib.parse.quote(ckey)

        text = html_to_text(raw)
        if len(text) < 120:
            continue
        chunks = chunk(text)
        if chunks:
            pages.append({"t": title, "u": url, "c": chunks})

        # O nome em inglês só faz sentido em páginas de item (nas páginas-índice
        # a primeira imagem é aleatória).
        en = infobox_en_name(raw)
        if en and depth >= 1 and title not in names and len(en) < 40:
            names.setdefault(en, title)

        if depth < 2:
            for link in page_links(raw):
                if not wanted(link):
                    continue
                if link in seen:
                    continue
                # a partir das páginas-índice seguimos para os itens e para
                # subcategorias (que listam mais itens)
                if link.startswith("Categoria:"):
                    if depth == 0:
                        queue.append((link, 1))
                    continue
                if depth == 0 or link.startswith("Categoria:"):
                    queue.append((link, depth + 1))
        print(
            f"[{len(pages):4d}/{args.max_pages}] {title} "
            f"({len(chunks)} trechos, {len(text)} chars) {time.time() - t0:.0f}s",
            file=sys.stderr,
        )
        time.sleep(args.delay)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with gzip.open(args.out, "wt", encoding="utf-8") as f:
        json.dump(pages, f, ensure_ascii=False)
    with open(args.names_out, "w", encoding="utf-8") as f:
        json.dump(names, f, ensure_ascii=False, indent=1, sort_keys=True)

    print(
        f"\n{len(pages)} páginas, {sum(len(p['c']) for p in pages)} trechos, "
        f"{len(names)} nomes EN->PT, {errors} erros -> {args.out}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
