# ЗАГОТОВКА BA — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "ba_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "ba_E.json")))
WORLD = {'name': 'Босния и Герцеговина', 'cap': 'Сараево', 'latlon': (43.86, 18.41), 'pop': 3.2, 'gdp': 29.0, 'debt': 17.4, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.0, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': False, 'euro': False, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.45, 0.52, 0.7, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 8.8, 'FR': 7.1, 'NL': 4.6, 'BE': 3.3, 'LU': 1.2, 'CH': 3.7, 'AT': 2.8, 'PL': 3.8, 'CZ': 2.3, 'DK': 2.6, 'NO': 2.7, 'SE': 3.1, 'IT': 6.1, 'ES': 5.2, 'PT': 2.2, 'GB': 7.5, 'IE': 3.0, 'SI': 1.1, 'SK': 1.5, 'HU': 1.9, 'FI': 2.2, 'HR': 1.2, 'RS': 1.2, 'ME': 0.4, 'MK': 0.5, 'AL': 0.6, 'XK': 0.4, 'BG': 1.3, 'RO': 2.5, 'GR': 2.0, 'EE': 0.8, 'LV': 0.8, 'LT': 1.2}, 'trade_m': {'DE': 8.8, 'FR': 7.1, 'NL': 4.6, 'BE': 3.3, 'LU': 1.2, 'CH': 3.7, 'AT': 2.8, 'PL': 3.8, 'CZ': 2.3, 'DK': 2.6, 'NO': 2.7, 'SE': 3.1, 'IT': 6.1, 'ES': 5.2, 'PT': 2.2, 'GB': 7.5, 'IE': 3.0, 'SI': 1.1, 'SK': 1.5, 'HU': 1.9, 'FI': 2.2, 'HR': 1.2, 'RS': 1.2, 'ME': 0.4, 'MK': 0.5, 'AL': 0.6, 'XK': 0.4, 'BG': 1.3, 'RO': 2.5, 'GR': 2.0, 'EE': 0.8, 'LV': 0.8, 'LT': 1.2}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
