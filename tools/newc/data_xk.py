# ЗАГОТОВКА XK — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "xk_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "xk_E.json")))
WORLD = {'name': 'Косово', 'cap': 'Приштина', 'latlon': (42.66, 21.17), 'pop': 1.6, 'gdp': 11.0, 'debt': 6.6, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.01, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': False, 'euro': True, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.4, 0.5, 0.72, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 5.4, 'FR': 4.4, 'NL': 2.8, 'BE': 2.0, 'LU': 0.7, 'CH': 2.3, 'AT': 1.7, 'PL': 2.3, 'CZ': 1.4, 'DK': 1.6, 'NO': 1.7, 'SE': 1.9, 'IT': 3.7, 'ES': 3.2, 'PT': 1.4, 'GB': 4.6, 'IE': 1.8, 'SI': 0.7, 'SK': 0.9, 'HU': 1.2, 'FI': 1.3, 'HR': 0.8, 'RS': 0.7, 'BA': 0.4, 'ME': 0.2, 'MK': 0.3, 'AL': 0.4, 'BG': 0.8, 'RO': 1.5, 'GR': 1.2, 'EE': 0.5, 'LV': 0.5, 'LT': 0.7}, 'trade_m': {'DE': 5.4, 'FR': 4.4, 'NL': 2.8, 'BE': 2.0, 'LU': 0.7, 'CH': 2.3, 'AT': 1.7, 'PL': 2.3, 'CZ': 1.4, 'DK': 1.6, 'NO': 1.7, 'SE': 1.9, 'IT': 3.7, 'ES': 3.2, 'PT': 1.4, 'GB': 4.6, 'IE': 1.8, 'SI': 0.7, 'SK': 0.9, 'HU': 1.2, 'FI': 1.3, 'HR': 0.8, 'RS': 0.7, 'BA': 0.4, 'ME': 0.2, 'MK': 0.3, 'AL': 0.4, 'BG': 0.8, 'RO': 1.5, 'GR': 1.2, 'EE': 0.5, 'LV': 0.5, 'LT': 0.7}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
