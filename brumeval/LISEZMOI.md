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

## Le bois de Ronceval, plus loin

La carte s'étend vers l'est (2 400 m) : le bois profond, avec cinq lieux de plus.
- **Clairière aux cerfs** : « Chasser le cerf » (une fois par jour ; Per et Agi, mieux avec un arc et le Pistage) : viande, peau, parfois des bois.
- **Ruines de l'ermitage** : les fouiller (une fois par jour ; un parchemin de Bourrasque y attend peut-être), prier à l'autel effondré (toute ta mana, et la lumière te parle un peu plus).
- **Source chaude des Fées** : s'y baigner rend la moitié des PV.
- **Grand Roncier** : des mûres, et la bauge des sangliers (on les croise trois fois plus souvent).
- **Étang noir** : un brochet, et une légende de noyé.
- La source, la clairière et l'étang sont aussi des lieux pour un moment risqué à deux.

## Les fées, les Gens de la Brume

D'après les vieilles croyances (`univers.md` : la Brume guide ceux qu'elle aime et prend ceux qui lui manquent de respect). Trois sœurs, fées adultes et très anciennes, visibles à l'aube (5 h – 8 h) et au crépuscule (19 h – 22 h) : **Brumelle** à la Source chaude, **Lirelle** à l'Étang noir, **Mousse** à la Clairière aux cerfs.
- **Leur faveur** est partagée : ce que tu fais à l'une, les trois le savent. Offrandes (pain sur la pierre de la source, pain, mûres) : +8 la première du jour.
- Faveur 30 : **la bénédiction de la Brume** pour la journée (un coup raté se rejoue en combat). Faveur 50 : dans le bois, **la Brume t'écarte des bêtes**. Faveur 70 : **elles peuvent choisir de te suivre** (un pacte, pas une capture : on ne dompte pas un être qui pense). Faveur −30 : **la Brume t'égare** dans le bois.
- Ce sont des adultes libres : l'intime suit les mêmes règles qu'avec tout le monde. Elles adorent le dehors, le bain, le jeu, l'audace et les nuits à plusieurs (partage 100, aucune jalousie).

## Le domptage des bêtes

- **Apprivoiser** (Vol 10) : en combat, une bête à moins d'un quart de sa vie, collée à toi ; Vol contre Vol. Elle cède, quitte le combat et **te suit** ensuite (elle compte dans ton équipe de 4). Elle se bat avec toi.
- **La classe Dompteur** s'éveille si tu apprivoises : Apprivoiser, Ordre de meute (tes bêtes : +2 dégâts, +10 % pour toucher), Lien de meute (une place de plus pour une bête). Pierrick et Basile enseignent à apprivoiser s'ils t'apprécient (affection 30).
- « Relâcher une bête » : elle retourne au bois.
- On n'apprivoise que des bêtes, jamais un être qui pense (les fées se gagnent, elles ne se domptent pas), et rien d'intime avec une bête.

## Pierrefane

La ville portuaire, au bout du sentier côtier : une vraie carte en 3D, avec ses rues, ses 18 habitants
et leurs emplois du temps (plan : [monde/cartes/pierrefane.md](../monde/cartes/pierrefane.md), touche Tab en jeu).

- **Le voyage** : au lieu « Sentier côtier », l'action « Prendre le sentier côtier (3 h) ». Ton équipe vient avec toi ;
  si tu laisses un compagnon dans l'autre ville, il t'attend au sentier.
- **Margo**, courtisane libre, au salon des Lanternes (18 h - 4 h) : 2 argent, et son droit de dire non.
- **Le Mouillage** (Ondine) : dormir, manger, danser ; le travail de nuit libre, là et au port.
- **Lysa et Bastien**, captifs de la Maison des Lanternes : aucun profil intime, aucune action intime.
- **Défis** : Thorga (bras de fer), Kael (course sur la lande).
- **Ajouter une carte** : un module `outils/<carte>_data.py` (lieux, chemins, côte), puis
  `python3 outils/build_carte.py <carte> <PREFIXE>`, `python3 outils/image_carte.py <carte> "<Nom>"`,
  `data/<carte>/pnj.csv` et `emplois.csv`, et une ligne dans `CARTES` (scripts/monde.gd).
  Une action réservée à une carte : `pierrefane:port` dans la colonne lieux.

## Les amours des habitants

Ils vivent leur vie sans toi (scripts/liens.gd), à toute heure, même dans la ville où tu n'es pas :
deux qui se plaisent passent la nuit ensemble ; une liaison devient un couple, ou s'éteint ; un couple
s'ouvre, se sépare, se retrouve ; une liaison secrète finit par se découvrir (pardon et couple ouvert,
ou la porte qui claque, selon la jalousie et ce que chacun partage). Seulement entre adultes qui ont
un profil, de la même ville, présents (pas « en route »), qui s'attirent, et jamais dans une famille.

Ce que tu en vois : l'image si tu es là, sinon les **ragots** (taverne, auberge, lavoir, place).
Ce que tu peux en faire :

| Action | Ce que ça fait |
| --- | --- |
| Lui demander où il en est | ses amours (affection 30 ; un secret à 50) |
| Lui présenter quelqu'un | Sag + Per : ça les rapproche, parfois tout de suite |
| Lui dire qu'on le trompe | s'il l'est, et que tu le sais : il te remercie, les amants t'en veulent (-20) |
| Couvrir ses amours | un alibi : +10 avec les deux, le secret tient mieux |
| Faire payer ton silence | de l'argent (Vol + Int contre lui) ; raté, il avoue tout et ça se sait |
| Le consoler | après une rupture (+8, une fois par jour) |
| Les réconcilier | Sag + Int : ils se retrouvent (+10) |
| Semer le doute | Int + Agi contre son flair : ils se séparent, ou ils comprennent que c'est toi (-25) |
| Leur proposer une nuit à trois | un couple ouvert, l'autre à côté, chacun doit le vouloir |

Et toi : un couple qui t'aime bien (affection 40, ouvert, qui partage) peut t'inviter à le suivre ;
tu peux décliner sans rien perdre. Si ton couple te trompe, il vient te le dire : pardonner, rompre,
partager (plus de secrets, et la porte ouverte à trois), ou t'expliquer avec l'autre à mains nues.

## La grotte de Brumeval

Le premier donjon (`monde/donjons/grotte_de_brumeval.md`, code dans `scripts/grotte.gd`), conseillé du niveau 5 au niveau 10. Il faut une lanterne pour y voir loin (il y en a une au fond du puits).

- **Y entrer** : par le puits du jardin Marbre, avec une corde (Joss et Silas en vendent ; Pierrick t'arrête s'il ne t'aime pas assez), ou à marée basse par la Bouche de mer sous la falaise, si on t'en a parlé (Agnès, Joss, Pierrick).
- **Les huit salles** : le fond du puits (4 rats), la galerie et la **porte des astres** (l'ordre de la comptine que chantent Joss, Tim et Ysolde, ou For 14, ou crochetage), la **salle inondée** qui suit la vraie marée (à pied et contre des crabes et un slime à marée basse, à la nage à marée haute), le **campement de Gaspard** (le journal et le coffre à quatre astres), le **gouffre** (brûler les toiles, se balancer à la corde, ou tomber dans le nid), la **chambre de Léa**, la **veine d'étoile** et sa Bête aveugle (l'attirer sous les stalactites, la contourner en silence, ou l'affronter), la **Bouche de mer** et la barque noire.
- **Au village, après** : rendre Léa (ou seulement son carnet, son alliance) à Pierrick, le fer d'étoile à Bram, les bijoux et le journal à Ysolde, le journal à Aldric (pour qu'il le brûle, ou pour le faire chanter), l'eau-de-vie et le secret de la grotte à Silas, la soie à Isaure.
- **Équilibre** (`godot --headless -- --equilibre --grotte`, épée courte et rondache) : au niveau 5, on gagne contre les rats et la moitié du temps dans la salle inondée et au gouffre ; la Bête aveugle se bat de front vers le niveau 7, ou dès le niveau 5 avec les stalactites ; tomber dans le nid se paie cher avant le niveau 9.

## Ta maison

La maison de la falaise (l'ancienne maison Marbre, au-dessus de la grotte). Ysolde en a hérité :
demande-la-lui. Elle te la donne si elle t'aime bien (affection 50), sinon elle te la vend 8 pièces d'argent.
Ensuite, les travaux, sur place (Bram aide si tu es son ami, et ça va deux fois plus vite) :

| Étape | Prix | Ce que ça ouvre |
| --- | --- | --- |
| 1. une ruine | (l'achat) | elle est à toi, on ne crochète plus sa porte |
| 2. habitable | 5 argent, 8 h | dormir chez toi ; y loger quelqu'un |
| 3. meublée | 6 argent, 6 h | le coffre (ce que tu ne portes pas) |
| 4. aménagée | 1 or, 10 h | la salle d'armes (+10 à l'entraînement), le bain chaud, l'enclos des bêtes |

La maison change à l'écran à chaque étape (une ruine sans toit, puis un toit, puis la lumière aux fenêtres,
puis l'enclos et le bain). « Lui proposer de vivre chez toi » : un compagnon ou un proche (affection 50
s'il est lié à toi, 70 sinon) garde son travail mais dort chez toi ; à l'entraînement, chez toi, ceux qui
y vivent sont là. Une bête à l'enclos ne prend plus de place dans l'équipe.

## Tout a un prix

`data/biens.csv` : chaque maison, chaque commerce, le Goéland gris… Sur place, « Acheter, louer, négocier ce lieu » :

- **Acheter** : au prix de base si le propriétaire t'aime assez (colonne `vend`), plus cher sinon, et il t'en
  veut d'avoir forcé la main. Ton commerce rapporte chaque jour (colonne `revenu`), le propriétaire y reste
  et y travaille ; chez lui, tu achètes à moitié prix. On peut **revendre** aux trois quarts.
- **Négocier** (une fois) : Int + Sag (+ Séduction, + commerçant) contre le vendeur : -15 % ou -30 %, ou +15 % s'il se vexe.
- **Louer** : un dixième du prix par semaine ; on y dort, pas de revenus ; loyer impayé, clé reprise.
- **Se le faire prêter** : une maison, par un ami (affection 70) ; il la reprend si vous vous brouillez.
- **Un événement** peut te donner ou te prêter un bien : `bien <id>` ou `pret <id>` dans une récompense de
  `data/defis.csv` (exemple : la vieille Mahaut te prête sa cabane si tu lui rapportes ses herbes). C'est là
  qu'on branche « un noble sauvé t'offre une maison ».
- Chez toi (acheté, loué, prêté), on dort gratuitement. Le corps de garde, la mairie, les chapelles et la
  maison du prévôt ne se vendent jamais.

**Les contrats de dette** (Lysa, Bastien, et Vesperine si elle a été vendue à Pierrefane) : « Racheter son
contrat » auprès d'Orsoline. Le contrat est à toi : tu le déchires (libre, +30), ou tu le gardes : il travaille
pour toi (8 cuivre par jour) ou il te suit au combat, et son affection baisse chaque jour. **Sous contrat,
rien d'intime, jamais** : il ne peut pas consentir. Acheter la Maison des Lanternes met ses contrats dans ta
poche (les déchirer, ou les garder). Vesperine rachetée et libérée reste à Pierrefane, et a besoin de deux
jours avant quoi que ce soit.

## Les jours de la chronique

Les jours 1 à 3 de [la chronique](../monde/chronique/joueur/) se jouent : `data/scenes.csv` (104 scènes,
Brumeval et Pierrefane) et `data/scenes_choix.csv` (leurs choix). Chaque scène a un jour, une heure de
début et de fin, un lieu et des PNJ : **les PNJ y vont à l'heure dite, même sans toi**. Si tu arrives à
moins de 30 m pendant la scène, elle s'ouvre (l'image, le texte, puis les choix). Si elle se termine sans
toi, ses effets « sans toi » s'appliquent : le monde continue (Élise moud pour Silas, la plainte de la
rigole arrive à la mairie, Nina vole ta bourse…).

Les choix ont des conditions (« fil elise=amante », « aff BRU012>=15 », « bourse>=36 », « ves capturee »,
« peuple demon »…), des jets (« Agi 20 +crochetage 6 » : ta caractéristique + 1d20 contre 20, +6 si tu as
Crochetage) et des effets (« fil farine=refus », « aff BRU001 +10 », « cuivre -36 », « ves libre »,
« combat BRU003 mortel vesperine », « partir BRU009 », « acheter taverne »…). Les **fils** (farine, Élise,
Silas, Nina, les amants, la falaise, Pâris, l'évasion…) relient les jours entre eux : ce que tu as fait au
jour 1 ouvre ou ferme des choix au jour 2 et 3. Tout est expliqué en tête de `scripts/scenes.gd`.

`data/presences.csv` : qui est dans le pays quels jours (Théo jusqu'au jour 11, Gaëlle et Félix jusqu'au
jour 9, Garec aux jours 1 à 3 puis à partir du jour 10, Mouche à partir du jour 10).

Images : `illustrations/<id de la scène>/` pour la scène, `illustrations/<scène>_<choix>/` pour la suite d'un choix.

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
- La grotte (une autre session s’en charge) et le reste du monde au-delà de Brumeval et Pierrefane.

- Pierrefane et le reste du monde. Dans la grotte : suivre en douce avec Tim et Nina, boucher ou surveiller la Bouche de mer.
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

`godot --headless -- --autotest` lance un test : données, trajets, PNJ, les garde-fous des actions intimes, les objets, le sac, les marchands et l'expérience, les classes et les métiers, la magie, les leçons et les compétences hors combat, la grotte, et des combats joués tout seuls (bagarre, loups, agression).

`godot --headless -- --autotest --carte=pierrefane` teste Pierrefane (et `--carte=pierrefane` marche aussi avec `--capture`).

`godot -- --capture=image.png --heure=20 --combat=loups` (ou `--combat=bagarre`) enregistre une image d'un combat ; `--fenetre=sac`, `perso`, `classe` ou `bram` une image des fenêtres ; `--creation=3` l'écran de création à l'étape 3 ; `--grotte=veine` (ou `puits`, `galerie`, `inondee`, `camp`, `gouffre`, `lea`, `bouche`) une salle de la grotte.
