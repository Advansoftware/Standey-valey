# -*- coding: utf-8 -*-
"""Verifica assets/data: imagens ausentes, ids duplicados, sobras de inglês."""
import glob, json, os, re
R = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ids, bad = set(), 0
for f in sorted(glob.glob(R + "/assets/data/*.json")):
    if f.endswith("index.json") or f.endswith("names_pt.json"):
        continue
    d = json.load(open(f, encoding="utf-8"))
    for e in d["entries"]:
        if e["id"] in ids:
            print("ID duplicado", e["id"]); bad += 1
        ids.add(e["id"])
        for n in [e.get("img")] + [g[0] for g in e.get("gallery", [])]:
            if n and not os.path.isfile(f"{R}/assets/img/{n}"):
                print("img ausente", e["id"], n); bad += 1
        if d["id"] not in ("pacotes", "guia") and not e.get("img"):
            print("sem img", d["id"], e["id"])
        if re.search(r"\b(the|and|with|from)\b", e.get("desc", "")):
            print("inglês?", e["id"], e["desc"][:60])
print("ids:", len(ids), "problemas:", bad)
