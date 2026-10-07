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
