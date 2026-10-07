# Brumeval : prototype

Le village de départ en 3D façon HD-2D, en temps réel. Fait avec Godot 4.3 (marche aussi avec les versions suivantes).

## L'ouvrir

1. Installe Godot 4.3 ou plus récent (godotengine.org, version standard, pas .NET).
2. Lance Godot, clique **Importer**, choisis le fichier `project.godot` de ce dossier.
3. Appuie sur **F5** pour jouer.

## Les touches

| Touche | Effet |
| --- | --- |
| ZQSD ou flèches | Marcher (1,5 m/s) |
| Maj | Courir (4 m/s) |
| Ctrl | Voyage rapide ×8 (pour tester) |
| E | Agir : parler à quelqu'un, ou agir sur place |
| I | Le sac : porter, retirer, manger |
| C | Le personnage : caractéristiques, niveau, points à répartir, classe, métier, compétences |
| 1 à 9 | Choisir une action dans le menu |
| Échap | Fermer le menu, arrêter une scène |
| Tab | Plan du village, avec ta position |
| T | Accélérer le temps : ×1, ×60, ×600 |
| Molette | Zoom |

En combat : 1 à 9 choisit l'action (se déplacer, attaquer, compétence, bander un blessé, se rendre, attendre), un clic choisit la case en surbrillance, Échap revient au menu.

## Ce qui marche

- **Le village tiré du plan** : les 28 lieux, les chemins, le ruisseau, la mer, les falaises, le bois de Ronceval. 1 case = 1 m.
- **L'horloge réelle** : il est la même heure dans le jeu que chez toi. Le jour 1 est le jour du premier lancement. Le soleil, la nuit, la brume du matin et les marées suivent l'heure.
- **Les 19 habitants** de Brumeval suivent leur emploi du temps, marchent par les chemins, flânent, et rentrent chez eux pour dormir. Les rochers de la crique ne sont praticables qu'à marée basse.
- **Les actions** : parler, saluer, offrir à manger, insulter, demander du travail, dormir à la taverne, se laver, pêcher, prier, travailler, fouiller la maison de la falaise, descendre au puits, cueillir, regarder la mer. Chaque action fait passer le temps et change l'affection du PNJ.
- **Une image ou une animation à chaque action** : voir `illustrations/LISEZMOI.md`. Sans fichier, écran noir et description.
- **Le combat** (règles de `monde/combat.md`) : une grille de 15 × 15 cases posée sur le décor, 1 case = 1 m, les hauteurs comptent. Tour par tour selon la vitesse, bonus de flanc et de dos, bouclier de face, coups critiques, états (renversé, étourdi, saignement). À 0 PV on tombe à terre : 3 tours pour être bandé, sinon la mort. Les PNJ se rendent ou fuient quand ça tourne mal.
  - **Bagarre** (« Provoquer en bagarre ») : à mains nues, personne ne meurt.
  - **Attaquer pour de vrai** : un combat à mort. La cible et les témoins t'en veulent, et Corentin s'en mêle s'il est là, de jour. Jamais contre un enfant.
  - **Les loups** : près de leur tanière, dans le bois, une meute surgit une fois par jour. Au niveau 1, c'est la mort assurée : évite-la.
  - **Des bêtes à ta taille** (monde/bestiaire.md) : un loup isolé (il fuit quand ça tourne mal) ou un sanglier des ronces dans le bois et les landes, un crabe-rocher sur la grève à marée basse (frappe-le de flanc ou de dos : son ventre est mou). Elles laissent peaux, crocs, carapaces, viande, défenses.
  - **La cave de Rosalie** : « Chasser les rats de la cave » à la taverne, une fois par jour, 1 argent si tu gagnes.
  - **Équilibre mesuré** (`godot --headless -- --equilibre`, 10 combats par bête, personnage « Équilibré » de niveau 1) : à mains nues, on bat 7 fois sur 10 deux rats, 8 sur 10 un loup isolé, toujours le crabe, 2 fois sur 10 le sanglier ; avec une dague (3 argent chez Bram), tout sauf la meute.
  - **Les PNJ qui te détestent** (affection −40 ou moins) peuvent venir t'agresser d'eux-mêmes, plus ou moins selon leur colère, leur courage et leur prudence. À −70, c'est pour te tuer. Si tu t'es fait un ennemi de Silas, il envoie Garec et Mouche la nuit.
  - Après un combat : de l'expérience (beaucoup contre plus fort que toi, presque rien contre plus faible, la moitié en bagarre, un quart si tu perds), le butin (peaux et crocs de loup, l'arme et la bourse de ceux que tu as mis à terre ; ils t'en voudront) et la tournée de la bagarre. Si tu perds un vrai combat, on te prend la moitié de ta bourse.
  - Perdre n'est pas la fin : tu te réveilles trois heures plus tard chez Agnès. Les morts restent morts (sauvés dans `user://etat.cfg`).

## La création de personnage

Au premier lancement (ou avec `godot -- --nouveau`), un écran en 9 étapes, d'après `monde/creation_personnage.md` : peuple et lignée (6 peuples, clans, 14 animaux, lignées démones), identité (sexe, pronoms, âge apparent, astre de naissance), caractéristiques (5 partout, 20 points, préréglages), caractère (archétypes), valeurs et passions, vie d'avant, avantages et défauts, tenue et objet de l'autre monde au réveil, nom et options. Chaque étape a son « au hasard », et « Tout au hasard » fait un personnage en un clic.

Ce qui compte déjà en jeu : les caractéristiques, les PV, la vitesse ; l'accueil des PNJ (Rosalie et les nains, Pierrick et les elfes ou demi-sangs, Nina et les renards, Beauté frappante, Ami des enfants, Air louche, Ennemi) ; une vingtaine d'avantages, de défauts et de vies d'avant (Robuste, Rapide, Increvable, Chanceux, Œil de tireur, Ami des bêtes, Apprend vite, Commerçant, Cuisinier, Ouvrier, Soldat, Joueur de jeux vidéo…) ; le contenu adulte désactivable. Le reste (corps, profil intime, affinités, phobies…) est gardé dans la fiche, marqué « plus tard ». Une nouvelle création remet le village à zéro (affections, morts).

Les choix sont dans `scripts/creation_donnees.gd`, modifiables.

## Les objets, l'argent, l'expérience

- **Au réveil**, tu n'as que ta tenue (vêtements d'ailleurs, simples, haillons, ou rien), l'anneau qui ne s'enlève pas et peut-être un objet de l'autre monde (une montre se vend 1 or 10 argent chez Silas). Pas un sou. La **Lame sans nom** se cache peut-être dans les fourrés de la clairière (« Fouiller les fourrés », une chance sur trois par jour).
- **Gagner sa vie** : travailler une heure (6 cuivre), pêcher (des maquereaux), cueillir (sauge et consoude pour Agnès), revendre les peaux de loup.
- **Les marchands** (« Acheter » et « Vendre » en parlant avec eux) : Bram (armes, mailles, boucliers), Isaure (cuir, chemises), Silas (dagues, cordes, lanterne), Mara (pain), Agnès (onguent, tisane), Rosalie (soupe), Joss (hareng, trident, vareuse), Pierrick (arc, collier de crocs), Ysolde (amulette), Basile (chapeau de paille). Ils rachètent tout à moitié prix ; un ami (affection 50) fait 10 % de remise. 1 or = 20 argent, 1 argent = 12 cuivre.
- **L'équipement** compte en combat : dégâts et portée de l'arme, défense de l'armure, blocage du bouclier, bonus de caractéristiques. Chaque objet demande des caractéristiques minimales (la cotte de mailles : End 8). Un arc ou un trident se tient à deux mains.
- **Les PV** restent d'un combat à l'autre. Ils remontent de 10 % par heure, d'un coup en dormant à la taverne, ou en mangeant (aussi en plein combat : « Manger ou se soigner »).
- **Les niveaux** : 50 × niveau d'expérience pour passer au suivant, 4 points à répartir à chaque niveau (touche C). Les compétences viennent avec les caractéristiques : Frappe lourde à For 10, Coup sournois à Agi 10 avec une dague, Tir précis à Per 10 avec un arc.
- Tout est dans `data/objets.csv`, modifiable au tableur (colonnes expliquées en haut de `scripts/objets.gd`). La fiche du joueur est sauvée dans `user://joueur.cfg` : supprime-la pour recommencer à zéro.

## Classes et métiers

D'après `monde/classes_metiers.md`. Un personnage a **une classe et un métier** à la fois ; les PNJ suivent les mêmes règles.

- **La classe s'éveille au combat.** Après ton premier vrai combat (pas une bagarre), le jeu te propose 3 classes selon ce que tu y as fait : frapper à l'épée → Guerrier, aux poings et en saisissant → Lutteur, à la dague et dans le dos → Voleur, à l'arc → Archer, encaisser derrière un bouclier → Garde, chasser les bêtes → Chasseur de monstres, fuir et esquiver → Éclaireur… Tu peux refuser et attendre une meilleure offre : elle revient après le combat suivant, et tout ce que tu fais s'additionne.
- **13 classes** sans magie : Guerrier, Lutteur, Garde, Lancier, Duelliste, Moine, Mercenaire, Archer, Lanceur, Voleur, Éclaireur, Chasseur de monstres, Rôdeur. Les classes de magie et de foi viendront avec la magie.
- **Le niveau de classe** monte avec la même expérience que le personnage. Chaque classe apprend 3 compétences : deux au niveau 1, la troisième au niveau 3 (au niveau 5 pour Tir dans l'œil et Pluie de lames) ; une compétence ne sert que si tu as les caractéristiques (et l'arme) qu'il faut, et tu la gardes si tu changes de classe. À chaque niveau du personnage, 2 points vont d'office aux caractéristiques favorites de ta classe (★ sur la fiche), 2 restent libres.
- **Les compétences en combat** (chiffres repris de `monde/donnees/competences`) : Parade, Cri de guerre, Coup de tête, Projection, Lever le bouclier, Provocation, Allonge, Mur de piques, Pas de côté, Feinte, Riposte, Poings de fer, Souffle intérieur, Esquive parfaite, Toutes armes, Pillage, Dernier debout, Volée, Tir dans l'œil, Couteaux de lancer, Javelot, Pluie de lames, Camouflage, Course longue, Point faible, Trophée, Soin des bois. Les passives jouent toutes seules ; les autres sont dans le menu de combat.
- **Hors combat** : le Voleur peut « Voler à la tire » (sur un adulte, une fois par jour et par personne). La réussite dépend de ton Agi et du nombre de gens qui regardent. Pris, la victime t'en veut (−30) et chaque témoin aussi (−15). Crochetage, Pistage et Piège attendent les intérieurs et l'exploration.
- **Le métier s'apprend en travaillant.** « Travailler une heure » à la forge, au fournil, au moulin, à l'atelier, « Pêcher » au port ou « Cueillir » : une journée (8 h) et te voilà apprenti forgeron, boulanger, meunier, couturier, pêcheur ou herboriste. Si le maître est là (Bram, Mara, Élise, Isaure, Joss, Agnès), tu apprends deux fois plus vite. Une journée dans un autre métier te propose d'en changer (le niveau repart de 1). Apprenti, puis compagnon au niveau 10, maître au niveau 25.
- **Ce que le métier rapporte** : forgeron, les armes et armures de métal se revendent 20 % plus cher ; couturier, le cuir, le tissu et les peaux ; boulanger, un pain toutes les deux heures au fournil ; meunier, 2 cuivre de plus par heure ; pêcheur, un poisson de plus ; herboriste, une plante de plus et des remèdes 20 % plus efficaces. Et 1 cuivre de plus par heure tous les 5 niveaux de métier.
- Tout est dans `data/classes.csv` et `data/metiers.csv`, modifiables au tableur (colonnes expliquées en haut de `scripts/classes.gd`) ; les compétences sont dans `scripts/combattant.gd`.

## Écrire les actions

Tout est dans `data/actions.csv` (s'ouvre avec un tableur ou un éditeur de texte, séparateur `;`). Une ligne par action ; une ligne avec un id de PNJ précis remplace la ligne générale pour ce PNJ. Les colonnes sont expliquées en haut de `scripts/actions.gd`. Les colonnes `prix` (« 1 argent », ou un objet : « OBJ327 1 ») et `donne` (« cuivre 6 », « BRV003 2 », « repos ») font payer et rapporter une action.

Les actions intimes (`intime` = 1) ont la description vide : c'est à toi de l'écrire. Le code garde les règles du jeu, quoi qu'il y ait dans le fichier :
- jamais avec un PNJ de moins de 18 ans ou sans profil intime ;
- jamais avec une personne captive, esclave ou sous contrat de dette ;
- jamais si un enfant est à moins de 20 m ;
- le PNJ refuse si son affection est trop basse ;
- Échap arrête la scène.

## Ce qui n'est pas encore là

- Le corps et le profil intime à la création, la magie (et les classes de magie et de foi), les évolutions de classe aux niveaux 25, 50 et 75, les PNJ qui enseignent une compétence, la maîtrise des armes et les titres.
- Les intérieurs des maisons (on agit devant la porte).
- La grotte, Pierrefane et le reste du monde.
- Les emplois du temps sont ceux de la routine actuelle du village (après le jour 11), pas encore la chronique jour par jour.
- Les sprites sont les essais en 16 × 24 ; les bâtiments sont des volumes simples.

## Les données

| Fichier | D'où il vient |
| --- | --- |
| `data/lieux.csv`, `chemins.csv`, `zones.csv` | Le plan de Brumeval (`monde/cartes/brumeval.md`), généré par `outils/build.py` |
| `data/pnj.csv` | Les fiches des PNJ (`monde/donnees/pnj/brumeval.csv`) |
| `data/emplois.csv` | La colonne emploi du temps des PNJ, transformée par `outils/emplois.py` (heure → lieu) |
| `data/actions.csv` | Écrit à la main, à compléter |
| `data/classes.csv`, `metiers.csv` | `monde/classes_metiers.md`, compétences reprises de `monde/donnees/competences` |
| `images/plan.png` | Le plan, généré par `outils/image.py` |

## Vérifier que tout marche

`godot --headless -- --autotest` lance un test : données, trajets, PNJ, les garde-fous des actions intimes, les objets, le sac, les marchands et l'expérience, les classes et les métiers, et trois combats joués tout seuls (bagarre, loups, agression).

`godot -- --capture=image.png --heure=20 --combat=loups` (ou `--combat=bagarre`) enregistre une image d'un combat ; `--fenetre=sac`, `perso`, `classe` ou `bram` une image des fenêtres ; `--creation=3` l'écran de création à l'étape 3.
