extends Control

signal restart_requested(config: Dictionary)
signal edit_requested(config: Dictionary)

var config: Dictionary
var title: Label
var summary: Label

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#151e2d")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 420)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	content.add_child(title)
	summary = Label.new()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 19)
	content.add_child(summary)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(buttons)
	for item in ["Restart", "Rematch", "Edit Forces"]:
		var button := Button.new()
		button.text = item
		button.custom_minimum_size = Vector2(150, 48)
		button.pressed.connect(_on_button.bind(item))
		buttons.add_child(button)

func show_result(state: BattleState, value: Dictionary) -> void:
	config = value.duplicate(true)
	title.text = "BLUE WIN" if state.outcome == &"blue" else ("RED WIN" if state.outcome == &"red" else "DRAW")
	var lines: Array[String] = ["Round %d" % state.round, ""]
	for side in state.sides:
		var living_squads := 0
		var living_members := 0
		var hp := 0
		for squad in side.squads:
			if squad.living_member_count() > 0:
				living_squads += 1
			for member in squad.members:
				if member.is_living():
					living_members += 1
					hp += member.current_hp
		lines.append("%s  •  %d squads  •  %d members  •  %d HP" % [str(side.id).to_upper(), living_squads, living_members, hp])
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
