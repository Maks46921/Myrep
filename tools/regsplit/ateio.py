import re,numpy as np
import os
P=os.environ.get('SYM_DATA', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'data') + '/')
def load_ate():
    s=open(P+'ate.dat',encoding='utf8').read()
    d={}
    for m in re.finditer(r'"(\w+)":\s*(Packed\w+Array)\(',s):
        k=m.group(1); st=m.end()
        en=s.index(')',st)
        body=s[st:en]
        if m.group(2)=='PackedStringArray':
            d[k]=re.findall(r'"([^"]*)"',body)
        elif m.group(2)=='PackedInt32Array':
            d[k]=np.array([int(x) for x in body.replace('\n',' ').split(',') if x.strip()])
        else:
            d[k]=np.array([float(x) for x in body.replace('\n',' ').split(',') if x.strip()])
    return s,d
if __name__=='__main__':
    s,d=load_ate()
    for k,v in d.items(): print(k,len(v))

def save_arrays(s, d, keys, fmt='%.5f'):
    """переписывает указанные Packed*Array в тексте ate.dat"""
    for k in keys:
        m = re.search(r'"%s":\s*(Packed\w+Array)\(' % k, s)
        st = m.end(); en = s.index(')', st)
        s = s[:st] + ', '.join(fmt % x for x in d[k]) + s[en:]
    return s

def renorm(d):
    """pw, gw внутри каждой единицы снова дают 1"""
    import numpy as np
    uid = np.array(d['uid'])
    for k in ('pw', 'gw'):
        a = np.array(d[k], float)
        for u in set(uid):
            m = uid == u
            t = a[m].sum()
            a[m] = a[m] / t if t > 0 else 1.0 / m.sum()
        d[k] = a
    return d
