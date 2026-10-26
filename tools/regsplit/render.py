import json,sys
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MP
import random
cc=sys.argv[1]; out=sys.argv[2] if len(sys.argv)>2 else 'r_%s.png'%cc
U=json.load(open('out/out_world_units.dat',encoding='utf8'))
fig,ax=plt.subplots(figsize=(9,9))
xs=[];ys=[]
random.seed(3)
for u in U:
    mine=u['cc']==cc
    col=(random.random()*.7+.3,random.random()*.7+.3,random.random()*.7+.3)
    for r in u['parts']:
        pts=[(r[k],r[k+1]) for k in range(0,len(r),2)]
        if mine:
            ax.add_patch(MP(pts,closed=True,fc=col,ec='k',lw=.6))
            xs+=[p[0] for p in pts]; ys+=[p[1] for p in pts]
        else:
            ax.add_patch(MP(pts,closed=True,fc='#dddddd',ec='#999999',lw=.3))
    if mine: ax.annotate(u['id'][len(cc)+1:],u['c'],fontsize=8,ha='center')
mx=(max(xs)-min(xs))*.15
ax.set_xlim(min(xs)-mx,max(xs)+mx); ax.set_ylim(max(ys)+mx,min(ys)-mx); ax.set_aspect('equal')
plt.savefig(out,dpi=80,bbox_inches='tight')
