extends Control

signal exit_requested(config: Dictionary)

const SECTIONS := ["PACKS", "TERRAIN", "UNITS", "COMBINED PREVIEW", "SHORTLIST / ARCHIVE"]
const STATES: Array[StringName] = [&"normal", &"selected", &"reachable", &"target", &"route", &"damaged", &"dense"]
const LEVELS: Array[StringName] = [&"low", &"medium", &"high"]
const SCALES: Array[StringName] = [&"small", &"medium", &"large"]
const ANGLES: Array[StringName] = [&"top", &"balanced", &"strong"]

var catalog: VisualLabCatalog
var packs: VisualPackCatalog
var selection: VisualLabSelection
var return_config: Dictionary = {}
var tabs: TabBar
var list: VBoxContainer
var preview: IsometricDiorama
var caption: Label
var terrain_filter: StringName = &"plain"
var role_filter: StringName = &"guard"
var unit_pack_filter: StringName = &"PACK-25D-A"
var site_filter: StringName = &"lumber"

func _ready() -> void:
	catalog = VisualLabCatalog.load_catalog()
	packs = VisualPackCatalog.load_catalog()
	if selection == null:
		selection = VisualLabSelection.new()
	selection.ensure_pack_defaults(catalog, packs)
	_build()
	_refresh()

func configure(value: Dictionary, session: VisualLabSelection) -> void:
	return_config = value.duplicate(true)
	selection = session
	if is_node_ready():
		selection.ensure_pack_defaults(catalog, packs)
		_refresh()

func select_pack(id: StringName) -> bool:
	if not selection.select_pack(id, catalog, packs):
		return false
	unit_pack_filter = id
	_refresh()
	return true

func select_variant(id: StringName) -> bool:
	var variant := catalog.get_variant(id)
	if variant == null:
		return false
	selection.select(variant)
	_refresh()
	return true

func mark_variant(id: StringName, status: String) -> bool:
	if catalog.get_variant(id) == null and packs.get_pack(id) == null:
		return false
	selection.set_status(id, status)
	_refresh()
	return true

func set_preview_state(state: StringName) -> void:
	if state in STATES:
		selection.preview_state = state
		_refresh()

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("#17291f")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_right = -16
	root.offset_top = 10
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := _label("ISOMETRIC FANTASY  /  VISUAL LAB", 24, Color("#f4e7c6"))
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	var back := Button.new()
	back.text = "←  SETUP"
	back.custom_minimum_size = Vector2(115, 36)
	back.pressed.connect(func() -> void: exit_requested.emit(return_config.duplicate(true)))
	header.add_child(back)
	root.add_child(_label("Four original 2.5D directions. Select, compare, shortlist; battle rules stay untouched.", 13, Color("#b6c4b3")))
	tabs = TabBar.new()
	for section in SECTIONS:
		tabs.add_tab(section)
	tabs.tab_changed.connect(func(_index: int) -> void: _refresh_list())
	root.add_child(tabs)
	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.name = "CatalogScroll"
	scroll.custom_minimum_size.x = 335
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	scroll.add_child(list)
	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = SIZE_EXPAND_FILL
	stage.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(stage)
	caption = _label("", 14, Color("#efdaaa"))
	stage.add_child(caption)
	preview = IsometricDiorama.new()
	preview.custom_minimum_size = Vector2(785, 500)
	preview.size_flags_horizontal = SIZE_EXPAND_FILL
	preview.size_flags_vertical = SIZE_EXPAND_FILL
	stage.add_child(preview)
	stage.add_child(_label("Blue pennant / Red standard  •  terrain-first overlays  •  sample scene only", 12, Color("#b9c8b8")))

func _refresh() -> void:
	if preview == null:
		return
	preview.configure(catalog, packs, selection)
	var pack := packs.get_pack(selection.pack_id)
	caption.text = "%s   •   %s   •   %s" % [pack.id, pack.display_name, str(selection.preview_state).capitalize()]
	_refresh_list()

func _refresh_list() -> void:
	if list == null:
		return
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	match tabs.current_tab:
		0: _fill_packs()
		1: _fill_terrain()
		2: _fill_units()
		3: _fill_combined()
		4: _fill_shortlist()

func _fill_packs() -> void:
	list.add_child(_label("COHERENT WORLD PACKS", 16, Color("#f0dbaa")))
	list.add_child(_label("One choice swaps terrain, units and work sites together.", 12, Color("#c0cbb8")))
	for pack in packs.packs:
		_pack_card(pack)

func _fill_terrain() -> void:
	list.add_child(_label("TERRAIN & WORK SITES", 16, Color("#f0dbaa")))
	var subjects: Array[StringName] = VisualLabCatalog.FAMILIES.duplicate()
	subjects.append_array([&"lumber", &"farm"])
	var filter := _picker("Subject", subjects, terrain_filter)
	filter.item_selected.connect(func(index: int) -> void:
		terrain_filter = subjects[index]
		_refresh_list())
	list.add_child(filter)
	if terrain_filter in [&"lumber", &"farm"]:
		for variant in catalog.variants_for("improvement", terrain_filter):
			_variant_card(variant)
	else:
		for variant in catalog.variants_for("terrain", terrain_filter):
			if not variant.pack_id.is_empty():
				_variant_card(variant)

func _fill_units() -> void:
	list.add_child(_label("LITTLE PEOPLE / FORMATIONS", 16, Color("#f0dbaa")))
	var roles: Array[StringName] = [&"guard", &"striker", &"archer", &"commander"]
	var role_picker := _picker("Role", roles, role_filter)
	role_picker.item_selected.connect(func(index: int) -> void:
		role_filter = roles[index]
		_refresh_list())
	list.add_child(role_picker)
	if role_filter == &"commander":
		for cue in catalog.variants_for("commander"):
			_variant_card(cue)
		return
	var pack_ids := VisualPackCatalog.REQUIRED_IDS.duplicate()
	var pack_picker := _picker("Pack", pack_ids, unit_pack_filter)
	pack_picker.item_selected.connect(func(index: int) -> void:
		unit_pack_filter = pack_ids[index]
		_refresh_list())
	list.add_child(pack_picker)
	for variant in catalog.variants_for_pack("unit", unit_pack_filter, role_filter):
		_variant_card(variant)

func _fill_combined() -> void:
	list.add_child(_label("COMBINED DIORAMA", 16, Color("#f0dbaa")))
	list.add_child(_label("Swap a complete pack, or mix one terrain, site or unit at a time.", 12, Color("#c0cbb8")))
	if terrain_filter not in VisualLabCatalog.FAMILIES:
		terrain_filter = &"plain"
	var pack_ids := VisualPackCatalog.REQUIRED_IDS.duplicate()
	var pack_picker := _picker("World pack", pack_ids, selection.pack_id)
	pack_picker.item_selected.connect(func(index: int) -> void: select_pack(pack_ids[index]))
	list.add_child(pack_picker)
	var family_picker := _picker("Terrain family", VisualLabCatalog.FAMILIES, terrain_filter)
	family_picker.item_selected.connect(func(index: int) -> void:
		terrain_filter = VisualLabCatalog.FAMILIES[index]
		_refresh_list())
	list.add_child(family_picker)
	_add_variant_picker("Terrain visual", catalog.variants_for("terrain", terrain_filter), selection.terrain_ids.get(terrain_filter, &""), true)
	var roles: Array[StringName] = VisualLabCatalog.ROLES.duplicate()
	var role_picker := _picker("Unit role", roles, role_filter if role_filter in roles else &"guard")
	role_picker.item_selected.connect(func(index: int) -> void:
		role_filter = roles[index]
		_refresh_list())
	list.add_child(role_picker)
	var active_role := role_filter if role_filter in roles else &"guard"
	_add_variant_picker("Unit visual", catalog.variants_for("unit", active_role), selection.unit_ids.get(active_role, &""), true)
	var sites: Array[StringName] = [&"lumber", &"farm"]
	var site_picker := _picker("Work site", sites, site_filter)
	site_picker.item_selected.connect(func(index: int) -> void:
		site_filter = sites[index]
		_refresh_list())
	list.add_child(site_picker)
	_add_variant_picker("Site visual", catalog.variants_for("improvement", site_filter), selection.improvement_ids.get(site_filter, &""), false)
	_add_variant_picker("Commander cue", catalog.variants_for("commander"), selection.commander_id, false)
	_add_setting_picker("Preview state", STATES, selection.preview_state, "state")
	_add_setting_picker("Detail density", LEVELS, selection.detail_level, "detail")
	_add_setting_picker("Unit scale", SCALES, selection.unit_scale, "scale")
	_add_setting_picker("Camera angle", ANGLES, selection.camera_angle, "angle")

func _add_variant_picker(title: String, items: Array[VisualVariantDef], chosen: StringName, packed_only: bool) -> void:
	var choices: Array[VisualVariantDef] = []
	for variant in items:
		if not packed_only or not variant.pack_id.is_empty():
			choices.append(variant)
	list.add_child(_label(title, 12, Color("#e4d9ba")))
	var picker := OptionButton.new()
	for i in choices.size():
		picker.add_item("%s  |  %s" % [choices[i].id, choices[i].display_name])
		if choices[i].id == chosen:
			picker.select(i)
	picker.item_selected.connect(func(index: int) -> void: select_variant(choices[index].id))
	list.add_child(picker)

func _add_setting_picker(title: String, choices: Array[StringName], chosen: StringName, kind: String) -> void:
	var picker := _picker(title, choices, chosen)
	picker.item_selected.connect(func(index: int) -> void:
		match kind:
			"state": selection.preview_state = choices[index]
			"detail": selection.detail_level = choices[index]
			"scale": selection.unit_scale = choices[index]
			"angle": selection.camera_angle = choices[index]
		_refresh())
	list.add_child(picker)

func _fill_shortlist() -> void:
	for status in [VisualLabSelection.FAVORITE, VisualLabSelection.ARCHIVE]:
		list.add_child(_label("SHORTLIST" if status == VisualLabSelection.FAVORITE else "ARCHIVE", 16, Color("#f0dbaa")))
		var count := 0
		for pack in packs.packs:
			if selection.status_of(pack.id) == status:
				_pack_card(pack)
				count += 1
		for variant in catalog.variants:
			if selection.status_of(variant.id) == status:
				_variant_card(variant)
				count += 1
		if count == 0:
			list.add_child(_label("Nothing marked yet", 12, Color("#aebba9")))

func _pack_card(pack: VisualPackDef) -> void:
	var card := _card(pack.id == selection.pack_id)
	list.add_child(card)
	var column := VBoxContainer.new()
	card.add_child(column)
	column.add_child(_label(str(pack.id), 12, Color("#d2d8bd")))
	column.add_child(_label(pack.display_name, 16, Color("#f4e5c3")))
	column.add_child(_label(pack.description, 12, Color("#c4cdbb")))
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var pick := Button.new()
	pick.text = "Selected" if pack.id == selection.pack_id else "Preview pack"
	pick.disabled = pack.id == selection.pack_id
	pick.pressed.connect(select_pack.bind(pack.id))
	actions.add_child(pick)
	_status_buttons(actions, pack.id)

func _variant_card(variant: VisualVariantDef) -> void:
	var card := _card(selection.is_selected(variant))
	list.add_child(card)
	var column := VBoxContainer.new()
	card.add_child(column)
	column.add_child(_label(str(variant.id), 11, Color("#d2d8bd")))
	column.add_child(_label(variant.display_name, 15, Color("#f4e5c3")))
	column.add_child(_label(variant.description, 12, Color("#c4cdbb")))
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var pick := Button.new()
	pick.text = "Selected" if selection.is_selected(variant) else "Preview"
	pick.disabled = selection.is_selected(variant)
	pick.pressed.connect(select_variant.bind(variant.id))
	actions.add_child(pick)
	_status_buttons(actions, variant.id)

func _status_buttons(row: HBoxContainer, id: StringName) -> void:
	var favorite := Button.new()
	favorite.text = "★" if selection.status_of(id) == VisualLabSelection.FAVORITE else "☆"
	favorite.tooltip_text = "Shortlist / remove from shortlist"
	favorite.pressed.connect(func() -> void:
		mark_variant(id, VisualLabSelection.NEUTRAL if selection.status_of(id) == VisualLabSelection.FAVORITE else VisualLabSelection.FAVORITE))
	row.add_child(favorite)
	var archive := Button.new()
	archive.text = "Restore" if selection.status_of(id) == VisualLabSelection.ARCHIVE else "Archive"
	archive.pressed.connect(func() -> void:
		mark_variant(id, VisualLabSelection.NEUTRAL if selection.status_of(id) == VisualLabSelection.ARCHIVE else VisualLabSelection.ARCHIVE))
	row.add_child(archive)

func _picker(title: String, choices: Array[StringName], current: StringName) -> OptionButton:
	list.add_child(_label(title, 12, Color("#e4d9ba")))
	var picker := OptionButton.new()
	for i in choices.size():
		picker.add_item(str(choices[i]).capitalize())
		if choices[i] == current:
			picker.select(i)
	return picker

func _card(selected: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3e5541") if selected else Color("#2b3d32")
	style.border_color = Color("#cfbb81") if selected else Color("#5a6d52")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(7)
	card.add_theme_stylebox_override("panel", style)
	return card

func _label(value: String, size_value: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
