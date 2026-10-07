# L'écran de création de personnage (monde/creation_personnage.md).
# Tout est rangé par étape, chaque étape a son « au hasard », et on peut tout laisser
# par défaut pour jouer vite. Le personnage est toujours adulte.
extends CanvasLayer

signal fini(fiche: Fiche)

const ETAPES := ["Peuple et lignée", "Identité", "Caractéristiques", "Caractère", "Valeurs et passions",
	"Vie d'avant", "Avantages et défauts", "Réveil : tenue et objet", "Nom et options"]
const NOMS_STATS := {"For": "Force", "Agi": "Agilité", "End": "Endurance", "Vit": "Vitalité", "Rob": "Robustesse",
	"Int": "Intelligence", "Sag": "Sagesse", "Per": "Perception", "Vol": "Volonté"}

var c := {}                       # les choix en cours
var etape := 0
var _etapes: VBoxContainer
var _contenu: VBoxContainer
var _apercu: Label
var _commencer: Button
var _titre: Label


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_defauts()
	var fond := ColorRect.new()
	fond.color = Color(0.06, 0.06, 0.08)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + m, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)
	var haut := Label.new()
	haut.text = "Avant de te réveiller dans le bois de Ronceval…"
	haut.add_theme_font_size_override("font_size", 24)
	col.add_child(haut)
	var ligne := HBoxContainer.new()
	ligne.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ligne.add_theme_constant_override("separation", 16)
	col.add_child(ligne)
	_etapes = VBoxContainer.new()
	_etapes.custom_minimum_size = Vector2(230, 0)
	ligne.add_child(_etapes)
	var milieu := VBoxContainer.new()
	milieu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(milieu)
	_titre = Label.new()
	_titre.add_theme_font_size_override("font_size", 20)
	milieu.add_child(_titre)
	var defile := ScrollContainer.new()
	defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	milieu.add_child(defile)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 6)
	defile.add_child(_contenu)
	_apercu = Label.new()
	_apercu.custom_minimum_size = Vector2(300, 0)
	_apercu.size_flags_horizontal = Control.SIZE_SHRINK_END
	_apercu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ligne.add_child(_apercu)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 10)
	col.add_child(bas)
	_bouton_simple(bas, "Au hasard (cette étape)", func(): _hasard(etape); _afficher())
	_bouton_simple(bas, "Tout au hasard", func():
		for i in ETAPES.size():
			_hasard(i)
		_afficher())
	_bouton_simple(bas, "← Étape précédente", func(): etape = maxi(0, etape - 1); _afficher())
	_bouton_simple(bas, "Étape suivante →", func(): etape = mini(ETAPES.size() - 1, etape + 1); _afficher())
	var vide := Control.new()
	vide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bas.add_child(vide)
	_commencer = _bouton_simple(bas, "Se réveiller", _terminer)
	_afficher()


func _defauts() -> void:
	c = {"peuple": "humain", "lignee": "", "sexe": "Homme", "pronoms": "il", "age": 25, "astre": "lune",
		"repartition": {}, "archetype": "neutre", "valeurs": [], "passions": [], "vie": "debrouillard",
		"traits": [], "tenue": "ailleurs", "objet_ailleurs": "", "nom": "",
		"options": {"chiffres": "complet", "adulte": true, "mort_definitive": false}}
	_preset("Équilibré")


func _bouton_simple(parent: Control, texte: String, appel: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.pressed.connect(appel)
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- affichage

func _afficher() -> void:
	for n in _etapes.get_children():
		n.queue_free()
	for i in ETAPES.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, ETAPES[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.button_pressed = i == etape
		b.pressed.connect(func(): etape = i; _afficher())
		_etapes.add_child(b)
	for n in _contenu.get_children():
		_contenu.remove_child(n)
		n.queue_free()
	_titre.text = ETAPES[etape]
	match etape:
		0: _etape_peuple()
		1: _etape_identite()
		2: _etape_stats()
		3: _etape_caractere()
		4: _etape_valeurs()
		5: _etape_vie()
		6: _etape_traits()
		7: _etape_reveil()
		8: _etape_nom()
	_maj_apercu()


func _texte(t: String, attenue := false) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if attenue:
		l.modulate = Color(1, 1, 1, 0.7)
	_contenu.add_child(l)


## Une liste de choix : options = [[id, libellé, explication], …]. Un seul choisi.
func _choix(cle: String, options: Array, colonnes := 1) -> void:
	var grille := GridContainer.new()
	grille.columns = colonnes
	grille.add_theme_constant_override("h_separation", 6)
	_contenu.add_child(grille)
	for o in options:
		var b := Button.new()
		b.text = o[1]
		b.toggle_mode = true
		b.button_pressed = c.get(cle) == o[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if o.size() > 2 and o[2] != "":
			b.tooltip_text = o[2]
		b.pressed.connect(func(): c[cle] = o[0]; _apres_choix(cle))
		grille.add_child(b)


## Plusieurs choix possibles, au plus « maxi ».
func _choix_multiples(cle: String, options: Array, maxi_: int, colonnes := 3) -> void:
	var grille := GridContainer.new()
	grille.columns = colonnes
	_contenu.add_child(grille)
	for o in options:
		var b := Button.new()
		b.text = o
		b.toggle_mode = true
		b.button_pressed = o in c[cle]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			if o in c[cle]:
				c[cle].erase(o)
			elif c[cle].size() < maxi_:
				c[cle].append(o)
			_afficher())
		grille.add_child(b)


func _apres_choix(cle: String) -> void:
	if cle == "peuple":
		var lig: Dictionary = CreationDonnees.LIGNEES[c.peuple]
		c.lignee = "" if lig.is_empty() else lig.keys()[0]
	_afficher()


# ---------------------------------------------------------------- les étapes

func _etape_peuple() -> void:
	var opts := []
	for k in CreationDonnees.PEUPLES:
		opts.append([k, CreationDonnees.PEUPLES[k].nom, CreationDonnees.PEUPLES[k].texte])
	_choix("peuple", opts, 3)
	_texte(CreationDonnees.PEUPLES[c.peuple].texte)
	var lig: Dictionary = CreationDonnees.LIGNEES[c.peuple]
	if not lig.is_empty():
		_texte("\n" + {"elfe": "Lignée", "nain": "Clan", "homme_bete": "Animal", "demi_sang": "Tes deux peuples", "demon": "Lignée"}[c.peuple])
		opts = []
		for k in lig:
			opts.append([k, "%s  %s" % [lig[k].nom, _stats_texte(lig[k].get("stats", {}))], lig[k].texte])
		_choix("lignee", opts, 2)
		if lig.has(c.lignee):
			_texte(lig[c.lignee].texte, true)


func _etape_identite() -> void:
	_texte("Sexe")
	_choix("sexe", CreationDonnees.SEXES.map(func(s): return [s, s]), 3)
	_texte("Pronoms (les PNJ s'y adaptent selon leur ouverture)")
	_choix("pronoms", CreationDonnees.PRONOMS.map(func(s): return [s, s]), 3)
	_texte("Âge apparent : %d ans  %s" % [c.age, _stats_texte(CreationDonnees.bonus_age(c))])
	var curseur := HSlider.new()
	curseur.min_value = 18
	curseur.max_value = 80
	curseur.value = c.age
	curseur.custom_minimum_size = Vector2(300, 24)
	curseur.value_changed.connect(func(v): c.age = int(v))
	curseur.drag_ended.connect(func(_x): _afficher())
	_contenu.add_child(curseur)
	_texte("Jeune (25 ans ou moins) : Agi +1. Mûr (40 ans et plus) : Vol +1. Âgé (60 ans et plus) : Sag +1, End −1. Pour les elfes et les démons, ce n'est que l'apparence.", true)
	_texte("\nAstre de naissance (les prêtres et les superstitieux y réagissent)")
	var opts := []
	for k in CreationDonnees.ASTRES:
		opts.append([k, "%s  %s" % [CreationDonnees.ASTRES[k].nom, _stats_texte(CreationDonnees.ASTRES[k].stats)]])
	_choix("astre", opts, 2)
	_texte("\nLe corps, le visage et le profil intime viendront avec les sprites : pour l'instant, le personnage a l'apparence de base.", true)


func _etape_stats() -> void:
	var reste := CreationDonnees.budget(c) - CreationDonnees.depenses(c)
	_texte("Tout part à %d. Répartis %d points, au plus %d au départ (avant les bonus). Baisser une caractéristique à 3 rend 2 points. Ce qui reste se garde pour plus tard (touche C)." % [CreationDonnees.BASE, CreationDonnees.budget(c), CreationDonnees.MAX_DEPART])
	_texte("Points restants : %d" % reste)
	var presets := HFlowContainer.new()
	_contenu.add_child(presets)
	for p in CreationDonnees.PRESETS:
		var b := Button.new()
		b.text = p
		b.pressed.connect(func(): _preset(p); _afficher())
		presets.add_child(b)
	var bon := CreationDonnees.bonus(c)
	var fin := CreationDonnees.stats_finales(c)
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 12)
	_contenu.add_child(grille)
	for s in Combattant.STATS:
		var r: int = c.repartition.get(s, 0)
		var l := Label.new()
		l.text = "%s : %d" % [NOMS_STATS[s], fin[s]] + ("  (%d %+d)" % [CreationDonnees.BASE + r, bon[s]] if bon.get(s, 0) != 0 else "")
		l.custom_minimum_size = Vector2(250, 0)
		grille.add_child(l)
		var moins := Button.new()
		moins.text = " − "
		moins.disabled = r <= -2
		moins.pressed.connect(func(): c.repartition[s] = r - 1; _afficher())
		grille.add_child(moins)
		var plus := Button.new()
		plus.text = " + "
		plus.disabled = reste <= 0 or CreationDonnees.BASE + r >= CreationDonnees.MAX_DEPART
		plus.pressed.connect(func(): c.repartition[s] = r + 1; _afficher())
		grille.add_child(plus)
		var vide := Label.new()
		grille.add_child(vide)


func _etape_caractere() -> void:
	_texte("Un archétype pour aller vite. Les traits vont de −100 à +100, comme pour les PNJ, et changeront avec ta vie.")
	var opts := []
	for k in CreationDonnees.ARCHETYPES:
		var t: Dictionary = CreationDonnees.ARCHETYPES[k].traits
		opts.append([k, CreationDonnees.ARCHETYPES[k].nom, ", ".join(t.keys().map(func(x): return "%s %+d" % [x, t[x]]))])
	_choix("archetype", opts, 3)
	var t: Dictionary = CreationDonnees.ARCHETYPES[c.archetype].traits
	_texte(", ".join(t.keys().map(func(x): return "%s %+d" % [x, t[x]])) if t else "Neutre partout.", true)


func _etape_valeurs() -> void:
	_texte("3 valeurs au plus : ce qui fait monter ou baisser ton moral, et les PNJ qui s'entendent avec toi.")
	_choix_multiples("valeurs", CreationDonnees.VALEURS, 3, 5)
	_texte("\n3 passions au plus : les pratiquer remonte le moral, et ceux qui les partagent deviennent vite des amis.")
	_choix_multiples("passions", CreationDonnees.PASSIONS, 3, 5)


func _etape_vie() -> void:
	_texte("Tu viens d'ailleurs. Personne ici ne le saura jamais : on te prendra pour un étranger d'un pays lointain.")
	var opts := []
	for k in CreationDonnees.VIES:
		opts.append([k, "%s  %s" % [CreationDonnees.VIES[k].nom, _stats_texte(CreationDonnees.VIES[k].stats)], CreationDonnees.VIES[k].texte])
	_choix("vie", opts, 2)
	_texte(CreationDonnees.VIES[c.vie].texte, true)


func _etape_traits() -> void:
	var solde := CreationDonnees.solde_traits(c)
	_texte("On part de 0 : un avantage coûte des points, un défaut en rapporte. Le total doit rester à 0 ou plus. %d avantages et %d défauts au plus. Ce qui est marqué « plus tard » est gardé, mais pas encore en jeu." % [CreationDonnees.MAX_TRAITS, CreationDonnees.MAX_TRAITS])
	_texte("Solde : %d" % solde)
	var nb_av: int = c.traits.filter(func(k): return CreationDonnees.TRAITS[k].cout > 0).size()
	var nb_def: int = c.traits.filter(func(k): return CreationDonnees.TRAITS[k].cout < 0).size()
	for titre in ["Avantages", "Défauts"]:
		_texte("\n" + titre)
		var grille := VBoxContainer.new()
		_contenu.add_child(grille)
		for k in CreationDonnees.TRAITS:
			var t: Dictionary = CreationDonnees.TRAITS[k]
			if (t.cout > 0) != (titre == "Avantages"):
				continue
			var b := Button.new()
			b.text = "%s (%s%d) : %s" % [t.nom, "−" if t.cout > 0 else "+", absi(t.cout), t.texte]
			b.toggle_mode = true
			b.button_pressed = k in c.traits
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.clip_text = true
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.tooltip_text = t.texte
			var plein: bool = (nb_av if t.cout > 0 else nb_def) >= CreationDonnees.MAX_TRAITS
			b.disabled = not (k in c.traits) and plein
			b.pressed.connect(func():
				if k in c.traits:
					c.traits.erase(k)
				else:
					c.traits.append(k)
				_afficher())
			grille.add_child(b)


func _etape_reveil() -> void:
	_texte("Ce que tu portes en te réveillant.")
	var opts := []
	for k in CreationDonnees.TENUES:
		opts.append([k, CreationDonnees.TENUES[k].nom, CreationDonnees.TENUES[k].texte])
	_choix("tenue", opts, 2)
	_texte(CreationDonnees.TENUES[c.tenue].texte, true)
	_texte("\nUn objet de l'autre monde, ou aucun. Il ne fait rien de magique, mais il peut se vendre très cher ou attirer les voleurs.")
	opts = []
	for k in CreationDonnees.OBJETS_AILLEURS:
		opts.append([k, CreationDonnees.OBJETS_AILLEURS[k].nom, Objets.get_(k).get("description", "")])
	_choix("objet_ailleurs", opts, 4)
	if c.objet_ailleurs != "":
		_texte(Objets.get_(c.objet_ailleurs).description, true)
	_texte("\nTu portes aussi un anneau que tu n'as pas mis toi-même. La Lame sans nom, elle, ne se choisit pas : on la trouve dans le bois, ou non.", true)


func _etape_nom() -> void:
	_texte("Ton nom")
	var ligne := HBoxContainer.new()
	_contenu.add_child(ligne)
	var champ := LineEdit.new()
	champ.text = c.nom
	champ.placeholder_text = "Ton nom"
	champ.custom_minimum_size = Vector2(300, 0)
	champ.text_changed.connect(func(t): c.nom = t.strip_edges(); _maj_apercu())
	ligne.add_child(champ)
	_bouton_simple(ligne, "Proposer un nom", func(): c.nom = _nom_au_hasard(); _afficher())
	_texte("\nAffichage des chiffres")
	_choix_option("chiffres", [["complet", "Complet (LitRPG)"], ["partiel", "Partiel"], ["cache", "Caché"]])
	_texte("Contenu adulte (scènes intimes entre adultes consentants)")
	_choix_option("adulte", [[true, "Activé"], [false, "Désactivé"]])
	_texte("La mort")
	_choix_option("mort_definitive", [[false, "Presque jamais définitive (capture, dette)"], [true, "Mort définitive"]])
	_texte("\nSeul l'affichage complet des chiffres et le contenu adulte (activé ou non) changent déjà le jeu ; la mort définitive viendra avec la capture.", true)


func _choix_option(cle: String, options: Array) -> void:
	var ligne := HBoxContainer.new()
	_contenu.add_child(ligne)
	for o in options:
		var b := Button.new()
		b.text = o[1]
		b.toggle_mode = true
		b.button_pressed = c.options[cle] == o[0]
		b.pressed.connect(func(): c.options[cle] = o[0]; _afficher())
		ligne.add_child(b)


# ---------------------------------------------------------------- aperçu et fin

func _stats_texte(d: Dictionary) -> String:
	if d.is_empty():
		return ""
	return "(" + ", ".join(d.keys().map(func(s): return "%s %+d" % [s, d[s]])) + ")"


func _maj_apercu() -> void:
	var fin := CreationDonnees.stats_finales(c)
	var lignes := []
	var peuple: String = CreationDonnees.PEUPLES[c.peuple].nom
	var lig: Dictionary = CreationDonnees.LIGNEES[c.peuple].get(c.lignee, {})
	lignes.append("%s" % (c.nom if c.nom != "" else "(sans nom)"))
	lignes.append("%s%s · %s, %d ans" % [peuple, " (%s)" % lig.nom if lig else "", c.sexe.to_lower(), c.age])
	lignes.append("Vie d'avant : %s" % CreationDonnees.VIES[c.vie].nom)
	lignes.append("")
	for s in Combattant.STATS:
		lignes.append("%s %d" % [s, fin[s]])
	var pv: int = 20 + fin.Vit * 8 + 4
	if "robuste" in c.traits:
		pv = roundi(pv * 1.15)
	if "fragile" in c.traits:
		pv = roundi(pv * 0.85)
	lignes.append("")
	lignes.append("PV %d · mana %d · endurance %d" % [pv, fin.Sag * 6 + fin.Int * 2, 20 + fin.End * 5])
	lignes.append("Vitesse %d · déplacement %d · saut %d" % [10 + fin.Agi + (3 if "rapide" in c.traits else 0), 3 + int(fin.Agi / 10.0), 1 + int(fin.Agi / 15.0)])
	var reste := CreationDonnees.budget(c) - CreationDonnees.depenses(c)
	lignes.append("Points non répartis : %d" % reste)
	var solde := CreationDonnees.solde_traits(c)
	lignes.append("Avantages et défauts : solde %d" % solde)
	if c.traits:
		lignes.append(", ".join(c.traits.map(func(k): return CreationDonnees.TRAITS[k].nom)))
	var probleme := _probleme()
	if probleme != "":
		lignes.append("\n" + probleme)
	_apercu.text = "\n".join(lignes)
	_commencer.disabled = probleme != ""


func _probleme() -> String:
	if c.nom == "":
		return "Il te faut un nom (étape 9)."
	if CreationDonnees.solde_traits(c) < 0:
		return "Trop d'avantages : ajoute un défaut ou retire un avantage (étape 7)."
	if CreationDonnees.depenses(c) > CreationDonnees.budget(c):
		return "Trop de points dépensés (étape 3)."
	return ""


func _preset(nom: String) -> void:
	c.repartition = {}
	for s in CreationDonnees.PRESETS[nom]:
		c.repartition[s] = CreationDonnees.PRESETS[nom][s]


func _nom_au_hasard() -> String:
	return CreationDonnees.PRENOMS[c.peuple].pick_random()


func _hasard(i: int) -> void:
	match i:
		0:
			c.peuple = CreationDonnees.PEUPLES.keys().pick_random()
			var lig: Dictionary = CreationDonnees.LIGNEES[c.peuple]
			c.lignee = "" if lig.is_empty() else lig.keys().pick_random()
		1:
			c.sexe = CreationDonnees.SEXES.pick_random()
			c.pronoms = {"Homme": "il", "Femme": "elle", "Intersexe": CreationDonnees.PRONOMS.pick_random()}[c.sexe]
			c.age = randi_range(18, 60)
			c.astre = CreationDonnees.ASTRES.keys().pick_random()
		2:
			_preset(CreationDonnees.PRESETS.keys().pick_random())
		3:
			c.archetype = CreationDonnees.ARCHETYPES.keys().pick_random()
		4:
			c.valeurs = CreationDonnees.VALEURS.duplicate()
			c.valeurs.shuffle()
			c.valeurs = c.valeurs.slice(0, 3)
			c.passions = CreationDonnees.PASSIONS.duplicate()
			c.passions.shuffle()
			c.passions = c.passions.slice(0, 3)
		5:
			c.vie = CreationDonnees.VIES.keys().pick_random()
		6:
			c.traits = []
			var avantages := CreationDonnees.TRAITS.keys().filter(func(k): return CreationDonnees.TRAITS[k].cout > 0)
			var defauts := CreationDonnees.TRAITS.keys().filter(func(k): return CreationDonnees.TRAITS[k].cout < 0)
			c.traits.append(defauts.pick_random())
			c.traits.append(avantages.pick_random())
			while CreationDonnees.solde_traits(c) < 0:
				var d: String = defauts.pick_random()
				if not d in c.traits:
					c.traits.append(d)
		7:
			c.tenue = ["ailleurs", "ailleurs", "simples", "haillons", "nu"].pick_random()
			c.objet_ailleurs = CreationDonnees.OBJETS_AILLEURS.keys().pick_random()
		8:
			c.nom = _nom_au_hasard()


func _terminer() -> void:
	if _probleme() != "":
		return
	var choix := c.duplicate(true)
	var caractere := {}
	for t in ["sociable", "honnete", "colerique", "courageux", "curieux", "genereux", "ambitieux", "orgueilleux",
			"empathique", "prudent", "romantique", "pieux", "rancunier", "pudique", "joueur"]:
		caractere[t] = CreationDonnees.ARCHETYPES[c.archetype].traits.get(t, 0)
	choix.caractere = caractere
	choix.affinites = CreationDonnees.affinites_au_hasard(c.peuple)
	var f := Fiche.depuis_creation(choix)
	f.points = maxi(0, CreationDonnees.budget(c) - CreationDonnees.depenses(c))
	fini.emit(f)
	queue_free()
