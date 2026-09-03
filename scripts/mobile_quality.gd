extends Node

# Lightweight runtime quality controller for Android/mobile builds.
# Keeps gameplay logic independent from device-specific tuning.
signal quality_changed(profile: String)

const LOW := "low"
const MEDIUM := "medium"
const HIGH := "high"

var profile := MEDIUM
var target_fps := 60
var max_visible_enemies := 8
var shadow_enabled := false
var environment_detail := 1.0

func _ready() -> void:
    if OS.has_feature("mobile"):
        profile = MEDIUM
    apply_profile(profile)

func apply_profile(value: String) -> void:
    profile = value
    match profile:
        LOW:
            target_fps = 30
            max_visible_enemies = 5
            shadow_enabled = false
            environment_detail = 0.55
        HIGH:
            target_fps = 60
            max_visible_enemies = 10
            shadow_enabled = true
            environment_detail = 1.0
        _:
            profile = MEDIUM
            target_fps = 60
            max_visible_enemies = 8
            shadow_enabled = false
            environment_detail = 0.75
    Engine.max_fps = target_fps
    quality_changed.emit(profile)

func get_profile() -> String:
    return profile

func get_enemy_budget() -> int:
    return max_visible_enemies

func get_environment_detail() -> float:
    return environment_detail

func should_use_shadows() -> bool:
    return shadow_enabled
