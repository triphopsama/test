# Un combattant : ses valeurs de combat tirées des caractéristiques (combat.md, section 2).
class_name Combattant
extends RefCounted

const STATS := ["For", "Agi", "End", "Vit", "Rob", "Int", "Sag", "Per", "Vol"]

const ARMES := {
	"poings": {"nom": "poings", "degats": 2, "portee": 1, "stat": "For"},
	"lutte": {"nom": "poings de lutteur", "degats": 5, "portee": 1, "stat": "For"},
	"dague": {"nom": "lame cachée", "degats": 5, "portee": 1, "stat": "Agi", "crit": 10, "objet": "OBJ002"},
	"marteau": {"nom": "marteau de forge", "degats": 12, "portee": 1, "stat": "For"},
	"epee": {"nom": "épée courte", "degats": 8, "portee": 1, "stat": "For", "objet": "OBJ007"},
	"masse": {"nom": "masse", "degats": 7, "portee": 1, "stat": "For"},
	"arc": {"nom": "arc de chasse", "degats": 8, "portee": 6, "stat": "Agi", "objet": "OBJ072"},
	"baton": {"nom": "bâton", "degats": 4, "portee": 1, "stat": "For"},
	"crocs": {"nom": "crocs", "degats": 4, "portee": 1, "stat": "Agi"},
	"dents": {"nom": "dents", "degats": 3, "portee": 1, "stat": "Agi"},
	"pinces": {"nom": "pinces", "degats": 8, "portee": 1, "stat": "For"},
	"defenses": {"nom": "défenses", "degats": 7, "portee": 1, "stat": "For"},
}

## Les compétences (noms et chiffres repris de monde/donnees/competences).
## mult × stat s'ajoute aux dégâts de l'arme. cond : caractéristiques minimales ;
## arme : catégorie d'arme nécessaire (dague, arc, lance, bouclier, poings).
## type : attaque (par défaut), soi (sur soi), allies (autour de soi), soin,
## passif (toujours actif), hors_combat (s'utilise dans le village, ou plus tard).
const COMPETENCES := {
	"frappe_lourde": {"nom": "Frappe lourde", "mult": 1.5, "stat": "For", "endurance": 10, "cond": {"For": 10},
		"desc": "Un coup appuyé : 1,5 × For."},
	"tir_precis": {"nom": "Tir précis", "mult": 1.2, "stat": "Agi", "endurance": 8, "toucher": 20, "cond": {"Per": 10}, "arme": "arc",
		"desc": "Un tir appliqué : 1,2 × Agi, +20 % pour toucher."},
	"coup_sournois": {"nom": "Coup sournois", "mult": 1.3, "stat": "Agi", "endurance": 8, "crit": 25, "cond": {"Agi": 10}, "arme": "dague",
		"desc": "La lame là où ça fait mal : 1,3 × Agi, +25 % de critique."},
	"prise": {"nom": "Prise de lutte", "mult": 0.8, "stat": "For", "endurance": 8, "etat": "renverse", "resiste": "For", "cond": {"For": 8},
		"desc": "Saisir et faire tomber : 0,8 × For, renverse (For contre For)."},
	"coup_bouclier": {"nom": "Coup de bouclier", "mult": 0.6, "stat": "For", "endurance": 8, "etat": "etourdi", "resiste": "Rob", "cond": {"Rob": 8}, "arme": "bouclier",
		"desc": "Le bouclier en plein visage : 0,6 × For, étourdit (contre Rob)."},
	"morsure": {"nom": "Morsure", "mult": 1.2, "stat": "Agi", "endurance": 6, "etat": "saignement", "resiste": "Vit"},
	"soin": {"nom": "Soin", "type": "soin", "soin": 2.0, "stat": "Sag", "mana": 8, "portee": 3},
	"charge": {"nom": "Charge", "mult": 1.3, "stat": "For", "endurance": 8, "etat": "renverse", "resiste": "Rob", "cond": {"For": 10, "End": 8},
		"desc": "Foncer dans le tas : 1,3 × For, renverse (contre Rob)."},
	# Guerrier
	"parade": {"nom": "Parade", "type": "passif", "cond": {"Agi": 6},
		"desc": "30 % de chances de parer un coup au corps à corps : il ne fait que 30 % des dégâts."},
	"cri_guerre": {"nom": "Cri de guerre", "type": "allies", "zone": 2, "endurance": 5, "etat_allies": "galvanise", "duree": 3, "cond": {"Vol": 8},
		"desc": "Les alliés à 2 cases font +10 % de dégâts pendant 3 tours."},
	# Lutteur
	"coup_tete": {"nom": "Coup de tête", "mult": 0.8, "stat": "For", "endurance": 3, "etat": "etourdi", "resiste": "Rob", "recul": 0.1,
		"desc": "0,8 × For, peut étourdir ; ça fait mal aussi à celui qui le donne."},
	"projection": {"nom": "Projection", "mult": 1.0, "stat": "For", "endurance": 7, "etat": "renverse", "resiste": "For", "cond": {"For": 12},
		"desc": "Soulever et jeter au sol : 1,0 × For, renverse (For contre For)."},
	# Garde
	"bouclier_leve": {"nom": "Lever le bouclier", "type": "soi", "endurance": 4, "etat_soi": "garde", "cond": {"Rob": 8}, "arme": "bouclier",
		"desc": "Jusqu'à ton prochain tour, -40 % de dégâts reçus de face."},
	"provocation": {"nom": "Provocation", "type": "provoquer", "portee": 3, "endurance": 4, "resiste": "Vol", "stat": "Vol", "cond": {"Vol": 8},
		"desc": "La cible (à 3 cases) doit s'en prendre à toi à son prochain tour (Vol contre Vol)."},
	# Lancier
	"allonge": {"nom": "Allonge", "mult": 1.0, "stat": "For", "endurance": 4, "portee": 2, "cond": {"Agi": 8}, "arme": "lance",
		"desc": "Frapper à 2 cases : 1,0 × For."},
	"mur_piques": {"nom": "Mur de piques", "type": "soi", "endurance": 5, "etat_soi": "piques", "cond": {"Vol": 10}, "arme": "lance",
		"desc": "Jusqu'à ton prochain tour, qui t'attaque de face au corps à corps prend 0,5 × ta For."},
	# Duelliste
	"pas_de_cote": {"nom": "Pas de côté", "type": "passif", "cond": {"Agi": 8},
		"desc": "20 % de chances d'esquiver un coup au corps à corps."},
	"feinte": {"nom": "Feinte", "mult": 0.8, "stat": "Agi", "endurance": 4, "toucher": 30, "imparable": true, "cond": {"Int": 8, "Agi": 10},
		"desc": "Tromper la garde : 0,8 × Agi, +30 % pour toucher, ni parade ni bouclier."},
	"riposte": {"nom": "Riposte", "type": "passif", "cond": {"Agi": 12},
		"desc": "Quand un coup au corps à corps te rate, tu frappes aussitôt : 1,0 × Agi."},
	# Moine
	"poings_de_fer": {"nom": "Poings de fer", "type": "passif", "cond": {"Rob": 8},
		"desc": "À mains nues, tes poings comptent comme des masses (6 dégâts)."},
	"souffle": {"nom": "Souffle intérieur", "type": "soi", "etat_soi": "concentre", "cond": {"Vol": 10},
		"desc": "Regagne 20 % d'endurance et 10 % de mana ; ton prochain coup fait +30 %."},
	"esquive_parfaite": {"nom": "Esquive parfaite", "type": "passif", "cond": {"Agi": 14},
		"desc": "Une fois par combat, annule entièrement un coup qui t'aurait touché."},
	# Mercenaire
	"toutes_armes": {"nom": "Toutes armes", "type": "passif",
		"desc": "À l'aise avec n'importe quelle arme : +5 % pour toucher."},
	"pillage": {"nom": "Pillage", "type": "passif", "cond": {"Per": 8},
		"desc": "Après une victoire, +50 % d'argent et plus de butin."},
	"dernier_debout": {"nom": "Dernier debout", "type": "passif", "cond": {"End": 12},
		"desc": "Une fois par combat, quand tu es le dernier de ton camp debout et à moins de 30 % de vie, tu remontes à 30 %."},
	# Archer
	"volee": {"nom": "Volée", "mult": 0.7, "stat": "Per", "endurance": 6, "portee": 5, "zone": 1, "cond": {"Agi": 10}, "arme": "arc",
		"desc": "Une volée de flèches : 0,7 × Per sur la cible et chaque ennemi collé à elle."},
	"tir_oeil": {"nom": "Tir dans l'œil", "mult": 1.5, "stat": "Per", "endurance": 8, "toucher": -10, "crit": 30, "cond": {"Per": 16}, "arme": "arc",
		"desc": "Viser l'œil : 1,5 × Per, +30 % de critique, mais -10 % pour toucher."},
	# Lanceur
	"couteaux": {"nom": "Couteaux de lancer", "mult": 0.6, "stat": "Agi", "endurance": 4, "portee": 4, "coups": 2, "cond": {"Agi": 8}, "arme": "dague",
		"desc": "Deux lames lancées à 4 cases : 0,6 × Agi chacune."},
	"javelot": {"nom": "Javelot", "mult": 1.0, "stat": "For", "endurance": 5, "portee": 4, "cond": {"For": 8}, "arme": "lance",
		"desc": "Lancer sa lance à 4 cases : 1,0 × For."},
	"pluie_lames": {"nom": "Pluie de lames", "mult": 0.6, "stat": "Agi", "endurance": 8, "portee": 4, "zone": 1, "cond": {"Agi": 14}, "arme": "dague",
		"desc": "Des lames partout : 0,6 × Agi sur la cible et chaque ennemi collé à elle."},
	# Voleur
	"vol_tire": {"nom": "Vol à la tire", "type": "hors_combat", "cond": {"Agi": 8},
		"desc": "Dans le village : « Voler à la tire » sur quelqu'un. Réussir dépend de ton Agi ; être pris, de ceux qui regardent."},
	"crochetage": {"nom": "Crochetage", "type": "hors_combat", "cond": {"Agi": 10},
		"desc": "« Crocheter une serrure » à la maison de la falaise ou au comptoir de Silas, une fois par jour. Agi, et gare aux témoins."},
	# Éclaireur
	"camouflage": {"nom": "Camouflage", "type": "soi", "endurance": 4, "etat_soi": "cache", "duree": 2, "cond": {"Agi": 8},
		"desc": "Disparaître : on ne peut plus te viser de loin, et ton prochain coup compte comme dans le dos."},
	"course_longue": {"nom": "Course longue", "type": "passif", "cond": {"End": 10},
		"desc": "+1 case de déplacement."},
	"pistage": {"nom": "Pistage", "type": "hors_combat", "cond": {"Per": 8},
		"desc": "« Suivre des traces » dans le bois ou les landes : tu trouves un loup isolé ou un sanglier avant qu'il ne te trouve (Per)."},
	# Chasseur de monstres
	"point_faible": {"nom": "Point faible", "mult": 1.2, "stat": "Per", "endurance": 5, "crit": 15, "vs_betes": true, "cond": {"Per": 12},
		"desc": "Contre une bête : 1,2 × Per, sa défense compte moitié, +15 % de critique."},
	"trophee": {"nom": "Trophée", "type": "passif",
		"desc": "+25 % d'expérience contre les bêtes."},
	"piege": {"nom": "Piège", "type": "hors_combat", "cond": {"Int": 8},
		"desc": "« Poser ou relever des pièges » dans le bois : des collets aujourd'hui, de la viande ou une peau demain (Int)."},
	# Rôdeur
	"soin_bois": {"nom": "Soin des bois", "type": "soin", "soin": 1.0, "stat": "Sag", "endurance": 6, "portee": 1, "cond": {"Sag": 8},
		"desc": "Des herbes sur la plaie : soigne un allié à côté (ou toi) de 1,0 × Sag. Marche aussi hors combat."},

	# ---- la magie (combat.md : les sorts touchent toujours ; dégâts = mult × stat × affinité,
	# réduits par la défense magique, multipliés par le facteur élémentaire de la cible)
	# Mage élémentaire
	"flamme": {"nom": "Flamme", "magique": true, "element": "feu", "mult": 1.0, "stat": "Int", "mana": 4, "portee": 4,
		"etat": "brulure", "resiste": "Vit", "desc": "Une flamme dans la paume, lancée à 4 cases : 1,0 × Int de feu, peut brûler. Hors combat : « Faire un feu de camp » (+25 % PV, une fois par jour)."},
	"bourrasque": {"nom": "Bourrasque", "magique": true, "element": "air", "mult": 0.7, "stat": "Int", "mana": 6, "portee": 3, "cond": {"Int": 8},
		"etat": "renverse", "resiste": "For", "desc": "Un coup de vent : 0,7 × Int d'air à 3 cases, renverse (contre For)."},
	"boule_feu": {"nom": "Boule de feu", "magique": true, "element": "feu", "mult": 1.3, "stat": "Int", "mana": 10, "portee": 5, "zone": 1, "cond": {"Int": 10},
		"etat": "brulure", "resiste": "Vit", "desc": "1,3 × Int de feu sur la cible et tout ce qui la touche, peut brûler."},
	"eclat_glace": {"nom": "Éclat de glace", "magique": true, "element": "glace", "mult": 1.1, "stat": "Int", "mana": 7, "portee": 5, "cond": {"Int": 10},
		"etat": "gel", "resiste": "Rob", "desc": "1,1 × Int de glace à 5 cases, peut geler (déplacement -2, vitesse -30 %)."},
	# Mage de soin
	"soin_leger": {"nom": "Soin léger", "type": "soin", "magique": true, "element": "lumière", "soin": 1.5, "stat": "Sag", "mana": 6, "portee": 3, "cond": {"Sag": 8},
		"desc": "Soigne un allié à 3 cases (ou toi) de 1,5 × Sag. Hors combat : se soigner, ou soigner quelqu'un (il t'en sait gré)."},
	"purification": {"nom": "Purification", "type": "purifier", "magique": true, "element": "lumière", "stat": "Sag", "mana": 6, "portee": 3, "cond": {"Sag": 10},
		"desc": "Chasse brûlure, gel, poison, saignement, aveuglement et malédiction d'un allié à 3 cases."},
	"soin_groupe": {"nom": "Soin de groupe", "type": "soin", "magique": true, "element": "lumière", "soin": 1.0, "stat": "Sag", "mana": 14, "zone_soi": 2, "cond": {"Sag": 14},
		"desc": "Soigne tous les alliés à 2 cases de toi (et toi) de 1,0 × Sag."},
	# Mage de l'eau et des marées
	"vague": {"nom": "Vague", "magique": true, "element": "eau", "mult": 0.9, "stat": "Int", "mana": 8, "portee": 4, "zone": 1, "cond": {"Sag": 10},
		"etat": "mouille", "desc": "0,9 × Int d'eau sur la cible et autour : mouillés (feu ×0,5, foudre ×1,5), les brûlures s'éteignent."},
	"respiration_eau": {"nom": "Respiration sous l'eau", "type": "hors_combat", "cond": {"Sag": 8}, "desc": "« Plonger » à la crique ou au port : des pièces perdues, parfois une carapace."},
	"lire_maree": {"nom": "Lire la marée", "type": "hors_combat", "cond": {"Per": 8}, "desc": "« Lire la marée » sur la côte : l'heure des basses mers, et une pêche meilleure dans les trois heures."},
	# Prêtre de combat
	"lumiere_pale": {"nom": "Lumière de la Pâle", "magique": true, "element": "lumière", "mult": 1.2, "stat": "Sag", "mana": 8, "portee": 4, "cond": {"Sag": 10},
		"etat": "aveugle", "resiste": "Per", "desc": "1,2 × Sag de lumière à 4 cases, peut aveugler (-40 % pour toucher)."},
	"benediction": {"nom": "Bénédiction", "type": "allies", "magique": true, "element": "lumière", "zone": 2, "mana": 6, "etat_allies": "inspire", "duree": 3, "cond": {"Sag": 8},
		"desc": "Les alliés à 2 cases sont inspirés : +10 % pour toucher pendant 3 tours. Hors combat : « Bénir » quelqu'un (les pieux adorent)."},
	"masse_sainte": {"nom": "Masse sainte", "mult": 1.0, "stat": "For", "endurance": 6, "cond": {"For": 8}, "element_bonus": "lumière",
		"desc": "Une frappe bénie : 1,0 × For, plus 0,3 × Sag de lumière."},
	# Envoûteur
	"malediction": {"nom": "Malédiction de faiblesse", "type": "maudire", "magique": true, "element": "mort", "stat": "Int", "mana": 6, "portee": 4,
		"etat": "affaibli", "resiste": "Vol", "cond": {"Int": 10}, "desc": "La cible ne fait plus que 70 % de ses dégâts pendant 3 tours (Vol contre Int)."},
	"mauvais_oeil": {"nom": "Mauvais œil", "type": "maudire", "magique": true, "element": "ombre", "stat": "Vol", "mana": 5, "portee": 4,
		"etat": "aveugle", "resiste": "Vol", "cond": {"Vol": 10}, "desc": "Un regard qui porte malheur : la cible est aveuglée 2 tours (Vol contre Vol)."},
	"poupee": {"nom": "Poupée", "type": "hors_combat", "cond": {"Int": 14}, "desc": "Maudire quelqu'un à distance avec une poupée et un cheveu (plus tard)."},
	# Enchanteur
	"arme_enflammee": {"nom": "Arme enflammée", "type": "soi", "magique": true, "element": "feu", "mana": 8, "etat_soi": "arme_feu", "duree": 3, "cond": {"Int": 10},
		"desc": "Ton arme brûle 3 tours : chaque coup ajoute 0,5 × Int de feu."},
	"rune_garde": {"nom": "Rune de garde", "type": "allies", "magique": true, "element": "terre", "zone": 1, "mana": 8, "etat_allies": "rune", "duree": 3, "cond": {"Int": 12},
		"desc": "Une rune sur toi et les alliés collés à toi : +10 de défense pendant 3 tours."},
	"lien_objet": {"nom": "Lien d'objet", "type": "hors_combat", "cond": {"Sag": 10}, "desc": "Lier un objet à soi : il revient à ta main (plus tard)."},

	# ---- l'intime (univers.md, « Désir et sexualité ») : entre adultes consentants
	"seduction": {"nom": "Séduction", "type": "hors_combat", "cond": {"Vol": 10, "Per": 8},
		"desc": "On te dit oui plus facilement (-10 d'affection demandée) et le plaisir monte plus vite. Silas, Élise l'enseignent."},
	"lecture_envies": {"nom": "Lecture des envies", "type": "hors_combat", "cond": {"Per": 12},
		"desc": "Demander à quelqu'un ce qu'il aime révèle tous ses goûts et toutes ses limites. Théo l'enseigne."},
	"massage": {"nom": "Massage", "type": "hors_combat", "cond": {"Agi": 8},
		"desc": "« Masser » quelqu'un : affection et désir montent ; en scène, le geste plaît davantage. Agnès l'enseigne."},
	"danse_lascive": {"nom": "Danse lascive", "type": "hors_combat", "cond": {"Agi": 12},
		"desc": "« Danser » à la taverne le soir : des pourboires, et le désir de ceux qui regardent monte. Élise l'enseigne."},
	"jeu_pouvoir": {"nom": "Jeu de pouvoir", "type": "hors_combat", "cond": {"Vol": 12},
		"desc": "Domination ou soumission consentie, avec un mot d'arrêt toujours respecté. Silas l'enseigne ; un pacte en tient lieu."},
	"discretion": {"nom": "Discrétion", "type": "hors_combat", "cond": {"Int": 8},
		"desc": "Tes nuits s'ébruitent moins (de 25 % à 10 %). Silas, Mouche l'enseignent."},
	"art_aimer": {"nom": "Art d'aimer", "type": "hors_combat",
		"desc": "Vient avec la première nuit ; monte d'un niveau toutes les trois nuits (jusqu'à 10) : +3 % de plaisir par niveau."},
}

## Les 12 éléments et leurs opposés (competences.md).
const OPPOSES := {"feu": ["eau", "glace"], "eau": ["feu"], "glace": ["feu"], "terre": ["air"], "air": ["terre"],
	"foudre": ["terre"], "lumière": ["ombre"], "ombre": ["lumière"], "nature": ["mort"], "mort": ["nature", "lumière"],
	"sang": ["lumière"], "esprit": []}
const AFFINITE_PAR_DEFAUT := 20
## Durée des états (en tours du porteur).
const DUREES := {"saignement": 99, "etourdi": 1, "renverse": 2, "brulure": 3, "gel": 3, "mouille": 3, "aveugle": 2, "affaibli": 3}
const NOMS_ETATS := {"renverse": "renversé", "etourdi": "étourdi", "saignement": "en sang", "brulure": "en feu", "gel": "gelé",
	"mouille": "trempé", "aveugle": "aveuglé", "affaibli": "affaibli"}
const ETATS_NEFASTES := ["brulure", "gel", "saignement", "poison", "aveugle", "affaibli", "etourdi"]

## La riposte, qui n'est pas dans le menu.
const RIPOSTE := {"nom": "riposte", "mult": 1.0, "stat": "Agi"}


var id := ""
var nom := ""
var camp := 0              # 0 : le camp du joueur, 1 : l'autre
var est_joueur := false
var est_bete := false
var stats := {}
var niveau := 1
var pv := 0
var pv_max := 0
var endurance := 0
var endurance_max := 0
var mana := 0
var mana_max := 0
var vitesse := 10
var deplacement := 3
var saut := 1
var def_phys := 0
var def_mag := 0
var bouclier := 0
var arme: Dictionary = ARMES.poings
var competences: Array = []
var case := Vector2i.ZERO
var orientation := Vector2i(0, 1)
var ct := 0.0
var etats := {}
var a_terre := false
var stable := false
var mort := false
var sorti := false         # a fui ou s'est rendu
var tours_saignement := 3
var ventre_mou := false      # crabe-rocher : de flanc ou de dos, la carapace ne protège plus
var bonus_toucher := 0       # Soldat : +5
var bonus_distance := 0      # Œil de tireur +10, Mauvaise vue -10
var increvable := false      # une fois : reste debout à 1 PV
var chance := 0              # +1 Chanceux (rejoue un raté), -1 Malchanceux (rejoue un réussi), une fois
var noeud: Node3D
var style := {}              # ce que le joueur a fait pendant le combat (pour lui proposer une classe)
var utilise := {}            # compétences une fois par combat déjà servies
var provoque_par: Combattant = null
var affinites := {}          # élément -> 0..100
var elements := {}           # bêtes : élément -> facteur de dégâts reçus (bestiaire)


## La catégorie d'une arme d'après son nom et sa portée : dague, arc, lance, poings ou for.
static func categorie_arme(arme: Dictionary) -> String:
	var n := str(arme.get("nom", "")).to_lower()
	if int(arme.get("portee", 1)) > 1 or n.contains("arc"):
		return "arc"
	for mot in ["dague", "couteau", "lame cachée"]:
		if n.contains(mot):
			return "dague"
	for mot in ["lance", "trident", "épieu", "pique"]:
		if n.contains(mot):
			return "lance"
	if n.contains("poing"):
		return "poings"
	return "for"


## Peut-on se servir de cette compétence avec ces caractéristiques, cette arme et ce bouclier ?
static func peut_utiliser(k: String, s: Dictionary, arme: Dictionary, bouclier: int) -> bool:
	var c: Dictionary = COMPETENCES.get(k, {})
	if c.is_empty():
		return false
	for st in c.get("cond", {}):
		if s.get(st, 0) < c.cond[st]:
			return false
	match str(c.get("arme", "")):
		"":
			return true
		"bouclier":
			return bouclier > 0
		var cat:
			return categorie_arme(arme) == cat


func affinite(e: String) -> int:
	return int(affinites.get(e, AFFINITE_PAR_DEFAUT))


## Puissance d'un sort selon l'affinité du lanceur : +1 % par point au-dessus de 50, -1 % sous 20.
func bonus_affinite(e: String) -> float:
	var a := affinite(e)
	return 1.0 + maxf(0, a - 50) / 100.0 - maxf(0, 20 - a) / 100.0


## Ce que coûte une compétence en mana : moins dans un élément aimé, double sous 10 d'affinité.
func cout_mana(comp: Dictionary) -> int:
	var m := int(comp.get("mana", 0))
	if m == 0 or not comp.has("element"):
		return m
	var a := affinite(comp.element)
	if a < 10:
		return m * 2
	return maxi(1, roundi(m * (1.0 - maxf(0, a - 50) / 200.0)))


## Ce que la cible prend d'un élément : les bêtes selon le bestiaire ; les gens résistent à leurs
## éléments forts (-0,5 % par point) et craignent l'opposé de ceux à 60 et plus (+25 %).
func facteur_element(e: String) -> float:
	if est_bete:
		return float(elements.get(e, 1.0))
	var f := 1.0 - affinite(e) * 0.005
	for fort in affinites:
		if int(affinites[fort]) >= 60 and e in OPPOSES.get(fort, []):
			f += 0.25
	return maxf(0.0, f)


func peut_payer(comp: Dictionary) -> bool:
	return endurance >= int(comp.get("endurance", 0)) and mana >= cout_mana(comp)


func a_comp(k: String) -> bool:
	return k in competences


## Les passifs qui changent les valeurs de combat (à appeler une fois les compétences connues).
func appliquer_passifs() -> void:
	if a_comp("poings_de_fer") and categorie_arme(arme) == "poings":
		arme = {"nom": "poings de fer", "degats": 6, "portee": 1, "stat": "For"}
	if a_comp("course_longue"):
		deplacement += 1
	if a_comp("toutes_armes"):
		bonus_toucher += 5


func _calculer() -> void:
	pv_max = 20 + stats.Vit * 8 + niveau * 4
	pv = pv_max
	mana_max = stats.Sag * 6 + stats.Int * 2
	mana = mana_max
	endurance_max = 20 + stats.End * 5
	endurance = endurance_max
	vitesse = 10 + stats.Agi
	deplacement = 3 + int(stats.Agi / 10.0)
	saut = 1 + int(stats.Agi / 15.0)
	def_phys += stats.Rob
	def_mag = stats.Vol * 2


static func depuis_pnj(d: Dictionary, n: Node3D) -> Combattant:
	var c := Combattant.new()
	c.id = d.id
	c.nom = d.nom
	c.noeud = n
	for s in STATS:
		c.stats[s] = int(d.get(s, "6"))
	c.niveau = maxi(1, int(d.get("niveau_classe", "1")))
	for morceau in str(d.get("affinites_fortes", "")).split(",", false):
		var m := morceau.strip_edges().split(" ", false)
		if m.size() == 2 and m[1].is_valid_int():
			c.affinites[m[0]] = int(m[1])
	var classe := str(d.get("classe", "")).to_lower()
	if classe.contains("archer"):
		c.arme = ARMES.arc
		c.competences = ["tir_precis"]
	elif classe.contains("voleu"):
		c.arme = ARMES.dague
		c.competences = ["coup_sournois"]
		c.def_phys = 4
	elif classe.contains("lutteu"):
		c.arme = ARMES.lutte
		c.competences = ["prise"]
	elif classe.contains("garde"):
		c.arme = ARMES.epee
		c.competences = ["coup_bouclier"]
		c.def_phys = 8
		c.bouclier = 15
	elif classe.contains("guerri"):
		c.arme = ARMES.marteau if c.id == "BRU002" else ARMES.epee
		c.competences = ["frappe_lourde"]
		c.def_phys = 4
	elif classe.contains("prêtre") or classe.contains("soin"):
		c.arme = ARMES.masse if classe.contains("prêtre") else ARMES.baton
		c.competences = ["soin"]
	# les PNJ suivent les mêmes règles : les compétences de leur classe, à leur niveau
	var id_classe := Classes.par_nom(str(d.get("classe", "")))
	for k in Classes.competences_jusqua(id_classe, c.niveau):
		if not k in c.competences and peut_utiliser(k, c.stats, c.arme, c.bouclier):
			c.competences.append(k)
	c._calculer()
	c.appliquer_passifs()
	return c


## Le joueur, tiré de sa fiche : caractéristiques avec les bonus portés, arme, armure, bouclier, PV actuels.
static func joueur(n: Node3D, f: Fiche = null) -> Combattant:
	var c := Combattant.new()
	c.id = "joueur"
	c.nom = "Toi"
	c.est_joueur = true
	c.noeud = n
	if f == null:
		f = Fiche.new()
	c.stats = f.stats_totales()
	c.niveau = f.niveau
	for e in f.equipement:
		var o := Objets.get_(f.equipement[e])
		c.def_phys += int(o.get("defense", "0"))
		c.bouclier += int(o.get("bouclier", "0"))
		if o.get("type", "") == "arme":
			c.arme = {"nom": o.nom, "degats": int(o.degats), "portee": int(o.portee), "stat": o.stat, "crit": int(o.crit), "objet": o.id}
	c.competences = f.competences()
	c.affinites = f.affinites.duplicate()
	c._calculer()
	c.mana_max = f.mana_max()
	c.mana = f.mana_actuelle()
	c.pv_max = f.pv_max()
	c.pv = clampi(f.pv, 1, c.pv_max)
	if f.a("rapide"):
		c.vitesse += 3
	c.bonus_toucher = 5 if f.vie == "soldat" else 0
	c.bonus_distance = (10 if f.a("tireur") else 0) - (10 if f.a("mauvaise_vue") and not f.equipe("BRV014") else 0)
	c.increvable = f.a("increvable")
	c.chance = (1 if f.a("chanceux") else 0) - (1 if f.a("malchanceux") else 0)
	c.appliquer_passifs()
	c.nom = f.nom if f.nom != "" else "Toi"
	return c


## Les bêtes de la côte (monde/bestiaire.md). armure : défense en plus de la Robustesse.
const BETES := {
	"loup": {"nom": "Loup gris", "niveau": 2, "arme": "crocs", "competences": ["morsure"], "planche": "res://sprites/loup_planche.png",
		"stats": {"For": 6, "Agi": 9, "End": 7, "Vit": 3, "Rob": 4, "Int": 1, "Sag": 2, "Per": 9, "Vol": 3}},
	"rat": {"nom": "Rat géant", "niveau": 1, "arme": "dents", "competences": [], "planche": "res://sprites/rat_planche.png", "elements": {"feu": 1.5, "lumière": 1.25},
		"stats": {"For": 3, "Agi": 7, "End": 4, "Vit": 1, "Rob": 2, "Int": 1, "Sag": 1, "Per": 6, "Vol": 2}},
	"crabe": {"nom": "Crabe-rocher", "niveau": 2, "arme": "pinces", "competences": [], "armure": 10, "ventre_mou": true, "elements": {"foudre": 1.5, "eau": 0.5, "feu": 0.75},
		"planche": "res://sprites/crabe_planche.png",
		"stats": {"For": 6, "Agi": 3, "End": 6, "Vit": 5, "Rob": 12, "Int": 1, "Sag": 1, "Per": 5, "Vol": 4}},
	"sanglier": {"nom": "Sanglier des ronces", "niveau": 3, "arme": "defenses", "competences": ["charge"], "planche": "res://sprites/sanglier_planche.png",
		"stats": {"For": 12, "Agi": 6, "End": 8, "Vit": 7, "Rob": 7, "Int": 1, "Sag": 2, "Per": 5, "Vol": 6}},
}


static func bete(type: String, i: int, n: Node3D) -> Combattant:
	var b: Dictionary = BETES[type]
	var c := Combattant.new()
	c.id = "%s%d" % [type, i]
	c.nom = b.nom + (" %d" % i if i > 0 else "")
	c.est_bete = true
	c.noeud = n
	c.niveau = b.niveau
	c.stats = b.stats.duplicate()
	c.arme = ARMES[b.arme]
	c.competences = b.competences.duplicate()
	c.def_phys = b.get("armure", 0)
	c.ventre_mou = b.get("ventre_mou", false)
	c.elements = b.get("elements", {})
	c._calculer()
	return c


static func loup(i: int, n: Node3D) -> Combattant:
	return bete("loup", i, n)


func en_jeu() -> bool:
	return not (a_terre or mort or sorti)


func etat_texte() -> String:
	if mort:
		return "mort"
	if sorti:
		return "hors du combat"
	if a_terre:
		return "stabilisé" if stable else "à terre (%d tours)" % tours_saignement
	var t := "%d/%d PV" % [pv, pv_max]
	if est_joueur and mana_max > 0:
		t += " · %d/%d mana" % [mana, mana_max]
	var visibles: Array = etats.keys().filter(func(e): return NOMS_ETATS.has(e)).map(func(e): return NOMS_ETATS[e])
	if not visibles.is_empty():
		t += " · " + ", ".join(visibles)
	return t
