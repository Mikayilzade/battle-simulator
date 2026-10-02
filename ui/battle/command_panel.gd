class_name BattleCommandPanel
extends PanelContainer

signal command_chosen(command: BattleCommand)
signal mode_changed(value: String)
signal selection_changed()

var legal: Array[BattleCommand] = []
var active: SquadState
var selected_target: StringName = &""
var mode := "MOVE"
var updating := false
var title: Label
var hint: Label
var move_button: Button
var attack_button: Button
var guard_button: Button
var front_button: Button
var pass_button: Button
var attacker_picker: OptionButton
var target_picker: OptionButton
var front_picker: OptionButton
var confirm_attack: Button
var confirm_front: Button
var attack_controls: HBoxContainer
var front_controls: HBoxContainer
var choosing_front := false

func _ready() -> void:
	custom_minimum_size.y = 104
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	title = Label.new()
	title.custom_minimum_size.x = 285
	title.add_theme_font_size_override("font_size", 18)
	row.add_child(title)
	move_button = _button("Move", func() -> void: _select_mode("MOVE"))
	attack_button = _button("Attack", func() -> void: _select_mode("ATTACK"))
	guard_button = _button("Guard", func() -> void: _emit_kind(BattleCommand.GUARD))
	front_button = _button("Formation", _show_front_controls)
	pass_button = _button("Pass turn", func() -> void: _emit_kind(BattleCommand.PASS))
	for button in [move_button, attack_button, guard_button, front_button, pass_button]:
		row.add_child(button)
	attack_controls = HBoxContainer.new()
	attack_controls.add_theme_constant_override("separation", 8)
	content.add_child(attack_controls)
	attack_controls.add_child(_small_label("Attacker"))
	attacker_picker = OptionButton.new()
	attacker_picker.custom_minimum_size.x = 150
	attacker_picker.item_selected.connect(func(_index: int) -> void: _refresh_targets())
	attack_controls.add_child(attacker_picker)
	attack_controls.add_child(_small_label("Target"))
	target_picker = OptionButton.new()
	target_picker.custom_minimum_size.x = 190
	target_picker.item_selected.connect(func(_index: int) -> void: selection_changed.emit())
	attack_controls.add_child(target_picker)
	confirm_attack = _button("Strike", _confirm_attack)
	attack_controls.add_child(confirm_attack)
	front_controls = HBoxContainer.new()
	front_controls.add_theme_constant_override("separation", 8)
	content.add_child(front_controls)
	front_controls.add_child(_small_label("New front"))
	front_picker = OptionButton.new()
	front_picker.custom_minimum_size.x = 210
	front_controls.add_child(front_picker)
	confirm_front = _button("Set front", _confirm_front)
	front_controls.add_child(confirm_front)
	hint = _small_label("Select a highlighted destination on the map.")
	content.add_child(hint)
	_update_visibility()

func set_context(value_active: SquadState, value_legal: Array[BattleCommand], target: StringName, value_mode: String) -> void:
	updating = true
	active = value_active
	legal = value_legal
	selected_target = target
	mode = value_mode
	var blue_turn := active != null and active.side_id == &"blue"
	title.text = "Your orders  ·  %d actions" % active.action_pool if blue_turn else "Enemy turn" if active != null else "Battle complete"
	attacker_picker.clear()
	front_picker.clear()
	if blue_turn:
		for member in active.members:
			if not member.is_living():
				continue
			var member_name := "Commander" if member.is_commander else "Fighter %d" % int(str(member.id).get_slice("_", 2))
			if _member_can_attack(member.id):
				attacker_picker.add_item("%s · %d HP" % [member_name, member.current_hp])
				attacker_picker.set_item_metadata(attacker_picker.item_count - 1, member.id)
			for command in legal:
				if command.kind == BattleCommand.SET_FRONT and command.front_member_id == member.id:
					front_picker.add_item("%s · %d HP" % [member_name, member.current_hp])
					front_picker.set_item_metadata(front_picker.item_count - 1, command)
					break
	_refresh_targets()
	move_button.disabled = not blue_turn or not _has_kind(BattleCommand.MOVE)
	attack_button.disabled = not blue_turn or not _has_kind(BattleCommand.ATTACK)
	guard_button.disabled = not blue_turn or not _has_kind(BattleCommand.GUARD)
	front_button.disabled = not blue_turn or not _has_kind(BattleCommand.SET_FRONT)
	pass_button.disabled = not blue_turn
	updating = false
	_update_visibility()

func select_target(id: StringName) -> void:
	selected_target = id
	_refresh_targets()
	_update_visibility()

func selected_attack_command() -> BattleCommand:
	if target_picker.item_count == 0 or target_picker.selected < 0:
		return null
	return target_picker.get_item_metadata(target_picker.selected) as BattleCommand

func set_hint(value: String) -> void:
	hint.text = value

func _refresh_targets() -> void:
	target_picker.clear()
	if selected_target.is_empty() or attacker_picker.item_count == 0 or attacker_picker.selected < 0:
		_update_visibility()
		return
	var attacker_id := StringName(attacker_picker.get_item_metadata(attacker_picker.selected))
	for command in legal:
		if command.kind != BattleCommand.ATTACK or command.attacker_id != attacker_id or command.target_squad_id != selected_target:
			continue
		var id := command.target_member_id
		var front := id.is_empty()
		target_picker.add_item("Front" if front else "Rear fighter %d" % int(str(id).get_slice("_", 2)))
		target_picker.set_item_metadata(target_picker.item_count - 1, command)
	_update_visibility()
	if not updating:
		selection_changed.emit()

func _select_mode(value: String) -> void:
	mode = value
	choosing_front = false
	_update_visibility()
	mode_changed.emit(value)

func _show_front_controls() -> void:
	choosing_front = not choosing_front
	mode = "FORMATION" if choosing_front else "MOVE"
	_update_visibility()
	mode_changed.emit(mode)

func _update_visibility() -> void:
	if attack_controls == null:
		return
	attack_controls.visible = mode == "ATTACK" and not choosing_front and active != null and active.side_id == &"blue"
	front_controls.visible = choosing_front and front_picker.item_count > 0
	target_picker.visible = attack_controls.visible and target_picker.item_count > 0
	confirm_attack.visible = target_picker.visible
	confirm_front.disabled = front_picker.item_count == 0

func _confirm_attack() -> void:
	var command := selected_attack_command()
	if command != null:
		command_chosen.emit(command)

func _confirm_front() -> void:
	if front_picker.item_count > 0:
		command_chosen.emit(front_picker.get_item_metadata(front_picker.selected) as BattleCommand)
		_select_mode("MOVE")

func _emit_kind(kind: StringName) -> void:
	for command in legal:
		if command.kind == kind:
			command_chosen.emit(command)
			return

func _has_kind(kind: StringName) -> bool:
	for command in legal:
		if command.kind == kind:
			return true
	return false

func _member_can_attack(id: StringName) -> bool:
	for command in legal:
		if command.kind == BattleCommand.ATTACK and command.attacker_id == id:
			return true
	return false

func _button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(104, 34)
	button.pressed.connect(callback)
	return button

func _small_label(label: String) -> Label:
	var node := Label.new()
	node.text = label
	node.add_theme_font_size_override("font_size", 14)
	return node
