import sys, math, random
from PIL import Image, ImageDraw, ImageFont
from data import *
S=0.8; W,H=int(1720*S),int(1180*S)
img=Image.new("RGB",(W,H),(64,112,160)); dr=ImageDraw.Draw(img)
F="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"; FB="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
f=ImageFont.truetype(F,12); fb=ImageFont.truetype(FB,13); ft=ImageFont.truetype(FB,22); fs=ImageFont.truetype(F,11)
P=lambda x,y:(x*S,y*S)
cote=COTE
dr.polygon([P(*p) for p in cote],fill=(132,168,96))
# landes
dr.polygon([P(*p) for p in LANDES],fill=(150,140,110))
# bois
dr.polygon([P(*p) for p in BOIS],fill=(52,96,58))
random.seed(3)
for i in range(700):
    x=random.uniform(980,1720); y=random.uniform(0,600)
    if dr.im.getpixel(P(x,y))==(52,96,58): dr.ellipse([P(x-7,y-7),P(x+7,y+7)],fill=(40,78,46))
# falaises (trait épais le long de la côte nord)
dr.line([P(*p) for p in cote[:14]],fill=(110,100,90),width=6)
# butte de la chapelle
dr.ellipse([P(400,830),P(545,945)],fill=(150,180,110))
# ruisseau
dr.line([P(*p) for p in RUISSEAU],fill=(80,140,200),width=4)
dr.line([P(800,540),P(770,560)],fill=(80,140,200),width=6)
# chemins
for a,b,fac,c in CHEMINS:
    A,B=L[a],L[b]
    col=(225,205,160); w=4
    if "marée" in c and {a,b}=={"crique","port"}:
        pts=[(195,288),(165,335),(110,395),(150,445),(220,475),(225,560),(240,600)]
        dr.line([P(*p) for p in pts],fill=(200,200,200),width=2); continue
    if "marée" in c: col=(200,200,200); w=2
    elif L[a][2]=="donjon" or L[b][2]=="donjon": col=(170,150,130); w=2
    dr.line([P(A[3],A[4]),P(B[3],B[4])],fill=col,width=w)
# lien souterrain puits → bouche
for t in range(0,10):
    x1=352+(198-352)*t/10; y1=178+(190-178)*t/10; x2=352+(198-352)*(t+.5)/10; y2=178+(190-178)*(t+.5)/10
    dr.line([P(x1,y1),P(x2,y2)],fill=(60,40,30),width=2)
# bâtiments et lieux
couleurs={"maison":(170,90,60),"métier":(190,120,60),"village":(220,200,140),"sacré":(235,235,250),"donjon":(40,30,30),"côte":(230,220,170),"bois":(30,60,35),"ferme":(170,110,60),"landes":(120,110,80),"route":(225,205,160)}
num={}
for i,l in enumerate(LIEUX,1):
    num[l[0]]=i; x,y=P(l[3],l[4]); c=couleurs[l[2]]
    r=7
    if l[2] in ("maison","métier","ferme","sacré"): dr.rectangle([x-r,y-r,x+r,y+r],fill=c,outline=(30,30,30))
    else: dr.ellipse([x-r,y-r,x+r,y+r],fill=c,outline=(30,30,30))
    t=str(i); tw=dr.textlength(t,font=fs); dr.text((x-tw/2,y-7),t,font=fs,fill=(0,0,0) if l[2] not in("donjon","bois") else (255,255,255))
# étiquettes courtes
def lab(id,txt,dx=10,dy=-6,font=f):
    x,y=P(L[id][3],L[id][4]); dr.text((x+dx,y+dy),txt,font=font,fill=(15,15,15),stroke_width=2,stroke_fill=(245,240,225))
for id,txt,dx,dy in [("reveil","Réveil",10,-6),("chene","Vieux chêne",10,-6),("loups","Loups",-50,-6),("cabane","Cabane",10,-6),("agnes","Agnès",10,-6),("fontaine","Vieille Fontaine",10,-2),("ferme","Ferme",10,-6),("moulin","Moulin",10,-6),("lavoir","Lavoir",10,-4),("landes","Landes du Haut",10,-6),("falaise","Maison de la falaise",10,-12),("puits","Puits",10,0),("bouche","Bouche de mer",-95,-16),("crique","Crique",10,-4),("guet","Pointe du Guet",-110,8),("port","Port",-40,-4),("comptoir","Comptoir",8,-16),("joss","Joss",-40,0),("taverne","Taverne",-58,6),("place","Place",8,-4),("garde","Garde",9,-14),("mairie","Mairie",8,-6),("boulangerie","Boulangerie",-82,0),("forge","Forge",-8,8),("atelier","Couture",8,0),("plage","Plage",-50,4),("chapelle","Chapelle",10,-6),("sentier","→ Pierrefane (16 km, 3 h)",10,-12)]:
    lab(id,txt,dx,dy)
dr.text((20,14),"Brumeval",font=ft,fill=(255,255,255),stroke_width=2,stroke_fill=(30,40,60))
dr.text((20,42),"MER",font=fb,fill=(220,235,255))
dr.text(P(1300,40),"Bois de Ronceval",font=fb,fill=(230,240,220),stroke_width=2,stroke_fill=(20,40,20))
# échelle et nord
x0,y0=P(1280,1120); dr.line([x0,y0,x0+200*S,y0],fill=(0,0,0),width=3); dr.text((x0,y0-18),"200 m · 2 min 15 à pied",font=f,fill=(0,0,0))
nx,ny=P(1660,1050); dr.polygon([(nx,ny-30),(nx-9,ny),(nx+9,ny)],fill=(0,0,0)); dr.text((nx-5,ny+2),"N",font=fb,fill=(0,0,0))
lx,ly=P(700,1000)
for i,(t,c,w) in enumerate([("Chemin",(225,205,160),4),("Rochers, marée basse",(200,200,200),2),("Galerie de la grotte",(60,40,30),2),("Ruisseau",(80,140,200),4)]):
    dr.line([lx,ly+i*16+7,lx+28,ly+i*16+7],fill=c,width=w); dr.text((lx+34,ly+i*16),t,font=f,fill=(0,0,0))
img.save(sys.argv[1]); print(img.size)
