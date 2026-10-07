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
  - **Les loups** : près de leur tanière, dans le bois, une meute surgit une fois par jour.
  - **Les PNJ qui te détestent** (affection −40 ou moins) peuvent venir t'agresser d'eux-mêmes, plus ou moins selon leur colère, leur courage et leur prudence. À −70, c'est pour te tuer. Si tu t'es fait un ennemi de Silas, il envoie Garec et Mouche la nuit.
  - Perdre n'est pas la fin : tu te réveilles trois heures plus tard chez Agnès. Les morts restent morts (sauvés dans `user://etat.cfg`).

## Écrire les actions

Tout est dans `data/actions.csv` (s'ouvre avec un tableur ou un éditeur de texte, séparateur `;`). Une ligne par action ; une ligne avec un id de PNJ précis remplace la ligne générale pour ce PNJ. Les colonnes sont expliquées en haut de `scripts/actions.gd`.

Les actions intimes (`intime` = 1) ont la description vide : c'est à toi de l'écrire. Le code garde les règles du jeu, quoi qu'il y ait dans le fichier :
- jamais avec un PNJ de moins de 18 ans ou sans profil intime ;
- jamais avec une personne captive, esclave ou sous contrat de dette ;
- jamais si un enfant est à moins de 20 m ;
- le PNJ refuse si son affection est trop basse ;
- Échap arrête la scène.

## Ce qui n'est pas encore là

- La création de personnage, l'expérience, l'inventaire, les armes et l'argent (tu te bats à mains nues pour l'instant).
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
| `images/plan.png` | Le plan, généré par `outils/image.py` |

## Vérifier que tout marche

`godot --headless -- --autotest` lance un test : données, trajets, PNJ, les garde-fous des actions intimes, et trois combats joués tout seuls (bagarre, loups, agression).

`godot -- --capture=image.png --heure=20 --combat=loups` (ou `--combat=bagarre`) enregistre une image d'un combat.
