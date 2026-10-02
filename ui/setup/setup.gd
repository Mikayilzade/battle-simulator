extends Control

signal battle_requested(config: Dictionary)
signal lab_requested(config: Dictionary)

var config: Dictionary = {}
var selected_map_id := "open_field"
var map_buttons: Dictionary = {}
var pickers: Dictionary = {}
var card_stats: Dictionary = {}
var emblems: Dictionary = {}
var preview: BattleBoardView
var status_label: Label

func _ready() -> void:
	_build()
	configure(UiBattleData.default_config())

func configure(value: Dictionary) -> void:
	config = value.duplicate(true)
	selected_map_id = str(config.get("map_id", "open_field"))
	if preview == null:
		return
	for side in ["blue", "red"]:
		for index in 2:
			var picker: OptionButton = pickers["%s_%d" % [side, index]]
			picker.select(UiBattleData.TYPES.find(config[side][index]))
	_refresh()

func autofill(side: String) -> void:
	for index in 2:
		(pickers["%s_%d" % [side, index]] as OptionButton).select(0 if index == 0 else 2)
	_refresh()

func build_config() -> Dictionary:
	var result := config.duplicate(true)
	result["map_id"] = selected_map_id
	for side in ["blue", "red"]:
		var types: Array[String] = []
		for index in 2:
			types.append(UiBattleData.TYPES[(pickers["%s_%d" % [side, index]] as OptionButton).selected])
		result[side] = types
	return result

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("#182921")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var title := _label("BATTLE SIMULATOR", 28)
	title.position = Vector2(34, 25)
	add_child(title)
	var subtitle := _label("Choose the ground. Muster two formations for each side.", 16)
	subtitle.position = Vector2(35, 68)
	add_child(subtitle)
	_build_force_panel("blue", Vector2(30, 112))
	_build_force_panel("red", Vector2(1005, 112))
	var theater := _panel(Color("#263930"), Vector2(288, 112), Vector2(704, 475))
	add_child(theater)
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 6)
	theater.add_child(center)
	center.add_child(_label("THEATER  /  FIXED DEPLOYMENT", 16))
	preview = BattleBoardView.new()
	preview.interactive = false
	preview.custom_minimum_size = Vector2(670, 370)
	center.add_child(preview)
	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 12)
	center.add_child(map_row)
	for id in ["open_field", "broken_pass"]:
		var button := Button.new()
		button.text = "OPEN FIELD  ·  clear center" if id == "open_field" else "BROKEN PASS  ·  split routes"
		button.toggle_mode = true
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 38
		button.pressed.connect(_choose_map.bind(id))
		map_row.add_child(button)
		map_buttons[id] = button
	var footer := _panel(Color("#11221c"), Vector2(30, 602), Vector2(1220, 100))
	add_child(footer)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 14)
	footer.add_child(footer_row)
	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 510
	footer_row.add_child(info)
	status_label = _label("", 14)
	info.add_child(status_label)
	var auto := Button.new()
	auto.text = "Autofill both"
	auto.pressed.connect(func() -> void: autofill("blue"); autofill("red"))
	auto.custom_minimum_size = Vector2(140, 48)
	footer_row.add_child(auto)
	var lab := Button.new()
	lab.text = "VISUAL STYLE LAB"
	lab.custom_minimum_size = Vector2(170, 48)
	lab.pressed.connect(func() -> void: lab_requested.emit(build_config()))
	footer_row.add_child(lab)
	var start := Button.new()
	start.text = "BEGIN BATTLE  →"
	start.custom_minimum_size = Vector2(220, 48)
	start.pressed.connect(_start)
	footer_row.add_child(start)

func _build_force_panel(side: String, at: Vector2) -> void:
	var blue := side == "blue"
	var panel := _panel(Color("#173a4b") if blue else Color("#482c2a"), at, Vector2(245, 475))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(_label("BLUE  /  YOUR FORCE" if blue else "RED  /  OPPONENT", 18))
	for index in 2:
		var card := _panel(Color("#1c303b") if blue else Color("#352726"), Vector2.ZERO, Vector2(0, 158))
		column.add_child(card)
		var card_content := VBoxContainer.new()
		card_content.add_theme_constant_override("separation", 8)
		card.add_child(card_content)
		card_content.add_child(_label("FORMATION %d" % (index + 1), 14))
		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 7)
		card_content.add_child(card_row)
		var emblem := UnitEmblem.new()
		emblem.set_type(&"guard", StringName(side))
		card_row.add_child(emblem)
		emblems["%s_%d" % [side, index]] = emblem
		var card_details := VBoxContainer.new()
		card_details.size_flags_horizontal = SIZE_EXPAND_FILL
		card_row.add_child(card_details)
		var picker := OptionButton.new()
		picker.custom_minimum_size.y = 36
		for type in UiBattleData.TYPES:
			picker.add_item(type.capitalize())
		picker.item_selected.connect(func(_selected: int) -> void: _refresh())
		card_details.add_child(picker)
		pickers["%s_%d" % [side, index]] = picker
		var stats := _label("", 13)
		card_details.add_child(stats)
		card_stats["%s_%d" % [side, index]] = stats
	var auto := Button.new()
	auto.text = "Autofill %s" % side.capitalize()
	auto.pressed.connect(func() -> void: autofill(side))
	column.add_child(auto)
	column.add_child(_label("3 figures per formation\n1 commander · +2 HP, +1 power", 13))

func _choose_map(id: String) -> void:
	selected_map_id = id
	_refresh()

func _refresh() -> void:
	if preview == null:
		return
	for id in map_buttons:
		(map_buttons[id] as Button).button_pressed = id == selected_map_id
	var unit_defs := UiBattleData.units()
	for side in ["blue", "red"]:
		for index in 2:
			var picker: OptionButton = pickers["%s_%d" % [side, index]]
			var unit: UnitTypeDef = unit_defs[picker.selected]
			(emblems["%s_%d" % [side, index]] as UnitEmblem).set_type(unit.id, StringName(side))
			var role := "Shield wall" if unit.id == &"guard" else ("Fast assault" if unit.id == &"striker" else "Ranged support")
			(card_stats["%s_%d" % [side, index]] as Label).text = "%s\nHP %d  ·  Armor %d\nPower %d  ·  Move %d  ·  Range %d" % [role, unit.max_hp, unit.armor, unit.power, unit.movement, unit.attack_range]
	var chosen := build_config()
	var setup_state := UiBattleData.setup(chosen)
	var no_commands: Array[BattleCommand] = []
	preview.set_model(UiBattleData.map_for(chosen), setup_state, no_commands, "", &"")
	status_label.text = "9 × 7 battlefield  ·  First side: %s\nFixed mirrored deployment  ·  No custom placement" % str(chosen["first_side_id"]).capitalize()

func _start() -> void:
	var chosen := build_config()
	var setup_state := UiBattleData.setup(chosen)
	var errors := BattleValidator.validate_setup(setup_state, UiBattleData.map_for(chosen), UiBattleData.balance(), UiBattleData.units(), UiBattleData.terrains())
	if not errors.is_empty():
		status_label.text = "Setup error: %s" % str(errors)
		return
	battle_requested.emit(chosen)

func _panel(color: Color, at: Vector2, extent: Vector2) -> PanelContainer:
	var node := PanelContainer.new()
	node.position = at
	node.size = extent
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	node.add_theme_stylebox_override("panel", style)
	return node

func _label(value: String, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	return node
