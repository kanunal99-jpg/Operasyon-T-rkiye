extends Node3D

signal environment_changed(time_phase: String, weather: String)

const DAY := "GÜNDÜZ"
const DUSK := "AKŞAM"
const NIGHT := "GECE"
const RAIN := "YAĞMUR"
const FOG := "SİS"
const CLEAR := "AÇIK"
const SNOW := "KAR"

var phase := DAY
var weather := CLEAR
var elapsed := 0.0
var cycle_seconds := 360.0
var world_environment: WorldEnvironment
var environment: Environment
var sun: DirectionalLight3D
var weather_particles: GPUParticles3D

func setup(theme: String, seed_value: int) -> void:
    _choose_conditions(theme, seed_value)
    _build_environment()
    _apply_conditions()

func _process(delta: float) -> void:
    elapsed = fmod(elapsed + delta, cycle_seconds)
    var previous := phase
    var ratio := elapsed / cycle_seconds
    if ratio < 0.58:
        phase = DAY
    elif ratio < 0.68:
        phase = DUSK
    else:
        phase = NIGHT
    _apply_lighting()
    if phase != previous:
        environment_changed.emit(phase, weather)

func _choose_conditions(theme: String, seed_value: int) -> void:
    var roll := absi(seed_value) % 100
    if theme == "snow":
        weather = SNOW if roll < 70 else FOG
    elif theme == "coastal":
        weather = RAIN if roll < 30 else (FOG if roll < 48 else CLEAR)
    elif theme == "desert":
        weather = FOG if roll < 18 else CLEAR
    else:
        weather = RAIN if roll < 20 else (FOG if roll < 35 else CLEAR)

func _build_environment() -> void:
    world_environment = WorldEnvironment.new()
    environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world_environment.environment = environment
    add_child(world_environment)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.shadow_enabled = false
    add_child(sun)

func _apply_conditions() -> void:
    if environment == null or sun == null:
        return
    environment.background_color = Color("#202832")
    environment.ambient_light_color = Color("#aebdca")
    environment.ambient_light_energy = 0.8
    environment.fog_enabled = weather == FOG or phase == NIGHT
    environment.fog_light_color = Color("#6f7a82")
    environment.fog_light_energy = 0.45
    environment.fog_density = 0.012 if weather == FOG else (0.006 if phase == NIGHT else 0.0)
    if weather == RAIN:
        environment.ambient_light_energy = 0.65
    elif weather == SNOW:
        environment.ambient_light_color = Color("#c9d2d8")
        environment.ambient_light_energy = 0.9
    _apply_lighting()

func _apply_lighting() -> void:
    if sun == null or environment == null:
        return
    var ratio := elapsed / cycle_seconds
    var daylight := clampf((sin(ratio * TAU - PI * 0.5) + 1.0) * 0.5, 0.05, 1.0)
    if phase == NIGHT:
        sun.light_energy = 0.12
        environment.ambient_light_energy = 0.22
        environment.background_color = Color("#080d16")
    elif phase == DUSK:
        sun.light_energy = 0.45
        environment.ambient_light_energy = 0.48
        environment.background_color = Color("#3a3030")
    else:
        sun.light_energy = 0.75 + daylight * 0.45
        if weather == RAIN:
            sun.light_energy *= 0.72
        environment.ambient_light_energy = 0.65 + daylight * 0.2

func get_time_phase() -> String:
    return phase

func get_weather() -> String:
    return weather

func get_status_text() -> String:
    return "%s • %s" % [phase, weather]
