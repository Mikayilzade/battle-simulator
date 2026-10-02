class_name UiBattleData
extends RefCounted

const MAPS := {
	"open_field": "res://data/maps/open_field.tres",
	"broken_pass": "res://data/maps/broken_pass.tres"
}
const TYPES := ["guard", "striker", "archer"]

static func default_config() -> Dictionary:
	return {"map_id": "open_field", "blue": ["guard", "archer"], "red": ["guard", "archer"], "seed": 1, "first_side_id": "blue", "spawn_swapped": false}

static func map_for(config: Dictionary) -> BattleMapDef:
	return load(MAPS.get(config.get("map_id", "open_field"), MAPS["open_field"])) as BattleMapDef

static func balance() -> BattleBalanceDef:
	return load("res://data/balance/default.tres") as BattleBalanceDef

static func units() -> Array[UnitTypeDef]:
	var result: Array[UnitTypeDef] = []
	for id in TYPES:
		result.append(load("res://data/unit_types/%s.tres" % id) as UnitTypeDef)
	return result

static func terrains() -> Array[TerrainDef]:
	var result: Array[TerrainDef] = []
	for id in ["plain", "rough", "blocked"]:
		result.append(load("res://data/terrain/%s.tres" % id) as TerrainDef)
	return result

static func setup(config: Dictionary) -> BattleState:
	var blue := ForcePresetDef.new()
	blue.id = &"ui_blue"
	blue.squad_unit_type_ids = PackedStringArray(config["blue"])
	var red := ForcePresetDef.new()
	red.id = &"ui_red"
	red.squad_unit_type_ids = PackedStringArray(config["red"])
	return HeadlessBattle.create_setup(map_for(config), balance(), units(), blue, red, int(config["seed"]), StringName(config["first_side_id"]), bool(config["spawn_swapped"]))
