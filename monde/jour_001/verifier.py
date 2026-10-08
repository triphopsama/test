#!/usr/bin/env python3
"""Vérifie les journées du jour 1 : python3 verifier.py [lieu ...]  (sans argument : tous les lieux écrits).

Format de monde/jour_001/<lieu>.csv (séparateur ';', UTF-8, aucun ';' dans les cellules) :
pnj;debut;fin;lieu;avec;action;consequence
- pnj : id du PNJ (ex. SAL001). Toutes les lignes d'un même PNJ se suivent, dans l'ordre des heures.
- debut, fin : HH:MM. La journée de chacun couvre 00:00 -> 24:00 sans trou ni chevauchement.
- lieu : où il est (un lieu de sa ville, ou « en route vers X »).
- avec : ids des PNJ présents et en interaction, séparés par ','. Sinon '—'.
- action : ce qu'il fait, en une ou deux phrases.
- consequence : humeur, souvenir, relation, objet, argent... ou '—'.
Règle de réciprocité : si A cite B dans 'avec', B a une ligne au même lieu, qui chevauche
l'heure, et qui cite A.
"""
import csv, glob, os, re, sys
ICI = os.path.dirname(os.path.abspath(__file__))
PNJ = os.path.join(ICI, '..', 'donnees', 'pnj')

def minutes(h):
    m = re.fullmatch(r'(\d{1,2}):(\d{2})', h.strip())
    if not m:
        raise ValueError(h)
    return int(m.group(1)) * 60 + int(m.group(2))

def fiches():
    f = {}
    for p in glob.glob(os.path.join(PNJ, '*.csv')):
        if p.endswith('toutes_pnj.csv'):
            continue
        lieu = os.path.basename(p)[:-4]
        for r in list(csv.reader(open(p, encoding='utf-8'), delimiter=';'))[1:]:
            f[r[0]] = (lieu, r[1])
    return f

def main():
    F = fiches()
    lieux = sys.argv[1:] or sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(ICI, '*.csv')))
    toutes = {}
    erreurs = []
    for lieu in lieux:
        p = os.path.join(ICI, lieu + '.csv')
        if not os.path.exists(p):
            erreurs.append(f'{lieu} : fichier absent')
            continue
        R = list(csv.reader(open(p, encoding='utf-8'), delimiter=';'))
        if R[0] != ['pnj', 'debut', 'fin', 'lieu', 'avec', 'action', 'consequence']:
            erreurs.append(f'{lieu} : en-tête incorrect')
        for n, r in enumerate(R[1:], 2):
            if len(r) != 7:
                erreurs.append(f'{lieu}:{n} : {len(r)} colonnes')
                continue
            try:
                d, fn = minutes(r[1]), minutes(r[2])
            except ValueError as e:
                erreurs.append(f'{lieu}:{n} : heure illisible {e}')
                continue
            if r[0] not in F:
                erreurs.append(f'{lieu}:{n} : pnj inconnu {r[0]}')
                continue
            if not r[5].strip():
                erreurs.append(f'{lieu}:{n} : action vide')
            avec = [x.strip() for x in r[4].split(',') if x.strip() and x.strip() != '—']
            for x in avec:
                if x not in F:
                    erreurs.append(f'{lieu}:{n} : {r[0]} cite un id inconnu {x}')
            toutes.setdefault(r[0], []).append((d, fn, r[3].strip(), avec, lieu, n))
        attendus = [i for i, (l, _) in F.items() if l == lieu]
        for i in attendus:
            if i not in toutes:
                erreurs.append(f'{lieu} : {i} ({F[i][1]}) n\'a pas de journée')
    for i, L in toutes.items():
        L.sort()
        t = 0
        for d, fn, *_ in L:
            if d != t:
                erreurs.append(f'{i} : {"trou" if d > t else "chevauchement"} à {t // 60:02d}:{t % 60:02d}')
            if fn <= d:
                erreurs.append(f'{i} : intervalle vide ou inversé à {d // 60:02d}:{d % 60:02d}')
            t = fn
        if t != 24 * 60:
            erreurs.append(f'{i} : la journée finit à {t // 60:02d}:{t % 60:02d}, pas à 24:00')
    for i, L in toutes.items():
        for d, fn, lieu_, avec, f, n in L:
            for x in avec:
                if x not in toutes:
                    continue   # PNJ d'un lieu pas encore écrit
                ok = any(dd < fn and d < ff and lx == lieu_ and i in ax for dd, ff, lx, ax, *_ in toutes[x])
                if not ok:
                    erreurs.append(f'{f}:{n} : {i} est avec {x} ({lieu_}, {d // 60:02d}:{d % 60:02d}) mais {x} ne le dit pas')
    print(f'{len(toutes)} journées lues, {len(erreurs)} erreur(s)')
    for e in erreurs[:200]:
        print('  ' + e)
    sys.exit(1 if erreurs else 0)

main()
