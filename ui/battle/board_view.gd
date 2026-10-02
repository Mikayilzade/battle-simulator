class_name BattleBoardView
extends Control

signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

const CELL := 70.0
const ORIGIN := Vector2(28, 24)

var map_def: BattleMapDef
var state: BattleState
var legal: Array[BattleCommand] = []
var mode := "MOVE"
var hover := Vector2i(-1, -1)
var selected_target: StringName = &""

func _ready() -> void:
	custom_minimum_size = Vector2(686, 544)
	mouse_filter = MOUSE_FILTER_STOP

func set_model(value_map: BattleMapDef, value_state: BattleState, value_legal: Array[BattleCommand], value_mode: String, target: StringName) -> void:
	map_def = value_map
	state = value_state
	legal = value_legal
	mode = value_mode
	selected_target = target
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _cell_at(event.position)
		if cell != hover:
			hover = cell
			cell_hovered.emit(cell)
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _cell_at(event.position)
		if map_def != null and map_def.contains(cell):
			cell_clicked.emit(cell)

func _cell_at(point: Vector2) -> Vector2i:
	var relative := point - ORIGIN
	return Vector2i(floori(relative.x / CELL), floori(relative.y / CELL))

func _draw() -> void:
	if map_def == null or state == null:
		return
	var font := ThemeDB.fallback_font
	var moves := {}
	var targets := {}
	for command in legal:
		if command.kind == BattleCommand.MOVE:
			moves[command.path.back()] = command
		elif command.kind == BattleCommand.ATTACK:
			targets[command.target_squad_id] = true
	var hovered_move: BattleCommand = moves.get(hover) if mode == "MOVE" else null
	for y in map_def.height:
		for x in map_def.width:
			var cell := Vector2i(x, y)
			var pos := ORIGIN + Vector2(x, y) * CELL
			var rect := Rect2(pos, Vector2(CELL - 2, CELL - 2))
			var terrain := map_def.terrain_id_at(cell)
			var base := Color("#587a52") if (x + y) % 2 == 0 else Color("#52734d")
			if terrain == &"rough":
				base = Color("#876f4f")
			elif terrain == &"blocked":
				base = Color("#51545a")
			draw_rect(rect, base)
			draw_rect(rect, Color("#263d35"), false, 1.5)
			if terrain == &"plain":
				for dot in 3:
					var px := 12.0 + float((x * 11 + y * 7 + dot * 19) % 46)
					var py := 10.0 + float((x * 5 + y * 17 + dot * 13) % 45)
					draw_line(pos + Vector2(px, py), pos + Vector2(px + 3, py - 6), Color("#78a16a", 0.55), 2)
			elif terrain == &"rough":
				for ridge in 2:
					var start := pos + Vector2(10 + ridge * 22, 45 - ridge * 12)
					draw_polyline(PackedVector2Array([start, start + Vector2(9, -14), start + Vector2(18, 0)]), Color("#c5a879", 0.85), 2)
			else:
				draw_colored_polygon(PackedVector2Array([pos + Vector2(9, 51), pos + Vector2(22, 16), pos + Vector2(42, 12), pos + Vector2(59, 48)]), Color("#767b80"))
				draw_line(pos + Vector2(23, 17), pos + Vector2(31, 42), Color("#45494d"), 2)
			if x == 0 or x == map_def.width - 1:
				var blue_column := (x == 0) != state.spawn_swapped
				var spawn_color := Color("#74b8f5", 0.5) if blue_column else Color("#f69e91", 0.5)
				draw_rect(Rect2(pos + Vector2(3, 3), Vector2(CELL - 8, CELL - 8)), spawn_color, false, 1)
			if mode == "MOVE" and moves.has(cell):
				draw_rect(Rect2(pos + Vector2(3, 3), Vector2(CELL - 8, CELL - 8)), Color("#baf592"), false, 3)
				draw_circle(pos + Vector2(57, 11), 5, Color("#c7f7a9"))
			if cell == hover:
				draw_rect(Rect2(pos + Vector2(1, 1), Vector2(CELL - 4, CELL - 4)), Color.WHITE, false, 2)
			var squad := _squad_at(cell)
			if squad != null:
				_draw_squad(pos, squad, targets.has(squad.id), font)
	if hovered_move != null:
		var points := PackedVector2Array()
		var squad := _active_squad()
		if squad != null:
			points.append(ORIGIN + Vector2(squad.position) * CELL + Vector2(34, 34))
		for cell in hovered_move.path:
			points.append(ORIGIN + Vector2(cell) * CELL + Vector2(34, 34))
		if points.size() > 1:
			draw_polyline(points, Color("#eaffbb"), 3, true)
	for x in map_def.width:
		draw_string(font, ORIGIN + Vector2(x * CELL + 28, -7), str(x + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b9c9bf"))
	for y in map_def.height:
		draw_string(font, ORIGIN + Vector2(-18, y * CELL + 40), str(y + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b9c9bf"))

func _draw_squad(pos: Vector2, squad: SquadState, targetable: bool, font: Font) -> void:
	var blue := squad.side_id == &"blue"
	var center := pos + Vector2(34, 33)
	var fill := Color("#235a94") if blue else Color("#9f3f3d")
	var edge := Color("#b6dcff") if blue else Color("#ffd4bd")
	if squad.id == state.active_squad_id:
		draw_circle(center, 30, Color("#ffe493"))
	if targetable and mode == "ATTACK":
		draw_circle(center, 31, Color("#ffdc63"))
	if squad.id == selected_target:
		draw_circle(center, 31, Color.WHITE)
	if blue:
		draw_circle(center, 27, fill)
		draw_arc(center, 27, 0, TAU, 24, edge, 2)
	else:
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -28), center + Vector2(29, 0), center + Vector2(0, 28), center + Vector2(-29, 0)]), fill)
		draw_polyline(PackedVector2Array([center + Vector2(0, -28), center + Vector2(29, 0), center + Vector2(0, 28), center + Vector2(-29, 0), center + Vector2(0, -28)]), edge, 2)
	var type_cue := str(squad.unit_type_id).substr(0, 1).to_upper()
	var number := int(str(squad.id).get_slice("_", 1)) + 1
	draw_string(font, pos + Vector2(9, 30), "%s%d %s" % ["B" if blue else "R", number, type_cue], HORIZONTAL_ALIGNMENT_CENTER, 50, 16, Color.WHITE)
	var hp := 0
	var max_hp := 0
	for member in squad.members:
		hp += member.current_hp
		max_hp += member.max_hp
	draw_string(font, pos + Vector2(9, 47), "%d / %d HP" % [squad.living_member_count(), hp], HORIZONTAL_ALIGNMENT_CENTER, 50, 11, Color.WHITE)
	draw_rect(Rect2(pos + Vector2(10, 56), Vector2(48, 4)), Color("#2b302c"))
	draw_rect(Rect2(pos + Vector2(10, 56), Vector2(48.0 * float(hp) / float(maxi(1, max_hp)), 4)), Color("#acf6ab"))

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
