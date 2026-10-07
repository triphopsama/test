# L'horloge du monde : un jour de jeu = un jour réel.
# Le jour 1 est le jour où le jeu a été lancé pour la première fois.
# Touche T : accélère le temps (×1, ×60, ×600) pour tester.
extends Node

const FICHIER := "user://monde.cfg"
const VITESSES := [1.0, 60.0, 600.0]

var acceleration := 1.0
var _decalage := 0.0      # secondes ajoutées par l'accélération
var _depart := 0.0        # minuit (heure locale) du jour 1, en secondes


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) == OK and cfg.has_section_key("monde", "depart"):
		_depart = float(cfg.get_value("monde", "depart"))
		_decalage = float(cfg.get_value("monde", "decalage", 0.0))
	else:
		_depart = floor(_local_reel() / 86400.0) * 86400.0
		_sauver()


func _process(delta: float) -> void:
	if acceleration > 1.0:
		_decalage += delta * (acceleration - 1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
		var i := VITESSES.find(acceleration)
		acceleration = VITESSES[(i + 1) % VITESSES.size()]
		_sauver()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_sauver()


func _sauver() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("monde", "depart", _depart)
	cfg.set_value("monde", "decalage", _decalage)
	cfg.save(FICHIER)


func _local_reel() -> float:
	var tz := Time.get_time_zone_from_system()
	return Time.get_unix_time_from_system() + float(tz.get("bias", 0)) * 60.0


## Secondes locales depuis 1970, accélération comprise.
func maintenant() -> float:
	return _local_reel() + _decalage


func jour() -> int:
	return int(floor((maintenant() - _depart) / 86400.0)) + 1


## Heure du jour en heures décimales (16.5 = 16 h 30).
func heure() -> float:
	return fposmod(maintenant(), 86400.0) / 3600.0


func texte_heure(h: float = -1.0) -> String:
	if h < 0.0:
		h = heure()
	var hh := int(h)
	var mm := int((h - hh) * 60.0)
	return "%d h %02d" % [hh, mm]


## Basse mer du jour : 9 h 15 au jour 1, puis 50 minutes plus tard chaque jour.
## Le cycle d'une marée dure 12 h 25.
func basses_mers(j: int = -1) -> Array:
	if j < 0:
		j = jour()
	var premiere := fposmod(9.25 + (j - 1) * 50.0 / 60.0, 12.4167)
	return [premiere, premiere + 12.4167]


## Vrai si les passages « marée basse » sont ouverts (2 h avant à 2 h après).
func maree_basse() -> bool:
	var h := heure()
	for b in basses_mers() + basses_mers(jour() - 1).map(func(x): return x - 24.0):
		if absf(h - b) <= 2.0:
			return true
	return false


## Fait passer du temps d'un coup (une action qui dure, une nuit de sommeil).
func avancer(minutes: float) -> void:
	_decalage += minutes * 60.0
	_sauver()
