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

## La magie

D'après `monde/competences.md` (affinités) et `monde/combat.md` (dégâts magiques, états).

- **12 éléments** : feu, eau, glace, air, terre, foudre, lumière, ombre, nature, mort, sang, esprit. Ton **affinité** avec chacun (0 à 100) est tirée à la création, souvent avec un pic inattendu, et **tu ne la vois pas** : la fiche (C) dit seulement ce que tu ressens (« le feu vient facilement ») pour les éléments que tu as déjà lancés. La **Pierre d'affinité** (2 or chez Silas) donne les vrais chiffres.
- **Ce que l'affinité change** : +1 % de puissance par point au-dessus de 50, −1 % sous 20 ; le sort coûte jusqu'à 25 % de mana en moins dans un élément aimé, le double sous 10, et rate alors une fois sur quatre. Chaque sort lancé fait monter son élément (et baisser l'opposé).
- **Les sorts touchent toujours** : dégâts = multiplicateur × Int (ou Sag) × affinité, réduits par la défense magique (Vol × 2), multipliés par le facteur élémentaire de la cible. Les gens résistent à leurs éléments forts et craignent leurs opposés ; les bêtes ont leurs faiblesses (les rats craignent le feu, le crabe-rocher la foudre et résiste à l'eau).
- **États** : brûlure (5 % des PV par tour), gel (déplacement −2, vitesse −30 %), trempé (feu ×0,5, foudre ×1,5, éteint les brûlures), aveuglé (−40 % pour toucher), affaibli (dégâts ×0,7), inspiré (+10 % pour toucher). Les contrôles se résistent (Vol, Rob, Per, Vit selon l'état).
- **La mana** (Sag × 6 + Int × 2) reste dépensée après un combat ; elle revient d'un quart par heure, et entière en dormant.
- **6 classes de magie et de foi** : Mage élémentaire (Flamme, Bourrasque, Boule de feu, Éclat de glace), Mage de soin (Soin léger, Purification, Soin de groupe), Mage de l'eau et des marées (Vague), Prêtre de combat (Lumière de la Pâle, Bénédiction, Masse sainte), Envoûteur (Malédiction de faiblesse, Mauvais œil), Enchanteur (Arme enflammée, Rune de garde). Elles se proposent comme les autres, d'après les sorts que tu as lancés.
- **Apprendre un sort sans classe** :
  - les **parchemins** (I : utiliser, deux heures de lecture) : Flamme (6 argent chez Silas, sans condition), Éclat de glace (1 or 4 argent chez Silas, Int 10), Vague (8 argent chez Joss, Sag 10) ;
  - les **leçons** : « Demander une leçon » à un PNJ qui t'aime un peu (affection 10). Chacun enseigne ce que sa classe lui a appris et qu'il sait vraiment faire : Agnès les soins, Ysolde la lumière, Bram la parade, Pierrick la volée, Silas le vol à la tire et le crochetage, Lucas les prises, Corentin le bouclier. 3 argent la leçon (6 pour une compétence avancée), moitié prix s'il t'apprécie (40), gratuit s'il t'aime bien (70). Les enfants n'enseignent pas.
- Équilibre mesuré (`--equilibre`, niveau 1, Flamme seule) : rats 10/10, loup 9/10, crabe 10/10, sanglier 4/10. Mieux qu'aux poings, moins bien qu'une dague.

## Les compétences hors combat

Elles deviennent des actions dans le village (colonne `competence` de `data/actions.csv`) :

| Compétence | Action | Où | Ce que ça fait |
| --- | --- | --- | --- |
| Vol à la tire (Agi 8) | Voler à la tire | sur un adulte | Agi contre les regards ; pris, la victime (−30) et les témoins (−15) s'en souviennent |
| Crochetage (Agi 10) | Crocheter une serrure | maison de la falaise, comptoir de Silas | de l'argent derrière la porte ; les témoins t'en veulent si tu rates |
| Pistage (Per 8) | Suivre des traces | bois, landes | tu trouves un loup isolé ou un sanglier, et le combat commence |
| Piège (Int 8) | Poser ou relever des pièges | bois, landes | des collets aujourd'hui, viande ou peau demain |
| Respiration sous l'eau (Sag 8) | Plonger | crique, port | des pièces perdues, parfois une carapace |
| Lire la marée (Per 8) | Lire la marée | côte | l'heure des basses mers ; +2 maquereaux si tu pêches dans les trois heures |
| Flamme | Faire un feu de camp | bois, plage | +25 % PV, une fois par jour, et l'affinité feu monte |
| Soin léger, Soin des bois | Soigner tes blessures, Soigner quelqu'un | partout | des PV contre de la mana ; soigner quelqu'un le rend plus amical (+4 ; Bram et ses mains, +10) |
| Bénédiction (Sag 8) | Bénir quelqu'un | partout | +2 d'affection, +6 chez les pieux |

Chacune une fois par jour (par lieu ou par personne).

## L'intime (entre adultes consentants)

D'après `univers.md` (« Désir et sexualité »). Désactivable à la création (contenu adulte). Les règles fixes, quoi qu'il y ait dans les fichiers : adultes seulement, jamais si un enfant est à portée, jamais avec un captif ou sous la contrainte, un non est un non, le mot d'arrêt (« Brume ») arrête tout.

- **Profils** (`data/intime.csv`, tiré des fiches par `outils/intime.py`, à régler à la main) : qui l'attire, ce qu'il cherche, **libido**, axe dominant/soumis, pudeur, expérience, intérêt pour les jeux de pouvoir, partage (harem, à plusieurs), **jalousie**, couple, ce qu'il **aime**, ses **talents**, ses **limites**. Mets `fige` à 1 pour que l'outil ne réécrive plus une ligne. Un PNJ « soumis à tout » : axe −90, bdsm 90, aime `etre_domine`.
- **Le désir** (0 à 100) monte chaque heure selon la libido, et retombe quand il est comblé. Le tien aussi.
- **Le consentement** dépend de l'affection, du désir, de l'attirance (ton sexe), de ce qu'il cherche (qui cherche l'amour ne passe pas la nuit sans être ensemble), de son couple, de la pudeur devant témoins. Séduire, embrasser, passer la nuit, être ensemble, un pacte : chacun son seuil.
- **La nuit** ouvre une fenêtre : ton image ou animation en haut, les jauges de chacun (Plaisir, Désir, Malaise, Intensité pour les jeux de pouvoir), une vingtaine de gestes (`data/gestes.csv`), inviter quelqu'un qui le veut aussi à se joindre, et « Arrêter ». Un geste qu'il aime fait monter le plaisir, un geste qu'il refuse le malaise : trop de malaise ou d'intensité, et c'est le mot d'arrêt. Après : rester dormir, partir avant l'aube, ou promettre d'être ensemble.
- **Harem** : plusieurs couples à la fois ; chaque nouveau couple coûte de l'affection aux jaloux, et certains refusent de partager.
- **Pacte maître/esclave** : un jeu convenu entre adultes (toi le maître, ou toi à son service), seulement si son profil s'y prête et que la confiance est haute, révocable à tout moment ; il ouvre les jeux de pouvoir de la scène.
- **Jalousie et rumeurs** : des témoins, ou un secret qui fuit (25 %, 10 % avec Discrétion) ; le conjoint trompé (−40), tes partenaires jaloux, les prudes du village.
- **Le désir à son comble** : un PNJ près de toi se soulage seul, ou avec quelqu'un qu'il attire et qui en a envie (ceux qui se rapprochent d'abord, jamais en famille, pas de tromperie s'il ne partage pas). Tu le surprends : une image, puis « Te montrer » (selon sa pudeur, une invitation ou la honte, puis tu lui parles) ou « Partir sans bruit ».
- **Compétences** : Séduction, Lecture des envies, Massage, Danse lascive, Jeu de pouvoir, Discrétion (leçons de Silas, Élise, Théo, Agnès, Mouche, s'ils t'apprécient), Art d'aimer (vient avec la première nuit, monte avec les suivantes).
- **Actions** : séduire, embrasser, passer la nuit, lui demander ce qu'il aime, masser, proposer d'être ensemble, rompre, pacte (maître ou à son service), y mettre fin, danser à la taverne le soir, travailler la nuit comme courtisan·e (métier : libre et payé, la paie monte avec l'Art d'aimer).
- **Les textes** restent suggérés : la colonne `description` de `data/actions.csv` et la colonne `texte` de `data/gestes.csv` sont à toi, ton texte remplace le texte par défaut.

## L'équipe et les tenues

- **4 compagnons au plus** te suivent (« Proposer de te suivre » : affection 50 avec un couple ou un pacte, 70 sinon ; jamais un enfant). Ils marchent derrière toi et **se battent avec toi** (pas en bagarre). « Dire de rentrer chez lui » : il retourne à son emploi du temps (une maison à toi viendra avec le logement).
- **Habiller ou déshabiller un compagnon** (« Habiller… ») : les accessoires de Silas (collier et laisse, cagoule, bâillon, cordes, plug) et la nudité. Seulement avec un pacte où tu mènes, et s'il aime ça (jeux de pouvoir 40, ou aime être dominé) ; ce qui se voit demande en plus qu'il aime le risque ou l'audace, ou soit peu pudique. Le plug ne se voit pas, mais c'est dit (barre d'infos).
- **Les passants réagissent** une fois par jour chacun : les prudes et les pieux s'indignent (−5), les autres sont gênés (−2), les audacieux ne détournent pas les yeux (+2, désir). Corentin verbalise la nudité (amende, on rhabille). Un compagnon qui n'aime pas être vu accumule du malaise : trop de regards outrés et c'est le mot d'arrêt (−10, on le couvre).
- **Un enfant à portée : tu le couvres aussitôt**, toujours.

## Les défis et l'entraînement

- **Les PNJ te lancent des défis** (`data/defis.csv`, à compléter) : quand tu passes près d'eux (une fois par jour), ou « Les défis de… ». Accepter, c'est risquer ce qui est en jeu.
  - Lucas : une lutte au port ; Bram : un bras de fer (gagné, il t'apprend la parade) ; Pierrick : une peau de loup avant la nuit (il t'apprend le pistage), un concours de tir ; Rosalie : un concours de boisson ; Silas : une partie de cartes ; Élise : trois fois cette nuit (elle t'apprend la danse).
  - Types : `bagarre` (une lutte, personne ne t'en veut), `jet` (ta caractéristique + 1d20 contre la sienne), `apporter` (un objet avant la fin du jour), `intime` (le combler N fois en une nuit : adultes consentants, mêmes règles que toute nuit ; entre deux, il en redemande).
  - Récompenses et pénalités : affection, cuivre, objet, leçon gratuite, Art d'aimer, et `pacte maitre` (il te propose un pacte où tu mènes, si son profil le veut aussi).
- **« T'entraîner »** : une heure de compétences par jour (+15 expérience), un combat d'entraînement contre quelqu'un de ton équipe (à mains nues, personne ne t'en veut), ou une pratique à deux avec un partenaire consentant (l'Art d'aimer monte).

## Vesperine, la nuit du jour 1

D'après `monde/demons/vesperine.md` et la chronique du jour 1 avec le joueur (`scripts/vesperine.gd`).

- **21 h 30**, elle échoue sa barque à la Bouche de mer, épuisée ; **21 h 45** elle mange des algues ; **22 h 30** elle longe la falaise ; **23 h 10** elle descend vers la crique ; **23 h 20** Silas la voit ; **23 h 30** la drogue et le collier. Sans toi, elle est capturée et vendue à Pierrefane : elle disparaît du jeu, et rien d'intime n'est possible avec une captive.
- **La nourrir** (un pain ou un poisson) : elle lit ce que tu lui veux (si ton désir est trop fort, elle garde ses distances). **La guider chez Agnès** (affection 20) : la crique n'a jamais lieu.
- **À la crique, si tu y es à 23 h 20** : intervenir en parlant (Int + Per), faire diversion (Agi), te battre contre Silas (niveau 18), ou regarder caché. Lucas, qui refuse d'y toucher, t'en sait gré si tu la sauves.
- **Libre**, elle vit cachée (chez Agnès, la falaise, le bois, la pointe du Guet le soir). Tant qu'elle a faim et peur, rien d'intime. Nourrie et en sécurité, c'est une adulte libre : succube, libido 95, elle aime l'audace et les jeux de pouvoir. Son défi : **« cinq fois cette nuit »** ; relevé, elle te propose un pacte où tu mènes.

## Le sort des vaincus

Après un vrai combat gagné contre quelqu'un, ceux qui sont à terre : **épargner** (il te doit la vie, +15, les témoins +3) ou **tuer** (les morts restent morts, les témoins −30).

## Écrire les actions

Tout est dans `data/actions.csv` (s'ouvre avec un tableur ou un éditeur de texte, séparateur `;`). Une ligne par action ; une ligne avec un id de PNJ précis remplace la ligne générale pour ce PNJ. Les colonnes sont expliquées en haut de `scripts/actions.gd`. Les colonnes `prix` (« 1 argent », ou un objet : « OBJ327 1 ») et `donne` (« cuivre 6 », « BRV003 2 », « repos ») font payer et rapporter une action.

Les actions intimes (`intime` = 1) ont la description vide : c'est à toi de l'écrire. Le code garde les règles du jeu, quoi qu'il y ait dans le fichier :
- jamais avec un PNJ de moins de 18 ans ou sans profil intime ;
- jamais avec une personne captive, esclave ou sous contrat de dette ;
- jamais si un enfant est à moins de 20 m ;
- le PNJ refuse si son affection est trop basse ;
- Échap arrête la scène.

## Ce qui n'est pas encore là

- Le corps et le profil intime à la création, les évolutions de classe aux niveaux 25, 50 et 75, la maîtrise des compétences (1 à 10) et les fusions, les sorts de terre, de foudre, d'ombre, de nature, de mort, de sang et d'esprit, le terrain qui brûle ou gèle, la maîtrise des armes et les titres.
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
| `data/actions.csv` | Écrit à la main, à compléter (colonne `competence` : l'action demande cette compétence) |
| `data/classes.csv`, `metiers.csv` | `monde/classes_metiers.md`, compétences reprises de `monde/donnees/competences` |
| `images/plan.png` | Le plan, généré par `outils/image.py` |

## Vérifier que tout marche

`godot --headless -- --autotest` lance un test : données, trajets, PNJ, les garde-fous des actions intimes, les objets, le sac, les marchands et l'expérience, les classes et les métiers, la magie, les leçons et les compétences hors combat, et des combats joués tout seuls (bagarre, loups, agression).

`godot -- --capture=image.png --heure=20 --combat=loups` (ou `--combat=bagarre`) enregistre une image d'un combat ; `--fenetre=sac`, `perso`, `classe` ou `bram` une image des fenêtres ; `--creation=3` l'écran de création à l'étape 3.
