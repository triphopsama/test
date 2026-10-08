# Tout a un prix (data/biens.csv) : les maisons, les commerces, un bateau, et les contrats de dette
# des captifs de la Maison des Lanternes.
#
# Colonnes de biens.csv :
#   id, carte, lieu      le bien et où il est
#   type                 maison, commerce, bateau, public (jamais à vendre), dette (un contrat de captif)
#   proprietaire         qui le vend (pour une dette : le captif lui-même ; c'est Orsoline qui vend)
#   prix                 « 3 or », « 6 argent »… ; revenu : cuivre par jour s'il est à toi
#   vend                 « affection N » : à ce prix s'il t'aime assez, plus cher sinon ; « jamais »
#   texte                ce que dit le vendeur
#
# Une maison ou un commerce : l'acheter (on peut négocier : Int + Sag, mais un vendeur vexé monte
# son prix), le louer (un dixième du prix par semaine), ou se le faire prêter (affection 70, ou un
# événement : « pret <id> » ou « bien <id> » dans une récompense de defis.csv). Chez toi, on dort
# gratuitement ; dans ton commerce, tu achètes à moitié prix ; chaque jour, tes commerces rapportent.
#
# Un contrat de dette : le racheter. Tu peux le déchirer aussitôt (il est libre), ou le garder : il
# travaille pour toi (8 cuivre par jour) ou te suit. Sous contrat, il ne peut pas consentir : rien
# d'intime, jamais, et son affection baisse chaque jour. Libéré, il te le doit (+30), et redevient un
# adulte comme les autres.
class_name Biens
extends RefCounted

const ACTIONS := ["bien_acheter", "bien_vendre", "dette_racheter", "contrat_gerer"]
const SALAIRE_CONTRAT := 8
const AFFECTION_PRET := 70

static var _tous := {}


static func tous() -> Dictionary:
	if _tous.is_empty():
		for l in Donnees.lire_csv("res://data/biens.csv"):
			_tous[l.id] = l
	return _tous


static func _a_moi(m: Node) -> Dictionary:
	if not m.fiche.drapeaux.has("biens"):
		m.fiche.drapeaux["biens"] = {}
	return m.fiche.drapeaux["biens"]


static func contrats(m: Node) -> Dictionary:
	if not m.fiche.drapeaux.has("contrats"):
		m.fiche.drapeaux["contrats"] = {}
	return m.fiche.drapeaux["contrats"]


static func liberes(m: Node) -> Array:
	return m.fiche.drapeaux.get("liberes", [])


## achat, location, pret, ou "" si ce n'est pas à toi.
static func statut(m: Node, id: String) -> String:
	return str(_a_moi(m).get(id, ""))


static func ici(m: Node, lieu: String, types := ["maison", "commerce", "bateau", "public"]) -> Array:
	return tous().values().filter(func(b): return b.carte == m.carte and b.lieu == lieu and b.type in types)


## Tu y es chez toi (achetée, louée, prêtée ; ou ta maison de la falaise).
static func chez_soi(m: Node, lieu: String) -> bool:
	if Maison.chez_toi(m) and lieu == Maison.LIEU and Maison.niveau(m) >= 2:
		return true
	return ici(m, lieu).any(func(b): return statut(m, b.id) != "")


## Tu possèdes le commerce de ce marchand : moitié prix.
static func possede_de(m: Node, pnj_id: String) -> bool:
	return tous().values().any(func(b): return b.proprietaire == pnj_id and b.type == "commerce" and statut(m, b.id) == "achat")


static func _nom(m: Node, id: String) -> String:
	return Donnees.prenom(str(m.pnj_donnees.get(id, {}).get("nom", id)))


## Le prix qu'on te fait : le prix de base s'il t'aime assez, plus sinon, et ce qu'a donné la négociation.
static func prix(m: Node, b: Dictionary) -> int:
	var base := Objets.cuivre_de(str(b.prix))
	var seuil := int(str(b.vend).get_slice(" ", 1)) if str(b.vend).begins_with("affection") else 0
	var aff: int = m.relations.get(b.proprietaire, 0)
	var f := 1.0 + maxf(0.0, (seuil - aff) / 100.0)
	if m.morts.has(b.proprietaire):
		f = 1.0     # la mairie vend ce qu'ont laissé les morts
	f *= float(m.fiche.drapeaux.get("nego_" + b.id, 1.0))
	return maxi(1, int(base * f))


# ---------------------------------------------------------------- au chargement

## Les libérés sont libres ; ceux sous ton contrat le sont aussi dans leurs données ; Vesperine,
## si elle a été vendue à Pierrefane, attend à la Maison des Lanternes.
static func installer(m: Node) -> void:
	for id in liberes(m):
		if m.pnj_donnees.has(id):
			m.pnj_donnees[id]["statut_social"] = "libre (contrat racheté)"
	for id in contrats(m):
		if m.pnj_donnees.has(id):
			m.pnj_donnees[id]["statut_social"] = "sous contrat de dette (à toi)"
	if m.carte == "pierrefane" and Vesperine.etat(m) == "capturee" and m._pnj_par_id(Vesperine.ID) == null and Vesperine.arrivee_a_pierrefane(m):
		var d: Dictionary = Vesperine.DONNEES.duplicate()
		d.statut_social = "captive de la Maison des Lanternes (collier)"
		d.detresse = "1"
		var n := preload("res://scripts/pnj.gd").new()
		n.monde = m
		n.id = Vesperine.ID
		n.donnees = d
		n.emploi = [[0.0, "lanternes", "enfermée, le collier au cou"]]
		if contrats(m).has(Vesperine.ID):
			d.statut_social = "sous contrat (à toi), le collier au cou"
		m.pnj_donnees[Vesperine.ID] = d
		m.add_child(n)
		m.pnjs.append(n)
	if m.carte == "pierrefane" and Vesperine.etat(m) == "rachetee" and m._pnj_par_id(Vesperine.ID) == null:
		var d: Dictionary = Vesperine.DONNEES.duplicate()
		d.statut_social = "libre (rachetée)"
		d.detresse = "1" if Horloge.jour() - int(m.fiche.drapeaux.get("vesperine_rachat_jour", 0)) < 2 else "0"
		var n := preload("res://scripts/pnj.gd").new()
		n.monde = m
		n.id = Vesperine.ID
		n.donnees = d
		n.emploi = [[0.0, "auberge", "dort au Mouillage"], [9.0, "jetee", "regarde la mer"], [14.0, "plage", "marche pieds nus"],
			[19.0, "auberge", "écoute les marins"], [23.0, "auberge", "dort au Mouillage"]]
		m.add_child(n)
		m.pnjs.append(n)


## Chaque jour : ce que rapportent tes commerces et le travail sous contrat ; les loyers ; ceux
## qu'on garde sous contrat t'en veulent un peu plus.
static func jour_passe(m: Node) -> String:
	var f: Fiche = m.fiche
	var dernier := int(f.drapeaux.get("revenus_jour", Horloge.jour()))
	f.drapeaux["revenus_jour"] = Horloge.jour()
	var jours := Horloge.jour() - dernier
	if jours <= 0:
		return ""
	var gain := 0
	var lignes := []
	for id in _a_moi(m):
		var b: Dictionary = tous().get(id, {})
		if b.is_empty():
			continue
		match statut(m, id):
			"achat":
				gain += int(b.revenu) * jours
			"location":
				var loyer := maxi(1, Objets.cuivre_de(str(b.prix)) / 70) * jours   # un dixième du prix par semaine
				if f.bourse + gain >= loyer:
					gain -= loyer
				else:
					_a_moi(m).erase(id)
					lignes.append("Tu n'as pas payé le loyer : %s n'est plus à toi." % b.nom)
			"pret":
				if int(m.relations.get(b.proprietaire, 0)) < 30:
					_a_moi(m).erase(id)
					lignes.append("%s reprend %s : « On n'est plus amis, rends-moi la clé. »" % [_nom(m, b.proprietaire), b.nom.to_lower()])
	for id in contrats(m):
		if contrats(m)[id] == "travail":
			gain += SALAIRE_CONTRAT * jours
		m.relations[id] = clampi(m.relations.get(id, 0) - 2 * jours, -100, 100)
	f.bourse = maxi(0, f.bourse + gain)
	if gain != 0:
		lignes.insert(0, "Tes biens %s %s." % ["rapportent" if gain > 0 else "te coûtent", Objets.texte_prix(absi(gain))])
	f.sauver()
	m.sauver_etat()
	return " ".join(lignes)


# ---------------------------------------------------------------- les actions

static func dispo(m: Node, quoi: String, pnj: Node, lieu: String) -> bool:
	match quoi:
		"bien_acheter":
			return pnj == null and ici(m, lieu).any(func(b): return statut(m, b.id) != "achat")
		"bien_vendre":
			return pnj == null and ici(m, lieu).any(func(b): return statut(m, b.id) == "achat")
		"dette_racheter":
			return pnj != null and _dette_de(m, pnj.id) != {} and not contrats(m).has(pnj.id) and not pnj.id in liberes(m)
		"contrat_gerer":
			return pnj != null and contrats(m).has(pnj.id)
	return false


static func _dette_de(m: Node, id: String) -> Dictionary:
	for b in tous().values():
		if b.type == "dette" and b.proprietaire == id and b.carte == m.carte:
			return b
	return {}


static func agir(m: Node, quoi: String, pnj: Node, lieu: String) -> String:
	match quoi:
		"bien_acheter":
			var options := []
			for b in ici(m, lieu):
				if statut(m, b.id) == "achat":
					continue
				if b.vend == "jamais":
					options.append([b.nom + " : pas à vendre", _dire.bind(m, b, str(b.texte)), str(b.texte)])
					continue
				var p := prix(m, b)
				options.append(["Acheter %s (%s)" % [b.nom, Objets.texte_prix(p)], acheter.bind(m, b.id), str(b.texte)])
				if not m.fiche.drapeaux.has("nego_" + b.id):
					options.append(["Négocier le prix de %s" % b.nom, negocier.bind(m, b.id), "Int + Sag contre le vendeur. Bien joué : moins cher. Mal joué : il se vexe."])
				if statut(m, b.id) == "" and b.type in ["maison", "commerce"]:
					options.append(["Louer %s (%s la semaine)" % [b.nom, Objets.texte_prix(Objets.cuivre_de(str(b.prix)) / 10)], louer.bind(m, b.id), "Tu y dors gratuitement ; pas de revenus."])
				if statut(m, b.id) == "" and b.type == "maison":
					options.append(["Demander à %s de te la prêter" % _nom(m, b.proprietaire), preter.bind(m, b.id), "Gratuit, s'il t'aime vraiment (affection %d)." % AFFECTION_PRET])
			options.append(["Rien", func(): pass, ""])
			m.fenetres.choix("Ce qui est à vendre ici", "Tout a un prix. Ta bourse : %s." % Objets.texte_prix(m.fiche.bourse), options)
			return ""
		"bien_vendre":
			var options := []
			for b in ici(m, lieu):
				if statut(m, b.id) == "achat":
					var p := int(Objets.cuivre_de(str(b.prix)) * 0.75)
					options.append(["Revendre %s (%s)" % [b.nom, Objets.texte_prix(p)], revendre.bind(m, b.id), "Aux trois quarts de son prix."])
			options.append(["Garder", func(): pass, ""])
			m.fenetres.choix("Revendre", "À qui veut bien racheter.", options)
			return ""
		"dette_racheter":
			var b := _dette_de(m, pnj.id)
			var p := prix(m, b)
			var options := [["Racheter le contrat (%s)" % Objets.texte_prix(p), racheter.bind(m, b.id), "Il est à toi : tu le déchires, ou tu le gardes."]]
			if not m.fiche.drapeaux.has("nego_" + b.id):
				options.append(["Négocier avec Orsoline", negocier.bind(m, b.id), "Int + Sag contre Orsoline."])
			options.append(["Plus tard", func(): pass, ""])
			m.fenetres.choix(b.nom, str(b.texte), options)
			return ""
		"contrat_gerer":
			var nom: String = Donnees.prenom(pnj.donnees.nom)
			m.fenetres.choix("Le contrat de %s" % nom, "%s est sous ton contrat. Sous contrat, rien d'intime : il ne peut pas consentir." % nom, [
				["Déchirer le contrat", liberer.bind(m, pnj), "Libre. Il te le doit (+30)."],
				["Le mettre au travail", _assigner.bind(m, pnj, "travail"), "%d cuivre par jour ; son affection baisse." % SALAIRE_CONTRAT],
				["Le prendre dans ton équipe", _assigner.bind(m, pnj, "equipe"), "Il te suit et se bat avec toi ; son affection baisse."],
				["Le laisser où il est", _assigner.bind(m, pnj, "garde"), ""]])
			return ""
	return ""


static func _dire(m: Node, b: Dictionary, t: String) -> void:
	Illustrations.montrer("bien_" + b.id + "_refus", [b.proprietaire, b.lieu], t)


static func acheter(m: Node, id: String) -> void:
	var b: Dictionary = tous()[id]
	var p := prix(m, b)
	if m.fiche.bourse < p:
		Illustrations.montrer("bien_acheter_refus", [b.proprietaire, b.lieu], "Il te manque %s." % Objets.texte_prix(p - m.fiche.bourse))
		return
	m.fiche.bourse -= p
	_a_moi(m)[id] = "achat"
	m.fiche.drapeaux["revenus_jour"] = m.fiche.drapeaux.get("revenus_jour", Horloge.jour())
	var seuil := int(str(b.vend).get_slice(" ", 1))
	var aff: int = m.relations.get(b.proprietaire, 0)
	m.relations[b.proprietaire] = clampi(aff + (3 if aff >= seuil else -10), -100, 100)
	var t := "%s\n\n%s est à toi (%s). Il rapporte %s par jour." % [b.texte, b.nom, Objets.texte_prix(p), Objets.texte_prix(int(b.revenu))] if int(b.revenu) > 0 \
		else "%s\n\n%s est à toi (%s). Tu y dors quand tu veux." % [b.texte, b.nom, Objets.texte_prix(p)]
	if aff < seuil:
		t += " %s t'en veut un peu de lui avoir forcé la main (-10)." % _nom(m, b.proprietaire)
	if id == "lanternes":
		t += "\n\nTu montes à l'étage avec Orsoline. Les contrats de Lysa et de Bastien sont là, dans le tiroir."
		m.fiche.sauver()
		m.sauver_etat()
		Illustrations.montrer("bien_lanternes", [b.proprietaire, b.lieu], t)
		await Illustrations.ferme
		m.fenetres.choix("Les contrats", "Les contrats de dette sont à toi, avec la maison.", [
			["Les déchirer tous", _dechirer_lanternes.bind(m), "Lysa et Bastien sont libres. La Maison devient une maison libre."],
			["Les garder", _garder_lanternes.bind(m), "Ils sont à toi. Rien d'intime avec eux, jamais : ils ne peuvent pas consentir."]])
		return
	m.fiche.sauver()
	m.sauver_etat()
	Illustrations.montrer("bien_" + id, [b.proprietaire, b.lieu], t)


static func _dechirer_lanternes(m: Node) -> void:
	for id in ["PIE002", "PIE003"]:
		_liberer_id(m, id)
	Illustrations.montrer("bien_lanternes_libre", ["PIE002", "PIE003", "lanternes"], "Le papier se déchire mal, puis bien. Lysa ne comprend pas tout de suite. Bastien, si : il pleure. La lanterne rouge reste allumée, mais ceux qui travaillent ici, désormais, le choisissent.")


static func _garder_lanternes(m: Node) -> void:
	for id in ["PIE002", "PIE003"]:
		contrats(m)[id] = "garde"
		if m.pnj_donnees.has(id):
			m.pnj_donnees[id]["statut_social"] = "sous contrat de dette (à toi)"
	m.fiche.sauver()
	Illustrations.montrer("bien_lanternes_contrats", ["PIE002", "PIE003", "lanternes"], "Tu ranges les contrats dans ta poche. Lysa baisse les yeux. Bastien te regarde comme il regardait Orsoline.")


static func negocier(m: Node, id: String) -> void:
	var b: Dictionary = tous()[id]
	var st: Dictionary = m.fiche.stats_totales()
	var bonus := 5 if "seduction" in m.fiche.competences() else 0
	if m.fiche.vie == "commercant":
		bonus += 5
	var moi: int = st.Int + st.Sag + bonus + randi_range(1, 20)
	var vendeur: Dictionary = m.pnj_donnees.get(b.proprietaire if b.type != "dette" else "PIE001", {})
	var lui: int = int(vendeur.get("Int", "10")) + int(vendeur.get("Sag", "10")) + randi_range(1, 20)
	var t := ""
	if moi >= lui + 10:
		m.fiche.drapeaux["nego_" + id] = 0.7
		t = "Tu fais valoir le toit qui fuit, les dettes, les années. Le vendeur soupire : moins trente pour cent. (%d contre %d)" % [moi, lui]
	elif moi >= lui:
		m.fiche.drapeaux["nego_" + id] = 0.85
		t = "Un peu de marchandage : moins quinze pour cent. (%d contre %d)" % [moi, lui]
	else:
		m.fiche.drapeaux["nego_" + id] = 1.15
		m.relations[b.proprietaire] = clampi(m.relations.get(b.proprietaire, 0) - 3, -100, 100)
		t = "Le vendeur se vexe : « Vous me prenez pour qui ? » Le prix monte de quinze pour cent (-3). (%d contre %d)" % [moi, lui]
	m.fiche.sauver()
	m.sauver_etat()
	Illustrations.montrer("negocier", [b.proprietaire, b.lieu], t + "\nNouveau prix : %s." % Objets.texte_prix(prix(m, b)))


static func louer(m: Node, id: String) -> void:
	var b: Dictionary = tous()[id]
	var semaine := Objets.cuivre_de(str(b.prix)) / 10
	if m.fiche.bourse < semaine:
		Illustrations.montrer("louer_refus", [b.proprietaire, b.lieu], "La première semaine se paie d'avance : il te manque %s." % Objets.texte_prix(semaine - m.fiche.bourse))
		return
	m.fiche.bourse -= semaine
	_a_moi(m)[id] = "location"
	m.fiche.drapeaux["revenus_jour"] = Horloge.jour() + 7    # la première semaine est payée
	m.fiche.sauver()
	Illustrations.montrer("louer", [b.proprietaire, b.lieu], "%s te tend la clé : « Le loyer, chaque semaine. Sinon je change la serrure. »" % _nom(m, b.proprietaire))


static func preter(m: Node, id: String) -> void:
	var b: Dictionary = tous()[id]
	var aff: int = m.relations.get(b.proprietaire, 0)
	if aff < AFFECTION_PRET:
		Illustrations.montrer("preter_refus", [b.proprietaire, b.lieu], "%s rit : « Te la prêter ? On n'est pas si proches. » (affection %d, il en faudrait %d)" % [_nom(m, b.proprietaire), aff, AFFECTION_PRET])
		return
	offrir(m, id, "pret", "%s te tend la clé : « Prends-la tant que tu en as besoin. Entre amis. »" % _nom(m, b.proprietaire))


## Un bien offert ou prêté par un événement (un noble sauvé, une dette d'honneur, un défi).
## mode : « achat » (il est à toi) ou « pret » (tant que vous restez en bons termes).
static func offrir(m: Node, id: String, mode: String, texte := "", montrer := true) -> String:
	if not tous().has(id):
		return ""
	var b: Dictionary = tous()[id]
	_a_moi(m)[id] = mode
	m.fiche.sauver()
	var t := texte if texte != "" else ("%s est à toi, en cadeau." % b.nom if mode == "achat" else "%s te prête %s." % [_nom(m, b.proprietaire), b.nom.to_lower()])
	if montrer:
		Illustrations.montrer("bien_offert", [b.proprietaire, b.lieu], t)
	return t


static func revendre(m: Node, id: String) -> void:
	var b: Dictionary = tous()[id]
	_a_moi(m).erase(id)
	var p := int(Objets.cuivre_de(str(b.prix)) * 0.75)
	m.fiche.bourse += p
	m.fiche.sauver()
	Illustrations.montrer("bien_vendre", [b.proprietaire, b.lieu], "%s rachète %s : %s. Les clés changent de main." % [_nom(m, b.proprietaire), b.nom.to_lower(), Objets.texte_prix(p)])


## Racheter un contrat de dette : il est à toi. Tu le déchires, ou tu le gardes.
static func racheter(m: Node, id: String) -> void:
	var b: Dictionary = tous()[id]
	var p := prix(m, b)
	if m.fiche.bourse < p:
		Illustrations.montrer("dette_racheter_refus", [b.proprietaire], "Orsoline referme le tiroir : « Revenez avec %s de plus. »" % Objets.texte_prix(p - m.fiche.bourse))
		return
	m.fiche.bourse -= p
	var cible: String = b.proprietaire
	contrats(m)[cible] = "garde"
	if m.pnj_donnees.has(cible):
		m.pnj_donnees[cible]["statut_social"] = "sous contrat de dette (à toi)"
	var n: Node = m._pnj_par_id(cible)
	if n:
		n.donnees["statut_social"] = "sous contrat de dette (à toi)"
	m.fiche.sauver()
	var nom := _nom(m, cible)
	Illustrations.montrer("dette_racheter", [cible], "Orsoline compte les pièces et te tend le contrat de %s. « À vous. »" % nom)
	await Illustrations.ferme
	m.fenetres.choix("Le contrat de %s" % nom, "Le papier est dans ta main.", [
		["Le déchirer, là, tout de suite", liberer.bind(m, n), "Libre. Il te le doit (+30)."],
		["Le garder", func(): pass, "Il est à toi. Rien d'intime, jamais, tant qu'il est sous contrat."]])


static func liberer(m: Node, n: Node) -> void:
	if n == null:
		return
	_liberer_id(m, n.id)
	var nom: String = Donnees.prenom(n.donnees.nom)
	var t := "Tu déchires le contrat de %s. Un long silence. Puis : « Pourquoi ? » Tu n'as pas besoin de répondre (+30)." % nom
	if n.id == Vesperine.ID:
		t = "Tu ouvres le collier. Vesperine se masse le cou, longtemps, sans te quitter des yeux : « Tu sais ce que je suis. Et tu fais ça quand même. » (+30)"
	Illustrations.montrer("liberer", [n.id], t)


static func _liberer_id(m: Node, id: String) -> void:
	contrats(m).erase(id)
	var l: Array = liberes(m)
	if not id in l:
		l.append(id)
	m.fiche.drapeaux["liberes"] = l
	m.relations[id] = clampi(m.relations.get(id, 0) + 30, -100, 100)
	if m.pnj_donnees.has(id):
		m.pnj_donnees[id]["statut_social"] = "libre (contrat racheté)"
	var n: Node = m._pnj_par_id(id)
	if n:
		n.donnees["statut_social"] = "libre (contrat racheté)"
		if n.suit:
			Compagnons.laisser(m, n)
	if id == Vesperine.ID:
		m.fiche.drapeaux["vesperine"] = "rachetee"
		m.fiche.drapeaux["vesperine_rachat_jour"] = Horloge.jour()
		if n:
			n.donnees["detresse"] = "1"     # deux jours pour respirer avant quoi que ce soit
	m.fiche.sauver()
	m.sauver_etat()


static func _assigner(m: Node, n: Node, quoi: String) -> void:
	if quoi == "equipe":
		if Compagnons.occupees(m) >= Compagnons.places(m):
			Illustrations.montrer("contrat_refus", [n.id], "Ton équipe est au complet.")
			return
		contrats(m)[n.id] = "equipe"
		Compagnons.prendre(m, n)
	else:
		if n.suit:
			Compagnons.laisser(m, n)
		contrats(m)[n.id] = quoi
	m.fiche.sauver()
	var nom: String = Donnees.prenom(n.donnees.nom)
	var t: String = {"travail": "%s travaille pour toi, sans un mot. Tu touches ce qu'il gagne." % nom,
		"equipe": "%s ramasse ses affaires et te suit, les yeux baissés." % nom,
		"garde": "%s reste où il est." % nom}[quoi]
	Illustrations.montrer("contrat_" + quoi, [n.id], t)
