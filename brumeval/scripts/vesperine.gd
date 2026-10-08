# Vesperine (monde/demons/vesperine.md), et la nuit du jour 1
# (monde/chronique/joueur/jour_001_avec_joueur.md, « La nuit : Vesperine »).
#
# Sans le joueur : 21 h 30 Bouche de mer, 21 h 45 elle mange des algues, 22 h 30 la falaise,
# 23 h 10 elle descend vers la crique, 23 h 20 Silas la voit, 23 h 30 la drogue et le collier :
# capturée, vendue à Pierrefane le lendemain.
# Avec le joueur : la nourrir, la guider ailleurs (la crique n'a jamais lieu), ou, à la crique,
# intervenir en parlant, faire diversion, se battre. Libre, elle vit cachée et c'est une adulte
# comme les autres. Captive, rien d'intime : elle ne peut pas consentir.
# Tant qu'elle a faim et peur (« detresse »), rien d'intime non plus.
class_name Vesperine
extends RefCounted

const ID := "VES019"
const DONNEES := {
	"id": ID, "nom": "Vesperine", "lieu": "Brumeval", "age": "140", "sexe": "femme", "peuple": "démon",
	"lignee": "succube", "statut_social": "libre, de passage", "role": "Éclaireuse de la reine démone",
	"classe": "Mage d'illusion", "niveau_classe": "24", "metier": "Espionne", "niveau_metier": "30",
	"For": "8", "Agi": "14", "End": "9", "Vit": "10", "Rob": "8", "Int": "15", "Sag": "12", "Per": "14", "Vol": "13",
	"affinites_fortes": "ombre 70, esprit 60, sang 40",
	"traits": "sociable +70, honnete -40, colerique -20, courageux +40, curieux +90",
	"profil_intime": "Succube : attirée par les hommes et les femmes, se sert de la séduction comme d'une arme, libre",
	"relations": "ennemie de Silas (BRU003) s'il l'a vue, méfiante envers les humains",
	"parole": "« Je viens du sud. Mon bateau a coulé. »",
	"detresse": "1",
}
const NUIT_1 := [[0.0, "bouche", "nuit en mer"], [21.5, "bouche", "débarque, épuisée"], [21.75, "bouche", "mange des algues crues"],
	[22.5, "falaise", "longe la falaise vers les lumières"], [23.15, "crique", "descend vers la crique"]]
const LIBRE := [[0.0, "agnes", "dort chez Agnès"], [8.0, "falaise", "guette la mer"], [13.0, "chene", "se cache au bois"],
	[18.0, "guet", "attend des lanternes au large"], [22.0, "agnes", "dort chez Agnès"]]


static func etat(m: Node) -> String:
	var e: String = m.fiche.drapeaux.get("vesperine", "")
	if e == "" and Horloge.jour() > 1:
		return "capturee"   # personne n'était là cette nuit-là
	return e


static func noeud(m: Node) -> Node:
	return m._pnj_par_id(ID)


## À l'ouverture du monde : elle est là le soir du jour 1, ou libre ensuite.
static func installer(m: Node) -> void:
	var e := etat(m)
	if e in ["capturee", "rachetee", "partie", "hangar"] or noeud(m) != null:   # vendue, ou rachetée à Pierrefane (biens.gd)
		return
	var n := preload("res://scripts/pnj.gd").new()
	n.monde = m
	n.id = ID
	n.donnees = DONNEES.duplicate()
	if e == "libre":
		n.donnees.detresse = "0" if Horloge.jour() > 1 or m.fiche.drapeaux.get("vesperine_nourrie", false) else "1"
		n.emploi = LIBRE
		if Biens.contrats(m).has(ID):
			n.donnees.statut_social = "sous contrat (à toi), le collier au cou"   # achetée à Silas sur place
	else:
		n.emploi = NUIT_1
	m.add_child(n)
	m.pnjs.append(n)


## Toutes les secondes : la crique à 23 h 20 si tu y es, sinon la capture à 23 h 30.
static func surveiller(m: Node) -> void:
	if noeud(m) == null or Horloge.jour() != 1 or etat(m) in ["libre", "capturee", "combat"]:
		return
	var h: float = Horloge.heure()
	if h >= 23.333 and not m.fiche.drapeaux.has("vesperine_choix"):
		var crique: Vector2 = m.lieux.crique.pos
		if m.joueur.pos2d().distance_to(crique) < 40.0 and m.fenetres.ouvert == "" and not Illustrations.ouvert:
			m.fiche.drapeaux["vesperine_choix"] = true
			a_la_crique(m)
			return
	if h >= 23.5 and not m.fiche.drapeaux.has("vesperine_choix"):
		capturer(m, "")


static func capturer(m: Node, texte: String) -> void:
	m.fiche.drapeaux["vesperine"] = "capturee"
	var n := noeud(m)
	if n:
		m.pnjs.erase(n)
		n.queue_free()
	m.fiche.sauver()
	if texte != "":
		Illustrations.montrer("vesperine_capturee", [ID], texte)


static func liberer(m: Node, texte: String) -> void:
	m.fiche.drapeaux["vesperine"] = "libre"
	var n := noeud(m)
	if n:
		n.emploi = LIBRE
		n.donnees.detresse = "0" if m.fiche.drapeaux.get("vesperine_nourrie", false) else "1"
	m.relations["BRU012"] = clampi(m.relations.get("BRU012", 0) + 10, -100, 100)   # Lucas, qui a refusé d'y toucher
	m.sauver_etat()
	m.fiche.sauver()
	if texte != "":
		Illustrations.montrer("vesperine_libre", [ID], texte)


## La nourrir (un pain ou un poisson) : elle dévore, et lit ce que tu lui veux.
static func nourrir(m: Node) -> String:
	var n := noeud(m)
	m.fiche.drapeaux["vesperine_nourrie"] = true
	m.relations[ID] = clampi(m.relations.get(ID, 0) + 25, -100, 100)
	var t := "Elle dévore sans un mot, les yeux dans les tiens. Ces yeux-là lisent quelque chose en toi."
	if m.fiche.desir >= 70:
		m.relations[ID] = clampi(m.relations.get(ID, 0) - 10, -100, 100)
		t += " Elle a lu que tu la veux. Elle te remercie, mais elle garde ses distances."
	else:
		t += " Ce qu'elle y lit la rassure un peu."
	if etat(m) == "libre" and n:
		n.donnees.detresse = "0"
	m.sauver_etat()
	return t


## La guider ailleurs (chez Agnès) : elle ne passe pas par la crique.
static func guider(m: Node) -> String:
	if m.relations.get(ID, 0) < 20:
		return "Elle recule : « Je ne te connais pas. » Elle a faim, elle a peur, elle va vers les lumières."
	liberer(m, "")
	var n := noeud(m)
	if n:
		n.donnees.detresse = "0" if m.fiche.drapeaux.get("vesperine_nourrie", false) else "1"
	return "Elle te suit jusque chez Agnès, qui met de l'eau à chauffer sans poser de questions. La crique, cette nuit, n'aura pas sa marchandise."


## À la crique, 23 h 20 : les choix.
static func a_la_crique(m: Node) -> void:
	var silas: Node = m._pnj_par_id("BRU003")
	var texte := "Silas et Lucas déchargent des tonneaux. Vesperine sort des rochers, trempée. Silas la regarde comme une marchandise : « Tiens. La mer nous fait des cadeaux, ce soir. »"
	Illustrations.montrer("vesperine_crique", [ID], texte)
	await Illustrations.ferme
	m.fenetres.choix("La crique, 23 h 20", texte, [
		["Intervenir en parlant", _parler.bind(m), "« Elle est avec moi. » Int et Per contre la méfiance de Silas."],
		["Faire diversion", _diversion.bind(m), "Une pierre, un cri : « La garde ! » Agi. Elle fuit dans le noir, Silas ne sait pas que c'est toi."],
		["Te battre contre Silas", _battre.bind(m, silas), "Voleur niveau 18. Lucas ne se battra pas pour lui. Très dur au niveau 1."],
		["L'acheter sur place", _acheter_crique.bind(m), "« Pour toi, six pièces d'or. » Ta bourse, les objets de ton monde, ou une dette s'il te connaît."],
		["Aider Silas", _aider_silas.bind(m), "Tu la tiens pendant qu'il la drogue. Il te paiera."],
		["Courir prévenir Corentin", _corentin.bind(m), "Il a peur du noir. Il viendra, mais quand ?"],
		["Regarder caché, sans rien faire", _regarder.bind(m), "Comme si tu n'étais pas là. Mais tu auras vu."]])


static func _acheter_crique(m: Node) -> void:
	var prix := 1440
	var silas_ok: bool = int(m.relations.get("BRU003", 0)) >= 10 or Scenes.fil(m, "silas") == "recrue"
	if _fortune(m) >= prix:
		var objets := _payer_avec_tout(m, prix)
		_a_toi_crique(m, "Silas compte, empoche%s, et te lance la clé du collier : « Elle en vaudra le double à Pierrefane. Ton affaire. »" % (" " + objets if objets != "" else ""))
	elif silas_ok:
		m.fiche.drapeaux["dette_silas"] = {"montant": prix, "jour": 5}
		Scenes.poser(m, "silas", "creancier")
		_a_toi_crique(m, "Silas sourit comme un homme qui vient de gagner plus que de l'or : « Six pièces, le jour du vote. Ou des services. » Il te lance la clé du collier.")
	else:
		capturer(m, "Silas rit : « Tu n'as rien, l'ami, et je ne te connais pas. » La drogue, le collier. Lucas recule.")


static func _a_toi_crique(m: Node, texte: String) -> void:
	m.fiche.drapeaux["vesperine"] = "libre"
	m.fiche.drapeaux["vesperine_choix"] = true
	Biens.contrats(m)[ID] = "garde"
	var n := noeud(m)
	if n:
		n.emploi = LIBRE
		n.donnees.statut_social = "sous contrat (à toi), le collier au cou"
		n.donnees.detresse = "1"
	m.relations["BRU012"] = clampi(m.relations.get("BRU012", 0) - 10, -100, 100)
	m.fiche.sauver()
	m.sauver_etat()
	Illustrations.montrer("vesperine_achetee", [ID, "crique"], texte + " Sous ton collier, rien d'intime, jamais : elle ne peut pas consentir. Tu peux l'ouvrir quand tu veux (son contrat).")


static func _aider_silas(m: Node) -> void:
	Scenes.poser(m, "silas", "complice")
	m.fiche.bourse += 60
	m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) + 20, -100, 100)
	m.relations["BRU012"] = clampi(m.relations.get("BRU012", 0) - 30, -100, 100)
	m.relations[ID] = clampi(m.relations.get(ID, 0) - 60, -100, 100)
	capturer(m, "Tu la tiens. Silas la drogue, lui passe le collier. Il te glisse cinq pièces d'argent : « Demain, huit heures, au comptoir. » Lucas te regarde : « Toi aussi, t'es une ordure. » Elle, elle a vu ton visage.")


static func _corentin(m: Node) -> void:
	Scenes.poser(m, "corentin", "crique")
	m.relations["BRU014"] = clampi(m.relations.get("BRU014", 0) + 5, -100, 100)
	m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) - 10, -100, 100)
	capturer(m, "Corentin arrive à minuit moins dix, sa lanterne à la main. La crique est vide. Il te croit quand même. Silas, lui, apprend qui l'a envoyé.")


static func _parler(m: Node) -> void:
	var t: Dictionary = m.fiche.stats_totales()
	var bonus := 5 if "seduction" in m.fiche.competences() else 0
	var moi: int = t.Int + t.Per + bonus + randi_range(1, 20)
	var lui: int = 30 + randi_range(1, 20)
	m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) - 20, -100, 100)
	if moi >= lui:
		Scenes.poser(m, "silas", "geneur")
		liberer(m, "Silas te jauge longtemps, puis crache dans le sable : « Garde-la, ta noyée. Mais je me souviendrai de ta tête. » (%d contre %d)" % [moi, lui])
	else:
		capturer(m, "Silas sourit : « Prouve-le. » Tu n'as rien à prouver. Lucas recule, Silas sort la fiole. La drogue, le collier. (%d contre %d)" % [moi, lui])


static func _diversion(m: Node) -> void:
	var moi: int = m.fiche.stats_totales().Agi + randi_range(1, 20)
	var seuil := 22 + randi_range(1, 8)
	if moi >= seuil:
		liberer(m, "Ta pierre claque sur les rochers, ton cri porte : « La garde ! » Silas et Lucas filent avec les tonneaux. Vesperine disparaît dans le noir. Tu la retrouveras à l'aube, chez Agnès.")
	else:
		m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) - 15, -100, 100)
		capturer(m, "Ta pierre roule dans le vide. Silas lève sa lanterne vers toi, puis se retourne vers elle. Trop tard.")


static func _battre(m: Node, silas: Node) -> void:
	m.fiche.drapeaux["vesperine"] = "combat"
	m.combat_contre_pnj(silas, "mortel", {"vesperine": true})


static func _regarder(m: Node) -> void:
	m.fiche.drapeaux["temoin_crique"] = true
	capturer(m, "La drogue, le collier de fer froid. Lucas recule : « Je touche pas à ça. » Silas : « Personne la cherchera. » Tu as tout vu. Ça pèsera, un jour, devant un juge.")


## Après le combat contre Silas à la crique.
static func apres_combat(m: Node, resultat: String) -> void:
	if resultat == "victoire":
		Scenes.poser(m, "silas", "ennemi")
		liberer(m, "Silas recule dans le noir en tenant son bras. Vesperine te regarde, incrédule : « Pourquoi ? » Puis elle te suit.")
	else:
		capturer(m, "Quand tu reprends tes esprits, la crique est vide. Ils l'ont emmenée.")


# ---------------------------------------------------------------- le jour 2 à Pierrefane

## La vente (monde/chronique/pierrefane/jour_002.md) : la charrette de Garec arrive à 10 h 45,
## Silas vend à 11 h, elle est aux Lanternes à 11 h 30. Si tu es là, tu peux enchérir.
const OBJETS_DAILLEURS := ["BRV011", "BRV017", "BRV014", "BRV015", "BRV012", "BRV013"]
const PRIX_SILAS := 960            # 4 pièces d'or : Orsoline paie ça ; il faut mieux
const DETTE_SILAS := 1440          # 6 pièces d'or, à rendre le jour du vote (jour 5)


## Est-elle déjà aux Lanternes ? Pas avant le jour 2 à 11 h 30, ni pendant la vente.
static func arrivee_a_pierrefane(m: Node) -> bool:
	if m.fiche.drapeaux.get("vente_faite", false):
		return true
	return Horloge.jour() > 2 or (Horloge.jour() == 2 and Horloge.heure() >= 11.5)


## Chaque seconde, à Pierrefane : la vente si tu es aux Lanternes vers 11 h, sinon elle arrive sans toi.
static func surveiller_pierrefane(m: Node) -> void:
	if m.carte != "pierrefane" or etat(m) != "capturee" or Horloge.jour() < 2 or m.joueur == null:
		return
	if m.fenetres.ouvert != "" or Illustrations.ouvert or m.combat != null:
		return
	var h: float = Horloge.heure()
	var pres: bool = m.lieux.has("lanternes") and m.joueur.pos2d().distance_to(m.lieux.lanternes.pos) < 30.0
	if Horloge.jour() == 2 and h >= 10.75 and h < 11.5 and pres and not m.fiche.drapeaux.has("vente_vue"):
		m.fiche.drapeaux["vente_vue"] = true
		vente(m)
		return
	if m._pnj_par_id(ID) == null and arrivee_a_pierrefane(m):
		Biens.installer(m)
		if pres and m.hud:
			m.hud.annoncer("Une charrette bâchée est repartie à vide. Chez Orsoline, il y a une nouvelle.")


static func vente(m: Node) -> void:
	var texte := "Une charrette bâchée devant la Maison des Lanternes. Silas en descend, frais comme au marché ; Garec soulève la bâche. Vesperine, le collier au cou, les yeux encore lourds de drogue. Orsoline la regarde comme on regarde un tissu : « Trois pièces d'or. » Silas sourit : « Quatre. »"
	Illustrations.montrer("vesperine_vente", [ID, "lanternes"], texte)
	await Illustrations.ferme
	var options := []
	var fortune := _fortune(m)
	options.append(["Enchérir : cinq pièces d'or", _encherir.bind(m), "Ta bourse et ce que tu portes de ton monde (la montre, le bijou… Silas adore ces choses-là) : %s en tout." % Objets.texte_prix(fortune)])
	options.append(["Proposer à Silas une dette", _dette.bind(m), "Six pièces d'or, le jour du vote. Silas adore tenir les gens, mais il ne fait pas crédit à un inconnu."])
	options.append(["Dire qu'elle est malade", _malade.bind(m), "Int contre Orsoline : le prix baisse, la vente traîne."])
	options.append(["Regarder sans rien dire", _laisser_vendre.bind(m), "Elle est vendue. Tu pourras revenir au salon, ou racheter son contrat plus tard (8 à 12 pièces d'or)."])
	m.fenetres.choix("La vente", texte, options)


## Ce que tu peux mettre sur la table : ta bourse et les objets de ton monde (au prix qu'en donne Silas).
static func _fortune(m: Node) -> int:
	var t: int = m.fiche.bourse
	for id in OBJETS_DAILLEURS:
		t += m.fiche.nombre(id) * maxi(0, Objets.prix(id))
	return t


static func _payer_avec_tout(m: Node, montant: int) -> String:
	var donnes := []
	var reste := montant
	for id in OBJETS_DAILLEURS:
		while reste > 0 and m.fiche.nombre(id) > 0 and Objets.prix(id) > 0:
			m.fiche.retirer(id)
			reste -= Objets.prix(id)
			donnes.append(Objets.get_(id).nom.to_lower())
	if reste > 0:
		m.fiche.bourse -= reste
	elif reste < 0:
		m.fiche.bourse += -reste      # Silas rend la monnaie, en grognant
	return ", ".join(donnes)


static func _encherir(m: Node) -> void:
	var prix := PRIX_SILAS + 240
	if _fortune(m) < prix:
		Illustrations.montrer("vesperine_vente_refus", [ID, "lanternes"], "Tu comptes. Il te manque %s. Silas rit : « Reviens quand tu seras riche, l'ami. » La vente se fait sous tes yeux." % Objets.texte_prix(prix - _fortune(m)))
		await Illustrations.ferme
		_laisser_vendre(m)
		return
	var objets := _payer_avec_tout(m, prix)
	m.relations["PIE001"] = clampi(m.relations.get("PIE001", 0) - 10, -100, 100)
	_a_toi(m, "Orsoline pince les lèvres et se retire. Silas compte, empoche%s, et te tend la clé du collier : « Elle est à toi. Fais-en ce que tu veux, ce n'est plus mon affaire. »" % (" " + objets if objets != "" else ""))


static func _dette(m: Node) -> void:
	if int(m.relations.get("BRU003", 0)) < 10:
		Illustrations.montrer("vesperine_vente_refus", [ID, "lanternes"], "Silas te regarde de haut en bas : « Je ne fais pas crédit aux inconnus. » La vente se fait sous tes yeux.")
		await Illustrations.ferme
		_laisser_vendre(m)
		return
	m.fiche.drapeaux["dette_silas"] = {"montant": DETTE_SILAS, "jour": 5}
	m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) + 5, -100, 100)
	m.relations["PIE001"] = clampi(m.relations.get("PIE001", 0) - 10, -100, 100)
	_a_toi(m, "Silas sourit comme un homme qui vient de gagner plus que de l'or : « Six pièces, le jour du vote. Ou un service. » Il te tend la clé du collier.")


static func _malade(m: Node) -> void:
	var t: Dictionary = m.fiche.stats_totales()
	if t.Int + randi_range(1, 20) >= 14 + randi_range(1, 20):
		m.fiche.drapeaux["vente_suspendue"] = Horloge.jour()
		Illustrations.montrer("vesperine_vente", [ID, "lanternes"], "« Elle tousse. Elle a la fièvre des noyés, j'en ai vu à Brumeval. » Orsoline recule d'un pas. « Deux pièces d'or. » Silas refuse, jure, et la vente traîne : elle reste enfermée chez Orsoline, pas encore vendue. Tu as gagné une nuit.")
	else:
		Illustrations.montrer("vesperine_vente", [ID, "lanternes"], "Orsoline te regarde par-dessus son lorgnon : « Elle est en meilleure santé que vous, mon cher. » Quatre pièces d'or.")
	await Illustrations.ferme
	_laisser_vendre(m, false)


static func _laisser_vendre(m: Node, montrer := true) -> void:
	m.fiche.drapeaux["vente_faite"] = true
	m.fiche.sauver()
	Biens.installer(m)
	if montrer:
		Illustrations.montrer("vesperine_vendue", [ID, "lanternes"], "Quatre pièces d'or. Orsoline note la vente dans son carnet. Vesperine passe devant toi sans te regarder ; Lysa l'attend dans le couloir avec une assiette.")


static func _a_toi(m: Node, texte: String) -> void:
	m.fiche.drapeaux["vente_faite"] = true
	Biens.contrats(m)[ID] = "garde"
	m.fiche.sauver()
	m.sauver_etat()
	Biens.installer(m)
	Illustrations.montrer("vesperine_achetee", [ID, "lanternes"], texte)
	await Illustrations.ferme
	m.fenetres.choix("La clé du collier", "La clé est dans ta main. Elle te regarde, et lit ce que tu veux d'elle.", [
		["Ouvrir le collier", Biens.liberer.bind(m, m._pnj_par_id(ID)), "Elle est libre. Elle n'a nulle part où aller, et deux jours avant de pouvoir penser à autre chose qu'à manger et dormir."],
		["Garder la clé", func(): pass, "Elle est à toi, sous contrat. Rien d'intime, jamais, tant qu'elle porte ton collier."]])


## Le jour du vote (jour 5 et après), à Brumeval : Silas réclame sa dette quand il te croise.
static func surveiller_dette(m: Node) -> void:
	var d = m.fiche.drapeaux.get("dette_silas", null)
	if not d is Dictionary or m.carte != "brumeval" or Horloge.jour() < int(d.jour):
		return
	if m.fenetres.ouvert != "" or Illustrations.ouvert or m.combat != null:
		return
	var silas: Node = m._pnj_par_id("BRU003")
	if silas == null or silas.mort or not silas.visible or silas.pos2d().distance_to(m.joueur.pos2d()) > 8.0:
		return
	if m.fiche.drapeaux.get("dette_silas_vu", -1) == Horloge.jour():
		return
	m.fiche.drapeaux["dette_silas_vu"] = Horloge.jour()
	var texte := "Silas te barre le passage, aimable : « Le jour du vote, l'ami. Six pièces d'or. Ou tu me rends un service. »"
	m.fenetres.choix("La dette de Silas", texte, [
		["Payer (%s)" % Objets.texte_prix(int(d.montant)), _payer_silas.bind(m), "Tu ne lui dois plus rien."],
		["Pas maintenant", _repousser_silas.bind(m), "Il sourit moins. Chaque jour de retard coûte."]])


static func _payer_silas(m: Node) -> void:
	var d: Dictionary = m.fiche.drapeaux["dette_silas"]
	if m.fiche.bourse < int(d.montant):
		Illustrations.montrer("dette_silas_refus", ["BRU003"], "Il te manque %s. Silas : « Demain, alors. Avec les intérêts. »" % Objets.texte_prix(int(d.montant) - m.fiche.bourse))
		d.montant = int(int(d.montant) * 1.1)
		return
	m.fiche.bourse -= int(d.montant)
	m.fiche.drapeaux.erase("dette_silas")
	m.fiche.sauver()
	Illustrations.montrer("dette_silas", ["BRU003"], "Silas compte, lentement, devant tout le monde. « Un plaisir de faire affaire. » Tu ne lui dois plus rien.")


static func _repousser_silas(m: Node) -> void:
	var d: Dictionary = m.fiche.drapeaux["dette_silas"]
	d.montant = int(int(d.montant) * 1.1)
	d["refus"] = int(d.get("refus", 0)) + 1
	m.relations["BRU003"] = clampi(m.relations.get("BRU003", 0) - 15, -100, 100)
	var t := "Silas te tapote la joue : « Dix pour cent par jour, l'ami. » (-15)"
	if int(d.refus) >= 3:
		t += " Ce soir, ses hommes viendront te rappeler ce que tu dois."
		m.relations["BRU003"] = mini(int(m.relations.get("BRU003", 0)), -60)   # il envoie Garec et Mouche
	m.sauver_etat()
	m.fiche.sauver()
	Illustrations.montrer("dette_silas_refus", ["BRU003"], t)
