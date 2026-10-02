class_name BattleRules
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

static func start_activation(state: BattleState, squad_id: StringName) -> Dictionary:
	if state == null or state.outcome != &"ongoing" or not state.active_squad_id.is_empty():
		return _error(state, "battle is finished or another squad is active")
	var squad := _find_squad(state, squad_id)
	if squad == null or squad.living_member_count() == 0:
		return _error(state, "squad does not exist or is dead")
	if state.activated_squad_ids.has(squad_id):
		return _error(state, "squad already activated this round")
	var next := _copy_state(state)
	var active := _find_squad(next, squad_id)
	active.is_active = true
	active.action_pool = active.living_member_count()
	active.moved_this_activation = false
	active.attacked_member_ids.clear()
	active.guarding = false
	next.active_squad_id = squad_id
	return _success(next, [{"type": &"activation_started", "squad_id": squad_id}])

static func finish_round(state: BattleState, balance: BattleBalanceDef) -> Dictionary:
	if state == null or balance == null or state.outcome != &"ongoing" or not state.active_squad_id.is_empty():
		return _error(state, "cannot finish round")
	for side in state.sides:
		for squad in side.squads:
			if squad.living_member_count() > 0 and not state.activated_squad_ids.has(squad.id):
				return _error(state, "living squad has not activated")
	var next := _copy_state(state)
	if next.round >= balance.round_cap:
		_set_outcome_by_score(next)
	else:
		next.round += 1
		next.activation_cursor = 0
		next.activated_squad_ids.clear()
	return _success(next, [{"type": &"round_finished", "round": state.round}])

static func legal_commands(state: BattleState, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> Array[BattleCommand]:
	var commands: Array[BattleCommand] = []
	if state == null or state.outcome != &"ongoing" or state.active_squad_id.is_empty():
		return commands
	var squad := _find_squad(state, state.active_squad_id)
	if squad == null or not squad.is_active:
		return commands
	commands.append(BattleCommand.pass_turn(squad.id))
	if squad.action_pool <= 0:
		return commands
	if not squad.moved_this_activation:
		var unit := _find_unit(units, squad.unit_type_id)
		if unit != null:
			var paths := _reachable_paths(state, squad, map_def, terrains, unit.movement)
			for y in map_def.height:
				for x in map_def.width:
					var cell := Vector2i(x, y)
					if paths.has(cell):
						commands.append(BattleCommand.move(squad.id, paths[cell]))
	for member in squad.members:
		if member == null or not member.is_living():
			continue
		if not squad.attacked_member_ids.has(member.id):
			for side in state.sides:
				if side.id == squad.side_id:
					continue
				for target in side.squads:
					if target.living_member_count() == 0:
						continue
					var front := BattleCommand.attack(squad.id, member.id, target.id)
					if _command_error(state, front, map_def, balance, units, terrains).is_empty():
						commands.append(front)
					var attacker_type := _find_unit(units, member.unit_type_id)
					if attacker_type != null and attacker_type.attack_range > 1:
						for rear in target.members:
							if rear != null and rear.is_living() and rear.id != target.front_member_id:
								var rear_command := BattleCommand.attack(squad.id, member.id, target.id, rear.id)
								if _command_error(state, rear_command, map_def, balance, units, terrains).is_empty():
									commands.append(rear_command)
		if member.id != squad.front_member_id:
			commands.append(BattleCommand.set_front(squad.id, member.id))
	if not squad.guarding:
		commands.append(BattleCommand.guard(squad.id))
	return commands

static func apply_command(state: BattleState, command: BattleCommand, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> Dictionary:
	var error := _command_error(state, command, map_def, balance, units, terrains)
	if not error.is_empty():
		return _error(state, error)
	var next := _copy_state(state)
	var squad := _find_squad(next, command.squad_id)
	var events: Array[Dictionary] = []
	match command.kind:
		BattleCommand.MOVE:
			squad.position = command.path.back()
			squad.moved_this_activation = true
			events.append({"type": &"moved", "squad_id": squad.id, "position": squad.position})
		BattleCommand.ATTACK:
			var attacker := _find_member(squad, command.attacker_id)
			var target_squad := _find_squad(next, command.target_squad_id)
			var target_id := target_squad.front_member_id if command.target_member_id.is_empty() else command.target_member_id
			var target := _find_member(target_squad, target_id)
			var power := (_find_unit(units, attacker.unit_type_id) as UnitTypeDef).power
			if attacker.is_commander:
				power += balance.commander_power_bonus
			if target_id != target_squad.front_member_id:
				power -= balance.rear_ranged_power_penalty
			var armor := (_find_unit(units, target.unit_type_id) as UnitTypeDef).armor
			var cover := (_find_terrain(terrains, map_def.terrain_id_at(target_squad.position)) as TerrainDef).cover
			var guard_armor := balance.guard_bonus_armor if target_squad.guarding else 0
			var damage := maxi(1, power - armor - cover - guard_armor)
			target.current_hp = maxi(0, target.current_hp - damage)
			squad.attacked_member_ids.append(attacker.id)
			events.append({"type": &"attacked", "attacker_id": attacker.id, "target_id": target.id, "damage": damage})
			if not target.is_living() and target.id == target_squad.front_member_id:
				target_squad.front_member_id = _next_living_member_id(target_squad, target.id)
			if target_squad.living_member_count() == 0:
				target_squad.guarding = false
		BattleCommand.GUARD:
			squad.guarding = true
			events.append({"type": &"guarded", "squad_id": squad.id})
		BattleCommand.SET_FRONT:
			squad.front_member_id = command.front_member_id
			events.append({"type": &"front_set", "member_id": command.front_member_id})
		BattleCommand.PASS:
			events.append({"type": &"passed", "squad_id": squad.id})
	if command.kind == BattleCommand.PASS:
		_end_activation(next, squad)
	else:
		squad.action_pool -= 1
		if squad.action_pool == 0:
			_end_activation(next, squad)
	_update_elimination(next)
	return _success(next, events)

static func _command_error(state: BattleState, command: BattleCommand, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> String:
	if state == null or command == null or map_def == null or balance == null:
		return "state, command, map and balance are required"
	if state.map_id != map_def.id or state.balance_id != balance.id:
		return "command definitions do not match battle state"
	if state.outcome != &"ongoing" or state.active_squad_id.is_empty() or command.squad_id != state.active_squad_id:
		return "command is not for the active squad"
	var squad := _find_squad(state, command.squad_id)
	if squad == null or not squad.is_active or squad.living_member_count() == 0:
		return "active squad is missing or dead"
	if command.kind == BattleCommand.PASS:
		return ""
	if squad.action_pool <= 0:
		return "no actions remain"
	match command.kind:
		BattleCommand.MOVE:
			if squad.moved_this_activation or command.path.is_empty():
				return "squad already moved or path is empty"
			var unit := _find_unit(units, squad.unit_type_id)
			if unit == null:
				return "unknown unit type"
			var cell := squad.position
			var cost := 0
			for step in command.path:
				if absi(step.x - cell.x) + absi(step.y - cell.y) != 1 or not map_def.contains(step):
					return "path must use in-bounds orthogonal steps"
				if _occupied(state, step):
					return "path crosses an occupied cell"
				var terrain := _find_terrain(terrains, map_def.terrain_id_at(step))
				if terrain == null or terrain.blocked:
					return "path crosses blocked or unknown terrain"
				cost += terrain.movement_cost
				if cost > unit.movement:
					return "path exceeds movement budget"
				cell = step
			return ""
		BattleCommand.ATTACK:
			var attacker := _find_member(squad, command.attacker_id)
			if attacker == null or not attacker.is_living() or squad.attacked_member_ids.has(command.attacker_id):
				return "attacker is absent, dead or has already attacked"
			var attacker_type := _find_unit(units, attacker.unit_type_id)
			var target_squad := _find_squad(state, command.target_squad_id)
			if attacker_type == null or target_squad == null or target_squad.side_id == squad.side_id or target_squad.living_member_count() == 0:
				return "invalid enemy target"
			var distance := absi(target_squad.position.x - squad.position.x) + absi(target_squad.position.y - squad.position.y)
			if distance < 1 or distance > attacker_type.attack_range:
				return "target is out of range"
			if attacker_type.attack_range > 1 and not _clear_line(squad.position, target_squad.position, map_def, terrains):
				return "line of sight is blocked"
			var target_id := target_squad.front_member_id if command.target_member_id.is_empty() else command.target_member_id
			var target := _find_member(target_squad, target_id)
			if target == null or not target.is_living():
				return "target member is absent or dead"
			if attacker_type.attack_range == 1 and target_id != target_squad.front_member_id:
				return "melee must target the front member"
			return ""
		BattleCommand.GUARD:
			return "guard does not stack" if squad.guarding else ""
		BattleCommand.SET_FRONT:
			var member := _find_member(squad, command.front_member_id)
			if member == null or not member.is_living() or member.id == squad.front_member_id:
				return "front target must be another living squad member"
			return ""
		_:
			return "unknown command kind"

static func _reachable_paths(state: BattleState, squad: SquadState, map_def: BattleMapDef, terrains: Array[TerrainDef], budget: int) -> Dictionary:
	var distance := {squad.position: 0}
	var paths := {}
	var frontier: Array[Vector2i] = [squad.position]
	while not frontier.is_empty():
		var best_index := 0
		for index in range(1, frontier.size()):
			var candidate := frontier[index]
			var best := frontier[best_index]
			if distance[candidate] < distance[best] or (distance[candidate] == distance[best] and (candidate.y < best.y or (candidate.y == best.y and candidate.x < best.x))):
				best_index = index
		var cell := frontier[best_index]
		frontier.remove_at(best_index)
		for direction in DIRECTIONS:
			var step := cell + direction
			if not map_def.contains(step) or _occupied(state, step):
				continue
			var terrain := _find_terrain(terrains, map_def.terrain_id_at(step))
			if terrain == null or terrain.blocked:
				continue
			var cost: int = distance[cell] + terrain.movement_cost
			if cost > budget or (distance.has(step) and distance[step] <= cost):
				continue
			distance[step] = cost
			var path: Array[Vector2i] = []
			if cell != squad.position:
				path.assign(paths[cell])
			path.append(step)
			paths[step] = path
			if not frontier.has(step):
				frontier.append(step)
	return paths

static func _clear_line(start: Vector2i, finish: Vector2i, map_def: BattleMapDef, terrains: Array[TerrainDef]) -> bool:
	var dx := absi(finish.x - start.x)
	var dy := absi(finish.y - start.y)
	var sx := signi(finish.x - start.x)
	var sy := signi(finish.y - start.y)
	var x := start.x
	var y := start.y
	var ix := 0
	var iy := 0
	while ix < dx or iy < dy:
		var horizontal := (1 + 2 * ix) * dy
		var vertical := (1 + 2 * iy) * dx
		if horizontal == vertical:
			if _blocks_sight(Vector2i(x + sx, y), map_def, terrains) or _blocks_sight(Vector2i(x, y + sy), map_def, terrains):
				return false
			x += sx
			y += sy
			ix += 1
			iy += 1
		elif horizontal < vertical:
			x += sx
			ix += 1
		else:
			y += sy
			iy += 1
		if Vector2i(x, y) != finish and _blocks_sight(Vector2i(x, y), map_def, terrains):
			return false
	return true

static func _blocks_sight(cell: Vector2i, map_def: BattleMapDef, terrains: Array[TerrainDef]) -> bool:
	if not map_def.contains(cell):
		return true
	var terrain := _find_terrain(terrains, map_def.terrain_id_at(cell))
	return terrain == null or terrain.blocked

static func _end_activation(state: BattleState, squad: SquadState) -> void:
	squad.is_active = false
	squad.action_pool = 0
	state.active_squad_id = &""
	state.activated_squad_ids.append(squad.id)
	state.activation_cursor += 1

static func _update_elimination(state: BattleState) -> void:
	var blue := 0
	var red := 0
	for side in state.sides:
		for squad in side.squads:
			if side.id == &"blue":
				blue += squad.living_member_count()
			elif side.id == &"red":
				red += squad.living_member_count()
	if blue == 0 or red == 0:
		state.outcome = &"draw" if blue == red else (&"red" if blue == 0 else &"blue")
		if not state.active_squad_id.is_empty():
			var active := _find_squad(state, state.active_squad_id)
			active.is_active = false
			active.action_pool = 0
			state.active_squad_id = &""

static func _set_outcome_by_score(state: BattleState) -> void:
	var counts := {}
	var hp := {}
	for side in state.sides:
		counts[side.id] = 0
		hp[side.id] = 0
		for squad in side.squads:
			for member in squad.members:
				if member.is_living():
					counts[side.id] += 1
					hp[side.id] += member.current_hp
	if counts[&"blue"] == counts[&"red"] and hp[&"blue"] == hp[&"red"]:
		state.outcome = &"draw"
	else:
		state.outcome = &"blue" if counts[&"blue"] > counts[&"red"] or (counts[&"blue"] == counts[&"red"] and hp[&"blue"] > hp[&"red"]) else &"red"

static func _next_living_member_id(squad: SquadState, former_front_id: StringName) -> StringName:
	var front_index := 0
	for index in squad.members.size():
		if squad.members[index].id == former_front_id:
			front_index = index
			break
	for offset in range(1, squad.members.size() + 1):
		var member := squad.members[(front_index + offset) % squad.members.size()]
		if member.is_living():
			return member.id
	return &""

static func _occupied(state: BattleState, cell: Vector2i) -> bool:
	for side in state.sides:
		for squad in side.squads:
			if squad.living_member_count() > 0 and squad.position == cell:
				return true
	return false

static func _find_squad(state: BattleState, id: StringName) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == id:
				return squad
	return null

static func _find_member(squad: SquadState, id: StringName) -> CombatantState:
	for member in squad.members:
		if member.id == id:
			return member
	return null

static func _find_unit(units: Array[UnitTypeDef], id: StringName) -> UnitTypeDef:
	for unit in units:
		if unit.id == id:
			return unit
	return null

static func _find_terrain(terrains: Array[TerrainDef], id: StringName) -> TerrainDef:
	for terrain in terrains:
		if terrain.id == id:
			return terrain
	return null

static func _copy_state(state: BattleState) -> BattleState:
	var next := BattleState.new()
	next.schema_version = state.schema_version
	next.balance_id = state.balance_id
	next.map_id = state.map_id
	next.round = state.round
	next.activation_cursor = state.activation_cursor
	next.active_squad_id = state.active_squad_id
	next.activated_squad_ids = state.activated_squad_ids.duplicate()
	next.outcome = state.outcome
	next.seed = state.seed
	for side in state.sides:
		var side_copy := SideState.new()
		side_copy.id = side.id
		for squad in side.squads:
			var squad_copy := SquadState.new()
			squad_copy.id = squad.id
			squad_copy.side_id = squad.side_id
			squad_copy.unit_type_id = squad.unit_type_id
			squad_copy.position = squad.position
			squad_copy.front_member_id = squad.front_member_id
			squad_copy.action_pool = squad.action_pool
			squad_copy.moved_this_activation = squad.moved_this_activation
			squad_copy.attacked_member_ids = squad.attacked_member_ids.duplicate()
			squad_copy.guarding = squad.guarding
			squad_copy.is_active = squad.is_active
			for member in squad.members:
				var member_copy := CombatantState.new()
				member_copy.id = member.id
				member_copy.squad_id = member.squad_id
				member_copy.unit_type_id = member.unit_type_id
				member_copy.max_hp = member.max_hp
				member_copy.current_hp = member.current_hp
				member_copy.is_commander = member.is_commander
				squad_copy.members.append(member_copy)
			side_copy.squads.append(squad_copy)
		next.sides.append(side_copy)
	return next

static func _success(state: BattleState, events: Array[Dictionary]) -> Dictionary:
	return {"ok": true, "state": state, "error": "", "events": events}

static func _error(state: BattleState, message: String) -> Dictionary:
	return {"ok": false, "state": state, "error": message, "events": []}
