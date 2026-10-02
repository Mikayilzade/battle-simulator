extends SceneTree

var failures := 0

func _initialize() -> void:
	var units: Array[UnitTypeDef] = [
		load("res://data/unit_types/guard.tres"),
		load("res://data/unit_types/striker.tres"),
		load("res://data/unit_types/archer.tres")
	]
	var terrains: Array[TerrainDef] = [
		load("res://data/terrain/plain.tres"),
		load("res://data/terrain/rough.tres"),
		load("res://data/terrain/blocked.tres")
	]
	var maps: Array[BattleMapDef] = [load("res://data/maps/open_field.tres")]
	var balances: Array[BattleBalanceDef] = [load("res://data/balance/default.tres")]
	var presets: Array[ForcePresetDef] = [load("res://data/forces/guard_archer.tres")]
	for resource in units + terrains + maps + balances + presets:
		if resource == null:
			push_error("authored resource failed to load")
			quit(1)
			return
	_expect_empty("authored defaults", BattleValidator.validate_definitions(units, terrains, maps, balances, presets))
	_expect_true("provisional unit values", units[0].max_hp == 12 and units[0].armor == 3 and units[0].power == 4 and units[0].movement == 2 and units[1].max_hp == 9 and units[1].armor == 1 and units[1].power == 6 and units[1].movement == 3 and units[2].max_hp == 8 and units[2].armor == 0 and units[2].power == 5 and units[2].movement == 2 and units[2].attack_range == 3)
	_expect_true("provisional balance and terrain", balances[0].commander_max_hp_bonus == 2 and balances[0].commander_power_bonus == 1 and balances[0].rear_ranged_power_penalty == 2 and balances[0].round_cap == 20 and balances[0].guard_bonus_armor == 1 and terrains[0].movement_cost == 1 and terrains[1].movement_cost == 2 and terrains[1].cover == 1)
	var state := _make_state(maps[0], balances[0], units)
	_expect_empty("valid battle state", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	_expect_empty("valid battle setup", BattleValidator.validate_setup(state, maps[0], balances[0], units, terrains))

	var duplicate_unit := UnitTypeDef.new()
	duplicate_unit.id = &"guard"
	_expect_error("duplicate definition ID", BattleValidator.validate_definitions([units[0], duplicate_unit], terrains, maps, balances, presets))
	var unknown_preset := ForcePresetDef.new()
	unknown_preset.id = &"invalid"
	unknown_preset.squad_unit_type_ids = PackedStringArray(["guard", "ghost"])
	_expect_error("unknown preset reference", BattleValidator.validate_definitions(units, terrains, maps, balances, [unknown_preset]))
	var invalid_map := BattleMapDef.new()
	invalid_map.id = &"invalid_map"
	invalid_map.width = 9
	invalid_map.height = 7
	invalid_map.default_terrain_id = &"plain"
	invalid_map.terrain_cells = [Vector2i(0, 2), Vector2i(0, 2)]
	invalid_map.terrain_cell_ids = PackedStringArray(["blocked", "rough"])
	invalid_map.blue_spawn_cells = [Vector2i(0, 2)]
	invalid_map.red_spawn_cells = [Vector2i(9, 0)]
	_expect_error("invalid map cells", BattleValidator.validate_definitions(units, terrains, [invalid_map], balances, presets))
	var invalid_balance := BattleBalanceDef.new()
	invalid_balance.id = &"invalid"
	invalid_balance.version = &"v1"
	invalid_balance.round_cap = 0
	_expect_error("invalid balance bounds", invalid_balance.validation_errors())

	state.sides[1].squads[0].position = state.sides[0].squads[0].position
	_expect_error("overlapping squads", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].members[0].current_hp = -1
	_expect_error("negative HP", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].members[0].current_hp = 0
	_expect_error("dead front member", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].action_pool = -1
	_expect_error("negative action pool", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].position = Vector2i(10, 2)
	_expect_error("position outside map", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].position = Vector2i(1, 2)
	_expect_error("position outside spawn", BattleValidator.validate_setup(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].members[1].id = state.sides[0].squads[0].members[0].id
	_expect_error("duplicate entity ID", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	state.sides[0].squads[0].members[0].current_hp = state.sides[0].squads[0].members[0].max_hp + 1
	_expect_error("HP above maximum", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	state = _make_state(maps[0], balances[0], units)
	for member in state.sides[0].squads[0].members:
		member.current_hp = 0
	state.sides[0].squads[0].is_active = true
	state.active_squad_id = state.sides[0].squads[0].id
	_expect_error("dead squad active", BattleValidator.validate_state(state, maps[0], balances[0], units, terrains))
	if failures == 0:
		print("Validation tests passed")
	quit(0 if failures == 0 else 1)

func _make_state(map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef]) -> BattleState:
	var state := BattleState.new()
	state.map_id = map_def.id
	state.balance_id = balance.id
	state.rng_state = BattleRng.initial_state(state.seed)
	for side_index in 2:
		var side := SideState.new()
		side.id = &"blue" if side_index == 0 else &"red"
		for squad_index in 2:
			var squad := SquadState.new()
			squad.id = StringName("%s_squad_%d" % [side.id, squad_index])
			squad.side_id = side.id
			var unit := units[0] if squad_index == 0 else units[2]
			squad.unit_type_id = unit.id
			squad.position = (map_def.blue_spawn_cells if side_index == 0 else map_def.red_spawn_cells)[squad_index]
			for member_index in 3:
				var member := CombatantState.new()
				member.id = StringName("%s_member_%d" % [squad.id, member_index])
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

func _expect_empty(label: String, errors: PackedStringArray) -> void:
	if not errors.is_empty():
		push_error("%s should pass: %s" % [label, errors])
		failures += 1

func _expect_error(label: String, errors: PackedStringArray) -> void:
	if errors.is_empty():
		push_error("%s should fail" % label)
		failures += 1

func _expect_true(label: String, condition: bool) -> void:
	if not condition:
		push_error("%s should be true" % label)
		failures += 1
