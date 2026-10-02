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
var commands: BattleCommandPanel
var status: Label
var selected_info: Label
var feed: RichTextLabel
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
	_log("Battle started · %s · seed %d" % [map_def.display_name, state.seed])
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
			mode = "MOVE"
			selected_target = &""
			commands.choosing_front = false
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
	background.color = Color("#172720")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var top := _panel(Color(0.07, 0.14, 0.14, 0.9))
	top.position = Vector2(20, 14)
	top.size = Vector2(1240, 44)
	add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	var title := _label("BATTLE SIMULATOR  /  %s" % "TACTICAL MAP", 18)
	title.custom_minimum_size.x = 410
	top_row.add_child(title)
	status = _label("", 17)
	top_row.add_child(status)
	board = BattleBoardView.new()
	board.position = Vector2(20, 65)
	board.size = Vector2(946, 518)
	board.cell_clicked.connect(_on_cell)
	board.cell_hovered.connect(_show_route)
	add_child(board)
	var detail_panel := _panel(Color(0.07, 0.14, 0.14, 0.9))
	detail_panel.position = Vector2(980, 65)
	detail_panel.size = Vector2(280, 218)
	add_child(detail_panel)
	var detail_content := VBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 8)
	detail_panel.add_child(detail_content)
	detail_content.add_child(_label("ACTIVE FORMATION", 15))
	selected_info = _label("", 15)
	detail_content.add_child(selected_info)
	var event_panel := _panel(Color(0.07, 0.14, 0.14, 0.82))
	event_panel.position = Vector2(980, 296)
	event_panel.size = Vector2(280, 287)
	add_child(event_panel)
	var event_content := VBoxContainer.new()
	event_panel.add_child(event_content)
	var toggle := Button.new()
	toggle.text = "CHRONICLE  ▾"
	toggle.flat = true
	event_content.add_child(toggle)
	feed = RichTextLabel.new()
	feed.size_flags_vertical = SIZE_EXPAND_FILL
	feed.scroll_following = true
	event_content.add_child(feed)
	toggle.pressed.connect(func() -> void:
		feed.visible = not feed.visible
		event_panel.size.y = 287 if feed.visible else 44
		toggle.text = "CHRONICLE  ▾" if feed.visible else "CHRONICLE  ▸"
	)
	commands = BattleCommandPanel.new()
	commands.position = Vector2(20, 597)
	commands.size = Vector2(1240, 108)
	_skin(commands, Color(0.07, 0.14, 0.14, 0.95))
	commands.mode_changed.connect(_on_mode_changed)
	commands.command_chosen.connect(submit_command)
	commands.selection_changed.connect(_update_attack_preview)
	add_child(commands)

func _render() -> void:
	if state == null:
		return
	legal = BattleRules.legal_commands(state, map_def, balance, units, terrains)
	var active := _active_squad()
	if active == null:
		status.text = "Round %d  ·  Battle ended" % state.round
		selected_info.text = ""
	else:
		status.text = "Round %d  ·  %s  ·  %d orders" % [state.round, _squad_name(active), active.action_pool]
		var lines: Array[String] = [_squad_name(active), "", "Front: %s" % _member_name(active.front_member_id), ""]
		for member in active.members:
			if member.is_living() and member.id != active.front_member_id:
				lines.append("Rear: %s" % _member_name(member.id))
		selected_info.text = "\n".join(lines)
	board.set_model(map_def, state, legal, mode, selected_target)
	commands.set_context(active, legal, selected_target, mode)
	commands.set_hint(_default_hint())
	feed.text = "\n".join(log_lines)
	_update_attack_preview()

func _on_mode_changed(value: String) -> void:
	mode = value
	if mode != "ATTACK":
		selected_target = &""
		commands.select_target(&"")
	board.set_model(map_def, state, legal, mode, selected_target)
	commands.set_hint(_default_hint())
	_update_attack_preview()

func _default_hint() -> String:
	if mode == "MOVE":
		return "Click a highlighted destination. Hover to inspect the route."
	if mode == "FORMATION":
		return "Choose a living member to lead the formation."
	return "Click a highlighted enemy, then choose a target."

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
		if squad == null or squad.side_id != &"red":
			return
		for command in legal:
			if command.kind == BattleCommand.ATTACK and command.target_squad_id == squad.id:
				selected_target = squad.id
				commands.select_target(squad.id)
				board.selected_target = squad.id
				board.queue_redraw()
				_update_attack_preview()
				return

func _show_route(cell: Vector2i) -> void:
	if mode != "MOVE":
		return
	for command in legal:
		if command.kind == BattleCommand.MOVE and command.path.back() == cell:
			commands.set_hint("Route: %s" % str(command.path))
			return
	commands.set_hint("Click a highlighted destination.")

func _update_attack_preview() -> void:
	if mode != "ATTACK":
		return
	var command := commands.selected_attack_command()
	if command == null:
		return
	var target_id := _squad(command.target_squad_id).front_member_id if command.target_member_id.is_empty() else command.target_member_id
	var target := _member_in(state, target_id)
	var applied := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
	if applied["ok"]:
		var after := _member_in(applied["state"], target_id)
		commands.set_hint("%s: %d damage%s" % [_member_name(target_id), target.current_hp - after.current_hp, " · lethal" if after.current_hp == 0 else ""])

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

func _member_in(value: BattleState, id: StringName) -> CombatantState:
	for side in value.sides:
		for squad in side.squads:
			for member in squad.members:
				if member.id == id:
					return member
	return null

func _log_command(command: BattleCommand, before: BattleState, events: Array) -> void:
	for event in events:
		match event["type"]:
			&"moved": _log("%s moved" % _squad_name(_squad(command.squad_id)))
			&"attacked":
				_log("%s hit %s for %d" % [_squad_name(_squad(command.squad_id)), _squad_name(_squad(command.target_squad_id)), event["damage"]])
				var before_member := _member_in(before, StringName(event["target_id"]))
				var after_member := _member_in(state, StringName(event["target_id"]))
				if before_member.current_hp > 0 and after_member.current_hp == 0:
					_log("%s lost a member" % _squad_name(_squad(command.target_squad_id)))
				var old_front := _squad_in(before, command.target_squad_id).front_member_id
				var new_front := _squad(command.target_squad_id).front_member_id
				if old_front != new_front:
					_log("%s changed front" % _squad_name(_squad(command.target_squad_id)))
			&"guarded": _log("%s guards" % _squad_name(_squad(command.squad_id)))
			&"front_set": _log("%s changed front" % _squad_name(_squad(command.squad_id)))
			&"passed": _log("%s passed" % _squad_name(_squad(command.squad_id)))
	if before.active_squad_id != &"" and state.active_squad_id == &"":
		_log("%s activation ended" % _squad_name(_squad(command.squad_id)))

func _log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 60:
		log_lines.pop_front()

func _squad_name(squad: SquadState) -> String:
	return "%s %s %d" % [str(squad.side_id).capitalize(), str(squad.unit_type_id).capitalize(), int(str(squad.id).get_slice("_", 1)) + 1]

func _squad_in(value: BattleState, id: StringName) -> SquadState:
	for side in value.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

func _member_name(id: StringName) -> String:
	var member := _member_in(state, id)
	if member == null:
		return "—"
	return "%s (%d HP)" % ["Commander" if member.is_commander else "Fighter %d" % int(str(id).get_slice("_", 2)), member.current_hp]

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	_skin(panel, color)
	return panel

func _skin(panel: PanelContainer, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	panel.add_theme_stylebox_override("panel", style)

func _label(value: String, font_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	return node
