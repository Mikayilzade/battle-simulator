class_name VisualLabPreview
extends Control

## A self-contained drawing stand. Its units and overlays are sample poses, never battle state.
const FAMILIES := VisualLabCatalog.FAMILIES
const GROUND := {
	&"plain": Color("#78985c"), &"fields": Color("#a98d58"),
	&"forest": Color("#426e50"), &"hills": Color("#83945d"),
	&"mountains": Color("#777e7a"), &"rough": Color("#8d8164"),
	&"rocks": Color("#6b716b"), &"lake": Color("#408b9d"),
	&"sea": Color("#316b91"), &"road": Color("#918064")
}

var catalog: VisualLabCatalog
var selection: VisualLabSelection

func configure(new_catalog: VisualLabCatalog, new_selection: VisualLabSelection) -> void:
	catalog = new_catalog
	selection = new_selection
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#172c2b"))
	if catalog == null or selection == null:
		return
	var field := catalog.get_variant(selection.field_id)
	if field == null:
		return
	var spacing := Vector2(minf((size.x - 32.0) / 5.0, 146.0), minf((size.y - 58.0) / 2.0, 205.0))
	var origin := Vector2((size.x - spacing.x * 5.0) * 0.5, 24.0)
	for i in FAMILIES.size():
		var center := origin + Vector2((i % 5 + 0.5) * spacing.x, (i / 5 + 0.5) * spacing.y)
		var family: StringName = FAMILIES[i]
		var terrain := catalog.get_variant(selection.terrain_ids.get(family, &""))
		_draw_ground(center, spacing, family, field, terrain)
		if i in [0, 1, 4, 5, 8, 9]:
			var role: StringName = [&"guard", &"striker", &"archer"][i % 3]
			var side := &"blue" if i in [0, 1, 5] else &"red"
			var unit := catalog.get_variant(selection.unit_ids.get(role, &""))
			_draw_unit(center + Vector2(0, -5), role, side, unit, i == 0)
		if i == 0:
			_draw_ring(center, Color("#f2d885"), 31.0)
		elif i == 1:
			_draw_ring(center, Color("#68c9d3cc"), 34.0)
		elif i == 8:
			_draw_ring(center, Color("#ef7771"), 34.0)
		_draw_caption(center + Vector2(0, spacing.y * 0.36), str(family).capitalize())
	_draw_caption(Vector2(size.x * 0.5, size.y - 12), "SELECTED   •   REACHABLE   •   TARGET" )

func _draw_ground(c: Vector2, step: Vector2, family: StringName, field: VisualVariantDef, terrain: VisualVariantDef) -> void:
	var tone: Color = GROUND.get(family, Color.DARK_GREEN)
	var w := step.x * 0.47
	var h := step.y * 0.33
	var deep := field.mode != "2d"
	if field.render_key == &"pastoral":
		w *= 0.91
		h *= 0.9
	if deep:
		var depth := 11.0 if field.render_key == &"isometric" else (18.0 if field.render_key == &"tabletop" else 27.0)
		var diamond := PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h), c + Vector2(-w, 0)])
		draw_colored_polygon(PackedVector2Array([diamond[1], diamond[2], diamond[2] + Vector2(0, depth), diamond[1] + Vector2(0, depth)]), tone.darkened(0.48))
		draw_colored_polygon(PackedVector2Array([diamond[2], diamond[3], diamond[3] + Vector2(0, depth), diamond[2] + Vector2(0, depth)]), tone.darkened(0.62))
		draw_colored_polygon(diamond, tone.lightened(0.1))
		draw_polyline(PackedVector2Array([diamond[3], diamond[0], diamond[1], diamond[2]]), Color("#d9d2a9", 0.24), 1.5)
	else:
		var rect := Rect2(c - Vector2(w, h * 0.73), Vector2(w * 2.0, h * 1.46))
		draw_rect(rect, tone, true)
		if field.render_key == &"atlas":
			draw_rect(rect.grow(-3.0), Color("#ebdfaa", 0.26), false, 1.0)
		else:
			for k in 5:
				var p := c + Vector2((k - 2) * w * 0.32, sin(float(k) * 2.7) * h * 0.28)
				draw_circle(p, 6.0, tone.lightened(0.12))
	var relief := terrain != null and terrain.render_key == &"relief"
	_draw_feature(c, family, relief, w, h)

func _draw_feature(c: Vector2, family: StringName, relief: bool, w: float, h: float) -> void:
	var rise := 1.35 if relief else 0.8
	match family:
		&"plain":
			for j in 5:
				var x := (j - 2) * 15.0
				draw_line(c + Vector2(x, 7), c + Vector2(x + 4, 1 - 5 * rise), Color("#d6d891"), 2.0)
		&"fields":
			for j in 4:
				draw_line(c + Vector2(-w * 0.7, -h * 0.32 + j * 10), c + Vector2(w * 0.7, -h * 0.32 + j * 10), Color("#d5b879"), 5.0 if relief else 2.5)
		&"forest":
			for j in 3:
				var p := c + Vector2((j - 1) * 22, 5 if j != 1 else -8)
				draw_line(p, p + Vector2(0, -19 * rise), Color("#3b4935"), 5.0)
				draw_circle(p + Vector2(0, -25 * rise), 14.0 if relief else 11.0, Color("#2e5941"))
		&"hills":
			for j in 2:
				var p := c + Vector2((j - 0.5) * 30, 12)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-24, 0), p + Vector2(0, -22 * rise), p + Vector2(27, 0)]), Color("#aab780"))
		&"mountains":
			for j in 2:
				var p := c + Vector2((j - 0.5) * 29, 13)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-23, 0), p + Vector2(0, -35 * rise), p + Vector2(24, 0)]), Color("#b5b5a5"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -26 * rise), p + Vector2(0, -35 * rise), p + Vector2(7, -25 * rise)]), Color("#ede8d8"))
		&"rough", &"rocks":
			for j in 5:
				var p := c + Vector2((j - 2) * 13, sin(float(j) * 2.1) * 9)
				var radius := (9.0 if family == &"rocks" else 5.0) * rise
				draw_colored_polygon(PackedVector2Array([p + Vector2(-radius, 3), p + Vector2(0, -radius), p + Vector2(radius, 3)]), Color("#c1b9a0") if family == &"rocks" else Color("#b7a277"))
		&"lake", &"sea":
			for j in 3:
				var y := (j - 1) * 11.0
				draw_arc(c + Vector2(0, y), 22.0 + j * 7.0, 0.15, 2.5, 18, Color("#a8d5cc", 0.7), 2.0)
		&"road":
			draw_line(c + Vector2(-w * 0.7, 13), c + Vector2(w * 0.7, -16), Color("#d8c497"), 12.0 if relief else 8.0)
			draw_line(c + Vector2(-w * 0.7, 13), c + Vector2(w * 0.7, -16), Color("#8a7152"), 1.0)

func _draw_unit(c: Vector2, role: StringName, side: StringName, variant: VisualVariantDef, selected: bool) -> void:
	if variant == null:
		return
	var base := Color("#4a9fd0") if side == &"blue" else Color("#d86a5b")
	var dark := base.darkened(0.45)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-26, 18), c + Vector2(0, 13), c + Vector2(26, 18), c + Vector2(0, 23)]), Color(0, 0, 0, 0.4))
	var lift := 7.0 if selected else 0.0
	var p := c - Vector2(0, lift)
	match variant.render_key:
		&"emblem":
			draw_circle(p, 21.0, dark)
			draw_circle(p, 18.0, base)
			draw_arc(p, 18.0, 0, TAU, 24, Color("#eee1b6"), 2.0)
			_draw_role_mark(p, role, Color("#f6f0d8"), 1.0)
		&"formation":
			for j in 3:
				var f := p + Vector2((j - 1) * 14, 5 if j != 1 else -7)
				draw_circle(f + Vector2(0, -10), 5.5, Color("#ebd4a8"))
				draw_rect(Rect2(f + Vector2(-6, -4), Vector2(12, 15)), base)
				draw_line(f + Vector2(0, 5), f + Vector2(0, 13), dark, 3.0)
			_draw_role_mark(p + Vector2(0, -3), role, Color("#f6f0d8"), 0.55)
		&"miniature":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-19, 13), p + Vector2(0, 20), p + Vector2(20, 13), p + Vector2(0, 6)]), dark)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 4), p + Vector2(0, -26), p + Vector2(14, 4), p + Vector2(0, 12)]), base)
			draw_circle(p + Vector2(0, -24), 7.0, Color("#e9d1a5"))
			_draw_role_mark(p + Vector2(0, -1), role, Color.WHITE, 0.65)
	if side == &"blue":
		draw_colored_polygon(PackedVector2Array([p + Vector2(-25, -24), p + Vector2(-15, -32), p + Vector2(-15, -16)]), Color("#95dcf7"))
	else:
		draw_rect(Rect2(p + Vector2(16, -30), Vector2(9, 13)), Color("#f7a18a"))
	if selected:
		draw_circle(p + Vector2(20, -24), 4.0, Color("#f8dd7d"))

func _draw_role_mark(p: Vector2, role: StringName, ink: Color, scale_value: float) -> void:
	match role:
		&"guard":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -8) * scale_value, p + Vector2(9, -8) * scale_value, p + Vector2(7, 6) * scale_value, p + Vector2(0, 12) * scale_value, p + Vector2(-7, 6) * scale_value]), ink)
		&"striker":
			draw_line(p + Vector2(-10, 9) * scale_value, p + Vector2(10, -11) * scale_value, ink, 4.0 * scale_value)
			draw_line(p + Vector2(-5, 4) * scale_value, p + Vector2(2, 11) * scale_value, ink, 3.0 * scale_value)
		&"archer":
			draw_arc(p + Vector2(-5, 0), 12.0 * scale_value, -1.2, 1.2, 14, ink, 3.0 * scale_value)
			draw_line(p + Vector2(-4, -11) * scale_value, p + Vector2(13, 8) * scale_value, ink, 2.0 * scale_value)

func _draw_ring(c: Vector2, color: Color, radius: float) -> void:
	draw_arc(c + Vector2(0, 9), radius, 0, TAU, 40, color, 3.0)

func _draw_caption(c: Vector2, caption: String) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, c - Vector2(width * 0.5, 0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e9e9cf"))
