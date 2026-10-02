class_name HeadlessBattle
extends RefCounted

static func create_setup(map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], blue_preset: ForcePresetDef, red_preset: ForcePresetDef, seed: int, first_side: StringName, spawn_swapped: bool) -> BattleState:
	var state := BattleState.new()
	state.map_id = map_def.id
	state.balance_id = balance.id
	state.seed = seed
	state.rng_state = BattleRng.initial_state(seed)
	state.first_side_id = first_side
	state.spawn_swapped = spawn_swapped
	for side_id in [&"blue", &"red"]:
		var side := SideState.new()
		side.id = side_id
		var preset := blue_preset if side_id == &"blue" else red_preset
		var spawns := map_def.red_spawn_cells if (side_id == &"blue") == spawn_swapped else map_def.blue_spawn_cells
		for index in preset.squad_unit_type_ids.size():
			var unit := _unit(units, StringName(preset.squad_unit_type_ids[index]))
			var squad := SquadState.new()
			squad.id = StringName("%s_%d" % [side_id, index])
			squad.side_id = side_id
			squad.unit_type_id = unit.id
			squad.position = spawns[index]
			for member_index in balance.members_per_squad:
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

static func run(setup: BattleState, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef], blue_policy: AiPolicyDef, red_policy: AiPolicyDef, verify_replay: bool = false) -> Dictionary:
	var errors := BattleValidator.validate_setup(setup, map_def, balance, units, terrains)
	if not errors.is_empty():
		return {"ok": false, "error": "invalid setup: %s" % errors}
	var state := BattleRules.copy_state(setup)
	var record := BattleReplayRecord.from_initial_state(setup, balance) if verify_replay else null
	var metrics := {
		"commands": 0, "activations": 0, "action_counts": {"MOVE": 0, "ATTACK": 0, "GUARD": 0, "SET_FRONT": 0, "PASS": 0},
		"damage_by_type": {"guard": 0, "striker": 0, "archer": 0},
		"kills_by_type": {"guard": 0, "striker": 0, "archer": 0},
		"wasted_actions": 0, "invalid_command_failures": 0, "invariant_failures": 0,
		"replay_failures": 0, "timeout": false
	}
	var command_limit := balance.round_cap * balance.squads_per_side * 2 * (balance.members_per_squad + 2) + 10
	while state.outcome == &"ongoing" and metrics["commands"] < command_limit:
		if state.active_squad_id.is_empty():
			var scheduled := BattleScheduler.next_activation(state, balance)
			if not scheduled["ok"]:
				return {"ok": false, "error": "scheduler: %s" % scheduled["error"], "metrics": metrics}
			state = scheduled["state"]
			if state.outcome != &"ongoing":
				metrics["timeout"] = true
				break
			metrics["activations"] += 1
		var legal := BattleRules.legal_commands(state, map_def, balance, units, terrains)
		var active_side := _active_side(state)
		var policy := blue_policy if active_side == &"blue" else red_policy
		var command := BaselineAi.choose_command(state, legal, map_def, balance, units, terrains, policy)
		if command == null or not legal.has(command):
			metrics["invalid_command_failures"] += 1
			return {"ok": false, "error": "AI chose no legal command", "metrics": metrics}
		if command.kind == BattleCommand.PASS:
			metrics["wasted_actions"] += _squad(state, command.squad_id).action_pool
		var target_before: CombatantState = null
		var attacker_type := ""
		if command.kind == BattleCommand.ATTACK:
			var attacker := _member(_squad(state, command.squad_id), command.attacker_id)
			attacker_type = str(attacker.unit_type_id)
			var target_squad := _squad(state, command.target_squad_id)
			var target_id := target_squad.front_member_id if command.target_member_id.is_empty() else command.target_member_id
			target_before = _member(target_squad, target_id)
		var applied := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
		if not applied["ok"]:
			metrics["invalid_command_failures"] += 1
			return {"ok": false, "error": "illegal AI command: %s" % applied["error"], "metrics": metrics}
		var next: BattleState = applied["state"]
		if command.kind == BattleCommand.ATTACK:
			var after := _member(_squad(next, command.target_squad_id), target_before.id)
			metrics["damage_by_type"][attacker_type] += target_before.current_hp - after.current_hp
			if after.current_hp == 0:
				metrics["kills_by_type"][attacker_type] += 1
		metrics["action_counts"][str(command.kind)] += 1
		metrics["commands"] += 1
		if verify_replay:
			record.append_command(command)
		var invariant_errors := BattleValidator.validate_state(next, map_def, balance, units, terrains)
		if not invariant_errors.is_empty():
			metrics["invariant_failures"] += 1
			return {"ok": false, "error": "invariant failure: %s" % invariant_errors, "metrics": metrics}
		state = next
	if state.outcome == &"ongoing":
		return {"ok": false, "error": "command limit reached before outcome", "metrics": metrics}
	if verify_replay:
		var replayed := BattleReplay.run(record, map_def, balance, units, terrains)
		if not replayed["ok"] or replayed["normalized"] != BattleStateCodec.normalized(state):
			metrics["replay_failures"] += 1
			return {"ok": false, "error": "replay mismatch: %s" % replayed["error"], "metrics": metrics}
	metrics["outcome"] = str(state.outcome)
	metrics["rounds"] = state.round
	metrics["first_side_id"] = str(setup.first_side_id)
	metrics["first_side_win"] = state.outcome == setup.first_side_id
	metrics["remaining"] = _remaining(state)
	return {"ok": true, "state": state, "metrics": metrics, "error": ""}

static func _remaining(state: BattleState) -> Dictionary:
	var result := {}
	for side in state.sides:
		var alive := 0
		var hp := 0
		var commanders := 0
		for squad in side.squads:
			for member in squad.members:
				if member.is_living():
					alive += 1
					hp += member.current_hp
					if member.is_commander:
						commanders += 1
		result[str(side.id)] = {"members": alive, "hp": hp, "commanders": commanders}
	return result

static func _active_side(state: BattleState) -> StringName:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == state.active_squad_id:
				return side.id
	return &""

static func _squad(state: BattleState, id: StringName) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

static func _member(squad: SquadState, id: StringName) -> CombatantState:
	for member in squad.members:
		if member.id == id:
			return member
	return null

static func _unit(units: Array[UnitTypeDef], id: StringName) -> UnitTypeDef:
	for unit in units:
		if unit.id == id:
			return unit
	return null
