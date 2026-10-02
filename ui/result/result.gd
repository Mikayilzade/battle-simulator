extends Control

signal restart_requested(config: Dictionary)
signal edit_requested(config: Dictionary)

var config: Dictionary
var preview: BattleBoardView
var title: Label
var subtitle: Label
var summary: Label

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#182921")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var heading := _label("BATTLE SIMULATOR  /  AFTER ACTION", 24)
	heading.position = Vector2(35, 26)
	add_child(heading)
	var map_panel := _panel(Color("#263930"), Vector2(35, 90), Vector2(755, 575))
	add_child(map_panel)
	var map_content := VBoxContainer.new()
	map_content.add_theme_constant_override("separation", 5)
	map_panel.add_child(map_content)
	map_content.add_child(_label("THE FIELD AT BATTLE'S END", 15))
	preview = BattleBoardView.new()
	preview.interactive = false
	preview.custom_minimum_size = Vector2(721, 510)
	map_content.add_child(preview)
	var report := _panel(Color("#15251f"), Vector2(812, 90), Vector2(430, 575))
	add_child(report)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 17)
	report.add_child(content)
	content.add_child(_label("FIELD REPORT", 15))
	title = _label("", 31)
	content.add_child(title)
	subtitle = _label("", 16)
	content.add_child(subtitle)
	var rule := HSeparator.new()
	content.add_child(rule)
	summary = _label("", 17)
	content.add_child(summary)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(spacer)
	for action in ["Restart", "Rematch", "Edit Forces"]:
		var button := Button.new()
		button.text = action
		button.custom_minimum_size.y = 42
		button.pressed.connect(_on_button.bind(action))
		content.add_child(button)

func show_result(state: BattleState, value: Dictionary) -> void:
	config = value.duplicate(true)
	var no_commands: Array[BattleCommand] = []
	preview.set_model(UiBattleData.map_for(config), state, no_commands, "", &"")
	title.text = "BLUE VICTORY" if state.outcome == &"blue" else ("RED VICTORY" if state.outcome == &"red" else "DRAW")
	subtitle.text = "%s  ·  Round %d" % [UiBattleData.map_for(config).display_name, state.round]
	var lines: Array[String] = []
	for side in state.sides:
		var living_squads := 0
		var living_members := 0
		var hp := 0
		var commanders := 0
		for squad in side.squads:
			if squad.living_member_count() > 0:
				living_squads += 1
			for member in squad.members:
				if member.is_living():
					living_members += 1
					hp += member.current_hp
					if member.is_commander:
						commanders += 1
		lines.append("%s" % str(side.id).to_upper())
		lines.append("%d formations  ·  %d of 6 fighters" % [living_squads, living_members])
		lines.append("%d HP remaining  ·  %d commanders" % [hp, commanders])
		lines.append("")
	summary.text = "\n".join(lines)

func _on_button(action: String) -> void:
	if action == "Edit Forces":
		edit_requested.emit(config.duplicate(true))
		return
	var next := config.duplicate(true)
	if action == "Rematch":
		next["spawn_swapped"] = not bool(next["spawn_swapped"])
		next["first_side_id"] = "red" if next["first_side_id"] == "blue" else "blue"
	restart_requested.emit(next)

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
