# Données du jeu : compétences et objets

Tableaux CSV (séparateur `;`, UTF-8) prêts à être chargés par Godot. Format et règles : [CONVENTIONS.md](CONVENTIONS.md). Règles du système : [competences.md](../competences.md) (dont les affinités magiques) et [classes_metiers.md](../classes_metiers.md).

## Compétences : 2 205 lignes, 2 135 compétences différentes

| Fichier | Préfixe | Compétences | Contenu |
| --- | --- | --- | --- |
| [corps_a_corps.csv](competences/corps_a_corps.csv) | CAC | 269 | Guerrier, Lutteur, Garde, Lancier, Duelliste, Moine, Mercenaire, Gladiateur, Brise-roc, armes de base, évolutions de classe |
| [distance_ombre.csv](competences/distance_ombre.csv) | DOM | 275 | Archer, Arbalétrier, Lanceur, Artificier, Voleur, Éclaireur, Assassin, Danseur-lame, Chasseur de primes, Pirate, Rôdeur, Archer-lune, Griffe libre |
| [magie_elementaire.csv](competences/magie_elementaire.csv) | ELE | 246 | Feu, eau, glace, terre, air, foudre, gravité, marées, Lame-sort, sorts mixtes, lecture des affinités |
| [magie_sombre_esprit.csv](competences/magie_sombre_esprit.csv) | SOM | 268 | Illusion, esprit, envoûtement, invocation, nécromancie, nécromancien esclavagiste, sang, classes démoniaques |
| [soin_foi_nature.csv](competences/soin_foi_nature.csv) | SFN | 238 | Soin, les Sept Astres, Paladin, Exorciste, Chaman, Druide, Chanteur des arbres, Hurleur, Prêtre des forges |
| [soutien_maitres.csv](competences/soutien_maitres.csv) | SMA | 231 | Barde, Tacticien, Alchimiste de combat, Dompteur, Dompteur de monstres, Esclavagiste, Bricoleur, Entre-deux, combos entre compagnons |
| [metiers.csv](competences/metiers.csv) | MET | 396 | Tous les métiers : forge (et runes, fer d'étoile), artisanat, récolte, alchimie, commerce, loi, métiers elfes et démons |
| [interaction_vie.csv](competences/interaction_vie.csv) | INT | 282 | Social, séduction entre adultes consentants, exploration, résistances, moral, évasion, passives raciales, titres |
| [toutes_competences.csv](competences/toutes_competences.csv) | — | 2 205 | Les 8 fichiers fusionnés, avec une colonne `fichier` |
| [_doublons.csv](competences/_doublons.csv) | — | 67 noms | Compétences écrites dans deux fichiers sous le même nom. Le jeu garde `id_garde` et traite les autres ids comme des alias. |

| Rareté | Nombre |
| --- | --- |
| Inférieure (gris) | 65 |
| Commune (blanc) | 574 |
| Peu commune (vert) | 734 |
| Rare (bleu) | 526 |
| Épique (violet) | 208 |
| Ancienne (orange) | 56 |
| Légendaire (rouge) | 42 |

| Sorte | Nombre |
| --- | --- |
| Active | 858 |
| Passive | 426 |
| Métier | 382 |
| Sociale | 158 |
| Exploration | 141 |
| Ultime | 93 |
| Réaction | 74 |
| Aura | 73 |

Les compétences cachées ont une `source` qui commence par « caché » ou « découverte cachée », avec l'action qui les débloque. Les titres commencent par « Titre : ».

## Objets : 511

[objets.csv](objets/objets.csv), préfixe OBJ.

| Type | Nombre |
| --- | --- |
| Armes (26 armes de base en 5 versions : rouillée, commune, de maître, enchantée, runique) | 142 |
| Armures, boucliers, vêtements | 121 |
| Consommables (bonus temporaires) | 57 |
| Bijoux (dont 36 anneaux d'affinité : 12 éléments × 3 niveaux) | 56 |
| Matériaux | 40 |
| Outils de métier | 33 |
| Objets permanents (augmentent une stat pour toujours) | 26 |
| Accessoires | 22 |
| Objets de quête | 14 |

On y trouve des sets avec bonus à 2 et 4 pièces, des objets liés à l'âme qui grandissent avec leur porteur, et du butin de boss.

## Les lieux

[lieux/](lieux/), préfixe BRU_L pour Brumeval. Le plan qui va avec est [cartes/brumeval.md](../cartes/brumeval.md).

| Fichier | Contenu |
| --- | --- |
| [brumeval_lieux.csv](lieux/brumeval_lieux.csv) | 28 lieux : coordonnées en mètres (1 case = 1 m), hauteur, habitants, horaires, accès, ce qui s'y cache, terrain de combat, lieux reliés |
| [brumeval_chemins.csv](lieux/brumeval_chemins.csv) | 35 chemins : distance, temps à pied (1,5 m/s) et en courant (4 m/s), condition (marée basse, nuit…) |
