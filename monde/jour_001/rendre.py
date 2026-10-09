#!/usr/bin/env python3
"""Met en page les journées : python3 rendre.py [lieu ...] -> <lieu>.md (une section par PNJ)."""
import csv, glob, os, sys
ICI = os.path.dirname(os.path.abspath(__file__))
PNJ = os.path.join(ICI, '..', 'donnees', 'pnj')

noms = {}
for p in glob.glob(os.path.join(PNJ, '*.csv')):
    if not p.endswith('toutes_pnj.csv'):
        for r in list(csv.reader(open(p, encoding='utf-8'), delimiter=';'))[1:]:
            noms[r[0]] = (r[1], r[8])

lieux = sys.argv[1:] or sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(ICI, '*.csv')))
for lieu in lieux:
    R = list(csv.reader(open(os.path.join(ICI, lieu + '.csv'), encoding='utf-8'), delimiter=';'))[1:]
    ordre, par = [], {}
    for r in R:
        if r[0] not in par:
            ordre.append(r[0])
            par[r[0]] = []
        par[r[0]].append(r)
    titre = lieu.replace('_', ' ').title()
    out = [f'# {titre}, jour 1 : chacun sa journée', '',
           f'> Généré par `rendre.py` depuis [{lieu}.csv]({lieu}.csv). {len(ordre)} journées, de 00:00 à 24:00. '
           'Les rencontres sont notées des deux côtés (`verifier.py`).', '']
    for i in sorted(ordre):
        nom, role = noms.get(i, (i, ''))
        out += [f'## {nom} ({i})', '', f'*{role}*', '', '| Heure | Où | Avec | Ce qu\'il ou elle fait | Ce que ça change |', '| --- | --- | --- | --- | --- |']
        for r in par[i]:
            avec = ', '.join(noms.get(x.strip(), (x.strip(),))[0] for x in r[4].split(',') if x.strip() and x.strip() != '—') or '—'
            out.append(f'| {r[1]}–{r[2]} | {r[3]} | {avec} | {r[5]} | {r[6]} |')
        out.append('')
    open(os.path.join(ICI, lieu + '.md'), 'w', encoding='utf-8').write('\n'.join(out))
    print(lieu, len(ordre))
