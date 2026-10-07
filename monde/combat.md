# Le combat et les dégâts

> Combat tactique au tour par tour sur grille isométrique, façon *Final Fantasy Tactics Advance*, avec des chiffres de LitRPG. Les règles générales sont dans la section 8 de [univers.md](univers.md). Les compétences et leurs multiplicateurs sont dans les [données](donnees/README.md). **Les PNJ suivent exactement les mêmes règles.**

## 1. Quand un combat commence

- **Sur la carte même :** la grille apparaît sur le décor, sans écran de transition. On se bat là où on est : la taverne, la crique, la forge.
- **Ce qui le déclenche :** une agression, une embuscade, un duel déclaré, une arrestation, un monstre, une négociation qui tourne mal.
- **Surprise :** le camp qui attaque sans être vu agit en premier, et ses premiers coups comptent comme des coups dans le dos.
- **Qui participe :** tous ceux qui sont dans la zone peuvent entrer dans le combat, selon leur caractère : un garde intervient, un ami aide, un lâche fuit, un témoin court prévenir. Jusqu'à **6 alliés** contrôlés ; les autres agissent seuls.
- **Le placement :** chaque camp place ses combattants dans sa zone de départ avant le premier tour (sauf en cas de surprise).

## 2. Les valeurs dérivées des caractéristiques

| Valeur | Formule | Exemple : villageois (stats 6) | Exemple : Bram (For 22, Vit 16) |
| --- | --- | --- | --- |
| **Points de vie (PV)** | 20 + Vit × 8 + niveau de race × 4 | 70 | 20 + 128 + 40 = 188 |
| **Mana** | Sag × 6 + Int × 2 | 48 | — |
| **Endurance** | 20 + End × 5 | 50 | — |
| **Vitesse** | 10 + Agi | 16 | — |
| **Déplacement** | 3 + Agi ÷ 10 (arrondi en dessous) | 3 cases | — |
| **Saut** (hauteur franchissable) | 1 + Agi ÷ 15 | 1 niveau | — |
| **Défense physique** | Armure (objets) + Rob | 6 + armure | — |
| **Défense magique** | Résistance (objets) + Vol × 2 | 12 + objets | — |

### L'échelle des caractéristiques
| Qui | Caractéristiques typiques |
| --- | --- |
| Enfant | 2 à 5 |
| Villageois, artisan | 5 à 10 (une ou deux plus hautes selon le métier : Bram a For 22) |
| Garde, chasseur, soldat | 10 à 20 |
| Vétéran, mage diplômé (niveau 25 et plus) | 20 à 40 |
| Héros, maître (niveau 50 et plus) | 40 à 80 |
| Légende, reine démone (niveau 75 et plus) | 80 à 150 et plus |

À chaque niveau de **classe** : +2 points fixés par la classe et +2 libres. À chaque niveau de **métier** : +1 fixé par le métier et +1 libre. À chaque niveau de **race** : +1 dans toutes les caractéristiques. Les objets et titres ajoutent par-dessus.

## 3. L'ordre des tours

- Chaque combattant a une **jauge d'action** qui se remplit de sa **Vitesse** à chaque tic. À 100, il joue.
- **Ce que coûte un tour :**
  - se déplacer **et** agir : la jauge repart à 0 ;
  - seulement agir ou seulement se déplacer : elle repart à 20 ;
  - attendre : elle repart à 40, et on récupère 10 d'endurance de plus.
- Les compétences lourdes ont parfois un **temps d'incantation** : le sort part au tic indiqué, et peut être interrompu si le lanceur est touché (jet de Volonté).
- Une **barre d'ordre des tours** montre qui va jouer, comme dans *FFTA*.
- **À la fin de son tour**, on choisit son **orientation** : elle décide d'où viennent les coups de flanc et de dos.

## 4. Toucher

**Chance de toucher (attaque physique)** = 85 % + (Per de l'attaquant − Agi du défenseur) × 2, entre 5 % et 99 %.

| Modificateur | Effet |
| --- | --- |
| Attaque de flanc | +15 % |
| Attaque dans le dos | +30 %, et le défenseur ne peut ni parer ni bloquer |
| Plus haut que la cible | +5 % par niveau de hauteur (max +20 %) |
| Plus bas | −5 % par niveau |
| Cible derrière un couvert (mur bas, caisse, arbre) | −25 % pour les tirs |
| Au-delà de la portée efficace | −10 % par case |
| Aveuglé, ivre, épuisé | −20 % à −40 % |
| Cible à terre, endormie, paralysée | Touche automatiquement |

**Les sorts touchent automatiquement**, sauf ceux marqués « résistible » (contrôle, peur, charme, malédiction) : la cible fait un **jet de Volonté**. Chance de résister = 30 % + (Vol de la cible − Int du lanceur) × 3, entre 5 % et 95 %.

### Esquiver, parer, bloquer
- L'**esquive** est déjà dans la chance de toucher (l'Agi du défenseur).
- **Bloquer au bouclier** (attaques de face seulement) : chance = valeur du bouclier + Rob ÷ 2 %. Un blocage réduit les dégâts de 60 %.
- **Parer** demande une compétence de parade : elle annule le coup et peut ouvrir une riposte.

## 5. Les dégâts

### Dégâts physiques
```
Dégâts bruts  = Dégâts de l'arme + Multiplicateur de la compétence × Caractéristique
Dégâts finaux = Dégâts bruts × 100 ÷ (100 + Défense physique de la cible) × modificateurs
```
- L'attaque de base sans compétence a un multiplicateur de 1,0.
- La caractéristique est indiquée dans chaque compétence (« 1,5 x For », « 1,2 x Agi »). Les armes lourdes utilisent la For, les dagues et arcs l'Agi, les arbalètes la Per.
- Une compétence qui « ignore X % de l'armure » réduit d'autant la Défense de la cible.

### Dégâts magiques
```
Dégâts bruts  = Multiplicateur du sort × Int × Bonus d'affinité du lanceur
Dégâts finaux = Dégâts bruts × 100 ÷ (100 + Défense magique de la cible) × Facteur élémentaire × modificateurs
```
- **Bonus d'affinité du lanceur** (voir [competences.md](competences.md)) : +1 % par point d'affinité au-dessus de 50, −1 % par point en dessous de 20.
- **Facteur élémentaire de la cible :**
  - elle résiste à un élément selon son affinité : −0,5 % de dégâts par point d'affinité dans cet élément (affinité 60 = −30 %) ;
  - elle est faible à l'opposé de ses éléments forts : affinité 60 et plus dans un élément donne +25 % de dégâts subis de l'élément opposé ;
  - les monstres ont leurs propres résistances et faiblesses ([bestiaire](bestiaire.md)) : ×0 (immunisé), ×0,5, ×1, ×1,5, ×2.

### Soins
```
Soin = Multiplicateur × Sag × Bonus d'affinité (lumière, eau ou nature selon le sort)
```
Un mort-vivant soigné à la lumière subit les dégâts au lieu d'être soigné.

### Les modificateurs (ils se multiplient entre eux)

| Situation | Effet sur les dégâts |
| --- | --- |
| **Critique** | ×1,5 (certaines compétences et armes plus) |
| Coup de flanc | ×1,15 |
| Coup dans le dos | ×1,3 |
| Hauteur | ×1,05 par niveau au-dessus (max ×1,25), ×0,95 par niveau en dessous |
| Synergie de terrain ou d'état | ×1,5 (foudre sur une cible mouillée, feu sur une cible huilée ou dans les toiles) |
| Moral haut (75 et plus) | ×1,05 |
| Moral bas (moins de 25) | ×0,9 |
| Blessure au bras qui frappe | ×0,7 |
| Arme pas maîtrisée (aucune compétence de cette arme) | ×0,8 |
| Combo entre compagnons | ×1,2 à ×2 selon la compétence |
| Variation aléatoire | ×0,9 à ×1,1 |

**Chance de critique** = 5 % + Per ÷ 10 %, +10 % dans le dos. Les dagues et certaines compétences l'augmentent.

### Exemple
Bram (For 22, marteau de forge 12 dégâts) utilise *Frappe lourde* (1,5 × For) sur un homme de main de Silas (Rob 10, gilet de cuir 8, donc Défense 18), de flanc :
- Bruts : 12 + 1,5 × 22 = 45.
- Après défense : 45 × 100 ÷ 118 = 38.
- De flanc : 38 × 1,15 = **44 dégâts**, sur environ 110 PV. Trois coups bien placés et il est à terre.

Le même coup sur une cible en armure de plates (Défense 60) ne ferait que 28 de face. Il faut une compétence qui ignore l'armure, la frapper de dos, ou utiliser la magie.

## 6. Les états

| État | Effet | Dure | Résisté par |
| --- | --- | --- | --- |
| **Brûlure** | 5 % des PV max par tour ; le feu se propage aux cases d'herbe sèche | 3 tours, ou jusqu'à ce qu'on l'éteigne (eau, se rouler par terre) | Vit |
| **Saignement** | 3 % des PV max par tour, empire en se déplaçant | Jusqu'à un bandage ou un soin | Vit |
| **Poison** | 4 % des PV max par tour, empêche de récupérer de l'endurance | 5 tours | Vit |
| **Gel** | Déplacement −2, vitesse −30 % ; gelé deux fois : bloqué 1 tour | 3 tours | Rob |
| **Mouillé** | Foudre ×1,5, feu ×0,5, éteint la brûlure | Jusqu'à séchage (3 tours, ou feu) | — |
| **Huilé** | Feu ×1,5 | Jusqu'à lavage | — |
| **Étourdi** | Perd son prochain tour | 1 tour | Rob |
| **Renversé** | À terre : touché automatiquement, se relever coûte le déplacement | Jusqu'à se relever | For |
| **Ralenti** | Vitesse −50 % | 3 tours | Agi |
| **Enraciné** | Ne peut pas se déplacer | 2 tours | For |
| **Aveuglé** | Toucher −40 %, ne voit pas plus loin que 2 cases | 2 tours | Per |
| **Silence** | Pas de sorts parlés ni de chant | 3 tours | Vol |
| **Peur** | Fuit le lanceur, ne peut pas l'attaquer | 2 tours | Vol |
| **Charmé** | Ne peut pas attaquer le lanceur ; peut changer de camp pour 1 tour si très charmé | 2 tours | Vol |
| **Endormi** | Ne fait rien, se réveille au premier coup | 3 tours | Vol |
| **Paralysé** | Ne fait rien, touché automatiquement | 2 tours | Vit |
| **Marqué** | Les compétences de traque font plus de dégâts | 5 tours | — |
| **Rage** | Dégâts ×1,3, ne peut que frapper l'ennemi le plus proche | 3 tours | Vol |
| **Inspiré** | Toucher +10 %, moral +10 | 3 tours | — |

Un même état ne se cumule pas, il se renouvelle. Chaque résistance réussie rend la cible plus résistante à cet état pour le reste du combat.

## 7. Le terrain

| Terrain | Effet |
| --- | --- |
| Herbe sèche, paille, toiles | Brûle et propage le feu |
| Eau peu profonde | Déplacement −1, rend mouillé, la foudre touche toutes les cases d'eau reliées |
| Eau profonde | Il faut nager (Endurance) ; armure lourde : on coule |
| Boue, neige | Déplacement −1, pas de course |
| Glace | Glissade d'une case dans le sens du mouvement |
| Hauteur (toits, rochers, escaliers) | Portée de tir +1 par 2 niveaux, bonus de hauteur |
| Couvert (mur bas, caisse) | −25 % aux tirs qui viennent de l'autre côté |
| Obscurité | Toucher −20 % sans vision de nuit ; discrétion plus facile |
| Lieux sacrés | Sorts de lumière ×1,2, d'ombre et de mort ×0,8 |
| Lieux maudits, cimetières | L'inverse |

Les sorts **changent le terrain** : *Mur de pierre* crée un couvert, *Sol gelé* crée de la glace, *Mer de feu* brûle tout. Une maison qui brûle reste brûlée après le combat.

## 8. Ressources pendant le combat

- **Endurance :** +End ÷ 2 par tour, +10 en attendant. À 0, on est **épuisé** (toucher −20 %, plus de techniques).
- **Mana :** +Sag ÷ 4 par tour. Une potion ou *Méditation* en rend plus.
- **PV :** ne remontent pas seuls en combat.

## 9. Quand on tombe

- **À 0 PV, on est à terre, pas mort.** On saigne : il reste **3 tours** pour être stabilisé (bandage, soin, potion). Sinon, on meurt.
- **Achever** un combattant à terre est une **action volontaire**. Elle a ses conséquences : témoins, loi, vengeance.
- **Blessure grave :** un coup critique qui fait tomber à 0 a 1 chance sur 4 de laisser une blessure durable (bras, jambe, œil). Elle bloque des compétences jusqu'à la guérison, ou pour toujours. C'est ce qui est arrivé aux mains de Bram.
- **Les monstres** ne font pas de prisonniers, sauf les intelligents (★), qui peuvent capturer ou négocier.

## 10. Parler, fuir, se rendre

- **Parler en plein combat** est une action : intimider, proposer une trêve, demander la reddition, insulter pour provoquer. On utilise les compétences sociales, avec un malus si l'autre camp gagne.
- **Reddition :** un PNJ sous 25 % de PV dont le moral est bas peut se rendre ou supplier. Le joueur aussi peut se rendre.
- **Fuir :** atteindre le bord de la grille. Les ennemis plus rapides peuvent poursuivre.
- **Moral pendant le combat :** voir un allié tomber fait baisser le moral, abattre le chef ennemi peut faire fuir toute une bande.
- **Compagnons :** ils gardent leur caractère (section 8 de [univers.md](univers.md)) : ils peuvent désobéir, fuir, protéger quelqu'un qu'ils aiment.

## 11. Après le combat

- **Vainqueur :** épargner, laisser partir, soigner, dépouiller, capturer, interroger, achever.
- **Vaincu :** rarement la mort. Capture, pillage, dette, esclavage, abandon dans la forêt. Une nouvelle histoire commence.
- **Expérience :**
  - la **classe** gagne de l'expérience selon la difficulté : vaincre plus fort que soi rapporte beaucoup, écraser plus faible presque rien ;
  - chaque compétence utilisée gagne de la **maîtrise** ;
  - les exploits débloquent des **titres** et des compétences cachées ;
  - épargner, capturer ou tuer : les trois rapportent de l'expérience, et vaincre sans tuer débloque ses propres titres.
- **Les lois et les témoins** jugent ce qui s'est passé : tuer en ville dans la République, c'est la prison ou la potence ; un duel déclaré devant témoins, c'est légal.

## 12. Côté Godot (données)

- **Combattant :** caractéristiques, PV, mana, endurance, jauge d'action, case, hauteur, orientation, états, compétences équipées, affinités, objets.
- **Calcul d'un coup :** toucher → bloquer/parer → dégâts bruts → défense → facteur élémentaire → modificateurs → critique → variation → états → réactions.
- **Journal du combat :** chaque coup est écrit en clair, comme une fenêtre de système : « Bram utilise Frappe lourde sur Garec : touché de flanc, 44 dégâts. »
