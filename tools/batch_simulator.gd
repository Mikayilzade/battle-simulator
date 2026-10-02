extends SceneTree

const PRESET_PATHS := [
	"res://data/forces/guard_guard.tres", "res://data/forces/striker_striker.tres",
	"res://data/forces/archer_archer.tres", "res://data/forces/guard_archer.tres",
	"res://data/forces/striker_archer.tres"
]

func _initialize() -> void:
	var options := _options(OS.get_cmdline_user_args())
	var count := int(options.get("count", "200"))
	var seed_start := int(options.get("seed-start", "1"))
	var replay_every := int(options.get("replay-every", "200"))
	var output_path := str(options.get("output", "reports/batch.json"))
	if count <= 0 or replay_every <= 0:
		push_error("--count and --replay-every must be positive")
		quit(1)
		return
	var maps: Array[BattleMapDef] = [load("res://data/maps/open_field.tres"), load("res://data/maps/broken_pass.tres")]
	var units: Array[UnitTypeDef] = [load("res://data/unit_types/guard.tres"), load("res://data/unit_types/striker.tres"), load("res://data/unit_types/archer.tres")]
	var terrains: Array[TerrainDef] = [load("res://data/terrain/plain.tres"), load("res://data/terrain/rough.tres"), load("res://data/terrain/blocked.tres")]
	var presets: Array[ForcePresetDef] = []
	for path in PRESET_PATHS:
		presets.append(load(path))
	var balance: BattleBalanceDef = load("res://data/balance/default.tres")
	var blue_policy: AiPolicyDef = load(str(options.get("blue-policy", "res://ai/default_policy.tres")))
	var red_policy: AiPolicyDef = load(str(options.get("red-policy", "res://ai/default_policy.tres")))
	if blue_policy == null or red_policy == null:
		push_error("policy resource could not be loaded")
		quit(1)
		return
	var balances: Array[BattleBalanceDef] = [balance]
	var catalog_errors := BattleValidator.validate_definitions(units, terrains, maps, balances, presets)
	if not catalog_errors.is_empty():
		push_error("invalid authored catalog: %s" % catalog_errors)
		quit(1)
		return
	var summary := _empty_summary(count, seed_start, blue_policy.id, red_policy.id)
	var started := Time.get_ticks_msec()
	var seed_block := 0
	while summary["battles"] < count:
		var seed := seed_start + seed_block
		for map_def in maps:
			for blue_preset in presets:
				for red_preset in presets:
					for mirrored in [false, true]:
						for first_side in [&"blue", &"red"]:
							if summary["battles"] >= count:
								break
							var setup := HeadlessBattle.create_setup(map_def, balance, units, blue_preset, red_preset, seed, first_side, mirrored)
							var check_replay: bool = summary["battles"] % replay_every == 0
							var result := HeadlessBattle.run(setup, map_def, balance, units, terrains, blue_policy, red_policy, check_replay)
							if not result["ok"]:
								push_error("battle %d failed (%s, %s vs %s, mirror=%s, first=%s, seed=%d): %s" % [summary["battles"], map_def.id, blue_preset.id, red_preset.id, mirrored, first_side, seed, result["error"]])
								quit(1)
								return
							_accumulate(summary, result["metrics"], map_def.id, blue_preset.id, red_preset.id, mirrored, first_side)
							if check_replay:
								summary["replays_checked"] += 1
							if summary["battles"] % 1000 == 0:
								print("Completed %d/%d battles" % [summary["battles"], count])
		seed_block += 1
	summary["runtime_seconds"] = snappedf(float(Time.get_ticks_msec() - started) / 1000.0, 0.001)
	if not _write_output(output_path, summary):
		quit(1)
		return
	print("Battles: %d; blue=%d red=%d draw=%d; first-side wins=%d; timeouts=%d; replay checks=%d; runtime=%.3fs" % [summary["battles"], summary["wins"]["blue"], summary["wins"]["red"], summary["wins"]["draw"], summary["first_side_wins"], summary["timeouts"], summary["replays_checked"], summary["runtime_seconds"]])
	print("Output: %s" % output_path)
	quit(0)

func _options(args: PackedStringArray) -> Dictionary:
	var result := {}
	for arg in args:
		if arg.begins_with("--") and arg.contains("="):
			var parts := arg.substr(2).split("=", false, 1)
			result[parts[0]] = parts[1]
	return result

func _empty_summary(requested: int, seed_start: int, blue_policy: StringName, red_policy: StringName) -> Dictionary:
	return {
		"requested": requested, "seed_start": seed_start, "matrix_strata": 200,
		"maps": ["open_field", "broken_pass"],
		"presets": ["guard_guard", "striker_striker", "archer_archer", "guard_archer", "striker_archer"],
		"blue_policy": str(blue_policy), "red_policy": str(red_policy), "battles": 0,
		"wins": {"blue": 0, "red": 0, "draw": 0}, "first_side_wins": 0, "decisive_battles": 0,
		"rounds_sum": 0, "activations_sum": 0, "timeouts": 0, "replays_checked": 0,
		"invalid_command_failures": 0, "invariant_failures": 0, "replay_failures": 0,
		"remaining": {"blue": {"hp": 0, "members": 0, "commanders": 0}, "red": {"hp": 0, "members": 0, "commanders": 0}},
		"damage_by_type": {"guard": 0, "striker": 0, "archer": 0},
		"kills_by_type": {"guard": 0, "striker": 0, "archer": 0},
		"action_counts": {"MOVE": 0, "ATTACK": 0, "GUARD": 0, "SET_FRONT": 0, "PASS": 0},
		"wasted_actions": 0, "strata": {}, "runtime_seconds": 0.0
	}

func _accumulate(summary: Dictionary, metrics: Dictionary, map_id: StringName, blue_preset: StringName, red_preset: StringName, mirrored: bool, first_side: StringName) -> void:
	summary["battles"] += 1
	summary["wins"][metrics["outcome"]] += 1
	if metrics["outcome"] != "draw":
		summary["decisive_battles"] += 1
		if metrics["first_side_win"]:
			summary["first_side_wins"] += 1
	summary["rounds_sum"] += metrics["rounds"]
	summary["activations_sum"] += metrics["activations"]
	summary["timeouts"] += int(metrics["timeout"])
	summary["wasted_actions"] += metrics["wasted_actions"]
	for key in ["invalid_command_failures", "invariant_failures", "replay_failures"]:
		summary[key] += metrics[key]
	for key in ["damage_by_type", "kills_by_type", "action_counts"]:
		for subkey in metrics[key]:
			summary[key][subkey] += metrics[key][subkey]
	for side_id in ["blue", "red"]:
		for key in ["hp", "members", "commanders"]:
			summary["remaining"][side_id][key] += metrics["remaining"][side_id][key]
	var stratum := "%s|%s|%s|mirror=%s|first=%s" % [map_id, blue_preset, red_preset, mirrored, first_side]
	if not summary["strata"].has(stratum):
		summary["strata"][stratum] = {"battles": 0, "blue": 0, "red": 0, "draw": 0, "rounds_sum": 0}
	summary["strata"][stratum]["battles"] += 1
	summary["strata"][stratum][metrics["outcome"]] += 1
	summary["strata"][stratum]["rounds_sum"] += metrics["rounds"]

func _write_output(path: String, summary: Dictionary) -> bool:
	var absolute := path if path.is_absolute_path() else ProjectSettings.globalize_path("res://" + path)
	var folder := absolute.get_base_dir()
	var error := DirAccess.make_dir_recursive_absolute(folder)
	if error != OK:
		push_error("could not create output directory: %s" % folder)
		return false
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		push_error("could not write output: %s" % absolute)
		return false
	file.store_string(JSON.stringify(summary, "  "))
	return true
