class_name BattleMapDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var width: int = 9
@export var height: int = 7
@export var default_terrain_id: StringName
@export var terrain_cells: Array[Vector2i] = []
@export var terrain_cell_ids: PackedStringArray = PackedStringArray()
@export var blue_spawn_cells: Array[Vector2i] = []
@export var red_spawn_cells: Array[Vector2i] = []

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("map id must not be empty")
	if width <= 0 or height <= 0:
		errors.append("map dimensions must be greater than 0")
	return errors

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func terrain_id_at(cell: Vector2i) -> StringName:
	var index := terrain_cells.find(cell)
	if index >= 0 and index < terrain_cell_ids.size():
		return StringName(terrain_cell_ids[index])
	return default_terrain_id
