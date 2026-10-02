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
	_test_scheduler()
	_test_dead_skips()
	_test_rng()
	_test_replay()
	if failures == 0:
		print("Scheduler/RNG/replay tests passed")
	quit(0 if failures == 0 else 1)

func _test_scheduler() -> void:
	var state := _new_state(123)
	var observed: Array[StringName] = []
	for index in 4:
		var result := BattleScheduler.next_activation(state, balance)
		_check("scheduler starts a squad", result["ok"])
		state = result["state"]
		observed.append(state.active_squad_id)
		_check("activation pool equals living members", _squad(state, state.active_squad_id).action_pool == 3)
		state = _apply(state, BattleCommand.pass_turn(state.active_squad_id))
	_check("odd round stable alternating order", observed == [&"blue_0", &"red_0", &"blue_1", &"red_1"])
	_check("all four activated once", state.activated_squad_ids == observed and state.activation_cursor == 4)
	var next := BattleScheduler.next_activation(state, balance)
	_check("next round starts after all living activate", next["ok"] and next["state"].round == 2)
	state = next["state"]
	_check("per-round tracking resets", state.activated_squad_ids.is_empty() and state.activation_cursor == 0 and state.active_squad_id == &"red_0")
	observed.clear()
	observed.append(state.active_squad_id)
	state = _apply(state, BattleCommand.pass_turn(state.active_squad_id))
	for index in 3:
		next = BattleScheduler.next_activation(state, balance)
		state = next["state"]
		observed.append(state.active_squad_id)
		state = _apply(state, BattleCommand.pass_turn(state.active_squad_id))
	_check("even round reverses first side", observed == [&"red_0", &"blue_0", &"red_1", &"blue_1"])
	var short_cap := BattleBalanceDef.new()
	short_cap.round_cap = 2
	next = BattleScheduler.next_activation(state, short_cap)
	_check("round cap produces draw", next["ok"] and next["state"].outcome == &"draw" and next["state"].active_squad_id.is_empty())

	state = _new_state(123)
	state.first_side_id = &"red"
	next = BattleScheduler.next_activation(state, balance)
	_check("initial side metadata can select red", next["ok"] and next["state"].active_squad_id == &"red_0")

func _test_dead_skips() -> void:
	var state := _new_state(7)
	for member in _squad(state, &"red_0").members:
		member.current_hp = 0
	_check("dead before turn omitted from pending list", BattleScheduler.pending_squad_ids(state) == [&"blue_0", &"blue_1", &"red_1"])
	state = BattleScheduler.next_activation(state, balance)["state"]
	state = _apply(state, BattleCommand.pass_turn(&"blue_0"))
	state = BattleScheduler.next_activation(state, balance)["state"]
	_check("scheduler skips dead squad", state.active_squad_id == &"blue_1")

	state = _new_state(7)
	_squad(state, &"blue_0").position = Vector2i(7, 2)
	_squad(state, &"blue_1").position = Vector2i(7, 3)
	for member in _squad(state, &"red_0").members:
		member.current_hp = 0
	_squad(state, &"red_0").members[0].current_hp = 1
	state = BattleScheduler.next_activation(state, balance)["state"]
	state = _apply(state, BattleCommand.pass_turn(&"blue_0"))
	state = BattleScheduler.next_activation(state, balance)["state"]
	state = _apply(state, BattleCommand.pass_turn(&"red_0"))
	state = BattleScheduler.next_activation(state, balance)["state"]
	state = _apply(state, BattleCommand.attack(&"blue_1", _squad(state, &"blue_1").members[0].id, &"red_0"))
	state = _apply(state, BattleCommand.pass_turn(&"blue_1"))
	_check("killed squad remains recorded as already activated", state.activated_squad_ids.has(&"red_0") and _squad(state, &"red_0").living_member_count() == 0)
	_check("killed squad is not scheduled again", BattleScheduler.pending_squad_ids(state) == [&"red_1"])
	state = BattleScheduler.next_activation(state, balance)["state"]
	_check("remaining red squad activates", state.active_squad_id == &"red_1")

func _test_rng() -> void:
	var first := BattleRng.initial_state(42)
	var second := BattleRng.initial_state(42)
	var other := BattleRng.initial_state(43)
	var seq_a: Array[int] = []
	var seq_b: Array[int] = []
	var seq_c: Array[int] = []
	for index in 5:
		var a := BattleRng.next_u32(first)
		var b := BattleRng.next_u32(second)
		var c := BattleRng.next_u32(other)
		first = a["state"]
		second = b["state"]
		other = c["state"]
		seq_a.append(a["value"])
		seq_b.append(b["value"])
		seq_c.append(c["value"])
	_check("same seed yields same RNG sequence", seq_a == seq_b)
	_check("xorshift32 v1 known seed-42 vector", seq_a == [11355432, 2836018348, 476557059, 3648046016, 3759983556])
	_check("different seeds differ in sample", seq_a != seq_c)
	_check("RNG state restoration continues sequence", BattleRng.next_u32(first) == BattleRng.next_u32(second))
	var state := _new_state(42)
	var untouched := BattleStateCodec.normalized(state)
	var advanced := BattleRng.advance(state)
	_check("explicit RNG advance changes copied state", advanced["ok"] and advanced["state"].rng_state != state.rng_state and BattleStateCodec.normalized(state) == untouched)
	var copied := BattleRules.copy_state(advanced["state"])
	_check("copied RNG state continues identically", BattleRng.advance(copied)["value"] == BattleRng.advance(advanced["state"])["value"])

func _test_replay() -> void:
	var setup := _new_state(12345)
	var record := BattleReplayRecord.from_initial_state(setup, balance)
	var state := BattleStateCodec.initial_from_replay(record)
	_check("restart recreates identical initial state", BattleStateCodec.normalized(state) == BattleStateCodec.normalized(BattleStateCodec.initial_from_replay(record)))
	_check("replay setup validates", BattleValidator.validate_setup(state, map_def, balance, units, terrains).is_empty())
	var commands: Array[BattleCommand] = []
	commands.append(BattleCommand.move(&"blue_0", [Vector2i(1, 2)]))
	commands.append(BattleCommand.pass_turn(&"blue_0"))
	commands.append(BattleCommand.guard(&"red_0"))
	commands.append(BattleCommand.pass_turn(&"red_0"))
	commands.append(BattleCommand.set_front(&"blue_1", _squad(state, &"blue_1").members[1].id))
	commands.append(BattleCommand.pass_turn(&"blue_1"))
	commands.append(BattleCommand.pass_turn(&"red_1"))
	commands.append(BattleCommand.pass_turn(&"red_0"))
	for command in commands:
		if state.active_squad_id.is_empty():
			var scheduled := BattleScheduler.next_activation(state, balance)
			_check("record scheduling succeeds", scheduled["ok"])
			state = scheduled["state"]
		_check("record command matches scheduler", command.squad_id == state.active_squad_id)
		state = _apply(state, command)
		record.append_command(command)
	var saved := JSON.stringify(record.to_dict())
	var restored := BattleReplayRecord.from_dict(JSON.parse_string(saved))
	var replayed := BattleReplay.run(restored, map_def, balance, units, terrains)
	_check("replay succeeds", replayed["ok"])
	if replayed["ok"]:
		_check("replay normalized state equals original", replayed["normalized"] == BattleStateCodec.normalized(state))
		_check("replay outcome equals original", replayed["outcome"] == state.outcome)
		var again := BattleReplay.run(restored, map_def, balance, units, terrains)
		_check("replaying twice is identical", again["ok"] and again["normalized"] == replayed["normalized"])
	var tampered := BattleReplayRecord.from_dict(record.to_dict())
	tampered.command_log[0]["path"] = [[8, 2]]
	var bad := BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("illegal replay command rejected", not bad["ok"] and "illegal command 0" in bad["error"])
	tampered = BattleReplayRecord.from_dict(record.to_dict())
	tampered.command_log[0]["squad_id"] = "red_0"
	bad = BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("wrong scheduled squad rejected", not bad["ok"] and "scheduled activation" in bad["error"])
	tampered = BattleReplayRecord.from_dict(record.to_dict())
	tampered.command_log[0]["path"] = [[1.5, 2]]
	bad = BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("noninteger path coordinate rejected", not bad["ok"] and "path coordinates" in bad["error"])
	tampered = BattleReplayRecord.from_dict(record.to_dict())
	tampered.map_id = &"wrong_map"
	bad = BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("wrong map rejected clearly", not bad["ok"] and "map ID" in bad["error"])
	tampered = BattleReplayRecord.from_dict(record.to_dict())
	tampered.balance_version = &"wrong_version"
	bad = BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("wrong balance rejected clearly", not bad["ok"] and "balance" in bad["error"])
	tampered = BattleReplayRecord.from_dict(record.to_dict())
	tampered.replay_version = 999
	bad = BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("wrong replay version rejected clearly", not bad["ok"] and "version" in bad["error"])
	tampered = BattleReplayRecord.from_dict(record.to_dict())
	tampered.setup_sides[0]["squads"][0].erase("position")
	bad = BattleReplay.run(tampered, map_def, balance, units, terrains)
	_check("malformed setup rejected clearly", not bad["ok"] and "squad missing position" in bad["error"])
	var cap_record := BattleReplayRecord.from_initial_state(setup, balance)
	for squad_id in [&"blue_0", &"red_0", &"blue_1", &"red_1"]:
		cap_record.append_command(BattleCommand.pass_turn(squad_id))
	var short_cap := BattleBalanceDef.new()
	short_cap.id = balance.id
	short_cap.version = balance.version
	short_cap.round_cap = 1
	var capped := BattleReplay.run(cap_record, map_def, short_cap, units, terrains)
	_check("replay resolves completed round cap", capped["ok"] and capped["outcome"] == &"draw")

func _new_state(seed: int) -> BattleState:
	var state := BattleState.new()
	state.map_id = map_def.id
	state.balance_id = balance.id
	state.seed = seed
	state.rng_state = BattleRng.initial_state(seed)
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

func _squad(state: BattleState, id: StringName) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

func _apply(state: BattleState, command: BattleCommand) -> BattleState:
	var result := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
	_check("apply %s: %s" % [command.kind, result["error"]], result["ok"])
	return result["state"]

func _check(label: String, condition: bool) -> void:
	if not condition:
		push_error("FAILED: %s" % label)
		failures += 1
