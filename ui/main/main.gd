extends Control

const SETUP_SCENE = preload("res://ui/setup/Setup.tscn")
const BATTLE_SCENE = preload("res://ui/battle/Battle.tscn")
const RESULT_SCENE = preload("res://ui/result/Result.tscn")

var screen: Control

func _ready() -> void:
	show_setup(UiBattleData.default_config())

func _replace(scene: PackedScene) -> Control:
	if screen != null:
		screen.queue_free()
	screen = scene.instantiate() as Control
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	return screen

func show_setup(config: Dictionary) -> void:
	var setup_screen := _replace(SETUP_SCENE)
	setup_screen.configure(config)
	setup_screen.battle_requested.connect(show_battle)

func show_battle(config: Dictionary) -> void:
	var battle_screen := _replace(BATTLE_SCENE)
	battle_screen.finished.connect(show_result)
	battle_screen.begin_battle(config)

func show_result(state: BattleState, config: Dictionary) -> void:
	var result_screen := _replace(RESULT_SCENE)
	result_screen.show_result(state, config)
	result_screen.restart_requested.connect(show_battle)
	result_screen.edit_requested.connect(show_setup)
