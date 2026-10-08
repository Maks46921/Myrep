# ЗАГОТОВКА MK — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "mk_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "mk_E.json")))
WORLD = {'name': 'Северная Македония', 'cap': 'Скопье', 'latlon': (41.99, 21.43), 'pop': 1.8, 'gdp': 16.0, 'debt': 9.6, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.0, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': False, 'euro': False, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.72, 0.55, 0.3, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 6.5, 'FR': 5.3, 'NL': 3.4, 'BE': 2.4, 'LU': 0.9, 'CH': 2.7, 'AT': 2.1, 'PL': 2.8, 'CZ': 1.7, 'DK': 1.9, 'NO': 2.0, 'SE': 2.3, 'IT': 4.5, 'ES': 3.9, 'PT': 1.6, 'GB': 5.6, 'IE': 2.2, 'SI': 0.8, 'SK': 1.1, 'HU': 1.4, 'FI': 1.6, 'HR': 0.9, 'RS': 0.9, 'BA': 0.5, 'ME': 0.3, 'AL': 0.5, 'XK': 0.3, 'BG': 1.0, 'RO': 1.8, 'GR': 1.5, 'EE': 0.6, 'LV': 0.6, 'LT': 0.9}, 'trade_m': {'DE': 6.5, 'FR': 5.3, 'NL': 3.4, 'BE': 2.4, 'LU': 0.9, 'CH': 2.7, 'AT': 2.1, 'PL': 2.8, 'CZ': 1.7, 'DK': 1.9, 'NO': 2.0, 'SE': 2.3, 'IT': 4.5, 'ES': 3.9, 'PT': 1.6, 'GB': 5.6, 'IE': 2.2, 'SI': 0.8, 'SK': 1.1, 'HU': 1.4, 'FI': 1.6, 'HR': 0.9, 'RS': 0.9, 'BA': 0.5, 'ME': 0.3, 'AL': 0.5, 'XK': 0.3, 'BG': 1.0, 'RO': 1.8, 'GR': 1.5, 'EE': 0.6, 'LV': 0.6, 'LT': 0.9}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
