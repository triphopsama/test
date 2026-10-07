# Test automatique : godot --headless -- --autotest
# Vérifie les données, les trajets, les PNJ et les garde-fous des actions intimes.
extends Node

var monde: Node3D
var erreurs := 0


func ok(cond: bool, quoi: String) -> void:
	if cond:
		print("  ok  ", quoi)
	else:
		erreurs += 1
		print("  ÉCHEC  ", quoi)


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("== Données")
	ok(monde.lieux.size() == 28, "28 lieux (%d)" % monde.lieux.size())
	ok(monde.pnjs.size() == 19, "19 PNJ au village (%d)" % monde.pnjs.size())
	ok(monde.actions.lignes.size() >= 10, "actions lues (%d)" % monde.actions.lignes.size())
	ok(monde.praticable(monde.lieux.reveil.pos), "on peut marcher à la clairière du réveil")
	ok(not monde.praticable(Vector2(50, 600)), "on ne marche pas sur la mer")
	print("== Trajets")
	var c: PackedVector2Array = monde.chemin("place", "crique")
	ok(c.size() >= 2, "un chemin place → crique (%d étapes)" % c.size())
	var c2: PackedVector2Array = monde.chemin("reveil", "forge")
	ok(c2.size() >= 3, "un chemin réveil → forge (%d étapes)" % c2.size())
	print("== Heure : jour %d, %s, marée basse : %s" % [Horloge.jour(), Horloge.texte_heure(), Horloge.maree_basse()])
	print("== PNJ")
	for n in monde.pnjs:
		print("  %-20s %-14s → %-12s visible=%s" % [n.donnees.nom, n.lieu_actuel, n.lieu_cible, n.visible])
	print("== Actions")
	var mara: Node = _pnj("BRU001")
	var tim: Node = _pnj("BRU005")
	var nina: Node = _pnj("BRU016")
	ok(_ids(monde.actions.disponibles(tim, "place")).has("parler"), "on peut parler à Tim")
	ok(not _ids(monde.actions.disponibles(tim, "place")).has("seduire"), "aucune action intime avec Tim (11 ans)")
	ok(not _ids(monde.actions.disponibles(nina, "place")).has("embrasser"), "aucune action intime avec Nina (13 ans)")
	# Mara seule avec le joueur, loin des enfants
	tim.visible = false
	nina.visible = false
	monde.joueur.position = mara.position
	tim.set_process(false)
	nina.set_process(false)
	ok(_ids(monde.actions.disponibles(mara, "boulangerie")).has("seduire"), "action intime proposée avec Mara, adulte")
	var demande := _ids(monde.actions.disponibles(_pnj("BRU002"), "forge"))
	ok(demande.has("demander_travail"), "Bram a sa ligne « demander du travail »")
	# un enfant à côté : plus rien d'intime
	tim.visible = true
	tim.position = mara.position + Vector3(2, 0, 0)
	ok(not _ids(monde.actions.disponibles(mara, "boulangerie")).has("seduire"), "rien d'intime si un enfant est à côté")
	tim.visible = false
	tim.position = Vector3(0, 0, 0)
	# refus si l'affection est trop basse
	monde.relations["BRU001"] = 0
	var ligne: Dictionary = {}
	for l in monde.actions.disponibles(mara, "boulangerie"):
		if l.id == "seduire":
			ligne = l
	var h0: float = Horloge.heure()
	monde.actions.executer(ligne, mara, "boulangerie")
	ok(Illustrations.ouvert and Illustrations._texte.text.contains("Non"), "Mara dit non quand l'affection est basse")
	Illustrations.fermer()
	monde.relations["BRU001"] = 50
	monde.actions.executer(ligne, mara, "boulangerie")
	ok(Illustrations._texte.text.contains("texte à écrire"), "texte vide : on invite à l'écrire")
	ok(Illustrations._texte.text.contains("Échap"), "on peut arrêter la scène")
	Illustrations.fermer()
	for l in monde.actions.disponibles(mara, "boulangerie"):
		if l.id == "parler":
			monde.actions.executer(l, mara, "boulangerie")
	print("  texte : ", Illustrations._texte.text)
	ok(Illustrations._texte.text.contains("Bordel de farine"), "parler reprend la parole de Mara")
	Illustrations.fermer()
	ok(Horloge.heure() != h0, "le temps a avancé avec les actions")
	print("== Temps accéléré ×600 pendant 2 s")
	Horloge.acceleration = 600.0
	var avant := {}
	for n in monde.pnjs:
		avant[n.id] = n.position
	await get_tree().create_timer(2.0).timeout
	var bouges := 0
	for n in monde.pnjs:
		if n.position.distance_to(avant[n.id]) > 1.0:
			bouges += 1
	ok(bouges > 0, "des PNJ se déplacent (%d)" % bouges)
	Horloge.acceleration = 1.0
	Horloge.avancer(-float(Horloge._decalage) / 60.0)   # on remet l'horloge à l'heure
	print("== %s" % ("TOUT EST BON" if erreurs == 0 else "%d ÉCHEC(S)" % erreurs))
	get_tree().quit(erreurs)


func _pnj(id: String) -> Node:
	for n in monde.pnjs:
		if n.id == id:
			return n
	return null


func _ids(liste: Array) -> Array:
	return liste.map(func(l): return l.id)
