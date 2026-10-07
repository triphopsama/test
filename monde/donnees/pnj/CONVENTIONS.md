# Fiches de PNJ en données (donnees/pnj/*.csv)

Un fichier par lieu (`saltevaux.csv`, `pierrefane.csv`…). CSV UTF-8, séparateur `;`, aucun `;` dans les cellules (utiliser `,` ou `/`). Tout en français. Le même profil que la création de personnage du joueur ([creation_personnage.md](../../creation_personnage.md)).

En-tête exacte (34 colonnes) :
`id;nom;lieu;age;sexe;peuple;lignee;statut_social;role;classe;niveau_classe;metier;niveau_metier;For;Agi;End;Vit;Rob;Int;Sag;Per;Vol;affinites_fortes;traits;valeurs;passions;envie_principale;secret;apparence;profil_intime;relations;emploi_du_temps;parole;competences`

- `id` : 3 lettres du lieu + numéro (ex. `SAL001`, `PIE001`, `BRU001`).
- `sexe` : homme, femme, intersexe.
- `peuple` : humain, elfe, nain, homme-bête, demi-sang, démon. `lignee` : animal, clan, lignée, ou les deux peuples d'un demi-sang ; sinon `—`.
- `statut_social` : un échelon de l'échelle du pays (section 9 ter d'[univers.md](../../univers.md)), ex. « citoyen », « notable », « esclave sous contrat de dette ».
- `classe` / `metier` : noms de [classes_metiers.md](../../classes_metiers.md), ou `—`. Niveaux : nombres ou `—`.
- Caractéristiques : nombres cohérents avec l'échelle de [combat.md](../../combat.md) (villageois 5-10, soldat 10-20, vétéran 20-40, maître 40-80).
- `affinites_fortes` : 1 à 3 éléments avec valeur, ex. `feu 62, terre 40` (les autres sont moyennes).
- `traits` : `sociable +60, honnete -20, colerique +10, courageux +40, curieux 0` puis éventuellement d'autres traits de la création de personnage.
- `valeurs` : 3 valeurs avec poids. `passions` : 1 à 3.
- `apparence` : une phrase précise (taille, corpulence, visage, cheveux, signes particuliers, traits de peuple, tenue habituelle).
- `profil_intime` : **adultes seulement**, une phrase : orientation, ce qu'il cherche, axe dominant/soumis, pudeur, expérience, deux ou trois goûts et une limite, situation (marié, amant, célibataire…). Pour un enfant (moins de 18 ans) : `—` obligatoirement.
- `relations` : les liens importants avec d'autres PNJ (id ou nom + lieu), ex. `épouse de SAL014, doit 3 or à Orsoline (Pierrefane)`. Tout le monde ne connaît pas tout le monde : les liens hors du lieu sont rares et justifiés (commerce, dette, famille, trafic, voyage).
- `emploi_du_temps` : la journée type, ex. `6h-12h forge, 12h taverne, 13h-19h forge, soir maison`.
- `parole` : registre + une réplique typique, dans le ton cru du jeu quand le personnage est cru (section 9 « Le ton des dialogues »).
- `competences` : 2 à 5 compétences notables, avec les noms des fichiers de données quand c'est possible.

Limites : aucun contenu sexuel lié à un enfant ; un captif ou un esclave n'a pas de partenaire consentant parmi ses maîtres (son profil intime décrit ce qu'il désirerait librement) ; les textes restent suggérés.
