# Помощник записи субъекта России (V50_1): тот же формат, что R(...) в ru_core.py.
def R(code, name, short, pop, pcrel, dev, unrest, auto, reg, tr, sec, infra, edu, health, env, mix, desc, E, stub=None):
    """E — партийные списки 2021 года (%; у занятых в 2022 году территорий — региональные выборы 2023 года); stub — профиль несистемной оппозиции."""
    Ecal = None
    if stub is not None:
        Ecal = list(E); Ecal[9] = stub
    return dict(code=code, name=name, short=short, pop=pop, pcrel=pcrel, dev=dev, unrest=unrest, auto=auto, reg=reg, tr=tr,
                sec={"ind": sec[0], "agr": sec[1], "srv": sec[2], "res": sec[3]}, infra=infra, edu=edu, health=health, env=env, mix=mix, desc=desc, E=E, Ecal=Ecal)
