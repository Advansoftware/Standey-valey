#!/usr/bin/env python3
"""Gera o ícone do app (Guia do Vale) a partir de um sprite do jogo.

Uso:
  python3 tools/make_icon.py [sprite]

Escreve:
  android/app/src/main/res/mipmap-*/ic_launcher.png         (ícone legado)
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (ícone adaptativo)
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/values/ic_launcher_background.xml
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android/app/src/main/res")

SPRITE = os.path.join(ROOT, "assets/img/crops_parsnip_crop.png")

# cores do app (tema "pergaminho")
TOP = (143, 185, 92)       # verde claro
BOTTOM = (63, 122, 42)     # verde escuro
LEAF = (0, 0, 0, 0)

DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def vertical_gradient(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        cor = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        d.line([(0, y), (size, y)], fill=cor + (255,))
    return img


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def build_legacy(size: int) -> Image.Image:
    base = vertical_gradient(size)
    mask = rounded_mask(size, int(size * 0.22))
    base.putalpha(mask)

    sprite = Image.open(SPRITE).convert("RGBA")
    # amplia mantendo a pixel art nítida
    alvo = int(size * 0.62)
    sprite = sprite.resize((alvo, alvo), Image.NEAREST)

    sombra = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s = Image.new("RGBA", sprite.size, (0, 0, 0, 130))
    sombra.paste(s, ((size - alvo) // 2, (size - alvo) // 2 + max(1, size // 22)), sprite)
    sombra = sombra.filter(ImageFilter.GaussianBlur(max(1, size / 48)))
    base = Image.alpha_composite(base, sombra)

    pos = ((size - alvo) // 2, (size - alvo) // 2 - int(size * 0.02))
    base.alpha_composite(sprite, pos)
    return base


def build_foreground(size: int) -> Image.Image:
    """Camada frontal do ícone adaptativo (108dp com 72dp visíveis)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sprite = Image.open(SPRITE).convert("RGBA")
    alvo = int(size * 0.42)
    sprite = sprite.resize((alvo, alvo), Image.NEAREST)
    pos = ((size - alvo) // 2, (size - alvo) // 2)
    img.alpha_composite(sprite, pos)
    return img


def main() -> None:
    for dens, size in DENSITIES.items():
        pasta = os.path.join(RES, f"mipmap-{dens}")
        os.makedirs(pasta, exist_ok=True)
        build_legacy(size).save(os.path.join(pasta, "ic_launcher.png"))
        # camada do ícone adaptativo (108dp => 1,5x o tamanho legado)
        build_foreground(int(size * 1.5)).save(os.path.join(pasta, "ic_launcher_foreground.png"))
        print(f"mipmap-{dens}: {size}px")

    pasta = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(pasta, exist_ok=True)
    with open(os.path.join(pasta, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n'
        )

    valores = os.path.join(RES, "values")
    os.makedirs(valores, exist_ok=True)
    with open(os.path.join(valores, "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources>\n'
            '    <color name="ic_launcher_background">#4E8B34</color>\n'
            '</resources>\n'
        )
    print("ícones gerados")


if __name__ == "__main__":
    main()
