class_name IsometricDiorama
extends Control

## Static, deterministic art-direction sample. It never creates or changes BattleState.
const GRID := [
	[&"sea", &"lake", &"plain", &"hills", &"mountains", &"rocks", &"plain"],
	[&"sea", &"lake", &"plain", &"forest", &"hills", &"rocks", &"plain"],
	[&"lake", &"plain", &"fields", &"road", &"forest", &"hills", &"plain"],
	[&"plain", &"fields", &"road", &"road", &"forest", &"rough", &"plain"],
	[&"plain", &"plain", &"road", &"plain", &"rough", &"plain", &"plain"],
	[&"plain", &"plain", &"road", &"plain", &"plain", &"rough", &"plain"]
]
const TERRAIN_COLORS := {
	&"plain": Color("#93aa70"), &"fields": Color("#b49464"),
	&"forest": Color("#648d64"), &"hills": Color("#9aa879"),
	&"mountains": Color("#8a9387"), &"rough": Color("#ab9b76"),
	&"rocks": Color("#858d80"), &"lake": Color("#5b9fa0"),
	&"sea": Color("#568da3"), &"road": Color("#a29a75")
}

var catalog: VisualLabCatalog
var packs: VisualPackCatalog
var selection: VisualLabSelection
var tile_w := 94.0
var tile_h := 47.0
var center_origin := Vector2.ZERO

func configure(new_catalog: VisualLabCatalog, new_packs: VisualPackCatalog, new_selection: VisualLabSelection) -> void:
	catalog = new_catalog
	packs = new_packs
	selection = new_selection
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#20362f"))
	if catalog == null or packs == null or selection == null:
		return
	var pack := packs.get_pack(selection.pack_id)
	if pack == null:
		return
	var width_scale := minf(1.0, (size.x - 75.0) / 760.0)
	tile_w = 94.0 * width_scale
	tile_h = (55.0 if selection.camera_angle == &"top" else (40.0 if selection.camera_angle == &"strong" else 47.0)) * width_scale
	center_origin = Vector2(size.x * 0.48, maxf(100.0, size.y * 0.25))
	_draw_landscape(pack)
	for diagonal in GRID.size() + GRID[0].size() - 1:
		for x in GRID[0].size():
			var y := diagonal - x
			if y >= 0 and y < GRID.size():
				_draw_tile(Vector2i(x, y), pack)
	_draw_roads(pack)
	_draw_improvement(Vector2i(1, 4), &"lumber", pack)
	_draw_improvement(Vector2i(1, 3), &"farm", pack)
	_draw_reachability()
	_draw_unit(Vector2i(2, 4), &"guard", &"blue", true, pack)
	_draw_unit(Vector2i(1, 5), &"archer", &"blue", false, pack)
	_draw_unit(Vector2i(5, 2), &"guard", &"red", false, pack)
	_draw_unit(Vector2i(5, 4), &"striker", &"red", false, pack)
	if selection.preview_state == &"dense":
		_draw_unit(Vector2i(4, 2), &"archer", &"blue", false, pack)
		_draw_tree(_cell(Vector2i(4, 2)) + Vector2(25, 6), pack, 0.65)
	_draw_foreground_overlays(pack)

func _draw_landscape(pack: VisualPackDef) -> void:
	var sky := Color("#637f73") if pack.render_key != "cozy" else Color("#8e9472")
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.42)), sky)
	draw_colored_polygon(PackedVector2Array([Vector2(0, size.y * 0.42), Vector2(size.x * 0.2, size.y * 0.35), Vector2(size.x * 0.5, size.y * 0.41), Vector2(size.x * 0.78, size.y * 0.32), Vector2(size.x, size.y * 0.4), Vector2(size.x, size.y), Vector2(0, size.y)]), pack.shadow_color.lerp(pack.ground_color, 0.44))
	_oval(Vector2(size.x * 0.52, size.y * 0.82), Vector2(size.x * 0.47, size.y * 0.15), Color(0.08, 0.15, 0.11, 0.42), 18)

func _cell(cell: Vector2i) -> Vector2:
	return center_origin + Vector2((cell.x - cell.y) * tile_w * 0.5, (cell.x + cell.y) * tile_h * 0.5)

func _tile_depth(pack: VisualPackDef) -> float:
	match pack.render_key:
		"clean": return 8.0
		"cozy": return 13.0
		"civ": return 5.0
		_: return 17.0

func _draw_tile(cell: Vector2i, pack: VisualPackDef) -> void:
	var family: StringName = GRID[cell.y][cell.x]
	var variant := catalog.get_variant(selection.terrain_ids.get(family, &""))
	var source_pack := packs.get_pack(variant.pack_id) if variant != null else pack
	if source_pack == null:
		source_pack = pack
	var c := _cell(cell)
	var half_w := tile_w * 0.5
	var half_h := tile_h * 0.5
	var depth := _tile_depth(pack)
	var base: Color = TERRAIN_COLORS.get(family, pack.ground_color)
	if family not in [&"lake", &"sea"]:
		base = base.lerp(source_pack.ground_color, 0.22)
	var top := PackedVector2Array([c + Vector2(0, -half_h), c + Vector2(half_w, 0), c + Vector2(0, half_h), c + Vector2(-half_w, 0)])
	var side_shadow := pack.shadow_color.darkened(0.16)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], top[2] + Vector2(0, depth), top[1] + Vector2(0, depth)]), base.darkened(0.33))
	draw_colored_polygon(PackedVector2Array([top[2], top[3], top[3] + Vector2(0, depth), top[2] + Vector2(0, depth)]), base.darkened(0.45))
	if pack.render_key == "cozy":
		var organic := PackedVector2Array([top[0], c + Vector2(half_w * 0.52, -half_h * 0.47), top[1], c + Vector2(half_w * 0.51, half_h * 0.49), top[2], c + Vector2(-half_w * 0.48, half_h * 0.47), top[3], c + Vector2(-half_w * 0.53, -half_h * 0.49)])
		draw_colored_polygon(organic, base.lightened(0.06))
	elif pack.render_key == "civ":
		draw_colored_polygon(top, base.lightened(0.13))
		_oval(c + Vector2(-6, -3), Vector2(half_w * 0.64, half_h * 0.54), base.lightened(0.19), 16)
	elif pack.render_key == "storybook":
		draw_colored_polygon(top, base.lightened(0.09))
		draw_polyline(PackedVector2Array([top[3], top[0], top[1], top[2]]), pack.edge_color.darkened(0.15), 2.8)
	else:
		draw_colored_polygon(top, base.lightened(0.1))
		draw_line(top[3], top[0], pack.accent_color.darkened(0.18), 1.2)
	if pack.edge_strength > 0.25:
		draw_line(top[2], top[1], side_shadow.lerp(base, 0.68), 1.0 + pack.edge_strength * 2.0)
	_draw_texture(c, family, source_pack)
	_draw_feature(c, family, source_pack, cell)

func _draw_texture(c: Vector2, family: StringName, pack: VisualPackDef) -> void:
	if family in [&"lake", &"sea", &"road"]:
		return
	var density := _detail_factor() * pack.detail_amount
	var amount := int(2.0 + density * 9.0)
	for i in amount:
		var dx := sin(float(i * 17 + int(c.x))) * tile_w * 0.29
		var dy := cos(float(i * 23 + int(c.y))) * tile_h * 0.24
		var mark := c + Vector2(dx, dy)
		if family in [&"plain", &"fields", &"forest", &"hills"]:
			draw_line(mark, mark + Vector2(2, -3), Color("#d6d8a0", 0.32), 1.0)
		else:
			draw_circle(mark, 1.1, Color("#dfd6b7", 0.27))

func _detail_factor() -> float:
	match selection.detail_level:
		&"low": return 0.45
		&"high": return 1.4
		_: return 1.0

func _draw_feature(c: Vector2, family: StringName, pack: VisualPackDef, cell: Vector2i) -> void:
	match family:
		&"plain":
			if pack.render_key == "cozy" or selection.detail_level == &"high":
				for i in 2:
					var p := c + Vector2((i - 0.5) * 25, i * 7 - 4)
					_draw_grass(p, pack)
		&"fields":
			for i in 4:
				var from := c + Vector2(-tile_w * 0.31 + i * 7, -tile_h * 0.15 - i * 2)
				var to := from + Vector2(tile_w * 0.5, tile_h * 0.35)
				draw_line(from, to, Color("#77563c"), 3.2 if pack.render_key == "storybook" else 2.2)
				draw_line(from + Vector2(0, -2), to + Vector2(0, -2), Color("#d0bc74"), 1.4)
		&"forest":
			var count := 3 if pack.render_key == "civ" else (5 if pack.render_key == "cozy" and selection.detail_level == &"high" else 4)
			for i in count:
				var p := c + Vector2((i % 3 - 1) * 19, (i / 3.0 - 0.5) * 12)
				_draw_tree(p, pack, 0.8 if i % 2 == 0 else 0.65)
		&"hills":
			_draw_hill(c, pack)
		&"mountains":
			_draw_mountain(c, pack)
		&"rough":
			for i in 5:
				var p := c + Vector2((i - 2) * 12, sin(float(i) * 2.1) * 7)
				_draw_rock(p, pack, 0.36 + i % 2 * 0.14)
		&"rocks":
			for i in 3:
				_draw_rock(c + Vector2((i - 1) * 17, (i % 2) * 8), pack, 0.8 if i == 1 else 0.64)
		&"lake", &"sea":
			_draw_water(c, family, pack, cell)
		&"road":
			if pack.render_key == "cozy" and selection.detail_level != &"low":
				_draw_rock(c + Vector2(20, 8), pack, 0.22)

func _draw_grass(p: Vector2, pack: VisualPackDef) -> void:
	var color := pack.ground_color.lightened(0.28)
	for i in 3:
		draw_line(p, p + Vector2((i - 1) * 4, -5 - i % 2 * 3), color, 1.2)

func _draw_tree(p: Vector2, pack: VisualPackDef, scale_value: float) -> void:
	var trunk := Color("#5e4b39")
	var green := Color("#3d6a4b") if pack.render_key != "storybook" else Color("#4c7a50")
	_oval(p + Vector2(5, 7), Vector2(13, 4) * scale_value, Color(0.08, 0.16, 0.1, pack.shadow_strength), 12)
	draw_line(p + Vector2(0, 3), p + Vector2(0, -19) * scale_value, trunk, 5.0 * scale_value)
	if pack.render_key == "civ":
		_oval(p + Vector2(0, -21) * scale_value, Vector2(18, 12) * scale_value, green, 12)
	else:
		for i in 3:
			var crown := p + Vector2((i - 1) * 9, -24 - (i % 2) * 9) * scale_value
			_oval(crown, Vector2(12, 10) * scale_value, green.lightened(0.09 * i), 12)
		if pack.render_key == "cozy" and selection.detail_level == &"high":
			draw_circle(p + Vector2(-11, -31) * scale_value, 2.2, Color("#d4c28b"))

func _draw_hill(c: Vector2, pack: VisualPackDef) -> void:
	_oval(c + Vector2(0, 7), Vector2(30, 10), Color(0.11, 0.19, 0.11, pack.shadow_strength), 14)
	var height := 20.0 if pack.render_key == "civ" else 29.0
	draw_colored_polygon(PackedVector2Array([c + Vector2(-30, 7), c + Vector2(-9, -height), c + Vector2(8, -height * 0.72), c + Vector2(31, 7)]), Color("#8e9f75"))
	draw_line(c + Vector2(-20, 2), c + Vector2(0, -height * 0.45), Color("#c3c29a"), 2.0)
	if pack.render_key == "cozy":
		_draw_grass(c + Vector2(14, -5), pack)

func _draw_mountain(c: Vector2, pack: VisualPackDef) -> void:
	var height := 48.0 if pack.render_key == "civ" else 66.0
	draw_colored_polygon(PackedVector2Array([c + Vector2(-37, 11), c + Vector2(-4, -height), c + Vector2(17, -height * 0.55), c + Vector2(34, 11)]), Color("#78847e"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -height), c + Vector2(17, -height * 0.55), c + Vector2(34, 11), c + Vector2(4, -8)]), Color("#606f6b"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-15, -height * 0.66), c + Vector2(-4, -height), c + Vector2(7, -height * 0.68)]), Color("#d9d9c5"))

func _draw_rock(p: Vector2, pack: VisualPackDef, scale_value: float) -> void:
	var radius := 18.0 * scale_value
	_oval(p + Vector2(4, 5), Vector2(radius, radius * 0.35), Color(0.07, 0.12, 0.1, pack.shadow_strength), 10)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-radius, 3), p + Vector2(-radius * 0.45, -radius * 0.8), p + Vector2(radius * 0.36, -radius), p + Vector2(radius, 2)]), Color("#9ca39a"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(radius * 0.36, -radius), p + Vector2(radius, 2), p + Vector2(0, 6)]), Color("#737f79"))

func _draw_water(c: Vector2, family: StringName, pack: VisualPackDef, cell: Vector2i) -> void:
	var wave := Color("#bddbd2") if family == &"lake" else Color("#c6dde1")
	for i in 3:
		var p := c + Vector2((i - 1) * 14, (i % 2) * 7 - 5)
		draw_arc(p, 7.0 if pack.render_key == "civ" else 10.0, 0.3, 2.6, 10, wave, 1.5)
	if cell.x < GRID[0].size() - 1 and GRID[cell.y][cell.x + 1] not in [&"lake", &"sea"]:
		draw_line(c + Vector2(tile_w * 0.42, -2), c + Vector2(0, tile_h * 0.42), wave, 2.5)

func _draw_roads(pack: VisualPackDef) -> void:
	for y in GRID.size():
		for x in GRID[y].size():
			if GRID[y][x] != &"road":
				continue
			var here := _cell(Vector2i(x, y))
			for next in [Vector2i(x + 1, y), Vector2i(x, y + 1)]:
				if next.x < GRID[y].size() and next.y < GRID.size() and GRID[next.y][next.x] == &"road":
					var there := _cell(next)
					draw_line(here, there, Color("#665b43"), 16.0 if pack.render_key == "storybook" else 13.0)
					draw_line(here, there, Color("#c3ab79"), 11.0 if pack.render_key == "storybook" else 9.0)
					draw_line(here, there, Color("#e0cda0", 0.45), 2.0)

func _draw_improvement(cell: Vector2i, site: StringName, pack: VisualPackDef) -> void:
	var id: StringName = selection.improvement_ids.get(site, &"")
	var variant := catalog.get_variant(id)
	if variant == null:
		return
	var site_pack := packs.get_pack(variant.pack_id)
	if site_pack == null:
		site_pack = pack
	var c := _cell(cell)
	if site == &"lumber":
		_oval(c + Vector2(1, 10), Vector2(31, 9), Color(0.09, 0.14, 0.09, 0.3), 14)
		var log_count := 5 if site_pack.render_key == "cozy" else (2 if site_pack.render_key == "civ" else 3)
		for i in log_count:
			var p := c + Vector2(-22 + i * 5, 4 + i * 2)
			draw_line(p, p + Vector2(23, -8), Color("#62452e"), 6.8 if site_pack.render_key == "storybook" else 5.5)
			draw_circle(p, 2.8, Color("#d4ab75"))
		draw_line(c + Vector2(-11, -3), c + Vector2(-11, -25), Color("#69503a"), 3.0)
		draw_line(c + Vector2(14, -4), c + Vector2(14, -25), Color("#69503a"), 3.0)
		var roof_rise := 41.0 if site_pack.render_key == "storybook" else (31.0 if site_pack.render_key == "civ" else 35.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -25), c + Vector2(0, -roof_rise), c + Vector2(23, -25), c + Vector2(6, -17)]), Color("#b58a61") if site_pack.render_key == "clean" else Color("#956744"))
		_draw_worker(c + Vector2(21, 0), site_pack)
		if selection.detail_level == &"high" or site_pack.render_key == "cozy":
			_draw_rock(c + Vector2(-23, 12), site_pack, 0.18)
	else:
		var row_count := 4 if site_pack.render_key == "cozy" else (2 if site_pack.render_key == "civ" else 3)
		for i in row_count:
			var p := c + Vector2(-20 + i * 11, 6)
			draw_line(p, p + Vector2(18, -12), Color("#e0c887"), 4.0 if site_pack.render_key == "storybook" else 3.0)
		if site_pack.render_key == "cozy":
			draw_line(c + Vector2(-23, -14), c + Vector2(16, -29), Color("#735738"), 2.2)
		_draw_worker(c + Vector2(18, -4), site_pack)

func _draw_worker(p: Vector2, pack: VisualPackDef) -> void:
	_oval(p + Vector2(2, 3), Vector2(5, 2), Color(0, 0, 0, 0.24), 10)
	var body_height := 12.0 * pack.figure_proportion
	draw_line(p, p + Vector2(1, -body_height), Color("#886044"), 5.0 * pack.figure_proportion)
	draw_circle(p + Vector2(1, -body_height - 3), 3.8 * pack.figure_proportion, Color("#e6bd8b"))
	draw_line(p + Vector2(4, -8), p + Vector2(12, -12), Color("#e0cfaa"), 1.5)

func _draw_reachability() -> void:
	if selection.preview_state != &"reachable":
		return
	for cell in [Vector2i(3, 4), Vector2i(2, 3), Vector2i(3, 3)]:
		var c := _cell(cell)
		var poly := PackedVector2Array([c + Vector2(0, -tile_h * 0.5), c + Vector2(tile_w * 0.5, 0), c + Vector2(0, tile_h * 0.5), c + Vector2(-tile_w * 0.5, 0)])
		draw_colored_polygon(poly, Color(0.2, 0.75, 0.75, 0.19))
		draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color("#9ad8ce"), 1.6)

func _draw_unit(cell: Vector2i, role: StringName, side: StringName, commander: bool, pack: VisualPackDef) -> void:
	var id: StringName = selection.unit_ids.get(role, &"")
	var variant := catalog.get_variant(id)
	if variant == null:
		return
	var unit_pack := packs.get_pack(variant.pack_id)
	if unit_pack == null:
		unit_pack = pack
	var scale_value := unit_pack.figure_proportion * (0.75 if selection.unit_scale == &"small" else (1.3 if selection.unit_scale == &"large" else 1.0))
	var c := _cell(cell) + Vector2(0, -4)
	var people: Array[Vector2] = [Vector2.ZERO]
	match variant.approach:
		&"formation": people = [Vector2(-13, 4), Vector2(11, 5), Vector2(0, -7)]
		&"banner": people = [Vector2(-9, 5), Vector2(9, 5), Vector2(0, -7)]
	for i in people.size():
		_draw_person(c + people[i] * scale_value, role, side, unit_pack, scale_value * (0.85 if people.size() > 1 else 1.0), i)
	if variant.approach == &"banner" or commander and selection.commander_id == &"COMMANDER-25D-BANNER-01":
		_draw_banner(c + Vector2(-19, 1) * scale_value, side, scale_value)
	if commander and selection.commander_id == &"COMMANDER-25D-PLUME-01":
		_draw_plume(c + Vector2(0, -31) * scale_value, scale_value)
	if commander and selection.commander_id == &"COMMANDER-25D-TRIM-01":
		draw_arc(c + Vector2(0, -15) * scale_value, 12.0 * scale_value, 0.2, 2.9, 16, Color("#efd485"), 2.5)
	if side == &"blue":
		draw_colored_polygon(PackedVector2Array([c + Vector2(-25, -32) * scale_value, c + Vector2(-17, -39) * scale_value, c + Vector2(-17, -25) * scale_value]), Color("#c3e9df"))
	else:
		draw_rect(Rect2(c + Vector2(18, -38) * scale_value, Vector2(8, 13) * scale_value), Color("#f6d2b0"))
	if selection.preview_state == &"damaged" and side == &"red" and role == &"guard":
		var bar := Rect2(c + Vector2(-22, 16), Vector2(44, 4))
		draw_rect(bar, Color("#312c2a"))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * 0.36, bar.size.y)), Color("#e16e58"))

func _draw_person(p: Vector2, role: StringName, side: StringName, pack: VisualPackDef, scale_value: float, index: int) -> void:
	var cloth := Color("#4b89a8") if side == &"blue" else Color("#ae604e")
	var dark := cloth.darkened(0.42)
	var head_size := 4.0 if pack.render_key == "civ" else (6.4 if pack.render_key == "storybook" else 5.2)
	var body_width := 7.0 if pack.render_key == "clean" else (10.0 if pack.render_key == "storybook" else 8.0)
	_oval(p + Vector2(4, 7) * scale_value, Vector2(10, 3) * scale_value, Color(0, 0, 0, pack.shadow_strength), 12)
	draw_line(p + Vector2(-3, 4) * scale_value, p + Vector2(-4, 9) * scale_value, Color("#4b4138"), 2.5 * scale_value)
	draw_line(p + Vector2(3, 4) * scale_value, p + Vector2(4, 9) * scale_value, Color("#4b4138"), 2.5 * scale_value)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-body_width, -11) * scale_value, p + Vector2(body_width, -11) * scale_value, p + Vector2(body_width * 0.8, 4) * scale_value, p + Vector2(-body_width * 0.8, 4) * scale_value]), cloth)
	draw_line(p + Vector2(-body_width * 0.6, -7) * scale_value, p + Vector2(body_width * 0.6, -7) * scale_value, dark, 1.6 * scale_value)
	draw_circle(p + Vector2(0, -17) * scale_value, head_size * scale_value, Color("#e6be91"))
	if pack.render_key == "cozy":
		draw_arc(p + Vector2(0, -18) * scale_value, head_size * scale_value, PI, TAU, 8, Color("#5e4737"), 2.0 * scale_value)
	match role:
		&"guard":
			_draw_shield(p + Vector2(-body_width - 3, -4) * scale_value, side, scale_value)
			draw_line(p + Vector2(body_width - 1, 0) * scale_value, p + Vector2(body_width + 3, -25) * scale_value, Color("#d1c6a0"), 2.0 * scale_value)
		&"striker":
			draw_line(p + Vector2(body_width - 1, -6) * scale_value, p + Vector2(body_width + 10, -25) * scale_value, Color("#d6d9c4"), 3.0 * scale_value)
			draw_line(p + Vector2(body_width + 4, -14) * scale_value, p + Vector2(body_width + 13, -11) * scale_value, Color("#73583d"), 2.5 * scale_value)
		&"archer":
			draw_arc(p + Vector2(body_width + 5, -9) * scale_value, 11.0 * scale_value, -1.5, 1.5, 18, Color("#6a4b32"), 2.6 * scale_value)
			draw_line(p + Vector2(body_width + 6, -20) * scale_value, p + Vector2(body_width + 6, 2) * scale_value, Color("#e4d7b3"), 1.2 * scale_value)
			draw_line(p + Vector2(body_width + 1, -8) * scale_value, p + Vector2(body_width + 19, -12) * scale_value, Color("#d8d3b5"), 1.3 * scale_value)
			draw_rect(Rect2(p + Vector2(-body_width - 4, -15) * scale_value, Vector2(4, 11) * scale_value), Color("#6e5238"))

func _draw_shield(p: Vector2, side: StringName, scale_value: float) -> void:
	var face := Color("#94c6d3") if side == &"blue" else Color("#db9b76")
	draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -7) * scale_value, p + Vector2(5, -7) * scale_value, p + Vector2(4, 4) * scale_value, p + Vector2(0, 8) * scale_value, p + Vector2(-5, 4) * scale_value]), face)
	if side == &"blue":
		draw_line(p + Vector2(-3, -2) * scale_value, p + Vector2(3, -2) * scale_value, Color("#365e75"), 1.5 * scale_value)
	else:
		draw_circle(p + Vector2(0, -1) * scale_value, 2.0 * scale_value, Color("#6b3e37"))

func _draw_banner(p: Vector2, side: StringName, scale_value: float) -> void:
	draw_line(p + Vector2(0, 5) * scale_value, p + Vector2(0, -43) * scale_value, Color("#796244"), 2.0 * scale_value)
	if side == &"blue":
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -43) * scale_value, p + Vector2(19, -40) * scale_value, p + Vector2(0, -30) * scale_value]), Color("#4f9cbc"))
	else:
		draw_rect(Rect2(p + Vector2(0, -43) * scale_value, Vector2(15, 12) * scale_value), Color("#c46a54"))

func _draw_plume(p: Vector2, scale_value: float) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0) * scale_value, p + Vector2(0, -12) * scale_value, p + Vector2(6, -10) * scale_value, p + Vector2(4, 0) * scale_value]), Color("#ead096"))

func _draw_foreground_overlays(pack: VisualPackDef) -> void:
	var state := selection.preview_state
	if state in [&"selected", &"reachable", &"target", &"route", &"dense"]:
		_ground_ring(_cell(Vector2i(2, 4)) + Vector2(0, 5), Color("#f2d689"), 23.0)
	if state == &"target":
		var c := _cell(Vector2i(5, 4)) + Vector2(0, 5)
		_ground_ring(c, Color("#ec775e"), 25.0)
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			var start := c + Vector2(cos(angle) * 28.0, sin(angle) * 11.0)
			draw_line(start, start + Vector2(cos(angle) * 8.0, sin(angle) * 4.0), Color("#f6b179"), 2.5)
	if state == &"route":
		var route := [Vector2i(2, 4), Vector2i(3, 4), Vector2i(3, 3), Vector2i(4, 3)]
		for i in route.size() - 1:
			var from := _cell(route[i]) + Vector2(0, 11)
			var to := _cell(route[i + 1]) + Vector2(0, 11)
			for k in 4:
				_oval(from.lerp(to, (k + 1) / 5.0), Vector2(3, 2), Color("#f5e3ae"), 8)
	if state == &"damaged":
		var c := _cell(Vector2i(5, 2))
		draw_line(c + Vector2(-17, -39), c + Vector2(10, -9), Color("#f48f70"), 2.0)
	if state == &"dense":
		_ground_ring(_cell(Vector2i(4, 2)) + Vector2(0, 5), Color("#a5dbcf"), 22.0)

func _ground_ring(c: Vector2, color: Color, radius: float) -> void:
	for i in 24:
		var a := TAU * i / 24.0
		var b := TAU * (i + 1) / 24.0
		draw_line(c + Vector2(cos(a) * radius, sin(a) * radius * 0.4), c + Vector2(cos(b) * radius, sin(b) * radius * 0.4), color, 2.4)

func _oval(c: Vector2, radii: Vector2, color: Color, segments: int) -> void:
	var points := PackedVector2Array()
	for i in segments:
		var angle := TAU * i / float(segments)
		points.append(c + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
