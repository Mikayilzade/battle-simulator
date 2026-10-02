extends Control

signal exit_requested(config: Dictionary)

const TAB_NAMES := ["Field Styles", "Terrain Library", "Unit Styles", "Combined Preview", "Shortlist / Archive"]

var catalog: VisualLabCatalog
var selection: VisualLabSelection
var return_config: Dictionary = {}
var tabs: TabContainer
var preview: VisualLabPreview
var caption: Label
var terrain_filter: StringName = &"plain"
var unit_filter: StringName = &"guard"

func _ready() -> void:
	catalog = VisualLabCatalog.load_catalog()
	if selection == null:
		selection = VisualLabSelection.new()
	selection.ensure_defaults(catalog)
	_build()
	_refresh()

func configure(value: Dictionary, session: VisualLabSelection) -> void:
	return_config = value.duplicate(true)
	selection = session
	if is_node_ready():
		selection.ensure_defaults(catalog)
		_refresh()

func select_variant(id: StringName) -> bool:
	var variant := catalog.get_variant(id)
	if variant == null:
		return false
	selection.select(variant)
	_refresh()
	return true

func mark_variant(id: StringName, status: String) -> bool:
	if catalog.get_variant(id) == null:
		return false
	selection.set_status(id, status)
	_refresh()
	return true

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("#101d1f")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 12
	root.offset_bottom = -14
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var heading := _label("VISUAL STYLE LAB", 26, Color("#f4e9d2"))
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(heading)
	var back := Button.new()
	back.text = "←  Return to Setup"
	back.custom_minimum_size = Vector2(170, 42)
	back.pressed.connect(func() -> void: exit_requested.emit(return_config.duplicate(true)))
	header.add_child(back)
	var note := _label("Compare original procedural directions. Preview is a sample, independent of battle state.", 14, Color("#a9b9aa"))
	root.add_child(note)
	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	tabs = TabContainer.new()
	tabs.custom_minimum_size.x = 445
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(tabs)
	for name in TAB_NAMES:
		var scroll := ScrollContainer.new()
		scroll.name = name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(right)
	caption = _label("", 15, Color("#f1dfad"))
	right.add_child(caption)
	preview = VisualLabPreview.new()
	preview.size_flags_horizontal = SIZE_EXPAND_FILL
	preview.size_flags_vertical = SIZE_EXPAND_FILL
	preview.custom_minimum_size = Vector2(650, 475)
	right.add_child(preview)
	var legend := _label("Blue triangle / Red banner   •   gold selected   •   cyan reachable   •   red target", 13, Color("#aabdb9"))
	right.add_child(legend)

func _refresh() -> void:
	if tabs == null:
		return
	for index in TAB_NAMES.size():
		var scroll := tabs.get_child(index) as ScrollContainer
		for child in scroll.get_children():
			scroll.remove_child(child)
			child.queue_free()
		var list := VBoxContainer.new()
		list.size_flags_horizontal = SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 8)
		scroll.add_child(list)
		match index:
			0: _fill_variants(list, catalog.variants_for("field"))
			1: _fill_terrain(list)
			2: _fill_units(list)
			3: _fill_combined(list)
			4: _fill_shortlist(list)
	preview.configure(catalog, selection)
	var chosen := catalog.get_variant(selection.field_id)
	caption.text = "%s  •  %s  •  %s" % [chosen.id, chosen.display_name, chosen.mode.to_upper()]

func _fill_terrain(list: VBoxContainer) -> void:
	list.add_child(_label("TERRAIN FAMILY", 15, Color("#e7d9b7")))
	var filter := OptionButton.new()
	for family in VisualLabCatalog.FAMILIES:
		filter.add_item(str(family).capitalize())
	filter.select(VisualLabCatalog.FAMILIES.find(terrain_filter))
	filter.item_selected.connect(func(index: int) -> void:
		terrain_filter = VisualLabCatalog.FAMILIES[index]
		_refresh())
	list.add_child(filter)
	_fill_variants(list, catalog.variants_for("terrain", terrain_filter))

func _fill_units(list: VBoxContainer) -> void:
	list.add_child(_label("UNIT ROLE", 15, Color("#e7d9b7")))
	var filter := OptionButton.new()
	for role in VisualLabCatalog.ROLES:
		filter.add_item(str(role).capitalize())
	filter.select(VisualLabCatalog.ROLES.find(unit_filter))
	filter.item_selected.connect(func(index: int) -> void:
		unit_filter = VisualLabCatalog.ROLES[index]
		_refresh())
	list.add_child(filter)
	_fill_variants(list, catalog.variants_for("unit", unit_filter))

func _fill_variants(list: VBoxContainer, items: Array[VisualVariantDef]) -> void:
	for variant in items:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _card_style(variant))
		list.add_child(panel)
		var column := VBoxContainer.new()
		panel.add_child(column)
		column.add_child(_label("%s  •  %s" % [variant.id, variant.mode.to_upper()], 12, Color("#bdc5b7")))
		column.add_child(_label(variant.display_name, 18, Color("#f6ead1")))
		column.add_child(_label(variant.description, 13, Color("#c0cabe")))
		var actions := HBoxContainer.new()
		column.add_child(actions)
		var pick := Button.new()
		pick.text = "Selected" if selection.is_selected(variant) else "Preview"
		pick.disabled = selection.is_selected(variant)
		pick.pressed.connect(select_variant.bind(variant.id))
		actions.add_child(pick)
		var favorite := Button.new()
		favorite.text = "★ Shortlisted" if selection.status_of(variant.id) == VisualLabSelection.FAVORITE else "☆ Shortlist"
		favorite.pressed.connect(func() -> void:
			mark_variant(variant.id, VisualLabSelection.NEUTRAL if selection.status_of(variant.id) == VisualLabSelection.FAVORITE else VisualLabSelection.FAVORITE))
		actions.add_child(favorite)
		var archive := Button.new()
		archive.text = "Restore" if selection.status_of(variant.id) == VisualLabSelection.ARCHIVE else "Archive"
		archive.pressed.connect(func() -> void:
			mark_variant(variant.id, VisualLabSelection.NEUTRAL if selection.status_of(variant.id) == VisualLabSelection.ARCHIVE else VisualLabSelection.ARCHIVE))
		actions.add_child(archive)

func _fill_combined(list: VBoxContainer) -> void:
	list.add_child(_label("MIX THE STAND", 17, Color("#f2dfab")))
	list.add_child(_label("Each selector changes the preview immediately. Archived choices remain available.", 13, Color("#b6c5bd")))
	_add_selector(list, "Field", catalog.variants_for("field"), selection.field_id)
	for family in VisualLabCatalog.FAMILIES:
		_add_selector(list, str(family).capitalize(), catalog.variants_for("terrain", family), selection.terrain_ids.get(family, &""))
	for role in VisualLabCatalog.ROLES:
		_add_selector(list, str(role).capitalize(), catalog.variants_for("unit", role), selection.unit_ids.get(role, &""))

func _add_selector(list: VBoxContainer, title: String, items: Array[VisualVariantDef], selected_id: StringName) -> void:
	list.add_child(_label(title, 13, Color("#d4d9be")))
	var picker := OptionButton.new()
	for i in items.size():
		picker.add_item("%s  |  %s" % [items[i].id, items[i].display_name])
		if items[i].id == selected_id:
			picker.select(i)
	picker.item_selected.connect(func(index: int) -> void: select_variant(items[index].id))
	list.add_child(picker)

func _fill_shortlist(list: VBoxContainer) -> void:
	for status in [VisualLabSelection.FAVORITE, VisualLabSelection.ARCHIVE]:
		list.add_child(_label("SHORTLIST" if status == VisualLabSelection.FAVORITE else "ARCHIVE", 17, Color("#f0dba7")))
		var items: Array[VisualVariantDef] = []
		for variant in catalog.variants:
			if selection.status_of(variant.id) == status:
				items.append(variant)
		if items.is_empty():
			list.add_child(_label("No variants yet", 13, Color("#9caaa1")))
		else:
			_fill_variants(list, items)

func _card_style(variant: VisualVariantDef) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#234238") if selection.is_selected(variant) else Color("#223231")
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
