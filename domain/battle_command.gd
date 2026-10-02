class_name BattleCommand
extends RefCounted

const MOVE: StringName = &"MOVE"
const ATTACK: StringName = &"ATTACK"
const GUARD: StringName = &"GUARD"
const SET_FRONT: StringName = &"SET_FRONT"
const PASS: StringName = &"PASS"

var kind: StringName
var squad_id: StringName
var path: Array[Vector2i] = []
var attacker_id: StringName
var target_squad_id: StringName
var target_member_id: StringName
var front_member_id: StringName

static func move(squad: StringName, cells: Array[Vector2i]) -> BattleCommand:
	var command := BattleCommand.new()
	command.kind = MOVE
	command.squad_id = squad
	command.path = cells.duplicate()
	return command

static func attack(squad: StringName, attacker: StringName, target_squad: StringName, target_member: StringName = &"") -> BattleCommand:
	var command := BattleCommand.new()
	command.kind = ATTACK
	command.squad_id = squad
	command.attacker_id = attacker
	command.target_squad_id = target_squad
	command.target_member_id = target_member
	return command

static func guard(squad: StringName) -> BattleCommand:
	var command := BattleCommand.new()
	command.kind = GUARD
	command.squad_id = squad
	return command

static func set_front(squad: StringName, member: StringName) -> BattleCommand:
	var command := BattleCommand.new()
	command.kind = SET_FRONT
	command.squad_id = squad
	command.front_member_id = member
	return command

static func pass_turn(squad: StringName) -> BattleCommand:
	var command := BattleCommand.new()
	command.kind = PASS
	command.squad_id = squad
	return command
