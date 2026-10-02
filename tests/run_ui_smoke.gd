extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := load("res://ui/main/Main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	var setup_screen: Control = main.screen
	_check(setup_screen.scene_file_path == "res://ui/setup/Setup.tscn", "Setup scene loads")
	setup_screen.autofill("blue")
	setup_screen.autofill("red")
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
	_check(attack != null and attack_scene.submit_command(attack), "Blue can attack")
	_check(attack_scene._squad(&"red_0").members[0].current_hp < hp_before, "attack changes canonical HP")
	attack_scene.queue_free()
	main.show_battle(config)
	await process_frame
	var battle_screen: Control = main.screen
	battle_screen.ai_step_delay = 0.0
	_check(battle_screen.scene_file_path == "res://ui/battle/Battle.tscn", "Battle scene loads")
	_check(battle_screen.board.map_def.width == 9 and battle_screen.board.map_def.height == 7, "9x7 board renders")
	_check(battle_screen.state != null and battle_screen.state.outcome == &"ongoing", "Start Battle creates state")
	var first_move: BattleCommand = null
	for command in battle_screen.legal:
		if command.kind == BattleCommand.MOVE:
			first_move = command
			break
	_check(first_move != null and battle_screen.submit_command(first_move), "Blue can move")
	var first_pass: BattleCommand = null
	for command in battle_screen.legal:
		if command.kind == BattleCommand.PASS:
			first_pass = command
			break
	_check(first_pass != null and battle_screen.submit_command(first_pass), "Blue can pass")
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
