# Les défis que lancent les PNJ (data/defis.csv), et l'entraînement avec ton équipe.
#
# Colonnes de defis.csv :
#   pnj          qui lance le défi
#   type         bagarre (une lutte à mains nues contre lui), jet (ta caractéristique + 1d20
#                contre « parametres » + 1d20, ex. « For 18 »), apporter (rapporter « OBJ407 1 »
#                avant la fin du jour), intime (le combler « parametres » fois en une nuit ;
#                adultes consentants seulement, les mêmes règles que toute nuit)
#   propose      1 : il te le propose de lui-même quand tu passes près de lui (une fois par jour)
#   recompense, penalite  « affection 15, cuivre 6, objet OBJ002, lecon parade, art 3,
#                pacte maitre » (pacte : il te propose un pacte où tu mènes, s'il le veut aussi)
#   texte, texte_victoire, texte_echec   ce qu'il dit
# Images : illustrations/defi_<id>/, defi_<id>_victoire/, defi_<id>_echec/.
class_name Defis
extends RefCounted

static var _tous := {}


static func tous() -> Dictionary:
	if _tous.is_empty():
		for l in Donnees.lire_csv("res://data/defis.csv"):
			_tous[l.id] = l
	return _tous


static func _jour(m: Node, id: String) -> String:
	return "defi_%s_%d" % [id, Horloge.jour()]


## Les défis de ce PNJ qu'il peut te lancer aujourd'hui.
static func de(m: Node, n: Node) -> Array:
	var r := []
	for id in tous():
		var d: Dictionary = tous()[id]
		if d.pnj != n.id or m.fiche.drapeaux.has(_jour(m, id)) or m.fiche.defis_actifs.has(id):
			continue
		if d.type == "intime" and (Intime.profil(n.id).is_empty() or not m.actions.intime_possible(n)):
			continue
		if int(m.relations.get(n.id, 0)) < -20:
			continue
		r.append(d)
	return r


## Accepter : selon le type, ça se joue tout de suite, ou ça attend que tu rapportes, ou la nuit s'ouvre.
static func accepter(m: Node, n: Node, id: String) -> void:
	var d: Dictionary = tous()[id]
	m.fiche.drapeaux[_jour(m, id)] = true
	match d.type:
		"bagarre":
			m.combat_contre_pnj(n, "bagarre", {"defi": id})
		"jet":
			var morceaux: PackedStringArray = str(d.parametres).split(" ")
			var st := morceaux[0]
			var moi: int = m.fiche.stats_totales()[st] + randi_range(1, 20)
			var lui: int = int(morceaux[1]) + randi_range(1, 20)
			resoudre(m, n, id, moi >= lui, " (%s : toi %d, %s %d)" % [st, moi, n.donnees.nom.get_slice(" ", 0), lui])
		"apporter":
			m.fiche.defis_actifs[id] = Horloge.jour()
			m.fiche.sauver()
			Illustrations.montrer("defi_" + id, [n.id], "Défi accepté : %s." % d.nom.to_lower())
		"intime":
			var raison := Intime.consentement(m, n, "nuit")
			if raison != "":
				resoudre(m, n, id, false, "\n\n" + raison)
				return
			m.scene_intime([n], m.lieu_proche(n.pos2d(), 40.0), {"defi": id, "fois": int(d.parametres), "pnj": n.id})


## Rapporter ce qu'on t'a demandé (le jour même).
static func rendre(m: Node, n: Node, id: String) -> void:
	var d: Dictionary = tous()[id]
	var p: PackedStringArray = str(d.parametres).split(" ")
	var nb := int(p[1]) if p.size() > 1 else 1
	var a_temps: bool = m.fiche.defis_actifs.get(id, -1) == Horloge.jour()
	m.fiche.defis_actifs.erase(id)
	if a_temps and m.fiche.nombre(p[0]) >= nb:
		m.fiche.retirer(p[0], nb)
		resoudre(m, n, id, true)
	else:
		resoudre(m, n, id, false)


## Les défis à rapporter dont le jour est passé : perdus.
static func expirer(m: Node) -> void:
	for id in m.fiche.defis_actifs.keys():
		if m.fiche.defis_actifs[id] < Horloge.jour():
			m.fiche.defis_actifs.erase(id)
			appliquer(m, tous()[id].pnj, str(tous()[id].penalite))


static func resoudre(m: Node, n: Node, id: String, gagne: bool, details := "") -> String:
	var d: Dictionary = tous()[id]
	var t: String = (d.texte_victoire if gagne else d.texte_echec) + details
	var gains := appliquer(m, n.id, str(d.recompense if gagne else d.penalite))
	if gains != "":
		t += "\n\n" + gains
	Illustrations.montrer("defi_%s_%s" % [id, "victoire" if gagne else "echec"], [n.id], t)
	return t


## « affection 15, cuivre 6, objet OBJ002, lecon parade, art 3, pacte maitre ». Renvoie le texte.
static func appliquer(m: Node, pnj_id: String, quoi: String) -> String:
	var f: Fiche = m.fiche
	var r := []
	for morceau in quoi.split(",", false):
		var p := morceau.strip_edges().split(" ", false)
		if p.size() < 2:
			continue
		match p[0]:
			"affection":
				m.relations[pnj_id] = clampi(m.relations.get(pnj_id, 0) + int(p[1]), -100, 100)
				r.append("Affection %+d." % int(p[1]))
			"cuivre":
				var c := maxi(-f.bourse, int(p[1]))
				f.bourse += c
				r.append("%s%s." % ["+" if c >= 0 else "−", Objets.texte_prix(absi(c))])
			"objet":
				f.ajouter(p[1])
				r.append("+ %s." % Objets.get_(p[1]).get("nom", p[1]))
			"lecon":
				if not p[1] in f.apprises:
					f.apprises.append(p[1])
					r.append("Tu apprends : %s." % Combattant.COMPETENCES[p[1]].nom)
			"art":
				f.drapeaux["art_xp"] = int(f.drapeaux.get("art_xp", 0)) + int(p[1])
				r.append("Art d'aimer : +%d." % int(p[1]))
			"pacte":
				var n: Node = m._pnj_par_id(pnj_id)
				if n and Intime.pacte(m, n, p[1]).contains(Intime.MOT_D_ARRET):
					r.append("Il te propose un pacte, et tu acceptes.")
	m.sauver_etat()
	f.sauver()
	return " ".join(r)


# ---------------------------------------------------------------- l'entraînement

## S'entraîner une heure : une fois par jour, de l'expérience (et ta classe avec).
static func entrainer_competences(m: Node) -> String:
	var f: Fiche = m.fiche
	var cle := "entrainement_%d" % Horloge.jour()
	if f.drapeaux.has(cle):
		return "Tu t'es déjà entraîné aujourd'hui. Les muscles ont besoin de repos."
	f.drapeaux[cle] = true
	var n := f.gagner_xp(15)
	var t := "Une heure à répéter les gestes, encore et encore. +15 expérience."
	if n:
		t += " Niveau %d !" % f.niveau
	t += " " + " ".join(f.annonces)
	f.annonces.clear()
	f.sauver()
	return t.strip_edges()
