class_name BattleReplayRecord
extends RefCounted

const REPLAY_VERSION: int = 1

var schema_version: int = 1
var replay_version: int = REPLAY_VERSION
var rng_version: int = BattleRng.VERSION
var balance_id: StringName
var balance_version: StringName
var map_id: StringName
var seed: int
var first_side_id: StringName = &"blue"
var spawn_swapped: bool = false
var setup_sides: Array[Dictionary] = []
var command_log: Array[Dictionary] = []

static func from_initial_state(state: BattleState, balance: BattleBalanceDef) -> BattleReplayRecord:
	var record := BattleReplayRecord.new()
	record.schema_version = state.schema_version
	record.balance_id = balance.id
	record.balance_version = balance.version
	record.map_id = state.map_id
	record.seed = state.seed
	record.first_side_id = state.first_side_id
	record.spawn_swapped = state.spawn_swapped
	record.setup_sides = BattleStateCodec.setup_sides(state)
	return record

func append_command(command: BattleCommand) -> void:
	var path: Array[Array] = []
	for cell in command.path:
		path.append([cell.x, cell.y])
	command_log.append({
		"kind": str(command.kind), "squad_id": str(command.squad_id), "path": path,
		"attacker_id": str(command.attacker_id), "target_squad_id": str(command.target_squad_id),
		"target_member_id": str(command.target_member_id), "front_member_id": str(command.front_member_id)
	})

func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version, "replay_version": replay_version, "rng_version": rng_version,
		"balance_id": str(balance_id), "balance_version": str(balance_version), "map_id": str(map_id),
		"seed": seed, "first_side_id": str(first_side_id), "spawn_swapped": spawn_swapped,
		"setup_sides": setup_sides.duplicate(true), "command_log": command_log.duplicate(true)
	}

static func from_dict(data: Dictionary) -> BattleReplayRecord:
	var record := BattleReplayRecord.new()
	record.schema_version = int(data.get("schema_version", -1))
	record.replay_version = int(data.get("replay_version", -1))
	record.rng_version = int(data.get("rng_version", -1))
	record.balance_id = StringName(data.get("balance_id", ""))
	record.balance_version = StringName(data.get("balance_version", ""))
	record.map_id = StringName(data.get("map_id", ""))
	record.seed = int(data.get("seed", 0))
	record.first_side_id = StringName(data.get("first_side_id", ""))
	record.spawn_swapped = bool(data.get("spawn_swapped", false))
	record.setup_sides.assign(data.get("setup_sides", []))
	record.command_log.assign(data.get("command_log", []))
	return record
