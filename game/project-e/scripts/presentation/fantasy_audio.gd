extends Node
## Original short local combat SFX. It observes only the controlled hero.
## No audible state from enemies, vision-hidden units or bots is inspected.
signal cue_played(name: String)
const ConsumablesScript = preload("res://scripts/battle/battle_consumables.gd")

const CUES: Dictionary = {
	"slash": "res://assets/audio/slash.wav",
	"arcane": "res://assets/audio/arcane.wav",
	"nature": "res://assets/audio/nature.wav",
	"hit": "res://assets/audio/hit.wav",
	"level": "res://assets/audio/level.wav",
}

var _player: AudioStreamPlayer
var _last_id: int = -1
var _last_phase: String = ""
var _last_slot: String = ""
var _last_damage_at: float = -1.0
var _last_level: int = -1
var _last_item_effect: String = ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "LocalAudioPlayer"
	_player.volume_db = -15.0
	_player.bus = "Master"
	add_child(_player)

func reset() -> void:
	_last_id = -1
	_last_phase = ""
	_last_slot = ""
	_last_damage_at = -1.0
	_last_level = -1
	_last_item_effect = ""
	if _player != null:
		_player.stop()

func _track(hero: Dictionary) -> void:
	_last_id = int(hero.id)
	_last_phase = str(hero.get("phase", "idle"))
	_last_slot = str(hero.get("cast", {}).get("slot", ""))
	_last_damage_at = float(hero.get("last_damage", -1.0))
	_last_level = int(hero.get("level", 1))
	_last_item_effect = str(hero.get("consumable_effect", {}).get("item_id", ""))

func _kit_sound(key: String) -> String:
	match key:
		"bas", "tere", "sera": return "slash"
		"rio", "orin", "lume": return "arcane"
		"nema", "mua": return "nature"
	return ""

func observe(battle: Variant, active: bool, paused: bool) -> void:
	if not active or battle == null or not battle.units.has(battle.controlled_id):
		reset()
		return
	var hero: Dictionary = battle.units[battle.controlled_id]
	if int(hero.id) != _last_id:
		_track(hero)
		return
	if paused:
		if _player != null:
			_player.stop()
		_track(hero)
		return
	var phase: String = str(hero.get("phase", "idle"))
	var slot: String = str(hero.get("cast", {}).get("slot", ""))
	var damage_at: float = float(hero.get("last_damage", -1.0))
	var level: int = int(hero.get("level", 1))
	var item_effect: String = str(hero.get("consumable_effect", {}).get("item_id", ""))
	var cue: String = ""
	# Level and observed damage take priority over item/cast activation feedback.
	if level > _last_level:
		cue = "level"
	elif damage_at > 0.0 and damage_at > _last_damage_at:
		cue = "hit"
	elif item_effect != _last_item_effect and ConsumablesScript.ITEMS.has(item_effect):
		cue = str(ConsumablesScript.ITEMS[item_effect].cue)
	elif phase == "windup" and not slot.is_empty() and (phase != _last_phase or slot != _last_slot):
		cue = _kit_sound(str(hero.hero))
	elif phase == "basic" and _last_phase != "basic":
		cue = _kit_sound(str(hero.hero))
	_track(hero)
	if not cue.is_empty():
		_play(cue)

func _play(cue: String) -> void:
	if _player == null or not CUES.has(cue):
		return
	var stream: AudioStream = load(str(CUES[cue])) as AudioStream
	if stream == null:
		return
	_player.stop()
	_player.stream = stream
	_player.play()
	cue_played.emit(cue)
