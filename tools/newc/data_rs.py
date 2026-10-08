# ЗАГОТОВКА RS — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "rs_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "rs_E.json")))
WORLD = {'name': 'Сербия', 'cap': 'Белград', 'latlon': (44.82, 20.46), 'pop': 6.6, 'gdp': 80.0, 'debt': 48.0, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.0, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': False, 'euro': False, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.58, 0.36, 0.36, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'RO': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 14.6, 'FR': 11.9, 'NL': 7.6, 'BE': 5.5, 'LU': 2.0, 'CH': 6.1, 'AT': 4.7, 'PL': 6.3, 'CZ': 3.8, 'DK': 4.3, 'NO': 4.5, 'SE': 5.1, 'IT': 10.1, 'ES': 8.7, 'PT': 3.7, 'GB': 12.5, 'IE': 5.0, 'SI': 1.8, 'SK': 2.5, 'HU': 3.2, 'FI': 3.6, 'HR': 2.0, 'BA': 1.2, 'ME': 0.6, 'MK': 0.9, 'AL': 1.1, 'XK': 0.7, 'BG': 2.2, 'RO': 4.1, 'GR': 3.3, 'EE': 1.4, 'LV': 1.4, 'LT': 1.9}, 'trade_m': {'DE': 14.6, 'FR': 11.9, 'NL': 7.6, 'BE': 5.5, 'LU': 2.0, 'CH': 6.1, 'AT': 4.7, 'PL': 6.3, 'CZ': 3.8, 'DK': 4.3, 'NO': 4.5, 'SE': 5.1, 'IT': 10.1, 'ES': 8.7, 'PT': 3.7, 'GB': 12.5, 'IE': 5.0, 'SI': 1.8, 'SK': 2.5, 'HU': 3.2, 'FI': 3.6, 'HR': 2.0, 'BA': 1.2, 'ME': 0.6, 'MK': 0.9, 'AL': 1.1, 'XK': 0.7, 'BG': 2.2, 'RO': 4.1, 'GR': 3.3, 'EE': 1.4, 'LV': 1.4, 'LT': 1.9}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
