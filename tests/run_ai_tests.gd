extends SceneTree

var failures := 0
var units: Array[UnitTypeDef]
var terrains: Array[TerrainDef]
var map_def: BattleMapDef
var broken_pass: BattleMapDef
var balance: BattleBalanceDef
var policy: AiPolicyDef
var guard_archer: ForcePresetDef
var archer_archer: ForcePresetDef

func _initialize() -> void:
	units = [load("res://data/unit_types/guard.tres"), load("res://data/unit_types/striker.tres"), load("res://data/unit_types/archer.tres")]
	terrains = [load("res://data/terrain/plain.tres"), load("res://data/terrain/rough.tres"), load("res://data/terrain/blocked.tres")]
	map_def = load("res://data/maps/open_field.tres")
	broken_pass = load("res://data/maps/broken_pass.tres")
	balance = load("res://data/balance/default.tres")
	policy = load("res://ai/default_policy.tres")
	guard_archer = load("res://data/forces/guard_archer.tres")
	archer_archer = load("res://data/forces/archer_archer.tres")
	for resource in units + terrains + [map_def, broken_pass, balance, policy, guard_archer, archer_archer]:
		if resource == null:
			push_error("AI test resource failed to load")
			quit(1)
			return
	_test_attacks()
	_test_movement_guard_pass()
	_test_determinism_and_driver()
	if failures == 0:
		print("AI/headless tests passed")
	quit(0 if failures == 0 else 1)

func _test_attacks() -> void:
	var state := _setup(guard_archer, guard_archer)
	_squad(state, &"blue_1").position = Vector2i(5, 4)
	_squad(state, &"red_1").position = Vector2i(8, 4)
	_squad(state, &"red_1").members[0].current_hp = 1
	state = BattleRules.start_activation(state, &"blue_1")["state"]
	var chosen := _choose(state, map_def)
	_check("lethal attack preferred", chosen.kind == BattleCommand.ATTACK and chosen.target_squad_id == &"red_1")

	state = _setup(guard_archer, guard_archer)
	_squad(state, &"blue_1").position = Vector2i(5, 4)
	_squad(state, &"red_0").position = Vector2i(6, 4)
	_squad(state, &"red_1").position = Vector2i(8, 4)
	_squad(state, &"red_1").front_member_id = _squad(state, &"red_1").members[1].id
	state = BattleRules.start_activation(state, &"blue_1")["state"]
	chosen = _choose(state, map_def)
	_check("higher expected damage beats commander on armored target", chosen.kind == BattleCommand.ATTACK and chosen.target_squad_id == &"red_1")

	state = _setup(archer_archer, archer_archer)
	_squad(state, &"blue_0").position = Vector2i(4, 3)
	_squad(state, &"red_0").position = Vector2i(5, 3)
	_squad(state, &"red_1").position = Vector2i(3, 3)
	_squad(state, &"red_1").front_member_id = _squad(state, &"red_1").members[1].id
	state = BattleRules.start_activation(state, &"blue_0")["state"]
	chosen = _choose(state, map_def)
	_check("commander damage wins equal-damage choice", chosen.kind == BattleCommand.ATTACK and chosen.target_squad_id == &"red_0")
	var first_key := _command_key(chosen)
	for index in 5:
		_check("stable tie-break repeats", _command_key(_choose(state, map_def)) == first_key)

func _test_movement_guard_pass() -> void:
	var state := _setup(guard_archer, guard_archer)
	_squad(state, &"blue_0").position = Vector2i(6, 2)
	state = BattleRules.start_activation(state, &"blue_0")["state"]
	var chosen := _choose(state, map_def)
	_check("move enabling same-activation attack preferred", chosen.kind == BattleCommand.MOVE and chosen.path.back() == Vector2i(7, 2))

	state = _setup(guard_archer, guard_archer)
	_squad(state, &"blue_0").position = Vector2i(4, 3)
	_squad(state, &"red_0").position = Vector2i(6, 3)
	var blocked := _blocked_map([Vector2i(5, 3), Vector2i(4, 2), Vector2i(4, 4)])
	state = BattleRules.start_activation(state, &"blue_0")["state"]
	chosen = _choose(state, blocked)
	_check("guard when threatened without useful move", chosen.kind == BattleCommand.GUARD)
	state = BattleRules.apply_command(state, chosen, blocked, balance, units, terrains)["state"]
	chosen = _choose(state, blocked)
	_check("pass after guard when no useful action", chosen.kind == BattleCommand.PASS)
	_squad(state, &"blue_0").members[0].current_hp = 1
	chosen = _choose(state, blocked)
	_check("set front after guard when survivability improves", chosen.kind == BattleCommand.SET_FRONT and chosen.front_member_id != _squad(state, &"blue_0").front_member_id)
	state = _setup(guard_archer, guard_archer)
	_squad(state, &"blue_0").position = Vector2i(4, 3)
	_squad(state, &"red_0").position = Vector2i(8, 3)
	_squad(state, &"red_1").position = Vector2i(8, 6)
	blocked = _blocked_map([Vector2i(5, 3), Vector2i(4, 2), Vector2i(4, 4)])
	state = BattleRules.start_activation(state, &"blue_0")["state"]
	chosen = _choose(state, blocked)
	_check("pass when no threat or useful move", chosen.kind == BattleCommand.PASS)

func _test_determinism_and_driver() -> void:
	var first := _setup(guard_archer, archer_archer)
	var second := BattleRules.copy_state(first)
	var one := HeadlessBattle.run(first, map_def, balance, units, terrains, policy, policy, true)
	var two := HeadlessBattle.run(second, map_def, balance, units, terrains, policy, policy, true)
	_check("same seed/policy/setup gives identical result", one["ok"] and two["ok"] and BattleStateCodec.normalized(one["state"]) == BattleStateCodec.normalized(two["state"]))
	for index in 24:
		var selected_map := map_def if index % 2 == 0 else broken_pass
		var blue := guard_archer if index % 3 == 0 else archer_archer
		var red := archer_archer if index % 3 == 0 else guard_archer
		var setup := HeadlessBattle.create_setup(selected_map, balance, units, blue, red, 100 + index, &"blue" if index % 2 == 0 else &"red", index % 4 >= 2)
		var result := HeadlessBattle.run(setup, selected_map, balance, units, terrains, policy, policy, index % 8 == 0)
		_check("small battle %d terminates validly" % index, result["ok"] and result["metrics"]["invalid_command_failures"] == 0 and result["metrics"]["invariant_failures"] == 0 and result["state"].outcome != &"ongoing")

func _choose(state: BattleState, selected_map: BattleMapDef) -> BattleCommand:
	var legal := BattleRules.legal_commands(state, selected_map, balance, units, terrains)
	var chosen := BaselineAi.choose_command(state, legal, selected_map, balance, units, terrains, policy)
	_check("AI returns a legal command", chosen != null and legal.has(chosen))
	return chosen

func _setup(blue: ForcePresetDef, red: ForcePresetDef) -> BattleState:
	return HeadlessBattle.create_setup(map_def, balance, units, blue, red, 42, &"blue", false)

func _blocked_map(cells: Array[Vector2i]) -> BattleMapDef:
	var result := BattleMapDef.new()
	result.id = map_def.id
	result.width = map_def.width
	result.height = map_def.height
	result.default_terrain_id = map_def.default_terrain_id
	result.terrain_cells = map_def.terrain_cells.duplicate()
	result.terrain_cell_ids = map_def.terrain_cell_ids.duplicate()
	for cell in cells:
		result.terrain_cells.append(cell)
		result.terrain_cell_ids.append("blocked")
	return result

func _squad(state: BattleState, id: StringName) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

func _command_key(command: BattleCommand) -> String:
	return "%s|%s|%s|%s|%s" % [command.kind, command.squad_id, command.attacker_id, command.target_squad_id, command.target_member_id]

func _check(label: String, condition: bool) -> void:
	if not condition:
		push_error("FAILED: %s" % label)
		failures += 1
