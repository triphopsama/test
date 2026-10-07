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
	ok(monde.pnjs.filter(func(n): return n.id != Vesperine.ID).size() == 19, "19 PNJ au village (%d)" % monde.pnjs.size())
	ok(monde.actions.lignes.size() >= 10, "actions lues (%d)" % monde.actions.lignes.size())
	ok(monde.praticable(monde.lieux.reveil.pos), "on peut marcher à la clairière du réveil")
	ok(not monde.praticable(Vector2(50, 600)), "on ne marche pas sur la mer")
	print("== Trajets")
	var c: PackedVector2Array = monde.chemin("place", "crique")
	ok(c.size() >= 2, "un chemin place > crique (%d étapes)" % c.size())
	var c2: PackedVector2Array = monde.chemin("reveil", "forge")
	ok(c2.size() >= 3, "un chemin réveil > forge (%d étapes)" % c2.size())
	print("== Heure : jour %d, %s, marée basse : %s" % [Horloge.jour(), Horloge.texte_heure(), Horloge.maree_basse()])
	print("== PNJ")
	for n in monde.pnjs:
		print("  %-20s %-14s > %-12s visible=%s" % [n.donnees.nom, n.lieu_actuel, n.lieu_cible, n.visible])
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
	ok(Illustrations.ouvert and Illustrations._texte.text.contains("Pas encore"), "Mara dit non quand l'affection est basse")
	Illustrations.fermer()
	monde.relations["BRU001"] = 50
	monde.actions.executer(ligne, mara, "boulangerie")
	ok(Illustrations._texte.text.contains("regard"), "Mara accepte : sans texte écrit dans actions.csv, un texte suggéré")
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
	ok(monde.fenetres._liste.get_child_count() >= 9, "la fiche montre les 9 caractéristiques")
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
	await _classes_metiers(mara, tim)
	await _magie(mara)
	await _intime()
	await _defis()
	await _vesperine()
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
	print("== Bêtes à ta taille")
	var rat := Combattant.bete("rat", 1, monde.joueur)
	ok(rat.niveau == 1 and rat.pv_max < 40, "un rat géant : niveau 1, %d PV" % rat.pv_max)
	var crabe := Combattant.bete("crabe", 0, monde.joueur)
	ok(crabe.ventre_mou and crabe.def_phys > 20, "le crabe-rocher : carapace %d, ventre mou" % crabe.def_phys)
	f = Fiche.new()
	monde.fiche = f
	f.ajouter("OBJ002")
	f.equiper("OBJ002")
	var tav: Vector2 = monde.lieux.taverne.pos + Vector2(0, 6)
	monde.joueur.position = Vector3(tav.x, monde.hauteur(tav.x, tav.y), tav.y)
	var rats: Dictionary = {}
	for l in monde.actions.disponibles(null, "taverne"):
		if l.id == "chasser_rats":
			rats = l
	ok(not rats.is_empty(), "on peut chasser les rats de la cave de Rosalie")
	monde.actions.executer(rats, null, "taverne")
	await get_tree().process_frame
	Illustrations.fermer()
	await get_tree().process_frame
	ok(monde.combat != null, "les rats attaquent")
	if monde.combat:
		var r4 = await monde.combat.fini
		await get_tree().process_frame
		ok(r4 != "victoire" or f.bourse >= 12, "chasse aux rats : %s, bourse %s" % [r4, Objets.texte_prix(f.bourse)])
		Illustrations.fermer()
	monde.actions.executer(rats, null, "taverne")
	ok(Illustrations._texte.text.contains("déjà"), "une fois par jour")
	Illustrations.fermer()
	var bois_p: Vector2 = monde.lieux.reveil.pos
	monde.joueur.position = Vector3(bois_p.x, monde.hauteur(bois_p.x, bois_p.y), bois_p.y)
	monde._prochaine_rencontre.clear()
	var vu := false
	for i in 200:
		monde._t_rencontres = 10.0
		monde._surveiller_rencontres(0.0)
		if Illustrations.ouvert:
			vu = true
			break
	ok(vu, "une bête finit par surgir dans le bois (%s)" % Illustrations._texte.text.left(40))
	Illustrations.fermer()
	await get_tree().process_frame
	if monde.combat:
		await monde.combat.fini
		await get_tree().process_frame
		Illustrations.fermer()
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


func _classes_metiers(mara: Node, tim: Node) -> void:
	print("== Classes et métiers")
	ok(Classes.classes().size() == 19 and Classes.metiers().size() == 7, "19 classes et 7 métiers lus (%d, %d)" % [Classes.classes().size(), Classes.metiers().size()])
	for id in Classes.classes():
		for p in Classes.classe(id).competences:
			ok(Combattant.COMPETENCES.has(p[0]), "%s : la compétence %s existe" % [id, p[0]])
	ok(Classes.par_nom("Voleuse") == "voleur" and Classes.par_nom("Garde") == "garde" and Classes.par_nom("Prêtresse de combat") == "pretre_combat" and Classes.par_nom("Mage de soin") == "mage_soin", "les classes des PNJ se retrouvent")
	ok(Classes.offre({"arc": 4, "distance": 4})[0] == "archer", "tirer à l'arc : on te propose Archer")
	ok(Classes.offre({"poings": 3, "prise": 3})[0] == "lutteur", "se battre à mains nues et saisir : Lutteur")
	ok(Classes.offre({"betes": 3, "frappe": 2})[0] == "chasseur_monstres", "chasser les bêtes : Chasseur de monstres")
	ok(Classes.offre({}).is_empty(), "rien fait, rien proposé")
	var f := Fiche.new()
	monde.fiche = f
	f.prendre_classe("guerrier")
	ok(f.niveau_classe == 1 and "parade" in f.apprises and not "cri_guerre" in f.apprises, "Guerrier niveau 1 : Parade, pas encore Cri de guerre")
	ok("parade" in Combattant.joueur(monde.joueur, f).competences, "la Parade sert en combat")
	var total := 0
	for st in f.stats:
		total += f.stats[st]
	f.gagner_xp(50)
	var total2 := 0
	for st in f.stats:
		total2 += f.stats[st]
	ok(f.niveau == 2 and f.points == 2 and total2 == total + 2, "un niveau avec une classe : 2 points d'office, 2 libres")
	ok(f.niveau_classe == 2, "la classe monte aussi (niveau %d)" % f.niveau_classe)
	f.gagner_xp(100)
	ok(f.niveau_classe >= 3 and "cri_guerre" in f.apprises, "niveau de classe 3 : Cri de guerre appris")
	f.stats.Vol = 7
	ok(not "cri_guerre" in f.competences() and "cri_guerre" in f.competences(true), "Cri de guerre attend Vol 8")
	f.stats.Vol = 8
	ok("cri_guerre" in f.competences(), "à Vol 8, on s'en sert")
	f.prendre_classe("lancier")
	ok(f.niveau_classe == 1 and "parade" in f.apprises and "allonge" in f.apprises, "changer de classe : niveau 1, on garde ses compétences")
	f.annonces.clear()
	# les PNJ suivent les mêmes règles
	var bram_c := Combattant.depuis_pnj(_pnj("BRU002").donnees, _pnj("BRU002"))
	ok("parade" in bram_c.competences and "cri_guerre" in bram_c.competences, "Bram, guerrier niveau 12 : Parade et Cri de guerre")
	var corentin := Combattant.depuis_pnj(_pnj("BRU014").donnees, _pnj("BRU014"))
	ok("bouclier_leve" in corentin.competences and "coup_bouclier" in corentin.competences and not "provocation" in corentin.competences,
		"Corentin, garde : le bouclier, mais pas la Provocation (Vol 6, il faut 8)")
	# les métiers
	ok(Classes.metier_pour("travailler", "forge") == "forgeron" and Classes.metier_pour("pecher", "port") == "pecheur", "travailler à la forge : forgeron ; pêcher : pêcheur")
	ok(f.travailler("forgeron", 3.0, false).contains("5 h"), "3 h à la forge : encore 5 h")
	ok(f.travailler("forgeron", 3.0, true).contains("apprenti") and f.metier == "forgeron", "avec Bram, ça va deux fois plus vite : apprenti forgeron")
	ok(f.travailler("boulanger", 8.0, false) == "propose", "une journée au fournil : on propose de changer")
	var prix_avant: int = monde.fenetres.prix_vente("OBJ002")
	f.metier = ""
	ok(prix_avant > monde.fenetres.prix_vente("OBJ002"), "un forgeron revend mieux une dague (%d)" % prix_avant)
	f.prendre_metier("boulanger")
	var four: Dictionary = {}
	for l in monde.actions.disponibles(null, "boulangerie"):
		if l.id == "travailler":
			four = l
	for i in 2:
		monde.actions.executer(four, null, "boulangerie")
		Illustrations.fermer()
	ok(f.nombre("OBJ327") >= 1, "boulanger : un pain toutes les deux heures")
	monde.fenetres.offre_metier("forgeron")
	ok(monde.fenetres._liste.get_child_count() == 2, "la fenêtre propose de changer de métier")
	monde.fenetres._prendre_metier("forgeron")
	ok(f.metier == "forgeron" and f.niveau_metier == 1, "on change : forgeron niveau 1")
	monde.fenetres.fermer()
	# l'offre de classe
	f.classe = ""
	f.style = {"dague": 3, "dos": 2}
	monde.fenetres.offre_classe()
	ok(monde.fenetres._liste.get_child_count() >= 2, "la fenêtre propose des classes")
	monde.fenetres._prendre_classe("voleur")
	ok(f.classe == "voleur" and "vol_tire" in f.apprises, "on devient voleur")
	monde.fenetres.personnage()
	ok(monde.fenetres._liste.get_child_count() > 9, "la fiche montre aussi les compétences")
	monde.fenetres.fermer()
	# vol à la tire : la victime et les témoins s'en souviennent
	f.stats.Agi = 10
	ok(_ids(monde.actions.disponibles(mara, "boulangerie")).has("vol_tire"), "un voleur peut faire les poches de Mara")
	ok(not _ids(monde.actions.disponibles(tim, "place")).has("vol_tire"), "pas celles d'un enfant")
	var vol: Dictionary = {}
	for l in monde.actions.disponibles(mara, "boulangerie"):
		if l.id == "vol_tire":
			vol = l
	monde.relations["BRU001"] = 0
	f.bourse = 0
	monde.actions.executer(vol, mara, "boulangerie")
	ok(f.bourse > 0 or monde.relations["BRU001"] == -30, "réussi (%s) ou pris la main dans le sac (affection %d)" % [Objets.texte_prix(f.bourse), monde.relations["BRU001"]])
	Illustrations.fermer()
	monde.actions.executer(vol, mara, "boulangerie")
	ok(Illustrations._texte.text.contains("Pas deux fois"), "une fois par jour")
	Illustrations.fermer()
	monde.relations["BRU001"] = 0
	# un combat de lancier : les compétences de zone, de soi et le style
	f = Fiche.new()
	monde.fiche = f
	f.stats = {"For": 10, "Agi": 10, "End": 9, "Vit": 7, "Rob": 9, "Int": 7, "Sag": 7, "Per": 9, "Vol": 10}
	f.ajouter("OBJ067")
	f.equiper("OBJ067")
	f.prendre_classe("lancier")
	f.niveau_classe = 3
	f._apprendre_classe()
	f.pv = f.pv_max()
	var cj := Combattant.joueur(monde.joueur, f)
	ok("allonge" in cj.competences and "mur_piques" in cj.competences and "charge" in cj.competences, "avec un trident : Allonge, Charge, Mur de piques")
	monde.combat_auto = true
	var p: Vector2 = monde.lieux.landes.pos
	monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
	monde.attaque_de_betes("rat", 2, p + Vector2(0, 4), "Des rats !")
	Illustrations.fermer()
	await get_tree().process_frame
	ok(monde.combat != null, "les rats attaquent le lancier")
	if monde.combat:
		var moi: Combattant = monde.combat.combattants.filter(func(c): return c.est_joueur)[0]
		monde.combat._attaquer(moi, moi, "mur_piques")
		ok(moi.etats.has("piques"), "Mur de piques : en garde")
		var r = await monde.combat.fini
		await get_tree().process_frame
		Illustrations.fermer()
		ok(f.style.has("lance") or f.style.has("bouge"), "le combat a noté ton style : %s (%s)" % [f.style, r])
	monde.combat_auto = false
	monde.fiche = Fiche.new()


func _action(id: String, pnj: Node, lieu: String) -> Dictionary:
	for l in monde.actions.disponibles(pnj, lieu):
		if l.id == id:
			return l
	return {}


func _magie(mara: Node) -> void:
	print("== Magie")
	ok(Classes.offre({"magie_feu": 3})[0] == "mage_elementaire" and Classes.offre({"magie_eau": 2})[0] == "mage_eau", "lancer du feu : Mage élémentaire ; de l'eau : Mage des marées")
	var c := Combattant.new()
	c.affinites = {"feu": 80}
	ok(is_equal_approx(c.bonus_affinite("feu"), 1.3) and c.cout_mana(Combattant.COMPETENCES.flamme) == 3, "affinité feu 80 : sorts de feu +30 %, Flamme à 3 mana")
	c.affinites = {"feu": 5}
	ok(c.cout_mana(Combattant.COMPETENCES.flamme) == 8, "affinité 5 : le sort coûte double")
	var rat := Combattant.bete("rat", 0, null)
	ok(rat.facteur_element("feu") == 1.5, "les rats craignent le feu (bestiaire)")
	c.affinites = {"eau": 60}
	ok(is_equal_approx(c.facteur_element("eau"), 0.7) and is_equal_approx(c.facteur_element("feu"), 1.15), "forte en eau : résiste à l'eau, craint le feu")
	var f := Fiche.new()
	monde.fiche = f
	ok(f.mana_max() == f.stats.Sag * 6 + f.stats.Int * 2, "mana : Sag × 6 + Int × 2 (%d)" % f.mana_max())
	f.ajouter("BRV030")
	ok(f.lire_parchemin("BRV030").contains("Flamme") and "flamme" in f.apprises and f.nombre("BRV030") == 0, "lire le parchemin de Flamme : sort appris")
	f.ajouter("BRV031")
	ok(f.lire_parchemin("BRV031").contains("Int 10") and f.nombre("BRV031") == 1, "Éclat de glace demande Int 10 pour comprendre")
	ok("flamme" in Combattant.joueur(monde.joueur, f).competences, "Flamme dans le menu de combat")
	# les leçons
	var agnes: Node = _pnj("BRU015")
	ok("soin_leger" in monde.lecons_de(agnes), "Agnès, mage de soin, peut t'apprendre Soin léger (%s)" % str(monde.lecons_de(agnes)))
	ok(monde.lecons_de(_pnj("BRU005")).is_empty(), "Tim (11 ans) n'enseigne rien")
	ok(not "provocation" in monde.lecons_de(_pnj("BRU014")), "Corentin n'enseigne pas ce qu'il ne sait pas faire")
	monde.relations["BRU015"] = 20
	f.bourse = 100
	monde.fenetres.lecons(agnes)
	ok(monde.fenetres._liste.get_child_count() >= 1, "la fenêtre des leçons s'ouvre")
	monde.fenetres._apprendre(agnes, "soin_leger")
	ok("soin_leger" in f.apprises and f.bourse == 64, "une leçon : 3 argent (%s)" % Objets.texte_prix(f.bourse))
	monde.fenetres.fermer()
	monde.relations["BRU015"] = 0
	print("== Hors combat")
	ok(_action("pister", null, "chene").is_empty(), "sans Pistage, pas de traces à suivre")
	f.apprises.append_array(["pistage", "piege", "respiration_eau", "lire_maree", "crochetage", "benediction"])
	f.stats.Per = 9
	f.stats.Agi = 10
	f.stats.Sag = 8
	ok(_action("pieges", null, "chene").is_empty(), "Piège demande Int 8 : pas de collets à Int 7")
	f.stats.Int = 8
	ok(not _action("pister", null, "chene").is_empty(), "avec Pistage : « Suivre des traces »")
	var pieges := _action("pieges", null, "chene")
	monde.actions.executer(pieges, null, "chene")
	ok(Illustrations._texte.text.contains("collets"), "les collets sont posés")
	Illustrations.fermer()
	f.drapeaux["piege_chene"] = Horloge.jour() - 1
	var avant_sac := f.sac.size()
	monde.actions.executer(pieges, null, "chene")
	ok(Illustrations._texte.text.contains("collet"), "le lendemain : on relève (%s)" % Illustrations._texte.text.left(50))
	Illustrations.fermer()
	var n_poisson := f.nombre("BRV003")
	monde.actions.executer(_action("lire_maree", null, "port"), null, "port")
	ok(Illustrations._texte.text.contains("Basse mer"), "lire la marée donne l'heure des basses mers")
	Illustrations.fermer()
	monde.actions.executer(_action("pecher", null, "port"), null, "port")
	ok(f.nombre("BRV003") == n_poisson + 4, "pêcher après avoir lu la marée : 4 maquereaux")
	Illustrations.fermer()
	monde.actions.executer(_action("plonger", null, "crique"), null, "crique")
	ok(Illustrations._texte.text.contains("pièces"), "plonger : des pièces au fond")
	Illustrations.fermer()
	monde.actions.executer(_action("crocheter", null, "falaise"), null, "falaise")
	ok(Illustrations._texte.text.contains("%"), "crocheter : réussi ou raté, selon l'Agi")
	Illustrations.fermer()
	f.pv = 10
	var mana0 := f.mana_actuelle()
	monde.actions.executer(_action("soigner_soi", null, "place"), null, "place")
	ok(f.pv > 10 and f.mana_actuelle() == mana0 - 6, "Soin léger hors combat : PV %d, mana -6" % f.pv)
	Illustrations.fermer()
	var bram: Node = _pnj("BRU002")
	monde.relations["BRU002"] = 0
	monde.actions.executer(_action("soigner", bram, "forge"), bram, "forge")
	ok(monde.relations["BRU002"] == 10 and Illustrations._texte.text.contains("tremblent"), "soigner Bram : ses mains, son secret (+10)")
	Illustrations.fermer()
	monde.relations["BRU002"] = 0
	monde.relations["BRU001"] = 0
	f.mana = -1
	monde.actions.executer(_action("benir", mara, "boulangerie"), mara, "boulangerie")
	ok(monde.relations["BRU001"] == 6, "bénir Mara, qui est pieuse : +6 (%d)" % monde.relations["BRU001"])
	Illustrations.fermer()
	monde.relations["BRU001"] = 0
	f.pv = 10
	monde.actions.executer(_action("feu_camp", null, "chene"), null, "chene")
	ok(f.pv > 10, "un feu de camp avec Flamme : +PV")
	Illustrations.fermer()
	monde.actions.executer(_action("feu_camp", null, "chene"), null, "chene")
	ok(Illustrations._texte.text.contains("déjà"), "un feu par jour")
	Illustrations.fermer()
	# un combat de mage contre des rats
	f = Fiche.new()
	monde.fiche = f
	f.stats.Int = 12
	f.stats.Sag = 10
	f.apprises = ["flamme", "eclat_glace", "soin_leger", "purification", "arme_enflammee"]
	f.affinites = {"feu": 40}
	monde.combat_auto = true
	var p: Vector2 = monde.lieux.landes.pos
	monde.joueur.position = Vector3(p.x, monde.hauteur(p.x, p.y), p.y)
	monde.attaque_de_betes("rat", 2, p + Vector2(0, 4), "Des rats !")
	Illustrations.fermer()
	await get_tree().process_frame
	ok(monde.combat != null, "les rats attaquent le mage")
	if monde.combat:
		var moi: Combattant = monde.combat.combattants.filter(func(x): return x.est_joueur)[0]
		var r1: Combattant = monde.combat.combattants.filter(func(x): return x.est_bete)[0]
		var pv_rat := r1.pv
		monde.combat._attaquer(moi, r1, "eclat_glace")
		ok(r1.pv < pv_rat, "Éclat de glace touche toujours (%d > %d PV)" % [pv_rat, r1.pv])
		monde.combat._attaquer(moi, moi, "arme_enflammee")
		ok(moi.etats.has("arme_feu"), "Arme enflammée : l'arme brûle")
		moi.etats["gel"] = 3
		monde.combat._attaquer(moi, moi, "purification")
		ok(not moi.etats.has("gel"), "Purification chasse le gel")
		var r = await monde.combat.fini
		await get_tree().process_frame
		Illustrations.fermer()
		ok(f.style.has("magie_feu") or f.style.has("magie_glace"), "le combat note la magie (%s, %s)" % [f.style, r])
		ok(f.affinite("feu") > 40 or f.affinite("glace") > 20, "lancer des sorts fait monter l'affinité (feu %d, glace %d)" % [f.affinite("feu"), f.affinite("glace")])
		ok(f.mana_actuelle() < f.mana_max(), "la mana dépensée reste dépensée après le combat")
	monde.combat_auto = false
	monde.fiche = Fiche.new()
	Horloge.avancer(-float(Horloge._decalage) / 60.0)


func _intime() -> void:
	print("== Intime (adultes consentants)")
	var f := Fiche.new()
	monde.fiche = f
	ok(Intime.profils().size() == 21 and Intime.profil("BRU005").is_empty() and Intime.profil("BRU016").is_empty(), "21 profils d'adultes (avec Vesperine), aucun pour Tim et Nina")
	ok(Intime.gestes().size() >= 15, "%d gestes de scène" % Intime.gestes().size())
	# personne d'autre autour : pas de témoins
	var caches := []
	for n in monde.pnjs:
		if n.visible:
			caches.append(n)
			n.visible = false
	var elise: Node = _pnj("BRU013")
	var isaure: Node = _pnj("BRU019")
	var silas: Node = _pnj("BRU003")
	var aldric: Node = _pnj("BRU007")
	for n in [elise, isaure, silas, aldric]:
		n.visible = true
	monde.joueur.position = elise.position + Vector3(1, 0, 0)
	monde.relations["BRU013"] = 10
	ok(Intime.consentement(monde, elise, "nuit").contains("Pas encore"), "affection 10 : Élise dit pas encore")
	monde.relations["BRU013"] = 65
	ok(Intime.consentement(monde, elise, "nuit") == "", "affection 65 : Élise dit oui")
	monde.relations["BRU007"] = 90
	ok(Intime.consentement(monde, aldric, "embrasser").contains("attires"), "Aldric aime les femmes : tu ne l'attires pas")
	f.sexe = "Femme"
	ok(Intime.consentement(monde, aldric, "embrasser").contains("avec quelqu'un"), "marié à Clémence : il ne trompe pas")
	f.sexe = "Homme"
	_seul_avec(isaure, [elise, isaure, silas, aldric])
	monde.relations["BRU019"] = 70
	monde.desirs["BRU019"] = 0
	ok(Intime.consentement(monde, isaure, "nuit").contains("Pas encore"), "Isaure cherche l'amour : pas de nuit sans être ensemble (%s)" % Intime.consentement(monde, isaure, "nuit"))
	# l'âge : Élise (38 ans) préfère les plus jeunes
	f.age = 22
	ok(Intime.a_son_gout(monde, elise) == 1, "22 ans : Élise, 38 ans, aime ça (cougar)")
	f.age = 50
	ok(Intime.a_son_gout(monde, elise) == -1, "50 ans : pas son genre")
	f.age = 17
	ok(Intime.consentement(monde, elise, "embrasser").contains("majeurs"), "jamais avant 18 ans")
	f.age = 25
	monde.desirs["BRU013"] = 100
	# la scène
	var sc := Intime.nouvelle_scene(monde, [elise], "moulin")
	for i in 40:
		Intime.jouer(monde, sc, "amour_passion")
		if sc.fini:
			break
	ok(sc.barres["BRU013"].comble, "Élise aime le rapide : comblée (%d)" % sc.barres["BRU013"].plaisir)
	ok(sc.barres["BRU013"].fois == Intime.profil("BRU013").endurance, "Élise, endurance %d : comblée %d fois avant d'être épuisée" % [Intime.profil("BRU013").endurance, sc.barres["BRU013"].fois])
	ok(Intime.gestes().size() >= 45, "%d gestes" % Intime.gestes().size())
	var avant: int = monde.relations["BRU013"]
	Intime.finir(monde, sc, "partir")
	ok(monde.relations["BRU013"] > avant and "art_aimer" in f.apprises and f.nuits.get("BRU013", 0) == 1, "une belle nuit : affection en hausse, Art d'aimer appris")
	ok(Intime.desir(monde, "BRU013") == 0, "comblée : son désir retombe à 0")
	var sc2 := Intime.nouvelle_scene(monde, [isaure], "atelier")
	var lignes := []
	for i in 3:
		lignes.append_array(Intime.jouer(monde, sc2, "jeu_pouvoir"))
	ok(sc2.barres["BRU019"].stop and "\n".join(lignes).contains(Intime.MOT_D_ARRET), "un jeu qu'Isaure refuse : le mot d'arrêt, tout s'arrête")
	Intime.finir(monde, sc2, "partir")
	monde.relations["BRU013"] = 75
	ok(Intime._reveler(monde, elise, Intime.profil("BRU013"), false).contains("fantasme"), "elle t'aime (75) : elle avoue son fantasme")
	var sc3 := Intime.nouvelle_scene(monde, [elise], "moulin")
	ok("\n".join(Intime.jouer(monde, sc3, "role")).contains("rêvait"), "le vivre : « exactement ce dont il rêvait »")
	Intime.jouer(monde, Intime.nouvelle_scene(monde, [elise], "moulin"), "demander")
	ok(not f.gouts_connus.get("BRU013", []).is_empty(), "lui demander ce qu'elle aime : une envie révélée (%s)" % str(f.gouts_connus.get("BRU013", [])))
	# harem et jalousie
	_seul_avec(isaure, [elise, isaure, silas, aldric])
	monde.relations["BRU019"] = 90
	ok(Intime.consentement(monde, isaure, "couple") == "", "Isaure accepte d'être ensemble : %s" % Intime.consentement(monde, isaure, "couple"))
	Intime.devenir_couple(monde, isaure)
	monde.relations["BRU013"] = 90
	var a_isaure: int = monde.relations["BRU019"]
	var t := Intime.devenir_couple(monde, elise)
	ok(monde.relations["BRU019"] < a_isaure and t.contains("Isaure"), "un harem : Isaure, jalouse, le vit mal (%s)" % t)
	ok(Intime.consentement(monde, isaure, "nuit") != "", "Isaure ne partage pas")
	# le pacte, un jeu convenu
	_seul_avec(silas, [elise, isaure, silas, aldric])
	monde.relations["BRU003"] = 90
	ok(Intime.pacte(monde, silas, "maitre").contains("genoux"), "Silas, dominant, refuse d'être mené")
	ok(Intime.pacte(monde, silas, "esclave").contains(Intime.MOT_D_ARRET) and f.pactes["BRU003"] == "esclave", "pacte avec Silas : toi à son service, avec un mot d'arrêt")
	# les rumeurs
	var mara: Node = _pnj("BRU001")
	mara.visible = true
	mara.position = monde.joueur.position + Vector3(3, 0, 0)
	monde.relations["BRU001"] = 0
	ok(Intime.rumeur(monde, [elise], "une nuit").contains("Mara"), "Mara a vu : ça se sait")
	ok(monde.relations["BRU001"] < 0 and monde.relations["BRU019"] < a_isaure, "la prude Mara et la jalouse Isaure t'en veulent")
	# les actions et la fenêtre
	ok(_ids(monde.actions.disponibles(elise, "moulin")).has("passer_la_nuit") and _ids(monde.actions.disponibles(elise, "moulin")).has("rompre"), "les actions intimes et « rompre » avec Élise")
	ok(not _ids(monde.actions.disponibles(elise, "moulin")).has("proposer_couple"), "déjà ensemble : pas de nouvelle proposition")
	mara.visible = false
	monde.relations["BRU013"] = 90
	monde.desirs["BRU013"] = 80
	monde.scene_intime([elise], "moulin")
	await get_tree().process_frame
	var fen = monde.get_children().filter(func(c): return c.has_method("_geste"))
	ok(not fen.is_empty() and get_tree().paused, "la fenêtre de nuit s'ouvre (le monde attend)")
	if not fen.is_empty():
		fen[0]._geste("embrasser")
		ok(fen[0]._boutons.get_child_count() >= 10, "des gestes à choisir (%d)" % fen[0]._boutons.get_child_count())
		fen[0]._arreter()
		fen[0]._finir("rester")
		await get_tree().process_frame
		ok(not get_tree().paused or Illustrations.ouvert, "on arrête quand on veut ; le récit s'affiche")
		Illustrations.fermer()
	# le désir à son comble : seul, ou avec quelqu'un selon leurs relations
	var bram: Node = _pnj("BRU002")
	var lucas: Node = _pnj("BRU012")
	for n in [bram, isaure, lucas]:
		n.visible = true
		n.position = elise.position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	elise.visible = false
	monde.desirs["BRU002"] = 100
	monde.desirs["BRU019"] = 80
	ok(Intime.partenaire_pour(monde, bram) == isaure, "Bram, à son comble, se tourne vers Isaure, qui se rapproche de lui")
	ok(Intime._lien(bram, lucas) == "famille", "Bram et Lucas : père et fils, jamais")
	monde.desirs["BRU019"] = 0
	ok(Intime.partenaire_pour(monde, bram) == null, "Isaure n'en a pas envie : Bram reste seul")
	monde.desirs["BRU002"] = 100
	monde.joueur.position = bram.position + Vector3(2, 0, 0)
	monde.surprendre(bram)
	await get_tree().process_frame
	ok(Illustrations.ouvert and Illustrations._texte.text.contains("Bram"), "tu surprends Bram (%s)" % Illustrations._texte.text.left(50))
	Illustrations.fermer()
	await get_tree().process_frame
	ok(monde.fenetres.ouvert == "choix" and monde.fenetres._liste.get_child_count() == 2, "te montrer ou partir sans bruit")
	monde.fenetres._choisir_option(monde._partir_sans_bruit.bind([bram]))
	ok(Illustrations.ouvert, "tu pars : on voit ce qui s'ensuit")
	Illustrations.fermer()
	ok(Intime.desir(monde, "BRU002") == 0, "il s'est soulagé : son désir retombe")
	# l'équipe : 4 au plus, elle te suit
	print("== Équipe")
	monde.relations["BRU002"] = 40
	ok(Compagnons.peut_suivre(monde, bram).contains("pas assez"), "Bram (affection 40) ne te suit pas encore")
	monde.relations["BRU002"] = 75
	ok(Compagnons.peut_suivre(monde, bram) == "", "affection 75 : il te suit")
	Compagnons.prendre(monde, bram)
	ok(bram.suit and "BRU002" in f.equipiers, "Bram est dans l'équipe")
	ok(Compagnons.peut_suivre(monde, _pnj("BRU005")).contains("enfant"), "un enfant ne te suit pas")
	f.equipiers.append_array(["X1", "X2", "X3"])
	monde.relations["BRU012"] = 90
	ok(Compagnons.peut_suivre(monde, lucas).contains("complet"), "4 au plus")
	for x in ["X1", "X2", "X3"]:
		f.equipiers.erase(x)
	ok(Compagnons.allies(monde).size() == 1, "l'équipe se bat avec toi")
	# la tenue : un pacte où tu mènes, et un profil qui s'y prête
	ok(Compagnons.habiller(monde, bram, "nu", true).contains("pacte"), "sans pacte, pas question")
	monde.relations["BRU022"] = 90
	var mouche: Node = _pnj("BRU022")
	mouche.visible = true
	f.pactes["BRU022"] = "maitre"
	Intime.profil("BRU022").bdsm = 50
	ok(Compagnons.peut_suivre(monde, mouche) == "", "Mouche, avec qui tu as un pacte, te suit")
	Compagnons.prendre(monde, mouche)
	f.ajouter("BRV041")
	f.ajouter("BRV044")
	for n in monde.pnjs:
		if int(n.donnees.get("age", "0")) < 18:
			n.position = Vector3(9999, 0, 9999)
	ok(Compagnons.habiller(monde, mouche, "BRV041", true) == "" and Compagnons.habiller(monde, mouche, "nu", true) == "", "Mouche aime le risque : cagoule et nu·e")
	ok(Compagnons.habiller(monde, mouche, "BRV044", true) == "" and Compagnons.description(monde, "BRU022").contains("ne se voit pas"), "le plug : ça ne se voit pas, mais c'est dit")
	var corentin: Node = _pnj("BRU014")
	corentin.visible = true
	corentin.position = monde.joueur.position + Vector3(4, 0, 0)
	monde.relations["BRU014"] = 0
	f.bourse = 100
	var lignes2 := Compagnons.reactions(monde)
	ok("\n".join(lignes2).contains("Corentin") and not Compagnons.tenue(monde, "BRU022").nu, "Corentin verbalise : on rhabille Mouche (%s)" % "\n".join(lignes2).left(80))
	Compagnons.habiller(monde, mouche, "nu", true)
	var tim: Node = _pnj("BRU005")
	tim.visible = true
	tim.position = mouche.position + Vector3(3, 0, 0)
	ok(Compagnons.couvrir_si_enfant(monde).contains("enfant") and Compagnons.choc(monde, "BRU022") == 0, "un enfant approche : on couvre tout, aussitôt")
	Compagnons.laisser(monde, mouche)
	Compagnons.laisser(monde, bram)
	ok(f.equipiers.is_empty() and not mouche.suit and f.nombre("BRV041") == 1, "ils rentrent chez eux, les accessoires reviennent dans ton sac")
	Intime.profil("BRU022").bdsm = 0
	for n in caches:
		n.visible = true
	Horloge.avancer(-float(Horloge._decalage) / 60.0)   # la nuit a fait avancer l'horloge
	for id in ["BRU001", "BRU003", "BRU007", "BRU013", "BRU019"]:
		monde.relations[id] = 0
	monde.desirs.clear()
	monde.sauver_etat()
	monde.fiche = Fiche.new()


func _defis() -> void:
	print("== Défis et entraînement")
	var f := Fiche.new()
	monde.fiche = f
	monde.combat_auto = true
	ok(Defis.tous().size() >= 7, "%d défis lus" % Defis.tous().size())
	var bram: Node = _pnj("BRU002")
	var pierrick: Node = _pnj("BRU020")
	var elise: Node = _pnj("BRU013")
	var lucas: Node = _pnj("BRU012")
	monde.relations["BRU002"] = 0
	ok(Defis.de(monde, bram).size() == 1, "Bram a un défi pour toi")
	f.stats.For = 40   # assez pour gagner à coup sûr
	Defis.accepter(monde, bram, "bram_bras_de_fer")
	ok(Illustrations._texte.text.contains("cède") and "parade" in f.apprises and monde.relations["BRU002"] == 10, "le bras de fer gagné : Bram t'apprend la parade")
	Illustrations.fermer()
	ok(Defis.de(monde, bram).is_empty(), "un défi par jour")
	f.stats.For = 7
	Defis.accepter(monde, pierrick, "pierrick_peau")
	Illustrations.fermer()
	ok(f.defis_actifs.has("pierrick_peau"), "le défi de Pierrick attend sa peau de loup")
	ok(_ids(monde.actions.disponibles(pierrick, monde.lieu_proche(pierrick.pos2d(), 40.0))).has("defis"), "« Les défis de Pierrick » pour la rendre")
	f.ajouter("OBJ407")
	Defis.rendre(monde, pierrick, "pierrick_peau")
	ok("pistage" in f.apprises and f.nombre("OBJ407") == 0 and f.bourse == 12, "la peau rendue : Pistage appris, 12 cuivre")
	Illustrations.fermer()
	# le défi intime d'Élise : trois fois dans la même nuit
	var caches := []
	for n in monde.pnjs:
		if n.visible and n != elise:
			caches.append(n)
			n.visible = false
	elise.visible = true
	monde.joueur.position = elise.position + Vector3(1, 0, 0)
	monde.relations["BRU013"] = 80
	var sc := Intime.nouvelle_scene(monde, [elise], "moulin")
	sc["defi"] = {"defi": "elise_trois", "fois": 3, "pnj": "BRU013"}
	var lignes := []
	for i in 40:
		lignes.append_array(Intime.jouer(monde, sc, "amour_passion"))
		if sc.fini:
			break
	ok(sc.defi.compte == 3 and sc.barres["BRU013"].comble, "Élise comblée trois fois (%d)" % sc.defi.get("compte", 0))
	ok("\n".join(lignes).contains("en redemande"), "… et entre deux, elle en redemande")
	Intime.finir(monde, sc, "rester")
	Defis.resoudre(monde, elise, "elise_trois", sc.defi.compte >= 3)
	ok("danse_lascive" in f.apprises, "défi relevé : Élise t'apprend la danse")
	Illustrations.fermer()
	for n in caches:
		n.visible = true
	# une lutte avec Lucas, jouée par l'IA
	lucas.visible = true
	monde.joueur.position = lucas.position + Vector3(2, 0, 0)
	monde.relations["BRU012"] = 0
	Defis.accepter(monde, lucas, "lucas_lutte")
	await get_tree().process_frame
	ok(monde.combat != null and monde.combat.mode == "bagarre", "le défi de Lucas : une lutte")
	if monde.combat:
		var r = await monde.combat.fini
		await get_tree().process_frame
		Illustrations.fermer()
		await get_tree().process_frame
		ok(Illustrations._texte.text.contains("Lucas"), "le défi se résout (%s) : %s" % [r, Illustrations._texte.text.left(50)])
		Illustrations.fermer()
	# l'entraînement
	var xp0 := f.xp + f.niveau * 1000
	ok(Defis.entrainer_competences(monde).contains("+15") and f.xp + f.niveau * 1000 > xp0, "une heure d'entraînement : +15 expérience")
	ok(Defis.entrainer_competences(monde).contains("déjà"), "une fois par jour")
	monde.combat_auto = false
	for id in ["BRU002", "BRU012", "BRU013", "BRU020"]:
		monde.relations[id] = 0
	monde.sauver_etat()
	monde.fiche = Fiche.new()
	Horloge.avancer(-float(Horloge._decalage) / 60.0)


func _vesperine() -> void:
	print("== Vesperine")
	var f := Fiche.new()
	monde.fiche = f
	f.drapeaux["vesperine"] = "libre"
	Vesperine.installer(monde)
	var v: Node = Vesperine.noeud(monde)
	ok(v != null and Vesperine.etat(monde) == "libre", "libre, elle est au village")
	if v == null:
		return
	var caches := []
	for n in monde.pnjs:
		if n.visible and n != v:
			caches.append(n)
			n.visible = false
	v.visible = true
	v.donnees.detresse = "1"
	monde.joueur.position = v.position + Vector3(1, 0, 0)
	monde.relations[Vesperine.ID] = 95
	ok(Intime.consentement(monde, v, "nuit").contains("faim"), "affamée et apeurée : rien d'intime, même à 95 d'affection")
	f.desir = 20
	ok(Vesperine.nourrir(monde).contains("dévore") and v.donnees.detresse == "0", "nourrie et en sécurité : la détresse s'efface")
	ok(Intime.consentement(monde, v, "nuit") == "", "libre et nourrie, elle dit oui si elle le veut")
	f.corps.sexe = "petit"
	ok(not Defis.de(monde, v).any(func(d): return d.id == "vesperine_cinq"), "petit : elle ne te met pas au défi")
	f.corps.sexe = "grand"
	ok(Defis.de(monde, v).any(func(d): return d.id == "vesperine_cinq"), "bien membré : elle te lance son défi, cinq fois cette nuit")
	var sc := Intime.nouvelle_scene(monde, [v], "agnes")
	sc["defi"] = {"defi": "vesperine_cinq", "fois": 5, "pnj": Vesperine.ID}
	for i in 80:
		Intime.jouer(monde, sc, "amour_passion")
		if sc.fini:
			break
	ok(sc.defi.compte == 5, "cinq fois (%d)" % sc.defi.compte)
	Intime.finir(monde, sc, "rester")
	monde.relations[Vesperine.ID] = 95
	Defis.resoudre(monde, v, "vesperine_cinq", true)
	ok(f.pactes.get(Vesperine.ID, "") == "maitre", "défi relevé : elle te propose un pacte où tu mènes, et tu acceptes")
	Illustrations.fermer()
	# la nuit du jour 1 : sans rien faire, elle est capturée
	Vesperine._regarder(monde)
	ok(Vesperine.etat(monde) == "capturee" and Vesperine.noeud(monde) == null, "regarder sans rien faire : capturée, elle disparaît vers Pierrefane")
	Illustrations.fermer()
	await get_tree().process_frame
	f.drapeaux["vesperine"] = ""
	f.stats.Int = 30
	f.stats.Per = 30
	if Horloge.jour() == 1:
		Vesperine.installer(monde)
	f.drapeaux["vesperine"] = "a_la_crique"
	Vesperine._parler(monde)
	ok(Vesperine.etat(monde) == "libre", "intervenir en parlant (Int et Per hautes) : Silas la lâche")
	Illustrations.fermer()
	for n in caches:
		n.visible = true
	for id in [Vesperine.ID, "BRU003", "BRU012"]:
		monde.relations[id] = 0
	monde.sauver_etat()
	monde.fiche = Fiche.new()
	Horloge.avancer(-float(Horloge._decalage) / 60.0)


## Seul avec n : les autres de la liste ne sont pas là (pas de témoins).
func _seul_avec(n: Node, tous: Array) -> void:
	for x in tous:
		x.visible = x == n
	monde.joueur.position = n.position + Vector3(1, 0, 0)


func _pnj(id: String) -> Node:
	for n in monde.pnjs:
		if n.id == id:
			return n
	return null


func _ids(liste: Array) -> Array:
	return liste.map(func(l): return l.id)
