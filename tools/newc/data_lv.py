# ЗАГОТОВКА LV — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "lv_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "lv_E.json")))
WORLD = {'name': 'Латвия', 'cap': 'Рига', 'latlon': (56.95, 24.11), 'pop': 1.86, 'gdp': 42.0, 'debt': 25.2, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.01, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': True, 'euro': True, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.62, 0.38, 0.4, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LT': 70}, 'trade_x': {'DE': 10.5, 'FR': 8.6, 'NL': 5.5, 'BE': 4.0, 'LU': 1.4, 'CH': 4.4, 'AT': 3.4, 'PL': 4.6, 'CZ': 2.7, 'DK': 3.1, 'NO': 3.2, 'SE': 3.7, 'IT': 7.3, 'ES': 6.3, 'PT': 2.6, 'GB': 9.1, 'IE': 3.6, 'SI': 1.3, 'SK': 1.8, 'HU': 2.3, 'FI': 2.6, 'HR': 1.5, 'RS': 1.4, 'BA': 0.8, 'ME': 0.4, 'MK': 0.6, 'AL': 0.8, 'XK': 0.5, 'BG': 1.6, 'RO': 3.0, 'GR': 2.4, 'EE': 1.0, 'LT': 1.4}, 'trade_m': {'DE': 10.5, 'FR': 8.6, 'NL': 5.5, 'BE': 4.0, 'LU': 1.4, 'CH': 4.4, 'AT': 3.4, 'PL': 4.6, 'CZ': 2.7, 'DK': 3.1, 'NO': 3.2, 'SE': 3.7, 'IT': 7.3, 'ES': 6.3, 'PT': 2.6, 'GB': 9.1, 'IE': 3.6, 'SI': 1.3, 'SK': 1.8, 'HU': 2.3, 'FI': 2.6, 'HR': 1.5, 'RS': 1.4, 'BA': 0.8, 'ME': 0.4, 'MK': 0.6, 'AL': 0.8, 'XK': 0.5, 'BG': 1.6, 'RO': 3.0, 'GR': 2.4, 'EE': 1.0, 'LT': 1.4}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
