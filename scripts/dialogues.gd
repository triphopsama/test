class_name Dialogues
extends RefCounted
## Arbres de dialogue des PNJ du village.
##
## Format d'un PNJ :
##   "entries" : liste de {"if": condition, "goto": nœud}, la première qui
##               passe choisit le nœud de départ (sans "if" = par défaut).
##   "nodes"   : nœuds {"text", "effects", "choices", "next"}.
## "text" peut être une liste de variantes {"if", "text"}.
## "lyra" (optionnel) choisit l'expression de Lyra : souriante, clin_oeil,
## colere, surprise, triste, rougissante (sinon déduite des effets).
## Un choix a "text", un "if" optionnel, et soit "next", soit
## "roll": {"chance", "success", "fail"} (actions risquées comme le vol).
## Conditions et effets : voir GameState.check() et GameState.apply_effects().

const DATA := {
	"chef": {
		"name": "Chef Aldric",
		"entries": [
			{"if": {"flag": "gobelins_vaincus"}, "goto": "merci"},
			{"if": {"opinion_max": -30}, "goto": "hostile"},
			{"if": {"flag": "quete_acceptee"}, "goto": "rappel"},
			{"if": {"flag": "quete_refusee"}, "goto": "reconsidere"},
			{"goto": "intro"},
		],
		"nodes": {
			"intro": {
				"lyra": "surprise",
				"text": "Ah, Lyra. Les gobelins de la colline pillent nos réserves depuis des semaines. Peux-tu nous en débarrasser ?",
				"choices": [
					{"text": "Bien sûr. C'est mon devoir.", "next": "accepte"},
					{"text": "Combien ça paie ?", "next": "negocie"},
					{"text": "Débrouillez-vous sans moi.", "next": "refus"},
				],
			},
			"accepte": {
				"text": "Merci ! Prépare-toi bien : certains villageois pourraient t'aider, s'ils te font confiance. Reviens me voir quand tu seras prête.",
				"effects": {"opinion": 10, "reputation": 5, "set": "quete_acceptee"},
			},
			"negocie": {
				"text": "Hmph. 30 pièces d'or, payées d'avance. C'est tout ce que le village peut offrir.",
				"effects": {"opinion": -5},
				"choices": [
					{"text": "Marché conclu.", "next": "paye"},
					{"text": "Gardez votre or. Je le ferai quand même.", "next": "genereux"},
				],
			},
			"paye": {
				"text": "Voilà ton or. J'espère qu'il en vaut la peine.",
				"effects": {"gold": 30, "set": ["quete_acceptee", "paye_avance"]},
			},
			"genereux": {
				"text": "... Je t'avais mal jugée. Le village n'oubliera pas ta générosité.",
				"effects": {"opinion": 20, "reputation": 10, "set": "quete_acceptee"},
			},
			"refus": {
				"lyra": "colere",
				"text": "Je vois. Le village s'en souviendra.",
				"effects": {"opinion": -15, "reputation": -5, "witnessed": -5, "set": "quete_refusee"},
			},
			"reconsidere": {
				"text": "Tu as changé d'avis pour les gobelins ?",
				"choices": [
					{"text": "Oui. Je m'en charge.", "next": "accepte"},
					{"text": "Non.", "next": "fin_seche"},
				],
			},
			"fin_seche": {"text": "Alors ne me fais pas perdre mon temps."},
			"rappel": {
				"text": [
					{"if": {"opinion_min": 40}, "text": "Tout le village compte sur toi, Lyra. Prête à partir pour la colline ?"},
					{"text": "Alors, prête à partir pour la colline ?"},
				],
				"choices": [
					{"text": "Oui, en route ! [Combat]", "next": "depart"},
					{"text": "Pas encore.", "next": "attendre"},
				],
			},
			"depart": {
				"lyra": "colere",
				"text": "Que les dieux te protègent.",
				"effects": {"battle": true},
			},
			"attendre": {"text": "Ne tarde pas trop."},
			"hostile": {
				"lyra": "triste",
				"text": "Tu oses te montrer ici après ce que tu as fait ? Va-t'en.",
				"choices": [
					{"text": "Je suis désolée. Prenez ces 20 pièces en dédommagement.", "if": {"gold_min": 20}, "next": "excuses"},
					{"text": "...", "next": "fin_seche"},
				],
			},
			"excuses": {
				"text": "Hmm. Les actes comptent plus que l'or, mais c'est un début.",
				"effects": {"gold": -20, "opinion": 30, "reputation": 5},
			},
			"merci": {
				"text": [
					{"if": {"flag": "vol_forge"}, "text": "Tu as sauvé le village... même si certains murmurent des choses à ton sujet. Merci, Lyra."},
					{"text": "Grâce à toi, le village est sauf ! Tu seras toujours la bienvenue ici."},
				],
			},
		},
	},
	"forge": {
		"name": "Brunhild la forgeronne",
		"entries": [
			{"if": {"opinion_max": -30}, "goto": "ferme"},
			{"if": {"flag": "vol_forge"}, "goto": "disparue"},
			{"if": {"flag": "epee_obtenue"}, "goto": "apres"},
			{"goto": "intro"},
		],
		"nodes": {
			"intro": {
				"text": "Bienvenue à la forge ! Cette épée d'acier est ma plus belle pièce : 40 pièces d'or.",
				"choices": [
					{"text": "Je la prends. (-40 or)", "if": {"gold_min": 40}, "next": "achat"},
					{"text": "Je pars affronter les gobelins. Un geste ?", "if": {"flag": "quete_acceptee", "opinion_min": 30}, "next": "don"},
					{"text": "Je pars affronter les gobelins. Un geste ?", "if": {"flag": "quete_acceptee", "opinion_max": 29}, "next": "pas_de_don"},
					{"text": "Votre travail est magnifique.", "if": {"not_flag": "forge_compliment"}, "next": "compliment"},
					{"text": "[Voler] Subtiliser l'épée", "roll": {"chance": 0.45, "success": "vol_reussi", "fail": "vol_rate"}},
					{"text": "Au revoir.", "next": "au_revoir"},
				],
			},
			"achat": {
				"text": "Bon choix ! Elle te servira bien. (Lyra : ATQ +4)",
				"effects": {"gold": -40, "opinion": 5, "set": "epee_obtenue"},
			},
			"don": {
				"text": "Pour protéger le village ? Prends-la. Ce sera mon combat à moi aussi. (Lyra : ATQ +4)",
				"effects": {"opinion": 10, "set": "epee_obtenue"},
			},
			"pas_de_don": {"text": "Désolée, je dois manger aussi. Si tu veux l'épée, c'est 40 pièces."},
			"compliment": {
				"lyra": "clin_oeil",
				"text": "Ha ! Enfin quelqu'un qui sait reconnaître du bon travail.",
				"effects": {"opinion": 15, "set": "forge_compliment"},
				"next": "intro",
			},
			"vol_reussi": {
				"lyra": "clin_oeil",
				"text": "*Pendant que Brunhild tourne le dos, tu glisses l'épée sous ta cape.* (Lyra : ATQ +4)",
				"effects": {"set": ["epee_obtenue", "vol_forge"], "reputation": -5},
			},
			"vol_rate": {
				"lyra": "surprise",
				"text": "AU VOLEUR ! Repose ça immédiatement ! Tout le monde va savoir ce que tu es !",
				"effects": {"opinion": -50, "reputation": -15, "witnessed": -25},
			},
			"au_revoir": {"text": "Reviens quand tu veux."},
			"ferme": {"text": "Je ne sers pas les voleurs. Dehors."},
			"disparue": {
				"lyra": "clin_oeil",
				"text": "Étrange... Ma plus belle épée a disparu. Tu n'aurais rien vu, par hasard ?",
			},
			"apres": {"text": "Prends soin de cette lame, elle te le rendra."},
		},
	},
	"kael": {
		"name": "Kael le chasseur",
		"entries": [
			{"if": {"flag": "kael_recrute"}, "goto": "groupe"},
			{"if": {"opinion_max": -20}, "goto": "mefiant"},
			{"goto": "intro"},
		],
		"nodes": {
			"intro": {
				"text": [
					{"if": {"opinion_min": 30}, "text": "Lyra. Toujours un plaisir. Qu'est-ce qui t'amène ?"},
					{"text": "Hm. Je traque les loups qui rôdent avec les gobelins. Qu'est-ce que tu veux ?"},
				],
				"choices": [
					{"text": "Viens avec moi affronter les gobelins.", "if": {"opinion_min": 30}, "next": "recrute"},
					{"text": "Viens avec moi affronter les gobelins.", "if": {"opinion_max": 29}, "next": "pas_confiance"},
					{"text": "Parle-moi de la colline.", "if": {"not_flag": "kael_info"}, "next": "info"},
					{"text": "Je t'offre 15 pièces pour ton aide. (-15 or)", "if": {"gold_min": 15, "not_flag": "kael_paye"}, "next": "payer"},
					{"text": "Ton arc a l'air bien usé...", "next": "vexe"},
					{"text": "Au revoir.", "next": "bye"},
				],
			},
			"recrute": {
				"text": "Avec toi ? D'accord. Mon arc est à toi. (Kael rejoint le groupe)",
				"effects": {"set": "kael_recrute", "opinion": 5},
			},
			"pas_confiance": {"text": "Je ne te connais pas assez pour te confier ma vie."},
			"info": {
				"text": "Les loups craignent les flèches et les lames. Le golem, lui, ne cède qu'à la lance et au feu. Frappe leurs faiblesses pour briser leur garde.",
				"effects": {"opinion": 10, "set": "kael_info"},
				"next": "intro",
			},
			"payer": {
				"text": "L'or ne fait pas tout... mais ça montre que tu prends ça au sérieux.",
				"effects": {"gold": -15, "opinion": 20, "set": "kael_paye"},
				"next": "intro",
			},
			"vexe": {
				"lyra": "surprise",
				"text": "Cet arc appartenait à mon père. Fais attention à ce que tu dis.",
				"effects": {"opinion": -15},
			},
			"bye": {"text": "Bonne chasse."},
			"groupe": {"text": "Je suis prêt quand tu l'es. Va voir le chef."},
			"mefiant": {"text": "On raconte des choses sur toi au village. Passe ton chemin."},
		},
	},
	"mira": {
		"name": "Mira la mage",
		"entries": [
			{"if": {"flag": "mira_recrutee"}, "goto": "groupe"},
			{"if": {"rep_max": -10}, "goto": "rep_basse"},
			{"goto": "intro"},
		],
		"nodes": {
			"intro": {
				"text": "Je suis Mira, mage itinérante. J'étudie le feu... et les gens. Surtout la façon dont ils parlent des autres.",
				"choices": [
					{"text": "Rejoins-nous contre les gobelins.", "if": {"rep_min": 15}, "next": "recrute"},
					{"text": "Rejoins-nous contre les gobelins.", "if": {"rep_max": 14}, "next": "hesite"},
					{"text": "Que dit-on de moi ?", "next": "rumeur"},
					{"text": "Au revoir.", "next": "bye"},
				],
			},
			"recrute": {
				"text": "Ta réputation te précède : les villageois disent du bien de toi. J'accepte. (Mira rejoint le groupe)",
				"effects": {"set": "mira_recrutee", "opinion": 10},
			},
			"hesite": {"text": "Je ne te connais pas. Gagne la confiance de ces gens, et on en reparlera. (Réputation 15 requise)"},
			"rumeur": {
				"text": [
					{"if": {"rep_min": 15}, "text": "Qu'on peut compter sur toi. C'est rare."},
					{"if": {"rep_max": -1}, "text": "Rien de bon. Les regards se détournent quand tu passes."},
					{"text": "Pas grand-chose. Tu es encore une inconnue ici."},
				],
				"next": "intro",
			},
			"bye": {"text": "À bientôt, peut-être."},
			"groupe": {"text": "Mes flammes sont prêtes."},
			"rep_basse": {"text": "Les villageois te craignent. Je ne m'associe pas à ce genre de personne."},
		},
	},
	"pip": {
		"name": "Pip",
		"entries": [
			{"if": {"opinion_max": -20}, "goto": "peur"},
			{"goto": "intro"},
		],
		"nodes": {
			"intro": {
				"text": [
					{"if": {"flag": "gobelins_vaincus"}, "text": "T'as battu les gobelins !! Quand je serai grand, je serai comme toi !"},
					{"text": "Salut ! T'es une aventurière ? Tu vas tuer les gobelins ?"},
				],
				"choices": [
					{"text": "Tiens, une pièce pour toi. (-1 or)", "if": {"gold_min": 1, "not_flag": "pip_piece"}, "next": "piece"},
					{"text": "Quelles sont les nouvelles ?", "next": "nouvelles"},
					{"text": "Dégage, gamin.", "next": "rudoie"},
				],
			},
			"piece": {
				"text": "Merci !! T'es la meilleure ! Je vais le dire à tout le monde !",
				"effects": {"gold": -1, "opinion": 20, "reputation": 5, "witnessed": 5, "set": "pip_piece"},
			},
			"nouvelles": {
				"text": [
					{"if": {"flag": "vol_forge"}, "text": "Brunhild a perdu sa plus belle épée ! Elle dit qu'un voleur traîne au village..."},
					{"if": {"rep_min": 15}, "text": "Tout le monde parle de toi ! Même la mage aux cheveux rouges a demandé qui t'étais."},
					{"if": {"rep_max": -10}, "text": "Maman dit que je dois pas te parler..."},
					{"text": "Kael dit que le golem de la colline craint le feu. Et la forgeronne aime bien qu'on admire ses épées !"},
				],
			},
			"rudoie": {
				"lyra": "colere",
				"text": "*Pip court se cacher derrière sa mère. Plusieurs villageois te dévisagent.*",
				"effects": {"opinion": -30, "reputation": -5, "witnessed": -10},
			},
			"peur": {"text": "*Pip s'enfuit en courant.*"},
		},
	},
}


## Texte du nœud, en résolvant les variantes conditionnelles.
static func resolve_text(text, speaker: String) -> String:
	if text is String:
		return text
	for variant in text:
		if GameState.check(variant.get("if", {}), speaker):
			return variant["text"]
	return ""


static func entry_node(npc_id: String) -> String:
	for entry in DATA[npc_id]["entries"]:
		if GameState.check(entry.get("if", {}), npc_id):
			return entry["goto"]
	return ""
