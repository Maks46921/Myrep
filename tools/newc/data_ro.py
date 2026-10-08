# ЗАГОТОВКА RO — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "ro_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "ro_E.json")))
WORLD = {'name': 'Румыния', 'cap': 'Бухарест', 'latlon': (44.43, 26.1), 'pop': 19.0, 'gdp': 360.0, 'debt': 216.0, 'growth': 1.5, 'infl': 2.5, 'unemp': 5.5, 'def': 3.0, 'stab': 60, 'appr': 35, 'gov': 'заготовка', 'gov_party': 'заготовка', 'pot': 1.5, 'ecb_w': 0.0, 'stance': {'eu': 0.5, 'aus': 0.2, 'trd': 0.6, 'brd': 0.0, 'nuk': 0.0}, 'desc': 'Заготовка', 'leader': 'Премьер-министр', 'pn': ['П1', 'П2', 'П3', 'П4', 'П5', 'П6', 'Др.', 'П8', 'П9', 'П10'], 'eu': True, 'euro': False, 'likes': 'заготовка', 'dislikes': 'заготовка', 'open': 0.7, 'stance0': 0.1, 'ccol': (0.66, 0.6, 0.35, 1.0), 'rel': {'DE': 70, 'FR': 70, 'NL': 70, 'BE': 70, 'LU': 70, 'CH': 70, 'AT': 70, 'PL': 70, 'CZ': 70, 'DK': 70, 'NO': 70, 'SE': 70, 'IT': 70, 'ES': 70, 'PT': 70, 'GB': 70, 'IE': 70, 'SI': 70, 'SK': 70, 'HU': 70, 'FI': 70, 'HR': 70, 'RS': 70, 'BA': 70, 'ME': 70, 'MK': 70, 'AL': 70, 'XK': 70, 'BG': 70, 'GR': 70, 'EE': 70, 'LV': 70, 'LT': 70}, 'trade_x': {'DE': 30.9, 'FR': 25.1, 'NL': 16.2, 'BE': 11.6, 'LU': 4.2, 'CH': 12.9, 'AT': 10.0, 'PL': 13.4, 'CZ': 8.0, 'DK': 9.1, 'NO': 9.4, 'SE': 10.8, 'IT': 21.4, 'ES': 18.5, 'PT': 7.8, 'GB': 26.6, 'IE': 10.6, 'SI': 3.8, 'SK': 5.4, 'HU': 6.8, 'FI': 7.6, 'HR': 4.3, 'RS': 4.1, 'BA': 2.5, 'ME': 1.2, 'MK': 1.8, 'AL': 2.3, 'XK': 1.5, 'BG': 4.7, 'GR': 7.1, 'EE': 2.9, 'LV': 3.0, 'LT': 4.1}, 'trade_m': {'DE': 30.9, 'FR': 25.1, 'NL': 16.2, 'BE': 11.6, 'LU': 4.2, 'CH': 12.9, 'AT': 10.0, 'PL': 13.4, 'CZ': 8.0, 'DK': 9.1, 'NO': 9.4, 'SE': 10.8, 'IT': 21.4, 'ES': 18.5, 'PT': 7.8, 'GB': 26.6, 'IE': 10.6, 'SI': 3.8, 'SK': 5.4, 'HU': 6.8, 'FI': 7.6, 'HR': 4.3, 'RS': 4.1, 'BA': 2.5, 'ME': 1.2, 'MK': 1.8, 'AL': 2.3, 'XK': 1.5, 'BG': 4.7, 'GR': 7.1, 'EE': 2.9, 'LV': 3.0, 'LT': 4.1}}
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
