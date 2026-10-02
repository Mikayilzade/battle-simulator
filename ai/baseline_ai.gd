class_name BaselineAi
extends RefCounted

static func choose_command(state: BattleState, legal: Array[BattleCommand], map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef], policy: AiPolicyDef) -> BattleCommand:
	if state == null or legal.is_empty() or policy == null:
		return null
	var squad := _squad(state, state.active_squad_id)
	if squad == null:
		return null
	var threatened := _threatened(state, squad, units)
	var best: BattleCommand = null
	var best_score := -1
	var best_key := ""
	for command in legal:
		var score := _score(state, squad, command, map_def, balance, units, terrains, policy, threatened)
		var key := _tie_key(command)
		if score > best_score or (score == best_score and (best == null or key < best_key)):
			best = command
			best_score = score
			best_key = key
	return best

static func _score(state: BattleState, squad: SquadState, command: BattleCommand, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef], policy: AiPolicyDef, threatened: bool) -> int:
	match command.kind:
		BattleCommand.ATTACK:
			var target_squad := _squad(state, command.target_squad_id)
			var target_id := target_squad.front_member_id if command.target_member_id.is_empty() else command.target_member_id
			var target := _member(target_squad, target_id)
			var applied := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
			if not applied["ok"]:
				return -1
			var after := _member(_squad(applied["state"], command.target_squad_id), target_id)
			var damage := target.current_hp - after.current_hp
			var bonus := policy.commander_damage_bonus if target.is_commander else 0
			return (policy.lethal_score if after.current_hp == 0 else policy.attack_score) + damage * policy.damage_weight + bonus
		BattleCommand.MOVE:
			var before := _nearest_distance(state, squad, squad.position)
			var destination: Vector2i = command.path.back()
			var after := _nearest_distance(state, squad, destination)
			var unit := _unit(units, squad.unit_type_id)
			if squad.action_pool > 1 and unit != null and after <= unit.attack_range:
				var applied := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
				if applied["ok"]:
					var next: BattleState = applied["state"]
					if _can_attack(next, _squad(next, squad.id), map_def, balance, units, terrains):
						return policy.enabling_move_score + before - after
			if after >= before:
				return -1
			var exposure := maxi(0, _threat_count(state, squad, units, destination) - _threat_count(state, squad, units, squad.position))
			return policy.progress_move_score + (before - after) * policy.move_progress_weight - exposure * policy.exposure_penalty
		BattleCommand.GUARD:
			return policy.guard_score if threatened else -1
		BattleCommand.SET_FRONT:
			if not threatened:
				return -1
			var current := _member(squad, squad.front_member_id)
			var replacement := _member(squad, command.front_member_id)
			var improvement := replacement.current_hp + _armor(units, replacement.unit_type_id) - current.current_hp - _armor(units, current.unit_type_id)
			return policy.set_front_score + improvement if improvement >= policy.front_improvement_threshold else -1
		BattleCommand.PASS:
			return 0
	return -1

static func _nearest_distance(state: BattleState, squad: SquadState, from_cell: Vector2i) -> int:
	var nearest := 9999
	for side in state.sides:
		if side.id == squad.side_id:
			continue
		for enemy in side.squads:
			if enemy.living_member_count() > 0:
				nearest = mini(nearest, absi(from_cell.x - enemy.position.x) + absi(from_cell.y - enemy.position.y))
	return nearest

static func _can_attack(state: BattleState, squad: SquadState, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> bool:
	for member in squad.members:
		if not member.is_living() or squad.attacked_member_ids.has(member.id):
			continue
		for side in state.sides:
			if side.id == squad.side_id:
				continue
			for enemy in side.squads:
				if enemy.living_member_count() > 0 and BattleRules.is_legal_command(state, BattleCommand.attack(squad.id, member.id, enemy.id), map_def, balance, units, terrains):
					return true
	return false

static func _threatened(state: BattleState, squad: SquadState, units: Array[UnitTypeDef]) -> bool:
	return _threat_count(state, squad, units, squad.position) > 0

static func _threat_count(state: BattleState, squad: SquadState, units: Array[UnitTypeDef], cell: Vector2i) -> int:
	var count := 0
	for side in state.sides:
		if side.id == squad.side_id:
			continue
		for enemy in side.squads:
			if enemy.living_member_count() == 0:
				continue
			var enemy_type := _unit(units, enemy.unit_type_id)
			if enemy_type != null:
				var distance := absi(cell.x - enemy.position.x) + absi(cell.y - enemy.position.y)
				if distance <= enemy_type.attack_range + enemy_type.movement:
					count += 1
	return count

static func _tie_key(command: BattleCommand) -> String:
	var destination: Vector2i = command.path.back() if not command.path.is_empty() else Vector2i(-1, -1)
	return "%s|%s|%s|%s|%04d|%04d|%s|%s" % [command.kind, command.target_squad_id, command.target_member_id, command.front_member_id, destination.y, destination.x, command.attacker_id, str(command.path)]

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

static func _armor(units: Array[UnitTypeDef], id: StringName) -> int:
	var unit := _unit(units, id)
	return unit.armor if unit != null else 0
