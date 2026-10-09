import csv, sys, os
from data import *
out=sys.argv[1]; os.makedirs(out,exist_ok=True)
num={l[0]:i for i,l in enumerate(LIEUX,1)}
with open(f"{out}/brumeval_lieux.csv","w",encoding="utf-8",newline="") as fh:
    w=csv.writer(fh,delimiter=";")
    w.writerow(["id","cle","numero","nom","type","x","y","hauteur","habitants","horaires","acces","cache","terrain_combat","relie_a"])
    for l in LIEUX:
        rel=sorted({b for a,b,f,c in CHEMINS if a==l[0]}|{a for a,b,f,c in CHEMINS if b==l[0]})
        w.writerow(["BRU_L%02d"%num[l[0]],l[0],num[l[0]],l[1],l[2],l[3],l[4],l[5],l[6],l[7],l[8],l[9],l[10],",".join("BRU_L%02d"%num[r] for r in rel)])
with open(f"{out}/brumeval_chemins.csv","w",encoding="utf-8",newline="") as fh:
    w=csv.writer(fh,delimiter=";")
    w.writerow(["de","a","distance_m","marche_min","course_min","condition"])
    for a,b,f,c in CHEMINS:
        m=d(a,b)*f
        w.writerow(["BRU_L%02d"%num[a],"BRU_L%02d"%num[b],round(m),round(minutes(m,MARCHE),1),round(minutes(m,COURSE),1),c or "—"])
# table markdown des trajets utiles
pairs=[("place","taverne"),("place","garde"),("place","mairie"),("place","boulangerie"),("boulangerie","forge"),("forge","atelier"),("place","port"),("comptoir","taverne"),("port","plage"),("place","chapelle"),("place","lavoir"),("place","moulin"),("moulin","ferme"),("place","agnes"),("reveil","agnes"),("reveil","place"),("cabane","reveil"),("place","falaise"),("falaise","crique"),("place","crique"),("taverne","crique"),("moulin","crique"),("crique","bouche"),("port","guet"),("chapelle","sentier")]
def fmt(x):
    m=int(x); s=int(round((x-m)*60/15)*15)
    if s==60: m+=1; s=0
    return f"{m} min" + (f" {s:02d}" if s else "") if m else f"{s} s"
rows=[]
for a,b in pairs:
    h=dist(a,b,False); bb=dist(a,b,True)
    t=f"| {L[a][1]} → {L[b][1]} | {round(h) if h else '—'} m | {fmt(minutes(h,MARCHE)) if h else '—'} | {fmt(minutes(h,COURSE)) if h else '—'} |"
    if bb and (not h or bb<h-30): t+=f" À marée basse, par les rochers : {round(bb)} m, {fmt(minutes(bb,MARCHE))} |"
    else: t+=" |"
    rows.append(t)
open(f"{out}/_trajets.md","w").write("\n".join(rows))
print("\n".join(rows))

with open(f"{out}/brumeval_zones.csv","w",encoding="utf-8",newline="") as fh:
    w=csv.writer(fh,delimiter=";"); w.writerow(["zone","ordre","x","y"])
    for nom,pts in (("cote",COTE),("landes",LANDES),("bois",BOIS),("ruisseau",RUISSEAU)):
        for i,(x,y) in enumerate(pts): w.writerow([nom,i,x,y])
