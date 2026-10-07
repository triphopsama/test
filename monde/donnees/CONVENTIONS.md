# Conventions des fichiers de données

Fichiers CSV, UTF-8, séparateur `;`, une ligne d'en-tête, aucun `;` dans les cellules (utiliser `,` ou `/` à la place). Tout en français.

## Compétences (donnees/competences/*.csv)

En-tête exacte :
`id;nom;sorte;famille;classes_ou_metiers;element;rarete;conditions;cout;recharge;portee_zone;effet;evolue_de;evolutions;source`

- `id` : préfixe du fichier + numéro sur 3 chiffres (ex. `CAC001`). Unique.
- `sorte` : active, reaction, passive, aura, metier, sociale, exploration, ultime.
- `famille` : groupe lisible (ex. « Épée », « Feu », « Séduction »).
- `classes_ou_metiers` : qui la reçoit naturellement, séparés par `/` (ou « Tous »).
- `element` : feu, eau, glace, terre, air, foudre, lumiere, ombre, sang, esprit, nature, mort, physique, aucun.
- `rarete` : inferieure, commune, peu commune, rare, epique, ancienne, legendaire.
- `conditions` : caractéristiques minimales abrégées For, Agi, End, Vit, Rob, Int, Sag, Per, Vol (ex. `Int 10, Sag 8`), plus éventuellement une affinité magique minimale (ex. `affinite feu 30`, voir la section « Les affinités magiques » de competences.md) et une condition spéciale (peuple, compétence préalable maîtrise N, exploit). « aucune » sinon.
- `cout` : ex. `8 mana`, `12 endurance`, `5 vie`, `—` pour une passive.
- `recharge` : en tours de combat, ou `—`, ou `1/combat`, `1/jour`.
- `portee_zone` : ex. `portée 4, cible unique`, `soi`, `cône 3`, `croix 1`, `—` hors combat.
- `effet` : une phrase claire, chiffres indicatifs (dégâts en multiplicateur de stat, ex. `1,4 x Int`).
- `evolue_de` : id de la compétence d'origine, ou vide. Une fusion ou une évolution à plusieurs chemins peut lister plusieurs ids séparés par `/`.
- `evolutions` : ids des évolutions possibles séparés par `/`, avec l'usage qui y mène entre parenthèses, ou vide.
- `source` : comment l'obtenir (maître, livre, découverte, choix de niveau, exploit, objet, pacte, peuple).

## Objets (donnees/objets/*.csv)

En-tête exacte :
`id;nom;type;emplacement;rarete;niveau_conseille;bonus_stats;effet_special;competence_donnee;conditions;prix;ou_le_trouver;description`

- `type` : arme, armure, bijou, accessoire, consommable, permanent (augmente une stat pour toujours), materiau, outil, objet_quete.
- `emplacement` : main droite, main gauche, deux mains, tête, torse, mains, jambes, pieds, cou, anneau, dos, ceinture, — .
- `bonus_stats` : ex. `For +3, Rob +2, Agi -1`.
- `prix` : en or, argent et cuivre (le cuivre est le denier). 1 or = 20 argent ; 1 argent = 12 cuivre.

## Limites de contenu (fixées avec trip)

Le jeu est pour adultes. Mais : aucune compétence ni objet ne sert à forcer un rapport intime ; le contrôle mental et le charme ne servent jamais pour le sexe ; un captif ne peut pas consentir ; aucun contenu intime impliquant des enfants ; les textes restent suggérés.
