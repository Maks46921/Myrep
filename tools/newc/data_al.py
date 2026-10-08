# ЗАГОТОВКА AL — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "al_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "al_E.json")))
WORLD = {'name': 'Албания', 'cap': 'Тирана', 'latlon': (41.33, 19.82), 'pop': 2.4, 'gdp': 25.0, 'debt': 15.0, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.0, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': False, 'euro': False, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.6, 0.3, 0.32, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 8.1, 'FR': 6.6, 'NL': 4.3, 'BE': 3.1, 'LU': 1.1, 'CH': 3.4, 'AT': 2.6, 'PL': 3.5, 'CZ': 2.1, 'DK': 2.4, 'NO': 2.5, 'SE': 2.8, 'IT': 5.6, 'ES': 4.9, 'PT': 2.0, 'GB': 7.0, 'IE': 2.8, 'SI': 1.0, 'SK': 1.4, 'HU': 1.8, 'FI': 2.0, 'HR': 1.1, 'RS': 1.1, 'BA': 0.6, 'ME': 0.3, 'MK': 0.5, 'XK': 0.4, 'BG': 1.2, 'RO': 2.3, 'GR': 1.9, 'EE': 0.8, 'LV': 0.8, 'LT': 1.1}, 'trade_m': {'DE': 8.1, 'FR': 6.6, 'NL': 4.3, 'BE': 3.1, 'LU': 1.1, 'CH': 3.4, 'AT': 2.6, 'PL': 3.5, 'CZ': 2.1, 'DK': 2.4, 'NO': 2.5, 'SE': 2.8, 'IT': 5.6, 'ES': 4.9, 'PT': 2.0, 'GB': 7.0, 'IE': 2.8, 'SI': 1.0, 'SK': 1.4, 'HU': 1.8, 'FI': 2.0, 'HR': 1.1, 'RS': 1.1, 'BA': 0.6, 'ME': 0.3, 'MK': 0.5, 'XK': 0.4, 'BG': 1.2, 'RO': 2.3, 'GR': 1.9, 'EE': 0.8, 'LV': 0.8, 'LT': 1.1}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
