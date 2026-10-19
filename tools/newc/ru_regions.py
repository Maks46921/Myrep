# V50_1: 89 субъектов России в игре — 83 «старых», Крым и Севастополь (2014) и четыре занятые в 2022 году территории Украины
# (ДНР, ЛНР, Запорожская и Херсонская области — в пределах линии фронта). Международно признаны территорией Украины: Крым, Севастополь и эти четыре.
# Данные — ru_reg_a.py (Центр и Северо-Запад), ru_reg_b.py (Юг, Кавказ, Крым, занятые территории), ru_reg_c.py (Поволжье и Урал), ru_reg_d.py (Сибирь и Дальний Восток).
RU_ORDER = ["MOW", "MOS", "SPB",
            # Центральный ФО
            "BEL", "BRY", "VLA", "VOR", "IVA", "KLU", "KOS", "KRS", "LIP", "ORL", "RYA", "SMO", "TAM", "TVE", "TUL", "YAR",
            # Северо-Западный ФО
            "LEN", "KGD", "KR", "KO", "ARK", "NEN", "VLG", "MUR", "NGR", "PSK",
            # Южный ФО и Крым
            "KDA", "AD", "ROS", "VGG", "AST", "KL", "CR", "SEV",
            # Северо-Кавказский ФО
            "DA", "IN", "KB", "KC", "SE", "CE", "STA",
            # Приволжский ФО
            "NIZ", "KIR", "ME", "MO", "CU", "UD", "PER", "PNZ", "ULY", "SAM", "SAR", "ORE", "TA", "BA",
            # Уральский ФО
            "SVE", "CHE", "KGN", "TYU", "KHM", "YAN",
            # Сибирский ФО
            "ALT", "AL", "TY", "KK", "KYA", "IRK", "KEM", "NVS", "OMS", "TOM",
            # Дальневосточный ФО
            "BU", "ZAB", "SA", "KAM", "PRI", "KHA", "AMU", "MAG", "SAK", "YEV", "CHU",
            # занятые в 2022 году территории Украины
            "DNR", "LNR", "ZAP", "KHE"]
assert len(RU_ORDER) == 89 and len(set(RU_ORDER)) == 89
# занятые территории (международно — Украина): штриховка на карте, особый статус в федерации
RU_DISPUTED = ["CR", "SEV", "DNR", "LNR", "ZAP", "KHE"]


def load():
    """(регионы в порядке RU_ORDER, доп. данные по коду)"""
    import ru_reg_a, ru_reg_b, ru_reg_c, ru_reg_d
    by = {}
    extra = {}
    for m in (ru_reg_a, ru_reg_b, ru_reg_c, ru_reg_d):
        for r in m.REGIONS:
            if r["code"] in by:
                raise SystemExit("субъект дважды: " + r["code"])
            by[r["code"]] = r
        extra.update(getattr(m, "EXTRA", {}))
    miss = [c for c in RU_ORDER if c not in by]
    if miss:
        raise SystemExit("нет данных субъектов: " + " ".join(miss))
    return [by[c] for c in RU_ORDER], extra
