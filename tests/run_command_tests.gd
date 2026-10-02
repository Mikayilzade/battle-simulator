extends SceneTree

var failures := 0
var units: Array[UnitTypeDef]
var terrains: Array[TerrainDef]
var map_def: BattleMapDef
var balance: BattleBalanceDef

func _initialize() -> void:
	units = [load("res://data/unit_types/guard.tres"), load("res://data/unit_types/striker.tres"), load("res://data/unit_types/archer.tres")]
	terrains = [load("res://data/terrain/plain.tres"), load("res://data/terrain/rough.tres"), load("res://data/terrain/blocked.tres")]
	map_def = load("res://data/maps/open_field.tres")
	balance = load("res://data/balance/default.tres")
	for resource in units + terrains + [map_def, balance]:
		if resource == null:
			push_error("authored resource failed to load")
			quit(1)
			return
	_test_activation_and_movement()
	_test_attacks_and_front()
	_test_guard_and_cover()
	_test_pass_and_round()
	_test_casualty_pool_and_outcome()
	if failures == 0:
		print("Command transition tests passed")
	quit(0 if failures == 0 else 1)

func _test_activation_and_movement() -> void:
	var state := _new_state()
	state = _start(state, &"blue_0")
	_check("activation grants living member count", _squad(state, &"blue_0").action_pool == 3)
	_check("legal commands include pass, guard and move", _has_kind(BattleRules.legal_commands(state, map_def, balance, units, terrains), BattleCommand.PASS) and _has_kind(BattleRules.legal_commands(state, map_def, balance, units, terrains), BattleCommand.GUARD) and _has_kind(BattleRules.legal_commands(state, map_def, balance, units, terrains), BattleCommand.MOVE))
	_reject_unchanged("diagonal move", state, BattleCommand.move(&"blue_0", [Vector2i(1, 3)]))
	_reject_unchanged("over budget path", state, BattleCommand.move(&"blue_0", [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]))
	_reject_unchanged("occupied path", state, BattleCommand.move(&"blue_0", [Vector2i(0, 3), Vector2i(0, 4)]))
	var blocked_map := _map_with_block(Vector2i(1, 2))
	_reject_unchanged("blocked path", state, BattleCommand.move(&"blue_0", [Vector2i(1, 2)]), blocked_map)
	var moved := _apply(state, BattleCommand.move(&"blue_0", [Vector2i(1, 2), Vector2i(2, 2)]))
	_check("orthogonal move costs one action", _squad(moved, &"blue_0").position == Vector2i(2, 2) and _squad(moved, &"blue_0").action_pool == 2)
	_reject_unchanged("second move", moved, BattleCommand.move(&"blue_0", [Vector2i(3, 2)]))
	state = _new_state()
	_squad(state, &"blue_0").position = Vector2i(3, 2)
	state = _start(state, &"blue_0")
	var rough := _apply(state, BattleCommand.move(&"blue_0", [Vector2i(4, 2)]))
	_check("rough costs two movement points", _squad(rough, &"blue_0").position == Vector2i(4, 2))
	_reject_unchanged("rough plus plain exceeds budget", state, BattleCommand.move(&"blue_0", [Vector2i(4, 2), Vector2i(5, 2)]))
	_check("legal commands omit second move", not _has_kind(BattleRules.legal_commands(moved, map_def, balance, units, terrains), BattleCommand.MOVE))
	_check("valid move leaves source unchanged", _squad(state, &"blue_0").position == Vector2i(3, 2))

func _test_attacks_and_front() -> void:
	var state := _new_state()
	_squad(state, &"blue_0").position = Vector2i(7, 2)
	state = _start(state, &"blue_0")
	var attacker := _squad(state, &"blue_0").members[0].id
	var red := _squad(state, &"red_0")
	var front := red.front_member_id
	_reject_unchanged("melee rear target", state, BattleCommand.attack(&"blue_0", attacker, &"red_0", red.members[1].id))
	_check("melee target is legal", _has_kind(BattleRules.legal_commands(state, map_def, balance, units, terrains), BattleCommand.ATTACK))
	var hit := _apply(state, BattleCommand.attack(&"blue_0", attacker, &"red_0"))
	_check("commander bonus and melee front damage", _member(_squad(hit, &"red_0"), front).current_hp == 12 and _squad(hit, &"red_0").members[1].current_hp == 12)
	_reject_unchanged("same member attacks twice", hit, BattleCommand.attack(&"blue_0", attacker, &"red_0"))
	var second := _apply(hit, BattleCommand.attack(&"blue_0", _squad(hit, &"blue_0").members[1].id, &"red_0"))
	_check("different member may attack", _member(_squad(second, &"red_0"), front).current_hp == 11 and _squad(second, &"blue_0").action_pool == 1)
	_check("attack leaves source unchanged", _member(_squad(state, &"red_0"), front).current_hp == 14)

	state = _new_state()
	_squad(state, &"blue_1").position = Vector2i(5, 4)
	_squad(state, &"red_1").position = Vector2i(8, 4)
	state = _start(state, &"blue_1")
	var archer := _squad(state, &"blue_1").members[0].id
	var red_rear := _squad(state, &"red_1").members[1].id
	var rear_hit := _apply(state, BattleCommand.attack(&"blue_1", archer, &"red_1", red_rear))
	_check("Archer range three and rear penalty", _member(_squad(rear_hit, &"red_1"), red_rear).current_hp == 4)
	_reject_unchanged("Archer out of range", state, BattleCommand.attack(&"blue_1", archer, &"red_0"))
	var sight_map := _map_with_block(Vector2i(6, 4))
	_reject_unchanged("blocked line of sight", state, BattleCommand.attack(&"blue_1", archer, &"red_1"), sight_map)

	state = _new_state()
	_squad(state, &"blue_0").position = Vector2i(7, 2)
	_squad(state, &"red_0").members[0].current_hp = 1
	state = _start(state, &"blue_0")
	var replacement := _apply(state, BattleCommand.attack(&"blue_0", _squad(state, &"blue_0").members[0].id, &"red_0"))
	_check("front death selects next living roster member", _squad(replacement, &"red_0").front_member_id == _squad(replacement, &"red_0").members[1].id and _squad(replacement, &"red_0").members[0].current_hp == 0)
	_check("state validates after front replacement", BattleValidator.validate_state(replacement, map_def, balance, units, terrains).is_empty())
	state = _new_state()
	_squad(state, &"blue_0").position = Vector2i(7, 2)
	_squad(state, &"red_0").front_member_id = _squad(state, &"red_0").members[1].id
	_squad(state, &"red_0").members[1].current_hp = 1
	state = _start(state, &"blue_0")
	replacement = _apply(state, BattleCommand.attack(&"blue_0", _squad(state, &"blue_0").members[0].id, &"red_0"))
	_check("manual front death chooses next roster member", _squad(replacement, &"red_0").front_member_id == _squad(replacement, &"red_0").members[2].id)

func _test_guard_and_cover() -> void:
	var state := _new_state()
	_squad(state, &"blue_1").position = Vector2i(7, 4)
	state = _start(state, &"red_1")
	state = _apply(state, BattleCommand.guard(&"red_1"))
	_check("guard costs one and stays active", _squad(state, &"red_1").guarding and _squad(state, &"red_1").action_pool == 2)
	_reject_unchanged("guard cannot stack", state, BattleCommand.guard(&"red_1"))
	state = _apply(state, BattleCommand.pass_turn(&"red_1"))
	state = _start(state, &"blue_1")
	var target := _squad(state, &"red_1").members[0].id
	var hit := _apply(state, BattleCommand.attack(&"blue_1", _squad(state, &"blue_1").members[0].id, &"red_1"))
	_check("guard reduces deterministic damage", _member(_squad(hit, &"red_1"), target).current_hp == 5)
	var next_round := _apply(hit, BattleCommand.pass_turn(&"blue_1"))
	for squad_id in [&"blue_0", &"red_0"]:
		next_round = _start(next_round, squad_id)
		next_round = _apply(next_round, BattleCommand.pass_turn(squad_id))
	next_round = BattleRules.finish_round(next_round, balance)["state"]
	next_round = _start(next_round, &"red_1")
	_check("guard expires at squad next activation", not _squad(next_round, &"red_1").guarding)
	state = _new_state()
	_squad(state, &"blue_1").position = Vector2i(3, 4)
	_squad(state, &"red_1").position = Vector2i(4, 4)
	state = _start(state, &"blue_1")
	var covered := _apply(state, BattleCommand.attack(&"blue_1", _squad(state, &"blue_1").members[0].id, &"red_1"))
	_check("rough cover reduces damage", _squad(covered, &"red_1").members[0].current_hp == 5)

func _test_pass_and_round() -> void:
	var state := _new_state()
	state = _start(state, &"blue_0")
	var new_front := _squad(state, &"blue_0").members[2].id
	state = _apply(state, BattleCommand.set_front(&"blue_0", new_front))
	_check("set front costs one action", _squad(state, &"blue_0").front_member_id == new_front and _squad(state, &"blue_0").action_pool == 2)
	state = _apply(state, BattleCommand.pass_turn(&"blue_0"))
	_check("pass is free and discards actions", state.active_squad_id.is_empty() and _squad(state, &"blue_0").action_pool == 0 and state.activated_squad_ids.has(&"blue_0"))
	_reject_unchanged("command after pass", state, BattleCommand.guard(&"blue_0"))
	var repeated := BattleRules.start_activation(state, &"blue_0")
	_check("squad cannot activate twice in round", not repeated["ok"] and repeated["state"] == state)
	var early := BattleRules.finish_round(state, balance)
	_check("round cannot end before all living squads activate", not early["ok"] and early["state"] == state)
	for squad_id in [&"red_0", &"blue_1", &"red_1"]:
		state = _start(state, squad_id)
		state = _apply(state, BattleCommand.pass_turn(squad_id))
	var short_cap := BattleBalanceDef.new()
	short_cap.round_cap = 1
	var capped := BattleRules.finish_round(state, short_cap)
	_check("round cap resolves equal score as draw", capped["ok"] and capped["state"].outcome == &"draw" and state.outcome == &"ongoing")
	var round_result := BattleRules.finish_round(state, balance)
	_check("round advances after four activations", round_result["ok"] and round_result["state"].round == 2)
	state = round_result["state"]
	state = _start(state, &"blue_0")
	_check("manual front persists into next activation", _squad(state, &"blue_0").front_member_id == new_front)
	_check("new activation restores action pool", _squad(state, &"blue_0").action_pool == 3)
	_squad(state, &"blue_0").members[1].current_hp = 0
	_reject_unchanged("set front rejects dead member", state, BattleCommand.set_front(&"blue_0", _squad(state, &"blue_0").members[1].id))
	_reject_unchanged("dead member cannot attack", state, BattleCommand.attack(&"blue_0", _squad(state, &"blue_0").members[1].id, &"red_0"))

func _test_casualty_pool_and_outcome() -> void:
	var state := _new_state()
	state = _start(state, &"blue_0")
	_squad(state, &"blue_0").members[2].current_hp = 0
	_check("casualty fixture remains valid", BattleValidator.validate_state(state, map_def, balance, units, terrains).is_empty())
	state = _apply(state, BattleCommand.guard(&"blue_0"))
	_check("current pool does not shrink after casualty", _squad(state, &"blue_0").action_pool == 2 and _squad(state, &"blue_0").living_member_count() == 2)
	state = _apply(state, BattleCommand.pass_turn(&"blue_0"))
	for squad_id in [&"red_0", &"blue_1", &"red_1"]:
		state = _start(state, squad_id)
		state = _apply(state, BattleCommand.pass_turn(squad_id))
	state = BattleRules.finish_round(state, balance)["state"]
	state = _start(state, &"blue_0")
	_check("next activation pool reflects casualty", _squad(state, &"blue_0").action_pool == 2)
	state = _new_state()
	for member in _squad(state, &"blue_0").members:
		member.current_hp = 0
	var dead_start := BattleRules.start_activation(state, &"blue_0")
	_check("dead squad cannot activate", not dead_start["ok"] and dead_start["state"] == state)

	state = _new_state()
	_squad(state, &"blue_0").position = Vector2i(7, 2)
	for member in _squad(state, &"red_1").members:
		member.current_hp = 0
	for member in _squad(state, &"red_0").members:
		member.current_hp = 0
	_squad(state, &"red_0").members[0].current_hp = 1
	state = _start(state, &"blue_0")
	var final_hit := _apply(state, BattleCommand.attack(&"blue_0", _squad(state, &"blue_0").members[0].id, &"red_0"))
	_check("elimination sets blue outcome", final_hit.outcome == &"blue" and final_hit.active_squad_id.is_empty())
	_check("finished battle has no legal commands", BattleRules.legal_commands(final_hit, map_def, balance, units, terrains).is_empty())

func _new_state() -> BattleState:
	var state := BattleState.new()
	state.map_id = map_def.id
	state.balance_id = balance.id
	for side_index in 2:
		var side := SideState.new()
		side.id = &"blue" if side_index == 0 else &"red"
		for squad_index in 2:
			var squad := SquadState.new()
			squad.id = StringName("%s_%d" % [side.id, squad_index])
			squad.side_id = side.id
			var unit := units[0] if squad_index == 0 else units[2]
			squad.unit_type_id = unit.id
			squad.position = (map_def.blue_spawn_cells if side_index == 0 else map_def.red_spawn_cells)[squad_index]
			for member_index in 3:
				var member := CombatantState.new()
				member.id = StringName("%s_%d" % [squad.id, member_index])
				member.squad_id = squad.id
				member.unit_type_id = unit.id
				member.is_commander = member_index == 0
				member.max_hp = unit.max_hp + (balance.commander_max_hp_bonus if member.is_commander else 0)
				member.current_hp = member.max_hp
				squad.members.append(member)
			squad.front_member_id = squad.members[0].id
			side.squads.append(squad)
		state.sides.append(side)
	return state

func _map_with_block(cell: Vector2i) -> BattleMapDef:
	var result := BattleMapDef.new()
	result.id = map_def.id
	result.width = map_def.width
	result.height = map_def.height
	result.default_terrain_id = map_def.default_terrain_id
	result.terrain_cells = map_def.terrain_cells.duplicate()
	result.terrain_cells.append(cell)
	result.terrain_cell_ids = map_def.terrain_cell_ids.duplicate()
	result.terrain_cell_ids.append("blocked")
	return result

func _start(state: BattleState, squad_id: StringName) -> BattleState:
	var result := BattleRules.start_activation(state, squad_id)
	_check("start %s" % squad_id, result["ok"])
	return result["state"]

func _apply(state: BattleState, command: BattleCommand) -> BattleState:
	var result := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
	_check("apply %s: %s" % [command.kind, result["error"]], result["ok"])
	return result["state"]

func _reject_unchanged(label: String, state: BattleState, command: BattleCommand, selected_map: BattleMapDef = null) -> bool:
	var before := _snapshot(state)
	var result := BattleRules.apply_command(state, command, map_def if selected_map == null else selected_map, balance, units, terrains)
	var passed: bool = not result["ok"] and result["state"] == state and _snapshot(state) == before
	_check(label, passed)
	return passed

func _snapshot(state: BattleState) -> String:
	var parts := [str(state.round), str(state.activation_cursor), str(state.active_squad_id), str(state.activated_squad_ids), str(state.outcome)]
	for side in state.sides:
		for squad in side.squads:
			parts.append(str([squad.id, squad.position, squad.front_member_id, squad.action_pool, squad.moved_this_activation, squad.attacked_member_ids, squad.guarding, squad.is_active]))
			for member in squad.members:
				parts.append(str([member.id, member.current_hp]))
	return "|".join(parts)

func _squad(state: BattleState, id: StringName) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

func _member(squad: SquadState, id: StringName) -> CombatantState:
	for member in squad.members:
		if member.id == id:
			return member
	return null

func _has_kind(commands: Array[BattleCommand], kind: StringName) -> bool:
	for command in commands:
		if command.kind == kind:
			return true
	return false

func _check(label: String, condition: bool) -> void:
	if not condition:
		push_error("FAILED: %s" % label)
		failures += 1
