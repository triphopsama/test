# Ta maison : la maison de la falaise (l'ancienne maison Marbre, au-dessus de la grotte).
# Ysolde Marbre en a hérité et n'en veut plus : elle te la vend, ou te la donne si elle t'aime bien.
# Puis tu la remets en état, étape par étape :
#   1 ruine      elle est à toi : la porte clouée, le plancher pourri, le vent partout
#   2 habitable  déblayée, une porte qui ferme, un toit : on y dort, on y loge son équipe
#   3 meublée    un lit, une table, un coffre : on y range ce qu'on ne porte pas
#   4 aménagée   une salle d'armes, un bain chaud, un enclos pour les bêtes
# Ceux qui vivent chez toi gardent leur travail ; ils dorment chez toi au lieu de chez eux.
# Les bêtes laissées à l'enclos ne prennent plus de place dans l'équipe.
# Images : illustrations/maison_<niveau>/ (1 à 4), et chaque action a son dossier.
class_name Maison
extends RefCounted

const LIEU := "falaise"
const PROPRIETAIRE := "BRU004"     # Ysolde Marbre
const PRIX := "8 argent"
const AFFECTION_DON := 50
const ACTIONS := ["maison_demander", "maison_travaux", "maison_dormir", "maison_coffre", "maison_inviter",
	"maison_renvoyer", "maison_betes", "maison_bain"]
## Les travaux : [nom, prix, heures, ce que ça change].
const TRAVAUX := {
	2: ["Déblayer, réparer la porte et le toit", "5 argent", 8, "On peut y dormir, et y loger ton équipe."],
	3: ["Meubler : un lit, une table, un coffre", "6 argent", 6, "Un vrai lit, et un coffre pour ce que tu ne portes pas."],
	4: ["Aménager : salle d'armes, bain chaud, enclos", "1 or", 10, "S'entraîner mieux, se délasser, garder les bêtes à l'enclos."],
}
const NOMS := ["", "une ruine", "habitable", "meublée", "aménagée"]


static func niveau(m: Node) -> int:
	return int(m.fiche.drapeaux.get("maison", 0))


static func habitants(m: Node) -> Array:
	return m.fiche.drapeaux.get("maison_habitants", [])


static func betes(m: Node) -> Array:
	return m.fiche.drapeaux.get("maison_betes", [])


static func coffre(m: Node) -> Dictionary:
	if not m.fiche.drapeaux.has("coffre"):
		m.fiche.drapeaux["coffre"] = {}
	return m.fiche.drapeaux["coffre"]


static func chez_toi(m: Node) -> bool:
	return m.carte == "brumeval" and niveau(m) >= 1 and m.lieu_proche(m.joueur.pos2d(), 40.0) == LIEU


# ---------------------------------------------------------------- au chargement

## Ceux qui vivent chez toi dorment à la falaise ; les bêtes de l'enclos y sont.
static func installer(m: Node) -> void:
	if m.carte != "brumeval" or not m.lieux.has(LIEU):
		return
	for n in m.pnjs:
		if n.id in habitants(m):
			loger(n)
	_poser_betes(m)


static func loger(n: Node) -> void:
	if not n.donnees.has("_emploi_chez_lui"):
		n.donnees["_emploi_chez_lui"] = n.emploi
	var chez_lui: String = n.donnees["_emploi_chez_lui"][0][1]
	# seulement les heures où il dort ou se repose chez lui : Mara vit au-dessus du fournil
	n.emploi = n.donnees["_emploi_chez_lui"].map(func(e): return [e[0], LIEU if e[1] == chez_lui and _repos(n, e[2]) else e[1], e[2]])
	n.maison = LIEU


static func _repos(n: Node, activite: String) -> bool:
	for mot in n.REPOS + ["dort", "dîne", "soir"]:
		if activite.to_lower().contains(mot):
			return true
	return false


static func reloger(n: Node) -> void:
	if n.donnees.has("_emploi_chez_lui"):
		n.emploi = n.donnees["_emploi_chez_lui"]
		n.maison = n.emploi[0][1]
		n.donnees.erase("_emploi_chez_lui")


static func _poser_betes(m: Node) -> void:
	for n in m.get_tree().get_nodes_in_group("betes_enclos"):
		n.queue_free()
	if niveau(m) < 4:
		return
	for b in betes(m):
		var n := preload("res://scripts/bete.gd").new()
		n.planche = Combattant.BETES[b.type].planche
		var p: Vector2 = m.lieux[LIEU].pos + Vector2(randf_range(6, 10), randf_range(-3, 3))
		n.position = Vector3(p.x, m.hauteur(p.x, p.y), p.y)
		n.add_to_group("betes_enclos")
		m.add_child(n)


# ---------------------------------------------------------------- les actions

static func dispo(m: Node, quoi: String, pnj: Node) -> bool:
	var nv := niveau(m)
	if m.carte != "brumeval":
		return false
	match quoi:
		"maison_demander":
			return pnj != null and pnj.id == PROPRIETAIRE and nv == 0
		"maison_travaux":
			return pnj == null and nv >= 1 and nv < 4
		"maison_dormir":
			return pnj == null and nv >= 2
		"maison_coffre":
			return pnj == null and nv >= 3
		"maison_bain":
			return pnj == null and nv >= 4
		"maison_betes":
			return pnj == null and nv >= 4 and not (m.fiche.betes.is_empty() and betes(m).is_empty())
		"maison_inviter":
			return pnj != null and nv >= 2 and not pnj.id in habitants(m) and int(pnj.donnees.get("age", "0")) >= 18 \
				and Liens.present(m, pnj.id) and not pnj.id in [Fees.ID] and not Fees.SOEURS.has(pnj.id)
		"maison_renvoyer":
			return pnj != null and pnj.id in habitants(m)
	return false


static func agir(m: Node, quoi: String, pnj: Node) -> String:
	var f: Fiche = m.fiche
	match quoi:
		"maison_demander":
			return demander(m, pnj)
		"maison_travaux":
			var nv := niveau(m) + 1
			var t: Array = TRAVAUX[nv]
			var aide: Node = m._pnj_par_id("BRU002")
			var avec_bram: bool = aide != null and not aide.mort and int(m.relations.get("BRU002", 0)) >= 30
			var heures: int = t[2] / 2 if avec_bram else t[2]
			m.fenetres.choix("Ta maison : %s" % NOMS[niveau(m)], "%s.\nPrix : %s · %d h de travail%s.\n%s" % [t[0], t[1], heures,
				" (Bram vient t'aider)" if avec_bram else "", t[3]], [
				["Faire les travaux (%s)" % t[1], faire_travaux.bind(m, heures, avec_bram), t[3]],
				["Plus tard", func(): pass, ""]])
			return ""
		"maison_dormir":
			Horloge.avancer(360.0)
			f.pv = f.pv_max()
			f.mana = f.mana_max()
			f.sauver()
			var qui: Array = habitants(m).map(func(id): return Donnees.prenom(str(m.pnj_donnees.get(id, {}).get("nom", id))))
			return "Chez toi. Le vent contre les volets, la mer en bas. Tu dors d'une traite%s. %d/%d PV." % [
				(", et la maison respire autour de toi : " + ", ".join(qui)) if qui else "", f.pv, f.pv_max()]
		"maison_coffre":
			m.fenetres.coffre()
			return ""
		"maison_bain":
			if f.drapeaux.get("bain_maison", -1) == Horloge.jour():
				return "L'eau du bain refroidit encore dans la cuve. Demain."
			f.drapeaux["bain_maison"] = Horloge.jour()
			Horloge.avancer(60.0)
			f.pv = f.pv_max()
			f.desir = mini(100, f.desir + 10)
			f.sauver()
			return "L'eau chaude, la vapeur, la mer par la lucarne. Tout se dénoue. %d/%d PV." % [f.pv, f.pv_max()]
		"maison_betes":
			var options := []
			for i in f.betes.size():
				options.append(["Laisser %s à l'enclos" % f.betes[i].nom, _enclos.bind(m, i), "Elle ne prend plus de place dans l'équipe."])
			for i in betes(m).size():
				options.append(["Reprendre %s" % betes(m)[i].nom, _reprendre.bind(m, i), "Elle te suit de nouveau."])
			options.append(["Rien", func(): pass, ""])
			m.fenetres.choix("L'enclos", "Tes bêtes.", options)
			return ""
		"maison_inviter":
			return inviter(m, pnj)
		"maison_renvoyer":
			var h: Array = habitants(m)
			h.erase(pnj.id)
			f.drapeaux["maison_habitants"] = h
			reloger(pnj)
			m.relations[pnj.id] = clampi(m.relations.get(pnj.id, 0) - 5, -100, 100)
			f.sauver()
			m.sauver_etat()
			return "{nom} rassemble ses affaires et rentre chez lui (-5)."
	return ""


## Demander la maison à Ysolde : un don si elle t'aime bien, sinon elle te la vend.
static func demander(m: Node, pnj: Node) -> String:
	var aff: int = m.relations.get(pnj.id, 0)
	if aff >= AFFECTION_DON:
		_devenir_proprietaire(m)
		return "Ysolde te tend une clé rouillée : « Prends-la. Mon grand-père y a fait des choses dont je ne veux plus entendre parler. Fais-en une maison, au lieu d'un tombeau. »"
	if aff < -10:
		return "Ysolde te toise : « La maison de mes pères ? À toi ? Non. »"
	m.fenetres.choix("La maison de la falaise", "Ysolde réfléchit : « Elle tombe en ruine, et personne n'en veut. %s, et elle est à toi. Les clous de la porte, tu les arracheras toi-même. »" % Objets.texte_prix(Objets.cuivre_de(PRIX)), [
		["Payer %s" % Objets.texte_prix(Objets.cuivre_de(PRIX)), _acheter.bind(m), "La clé, l'acte, et le vent qui siffle dans les volets."],
		["Plus tard", func(): pass, ""]])
	return ""


static func _acheter(m: Node) -> void:
	var c := Objets.cuivre_de(PRIX)
	if m.fiche.bourse < c:
		Illustrations.montrer("maison_demander_refus", [PROPRIETAIRE], "Tu comptes ta bourse. Il manque %s." % Objets.texte_prix(c - m.fiche.bourse))
		return
	m.fiche.bourse -= c
	_devenir_proprietaire(m)
	Illustrations.montrer("maison_1", [LIEU, "defaut"], "Ysolde compte les pièces, signe l'acte devant Aldric, et te tend une clé rouillée. La maison de la falaise est à toi. Une ruine, mais à toi.")


static func _devenir_proprietaire(m: Node) -> void:
	m.fiche.drapeaux["maison"] = 1
	m.fiche.drapeaux["maison_jour"] = Horloge.jour()
	if Horloge.jour() <= 5:
		m.fiche.drapeaux["maison_nina"] = true   # elle dort encore dans la cave
	m.fiche.sauver()
	m.reconstruire_maison()


static func faire_travaux(m: Node, heures: int, avec_bram: bool) -> void:
	var nv := niveau(m) + 1
	var c := Objets.cuivre_de(TRAVAUX[nv][1])
	if m.fiche.bourse < c:
		Illustrations.montrer("maison_travaux_refus", [LIEU], "Le bois, les clous, l'ardoise : il te manque %s." % Objets.texte_prix(c - m.fiche.bourse))
		return
	m.fiche.bourse -= c
	m.fiche.drapeaux["maison"] = nv
	Horloge.avancer(heures * 60.0)
	m.fiche.gagner_xp(5 * nv)
	if avec_bram:
		m.relations["BRU002"] = clampi(m.relations.get("BRU002", 0) + 5, -100, 100)
	m.fiche.sauver()
	m.sauver_etat()
	m.reconstruire_maison()
	_poser_betes(m)
	var textes := {
		2: "Les clous arrachés, les gravats sortis à la brouette, des ardoises neuves sur le toit. La porte ferme. Pour la première fois depuis trente ans, la maison de la falaise a de la lumière aux fenêtres.",
		3: "Un lit de Bram, une table du marché, un coffre ferré. Ça sent le bois neuf et la cire. Une maison, une vraie.",
		4: "Une salle d'armes dans l'ancien cellier, une cuve de cuivre pour le bain, un enclos contre le mur du jardin. Les Marbre n'ont jamais eu ça.",
	}
	var t: String = textes[nv] + (" Bram a porté les poutres sans un mot, puis a bu ta bière (+5)." if avec_bram else "")
	if nv == 2 and m.fiche.drapeaux.get("maison_nina", false):
		t += " Dans la cave, une couverture roulée et des arêtes de poisson : quelqu'un dormait là. Nina, sans doute."
	Illustrations.montrer("maison_%d" % nv, [LIEU, "defaut"], t)


## Lui proposer de vivre chez toi : quelqu'un de ton équipe, ou qui t'aime, et qui le veut.
static func inviter(m: Node, pnj: Node) -> String:
	var aff: int = m.relations.get(pnj.id, 0)
	var lie: bool = m.fiche.partenaires.has(pnj.id) or m.fiche.pactes.has(pnj.id) or pnj.suit
	if aff < (50 if lie else 70):
		return "{nom} sourit : « Vivre chez toi ? On n'en est pas là. » (affection %d, il en faudrait %d)" % [aff, 50 if lie else 70]
	var c := Liens.couple_de(m, pnj.id)
	if c != "" and not m.fiche.partenaires.has(pnj.id):
		return "{nom} secoue la tête : « Et %s ? Non. Ma maison, c'est avec lui. »" % Donnees.prenom(str(m.pnj_donnees.get(c, {}).get("nom", c)))
	var h: Array = habitants(m)
	h.append(pnj.id)
	m.fiche.drapeaux["maison_habitants"] = h
	loger(pnj)
	m.relations[pnj.id] = clampi(aff + 5, -100, 100)
	m.fiche.sauver()
	m.sauver_etat()
	return "{nom} pose son baluchon dans l'entrée de la maison de la falaise. « Bon. Je garde mon travail, mais le soir, c'est ici que je rentre. » (+5)"


static func _enclos(m: Node, i: int) -> void:
	var b: Dictionary = m.fiche.betes[i]
	m.fiche.betes.remove_at(i)
	var e: Array = betes(m)
	e.append(b)
	m.fiche.drapeaux["maison_betes"] = e
	m.fiche.sauver()
	Compagnons.installer_betes(m)
	_poser_betes(m)
	Illustrations.montrer("maison_betes", [b.type, LIEU], "%s renifle l'enclos, gratte la terre, et se couche au soleil." % b.nom)


static func _reprendre(m: Node, i: int) -> void:
	if Compagnons.occupees(m) >= Compagnons.places(m):
		Illustrations.montrer("maison_betes_refus", [LIEU], "Ton équipe est au complet.")
		return
	var e: Array = betes(m)
	var b: Dictionary = e[i]
	e.remove_at(i)
	m.fiche.drapeaux["maison_betes"] = e
	m.fiche.betes.append(b)
	m.fiche.sauver()
	Compagnons.installer_betes(m)
	_poser_betes(m)
	Illustrations.montrer("maison_betes", [b.type, LIEU], "%s bondit par-dessus la barrière et vient se coller à ta jambe." % b.nom)


## Le coffre : objets déposés (id -> nombre).
static func deposer(m: Node, id: String) -> void:
	var f: Fiche = m.fiche
	if f.nombre(id) <= 0:
		return
	if f.equipe(id) and f.nombre(id) <= 1:
		return
	f.retirer(id)
	coffre(m)[id] = int(coffre(m).get(id, 0)) + 1
	f.sauver()


static func reprendre(m: Node, id: String) -> void:
	var c := coffre(m)
	if int(c.get(id, 0)) <= 0:
		return
	c[id] = int(c[id]) - 1
	if c[id] <= 0:
		c.erase(id)
	m.fiche.ajouter(id)
	m.fiche.sauver()
