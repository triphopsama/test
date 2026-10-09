# Transforme la colonne emploi_du_temps de brumeval.csv en table propre heure -> lieu.
import csv, re, sys
src, out = sys.argv[1], sys.argv[2]
MAISON = {"BRU001":"boulangerie","BRU002":"forge","BRU003":"comptoir","BRU004":"chapelle","BRU005":"boulangerie",
 "BRU006":"joss","BRU007":"mairie","BRU008":"mairie","BRU009":"mairie","BRU010":"taverne","BRU011":"taverne",
 "BRU012":"forge","BRU013":"moulin","BRU014":"garde","BRU015":"agnes","BRU016":"agnes","BRU017":"taverne",
 "BRU018":"ferme","BRU019":"atelier","BRU020":"cabane","BRU021":"taverne","BRU022":"taverne"}
# mots-clés -> lieu (ordre = priorité)
MOTS = [("préparations","agnes"),("alliance","chapelle"),("avec tim","plage"),("crique","crique"),("falaise","falaise"),("cabane","cabane"),("comptoir","comptoir"),("taverne","taverne"),
 ("fournil","boulangerie"),("boutique","boulangerie"),("livraisons","place"),("forge","forge"),("chapelle","chapelle"),("sacristie","chapelle"),
 ("école","chapelle"),("prière","chapelle"),("jardin d'herbes","chapelle"),("toit","chapelle"),("soins aux malades","chapelle"),
 ("mairie","mairie"),("visites de malades","place"),("visites","place"),("réception","mairie"),("atelier","atelier"),("clientes","atelier"),
 ("moulin","moulin"),("ventes","moulin"),("réparations de clôtures","ferme"),("réparations","moulin"),("bergerie","ferme"),("pâturages","landes"),
 ("cueillette","reveil"),("chasse","reveil"),("préparations","agnes"),("chez agnès","agnes"),("ronde de la place","place"),
 ("ronde du port","port"),("port","port"),("pêche","port"),("marché","place"),("plage","plage"),("promenade","port"),
 ("sieste","@maison"),("maison","@maison"),("repas","@maison"),("dort","@maison"),("lever","@maison"),("ménage","taverne"),("service","taverne"),
 ("pansement","forge"),("petits travaux","forge"),("ronde vers","falaise"),("leçon d'arc","cabane"),("sculpture","cabane"),("mer","port")]
def lieu_de(txt, pid):
    t=txt.lower()
    for k,v in MOTS:
        if k in t: return MAISON[pid] if v=="@maison" else v
    return None
rows=[]
for r in csv.DictReader(open(src,encoding="utf-8"),delimiter=";"):
    pid=r["id"]
    if r["lieu"]!="Brumeval": continue
    plan=[(0,MAISON[pid],"nuit")]
    for part in r["emploi_du_temps"].split(","):
        m=re.match(r"\s*(\d{1,2})h(?:-(\d{1,2})h)?\s*(.*)",part)
        if not m: continue
        h=int(m.group(1)); quoi=m.group(3).strip(); l=lieu_de(quoi,pid)
        if not l: print("?",pid,part); continue
        plan.append((h,l,quoi))
        if m.group(2) and int(m.group(2))<24 and "crique" in quoi:
            pass
        if m.group(2):
            fin=int(m.group(2))
            if fin<h: fin+=24
            plan.append((fin%24,MAISON[pid],"retour"))
    # trier, dédoublonner: une fin "retour" écrasée par un début à la même heure
    d={}
    for h,l,q in plan:
        if h in d and q=="retour": continue
        d[h]=(l,q)
    for h in sorted(d): rows.append((pid,r["nom"],h,d[h][0],d[h][1]))
with open(out,"w",encoding="utf-8",newline="") as fh:
    w=csv.writer(fh,delimiter=";"); w.writerow(["pnj","nom","heure","lieu","activite"])
    for x in rows: w.writerow(x)
for x in rows: print(x)
