class_name AiPolicyDef
extends Resource

@export var id: StringName = &"baseline"
@export var lethal_score: int = 7000
@export var attack_score: int = 6000
@export var enabling_move_score: int = 4000
@export var progress_move_score: int = 3000
@export var guard_score: int = 2000
@export var set_front_score: int = 1000
@export var damage_weight: int = 10
@export var commander_damage_bonus: int = 1
@export var move_progress_weight: int = 10
@export var exposure_penalty: int = 2
@export var front_improvement_threshold: int = 3
