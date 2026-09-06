"""Chroma-key Imagine JPGs, harden player-frame alpha, write ICO."""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"D:\code\tuitui\tuitui_run")
SESSION = Path(
    r"C:\Users\nailong\.grok\sessions"
    r"\D%3A%5Ccode%5Ctuitui\01a0529b-efd0-7aa0-9aa8-1308d8aa331a\images"
)


def flood_bg(im: Image.Image, is_bg) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        i = y * w + x
        if seen[i]:
            return
        r, g, b, a = px[x, y]
        if not is_bg(r, g, b, a):
            return
        seen[i] = 1
        q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        if x > 0:
            push(x - 1, y)
        if x + 1 < w:
            push(x + 1, y)
        if y > 0:
            push(x, y - 1)
        if y + 1 < h:
            push(x, y + 1)
    return im


def bg_black_or_mint(r: int, g: int, b: int, a: int) -> bool:
    if a < 12:
        return True
    if r + g + b < 48:
        return True
    if g > 140 and g > r + 25 and g > b + 18:
        return True
    return False


def bg_checker_or_white(r: int, g: int, b: int, a: int) -> bool:
    if a < 12:
        return True
    sat = max(r, g, b) - min(r, g, b)
    return sat < 28 and min(r, g, b) > 155


def harden_alpha(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 20:
                px[x, y] = (0, 0, 0, 0)
            elif g > r + 18 and g > b + 18 and a < 140:
                px[x, y] = (0, 0, 0, 0)
    return im


def save(im: Image.Image, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, "PNG")
    print("wrote", dest, im.size)


def convert_session(name: str, dest: Path, checker: bool) -> None:
    src = SESSION / name
    im = Image.open(src)
    pred = bg_checker_or_white if checker else bg_black_or_mint
    out = harden_alpha(flood_bg(im, pred))
    save(out, dest)


def hanging_barrier() -> Image.Image:
    w, h = 720, 900
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # ropes from top
    d.rectangle((150, 0, 168, 70), fill=(196, 154, 72, 255))
    d.rectangle((552, 0, 570, 70), fill=(196, 154, 72, 255))
    board = (48, 56, 672, 430)
    d.rounded_rectangle(board, radius=18, fill=(22, 38, 92, 255), outline=(218, 176, 64, 255), width=10)
    inner = (78, 86, 642, 400)
    d.rounded_rectangle(inner, radius=10, fill=(28, 48, 108, 255))
    for y in range(120, 390, 42):
        d.line((96, y, 624, y), fill=(18, 30, 72, 255), width=4)
    d.rectangle((48, 200, 672, 218), fill=(218, 176, 64, 255))
    d.rectangle((48, 300, 672, 318), fill=(218, 176, 64, 255))
    return im


def make_tab_off(on: Image.Image) -> Image.Image:
    im = on.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            px[x, y] = (int(r * 0.38 + 18), int(g * 0.32 + 22), int(b * 0.55 + 70), a)
    return im


def make_ico(src: Path, dest: Path) -> None:
    im = Image.open(src).convert("RGBA")
    # if fully opaque with light corners, keep navy fill to edges
    sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    im.save(dest, sizes=sizes)
    print("wrote", dest)


def main() -> None:
    assets = ROOT / "assets"
    convert_session("38.jpg", assets / "ui" / "btn_start.png", True)
    convert_session("39.jpg", assets / "ui" / "btn_tab_on.png", True)
    convert_session("40.jpg", assets / "ui" / "icon_bless.png", True)
    convert_session("41.jpg", assets / "ui" / "icon_sprint.png", True)
    convert_session("42.jpg", assets / "ui" / "icon_shield.png", True)
    convert_session("43.jpg", assets / "ui" / "icon_magnet.png", True)
    convert_session("44.jpg", assets / "ui" / "celebrate.png", True)
    convert_session("45.jpg", assets / "obstacles" / "coin_copper.png", False)
    convert_session("46.jpg", assets / "characters" / "witch_blue.png", False)
    convert_session("47.jpg", assets / "obstacles" / "coin_silver.png", False)

    tab_on = Image.open(assets / "ui" / "btn_tab_on.png")
    save(make_tab_off(tab_on), assets / "ui" / "btn_tab_off.png")
    save(hanging_barrier(), assets / "obstacles" / "barrier.png")

    player_dir = assets / "characters" / "player"
    for name in [
        "player_run_0.png",
        "player_run_1.png",
        "player_run_2.png",
        "player_run_3.png",
        "player_jump.png",
        "player_fall.png",
        "player_duck.png",
        "player_dead.png",
        "player_idle.png",
    ]:
        p = player_dir / name
        im = harden_alpha(flood_bg(Image.open(p), bg_black_or_mint))
        save(im, p)

    # icon: keep full canvas, write png + ico
    icon = Image.open(ROOT / "icon.png").convert("RGBA")
    save(icon, ROOT / "icon.png")
    make_ico(ROOT / "icon.png", ROOT / "icon.ico")


if __name__ == "__main__":
    main()
