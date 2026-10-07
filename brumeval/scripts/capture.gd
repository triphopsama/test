# Capture d'écran pour vérifier le rendu : godot -- --capture=chemin.png --heure=11 --lieu=place
extends Node

var monde: Node3D


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("heure"):
		var ecart := fposmod(float(args.heure) - Horloge.heure(), 24.0)
		Horloge.avancer(ecart * 60.0)
	if args.has("lieu"):
		var p: Vector2 = monde.lieux[args.lieu].pos + Vector2(0, 8)
		monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
		monde.camera.position = monde.joueur.position + Vector3(0, 10, 14)
	if args.has("zoom"):
		monde._zoom = float(args.zoom)
	for i in 90:
		await get_tree().process_frame
	if args.has("combat"):
		# --combat=loups : la meute près de sa tanière ; --combat=bagarre : Lucas au port
		if args.combat == "loups":
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
	get_viewport().get_texture().get_image().save_png(args.capture)
	Horloge.avancer(-Horloge._decalage / 60.0)
	get_tree().quit()
