# Toi, captif (monde/chronique/joueur/jour_002_avec_joueur.md, [V-toi-pris] ; jour 3 [Toi-matelot],
# [Toi-entretien]). Perdre contre Silas à la crique, la nuit du jour 1, quand tu vaux quelque chose
# pour lui (homme-bête, démon ; un étranger sans papiers, une fois sur deux) : la cellule, la
# charrette du jour 2, la vente à Pierrefane, puis matelot de Daunel (For 12 et plus) ou à
# l'entretien chez Orsoline.
#
# Le fil « captif » : cellule, charrette, vente, matelot, entretien ; libre quand c'est fini.
# Captif : pas de voyage, pas d'achat de biens, rien d'intime (un captif ne peut pas consentir,
# et le jeu ne te met jamais au service intime de qui que ce soit). On en sort par les scènes
# (les liens à la halte, la cale et Yann, le bureau et les clés, l'évasion par la lande, sauter à
# l'eau), en rachetant ton contrat, ou si un allié te rachète.
class_name Captif
extends RefCounted

const ETATS := ["cellule", "charrette", "vente", "matelot", "entretien"]


static func est(m: Node) -> bool:
	return Scenes.fil(m, "captif") in ETATS


## Silas t'a battu à la crique. Vaux-tu quelque chose pour lui ?
static func pris_a_la_crique(m: Node) -> bool:
	var f: Fiche = m.fiche
	if f.peuple in ["homme_bete", "demon"] or randf() < 0.5:
		Scenes.poser(m, "captif", "cellule")
		f.drapeaux["vesperine"] = "capturee"
		var p: Vector2 = m.lieux.comptoir.pos
		m.joueur.position = Vector3(p.x, m.hauteur(p.x, p.y), p.y)
		# tu te réveilles à l'aube, dans la cellule, à côté d'elle
		Horloge.avancer(fposmod(5.5 - Horloge.heure(), 24.0) * 60.0)
		f.sauver()
		Illustrations.montrer("captif_cellule", ["captif", Vesperine.ID], "Le noir. Puis une odeur de cave, de sel et de goudron. Ton cou est lourd : un collier de fer. À côté de toi, dans la paille, elle respire lentement. Au-dessus, des bottes sur le plancher du comptoir. Silas, à quelqu'un : « Deux pour le prix d'une charrette. »")
		return true
	return false


## La vente de 11 h : Daunel prend les forts, Orsoline le reste.
static func vendu(m: Node) -> String:
	var fort: bool = int(m.fiche.stats_totales().For) >= 12
	Scenes.poser(m, "captif", "matelot" if fort else "entretien")
	m.fiche.drapeaux["vesperine"] = "capturee"
	m.fiche.drapeaux["vente_faite"] = true
	m.fiche.sauver()
	if fort:
		return "Orsoline achète Vesperine quatre pièces d'or. Toi, le capitaine Daunel te tâte l'épaule comme un cheval : « Deux pièces. Il grattera ma coque. » Tu dormiras dans la cale du Goéland gris."
	return "Orsoline achète Vesperine quatre pièces d'or, et toi pour une : « Pour la plonge et le ménage. Rien d'autre, mon cher : je ne vends pas ce qui ne sait rien faire. » Tu dormiras sous l'escalier des Lanternes."


## Libre. texte : comment.
static func fin(m: Node, texte: String = "") -> void:
	Scenes.poser(m, "captif", "libre")
	m.fiche.drapeaux.erase("collier_toi")
	m.fiche.sauver()
	if texte != "":
		Illustrations.montrer("captif_libre", ["captif"], texte)


## Chaque seconde : la charrette t'emmène à Pierrefane (arrivée à 10 h 45, pour la vente de 11 h).
static func surveiller(m: Node) -> void:
	if Scenes.fil(m, "captif") != "vente" or m.carte != "brumeval":
		return
	if m.fenetres.ouvert != "" or Illustrations.ouvert or m.combat != null:
		return
	var h: float = Horloge.heure()
	if h < 7.75:
		Horloge.avancer((7.75 - h) * 60.0)
	m.voyager("pierrefane")
