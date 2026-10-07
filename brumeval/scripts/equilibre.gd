# Mesure l'équilibre : godot --headless -- --equilibre
# Un personnage de niveau 1 (création « Équilibré ») affronte chaque bête plusieurs fois, l'IA joue pour lui.
# godot --headless -- --equilibre --grotte : les combats de la grotte, aux niveaux 5, 7 et 9.
extends Node

const ESSAIS := 10
const TYPES := ["rat", "loup", "crabe", "sanglier", "meute"]

var monde: Node3D


func _ready() -> void:
	await get_tree().process_frame
	monde.combat_auto = true
	var sauvee: Fiche = monde.fiche
	if "--grotte" in OS.get_cmdline_user_args():
		await _grotte()
		monde.fiche = sauvee
		sauvee.sauver()
		get_tree().quit()
		return
	for kit in ["poings", "dague", "épée courte + rondache", "Flamme (parchemin)"]:
		for type in TYPES:
			var gagnes := 0
			var pv_restants := 0
			for i in ESSAIS:
				var f := _perso(kit)
				monde.fiche = f
				var nombre: int = {"rat": 2, "meute": 3}.get(type, 1)
				monde.attaque_de_betes("loup" if type == "meute" else type, nombre, monde.joueur.pos2d() + Vector2(0, 4), "test")
				await get_tree().process_frame
				Illustrations.fermer()
				await get_tree().process_frame
				var r = await monde.combat.fini
				await get_tree().process_frame
				Illustrations.fermer()
				if r == "victoire":
					gagnes += 1
					pv_restants += f.pv
			print("  %-24s %-9s gagné %2d / %d   PV moyens après victoire : %s" % [kit, type, gagnes, ESSAIS, str(pv_restants / gagnes) if gagnes else "—"])
	monde.fiche = sauvee
	sauvee.sauver()
	get_tree().quit()


func _perso(kit: String) -> Fiche:
	var c := {"peuple": "humain", "age": 30, "astre": "lune", "vie": "sportif", "repartition": CreationDonnees.PRESETS["Équilibré"].duplicate(),
		"traits": [], "tenue": "ailleurs", "objet_ailleurs": "", "nom": "Test"}
	var f := Fiche.depuis_creation(c)
	match kit:
		"dague":
			f.ajouter("OBJ002")
			f.equiper("OBJ002")
		"épée courte + rondache":
			for id in ["OBJ007", "OBJ208"]:
				f.ajouter(id)
				f.equiper(id)
		"Flamme (parchemin)":
			f.ajouter("BRV030")
			f.lire_parchemin("BRV030")
	return f


const GROTTE := {"rats": [["rat", 4]], "inondee": [["crabe", 2], ["slime", 1]], "gouffre": [["araignee", 4]],
	"nid": [["araignee", 2], ["reine", 1]], "bete": [["bete", 1]], "bete (stalactites)": [["bete", 1]]}
const SALLE_DE := {"rats": "puits", "inondee": "inondee", "gouffre": "gouffre", "nid": "gouffre_sud", "bete": "veine", "bete (stalactites)": "veine"}


func _grotte() -> void:
	for niveau in [5, 7, 9]:
		for quoi in GROTTE:
			if OS.get_environment("SEULEMENT") != "" and quoi != OS.get_environment("SEULEMENT"):
				continue
			var gagnes := 0
			var pv_restants := 0
			for i in 6:
				var f := _perso("épée courte + rondache")
				f.niveau = niveau
				var ordre := ["For", "Vit", "Agi", "End"]
				for p in (niveau - 1) * 4:
					f.stats[ordre[p % 4]] += 1
				f.pv = f.pv_max()
				monde.fiche = f
				Horloge.avancer(fposmod(Horloge.basses_mers()[0] - Horloge.heure(), 24.0) * 60.0)
				var g: Vector2 = monde.lieux["g_" + SALLE_DE[quoi]].pos
				monde.joueur.position = Vector3(g.x, Grotte.SOL, g.y)
				var ennemis := []
				for grp in GROTTE[quoi]:
					for k in int(grp[1]):
						ennemis.append(Grotte._creer_bete(monde, grp[0], k + 1, g + Vector2(0, 2)))
				if quoi == "gouffre":
					Grotte.roussir(ennemis)
				if quoi.contains("stalactites"):
					ennemis[0].pv = ennemis[0].pv_max / 2
					ennemis[0].etats["renverse"] = 2
				monde._lancer([Combattant.joueur(monde.joueur, f)], ennemis, "mortel", {"betes": "grotte", "grotte": quoi})
				var r = await monde.combat.fini
				await get_tree().process_frame
				Illustrations.fermer()
				monde.fenetres.fermer()
				if r == "victoire":
					gagnes += 1
					pv_restants += f.pv
			print("  niveau %d  %-20s gagné %d / 6   PV après victoire : %s" % [niveau, quoi, gagnes, str(pv_restants / gagnes) if gagnes else "—"])
