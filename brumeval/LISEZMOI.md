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

## Ce qui marche

- **Le village tiré du plan** : les 28 lieux, les chemins, le ruisseau, la mer, les falaises, le bois de Ronceval. 1 case = 1 m.
- **L'horloge réelle** : il est la même heure dans le jeu que chez toi. Le jour 1 est le jour du premier lancement. Le soleil, la nuit, la brume du matin et les marées suivent l'heure.
- **Les 19 habitants** de Brumeval suivent leur emploi du temps, marchent par les chemins, flânent, et rentrent chez eux pour dormir. Les rochers de la crique ne sont praticables qu'à marée basse.
- **Les actions** : parler, saluer, offrir à manger, insulter, demander du travail, dormir à la taverne, se laver, pêcher, prier, travailler, fouiller la maison de la falaise, descendre au puits, cueillir, regarder la mer. Chaque action fait passer le temps et change l'affection du PNJ.
- **Une image ou une animation à chaque action** : voir `illustrations/LISEZMOI.md`. Sans fichier, écran noir et description.

## Écrire les actions

Tout est dans `data/actions.csv` (s'ouvre avec un tableur ou un éditeur de texte, séparateur `;`). Une ligne par action ; une ligne avec un id de PNJ précis remplace la ligne générale pour ce PNJ. Les colonnes sont expliquées en haut de `scripts/actions.gd`.

Les actions intimes (`intime` = 1) ont la description vide : c'est à toi de l'écrire. Le code garde les règles du jeu, quoi qu'il y ait dans le fichier :
- jamais avec un PNJ de moins de 18 ans ou sans profil intime ;
- jamais avec une personne captive, esclave ou sous contrat de dette ;
- jamais si un enfant est à moins de 20 m ;
- le PNJ refuse si son affection est trop basse ;
- Échap arrête la scène.

## Ce qui n'est pas encore là

- Le combat, la création de personnage, l'inventaire et l'argent.
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

`godot --headless -- --autotest` lance un test : données, trajets, PNJ, et les garde-fous des actions intimes.
