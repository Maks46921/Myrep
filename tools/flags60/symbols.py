# 0.60: символы флагов. Все нарисованы в квадрате 24x24 с центром в (0,0); один цвет (подставляется вместо «C»).
# Запуск: python3 symbols.py  -> sym.json (имя, svg) и вставка в scripts/ui/ui_flag.gd (метка FLAG_SYM60).
import math, json, sys

def f(x):
    s = "%.2f" % x
    return s.rstrip("0").rstrip(".") if "." in s else s

def pts(lst):
    return " ".join("%s,%s" % (f(x), f(y)) for x, y in lst)

def poly(lst, extra=""):
    return '<polygon points="%s" fill="C" %s/>' % (pts(lst), extra)

def path(d, extra=""):
    return '<path d="%s" fill="C" %s/>' % (d, extra)

def star(r, n=5, ri=None, cx=0.0, cy=0.0, rot=-90.0):
    ri = r * 0.382 if ri is None else ri
    out = []
    for i in range(2 * n):
        a = math.radians(rot + i * 180.0 / n)
        rr = r if i % 2 == 0 else ri
        out.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return out

def mirror(half):
    """half — точки правой половины сверху вниз; возвращает замкнутый контур, симметричный относительно x=0"""
    left = [(-x, y) for x, y in reversed(half)]
    return half + left

def rot(p, a):
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c)

def rot_pts(lst, a, c):
    return [(c[0] + rot((x - c[0], y - c[1]), a)[0], c[1] + rot((x - c[0], y - c[1]), a)[1]) for x, y in lst]

def ellipse_path(cx, cy, rx, ry, a=0.0):
    # эллипс, повёрнутый на угол a, в виде двух дуг
    p1 = rot((-rx, 0), a); p2 = rot((rx, 0), a)
    return "M%s,%s A%s,%s %s 1 0 %s,%s A%s,%s %s 1 0 %s,%s Z" % (f(cx + p1[0]), f(cy + p1[1]), f(rx), f(ry), f(math.degrees(a)), f(cx + p2[0]), f(cy + p2[1]), f(rx), f(ry), f(math.degrees(a)), f(cx + p1[0]), f(cy + p1[1]))

SYM = {}

# 0 Звезда
SYM["Звезда"] = poly(star(11.5))

# 1 Три звезды
SYM["Три звезды"] = poly(star(6.2, cx=0, cy=-6.0)) + poly(star(6.2, cx=-7.2, cy=6.2)) + poly(star(6.2, cx=7.2, cy=6.2))

# 2 Круг
SYM["Круг"] = '<circle cx="0" cy="0" r="10.5" fill="C"/>'

# 3 Кольцо
SYM["Кольцо"] = '<circle cx="0" cy="0" r="8.8" fill="none" stroke="C" stroke-width="3.4"/>'

# 4 Полумесяц (рога вправо) со звездой
R, r, d = 10.5, 8.4, 4.6
x = (d * d + R * R - r * r) / (2 * d); y = math.sqrt(max(0.0, R * R - x * x))
SYM["Полумесяц"] = path("M%s,%s A%s,%s 0 1 0 %s,%s A%s,%s 0 0 1 %s,%s Z" % (f(x - 1.5), f(-y), f(R), f(R), f(x - 1.5), f(y), f(r), f(r), f(x - 1.5), f(-y)), 'transform="translate(-1.5 0)"') + poly(star(3.6, cx=5.8, cy=0, rot=-90))

# 5 Солнце
rays = []
for k in range(16):
    a = math.radians(k * 22.5); hw = math.radians(5.5 if k % 2 == 0 else 4.0); ro = 11.8 if k % 2 == 0 else 9.6
    rays.append(poly([(7.3 * math.cos(a - hw), 7.3 * math.sin(a - hw)), (ro * math.cos(a), ro * math.sin(a)), (7.3 * math.cos(a + hw), 7.3 * math.sin(a + hw))]))
SYM["Солнце"] = '<circle cx="0" cy="0" r="5.6" fill="C"/>' + "".join(rays)

# 6 Крест (латинский, с утолщёнными концами)
SYM["Крест"] = poly([(-2.3, -11.5), (2.3, -11.5), (2.3, -5.2), (8.6, -5.2), (8.6, -0.8), (2.3, -0.8), (2.3, 11.5), (-2.3, 11.5), (-2.3, -0.8), (-8.6, -0.8), (-8.6, -5.2), (-2.3, -5.2)])

# 7 Серп и молот
def arc_band(cx, cy, a0, a1, r_out0, r_out1, thick0, thick1, n=24):
    """дуга-полоса: от угла a0 к a1 (градусы, по часовой в координатах SVG)"""
    outer, inner = [], []
    for i in range(n + 1):
        t = i / n
        a = math.radians(a0 + (a1 - a0) * t)
        ro = r_out0 + (r_out1 - r_out0) * t
        th = thick0 + (thick1 - thick0) * t
        outer.append((cx + ro * math.cos(a), cy + ro * math.sin(a)))
        inner.append((cx + (ro - th) * math.cos(a), cy + (ro - th) * math.sin(a)))
    return outer + list(reversed(inner))

SYM["Серп и молот"] = (
    poly(arc_band(-0.8, -1.4, -25.0, 195.0, 10.4, 10.6, 1.0, 3.8)) +
    poly([(-9.0, -4.4), (-11.8, -7.4), (-10.4, -8.8), (-7.8, -5.8)]) +
    poly(rot_pts([(-0.9, -4.0), (0.9, -4.0), (0.9, 11.6), (-0.9, 11.6)], -0.62, (0.0, 0.0))) +
    poly(rot_pts([(-4.8, -7.2), (4.2, -7.2), (4.2, -3.8), (-4.8, -3.8)], -0.62, (0.0, 0.0))))

# 8 Орёл (одноглавый, крылья подняты)
def eagle_parts(hx=0.0, hy=-6.6, beak=1):
    p = '<path d="' + ellipse_path(0, 2.2, 3.5, 6.2, 0) + '" fill="C"/>'
    p += '<circle cx="' + f(hx) + '" cy="' + f(hy) + '" r="2.3" fill="C"/>'
    p += poly([(hx + beak * 1.6, hy - 0.8), (hx + beak * 4.8, hy + 0.2), (hx + beak * 1.8, hy + 1.6)])
    return p

WING = [(2.8, -4.6), (6, -8.4), (9.6, -11.0), (11.8, -10.6), (11.2, -8.4), (12.2, -7.6), (11.0, -5.6), (11.8, -4.4), (10.2, -2.6), (10.6, -1.2), (8.2, -0.6), (6.6, 1.6), (3.0, 2.8)]
SYM["Орёл"] = eagle_parts() + poly(WING) + poly([(-x, y) for x, y in WING]) + \
    poly([(-3.0, 7.4), (-4.6, 11.8), (-1.6, 10.4), (0, 12.2), (1.6, 10.4), (4.6, 11.8), (3.0, 7.4)])

# 21 Двуглавый орёл
DW = [(x, y + 1.4) for x, y in WING]
SYM["Двуглавый орёл"] = (
    '<path d="' + ellipse_path(0, 3.6, 3.4, 6.0, 0) + '" fill="C"/>' +
    '<circle cx="-3.6" cy="-7.4" r="2.1" fill="C"/><circle cx="3.6" cy="-7.4" r="2.1" fill="C"/>' +
    poly([(-5.2, -8.2), (-8.2, -7.2), (-5.4, -5.8)]) + poly([(5.2, -8.2), (8.2, -7.2), (5.4, -5.8)]) +
    poly([(-3.8, -6.0), (-1.2, -2.0), (1.2, -2.0), (3.8, -6.0), (2.2, -6.0), (0, -3.6), (-2.2, -6.0)]) +
    poly(DW) + poly([(-x, y) for x, y in DW]) +
    poly([(-3.0, 8.4), (-4.4, 12.0), (-1.6, 10.8), (0, 12.4), (1.6, 10.8), (4.4, 12.0), (3.0, 8.4)]) +
    poly([(-3.2, -11.8), (-2.2, -10.0), (-1.1, -11.2), (0, -9.8), (1.1, -11.2), (2.2, -10.0), (3.2, -11.8), (3.2, -9.6), (-3.2, -9.6)]))

# 9 Корона
SYM["Корона"] = poly([(-10.6, 7.6), (-10.6, -4.4), (-5.4, 0.6), (0, -8.6), (5.4, 0.6), (10.6, -4.4), (10.6, 7.6)]) + \
    '<circle cx="-10.6" cy="-6.2" r="1.9" fill="C"/><circle cx="0" cy="-10.4" r="2.1" fill="C"/><circle cx="10.6" cy="-6.2" r="1.9" fill="C"/>' + \
    '<rect x="-10.6" y="8.8" width="21.2" height="3.2" fill="C"/>'

# 10 Щит
SYM["Щит"] = path("M-9.6,-10.8 L9.6,-10.8 L9.6,-1.2 C9.6,5.6 5.0,9.4 0,12.0 C-5.0,9.4 -9.6,5.6 -9.6,-1.2 Z M-6.2,-7.4 L-6.2,-1.4 C-6.2,3.4 -3.2,6.2 0,8.2 C3.2,6.2 6.2,3.4 6.2,-1.4 L6.2,-7.4 Z", 'fill-rule="evenodd"')

# 11 Лев (голова анфас: грива с зубцами, морда, глаза, нос)
mane = []
for k in range(24):
    a = math.radians(k * 15.0 - 90.0); rr = 11.8 if k % 2 == 0 else 9.4
    mane.append((rr * math.cos(a), rr * math.sin(a)))
SYM["Лев"] = path("M" + " L".join("%s,%s" % (f(x), f(y)) for x, y in mane) + " Z " +
                  "M-5.6,-4.2 C-5.4,-7.4 5.4,-7.4 5.6,-4.2 C6.0,0.6 4.2,5.4 0,7.4 C-4.2,5.4 -6.0,0.6 -5.6,-4.2 Z " +
                  "M-3.8,-2.4 L-1.2,-1.8 L-1.4,-0.6 L-3.8,-1.0 Z M3.8,-2.4 L1.2,-1.8 L1.4,-0.6 L3.8,-1.0 Z " +
                  "M-1.6,1.6 L1.6,1.6 L0,3.6 Z M-0.5,3.6 L0.5,3.6 L0.5,5.4 L-0.5,5.4 Z", 'fill-rule="evenodd"')

# 12 Дуб/лавр (венок)
leaves = ""
for side in (-1, 1):
    for k in range(9):
        t = math.radians(-100.0 + 15.5 * k + 0.0)       # от низа к верху вдоль дуги
        cx = side * 8.4 * math.cos(t + math.radians(90 - 90)) * 1.0
        ang = math.radians(100.0 - 17.0 * k)
        px = side * 8.2 * math.sin(math.radians(20 + 18 * k)) * 1.0
        py = 8.8 * math.cos(math.radians(20 + 18 * k)) * 1.0
        ra = math.atan2(py, px) + math.pi / 2 * (1 if side == 1 else -1)
        leaves += '<path d="%s" fill="C"/>' % ellipse_path(px, py, 3.0, 1.35, ra + side * 0.35)
stems = '<path d="M-1.6,10.8 C-9.6,8.6 -10.2,-3.2 -4.6,-9.2" fill="none" stroke="C" stroke-width="0.9"/><path d="M1.6,10.8 C9.6,8.6 10.2,-3.2 4.6,-9.2" fill="none" stroke="C" stroke-width="0.9"/>'
SYM["Дуб/лавр"] = stems + leaves + '<circle cx="-1.4" cy="11.0" r="1.2" fill="C"/><circle cx="1.4" cy="11.0" r="1.2" fill="C"/>'

# 13 Колос
grains = ""
for k in range(5):
    y = 6.0 - k * 4.4
    for side in (-1, 1):
        grains += '<path d="%s" fill="C"/>' % ellipse_path(side * 3.2, y - 1.2, 3.1, 1.45, side * -0.85)
grains += '<path d="%s" fill="C"/>' % ellipse_path(0, -12.0, 1.5, 3.0, 0)
SYM["Колос"] = '<rect x="-0.55" y="-9" width="1.1" height="21" fill="C"/>' + grains

# 14 Шестерня
g = []
n = 10
for k in range(n):
    a0 = 2 * math.pi * k / n
    for da, rr in ((-0.20, 8.4), (-0.13, 11.6), (0.13, 11.6), (0.20, 8.4)):
        g.append((rr * math.cos(a0 + da), rr * math.sin(a0 + da)))
SYM["Шестерня"] = path("M" + " L".join("%s,%s" % (f(x), f(y)) for x, y in g) + " Z M4.4,0 A4.4,4.4 0 1 0 -4.4,0 A4.4,4.4 0 1 0 4.4,0 Z", 'fill-rule="evenodd"')

# 15 Книга (раскрытая)
SYM["Книга"] = path("M-11.2,-6.8 C-7.6,-8.4 -3.4,-8.2 -0.8,-6.0 L-0.8,9.6 C-3.4,7.6 -7.6,7.4 -11.2,9.0 Z") + \
    path("M11.2,-6.8 C7.6,-8.4 3.4,-8.2 0.8,-6.0 L0.8,9.6 C3.4,7.6 7.6,7.4 11.2,9.0 Z") + \
    path("M-12.0,-5.2 L-12.0,10.4 C-8.0,8.4 -4.0,8.8 -0.0,11.2 C4.0,8.8 8.0,8.4 12.0,10.4 L12.0,-5.2 L12.8,-5.2 L12.8,11.8 C8.2,9.8 4.0,10.4 0,12.6 C-4.0,10.4 -8.2,9.8 -12.8,11.8 L-12.8,-5.2 Z")

# 16 Меч (остриём вверх)
SYM["Меч"] = poly([(0, -12.0), (2.0, -8.6), (2.0, 4.0), (-2.0, 4.0), (-2.0, -8.6)]) + \
    poly([(-7.0, 4.0), (7.0, 4.0), (7.0, 6.2), (-7.0, 6.2)]) + \
    '<rect x="-1.4" y="6.2" width="2.8" height="4.6" fill="C"/>' + '<circle cx="0" cy="11.4" r="1.7" fill="C"/>'

# 17 Роза (пять лепестков вокруг сердцевины, пять чашелистиков)
pet = ""
for k in range(5):
    a = math.radians(-90 + 72 * k)
    cx, cy = 6.5 * math.cos(a), 6.5 * math.sin(a)
    pet += "M%s,%s A4.5,4.5 0 1 0 %s,%s A4.5,4.5 0 1 0 %s,%s Z " % (f(cx - 4.5), f(cy), f(cx + 4.5), f(cy), f(cx - 4.5), f(cy))
sep = ""
for k in range(5):
    a = math.radians(-54 + 72 * k)
    sep += poly([(9.4 * math.cos(a - 0.22), 9.4 * math.sin(a - 0.22)), (12.4 * math.cos(a), 12.4 * math.sin(a)), (9.4 * math.cos(a + 0.22), 9.4 * math.sin(a + 0.22))])
SYM["Роза"] = path(pet, 'fill-rule="evenodd"') + sep + '<circle cx="0" cy="0" r="1.2" fill="C"/>'

# 18 Якорь
SYM["Якорь"] = '<circle cx="0" cy="-9.0" r="2.4" fill="none" stroke="C" stroke-width="1.6"/>' + \
    '<rect x="-1.0" y="-6.6" width="2.0" height="17.6" fill="C"/>' + '<rect x="-5.4" y="-4.8" width="10.8" height="1.9" fill="C"/>' + \
    path("M-10.6,3.2 L-8.4,2.2 C-7.6,6.0 -4.0,8.4 0,8.4 C4.0,8.4 7.6,6.0 8.4,2.2 L10.6,3.2 L9.2,5.4 C7.6,9.6 3.6,11.6 0,11.6 C-3.6,11.6 -7.6,9.6 -9.2,5.4 Z") + \
    poly([(-12.0, 1.0), (-8.6, 0.6), (-8.6, 4.4)]) + poly([(12.0, 1.0), (8.6, 0.6), (8.6, 4.4)])

# 19 Кедр (ярусами)
SYM["Кедр"] = poly([(0, -11.6), (3.4, -6.0), (1.6, -6.0), (6.2, -1.0), (3.6, -1.0), (9.8, 5.6), (1.8, 5.6), (1.8, 11.6), (-1.8, 11.6), (-1.8, 5.6), (-9.8, 5.6), (-3.6, -1.0), (-6.2, -1.0), (-1.6, -6.0), (-3.4, -6.0)])

# 20 Трезубец
SYM["Трезубец"] = '<rect x="-0.9" y="-9.4" width="1.8" height="21.4" fill="C"/>' + poly([(0, -12.0), (2.2, -8.0), (0.9, -8.0), (0.9, -6.0), (-0.9, -6.0), (-0.9, -8.0), (-2.2, -8.0)]) + \
    path("M-1.2,-2.2 L-1.2,0.6 L-5.8,0.6 C-8.6,0.6 -9.6,-2.2 -9.6,-6.6 L-11.4,-6.6 L-8.6,-11.4 L-5.8,-6.6 L-7.6,-6.6 C-7.6,-3.6 -7.0,-1.8 -5.4,-1.8 L-1.2,-1.8 Z") + \
    path("M1.2,-2.2 L1.2,0.6 L5.8,0.6 C8.6,0.6 9.6,-2.2 9.6,-6.6 L11.4,-6.6 L8.6,-11.4 L5.8,-6.6 L7.6,-6.6 C7.6,-3.6 7.0,-1.8 5.4,-1.8 L1.2,-1.8 Z")

# 22 Рука/кулак (поднятый кулак)
SYM["Рука/кулак"] = (
    '<rect x="-6.4" y="-9.4" width="3.0" height="7.0" rx="1.5" fill="C"/><rect x="-2.9" y="-10.4" width="3.0" height="8.0" rx="1.5" fill="C"/>' +
    '<rect x="0.6" y="-10.2" width="3.0" height="7.8" rx="1.5" fill="C"/><rect x="4.1" y="-9.0" width="2.9" height="6.6" rx="1.45" fill="C"/>' +
    path("M-6.6,-4.0 L7.0,-4.0 L7.0,3.6 C7.0,5.6 5.8,6.6 4.0,6.8 L-3.0,6.8 C-5.4,6.8 -6.6,5.2 -6.6,3.2 Z") +
    '<rect x="-8.2" y="-3.0" width="9.6" height="4.4" rx="2.2" fill="C" transform="rotate(14 -3 -1)"/>' +
    poly([(-4.0, 6.4), (4.4, 6.4), (5.0, 12.4), (-4.6, 12.4)]))

ORDER = ["Звезда", "Три звезды", "Круг", "Кольцо", "Полумесяц", "Солнце", "Крест", "Серп и молот", "Орёл", "Корона", "Щит",
         "Лев", "Дуб/лавр", "Колос", "Шестерня", "Книга", "Меч", "Роза", "Якорь", "Кедр", "Трезубец", "Двуглавый орёл", "Рука/кулак"]

if __name__ == "__main__":
    assert set(ORDER) == set(SYM), set(SYM) ^ set(ORDER)
    json.dump([[n, SYM[n]] for n in ORDER], open("sym.json", "w"), ensure_ascii=False, indent=0)
    print(len(ORDER), "символов")
