class_name BattleValidator
extends RefCounted

static func validate_definitions(unit_types: Array[UnitTypeDef], terrains: Array[TerrainDef], maps: Array[BattleMapDef], balances: Array[BattleBalanceDef], presets: Array[ForcePresetDef]) -> PackedStringArray:
	var errors := PackedStringArray()
	var unit_ids := {}
	var terrain_ids := {}
	var balance_ids := {}
	_check_catalog(unit_types, unit_ids, "unit type", errors)
	_check_catalog(terrains, terrain_ids, "terrain", errors)
	_check_catalog(maps, {}, "map", errors)
	_check_catalog(balances, balance_ids, "balance", errors)
	_check_catalog(presets, {}, "force preset", errors)
	for map_def in maps:
		if map_def == null:
			continue
		if map_def.width <= 0 or map_def.height <= 0:
			errors.append("map %s has invalid dimensions" % map_def.id)
		if not terrain_ids.has(map_def.default_terrain_id):
			errors.append("map %s has unknown default terrain %s" % [map_def.id, map_def.default_terrain_id])
		if map_def.terrain_cells.size() != map_def.terrain_cell_ids.size():
			errors.append("map %s terrain cell/id counts differ" % map_def.id)
		var overrides := {}
		for index in map_def.terrain_cells.size():
			var cell := map_def.terrain_cells[index]
			if not map_def.contains(cell):
				errors.append("map %s terrain cell outside bounds: %s" % [map_def.id, cell])
			if overrides.has(cell):
				errors.append("map %s duplicates terrain cell %s" % [map_def.id, cell])
			overrides[cell] = true
			if index < map_def.terrain_cell_ids.size() and not terrain_ids.has(StringName(map_def.terrain_cell_ids[index])):
				errors.append("map %s has unknown terrain %s" % [map_def.id, map_def.terrain_cell_ids[index]])
		var spawn_cells := {}
		for cell in map_def.blue_spawn_cells + map_def.red_spawn_cells:
			if not map_def.contains(cell):
				errors.append("map %s spawn outside bounds: %s" % [map_def.id, cell])
			if spawn_cells.has(cell):
				errors.append("map %s duplicates spawn cell %s" % [map_def.id, cell])
			spawn_cells[cell] = true
			var terrain_id := map_def.terrain_id_at(cell)
			if terrain_ids.has(terrain_id) and (terrain_ids[terrain_id] as TerrainDef).blocked:
				errors.append("map %s spawn on blocked terrain: %s" % [map_def.id, cell])
		if map_def.blue_spawn_cells.is_empty() or map_def.red_spawn_cells.is_empty():
			errors.append("map %s needs spawn cells for both sides" % map_def.id)
	for preset in presets:
		if preset == null:
			continue
		for type_id in preset.squad_unit_type_ids:
			if not unit_ids.has(StringName(type_id)):
				errors.append("preset %s references unknown unit type %s" % [preset.id, type_id])
		for balance in balances:
			if balance != null and preset.squad_unit_type_ids.size() != balance.squads_per_side:
				errors.append("preset %s squad count differs from balance %s" % [preset.id, balance.id])
	for map_def in maps:
		if map_def == null:
			continue
		for balance in balances:
			if balance != null and (map_def.blue_spawn_cells.size() < balance.squads_per_side or map_def.red_spawn_cells.size() < balance.squads_per_side):
				errors.append("map %s lacks spawn cells for balance %s" % [map_def.id, balance.id])
	return errors

static func validate_setup(state: BattleState, map_def: BattleMapDef, balance: BattleBalanceDef, unit_types: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> PackedStringArray:
	var errors := validate_state(state, map_def, balance, unit_types, terrains)
	if state == null or map_def == null:
		return errors
	if state.round != 1 or state.activation_cursor != 0 or not state.active_squad_id.is_empty() or not state.activated_squad_ids.is_empty() or state.outcome != &"ongoing":
		errors.append("setup must start before the first activation")
	if state.rng_state != BattleRng.initial_state(state.seed):
		errors.append("setup RNG state does not match seed")
	for side in state.sides:
		if side == null:
			continue
		var allowed: Array[Vector2i]
		if side.id == &"blue":
			allowed = map_def.blue_spawn_cells
		elif side.id == &"red":
			allowed = map_def.red_spawn_cells
		else:
			errors.append("setup has unknown side %s" % side.id)
			continue
		for squad in side.squads:
			if squad == null:
				continue
			if not allowed.has(squad.position):
				errors.append("squad %s is not on a legal spawn cell" % squad.id)
			if squad.action_pool != 0 or squad.is_active or squad.moved_this_activation or not squad.attacked_member_ids.is_empty() or squad.guarding:
				errors.append("squad %s has battle progress in setup" % squad.id)
	return errors

static func validate_state(state: BattleState, map_def: BattleMapDef, balance: BattleBalanceDef, unit_types: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> PackedStringArray:
	var errors := PackedStringArray()
	if state == null or map_def == null or balance == null:
		errors.append("state, map and balance are required")
		return errors
	if state.schema_version != 1 or state.round < 1 or state.activation_cursor < 0:
		errors.append("invalid schema version, round or activation cursor")
	if state.first_side_id != &"blue" and state.first_side_id != &"red":
		errors.append("invalid initial side ID")
	if state.rng_state < 0 or state.rng_state > 0xffffffff:
		errors.append("RNG state must fit unsigned 32 bits")
	var activated := {}
	for squad_id in state.activated_squad_ids:
		if squad_id.is_empty() or activated.has(squad_id):
			errors.append("invalid activated squad ID %s" % squad_id)
		activated[squad_id] = true
	if state.map_id != map_def.id or state.balance_id != balance.id:
		errors.append("state map or balance ID does not match selected definitions")
	if state.outcome != &"ongoing" and state.outcome != &"blue" and state.outcome != &"red" and state.outcome != &"draw":
		errors.append("unknown battle outcome")
	if state.sides.size() != 2:
		errors.append("battle requires two sides")
	var unit_ids := {}
	var terrain_ids := {}
	for unit in unit_types:
		if unit != null:
			unit_ids[unit.id] = unit
	for terrain in terrains:
		if terrain != null:
			terrain_ids[terrain.id] = terrain
	var entity_ids := {}
	var squad_ids := {}
	var occupied := {}
	var active_count := 0
	for side in state.sides:
		if side == null:
			errors.append("null side")
			continue
		_check_entity_id(side.id, entity_ids, "side", errors)
		if side.id != &"blue" and side.id != &"red":
			errors.append("unknown side ID %s" % side.id)
		if side.squads.size() != balance.squads_per_side:
			errors.append("side %s has wrong squad count" % side.id)
		for squad in side.squads:
			if squad == null:
				errors.append("null squad")
				continue
			_check_entity_id(squad.id, entity_ids, "squad", errors)
			squad_ids[squad.id] = true
			if squad.side_id != side.id:
				errors.append("squad %s has wrong side ID" % squad.id)
			if not unit_ids.has(squad.unit_type_id):
				errors.append("squad %s has unknown unit type" % squad.id)
			if not map_def.contains(squad.position):
				errors.append("squad %s is outside map" % squad.id)
			else:
				var terrain_id := map_def.terrain_id_at(squad.position)
				if not terrain_ids.has(terrain_id) or (terrain_ids[terrain_id] as TerrainDef).blocked:
					errors.append("squad %s occupies blocked or unknown terrain" % squad.id)
			if occupied.has(squad.position):
				errors.append("squads overlap at %s" % squad.position)
			occupied[squad.position] = true
			if squad.members.size() != balance.members_per_squad:
				errors.append("squad %s has wrong member count" % squad.id)
			var member_ids := {}
			var commanders := 0
			for member in squad.members:
				if member == null:
					errors.append("null combatant")
					continue
				_check_entity_id(member.id, entity_ids, "combatant", errors)
				member_ids[member.id] = member
				if member.squad_id != squad.id or member.unit_type_id != squad.unit_type_id:
					errors.append("combatant %s has wrong squad or unit type" % member.id)
				if member.is_commander:
					commanders += 1
				if unit_ids.has(member.unit_type_id):
					var unit: UnitTypeDef = unit_ids[member.unit_type_id]
					var expected_hp := unit.max_hp + (balance.commander_max_hp_bonus if member.is_commander else 0)
					if member.max_hp != expected_hp:
						errors.append("combatant %s has wrong max HP" % member.id)
				if member.max_hp <= 0 or member.current_hp < 0 or member.current_hp > member.max_hp:
					errors.append("combatant %s has invalid current HP" % member.id)
			if commanders != 1:
				errors.append("squad %s needs exactly one commander" % squad.id)
			if squad.living_member_count() > 0:
				if not member_ids.has(squad.front_member_id) or not (member_ids[squad.front_member_id] as CombatantState).is_living():
					errors.append("living squad %s needs a living front member" % squad.id)
			elif squad.is_active or squad.action_pool > 0:
				errors.append("dead squad %s cannot be active or have actions" % squad.id)
			if squad.action_pool < 0:
				errors.append("squad %s has negative action pool" % squad.id)
			if squad.is_active:
				active_count += 1
				if state.active_squad_id != squad.id or squad.living_member_count() == 0:
					errors.append("active squad ID or living state invalid")
			var attacked := {}
			for member_id in squad.attacked_member_ids:
				if attacked.has(member_id) or not member_ids.has(member_id):
					errors.append("squad %s has invalid attacked member ID" % squad.id)
				attacked[member_id] = true
	if active_count > 1 or (active_count == 0 and not state.active_squad_id.is_empty()) or (active_count == 1 and state.active_squad_id.is_empty()):
		errors.append("active squad cursor is inconsistent")
	for squad_id in state.activated_squad_ids:
		if not squad_ids.has(squad_id):
			errors.append("activated squad ID %s is unknown" % squad_id)
	if not state.active_squad_id.is_empty() and activated.has(state.active_squad_id):
		errors.append("active squad has already activated this round")
	return errors

static func _check_catalog(items: Array, ids: Dictionary, label: String, errors: PackedStringArray) -> void:
	for item in items:
		if item == null:
			errors.append("null %s definition" % label)
			continue
		for error in item.validation_errors():
			errors.append("%s %s: %s" % [label, item.id, error])
		if not item.id.is_empty():
			if ids.has(item.id):
				errors.append("duplicate %s id %s" % [label, item.id])
			ids[item.id] = item

static func _check_entity_id(id: StringName, ids: Dictionary, label: String, errors: PackedStringArray) -> void:
	if id.is_empty():
		errors.append("%s id must not be empty" % label)
	elif ids.has(id):
		errors.append("duplicate entity id %s" % id)
	else:
		ids[id] = true
