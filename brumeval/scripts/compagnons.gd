# L'équipe (4 au plus) : ceux qui te suivent, se battent avec toi, et ce qu'ils portent.
# Les autres restent chez eux (leur emploi du temps), en attendant une maison à toi.
#
# Les accessoires (objets de type « accessoire », chez Silas) et la nudité, en public :
#   - seulement sur un compagnon adulte avec qui tu as un pacte où tu es le maître, qui aime ça
#     (jeux de pouvoir 40 et plus, ou aime être dominé) ;
#   - ce qui se voit demande en plus d'aimer le risque ou l'audace, ou peu de pudeur ;
#   - les passants réagissent selon leur pudeur et leurs goûts ; Corentin peut verbaliser ;
#   - le compagnon a son propre malaise : trop de regards outrés et c'est le mot d'arrêt ;
#   - un enfant à portée : tu le couvres aussitôt, toujours.
class_name Compagnons
extends RefCounted

const MAX := 4
## Les accessoires : se voit-il, et à quel point ça choque (0 à 3).
const ACCESSOIRES := {
	"BRV040": {"visible": true, "choc": 2, "dit": "un collier et une laisse"},
	"BRV041": {"visible": true, "choc": 3, "dit": "une cagoule de cuir"},
	"BRV042": {"visible": true, "choc": 2, "dit": "un bâillon"},
	"BRV043": {"visible": true, "choc": 2, "dit": "des cordes serrées"},
	"BRV044": {"visible": false, "choc": 0, "dit": "un plug, qui ne se voit pas"},
}


static func dans_equipe(m: Node, id: String) -> bool:
	return id in m.fiche.equipiers


## Oui ("") ou non : un adulte qui t'aime assez (affection 50 et un couple ou un pacte, ou 70).
static func peut_suivre(m: Node, n: Node) -> String:
	var nom: String = n.donnees.nom.get_slice(" ", 0)
	var f: Fiche = m.fiche
	if int(n.donnees.get("age", "0")) < 18:
		return "%s est un enfant : sa place est chez lui." % nom
	if f.equipiers.size() >= MAX:
		return "Ton équipe est au complet (%d). Laisse quelqu'un rentrer chez lui d'abord." % MAX
	var aff: int = m.relations.get(n.id, 0)
	var lie: bool = f.partenaires.has(n.id) or f.pactes.has(n.id)
	if aff < (50 if lie else 70):
		return "%s hésite : « Te suivre ? Je ne te connais pas assez. » (affection %d)" % [nom, aff]
	return ""


static func prendre(m: Node, n: Node) -> void:
	if not n.id in m.fiche.equipiers:
		m.fiche.equipiers.append(n.id)
	n.suit = true
	m.fiche.sauver()


## Il rentre chez lui ; il garde ce qu'il porte dans son sac, pas sur lui.
static func laisser(m: Node, n: Node) -> void:
	m.fiche.equipiers.erase(n.id)
	_tout_retirer(m, n.id)
	n.suit = false
	m.fiche.sauver()


## Au chargement : ceux de l'équipe reprennent leur place derrière toi.
static func restaurer(m: Node) -> void:
	for n in m.pnjs:
		n.suit = n.id in m.fiche.equipiers and not n.mort


## Les combattants de ton équipe, pour un combat (sauf la cible).
static func allies(m: Node, sauf: String = "") -> Array:
	var r := []
	for n in m.pnjs:
		if n.suit and n.id != sauf and not n.mort:
			r.append(Combattant.depuis_pnj(n.donnees, n))
	return r


static func tenue(m: Node, id: String) -> Dictionary:
	if not m.fiche.tenues.has(id):
		m.fiche.tenues[id] = {"nu": false, "objets": []}
	return m.fiche.tenues[id]


## Mettre (ou retirer) un accessoire, ou la nudité (quoi = "nu"). Renvoie "" si c'est fait, sinon pourquoi.
static func habiller(m: Node, n: Node, quoi: String, mettre: bool) -> String:
	var t := tenue(m, n.id)
	var nom: String = n.donnees.nom.get_slice(" ", 0)
	if not mettre:
		if quoi == "nu":
			t.nu = false
		elif quoi in t.objets:
			t.objets.erase(quoi)
			m.fiche.ajouter(quoi)
		m.fiche.sauver()
		return ""
	var p := Intime.profil(n.id)
	if p.is_empty() or m.fiche.pactes.get(n.id, "") != "maitre":
		return "%s te regarde sans comprendre. Il faudrait un pacte où tu mènes." % nom
	if p.bdsm < 40 and not "etre_domine" in p.aime:
		return "%s secoue la tête : ce jeu-là ne l'attire pas." % nom
	var se_voit: bool = quoi == "nu" or ACCESSOIRES.get(quoi, {}).get("visible", false)
	if se_voit and not ("risque" in p.aime or "audace" in p.aime or p.pudeur < 40):
		return "%s rougit : « Pas dehors. Pas devant les autres. »" % nom
	if se_voit and "public" in p.refuse:
		return "%s refuse net : être vu, c'est sa limite." % nom
	if m.enfant_proche(n.pos2d()):
		return "Pas ici : il y a des enfants."
	if quoi == "nu":
		t.nu = true
	else:
		if m.fiche.nombre(quoi) == 0:
			return "Tu n'as pas ça dans ton sac."
		m.fiche.retirer(quoi)
		t.objets.append(quoi)
	m.fiche.sauver()
	return ""


static func _tout_retirer(m: Node, id: String) -> void:
	var t := tenue(m, id)
	for o in t.objets:
		m.fiche.ajouter(o)
	t.objets = []
	t.nu = false


## Ce qui se voit (ou se dit) de sa tenue, pour le HUD et les réactions.
static func description(m: Node, id: String) -> String:
	var t := tenue(m, id)
	var r := []
	if t.nu:
		r.append("nu·e")
	for o in t.objets:
		r.append(ACCESSOIRES[o].dit)
	return ", ".join(r)


static func choc(m: Node, id: String) -> int:
	var t := tenue(m, id)
	var c := 3 if t.nu else 0
	for o in t.objets:
		c += int(ACCESSOIRES[o].choc)
	return c


## Un enfant à portée : tu couvres tout le monde, tout de suite. Renvoie le texte ("" si rien à couvrir).
static func couvrir_si_enfant(m: Node) -> String:
	var couverts := []
	for id in m.fiche.equipiers:
		var n: Node = m._pnj_par_id(id)
		if n and choc(m, id) > 0 and m.enfant_proche(n.pos2d()):
			_tout_retirer(m, id)
			couverts.append(n.donnees.nom.get_slice(" ", 0))
	if couverts.is_empty():
		return ""
	m.fiche.sauver()
	return "Un enfant approche : tu couvres %s en hâte." % ", ".join(couverts)


## Les passants qui voient ton équipe. Renvoie les lignes à afficher ; Corentin peut verbaliser.
static func reactions(m: Node) -> Array:
	var lignes := []
	var f: Fiche = m.fiche
	for id in f.equipiers.duplicate():
		var c := choc(m, id)
		var n: Node = m._pnj_par_id(id)
		if c == 0 or n == null:
			continue
		var pc := Intime.profil(id)
		var nom: String = n.donnees.nom.get_slice(" ", 0)
		for t in m.temoins(15.0):
			if t.id in f.equipiers or int(t.donnees.get("age", "0")) < 18:
				continue
			var cle := "vu_%s_%s_%d" % [t.id, id, Horloge.jour()]
			if f.drapeaux.has(cle):
				continue
			f.drapeaux[cle] = true
			var p := Intime.profil(t.id)
			var pudeur: int = p.get("pudeur", 60)
			var qui: String = t.donnees.nom.get_slice(" ", 0)
			var outre := false
			if t.id == "BRU014" and tenue(m, id).nu:
				var amende := mini(60, f.bourse)
				f.bourse -= amende
				m.relations["BRU014"] = clampi(m.relations.get("BRU014", 0) - 5, -100, 100)
				_tout_retirer(m, id)
				lignes.append("Corentin s'interpose : « Indécence sur la voie publique. Couvrez-le, et c'est %s d'amende. » (−5)" % Objets.texte_prix(amende))
				outre = true
			elif pudeur >= 70 or t.trait_("pieux") >= 40:
				m.relations[t.id] = clampi(m.relations.get(t.id, 0) - 5, -100, 100)
				lignes.append("%s voit %s (%s) et détourne les yeux, outré·e (−5)." % [qui, nom, description(m, id)])
				outre = true
			elif pudeur < 40 or "risque" in p.get("aime", []) or "dominer" in p.get("aime", []):
				m.relations[t.id] = clampi(m.relations.get(t.id, 0) + 2, -100, 100)
				m.desirs[t.id] = mini(100, Intime.desir(m, t.id) + 10)
				lignes.append("%s ne peut pas détourner les yeux de %s (+2)." % [qui, nom])
			else:
				m.relations[t.id] = clampi(m.relations.get(t.id, 0) - 2, -100, 100)
				lignes.append("%s, gêné·e, fait mine de ne rien voir (−2)." % qui)
			# le compagnon : ce que ces regards lui font
			if "risque" in pc.aime or "audace" in pc.aime:
				m.desirs[id] = mini(100, Intime.desir(m, id) + 5)
			elif outre:
				f.drapeaux["malaise_" + id] = int(f.drapeaux.get("malaise_" + id, 0)) + 10 * c
				if f.drapeaux["malaise_" + id] >= 60:
					f.drapeaux.erase("malaise_" + id)
					_tout_retirer(m, id)
					m.relations[id] = clampi(m.relations.get(id, 0) - 10, -100, 100)
					lignes.append("« %s. » %s a dit le mot d'arrêt : tu le couvres, le jeu s'arrête là (−10)." % [Intime.MOT_D_ARRET, nom])
					break
	m.sauver_etat()
	f.sauver()
	return lignes
