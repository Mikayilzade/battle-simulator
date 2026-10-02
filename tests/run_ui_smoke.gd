extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var main := load("res://ui/main/Main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	var setup_screen: Control = main.screen
	_check(setup_screen.scene_file_path == "res://ui/setup/Setup.tscn", "Setup scene loads")
	setup_screen.autofill("blue")
	setup_screen.autofill("red")
	setup_screen._choose_map("broken_pass")
	_check(setup_screen.build_config()["map_id"] == "broken_pass" and setup_screen.preview.map_def.id == &"broken_pass", "map card updates preview")
	setup_screen._choose_map("open_field")
	var config: Dictionary = setup_screen.build_config()
	_check(BattleValidator.validate_setup(UiBattleData.setup(config), UiBattleData.map_for(config), UiBattleData.balance(), UiBattleData.units(), UiBattleData.terrains()).is_empty(), "autofill creates valid setup")
	var attack_scene: Control = load("res://ui/battle/Battle.tscn").instantiate()
	root.add_child(attack_scene)
	attack_scene.begin_battle(config)
	await process_frame
	attack_scene._squad(&"blue_0").position = Vector2i(1, 2)
	attack_scene._squad(&"red_0").position = Vector2i(2, 2)
	attack_scene._render()
	var attack: BattleCommand = null
	for command in attack_scene.legal:
		if command.kind == BattleCommand.ATTACK:
			attack = command
			break
	var hp_before: int = attack_scene._squad(&"red_0").members[0].current_hp
	_check(attack != null, "Blue has legal attack")
	attack_scene.commands._select_mode("ATTACK")
	attack_scene._on_cell(Vector2i(2, 2))
	_check(attack_scene.commands.selected_attack_command() != null, "clicking enemy opens attack choice")
	attack_scene.commands._confirm_attack()
	_check(attack_scene._squad(&"red_0").members[0].current_hp < hp_before, "attack changes canonical HP")
	attack_scene.queue_free()
	var formation_scene: Control = load("res://ui/battle/Battle.tscn").instantiate()
	root.add_child(formation_scene)
	formation_scene.begin_battle(config)
	await process_frame
	formation_scene.commands._emit_kind(BattleCommand.GUARD)
	_check(formation_scene._squad(&"blue_0").guarding, "Guard button applies domain command")
	formation_scene.commands._show_front_controls()
	_check(formation_scene.commands.front_picker.item_count > 0, "Formation shows living alternatives")
	formation_scene.commands._confirm_front()
	_check(formation_scene._squad(&"blue_0").front_member_id == &"blue_0_1", "Formation button changes front")
	formation_scene.queue_free()
	main.show_battle(config)
	await process_frame
	var battle_screen: Control = main.screen
	battle_screen.ai_step_delay = 0.0
	_check(battle_screen.scene_file_path == "res://ui/battle/Battle.tscn", "Battle scene loads")
	_check(battle_screen.board.map_def.width == 9 and battle_screen.board.map_def.height == 7, "9x7 board renders")
	_check(battle_screen.board.position.x + battle_screen.board.size.x <= 980.0, "map fits its 1280x720 stage")
	_check(battle_screen.commands.position.y + battle_screen.commands.size.y <= 720.0, "command bar fits 1280x720 stage")
	for y in 7:
		for x in 9:
			var cell := Vector2i(x, y)
			var projected: Vector2 = battle_screen.board._projection_offset() + battle_screen.board._center(cell) * battle_screen.board._projection_scale()
			_check(battle_screen.board._cell_at(projected) == cell, "isometric hit test %s" % cell)
	_check(battle_screen.state != null and battle_screen.state.outcome == &"ongoing", "Start Battle creates state")
	var first_move: BattleCommand = null
	for command in battle_screen.legal:
		if command.kind == BattleCommand.MOVE:
			first_move = command
			break
	_check(first_move != null, "Blue has legal move")
	battle_screen._on_cell(first_move.path.back())
	_check(battle_screen._squad(&"blue_0").position == first_move.path.back(), "clicking terrain moves Blue")
	var first_pass: BattleCommand = null
	for command in battle_screen.legal:
		if command.kind == BattleCommand.PASS:
			first_pass = command
			break
	_check(first_pass != null, "Blue has legal pass")
	battle_screen.commands._emit_kind(BattleCommand.PASS)
	_check(battle_screen.state.active_squad_id.is_empty(), "Pass ends Blue activation")
	var red_acted := false
	for tick in 100:
		await process_frame
		if battle_screen == null or not is_instance_valid(battle_screen):
			break
		if battle_screen.log_lines.any(func(line: String) -> bool: return line.contains("Red Guard 1 activation ended")):
			red_acted = true
			break
	_check(red_acted, "Red AI completes an activation")
	var steps := 0
	while is_instance_valid(battle_screen) and battle_screen.state.outcome == &"ongoing" and steps < 600:
		if not battle_screen.state.active_squad_id.is_empty() and battle_screen._active_squad().side_id == &"blue" and not battle_screen.ai_running:
			var choice: BattleCommand = BaselineAi.choose_command(battle_screen.state, battle_screen.legal, battle_screen.map_def, battle_screen.balance, battle_screen.units, battle_screen.terrains, load("res://ai/default_policy.tres"))
			_check(choice != null and battle_screen.submit_command(choice), "Blue legal command %d" % steps)
		await process_frame
		steps += 1
	_check(steps < 600, "battle terminates")
	await process_frame
	var result_screen: Control = main.screen
	_check(result_screen.scene_file_path == "res://ui/result/Result.tscn", "Result scene reached")
	var original: Dictionary = result_screen.config.duplicate(true)
	result_screen._on_button("Restart")
	await process_frame
	battle_screen = main.screen
	_check(battle_screen.state.spawn_swapped == original["spawn_swapped"] and battle_screen.state.seed == original["seed"] and battle_screen.state.first_side_id == StringName(original["first_side_id"]), "Restart restores setup")
	main.show_result(battle_screen.state, original)
	await process_frame
	result_screen = main.screen
	result_screen._on_button("Rematch")
	await process_frame
	battle_screen = main.screen
	_check(battle_screen.state.spawn_swapped != original["spawn_swapped"] and battle_screen.state.first_side_id != StringName(original["first_side_id"]), "Rematch swaps orientation")
	main.show_result(battle_screen.state, original)
	await process_frame
	result_screen = main.screen
	result_screen._on_button("Edit Forces")
	await process_frame
	setup_screen = main.screen
	_check(setup_screen.scene_file_path == "res://ui/setup/Setup.tscn" and setup_screen.build_config()["blue"] == original["blue"], "Edit Forces preserves selection")
	print("UI smoke tests passed" if failures == 0 else "UI smoke failures: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
