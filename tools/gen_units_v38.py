#!/usr/bin/env python3
"""v38: добавляет в data/world_units.dat 13 стран — Хорватию, Сербию, Боснию и Герцеговину, Черногорию, Северную Македонию, Албанию,
Косово, Болгарию, Румынию, Грецию, Эстонию, Латвию и Литву — из Natural Earth admin-1 (/tmp/ne_admin1.geojson).
Те же приёмы, что в gen_units_cee.py: страны берутся из Natural Earth как есть; соседние единицы v33 (SI, HU — тоже из Natural Earth)
не трогаются, а новые режутся по ним; грубые старые единицы (PL, IT) режутся по новым; контекстные страны, ставшие игровыми, удаляются
из WORLD_CTX, остальные (Украина, Молдавия, Белоруссия, Россия, Турция) режутся по новым, щели добираются сушей соседей из Natural Earth.
Повторный запуск строит от сохранённых исходников tools/units_before_v38.dat и tools/ctx_before_v38.dat."""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datio
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "newc"))
import gdconst
from shapely.geometry import shape, Polygon, MultiPolygon, box, Point
from shapely.ops import unary_union
from shapely.validation import make_valid
import shapely
from gen_units_cee import proj, poly_of, polys_only, ring_pts, set_parts

DC = "scripts/data/data_core.gd"
UNITS0 = "tools/units_before_v38.dat"
CTX0 = "tools/ctx_before_v38.dat"
SRC = "/tmp/ne_admin1.geojson"

N = "name"
HR = {"ZAG": (N, ["Grad Zagreb"]), "ZGZ": (N, ["Zagrebacka", "Krapinsko-Zagorska"]),
      "SJZ": (N, ["Varaždinska", "Medimurska", "Koprivničko-Križevačka", "Bjelovarsko-bilogorska"]),
      "SLA": (N, ["Osjecko-Baranjska", "Vukovarsko-Srijemska", "Brodsko-Posavska", "Viroviticko-Podravska"]),
      "SMK": (N, ["Sisacko-Moslavacka", "Karlovacka"]), "PGI": (N, ["Istarska", "Primorsko-Goranska", "Licko-Senjska"]),
      "SDA": (N, ["Zadarska", "Šibensko-Kninska"]), "SPL": (N, ["Splitsko-Dalmatinska", "Dubrovacko-Neretvanska"])}
A = "name_alt"
RS = {"BEO": (A, ["Belgrade"]), "SVO": (A, ["North Bačka", "West Bačka", "North Banat", "Central Banat"]),
      "JVO": (A, ["South Bačka", "South Banat", "Srem"]), "SUM": (A, ["Šumadija", "Pomoravlje", "Podunavlje|Danube", "Braničevo"]),
      "ZAP": (A, ["Zlatibor", "Moravica|Morava", "Raška"]), "KOL": (A, ["Kolubara", "Mačva"]), "IST": (A, ["Bor", "Zaječar"]),
      "JUG": (A, ["Nišava", "Pirot", "Toplica", "Jablanica", "Pčinja", "Rasina"])}
BA = {"SAR": (N, ["Sarajevo", "Bosnian Podrinje"]), "ZDC": (N, ["Zenica-Doboj", "Central Bosnia"]), "TUZ": (N, ["Tuzla", "Posavina"]),
      "HER": (N, ["Herzegovina-Neretva", "West Herzegovina", "West Bosnia"]), "USK": (N, ["Una-Sana"]), "RBL": (N, ["Banja Luka"]),
      "RIS": (N, ["Bijeljina", "Doboj", "Vlasenica"]), "RJU": (N, ["Trebinje", "Foča", "Sarajevo-romanija"]), "BRC": (N, ["Brčko Distrikt"])}
ME = {"POD": (N, ["Podgorica", "Danilovgrad", "Cetinje"]), "NIK": (N, ["Nikšic"]),
      "PRI": (N, ["Herceg Novi", "Kotor", "Tivat", "Budva", "Bar", "Ulcinj"]),
      "SEV": (N, ["Pljevlja", "Bijelo Polje", "Žabljak", "Mojkovac", "Kolašin", "Šavnik", "Plužine"]),
      "IST": (N, ["Berane", "Rožaje", "Plav", "Andrijevica"])}
R = "region"
MK = {"SKO": (R, ["Skopje", "Greater Skopje"]), "POL": (R, ["Polog"]), "SIS": (R, ["Northeastern"]), "IST": (R, ["Eastern"]),
      "JIS": (R, ["Southeastern"]), "VAR": (R, ["Vardar"]), "PEL": (R, ["Pelagonia"]), "JZA": (R, ["Southwestern"])}
AL = {"TIR": (N, ["Tiranë"]), "DUR": (N, ["Durrës"]), "SHK": (N, ["Shkodër", "Lezhë"]), "KUK": (N, ["Kukës", "Dibër"]), "ELB": (N, ["Elbasan"]),
      "FIB": (N, ["Fier", "Berat"]), "KOR": (N, ["Korçë"]), "VLG": (N, ["Vlorë", "Gjirokastër"])}
XK = {"PRI": (R, ["Pristina"]), "MIT": (R, ["Kosovska Mitrovica"]), "PEJ": (R, ["Peć"]), "GJA": (R, ["Đakovica"]), "PRZ": (R, ["Prizren"]),
      "FER": (R, ["Uroševac"]), "GJI": (R, ["Gnjilane"])}
BG = {"SOF": (N, ["Grad Sofiya"]), "YZA": (N, ["Sofia", "Pernik", "Kyustendil", "Blagoevgrad"]), "SZA": (N, ["Vidin", "Montana", "Vratsa", "Pleven", "Lovech"]),
      "SCE": (N, ["Veliko Tarnovo", "Gabrovo", "Ruse", "Razgrad", "Silistra"]), "SIZ": (N, ["Varna", "Dobrich", "Shumen", "Targovishte"]),
      "YIZ": (N, ["Burgas", "Sliven", "Yambol", "Stara Zagora"]), "YCE": (N, ["Plovdiv", "Pazardzhik", "Smolyan", "Kardzhali", "Haskovo"])}
RO = {"BUC": (N, ["Bucharest", "Ilfov"]), "NES": (N, ["Bacau", "Botosani", "Iasi", "Neamt", "Suceava", "Vaslui"]),
      "SES": (N, ["Braila", "Buzau", "Constanta", "Galati", "Tulcea", "Vrancea"]),
      "SMU": (N, ["Arges", "Calarasi", "Dâmbovita", "Giurgiu", "Ialomita", "Prahova", "Teleorman"]),
      "SVO": (N, ["Dolj", "Gorj", "Mehedinti", "Olt", "Vâlcea"]), "VES": (N, ["Arad", "Caras-Severin", "Hunedoara", "Timis"]),
      "NVS": (N, ["Bihor", "Bistrita-Nasaud", "Cluj", "Maramures", "Satu Mare", "Salaj"]),
      "CEN": (N, ["Alba", "Brasov", "Covasna", "Harghita", "Mures", "Sibiu"])}
GR = {"ATT": (N, ["Attiki"]), "KMA": (N, ["Kentriki Makedonia", "Ayion Oros"]), "AMT": (N, ["Anatoliki Makedonia kai Thraki"]),
      "DMA": (N, ["Dytiki Makedonia"]), "IPE": (N, ["Ipeiros"]), "THE": (N, ["Thessalia"]), "STE": (N, ["Stereá Elláda"]),
      "DEL": (N, ["Dytiki Ellada"]), "PEL": (N, ["Peloponnisos"]), "ION": (N, ["Ionioi Nisoi"]), "VAI": (N, ["Voreio Aigaio"]),
      "NAI": (N, ["Notio Aigaio"]), "KRI": (N, ["Kriti"])}
EE = {"HAR": (N, ["Harju"]), "KIR": (N, ["Ida-Viru"]), "KES": (N, ["Järva", "Lääne-Viru", "Rapla"]),
      "LAA": (N, ["Hiiu", "Lääne", "Pärnu", "Saare"]), "LOU": (N, ["Jõgeva", "Põlva", "Tartu", "Valga", "Viljandi", "Võru"])}
LV = {"RIG": (R, ["Riga"]), "KUR": (R, ["Kurzeme"]), "ZEM": (R, ["Zemgale"]), "VID": (R, ["Vidzeme"]), "LAT": (R, ["Latgale"])}
LT = {"VIL": (N, ["Vilniaus"]), "KAU": (N, ["Kauno"]), "KLA": (N, ["Klaipedos"]), "SIA": (N, ["Šiauliai"]), "PAN": (N, ["Panevezio"]),
      "ALY": (N, ["Alytaus", "Marijampoles"]), "TEL": (N, ["Telšiai", "Taurages"]), "UTE": (N, ["Utenos"])}
SETS = [("HR", "HRV", HR), ("RS", "SRB", RS), ("BA", "BIH", BA), ("ME", "MNE", ME), ("MK", "MKD", MK), ("AL", "ALB", AL), ("XK", "KOS", XK),
        ("BG", "BGR", BG), ("RO", "ROU", RO), ("GR", "GRC", GR), ("EE", "EST", EE), ("LV", "LVA", LV), ("LT", "LTU", LT)]
NEWCC = [s[0] for s in SETS]
# контекстные страны, ставшие игровыми, — удаляются
CTX_DROP = ["Сербия", "Румыния", "Черногория", "Северная Македония", "Литва", "Латвия", "Республика Косово", "Греция", "Эстония",
            "Хорватия", "Болгария", "Босния и Герцеговина", "Албания"]
# соседи: единицы из Natural Earth (их не трогаем, новые режем по ним) и контекстные страны (их суша заполняет щели)
NE_UNITS = ["SI", "HU", "SK", "FI"]
NB_UNITS = {"POL": "PL", "ITA": "IT"}
NB_CTX = {"UKR": "Украина", "MDA": "Молдавия", "BLR": "Белоруссия", "RUS": "Россия", "TUR": "Турция"}
# морские переходы: острова Греции, Эгейское и Ионическое море; Отрантский пролив (Апулия — Влёра)
SEA = [("GR-ION", "GR-DEL"), ("GR-ION", "GR-IPE"), ("GR-VAI", "GR-AMT"), ("GR-VAI", "GR-KMA"), ("GR-NAI", "GR-ATT"), ("GR-NAI", "GR-KRI"),
       ("GR-KRI", "GR-PEL"), ("GR-NAI", "GR-VAI"), ("GR-STE", "GR-VAI"), ("EE-HAR", "FI-UUS")]


# общины без поля region в Natural Earth
EXTRA = {"MKD": {"Strumitsa": "JIS", "Gevgelija": "JIS", "Bosilovo": "JIS", "Jegunovce": "POL", "Tearce": "POL", "Tetovo": "POL",
                 "Vrapcište": "POL", "Staro Nagoričane": "SIS", "Oslomej": "JZA", "Drugovo": "JZA", "Plasnica": "JZA", "Mogila": "PEL",
                 "Rosoman": "VAR", "Skopje": "SKO", "Zrnovci": "IST"}}


def match(p, a3, M):
    if p.get("adm0_a3") != a3:
        return None
    if p.get("name") in EXTRA.get(a3, {}):
        return EXTRA[a3][p.get("name")]
    for code, (fld, names) in M.items():
        if p.get(fld) in names:
            return code
    return "?"


def main():
    g = json.load(open(SRC))
    groups = {}
    for f in g["features"]:
        p = f["properties"]
        for cc, a3, M in SETS:
            code = match(p, a3, M)
            if code == "?":
                raise SystemExit("не распределено: %s %s (%s)" % (cc, p.get("name"), p.get("name_alt")))
            if code:
                groups.setdefault((cc, code), []).append(shape(f["geometry"]))
    if not os.path.exists(UNITS0):
        datio.dump(UNITS0, datio.load("data/world_units.dat"))
    units = datio.load(UNITS0)
    if any(u["cc"] in NEWCC for u in units):
        raise SystemExit("в %s уже есть новые страны" % UNITS0)
    if os.path.exists(CTX0):
        ctx = datio.load(CTX0)
    else:
        ctx = gdconst.get(DC, "WORLD_CTX")
        datio.dump(CTX0, ctx)
    ctx = [c for c in ctx if c["name"] not in CTX_DROP]
    base = len(units)
    fixed = unary_union([poly_of(u) for u in units if u["cc"] in NE_UNITS]).buffer(0.05)
    allcut, allkeys, prev = [], [], fixed
    for cc, a3, M in SETS:
        raw = {}
        for code in M:
            gl = groups.get((cc, code))
            if not gl:
                raise SystemExit("нет данных: %s-%s" % (cc, code))
            raw[code] = proj(unary_union([x.buffer(0.0005) for x in gl]).buffer(-0.0005))
        country = unary_union(list(raw.values())).buffer(0.4).buffer(-0.4).difference(prev)
        prev = prev.union(country)
        codes = list(M)
        cut, taken = [], None
        for code in reversed(codes):
            r = raw[code].intersection(country)
            if taken is not None:
                r = r.difference(taken)
            taken = r if taken is None else taken.union(r)
            cut.append(r)
        cut.reverse()
        rest = country.difference(taken)
        for d in (0.5, 1.0, 2.0, 3.0, 5.0, 8.0):
            if rest.area < 1e-6:
                break
            for k in range(len(cut)):
                add = cut[k].buffer(d).intersection(rest)
                if add.area > 0:
                    cut[k] = cut[k].union(add)
                    rest = rest.difference(add)
        allcut += [polys_only(r) for r in cut]
        allkeys += [(cc, code) for code in codes]
    allcut = list(shapely.coverage_simplify(allcut, 0.8, simplify_boundary=True))
    # после упрощения новые регионы могли заехать на SI/HU — срезаем
    allcut = [polys_only(make_valid(pg).difference(fixed)) for pg in allcut]
    new = []
    for (cc, code), pg in zip(allkeys, allcut):
        polys = []
        for q in getattr(pg, "geoms", [pg]):
            polys += [x for x in getattr(q, "geoms", [q]) if isinstance(x, Polygon)]
        polys = [q for q in polys if q.area > 0.6]
        if not polys:
            raise SystemExit("пусто: %s-%s" % (cc, code))
        polys.sort(key=lambda q: -q.area)
        mp = polys[0]
        c = mp.centroid if mp.contains(mp.centroid) else mp.representative_point()
        new.append({"id": "%s-%s" % (cc, code), "cc": cc, "c": [round(c.x, 1), round(c.y, 1)], "nb": [],
                    "parts": [ring_pts(q) for q in polys], "_geo": unary_union(polys)})
    newall = unary_union([u["_geo"] for u in new])
    cutter = newall.buffer(0.05)
    for u in units:
        if u["cc"] in NE_UNITS:
            continue
        g0 = poly_of(u)
        if g0.intersection(cutter).area < 0.05:
            continue
        set_parts(u, g0, cutter)
        print("старый контур обрезан:", u["id"], round(g0.area - poly_of(u).area, 1))
    old_all = unary_union([poly_of(u) for u in units])
    ctx_all = unary_union([poly_of(c) for c in ctx])
    covered = unary_union([old_all, ctx_all, newall])
    zone = newall.buffer(25).difference(covered)
    zb = box(*zone.bounds)
    nbg = {}
    x0, y0, x1, y1 = zb.bounds
    llbox = box((x0 - 154.29) / 25.7085, (2192.0 - y1) / 38.6135, (x1 - 154.29) / 25.7085, (2192.0 - y0) / 38.6135)
    for f in g["features"]:
        a3 = f["properties"].get("adm0_a3")
        if a3 in NB_UNITS or a3 in NB_CTX:
            sh = shape(f["geometry"])
            if not sh.intersects(llbox):
                continue
            sp = make_valid(proj(sh))
            if sp.intersects(zb):
                nbg.setdefault(a3, []).append(sp.intersection(zb))
    touch = newall.buffer(1.5)
    for a3, gl in nbg.items():
        add = unary_union(gl).intersection(zone)
        comps = [q for q in getattr(add, "geoms", [add]) if isinstance(q, Polygon) and q.area > 0.5 and q.intersects(touch)]
        for q in comps:
            if a3 in NB_UNITS:
                cands = [u for u in units if u["cc"] == NB_UNITS[a3]]
                tgt = min(cands, key=lambda u: poly_of(u).distance(q))
            else:
                tgt = next(c for c in ctx if c["name"] == NB_CTX[a3])
            set_parts(tgt, poly_of(tgt).union(q.buffer(0.3)).buffer(0.2).buffer(-0.2), cutter)
            print("щель заполнена:", tgt.get("id", tgt.get("name")), round(q.area, 1))
    allu = units + new
    geos = [poly_of(u) for u in units] + [u["_geo"] for u in new]
    idx = {u["id"]: i for i, u in enumerate(allu)}

    def link(i, j):
        if j not in allu[i]["nb"]:
            allu[i]["nb"].append(j)
        if i not in allu[j]["nb"]:
            allu[j]["nb"].append(i)
    for k in range(base, len(allu)):
        gk = geos[k].buffer(1.2)
        for j in range(len(allu)):
            if j != k and gk.intersects(geos[j]) and gk.intersection(geos[j]).area > 0.5:
                link(k, j)
    for a, b in SEA:
        link(idx[a], idx[b])
    for u in new:
        del u["_geo"]
    datio.dump("data/world_units.dat", allu)
    newg = unary_union(geos[base:]).buffer(0.1)
    for c in ctx:
        g0 = poly_of(c)
        if not g0.intersects(newg):
            continue
        set_parts(c, g0, newg)
        print("ctx обрезан:", c["name"], round(g0.area - poly_of(c).area, 1))
    gdconst.put(DC, "WORLD_CTX", ctx, True)
    for u in new:
        print(u["id"], len(u["nb"]), sum(len(p) // 2 for p in u["parts"]))


if __name__ == "__main__":
    main()
