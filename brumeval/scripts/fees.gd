# Les Gens de la Brume (univers.md, « Les vieilles croyances de la Brume » : la Brume est
# vivante, elle guide ceux qu'elle aime et « prend » ceux qui lui manquent de respect).
#
# Brumelle, la Dame de la Source : une fée adulte et très ancienne, à la Source chaude des Fées,
# visible à l'aube (5 h – 8 h) et au crépuscule (19 h – 22 h). Sa faveur, c'est son affection
# (relations) : les offrandes la font monter, le mépris la fait tomber.
#   - faveur 30 : sa bénédiction pour la journée (une chance de rejouer un coup raté en combat) ;
#   - faveur 50 : dans le bois, la Brume t'écarte des bêtes ;
#   - faveur 70 : elle peut choisir de te suivre (un pacte, pas une capture : on ne dompte pas
#     un être qui pense) ;
#   - faveur −30 : la Brume t'égare dans le bois.
# Une fée est une personne : l'intime suit les mêmes règles qu'avec n'importe quel adulte.
class_name Fees
extends RefCounted

const ID := "FEE001"
## Les trois sœurs de la Brume : Brumelle à la source, Lirelle à l'étang, Mousse à la clairière.
const SOEURS := {
	"FEE002": {"nom": "Lirelle", "lieu": "etang", "role": "Dame de l'Étang", "parole": "« Les noyés ? Ils voulaient voir de plus près. »",
		"affinites_fortes": "eau 70, ombre 50, esprit 60"},
	"FEE003": {"nom": "Mousse", "lieu": "clairiere", "role": "Dame de la Clairière", "parole": "« Tu sens le pain et la fumée. J'aime bien. »",
		"affinites_fortes": "nature 85, air 50, esprit 50"},
}
const DONNEES := {
	"id": ID, "nom": "Brumelle", "lieu": "Brumeval", "age": "900", "sexe": "femme", "peuple": "fée",
	"lignee": "Gens de la Brume", "statut_social": "libre, esprit du bois", "role": "Dame de la Source",
	"classe": "Mage de l'eau et des marées", "niveau_classe": "20", "metier": "—", "niveau_metier": "—",
	"For": "6", "Agi": "16", "End": "8", "Vit": "9", "Rob": "6", "Int": "14", "Sag": "18", "Per": "16", "Vol": "15",
	"affinites_fortes": "eau 80, nature 70, esprit 60",
	"traits": "sociable +30, honnete +60, colerique +20, courageux +10, curieux +80, rancunier +70, pieux -50",
	"profil_intime": "Fée adulte, très ancienne : attirée par les hommes et les femmes, libre comme la brume",
	"relations": "la Brume elle-même ; Agnès laisse du pain sur la pierre",
	"parole": "« Tu marches fort, pour quelqu'un qui ne sait pas où il est. »",
}
const EMPLOI := [[0.0, "source", "dort dans la brume"], [5.0, "source", "danse dans la vapeur"], [8.0, "source", "dort dans la brume"],
	[19.0, "source", "chante au-dessus de l'eau"], [22.0, "source", "dort dans la brume"]]


static func installer(m: Node) -> void:
	if not m.lieux.has("source") or m._pnj_par_id(ID) != null:
		return
	_ajouter(m, ID, DONNEES.duplicate(), EMPLOI)
	for id in SOEURS:
		var d: Dictionary = DONNEES.duplicate()
		d.merge(SOEURS[id], true)
		d.id = id
		var emploi := EMPLOI.map(func(e): return [e[0], SOEURS[id].lieu, e[2]])
		_ajouter(m, id, d, emploi)


static func _ajouter(m: Node, id: String, d: Dictionary, emploi: Array) -> void:
	var n := preload("res://scripts/pnj.gd").new()
	n.monde = m
	n.id = id
	n.donnees = d
	n.emploi = emploi
	m.add_child(n)
	m.pnjs.append(n)


static func faveur(m: Node) -> int:
	return int(m.relations.get(ID, 0))


## La faveur de la Brume est partagée : ce que tu fais à l'une, les trois sœurs le savent.
static func changer(m: Node, d: int) -> void:
	for id in [ID] + SOEURS.keys():
		m.relations[id] = clampi(int(m.relations.get(id, 0)) + d, -100, 100)
	m.sauver_etat()


## Une offrande : un pain sur la pierre, des mûres, un poisson. Une fois par jour compte double.
static func offrande(m: Node, texte: String) -> String:
	var premier: bool = not m.fiche.drapeaux.has("offrande_%d" % Horloge.jour())
	m.fiche.drapeaux["offrande_%d" % Horloge.jour()] = true
	changer(m, 8 if premier else 2)
	return texte + (" La brume s'épaissit un instant, comme un remerciement." if premier else " La pierre en a déjà eu aujourd'hui.")


static func benir(m: Node) -> String:
	if faveur(m) < 30:
		return "Brumelle te regarde de très loin : « Pourquoi le ferais-je ? » (faveur 30)"
	m.fiche.drapeaux["benie_%d" % Horloge.jour()] = true
	return "Brumelle souffle sur ton front. Une fraîcheur, une odeur de mousse. Aujourd'hui, la Brume veille sur toi : un coup raté, en combat, pourra se rejouer."


static func beni(m: Node) -> bool:
	return m.fiche.drapeaux.has("benie_%d" % Horloge.jour())


static func mepris(m: Node) -> String:
	changer(m, -30)
	return "Tu ris de la « fée ». La vapeur se glace. Brumelle ne dit rien ; la brume, elle, s'en souviendra (-30)."


## Dans le bois : la Brume t'écarte des bêtes si elle t'aime, t'égare si elle te hait.
static func dans_le_bois(m: Node) -> String:
	var f := faveur(m)
	if f <= -30 and not m.fiche.drapeaux.has("egare_%d" % Horloge.jour()) and randf() < 0.15:
		m.fiche.drapeaux["egare_%d" % Horloge.jour()] = true
		var cibles := ["clairiere", "ruines", "etang", "roncier", "loups"].filter(func(k): return m.lieux.has(k))
		var cle: String = cibles.pick_random()
		var p: Vector2 = m.lieux[cle].pos + Vector2(3, 3)
		m.joueur.position = Vector3(p.x, m.hauteur(p.x, p.y), p.y)
		Horloge.avancer(90.0)
		return "La brume se lève d'un coup, blanche, épaisse. Tu marches longtemps. Quand elle se dissipe, tu es à %s, et une heure et demie a passé." % m.lieux[cle].nom
	return ""


static func protege(m: Node) -> bool:
	return faveur(m) >= 50
