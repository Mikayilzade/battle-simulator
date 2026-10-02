extends Control

signal finished(state: BattleState, config: Dictionary)

var config: Dictionary
var state: BattleState
var map_def: BattleMapDef
var balance: BattleBalanceDef
var units: Array[UnitTypeDef]
var terrains: Array[TerrainDef]
var legal: Array[BattleCommand] = []
var board: BattleBoardView
var status: Label
var route: Label
var feed: RichTextLabel
var attacker_picker: OptionButton
var target_picker: OptionButton
var front_picker: OptionButton
var move_button: Button
var attack_button: Button
var guard_button: Button
var front_button: Button
var pass_button: Button
var selected_target: StringName = &""
var mode := "MOVE"
var ai_running := false
var ai_step_delay := 0.18
var log_lines: Array[String] = []

func _ready() -> void:
	_build()

func begin_battle(value: Dictionary) -> void:
	config = value.duplicate(true)
	map_def = UiBattleData.map_for(config)
	balance = UiBattleData.balance()
	units = UiBattleData.units()
	terrains = UiBattleData.terrains()
	state = UiBattleData.setup(config)
	var errors := BattleValidator.validate_setup(state, map_def, balance, units, terrains)
	if not errors.is_empty():
		push_error("Invalid UI battle setup: %s" % str(errors))
		return
	log_lines.clear()
	_log("Battle started • %s • seed %d" % [map_def.display_name, state.seed])
	_render()
	call_deferred("advance_turn")

func advance_turn() -> void:
	if state == null or ai_running:
		return
	while is_inside_tree() and state.outcome == &"ongoing":
		if state.active_squad_id.is_empty():
			var old_round := state.round
			var scheduled := BattleScheduler.next_activation(state, balance)
			if not scheduled["ok"]:
				_log("Scheduler error: %s" % scheduled["error"])
				return
			state = scheduled["state"]
			if state.round != old_round:
				_log("Round %d begins" % state.round)
			if state.outcome != &"ongoing":
				break
			_log("%s activates" % _squad_name(_active_squad()))
			_render()
		if _active_squad().side_id == &"blue":
			return
		ai_running = true
		var choices := BattleRules.legal_commands(state, map_def, balance, units, terrains)
		var command := BaselineAi.choose_command(state, choices, map_def, balance, units, terrains, load("res://ai/default_policy.tres") as AiPolicyDef)
		if command == null or not choices.has(command):
			_log("AI failed to choose a legal action")
			ai_running = false
			return
		_submit(command)
		await get_tree().create_timer(ai_step_delay).timeout
		ai_running = false
	if is_inside_tree() and state != null and state.outcome != &"ongoing":
		finished.emit(state, config)

func submit_command(command: BattleCommand) -> bool:
	if state == null or state.outcome != &"ongoing" or state.active_squad_id.is_empty() or _active_squad().side_id != &"blue" or ai_running:
		return false
	if not legal.has(command):
		return false
	var applied := _submit(command)
	if applied:
		call_deferred("advance_turn")
	return applied

func _submit(command: BattleCommand) -> bool:
	var before := state
	var result := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
	if not result["ok"]:
		_log("Invalid action: %s" % result["error"])
		return false
	state = result["state"]
	_log_command(command, before, result["events"])
	_render()
	return true

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("#151e2d")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % edge, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "BATTLE SIMULATOR  /  BATTLE"
	heading.add_theme_font_size_override("font_size", 25)
	root.add_child(heading)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 17)
	root.add_child(status)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(body)
	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(board_panel)
	var board_column := VBoxContainer.new()
	board_panel.add_child(board_column)
	board = BattleBoardView.new()
	board.cell_clicked.connect(_on_cell)
	board.cell_hovered.connect(_show_route)
	board_column.add_child(board)
	route = Label.new()
	route.text = "GREEN = reachable   •   GOLD = active   •   B circle / R diamond   •   G Guard, S Striker, A Archer"
	board_column.add_child(route)
	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size.x = 455
	body.add_child(side_panel)
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	side_panel.add_child(controls)
	controls.add_child(_label("BLUE COMMANDS", 20))
	var modes := HBoxContainer.new()
	controls.add_child(modes)
	move_button = _button("MOVE  •  click cell", func() -> void: _select_mode("MOVE"))
	attack_button = _button("ATTACK  •  click enemy", func() -> void: _select_mode("ATTACK"))
	modes.add_child(move_button)
	modes.add_child(attack_button)
	controls.add_child(_label("Attacker", 15))
	attacker_picker = OptionButton.new()
	attacker_picker.item_selected.connect(func(_index: int) -> void: _refresh_targets())
	controls.add_child(attacker_picker)
	controls.add_child(_label("Target member (front by default)", 15))
	target_picker = OptionButton.new()
	target_picker.item_selected.connect(func(_index: int) -> void: _update_attack_preview())
	controls.add_child(target_picker)
	controls.add_child(_button("CONFIRM ATTACK", _attack_selected))
	controls.add_child(_label("Set front member", 15))
	front_picker = OptionButton.new()
	controls.add_child(front_picker)
	front_button = _button("SET FRONT", _set_front)
	controls.add_child(front_button)
	guard_button = _button("GUARD  (+1 armor)", _guard)
	controls.add_child(guard_button)
	pass_button = _button("PASS  /  end activation", _pass)
	controls.add_child(pass_button)
	controls.add_child(_label("EVENT FEED", 18))
	feed = RichTextLabel.new()
	feed.size_flags_vertical = SIZE_EXPAND_FILL
	feed.scroll_following = true
	controls.add_child(feed)

func _render() -> void:
	if state == null:
		return
	legal = BattleRules.legal_commands(state, map_def, balance, units, terrains)
	var active := _active_squad()
	if active == null:
		status.text = "Round %d  •  Battle ended" % state.round
	else:
		var rear: Array[String] = []
		for member in active.members:
			if member.is_living() and member.id != active.front_member_id:
				rear.append(_member_name(member.id))
		status.text = "Round %d  •  %s  •  %d actions  •  Front: %s  •  Rear: %s" % [state.round, _squad_name(active), active.action_pool, _member_name(active.front_member_id), ", ".join(rear)]
	board.set_model(map_def, state, legal, mode, selected_target)
	route.text = "GREEN = reachable   •   GOLD = active   •   B circle / R diamond   •   G Guard, S Striker, A Archer"
	_refresh_controls()
	feed.text = "\n".join(log_lines)

func _refresh_controls() -> void:
	var blue_turn := state.outcome == &"ongoing" and not state.active_squad_id.is_empty() and _active_squad().side_id == &"blue"
	attacker_picker.clear()
	front_picker.clear()
	if blue_turn:
		var squad := _active_squad()
		for member in squad.members:
			if member.is_living():
				front_picker.add_item(_member_name(member.id))
				front_picker.set_item_metadata(front_picker.item_count - 1, str(member.id))
				if not squad.attacked_member_ids.has(member.id):
					attacker_picker.add_item(_member_name(member.id))
					attacker_picker.set_item_metadata(attacker_picker.item_count - 1, str(member.id))
	_refresh_targets()
	move_button.disabled = not blue_turn or not _has_kind(BattleCommand.MOVE)
	attack_button.disabled = not blue_turn or not _has_kind(BattleCommand.ATTACK)
	guard_button.disabled = not blue_turn or not _has_kind(BattleCommand.GUARD)
	front_button.disabled = not blue_turn or not _has_kind(BattleCommand.SET_FRONT)
	pass_button.disabled = not blue_turn

func _refresh_targets() -> void:
	target_picker.clear()
	if selected_target.is_empty() or attacker_picker.item_count == 0:
		return
	var attacker_id := StringName(attacker_picker.get_item_metadata(attacker_picker.selected))
	for command in legal:
		if command.kind != BattleCommand.ATTACK or command.attacker_id != attacker_id or command.target_squad_id != selected_target:
			continue
		var squad := _squad(selected_target)
		var id := squad.front_member_id if command.target_member_id.is_empty() else command.target_member_id
		target_picker.add_item("%s%s" % [_member_name(id), " • front" if command.target_member_id.is_empty() else " • rear"])
		target_picker.set_item_metadata(target_picker.item_count - 1, command)
	_update_attack_preview()

func _update_attack_preview() -> void:
	if target_picker.item_count == 0 or target_picker.selected < 0:
		return
	var command := target_picker.get_item_metadata(target_picker.selected) as BattleCommand
	var target := _member_in(state, _squad(command.target_squad_id).front_member_id if command.target_member_id.is_empty() else command.target_member_id)
	var applied := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
	if applied["ok"]:
		var after := _member_in(applied["state"], target.id)
		route.text = "Attack preview: %s takes %d damage%s" % [_member_name(target.id), target.current_hp - after.current_hp, " • lethal" if after.current_hp == 0 else ""]

func _on_cell(cell: Vector2i) -> void:
	if state == null or state.active_squad_id.is_empty() or _active_squad().side_id != &"blue":
		return
	if mode == "MOVE":
		for command in legal:
			if command.kind == BattleCommand.MOVE and command.path.back() == cell:
				submit_command(command)
				return
	elif mode == "ATTACK":
		var squad := _squad_at(cell)
		if squad != null and squad.side_id == &"red":
			var targetable := false
			for command in legal:
				if command.kind == BattleCommand.ATTACK and command.target_squad_id == squad.id:
					targetable = true
					break
			if not targetable:
				return
			selected_target = squad.id
			_refresh_targets()
			board.selected_target = selected_target
			board.queue_redraw()

func _show_route(cell: Vector2i) -> void:
	if mode != "MOVE":
		return
	for command in legal:
		if command.kind == BattleCommand.MOVE and command.path.back() == cell:
			route.text = "Route: %s" % str(command.path)
			return

func _attack_selected() -> void:
	if target_picker.item_count > 0:
		submit_command(target_picker.get_item_metadata(target_picker.selected) as BattleCommand)

func _set_front() -> void:
	if front_picker.item_count == 0:
		return
	var id := StringName(front_picker.get_item_metadata(front_picker.selected))
	for command in legal:
		if command.kind == BattleCommand.SET_FRONT and command.front_member_id == id:
			submit_command(command)
			return

func _guard() -> void:
	_submit_kind(BattleCommand.GUARD)

func _pass() -> void:
	_submit_kind(BattleCommand.PASS)

func _submit_kind(kind: StringName) -> void:
	for command in legal:
		if command.kind == kind:
			submit_command(command)
			return

func _select_mode(value: String) -> void:
	mode = value
	_render()

func _has_kind(kind: StringName) -> bool:
	for command in legal:
		if command.kind == kind:
			return true
	return false

func _active_squad() -> SquadState:
	return _squad(state.active_squad_id)

func _squad(id: StringName) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

func _squad_at(cell: Vector2i) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.position == cell and squad.living_member_count() > 0:
				return squad
	return null

func _log_command(command: BattleCommand, before: BattleState, events: Array) -> void:
	for event in events:
		match event["type"]:
			&"moved":
				_log("%s moved to %s" % [_squad_name(_squad(command.squad_id)), event["position"]])
			&"attacked":
				_log("%s attacked %s %s for %d damage" % [_squad_name(_squad(command.squad_id)), _squad_name(_squad(command.target_squad_id)), _member_name(StringName(event["target_id"])), event["damage"]])
				var target_before := _member_in(before, StringName(event["target_id"]))
				var target_after := _member_in(state, StringName(event["target_id"]))
				if target_before.current_hp > 0 and target_after.current_hp == 0:
					_log("%s %s died" % [_squad_name(_squad(command.target_squad_id)), _member_name(StringName(event["target_id"]))])
				var old_front := _squad_in(before, command.target_squad_id).front_member_id
				var new_front := _squad(command.target_squad_id).front_member_id
				if old_front != new_front:
					_log("%s front changed to %s" % [_squad_name(_squad(command.target_squad_id)), _member_name(new_front)])
			&"guarded": _log("%s used Guard" % _squad_name(_squad(command.squad_id)))
			&"front_set": _log("%s front changed to %s" % [_squad_name(_squad(command.squad_id)), _member_name(StringName(event["member_id"]))])
			&"passed": _log("%s passed" % _squad_name(_squad(command.squad_id)))
	if before.active_squad_id != &"" and state.active_squad_id == &"":
		_log("%s activation ended" % _squad_name(_squad(command.squad_id)))

func _squad_in(value: BattleState, id: StringName) -> SquadState:
	for side in value.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

func _member_in(value: BattleState, id: StringName) -> CombatantState:
	for side in value.sides:
		for squad in side.squads:
			for member in squad.members:
				if member.id == id:
					return member
	return null

func _log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 60:
		log_lines.pop_front()

func _squad_name(squad: SquadState) -> String:
	return "%s %s %d" % [str(squad.side_id).capitalize(), str(squad.unit_type_id).capitalize(), int(str(squad.id).get_slice("_", 1)) + 1]

func _member_name(id: StringName) -> String:
	var member := _member_in(state, id)
	if member == null:
		return "—"
	return "%s (%d HP)" % ["Commander" if member.is_commander else "Fighter %d" % int(str(id).get_slice("_", 2)), member.current_hp]

func _label(value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 38
	button.pressed.connect(callback)
	return button
