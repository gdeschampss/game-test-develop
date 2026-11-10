"""Gera as texturas da interface (molduras de metal escuro com detalhe dourado, anel do retrato,
preenchimento das barras). Arte própria, desenhada por código. Rodar: python3 tools/gen_ui.py"""
from PIL import Image, ImageDraw, ImageFilter
import math, os, random
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui')
SS = 4  # supersampling

GOLD_L = (247, 214, 120); GOLD = (201, 158, 64); GOLD_D = (118, 82, 28)
MET_L = (128, 128, 132); MET = (74, 74, 78); MET_D = (30, 30, 33); BLACK = (8, 8, 9)

def save(img, name, size):
    img = img.resize(size, Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print(name, size)

def bevel_rect(d, box, w, light, mid, dark, radius=0):
    x0, y0, x1, y1 = box
    for i in range(w):
        t = i / max(1, w - 1)
        # luz em cima/esquerda, sombra embaixo/direita
        col_tl = tuple(int(light[k] * (1 - t) + mid[k] * t) for k in range(3))
        col_br = tuple(int(dark[k] * (1 - t) + mid[k] * t) for k in range(3))
        d.line([(x0 + i, y1 - i), (x0 + i, y0 + i), (x1 - i, y0 + i)], fill=col_tl, width=1)
        d.line([(x1 - i, y0 + i), (x1 - i, y1 - i), (x0 + i, y1 - i)], fill=col_br, width=1)

def noise(img, amt=10, seed=1):
    random.seed(seed)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                n = random.randint(-amt, amt)
                px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)), a)

# 1) Moldura de slot (quadrado): metal escuro chanfrado + filete dourado fino por dentro, miolo transparente.
def slot_frame(name, gold_line=True, glow=False):
    S = 64 * SS
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    b = 6 * SS
    d.rectangle([0, 0, S - 1, S - 1], fill=BLACK + (255,))
    d.rectangle([SS, SS, S - 1 - SS, S - 1 - SS], fill=MET + (255,))
    bevel_rect(d, (SS, SS, S - 1 - SS, S - 1 - SS), b - SS, MET_L, MET, MET_D)
    # recorte do miolo
    inner = [b, b, S - 1 - b, S - 1 - b]
    d.rectangle(inner, fill=(0, 0, 0, 0))
    if gold_line:
        d.rectangle([b - SS, b - SS, S - b + SS - 1, S - b + SS - 1], outline=GOLD_D + (255,), width=SS)
    if glow:
        im2 = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d2 = ImageDraw.Draw(im2)
        d2.rectangle([b, b, S - 1 - b, S - 1 - b], outline=GOLD_L + (255,), width=3 * SS)
        im2 = im2.filter(ImageFilter.GaussianBlur(2 * SS))
        im = Image.alpha_composite(im2, im)
        d = ImageDraw.Draw(im)
        d.rectangle([0, 0, S - 1, S - 1], outline=GOLD_L + (255,), width=2 * SS)
        d.rectangle([b, b, S - 1 - b, S - 1 - b], fill=(0, 0, 0, 0))
    noise(im, 6)
    save(im, name, (64, 64))

# 2) Moldura de painel/barra (9-patch): borda de metal escuro com cantos chanfrados e filete dourado.
def panel_frame(name, fill_center, gold=True, size=48, border=6):
    S = size * SS
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c = 3 * SS
    poly = [(c, 0), (S - 1 - c, 0), (S - 1, c), (S - 1, S - 1 - c), (S - 1 - c, S - 1), (c, S - 1), (0, S - 1 - c), (0, c)]
    d.polygon(poly, fill=BLACK + (255,))
    b = border * SS
    d.rectangle([SS, SS, S - 1 - SS, S - 1 - SS], fill=MET + (255,))
    bevel_rect(d, (SS, SS, S - 1 - SS, S - 1 - SS), b - 2 * SS, MET_L, MET, MET_D)
    if fill_center:
        d.rectangle([b, b, S - 1 - b, S - 1 - b], fill=(14, 13, 12, 235))
    else:
        d.rectangle([b, b, S - 1 - b, S - 1 - b], fill=(0, 0, 0, 0))
    if gold:
        d.rectangle([b - SS, b - SS, S - b + SS - 1, S - b + SS - 1], outline=GOLD_D + (255,), width=SS)
    # cantos dourados
    for (x, y) in [(0, 0), (S - 1, 0), (0, S - 1), (S - 1, S - 1)]:
        r = 3 * SS
        d.ellipse([x - r, y - r, x + r, y + r], fill=GOLD + (255,))
    noise(im, 6, 2)
    save(im, name, (size, size))

# 3) Anel do retrato: ouro com relevo, interior transparente. Variante com "ponta" no canto (gota).
def portrait_ring(name, drop):
    S = 256 * SS
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    cx = cy = S / 2; R = S / 2 - 2 * SS; w = 16 * SS
    def shape(dr, rad, fill):
        dr.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=fill)
        if drop:
            dr.rectangle([cx, cy, cx + rad, cy + rad], fill=fill)
    shape(d, R, BLACK + (255,))
    shape(d, R - SS * 2, GOLD_D + (255,))
    # gradiente do ouro (luz em cima à esquerda)
    grad = Image.new('RGBA', (S, S), (0, 0, 0, 0)); gp = grad.load()
    mask = Image.new('L', (S, S), 0); md = ImageDraw.Draw(mask)
    shape(md, R - SS * 3, 255)
    hole = Image.new('L', (S, S), 0); hd = ImageDraw.Draw(hole)
    hd.ellipse([cx - (R - w), cy - (R - w), cx + (R - w), cy + (R - w)], fill=255)
    gold_img = Image.new('RGBA', (S, S))
    for y in range(0, S, SS):
        for x in range(0, S, SS):
            t = ((x - cx) * -0.7 + (y - cy) * -0.7) / R
            t = max(-1, min(1, t))
            col = tuple(int(GOLD[k] + (GOLD_L[k] - GOLD[k]) * max(0, t) + (GOLD_D[k] - GOLD[k]) * max(0, -t)) for k in range(3))
            for yy in range(SS):
                for xx in range(SS):
                    gold_img.putpixel((x + xx, y + yy), col + (255,))
    im.paste(gold_img, (0, 0), mask)
    d = ImageDraw.Draw(im)
    # filetes
    d.ellipse([cx - (R - 5 * SS), cy - (R - 5 * SS), cx + (R - 5 * SS), cy + (R - 5 * SS)], outline=GOLD_D + (200,), width=SS)
    d.ellipse([cx - (R - w), cy - (R - w), cx + (R - w), cy + (R - w)], outline=BLACK + (255,), width=3 * SS)
    # miolo transparente
    im.paste((0, 0, 0, 0), (0, 0), hole.point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.MinFilter(3 * SS + 1)))
    save(im, name, (256, 256))

# 4) Preenchimento branco das barras (com brilho em cima) — a cor vem do modulate.
def bar_fill(name):
    W, H = 8, 32
    im = Image.new('RGBA', (W, H)); px = im.load()
    for y in range(H):
        t = y / (H - 1)
        v = 1.0 - 0.45 * t
        if t < 0.18: v = 1.0 + 0.0
        if 0.18 <= t < 0.24: v = 0.92
        c = int(255 * min(1, v))
        for x in range(W):
            px[x, y] = (c, c, c, 255)
    im.save(os.path.join(OUT, name)); print(name)

# 5) Botão redondo pequeno (zoom do minimapa, micro-menu)
def round_button(name):
    S = 64 * SS
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([0, 0, S - 1, S - 1], fill=BLACK + (255,))
    d.ellipse([2 * SS, 2 * SS, S - 1 - 2 * SS, S - 1 - 2 * SS], fill=GOLD_D + (255,))
    d.ellipse([5 * SS, 5 * SS, S - 1 - 5 * SS, S - 1 - 5 * SS], fill=(36, 30, 24, 255))
    d.arc([4 * SS, 4 * SS, S - 1 - 4 * SS, S - 1 - 4 * SS], 180, 300, fill=GOLD_L + (255,), width=2 * SS)
    save(im, name, (64, 64))

if __name__ == '__main__':
    slot_frame('hud_slot.png')
    slot_frame('hud_slot_active.png', glow=True)
    panel_frame('hud_panel.png', True)
    panel_frame('hud_bar_frame.png', False, gold=False, size=24, border=3)
    portrait_ring('hud_ring_drop.png', True)
    portrait_ring('hud_ring.png', False)
    bar_fill('hud_bar_fill.png')
    round_button('hud_round_button.png')


# 6) Janela grande (9-patch): metal escuro, filete dourado, interior quase preto.
def window_frame(name):
    panel_frame(name, True, gold=True, size=96, border=10)

# 7) Botões (vermelho escuro com borda dourada, como os botões clássicos)
def button(name, top, bottom, border):
    S = 48 * SS
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c = 4 * SS
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=c, fill=BLACK + (255,))
    d.rounded_rectangle([SS, SS, S - 1 - SS, S - 1 - SS], radius=c, fill=border + (255,))
    for y in range(3 * SS, S - 3 * SS):
        t = (y - 3 * SS) / (S - 6 * SS)
        col = tuple(int(top[k] * (1 - t) + bottom[k] * t) for k in range(3))
        d.line([(3 * SS, y), (S - 1 - 3 * SS, y)], fill=col + (255,))
    d.line([(3 * SS, 3 * SS), (S - 1 - 3 * SS, 3 * SS)], fill=tuple(min(255, v + 60) for v in top) + (255,), width=SS)
    save(im, name, (48, 48))

if __name__ == '__main__':
    window_frame('hud_window.png')
    button('hud_button.png', (150, 22, 14), (78, 8, 6), GOLD)
    button('hud_button_hover.png', (190, 40, 24), (110, 16, 10), GOLD_L)
    button('hud_button_pressed.png', (70, 8, 6), (120, 18, 12), GOLD_D)
    button('hud_button_disabled.png', (60, 56, 54), (36, 34, 33), (90, 84, 76))
