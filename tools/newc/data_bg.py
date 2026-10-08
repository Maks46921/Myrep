# ЗАГОТОВКА BG — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "bg_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "bg_E.json")))
WORLD = {'name': 'Болгария', 'cap': 'София', 'latlon': (42.7, 23.32), 'pop': 6.4, 'gdp': 105.0, 'debt': 63.0, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.01, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': True, 'euro': True, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.42, 0.6, 0.45, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 16.7, 'FR': 13.6, 'NL': 8.7, 'BE': 6.3, 'LU': 2.3, 'CH': 7.0, 'AT': 5.4, 'PL': 7.3, 'CZ': 4.3, 'DK': 4.9, 'NO': 5.1, 'SE': 5.8, 'IT': 11.5, 'ES': 10.0, 'PT': 4.2, 'GB': 14.3, 'IE': 5.7, 'SI': 2.1, 'SK': 2.9, 'HU': 3.6, 'FI': 4.1, 'HR': 2.3, 'RS': 2.2, 'BA': 1.3, 'ME': 0.7, 'MK': 1.0, 'AL': 1.2, 'XK': 0.8, 'RO': 4.7, 'GR': 3.8, 'EE': 1.6, 'LV': 1.6, 'LT': 2.2}, 'trade_m': {'DE': 16.7, 'FR': 13.6, 'NL': 8.7, 'BE': 6.3, 'LU': 2.3, 'CH': 7.0, 'AT': 5.4, 'PL': 7.3, 'CZ': 4.3, 'DK': 4.9, 'NO': 5.1, 'SE': 5.8, 'IT': 11.5, 'ES': 10.0, 'PT': 4.2, 'GB': 14.3, 'IE': 5.7, 'SI': 2.1, 'SK': 2.9, 'HU': 3.6, 'FI': 4.1, 'HR': 2.3, 'RS': 2.2, 'BA': 1.3, 'ME': 0.7, 'MK': 1.0, 'AL': 1.2, 'XK': 0.8, 'RO': 4.7, 'GR': 3.8, 'EE': 1.6, 'LV': 1.6, 'LT': 2.2}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
