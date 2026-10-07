# Mesure l'équilibre : godot --headless -- --equilibre
# Un personnage de niveau 1 (création « Équilibré ») affronte chaque bête plusieurs fois, l'IA joue pour lui.
extends Node

const ESSAIS := 10
const TYPES := ["rat", "loup", "crabe", "sanglier", "meute"]

var monde: Node3D


func _ready() -> void:
	await get_tree().process_frame
	monde.combat_auto = true
	var sauvee: Fiche = monde.fiche
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
