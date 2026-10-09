# Capture d'écran pour vérifier le rendu : godot -- --capture=chemin.png --heure=11 --lieu=place (ou --grotte=veine,
# ou --scene=j1_farine_silas [--texte] : une scène de la chronique et ses choix)
extends Node

var monde: Node3D


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("heure") and not args.has("jour"):     # avec --jour, le monde s'est déjà placé
		var ecart := fposmod(float(args.heure) - Horloge.heure(), 24.0)
		Horloge.avancer(ecart * 60.0)
	if args.has("lieu"):
		var p: Vector2 = monde.lieux[args.lieu].pos + Vector2(0, 8)
		monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
		monde.camera.position = monde.joueur.position + Vector3(0, 10, 14)
	if args.has("zoom"):
		monde._zoom = float(args.zoom)
	if args.has("grotte"):
		# --grotte=puits | galerie | inondee | camp | gouffre | lea | veine | bouche : une salle de la grotte,
		# avec un personnage neuf (la salle déclenche ce qu'elle déclenche : combat, Bête aveugle…)
		monde.fiche = Fiche.new()
		monde.fiche.ajouter("OBJ464")
		var g: Vector2 = monde.lieux["g_" + args.grotte].pos
		monde.joueur.position = Vector3(g.x, Grotte.SOL, g.y)
		monde.camera.position = monde.joueur.position + Vector3(0, 10, 14)
		for i in 60:
			await get_tree().process_frame
		Illustrations.fermer()
		for i in 150:
			await get_tree().process_frame
	for i in 90:
		await get_tree().process_frame
	if args.has("scene"):
		# --scene=j1_farine_silas : ouvre une scène de la chronique, puis ses choix
		var s: Dictionary = Scenes.toutes()[args.scene]
		var l: Vector2 = monde.lieux[s.lieu].pos + Vector2(0, 6)
		monde.joueur.position = Vector3(l.x, monde.hauteur(l.x, l.y), l.y)
		monde.camera.position = monde.joueur.position + Vector3(0, 10, 14)
		monde.fiche.bourse = maxi(monde.fiche.bourse, 200)
		Illustrations.fermer()
		Scenes.declencher(monde, s)
		for i in 30:
			await get_tree().process_frame
		if not args.has("texte"):
			Illustrations.fermer()
		for i in 30:
			await get_tree().process_frame
	if args.has("combat"):
		# --combat=loups : la meute près de sa tanière ; --combat=bagarre : Lucas au port
		if Combattant.BETES.has(args.combat):
			monde.attaque_de_betes(args.combat, 2 if args.combat == "rat" else 1, monde.joueur.pos2d() + Vector2(1, 4), "")
		elif args.combat == "loups":
			var p: Vector2 = monde.lieux.loups.pos + Vector2(0, 14)
			monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
			monde._dernier_jour_loups = 0
			monde._surveiller_loups()
		else:
			for n in monde.pnjs:
				if n.id == "BRU012":
					monde.joueur.position = n.position + Vector3(2, 0, 0)
					monde.combat_contre_pnj(n, "bagarre")
		for i in 20:
			await get_tree().process_frame
		Illustrations.fermer()
		for i in 120:
			await get_tree().process_frame
	if args.has("creation"):
		# --creation=3 : l'écran de création, à l'étape 3
		var ecran := preload("res://scripts/creation.gd").new()
		monde.add_child(ecran)
		await get_tree().process_frame
		ecran.c.nom = "Brindille"
		ecran.c.peuple = "homme_bete"
		ecran.c.lignee = "renard"
		ecran.etape = int(args.creation) - 1
		ecran._afficher()
		for i in 10:
			await get_tree().process_frame
	if args.has("nuit"):
		# --nuit=BRU013 : la fenêtre d'une nuit avec ce PNJ, après un baiser
		var n: Node = monde._pnj_par_id(args.nuit)
		monde.relations[n.id] = 90
		monde.desirs[n.id] = 70
		monde.scene_intime([n], "moulin")
		for i in 5:
			await get_tree().process_frame
		var fen = monde.get_children().filter(func(c): return c.has_method("_geste"))[0]
		fen._geste("embrasser")
		fen._geste("amour_tendre")
		for i in 10:
			await get_tree().process_frame
	if args.has("fenetre"):
		# --fenetre=sac | perso | classe | bram : un sac d'exemple pour voir les fenêtres
		var f := Fiche.new()
		monde.fiche = f
		f.bourse = 87
		for id in ["OBJ002", "OBJ208", "OBJ327", "OBJ407", "BRV001"]:
			f.ajouter(id, 2 if id == "OBJ327" else 1)
		f.equiper("OBJ002")
		f.equiper("OBJ208")
		f.prendre_classe("voleur")
		f.prendre_metier("forgeron")
		f.gagner_xp(60)
		f.annonces.clear()
		match args.fenetre:
			"sac": monde.fenetres.sac()
			"perso": monde.fenetres.personnage()
			"classe":
				f.classe = ""
				f.style = {"dague": 3, "dos": 2, "arme_for": 1, "esquive": 1}
				monde.fenetres.offre_classe()
				monde.fenetres._liste.get_child(0).grab_focus()
			_: monde.fenetres.marchand(monde._pnj_par_id("BRU002"), false)
		for i in 10:
			await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(args.capture)
	Horloge.avancer(-Horloge._decalage / 60.0)
	get_tree().quit()
