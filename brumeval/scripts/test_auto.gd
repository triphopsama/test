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
	print("== Objets, sac, expérience")
	var sauvee: Fiche = monde.fiche
	var f := Fiche.new()
	monde.fiche = f
	ok(Objets.tous().size() >= 40, "objets lus (%d)" % Objets.tous().size())
	ok(Objets.cuivre_de("3 argent 6 cuivre") == 42 and Objets.cuivre_de("2 or") == 480, "les prix se lisent (1 or = 20 argent = 240 cuivre)")
	ok(Objets.texte_prix(42) == "3 argent 6 cuivre", "les prix s'écrivent")
	ok(f.equipe("OBJ222") and f.equipe("OBJ511") and f.bourse == 0, "au réveil : les vêtements d'ailleurs, l'anneau, pas un sou")
	ok(f.desequiper("OBJ511") != "", "l'anneau ne s'enlève pas")
	ok(Combattant.joueur(monde.joueur, f).arme.nom == "poings", "sans arme, on se bat aux poings")
	f.ajouter("OBJ157")
	ok(f.equiper("OBJ157").contains("End 8"), "la cotte de mailles demande End 8")
	f.ajouter("OBJ012")
	ok(f.equiper("OBJ012").contains("For 10"), "l'épée longue demande For 10")
	f.ajouter("OBJ208")
	ok(f.equiper("OBJ208") == "", "on prend la rondache")
	f.ajouter("OBJ072")
	ok(f.equiper("OBJ072") == "" and not f.equipement.has("main_gauche"), "l'arc à deux mains fait poser le bouclier")
	var c_arc := Combattant.joueur(monde.joueur, f)
	ok(c_arc.arme.portee == 5 and c_arc.stats.Per >= 10, "l'arc tire à 5 cases et donne Per +2 (%d)" % c_arc.stats.Per)
	ok("tir_precis" in c_arc.competences, "Per 10 avec un arc : Tir précis")
	f.ajouter("OBJ002")
	f.equiper("OBJ002")
	f.equiper("OBJ208")
	var c_dague := Combattant.joueur(monde.joueur, f)
	ok(c_dague.arme.degats == 5 and c_dague.bouclier == 12 and c_dague.def_phys >= 1 + c_dague.stats.Rob, "dague, rondache et vêtements comptent en combat")
	ok(f.gagner_xp(60) == 1 and f.niveau == 2 and f.points == 4, "60 expérience : niveau 2, 4 points")
	ok(f.depenser_point("For") and f.stats.For == 8, "un point en Force")
	f.pv = 10
	f.ajouter("OBJ327")
	ok(f.utiliser("OBJ327").contains("+15") and f.pv == 25, "le pain de Mara rend 15 PV")
	# gagner sa vie, payer
	var forge: Dictionary = {}
	for l in monde.actions.disponibles(null, "forge"):
		if l.id == "travailler":
			forge = l
	monde.actions.executer(forge, null, "forge")
	ok(f.bourse == 6, "une heure de travail : 6 cuivre (%d)" % f.bourse)
	Illustrations.fermer()
	for l in monde.actions.disponibles(null, "taverne"):
		if l.id == "dormir":
			monde.actions.executer(l, null, "taverne")
	ok(Illustrations._texte.text.contains("Ça coûte") and f.bourse == 6, "pas de lit sans 1 argent")
	Illustrations.fermer()
	# Bram vend des armes
	var bram_m: Node = _pnj("BRU002")
	monde.relations["BRU002"] = 0
	ok(_ids(monde.actions.disponibles(bram_m, "forge")).has("acheter"), "on peut acheter chez Bram")
	f.bourse = 50
	monde.fenetres.marchand(bram_m, false)
	ok(monde.fenetres._liste.get_child_count() >= 6, "Bram a des armes et des mailles (%d)" % monde.fenetres._liste.get_child_count())
	monde.fenetres._acheter("OBJ002")
	ok(f.bourse == 14 and f.nombre("OBJ002") == 2, "une dague pour 3 argent")
	monde.fenetres.fermer()
	monde.fenetres.marchand(bram_m, true)
	monde.fenetres._vendre("OBJ002")
	ok(f.bourse == 32, "revendue la moitié (%d)" % f.bourse)
	monde.fenetres.fermer()
	monde.fenetres.sac()
	ok(monde.fenetres._liste.get_child_count() >= 5, "le sac s'affiche")
	monde.fenetres.fermer()
	monde.fenetres.personnage()
	ok(monde.fenetres._liste.get_child_count() == 9, "la fiche montre les 9 caractéristiques")
	monde.fenetres.fermer()
	print("== Création de personnage")
	var ch := {"peuple": "nain", "lignee": "profondeurs", "age": 45, "astre": "rouge", "vie": "sportif",
		"repartition": {"For": 7, "Rob": 5, "Vit": 5, "Int": -2, "Sag": 3}, "traits": ["robuste", "fragile"], "tenue": "nu",
		"objet_ailleurs": "BRV011", "nom": "Durgrim", "sexe": "Homme", "pronoms": "il", "archetype": "brute",
		"options": {"chiffres": "complet", "adulte": false, "mort_definitive": false}}
	ok(CreationDonnees.budget(ch) == 22 and CreationDonnees.depenses(ch) == 20, "baisser Int à 3 rend 2 points (budget %d)" % CreationDonnees.budget(ch))
	var st := CreationDonnees.stats_finales(ch)
	ok(st.For == 14 and st.Rob == 12 and st.End == 8 and st.Agi == 5 and st.Vol == 6, "nain, profondeurs, mûr, Rouge, sportif : For %d Rob %d End %d Agi %d Vol %d" % [st.For, st.Rob, st.End, st.Agi, st.Vol])
	ok(CreationDonnees.solde_traits(ch) == 0, "Robuste et Fragile s'annulent")
	var fn := Fiche.depuis_creation(ch)
	ok(fn.nom == "Durgrim" and fn.drapeaux.has("cree") and fn.equipement.size() == 1 and fn.nombre("BRV011") == 1, "nu, l'anneau au doigt, la montre en poche")
	ok(Combattant.joueur(monde.joueur, fn).nom == "Durgrim", "le combat t'appelle par ton nom")
	monde.fiche = fn
	ok(not monde.actions.intime_possible(mara), "contenu adulte désactivé : aucune action intime")
	monde.nouvelle_vie()
	ok(monde.relations.get("BRU011", 0) == 20, "Rosalie accueille un nain en cousin")
	var ecran := preload("res://scripts/creation.gd").new()
	add_child(ecran)
	await get_tree().process_frame
	for i in ecran.ETAPES.size():
		ecran._hasard(i)
		ecran.etape = i
		ecran._afficher()
	await get_tree().process_frame
	ok(ecran._probleme() == "", "tout au hasard donne un personnage valide (%s)" % ecran._probleme())
	var recu := []
	ecran.fini.connect(func(x): recu.append(x))
	ecran._terminer()
	var fh: Fiche = recu[0] if recu else null
	ok(fh != null and fh.drapeaux.has("cree") and int(fh.stats.For) >= 1, "l'écran rend une fiche : %s, %s" % [fh.nom if fh else "?", fh.peuple if fh else "?"])
	monde.relations.clear()
	# pour les combats : une dague, de quoi se soigner
	f = Fiche.new()
	monde.fiche = f
	f.ajouter("OBJ002")
	f.equiper("OBJ002")
	f.ajouter("BRV001", 2)
	print("== Combat")
	monde.combat_auto = true
	ok(not _ids(monde.actions.disponibles(tim, "place")).has("attaquer"), "on ne peut pas attaquer Tim (enfant)")
	ok(_ids(monde.actions.disponibles(_pnj("BRU012"), "port")).has("bagarre"), "on peut provoquer Lucas en bagarre")
	var lucas: Node = _pnj("BRU012")
	lucas.visible = true
	monde.joueur.position = lucas.position + Vector3(2, 0, 0)
	monde.combat_contre_pnj(lucas, "bagarre")
	var r1 = await monde.combat.fini
	ok(r1 in ["victoire", "defaite", "fuite", "reddition"], "la bagarre contre Lucas se termine : " + str(r1))
	ok(not lucas.mort, "personne ne meurt dans une bagarre")
	Illustrations.fermer()
	await get_tree().process_frame
	var p: Vector2 = monde.lieux.loups.pos + Vector2(0, 10)
	monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
	monde._dernier_jour_loups = 0
	monde._surveiller_loups()
	ok(Illustrations.ouvert, "les loups surgissent près de leur tanière")
	Illustrations.fermer()
	await get_tree().process_frame
	ok(monde.combat != null, "le combat contre les loups commence")
	if monde.combat:
		var r2 = await monde.combat.fini
		ok(r2 in ["victoire", "defaite", "fuite", "reddition"], "le combat contre les loups se termine : " + str(r2))
		await get_tree().process_frame
		if r2 == "victoire":
			ok(f.nombre("OBJ407") > 0 and (f.xp > 0 or f.niveau > 1), "peaux de loup et expérience")
		else:
			ok(f.pv >= 1, "vaincu, mais vivant (%d PV)" % f.pv)
	Illustrations.fermer()
	await get_tree().process_frame
	print("== Agression")
	var bram: Node = _pnj("BRU002")
	monde.relations["BRU002"] = -90
	bram.visible = true
	bram.mort = false
	bram.hostile = true
	monde.joueur.position = bram.position + Vector3(5, 0, 0)
	for i in 50:
		await get_tree().create_timer(0.1).timeout
		if Illustrations.ouvert:
			break
	ok(Illustrations.ouvert and Illustrations._texte.text.contains("Bram"), "Bram, qui te déteste, vient t'agresser (%s)" % Illustrations._texte.text.left(60))
	Illustrations.fermer()
	await get_tree().process_frame
	if monde.combat:
		var r3 = await monde.combat.fini
		ok(true, "l'agression de Bram se termine : " + str(r3))
	Illustrations.fermer()
	ok(not monde.temoins(9999.0).is_empty(), "le village vit toujours")
	monde.relations["BRU002"] = 0
	monde.morts.clear()
	monde.sauver_etat()
	monde.fiche = sauvee
	sauvee.sauver()
	print("== %s" % ("TOUT EST BON" if erreurs == 0 else "%d ÉCHEC(S)" % erreurs))
	get_tree().quit(erreurs)


func _pnj(id: String) -> Node:
	for n in monde.pnjs:
		if n.id == id:
			return n
	return null


func _ids(liste: Array) -> Array:
	return liste.map(func(l): return l.id)
