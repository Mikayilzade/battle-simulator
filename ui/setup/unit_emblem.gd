class_name UnitEmblem
extends Control

var unit_type_id: StringName = &"guard"
var side_id: StringName = &"blue"

func _ready() -> void:
	custom_minimum_size = Vector2(56, 62)
	mouse_filter = MOUSE_FILTER_IGNORE

func set_type(type_id: StringName, side: StringName) -> void:
	unit_type_id = type_id
	side_id = side
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var blue := side_id == &"blue"
	var field := Color("#2874a4") if blue else Color("#a44740")
	var metal := Color("#d5e8dd")
	draw_circle(center + Vector2(0, 3), 25, Color(0.04, 0.08, 0.09, 0.32))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -27), center + Vector2(22, -15), center + Vector2(19, 14), center + Vector2(0, 28), center + Vector2(-19, 14), center + Vector2(-22, -15)]), field)
	draw_polyline(PackedVector2Array([center + Vector2(0, -27), center + Vector2(22, -15), center + Vector2(19, 14), center + Vector2(0, 28), center + Vector2(-19, 14), center + Vector2(-22, -15), center + Vector2(0, -27)]), metal, 2)
	match unit_type_id:
		&"guard":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -13), center + Vector2(12, -13), center + Vector2(10, 8), center + Vector2(0, 17), center + Vector2(-10, 8)]), metal)
			draw_line(center + Vector2(0, -10), center + Vector2(0, 13), field.darkened(0.35), 3)
		&"striker":
			draw_line(center + Vector2(-13, 11), center + Vector2(12, -15), metal, 5)
			draw_line(center + Vector2(-15, -14), center + Vector2(13, 13), metal, 5)
			draw_line(center + Vector2(-15, 5), center + Vector2(-5, 15), Color("#e4bd76"), 4)
		&"archer":
			draw_arc(center, 16, -PI * 0.5, PI * 0.5, 16, Color("#e6bf7b"), 4)
			draw_line(center + Vector2(0, -16), center + Vector2(0, 16), metal, 2)
			draw_line(center + Vector2(-13, 0), center + Vector2(17, 0), metal, 3)
			draw_colored_polygon(PackedVector2Array([center + Vector2(17, 0), center + Vector2(10, -5), center + Vector2(10, 5)]), metal)
