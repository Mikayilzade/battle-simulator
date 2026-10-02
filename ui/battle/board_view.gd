class_name BattleBoardView
extends Control

signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

const TILE_W := 96.0
const TILE_H := 54.0

var map_def: BattleMapDef
var state: BattleState
var legal: Array[BattleCommand] = []
var mode := "MOVE"
var hover := Vector2i(-1, -1)
var selected_target: StringName = &""
var interactive := true

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(900, 520)
	mouse_filter = MOUSE_FILTER_STOP if interactive else MOUSE_FILTER_IGNORE

func set_model(value_map: BattleMapDef, value_state: BattleState, value_legal: Array[BattleCommand], value_mode: String, target: StringName) -> void:
	map_def = value_map
	state = value_state
	legal = value_legal
	mode = value_mode
	selected_target = target
	queue_redraw()

func _projection_scale() -> float:
	if map_def == null:
		return 1.0
	var world_width := float(map_def.width + map_def.height) * TILE_W * 0.5
	var world_height := float(map_def.width + map_def.height) * TILE_H * 0.5 + 46.0
	return minf((size.x - 34.0) / world_width, (size.y - 22.0) / world_height)

func _projection_offset() -> Vector2:
	var scale := _projection_scale()
	var center_x := float(map_def.width - map_def.height) * TILE_W * 0.25
	var center_y := float(map_def.width + map_def.height - 2) * TILE_H * 0.25
	return size * 0.5 - Vector2(center_x, center_y - 9.0) * scale

func _center(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x - cell.y) * TILE_W * 0.5, float(cell.x + cell.y) * TILE_H * 0.5)

func _cell_at(point: Vector2) -> Vector2i:
	var world := (point - _projection_offset()) / _projection_scale()
	var found := Vector2i(-1, -1)
	for y in map_def.height:
		for x in map_def.width:
			var cell := Vector2i(x, y)
			var delta := world - _center(cell)
			if absf(delta.x) / (TILE_W * 0.5) + absf(delta.y) / (TILE_H * 0.5) <= 1.0:
				found = cell
	return found

func _gui_input(event: InputEvent) -> void:
	if not interactive or map_def == null:
		return
	if event is InputEventMouseMotion:
		var cell := _cell_at(event.position)
		if cell != hover:
			hover = cell
			cell_hovered.emit(cell)
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _cell_at(event.position)
		if map_def.contains(cell):
			cell_clicked.emit(cell)

func _draw() -> void:
	if map_def == null or state == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#20372f"))
	draw_set_transform(_projection_offset(), 0.0, Vector2.ONE * _projection_scale())
	var moves := {}
	var targets := {}
	for command in legal:
		if command.kind == BattleCommand.MOVE:
			moves[command.path.back()] = command
		elif command.kind == BattleCommand.ATTACK:
			targets[command.target_squad_id] = true
	for depth in map_def.width + map_def.height - 1:
		for y in map_def.height:
			var x := depth - y
			if x < 0 or x >= map_def.width:
				continue
			var cell := Vector2i(x, y)
			_draw_tile(cell)
			if state.round == 1 and state.activation_cursor == 0:
				_draw_spawn_wash(cell)
			if mode == "MOVE" and moves.has(cell):
				_draw_overlay(cell, Color(0.55, 0.91, 0.56, 0.28), Color("#a9e8a8"))
			if hover == cell:
				_draw_overlay(cell, Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.68))
	var hovered_move: BattleCommand = moves.get(hover) if mode == "MOVE" else null
	if hovered_move != null:
		_draw_route(hovered_move)
	for depth in map_def.width + map_def.height - 1:
		for y in map_def.height:
			var x := depth - y
			if x < 0 or x >= map_def.width:
				continue
			var squad := _squad_at(Vector2i(x, y))
			if squad == null:
				continue
			var center := _center(squad.position)
			if squad.id == state.active_squad_id:
				_draw_ground_ring(center, Color("#f8d98a"))
			if mode == "ATTACK" and targets.has(squad.id):
				_draw_ground_ring(center, Color("#f08b72"))
			if squad.id == selected_target:
				_draw_ground_ring(center, Color.WHITE)
			SquadMarker.draw(self, center + Vector2(0, 6), squad, squad.id == state.active_squad_id)
	draw_set_transform(Vector2.ZERO)

func _corners(cell: Vector2i) -> PackedVector2Array:
	var center := _center(cell)
	return PackedVector2Array([center + Vector2(0, -TILE_H * 0.5), center + Vector2(TILE_W * 0.5, 0), center + Vector2(0, TILE_H * 0.5), center + Vector2(-TILE_W * 0.5, 0)])

func _draw_tile(cell: Vector2i) -> void:
	var corners := _corners(cell)
	var terrain := map_def.terrain_id_at(cell)
	var variation := float((cell.x * 7 + cell.y * 11) % 5) * 0.012
	var top := Color("#668b62").lightened(variation)
	if terrain == &"rough":
		top = Color("#8e845b").lightened(variation)
	elif terrain == &"blocked":
		top = Color("#64716b").lightened(variation)
	var depth := 10.0 if terrain == &"rough" else 7.0
	draw_colored_polygon(PackedVector2Array([corners[3], corners[2], corners[2] + Vector2(0, depth), corners[3] + Vector2(0, depth)]), top.darkened(0.34))
	draw_colored_polygon(PackedVector2Array([corners[2], corners[1], corners[1] + Vector2(0, depth), corners[2] + Vector2(0, depth)]), top.darkened(0.46))
	draw_colored_polygon(corners, top)
	draw_line(corners[3], corners[2], top.darkened(0.14), 1)
	draw_line(corners[2], corners[1], top.darkened(0.2), 1)
	var center := _center(cell)
	if terrain == &"plain":
		for tuft in 4:
			var dx := float((cell.x * 13 + cell.y * 19 + tuft * 17) % 48) - 24.0
			var dy := float((cell.x * 7 + cell.y * 5 + tuft * 9) % 16) - 8.0
			var at := center + Vector2(dx, dy)
			draw_line(at, at + Vector2(-2, -5), Color("#89ab72", 0.7), 1.5)
			draw_line(at, at + Vector2(2, -4), Color("#abc18a", 0.55), 1.5)
	elif terrain == &"rough":
		for rock in 3:
			var at := center + Vector2(float(rock - 1) * 17.0, float((rock * 7) % 9) - 2.0)
			_draw_rock(at, 12.0 + float(rock % 2) * 4.0, Color("#aa9a70"))
	else:
		_draw_rock(center + Vector2(-14, 6), 29, Color("#7b8780"))
		_draw_rock(center + Vector2(16, 3), 25, Color("#65716d"))

func _draw_rock(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, 5), center + Vector2(-radius * 0.5, -radius * 0.55), center + Vector2(radius * 0.22, -radius), center + Vector2(radius, -radius * 0.12), center + Vector2(radius * 0.8, 7)]), color.darkened(0.28))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, 5), center + Vector2(-radius * 0.5, -radius * 0.55), center + Vector2(radius * 0.22, -radius), center + Vector2(radius * 0.12, 3)]), color)

func _draw_overlay(cell: Vector2i, wash: Color, edge: Color) -> void:
	var corners := _corners(cell)
	draw_colored_polygon(corners, wash)
	if edge.a > 0.0:
		draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]]), edge, 2.0, true)

func _draw_spawn_wash(cell: Vector2i) -> void:
	if not map_def.blue_spawn_cells.has(cell) and not map_def.red_spawn_cells.has(cell):
		return
	var blue_side := map_def.blue_spawn_cells.has(cell) != state.spawn_swapped
	_draw_overlay(cell, Color(0.25, 0.57, 0.9, 0.12) if blue_side else Color(0.93, 0.36, 0.3, 0.12), Color.TRANSPARENT)

func _draw_ground_ring(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 25:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * 34.0, sin(angle) * 13.0 + 12.0))
	draw_polyline(points, color, 3.5, true)

func _draw_route(command: BattleCommand) -> void:
	var squad := _active_squad()
	if squad == null:
		return
	var points := PackedVector2Array([_center(squad.position) + Vector2(0, 8)])
	for cell in command.path:
		points.append(_center(cell) + Vector2(0, 8))
	if points.size() < 2:
		return
	draw_polyline(points, Color("#fff0b1"), 4, true)
	var direction := (points[points.size() - 1] - points[points.size() - 2]).normalized()
	var tip := points[points.size() - 1]
	draw_colored_polygon(PackedVector2Array([tip + direction * 9, tip - direction * 4 + direction.orthogonal() * 5, tip - direction * 4 - direction.orthogonal() * 5]), Color("#fff0b1"))

func _active_squad() -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.id == state.active_squad_id:
				return squad
	return null

func _squad_at(cell: Vector2i) -> SquadState:
	for side in state.sides:
		for squad in side.squads:
			if squad.position == cell and squad.living_member_count() > 0:
				return squad
	return null
