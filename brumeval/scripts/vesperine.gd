# Vesperine (monde/demons/vesperine.md), et la nuit du jour 1
# (monde/chronique/joueur/jour_001_avec_joueur.md, « La nuit : Vesperine »).
#
# Sans le joueur : 21 h 30 Bouche de mer, 21 h 45 elle mange des algues, 22 h 30 la falaise,
# 23 h 10 elle descend vers la crique, 23 h 20 Silas la voit, 23 h 30 la drogue et le collier :
# capturée, vendue à Pierrefane le lendemain.
# Avec le joueur : la nourrir, la guider ailleurs (la crique n'a jamais lieu), ou, à la crique,
# intervenir en parlant, faire diversion, se battre. Libre, elle vit cachée et c'est une adulte
# comme les autres. Captive, rien d'intime : elle ne peut pas consentir.
# Tant qu'elle a faim et peur (« detresse »), rien d'intime non plus.
class_name Vesperine
extends RefCounted

const ID := "VES019"
const DONNEES := {
	"id": ID, "nom": "Vesperine", "lieu": "Brumeval", "age": "140", "sexe": "femme", "peuple": "démon",
	"lignee": "succube", "statut_social": "libre, de passage", "role": "Éclaireuse de la reine démone",
	"classe": "Mage d'illusion", "niveau_classe": "24", "metier": "Espionne", "niveau_metier": "30",
	"For": "8", "Agi": "14", "End": "9", "Vit": "10", "Rob": "8", "Int": "15", "Sag": "12", "Per": "14", "Vol": "13",
	"affinites_fortes": "ombre 70, esprit 60, sang 40",
	"traits": "sociable +70, honnete -40, colerique -20, courageux +40, curieux +90",
	"profil_intime": "Succube : attirée par les hommes et les femmes, se sert de la séduction comme d'une arme, libre",
	"relations": "ennemie de Silas (BRU003) s'il l'a vue, méfiante envers les humains",
	"parole": "« Je viens du sud. Mon bateau a coulé. »",
	"detresse": "1",
}
const NUIT_1 := [[0.0, "bouche", "nuit en mer"], [21.5, "bouche", "débarque, épuisée"], [21.75, "bouche", "mange des algues crues"],
	[22.5, "falaise", "longe la falaise vers les lumières"], [23.15, "crique", "descend vers la crique"]]
const LIBRE := [[0.0, "agnes", "dort chez Agnès"], [8.0, "falaise", "guette la mer"], [13.0, "chene", "se cache au bois"],
	[18.0, "guet", "attend des lanternes au large"], [22.0, "agnes", "dort chez Agnès"]]


static func etat(m: Node) -> String:
	var e: String = m.fiche.drapeaux.get("vesperine", "")
	if e == "" and Horloge.jour() > 1:
		return "capturee"   # personne n'était là cette nuit-là
	return e


static func noeud(m: Node) -> Node:
	return m._pnj_par_id(ID)


## À l'ouverture du monde : elle est là le soir du jour 1, ou libre ensuite.
static func installer(m: Node) -> void:
	var e := etat(m)
	if e in ["capturee", "rachetee"] or noeud(m) != null:   # vendue, ou rachetée à Pierrefane (biens.gd)
		return
	var n := preload("res://scripts/pnj.gd").new()
	n.monde = m
	n.id = ID
	n.donnees = DONNEES.duplicate()
	if e == "libre":
		n.donnees.detresse = "0" if Horloge.jour() > 1 or m.fiche.drapeaux.get("vesperine_nourrie", false) else "1"
		n.emploi = LIBRE
	else:
		n.emploi = NUIT_1
	m.add_child(n)
	m.pnjs.append(n)


## Toutes les secondes : la crique à 23 h 20 si tu y es, sinon la capture à 23 h 30.
static func surveiller(m: Node) -> void:
	if noeud(m) == null or Horloge.jour() != 1 or etat(m) in ["libre", "capturee", "combat"]:
		return
	var h: float = Horloge.heure()
	if h >= 23.333 and not m.fiche.drapeaux.has("vesperine_choix"):
		var crique: Vector2 = m.lieux.crique.pos
		if m.joueur.pos2d().distance_to(crique) < 40.0 and m.fenetres.ouvert == "" and not Illustrations.ouvert:
			m.fiche.drapeaux["vesperine_choix"] = true
			a_la_crique(m)
			return
	if h >= 23.5 and not m.fiche.drapeaux.has("vesperine_choix"):
		capturer(m, "")


static func capturer(m: Node, texte: String) -> void:
	m.fiche.drapeaux["vesperine"] = "capturee"
	var n := noeud(m)
	if n:
		m.pnjs.erase(n)
		n.queue_free()
	m.fiche.sauver()
	if texte != "":
		Illustrations.montrer("vesperine_capturee", [ID], texte)


static func liberer(m: Node, texte: String) -> void:
	m.fiche.drapeaux["vesperine"] = "libre"
	var n := noeud(m)
	if n:
		n.emploi = LIBRE
		n.donnees.detresse = "0" if m.fiche.drapeaux.get("vesperine_nourrie", false) else "1"
	m.relations["BRU012"] = clampi(m.relations.get("BRU012", 0) + 10, -100, 100)   # Lucas, qui a refusé d'y toucher
	m.sauver_etat()
	m.fiche.sauver()
	if texte != "":
		Illustrations.montrer("vesperine_libre", [ID], texte)


## La nourrir (un pain ou un poisson) : elle dévore, et lit ce que tu lui veux.
static func nourrir(m: Node) -> String:
	var n := noeud(m)
	m.fiche.drapeaux["vesperine_nourrie"] = true
	m.relations[ID] = clampi(m.relations.get(ID, 0) + 25, -100, 100)
	var t := "Elle dévore sans un mot, les yeux dans les tiens. Ces yeux-là lisent quelque chose en toi."
	if m.fiche.desir >= 70:
		m.relations[ID] = clampi(m.relations.get(ID, 0) - 10, -100, 100)
		t += " Elle a lu que tu la veux. Elle te remercie, mais elle garde ses distances."
	else:
		t += " Ce qu'elle y lit la rassure un peu."
	if etat(m) == "libre" and n:
		n.donnees.detresse = "0"
	m.sauver_etat()
	return t


## La guider ailleurs (chez Agnès) : elle ne passe pas par la crique.
static func guider(m: Node) -> String:
	if m.relations.get(ID, 0) < 20:
		return "Elle recule : « Je ne te connais pas. » Elle a faim, elle a peur, elle va vers les lumières."
	liberer(m, "")
	var n := noeud(m)
	if n:
		n.donnees.detresse = "0" if m.fiche.drapeaux.get("vesperine_nourrie", false) else "1"
	return "Elle te suit jusque chez Agnès, qui met de l'eau à chauffer sans poser de questions. La crique, cette nuit, n'aura pas sa marchandise."


## À la crique, 23 h 20 : les choix.
static func a_la_crique(m: Node) -> void:
	var silas: Node = m._pnj_par_id("BRU003")
	var texte := "Silas et Lucas déchargent des tonneaux. Vesperine sort des rochers, trempée. Silas la regarde comme une marchandise : « Tiens. La mer nous fait des cadeaux, ce soir. »"
	Illustrations.montrer("vesperine_crique", [ID], texte)
	await Illustrations.ferme
	m.fenetres.choix("La crique, 23 h 20", texte, [
		["Intervenir en parlant", _parler.bind(m), "« Elle est avec moi. » Int et Per contre la méfiance de Silas."],
		["Faire diversion", _diversion.bind(m), "Une pierre, un cri : « La garde ! » Agi. Elle fuit dans le noir, Silas ne sait pas que c'est toi."],
		["Te battre contre Silas", _battre.bind(m, silas), "Voleur niveau 18. Lucas ne se battra pas pour lui. Très dur au niveau 1."],
		["Regarder caché, sans rien faire", _regarder.bind(m), "Comme si tu n'étais pas là. Mais tu auras vu."]])


static func _parler(m: Node) -> void:
	var t: Dictionary = m.fiche.stats_totales()
	var bonus := 5 if "seduction" in m.fiche.competences() else 0
	var moi: int = t.Int + t.Per + bonus + randi_range(1, 20)
	var lui: int = 30 + randi_range(1, 20)
	m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) - 20, -100, 100)
	if moi >= lui:
		liberer(m, "Silas te jauge longtemps, puis crache dans le sable : « Garde-la, ta noyée. Mais je me souviendrai de ta tête. » (%d contre %d)" % [moi, lui])
	else:
		capturer(m, "Silas sourit : « Prouve-le. » Tu n'as rien à prouver. Lucas recule, Silas sort la fiole. La drogue, le collier. (%d contre %d)" % [moi, lui])


static func _diversion(m: Node) -> void:
	var moi: int = m.fiche.stats_totales().Agi + randi_range(1, 20)
	var seuil := 22 + randi_range(1, 8)
	if moi >= seuil:
		liberer(m, "Ta pierre claque sur les rochers, ton cri porte : « La garde ! » Silas et Lucas filent avec les tonneaux. Vesperine disparaît dans le noir. Tu la retrouveras à l'aube, chez Agnès.")
	else:
		m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) - 15, -100, 100)
		capturer(m, "Ta pierre roule dans le vide. Silas lève sa lanterne vers toi, puis se retourne vers elle. Trop tard.")


static func _battre(m: Node, silas: Node) -> void:
	m.fiche.drapeaux["vesperine"] = "combat"
	m.combat_contre_pnj(silas, "mortel", {"vesperine": true})


static func _regarder(m: Node) -> void:
	m.fiche.drapeaux["temoin_crique"] = true
	capturer(m, "La drogue, le collier de fer froid. Lucas recule : « Je touche pas à ça. » Silas : « Personne la cherchera. » Tu as tout vu. Ça pèsera, un jour, devant un juge.")


## Après le combat contre Silas à la crique.
static func apres_combat(m: Node, resultat: String) -> void:
	if resultat == "victoire":
		liberer(m, "Silas recule dans le noir en tenant son bras. Vesperine te regarde, incrédule : « Pourquoi ? » Puis elle te suit.")
	else:
		capturer(m, "Quand tu reprends tes esprits, la crique est vide. Ils l'ont emmenée.")
