class_name BattleReplay
extends RefCounted

static func run(record: BattleReplayRecord, map_def: BattleMapDef, balance: BattleBalanceDef, units: Array[UnitTypeDef], terrains: Array[TerrainDef]) -> Dictionary:
	if record == null or map_def == null or balance == null:
		return _error("replay, map and balance are required")
	if record.schema_version != 1 or record.replay_version != BattleReplayRecord.REPLAY_VERSION:
		return _error("unsupported schema or replay version")
	if record.rng_version != BattleRng.VERSION:
		return _error("unsupported RNG version")
	if record.map_id != map_def.id:
		return _error("replay map ID does not match")
	if record.balance_id != balance.id or record.balance_version != balance.version:
		return _error("replay balance ID or version does not match")
	if record.first_side_id != &"blue" and record.first_side_id != &"red":
		return _error("invalid initial side")
	var shape_error := _setup_shape_error(record.setup_sides)
	if not shape_error.is_empty():
		return _error("invalid replay setup: %s" % shape_error)
	var state := BattleStateCodec.initial_from_replay(record)
	var setup_errors := BattleValidator.validate_setup(state, map_def, balance, units, terrains)
	if not setup_errors.is_empty():
		return _error("invalid replay setup: %s" % setup_errors)
	for index in record.command_log.size():
		if state.outcome != &"ongoing":
			return _error("command %d occurs after battle outcome" % index)
		if state.active_squad_id.is_empty():
			var scheduled := BattleScheduler.next_activation(state, balance)
			if not scheduled["ok"]:
				return _error("scheduler failed before command %d: %s" % [index, scheduled["error"]])
			state = scheduled["state"]
			if state.outcome != &"ongoing":
				return _error("command %d occurs after round cap" % index)
		if not record.command_log[index] is Dictionary:
			return _error("invalid command %d: entry must be a dictionary" % index)
		var decoded := _decode_command(record.command_log[index])
		if not decoded["ok"]:
			return _error("invalid command %d: %s" % [index, decoded["error"]])
		var command: BattleCommand = decoded["command"]
		if command.squad_id != state.active_squad_id:
			return _error("command %d squad does not match scheduled activation %s" % [index, state.active_squad_id])
		var applied := BattleRules.apply_command(state, command, map_def, balance, units, terrains)
		if not applied["ok"]:
			return _error("illegal command %d: %s" % [index, applied["error"]])
		state = applied["state"]
	if not record.command_log.is_empty() and state.outcome == &"ongoing" and state.active_squad_id.is_empty() and BattleScheduler.pending_squad_ids(state).is_empty():
		var completed_round := BattleRules.finish_round(state, balance)
		if not completed_round["ok"]:
			return _error("could not finish recorded round: %s" % completed_round["error"])
		state = completed_round["state"]
	return {"ok": true, "state": state, "normalized": BattleStateCodec.normalized(state), "outcome": state.outcome, "error": ""}

static func _decode_command(entry: Dictionary) -> Dictionary:
	for key in ["kind", "squad_id", "path", "attacker_id", "target_squad_id", "target_member_id", "front_member_id"]:
		if not entry.has(key):
			return {"ok": false, "error": "missing %s" % key}
	for key in ["kind", "squad_id", "attacker_id", "target_squad_id", "target_member_id", "front_member_id"]:
		if not entry[key] is String and not entry[key] is StringName:
			return {"ok": false, "error": "%s must be text" % key}
	var command := BattleCommand.new()
	command.kind = StringName(entry["kind"])
	command.squad_id = StringName(entry["squad_id"])
	command.attacker_id = StringName(entry["attacker_id"])
	command.target_squad_id = StringName(entry["target_squad_id"])
	command.target_member_id = StringName(entry["target_member_id"])
	command.front_member_id = StringName(entry["front_member_id"])
	if not entry["path"] is Array:
		return {"ok": false, "error": "path must be an array"}
	for cell in entry["path"]:
		if not cell is Array or cell.size() != 2:
			return {"ok": false, "error": "path cell must be [x, y]"}
		for coordinate in cell:
			if (not coordinate is int and not coordinate is float) or int(coordinate) != coordinate:
				return {"ok": false, "error": "path coordinates must be integers"}
		command.path.append(Vector2i(int(cell[0]), int(cell[1])))
	return {"ok": true, "command": command}

static func _setup_shape_error(sides: Array[Dictionary]) -> String:
	for side in sides:
		if not side.has("id") or not side.has("squads") or not side["squads"] is Array:
			return "side needs ID and squads"
		for squad in side["squads"]:
			if not squad is Dictionary:
				return "squad must be a dictionary"
			for key in ["id", "side_id", "unit_type_id", "position", "front_member_id", "members"]:
				if not squad.has(key):
					return "squad missing %s" % key
			if not squad["position"] is Array or squad["position"].size() != 2 or not squad["members"] is Array:
				return "squad position or members are malformed"
			for member in squad["members"]:
				if not member is Dictionary:
					return "member must be a dictionary"
				for key in ["id", "squad_id", "unit_type_id", "max_hp", "current_hp", "is_commander"]:
					if not member.has(key):
						return "member missing %s" % key
	return ""

static func _error(message: String) -> Dictionary:
	return {"ok": false, "state": null, "error": message}
