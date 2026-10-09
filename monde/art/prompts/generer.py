#!/usr/bin/env python3
"""Prompts d'images des PNJ : python3 generer.py -> brumeval.md et brumeval.csv.
Les apparences viennent des fiches (donnees/pnj/brumeval.csv) ; la traduction anglaise est ici,
parce que les modèles d'image comprennent mieux l'anglais."""
import csv, os
ICI = os.path.dirname(os.path.abspath(__file__))


# id: (description en anglais, cadrage conseillé, notes)
P = {
"BRU001": ("1woman, 34 years old, baker, medium height, sturdy round arms, round face flushed from the oven, tired hazel eyes, brown hair tied under a white headscarf, flour up to the elbows, stained apron over a brown dress, small burn scar on left wrist, warm tired smile", "devant le four de la boulangerie, à l'aube", ""),
"BRU002": ("1man, 47 years old, blacksmith, very tall and massive, bull shoulders, huge scarred hands, square face, short grey beard, shaved head, bushy eyebrows, leather apron over a torn linen shirt, forge glow, stern proud expression", "à la forge, marteau en main", "Jour 1 : pas encore de bandage au bras (la brûlure arrive plus tard)."),
"BRU003": ("1man, 29 years old, smuggler merchant, slim and supple, handsome thin smiling face, sharp grey eyes, shoulder-length black hair tied with a silk ribbon, thin mustache, rings on fingers, embroidered midnight-blue doublet, polished boots, charming but dangerous smile, hidden blade in left sleeve", "au comptoir, la nuit, une lanterne", ""),
"BRU004": ("1woman, 41 years old, priestess, tall and lean, very straight posture, long face with high cheekbones, piercing pale blue eyes, black hair streaked with grey in a bun under a veil, herb-stained hands, grey priestess robe, seven-star pendant, cold dignified expression", "sous le vitrail brisé de la chapelle", ""),
"BRU005": ("1boy, child, 11 years old, skinny lively boy, scraped knees, round freckled face, spiky brown hair, big hazel eyes, oversized shirt, canvas cap, simple wooden bow, curious cheerful expression, fully clothed, wholesome", "sur la plage ou la place, en mouvement", "Enfant : uniquement des images d'enfant, ordinaires. Négatif renforcé."),
"BRU006": ("1man, old man, 72 years old, fisherman storyteller, thin and stooped, sun-tanned cracked skin, laughing blue eyes, wild white beard, missing teeth, red wool cap, patched pea jacket, gnarled hands, pipe", "sur le port, filets et barques", ""),
"BRU007": ("1man, 58 years old, village mayor, pot-bellied, soft pink face, double chin, tired brown eyes behind small spectacles, thinning grey hair combed to the side, silver mayor chain over a burgundy waistcoat, ink-stained fingers, nervous expression", "à la mairie, devant des registres", ""),
"BRU008": ("1woman, 55 years old, wealthy moneylender, tall and thin, queenly posture, angular powdered face, pinched lips, hard green eyes, silver hair styled high, dark silk fitted dress, jet brooch, gloves, cold haughty expression", "dans son salon, gantée", ""),
"BRU009": ("1woman, 24 years old, young copyist, slender, pale oval face, big green eyes, freckles, long braided auburn hair, green dress, grey cape, ink on right middle finger, hopeful secretive expression", "derrière la taverne, le soir", "Jour 1 : robe propre (le goudron et la fuite viennent plus tard)."),
"BRU010": ("1man, 19 years old, minstrel, slim and lanky, beardless gentle face, dreamy brown eyes, messy black curls, easy smile, faded white shirt, green vest, lute on his back", "à la taverne, le luth en main", ""),
"BRU011": ("1woman, dwarf woman, 50 years old, tavern keeper, short and stocky, barrel-wide, thick arms, round ruddy face, upturned nose, mischievous black eyes, long greying red braids with copper rings, spice-stained apron, ladle at her belt, hearty grin", "derrière le comptoir du Hareng Rieur", ""),
"BRU012": ("1man, 22 years old, dockworker, broad shoulders, thick neck, square face with clenched jaw, short brown hair, stubble, open shirt, tarred canvas trousers, troubled guilty look", "sur le quai, un tonneau à l'épaule", "Jour 1 : pas encore de cicatrice à la paume."),
"BRU013": ("1woman, 38 years old, miller, wiry and nervous, sinewy arms, angular face dusted with flour, stormy grey eyes, short ash-blond hair under a scarf, rolled-up work dress, leather apron, wrench at her belt, defiant expression", "au moulin, la roue derrière elle", ""),
"BRU014": ("1man, 31 years old, village guard, tall and a bit soft, sloping shoulders, baby face, neat mustache, worried blue eyes, slicked blond hair, simple guard uniform, whistle at belt, lantern", "sur la place, en uniforme", "Jour 1 : en uniforme (il le rend au jour 9)."),
"BRU015": ("1woman, old woman, 66 years old, herbalist healer, small and gnarled, slightly stooped, face wrinkled like a winter apple, very bright pale green eyes, long white braid, brown wool shawl, basket of herbs, ginger cat at her feet, knowing smile", "dans sa cabane à la lisière, herbes séchées", ""),
"BRU016": ("1girl, child, 13 years old, fox beastkin girl, skinny and twitchy, red fox ears half hidden under a hood, big red fox tail with white tip, pointed face, amber almond eyes, messy red hair, too-short tunic, barefoot, mischievous wary expression, fully clothed, wholesome", "sur les toits ou la place, une pomme volée", "Enfant : uniquement des images d'enfant, ordinaires. Négatif renforcé. Pas de bandage au jour 1."),
"BRU017": ("1man, 35 years old, travelling glassmaker and spy, lean, clean-shaven fine face, attentive hazel eyes, light brown hair in a short ponytail, glass burn scars on hands, dusty grey travel clothes, backpack, glassmaker goggles on forehead, observant expression", "sur l'échafaudage du vitrail", ""),
"BRU018": ("1man, 45 years old, sheep farmer, stocky, red neck, rough chiselled face, broken nose, small suspicious eyes, greying brown beard, bowl haircut, muddy clogs, sheepskin vest, shepherd crook, grumpy expression", "sur la lande avec ses moutons", ""),
"BRU019": ("1woman, 39 years old, seamstress, petite and graceful, soft heart-shaped face, big melancholic brown eyes, wavy black hair pinned up, fresh flower on her bodice, lavender-blue dress she sewed herself, thimble on middle finger, gentle sad smile", "dans son atelier, tissus et fils", ""),
"BRU020": ("1man, half-elf, 40 years old, hunter, lean and wiry, slightly pointed ears hidden under hair, gaunt angular face, pale green eyes, long dirty black hair, short beard, claw scar on cheek, worn hunting leathers, longbow and quiver, guarded expression", "en lisière de forêt, au crépuscule", ""),
"BRU021": ("1man, 38 years old, thug, massive brute, thick neck, shaved scarred head, flattened nose, small grey eyes, torn left ear, yellow teeth, studded leather vest, club and knife at belt, menacing", "dans une ruelle, la nuit", ""),
"BRU022": ("1man, 24 years old, thug, small and skinny, weaselly face, shifty black eyes, greasy hair strands, sparse mustache, gap-toothed grin, patched jacket full of throwing knives, chewing a straw", "adossé à un mur, couteau en main", ""),
}
VES = ("1woman, demon woman, succubus, appears 25 years old, grey-mauve skin, curved horns, amber eyes, folded bat wings, thin tail, too thin, hollow cheeks from hunger, long dark hair, soaked travel clothes, exhausted but proud expression, shore at night, black boat",
       "sur les galets de la Bouche de mer, 21 h 30, jour 1",
       "Sa vraie forme, à son arrivée au jour 1 (libre, avant toute capture). Sous illusion humaine : remplacer par « human woman, dark eyes, long brown hair, southern look ».")

def ligne(i, nom, age, role, desc, cadre, notes, enfant):
    return dict(id=i, nom=nom, age=age, role=role, personnage=desc, notes=notes,
                negatif_enfant="nsfw, suggestive, revealing clothes, mature body" if enfant else "")

rows = []
for r in list(csv.reader(open(os.path.join(ICI, '..', '..', 'donnees', 'pnj', 'brumeval.csv'), encoding='utf-8'), delimiter=';'))[1:]:
    d, c, n = P[r[0]]
    rows.append(ligne(r[0], r[1], r[3], r[8], d, c, n, int(r[3]) < 18))
rows.append(ligne("PIE019", "Vesperine", "140 (paraît 25)", "Éclaireuse de la reine Sanae", *VES, False))

with open(os.path.join(ICI, 'brumeval.csv'), 'w', encoding='utf-8', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0]), delimiter=';')
    w.writeheader()
    w.writerows(rows)

md = ["# Personnages de Brumeval (prompts)", "",
      "> Générés par `generer.py` depuis les fiches. Seulement le personnage, état du **jour 1** : ajoute ton style et ton LoRA.",
      "> Tim (11 ans) et Nina (13 ans) sont des enfants : ajoute leur négatif.", ""]
for x in rows:
    md += [f"## {x['nom']} ({x['id']}), {x['age']} ans, {x['role'].lower()}", "", "```", x['personnage'], "```"]
    if x['negatif_enfant']:
        md += ["Négatif à ajouter : `" + x['negatif_enfant'] + "`"]
    if x['notes']:
        md += ["", x['notes']]
    md += [""]
open(os.path.join(ICI, 'brumeval.md'), 'w', encoding='utf-8').write("\n".join(md))
print(len(rows), "PNJ")
