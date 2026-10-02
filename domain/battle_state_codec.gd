class_name BattleStateCodec
extends RefCounted

static func normalized(state: BattleState) -> Dictionary:
	var sides: Array[Dictionary] = []
	for side in state.sides:
		var squads: Array[Dictionary] = []
		for squad in side.squads:
			var members: Array[Dictionary] = []
			for member in squad.members:
				members.append({
					"id": str(member.id), "squad_id": str(member.squad_id), "unit_type_id": str(member.unit_type_id),
					"max_hp": member.max_hp, "current_hp": member.current_hp, "is_commander": member.is_commander
				})
			var attacked: Array[String] = []
			for id in squad.attacked_member_ids:
				attacked.append(str(id))
			squads.append({
				"id": str(squad.id), "side_id": str(squad.side_id), "unit_type_id": str(squad.unit_type_id),
				"position": [squad.position.x, squad.position.y], "members": members,
				"front_member_id": str(squad.front_member_id), "action_pool": squad.action_pool,
				"moved_this_activation": squad.moved_this_activation, "attacked_member_ids": attacked,
				"guarding": squad.guarding, "is_active": squad.is_active
			})
		sides.append({"id": str(side.id), "squads": squads})
	var activated: Array[String] = []
	for id in state.activated_squad_ids:
		activated.append(str(id))
	return {
		"schema_version": state.schema_version, "balance_id": str(state.balance_id), "map_id": str(state.map_id),
		"round": state.round, "activation_cursor": state.activation_cursor,
		"active_squad_id": str(state.active_squad_id), "activated_squad_ids": activated,
		"outcome": str(state.outcome), "seed": state.seed, "rng_state": state.rng_state,
		"first_side_id": str(state.first_side_id), "spawn_swapped": state.spawn_swapped, "sides": sides
	}

static func setup_sides(state: BattleState) -> Array[Dictionary]:
	var sides: Array[Dictionary] = normalized(state)["sides"]
	for side in sides:
		for squad in side["squads"]:
			squad.erase("action_pool")
			squad.erase("moved_this_activation")
			squad.erase("attacked_member_ids")
			squad.erase("guarding")
			squad.erase("is_active")
	return sides

static func initial_from_replay(record: BattleReplayRecord) -> BattleState:
	var state := BattleState.new()
	state.schema_version = record.schema_version
	state.balance_id = record.balance_id
	state.map_id = record.map_id
	state.seed = record.seed
	state.rng_state = BattleRng.initial_state(record.seed)
	state.first_side_id = record.first_side_id
	state.spawn_swapped = record.spawn_swapped
	for side_data in record.setup_sides:
		var side := SideState.new()
		side.id = StringName(side_data["id"])
		for squad_data in side_data["squads"]:
			var squad := SquadState.new()
			squad.id = StringName(squad_data["id"])
			squad.side_id = StringName(squad_data["side_id"])
			squad.unit_type_id = StringName(squad_data["unit_type_id"])
			var cell: Array = squad_data["position"]
			squad.position = Vector2i(int(cell[0]), int(cell[1]))
			squad.front_member_id = StringName(squad_data["front_member_id"])
			for member_data in squad_data["members"]:
				var member := CombatantState.new()
				member.id = StringName(member_data["id"])
				member.squad_id = StringName(member_data["squad_id"])
				member.unit_type_id = StringName(member_data["unit_type_id"])
				member.max_hp = int(member_data["max_hp"])
				member.current_hp = int(member_data["current_hp"])
				member.is_commander = bool(member_data["is_commander"])
				squad.members.append(member)
			side.squads.append(squad)
		state.sides.append(side)
	return state
