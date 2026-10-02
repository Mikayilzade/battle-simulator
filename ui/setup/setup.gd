extends Control

signal battle_requested(config: Dictionary)

var config: Dictionary = {}
var map_picker: OptionButton
var pickers: Dictionary = {}
var status_label: Label

func _ready() -> void:
	_build()
	configure(UiBattleData.default_config())

func configure(value: Dictionary) -> void:
	config = value.duplicate(true)
	if map_picker == null:
		return
	map_picker.select(0 if config.get("map_id", "open_field") == "open_field" else 1)
	for side in ["blue", "red"]:
		for index in 2:
			var picker: OptionButton = pickers["%s_%d" % [side, index]]
			picker.select(UiBattleData.TYPES.find(config[side][index]))
	_update_status()

func autofill(side: String) -> void:
	for index in 2:
		(pickers["%s_%d" % [side, index]] as OptionButton).select(0 if index == 0 else 2)
	_update_status()

func build_config() -> Dictionary:
	var result := config.duplicate(true)
	result["map_id"] = "open_field" if map_picker.selected == 0 else "broken_pass"
	for side in ["blue", "red"]:
		var types: Array[String] = []
		for index in 2:
			types.append(UiBattleData.TYPES[(pickers["%s_%d" % [side, index]] as OptionButton).selected])
		result[side] = types
	return result

func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#151e2d")
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 54)
	outer.add_theme_constant_override("margin_right", 54)
	outer.add_theme_constant_override("margin_top", 30)
	outer.add_theme_constant_override("margin_bottom", 30)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)
	root.add_child(_label("BATTLE SIMULATOR  /  SETUP", 28))
	root.add_child(_label("Choose a map and two squads per side. Blue is yours; Red uses Baseline AI.", 16))
	var map_row := HBoxContainer.new()
	root.add_child(map_row)
	map_row.add_child(_label("Map", 18))
	map_picker = OptionButton.new()
	map_picker.custom_minimum_size = Vector2(260, 42)
	map_picker.add_item("Open Field")
	map_picker.add_item("Broken Pass")
	map_row.add_child(map_picker)
	var sides := HBoxContainer.new()
	sides.add_theme_constant_override("separation", 22)
	sides.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(sides)
	for side in ["blue", "red"]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		sides.add_child(panel)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 12)
		panel.add_child(content)
		content.add_child(_label("BLUE  /  HUMAN" if side == "blue" else "RED  /  AI", 22))
		for index in 2:
			var row := HBoxContainer.new()
			content.add_child(row)
			row.add_child(_label("Squad %d" % (index + 1), 17))
			var picker := OptionButton.new()
			picker.size_flags_horizontal = SIZE_EXPAND_FILL
			for type in UiBattleData.TYPES:
				picker.add_item(type.capitalize())
			picker.item_selected.connect(func(_selected: int) -> void: _update_status())
			row.add_child(picker)
			pickers["%s_%d" % [side, index]] = picker
		var auto := Button.new()
		auto.text = "Autofill %s  (Guard + Archer)" % side.capitalize()
		auto.pressed.connect(func() -> void: autofill(side))
		content.add_child(auto)
		content.add_child(_label("Each squad: 3 members, including 1 commander.", 15))
	status_label = _label("", 15)
	root.add_child(status_label)
	var footer := HBoxContainer.new()
	root.add_child(footer)
	var both := Button.new()
	both.text = "Autofill Both"
	both.pressed.connect(func() -> void: autofill("blue"); autofill("red"))
	footer.add_child(both)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var start := Button.new()
	start.text = "START BATTLE  →"
	start.custom_minimum_size = Vector2(230, 50)
	start.pressed.connect(_start)
	footer.add_child(start)

func _update_status() -> void:
	if status_label == null:
		return
	var lines: Array[String] = ["First activation: %s  •  %s spawn orientation" % [str(config.get("first_side_id", "blue")).capitalize(), "Mirrored" if config.get("spawn_swapped", false) else "Standard"], "Stats per member  •  Commander: +2 max HP, +1 power (one per squad)"]
	var unit_defs := UiBattleData.units()
	for unit in unit_defs:
		lines.append("%s  HP %d  Armor %d  Power %d  Move %d  Range %d" % [unit.display_name, unit.max_hp, unit.armor, unit.power, unit.movement, unit.attack_range])
	status_label.text = "\n".join(lines)

func _start() -> void:
	var chosen := build_config()
	var state := UiBattleData.setup(chosen)
	var errors := BattleValidator.validate_setup(state, UiBattleData.map_for(chosen), UiBattleData.balance(), UiBattleData.units(), UiBattleData.terrains())
	if not errors.is_empty():
		status_label.text = "Setup error: %s" % str(errors)
		return
	battle_requested.emit(chosen)

func _label(value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	return label
