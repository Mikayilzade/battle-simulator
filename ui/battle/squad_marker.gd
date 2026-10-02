class_name SquadMarker
extends RefCounted

static func draw(canvas: CanvasItem, ground: Vector2, squad: SquadState, active: bool) -> void:
	var blue := squad.side_id == &"blue"
	var cloth := Color("#338bc4") if blue else Color("#ba5147")
	var light := Color("#a9dcf5") if blue else Color("#f4b7a3")
	var ink := Color("#202833")
	var center := ground + Vector2(0, -7.0 if active else 0.0)
	canvas.draw_colored_polygon(PackedVector2Array([ground + Vector2(-31, 11), ground + Vector2(-18, 17), ground + Vector2(18, 17), ground + Vector2(31, 11), ground + Vector2(18, 7), ground + Vector2(-18, 7)]), Color(0.08, 0.12, 0.12, 0.45))
	canvas.draw_line(center + Vector2(-24, 7), center + Vector2(-24, -48), ink, 4)
	canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-23, -47), center + Vector2(6, -43), center + Vector2(1, -27), center + Vector2(-23, -31)]), cloth)
	canvas.draw_line(center + Vector2(-22, -45), center + Vector2(4, -41), light, 2)
	var count := mini(3, squad.living_member_count())
	for index in count:
		var figure := center + Vector2(float(index - 1) * 17.0 + 8.0, 0.0 if index == 1 else 5.0)
		canvas.draw_colored_polygon(PackedVector2Array([figure + Vector2(-8, 8), figure + Vector2(-6, -11), figure + Vector2(6, -11), figure + Vector2(8, 8)]), ink)
		canvas.draw_colored_polygon(PackedVector2Array([figure + Vector2(-6, 4), figure + Vector2(-5, -10), figure + Vector2(5, -10), figure + Vector2(6, 4)]), cloth)
		canvas.draw_circle(figure + Vector2(0, -16), 6, Color("#ddc5a1"))
		canvas.draw_arc(figure + Vector2(0, -17), 7, PI, TAU, 8, ink, 3)
		if index == 1:
			_draw_role(canvas, figure, squad.unit_type_id, light, ink)
	for member in squad.members:
		if member.is_commander and member.is_living():
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-29, -52), center + Vector2(-25, -60), center + Vector2(-21, -52)]), Color("#f5d474"))
			break
	var hp := 0
	var max_hp := 0
	for member in squad.members:
		hp += member.current_hp
		max_hp += member.max_hp
	canvas.draw_rect(Rect2(ground + Vector2(-26, 19), Vector2(52, 4)), Color("#26332e"))
	canvas.draw_rect(Rect2(ground + Vector2(-26, 19), Vector2(52.0 * float(hp) / float(maxi(1, max_hp)), 4)), light)
	canvas.draw_string(ThemeDB.fallback_font, ground + Vector2(32, 21), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f6f1df"))

static func _draw_role(canvas: CanvasItem, figure: Vector2, role: StringName, light: Color, ink: Color) -> void:
	match role:
		&"guard":
			canvas.draw_colored_polygon(PackedVector2Array([figure + Vector2(-11, -8), figure + Vector2(-2, -10), figure + Vector2(-2, 2), figure + Vector2(-7, 7), figure + Vector2(-11, 2)]), light)
			canvas.draw_line(figure + Vector2(-7, -8), figure + Vector2(-7, 4), ink, 2)
		&"striker":
			canvas.draw_line(figure + Vector2(8, 0), figure + Vector2(15, -25), Color("#e2e6dd"), 3)
			canvas.draw_line(figure + Vector2(4, -6), figure + Vector2(16, -3), ink, 3)
		&"archer":
			canvas.draw_arc(figure + Vector2(9, -9), 11, -PI / 2.0, PI / 2.0, 10, Color("#d9b77b"), 3)
			canvas.draw_line(figure + Vector2(9, -20), figure + Vector2(9, 2), Color("#f1e8d1"), 1)
			canvas.draw_line(figure + Vector2(1, -10), figure + Vector2(22, -10), Color("#e4e7df"), 2)
