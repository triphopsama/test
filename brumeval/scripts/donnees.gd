# Lecture des fichiers CSV du monde (séparateur ;, UTF-8).
class_name Donnees
extends RefCounted


static func lire_csv(chemin: String) -> Array:
	var f := FileAccess.open(chemin, FileAccess.READ)
	if f == null:
		push_error("Impossible d'ouvrir " + chemin)
		return []
	var entete := f.get_csv_line(";")
	var lignes := []
	while not f.eof_reached():
		var l := f.get_csv_line(";")
		if l.size() < entete.size():
			continue
		var d := {}
		for i in entete.size():
			d[entete[i]] = l[i]
		lignes.append(d)
	return lignes


const TITRES := ["Capitaine", "Prévôt", "Maître", "Sœur", "Madame", "Gros", "Vieille", "Vieux", "Père", "Mère", "Dame"]


## Le prénom, sans le titre : « Capitaine Ambroise Daunel » > Ambroise, « Gros Hugues » > Hugues.
static func prenom(nom: String) -> String:
	var mots := nom.split(" ", false)
	for m in mots:
		if not m in TITRES:
			return m
	return nom
