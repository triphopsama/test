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
	ok(Classes.classes().size() == 19 and Classes.metiers().size() == 6, "19 classes et 6 métiers lus (%d, %d)" % [Classes.classes().size(), Classes.metiers().size()])
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
	ok(f.pv > 10 and f.mana_actuelle() == mana0 - 6, "Soin léger hors combat : PV %d, mana −6" % f.pv)
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
		ok(r1.pv < pv_rat, "Éclat de glace touche toujours (%d → %d PV)" % [pv_rat, r1.pv])
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


func _pnj(id: String) -> Node:
	for n in monde.pnjs:
		if n.id == id:
			return n
	return null


func _ids(liste: Array) -> Array:
	return liste.map(func(l): return l.id)
