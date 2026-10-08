# Chronique de Brumeval

La vie du village, écrite jour après jour, **sans joueur**. Les joueurs seront intégrés plus tard.

## Principe : temps réel

Le jeu suit l'heure réelle. Un jour de jeu = un jour réel. Chaque événement de la chronique a une **heure** et un **lieu** : ce que le joueur voit dépend de l'endroit où il se trouve et de l'heure à laquelle il joue.

- Un joueur à la forge à 11 h le jour 1 assiste à l'humiliation de Bram par Silas.
- Un joueur au port au même moment ne la voit pas, mais pourra en entendre parler le soir par Joss à la taverne.
- Un joueur qui ne se connecte qu'à 22 h ne voit que la taverne et la crique.

Entre deux événements, chaque PNJ suit son **emploi du temps** (voir les fiches dans `../memoire_monde.md`). Un événement remplace l'emploi du temps le temps qu'il dure.

## Format d'un jour

Chaque fichier `jour_NNN.md` contient :

1. une ligne de résumé et la météo ;
2. une **chronologie** : `Heure | Lieu | Qui | Ce qui se passe | Conséquences` ;
3. un **bilan** : ce qui a changé dans les relations, les envies, les rumeurs.

Les conséquences utilisent les jauges du document de conception (affection, confiance, respect, humeur, progression des envies).

## Jours écrits

| Jour | Titre | Résumé |
| --- | --- | --- |
| [1](jour_001.md) | La farine manque | La pénurie s'installe, Silas place ses pions ; la nuit, Silas capture une démone sortie de la mer. |
| [2](jour_002.md) | Les alliances | Vesperine est vendue au bordel de Pierrefane ; Ysolde pousse Mara au vote ; Élise cède à Silas. |
| [3](jour_003.md) | La falaise | Tim et Nina entrent dans la maison abandonnée ; le dîner arrangé de Clémence tourne mal. |
| [4](jour_004.md) | Les mains de Bram | Bram se brûle, Isaure le soigne ; Théo envoie un premier rapport. |
| [5](jour_005.md) | Le vote | Silas devient marchand officiel à 5 voix contre 4 ; Lucas comprend qu'il a été dupé. |
| [6](jour_006.md) | Le bateau arrive | Le ravitaillement arrive le lendemain du vote ; Ysolde et Agnès s'allient ; Joss promet d'aider les amoureux. |
| [7](jour_007.md) | La dette | Bram fracasse le comptoir de Silas ; Corentin refuse de l'arrêter ; Lucas vole le registre des dettes. |
| [8](jour_008.md) | Le registre | Silas découvre le vol ; Théo recopie le registre chez les Ferrand ; Mara avoue sa dette à Ysolde. |
| [9](jour_009.md) | Les fiançailles | Silas refuse publiquement d'épouser Gaëlle ; Rosalie protège Lucas ; Gaëlle et Félix partent pour Pierrefane. |
| [10](jour_010.md) | La nuit de la crique | Gaëlle et Félix embarquent ; Silas fait venir deux hommes de main ; Corentin voit le trafic de ses yeux. |
| [11](jour_011.md) | Le départ de Théo | Théo part pour Vaulx-sur-Mer ; Rosalie apprend que Silas vend des gens et rejoint l'alliance. |

## Arcs en cours (pour écrire la suite)

| Arc | Où il en est au soir du jour 7 |
| --- | --- |
| Contrebande de Silas | Silas est marchand officiel. Bram l'a accusé en public ; le village est divisé. Silas soupçonne Théo. |
| Le registre | Lucas a volé le registre des dettes : il prouve la contrebande et le retard du bateau, mais expose aussi Mara (15 pièces) et Clémence (« commissions »). Silas découvrira le vol au matin du jour 8. |
| L'enquête | Théo s'est dévoilé à Ysolde et Agnès. Ils veulent faire témoigner Lucas, et peut-être Élise. Mission de Théo à 85 %. |
| Corentin | A refusé d'arrêter Bram ; a vu une silhouette fuir le comptoir. Tiraillé entre son salaire et son rêve. |
| Gaëlle et Félix | Fuite prévue au jour 10 sur le bateau du ravitaillement, avec Joss. Clémence soupçonne Joss. Réception de fiançailles au jour 9. |
| La falaise | Tim, Nina, Agnès et Pierrick connaissent le puits ; Pierrick a raconté à Agnès la mort de sa femme dans la grotte. Tim se rapproche de Pierrick. |
| Bram et Isaure | Rapprochement ; Bram accepte qu'Agnès soigne ses mains. Il ne pourra pas forger avant le jour 11. |
| Le ruisseau | Tranché au jour 5 (jours alternés) ; Basile ne respecte pas l'accord. Élise n'a plus d'appui. |
| Nina | Dort chez Agnès et apprend les plantes. |
| Rosalie | Vend des informations aux deux camps ; veut racheter la taverne à Clémence. |
| La fille de Joss | Aucune nouvelle ; la chanson de Félix a ému tout le village. |

## Pierrefane

La même chronique, à 16 km de là (le port où Vesperine est vendue).

| Jour | Titre | Résumé |
| --- | --- | --- |
| [1](pierrefane/jour_001.md) | Le gouvernail | Le *Goéland gris* reste à quai sur une avarie inventée ; Orsoline nomme Fleur devant Pâris ; Gilles fait passer deux fugitifs. |
| [2](pierrefane/jour_002.md) | La nouvelle | Silas vend Vesperine à Orsoline ; Lysa la prend sous son aile ; le plan d'évasion passe à trois. |
| [3](pierrefane/jour_003.md) | Le thé de Madame | Odile touche la main de Vesperine ; Orsoline fixe le jour 4 pour « les chambres » ; elle parle de Fleur à Pâris ; l'orage cloue les barques. |

## Avec le joueur

- [Jour 1 avec le joueur](joueur/jour_001_avec_joueur.md) : Brumeval heure par heure, toutes les actions possibles et leur suite, dont l'embranchement de Vesperine.
- [Jour 1 à Pierrefane avec le joueur](joueur/jour_001_pierrefane_avec_joueur.md) : y aller (à pied, en courant, avec Joss), Pierrefane heure par heure, et comment voir les deux villes le même jour.
- [Jour 2 avec le joueur](joueur/jour_002_avec_joueur.md) : l'état du monde au réveil (tous les fils du jour 1 et leurs valeurs), les actions nouvelles, Brumeval et Pierrefane heure par heure, et les embranchements qui mènent au jour 3.
- [Jour 3 avec le joueur](joueur/jour_003_avec_joueur.md) : la farine, Garec qui cherche Vesperine, la falaise avec les enfants, le dîner des Montval, la fuite de Gaëlle et Félix avant l'orage, Lucas sous le tonneau ; à Pierrefane, le compte à rebours d'Orsoline, le carnet, Fleur, l'évasion par la terre ; et les embranchements du jour 4.
- [Tous les scénarios, jours 1 à 3](joueur/scenarios_jours_1_a_3.md) : selon qui tu es (peuple, tenue, avantages, corps), les grandes voies (héros, complice, marchand, libertin, enquêteur, protecteur, explorateur, voyageur, hors-la-loi, captif, rien), qui peut mourir et ce que ça change, les nuits possibles, chaque fil jour après jour, les collisions entre les deux villes, et ce qui reste impossible.
