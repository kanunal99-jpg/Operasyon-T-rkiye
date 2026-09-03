extends CharacterBody3D

signal died
signal hit_player(amount: int)

const CountryProfile = preload("res://scripts/country_profile.gd")

var target: Node3D
var health := 100
var speed := 2.2
var attack_timer := 0.0
var attack_range := 12.0
var hit_flash_timer := 0.0
var body_mesh: MeshInstance3D
var country := "Türkiye"
var callout_timer := 0.0
var callout_text := ""
var spawn_position := Vector3.ZERO
var patrol_phase := 0.0
var state := "PATROL"

func configure_country(country_name: String) -> void:
    country = country_name
    if is_instance_valid(body_mesh): _apply_country_look()

func apply_support_bonus(damage_multiplier: float = 1.0, intelligence_bonus: int = 0) -> void:
    # Allied intelligence makes enemies slightly less durable while keeping
    # the mobile prototype balanced. Values are gameplay abstractions.
    health = maxi(50, int(round(health / maxf(1.0, damage_multiplier))))
    speed = maxf(1.5, speed - float(intelligence_bonus) * 0.003)

func _ready() -> void:
    spawn_position = global_position
    patrol_phase = float(get_instance_id() % 100) * 0.1
    body_mesh = MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    body_mesh.mesh = capsule
    body_mesh.position.y = 0.0
    add_child(body_mesh)
    _apply_country_look()
    var shape := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    shape.shape = capsule_shape
    add_child(shape)

func _apply_country_look() -> void:
    var profile := CountryProfile.get_profile(country)
    var material := StandardMaterial3D.new()
    material.albedo_color = _country_color(str(profile.get("uniform", "generic_modern")))
    material.roughness = 0.78
    body_mesh.material_override = material
    callout_text = CountryProfile.get_callout(country, "contact")

func _country_color(uniform_id: String) -> Color:
    var palette := {
        "modern_turkish": Color("#53634f"), "modern_greek": Color("#536b73"),
        "modern_bulgarian": Color("#596456"), "modern_german": Color("#3f464b"),
        "modern_french": Color("#3d4c5f"), "modern_italian": Color("#536052"),
        "modern_spanish": Color("#665f4d"), "modern_british": Color("#4b5563"),
        "modern_us": Color("#4f5d4b"), "modern_canadian": Color("#55624e"),
        "modern_mexican": Color("#53604c"), "modern_brazilian": Color("#53634f"),
        "modern_argentine": Color("#58646a"), "modern_egyptian": Color("#6b634f"),
        "modern_moroccan": Color("#655d4d"), "modern_south_african": Color("#4d5d4f"),
        "modern_saudi": Color("#4f5c50"), "modern_uae": Color("#4f5d53"),
        "modern_iranian": Color("#4d5b4f"), "modern_iraqi": Color("#5d604d"),
        "modern_indian": Color("#53624e"), "modern_pakistani": Color("#4e624f"),
        "modern_chinese": Color("#4b5552"), "modern_japanese": Color("#4e575c"),
        "modern_south_korean": Color("#4e5a62"), "modern_indonesian": Color("#53614f"),
        "modern_australian": Color("#56624f"), "modern_new_zealand": Color("#505c54")
    }
    if palette.has(uniform_id): return palette[uniform_id]
    # Stable per-country fallback prevents every unprofiled nation from looking identical.
    var hash_value := absi(hash(uniform_id))
    var shade := 0.28 + float(hash_value % 35) / 100.0
    return Color(shade, shade + 0.03, shade - 0.01)

func _physics_process(delta: float) -> void:
    if hit_flash_timer > 0.0:
        hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
        if hit_flash_timer == 0.0: _apply_country_look()
    if callout_timer > 0.0: callout_timer = maxf(0.0, callout_timer - delta)
    if not is_instance_valid(target): return

    attack_timer = maxf(0.0, attack_timer - delta)
    var offset := target.global_position - global_position
    offset.y = 0
    var distance := offset.length()
    if distance <= 16.0:
        state = "ATTACK" if distance <= attack_range else "CHASE"
    else:
        state = "PATROL"

    if state == "PATROL":
        patrol_phase += delta * 0.55
        var patrol_target := spawn_position + Vector3(cos(patrol_phase) * 3.5, 0, sin(patrol_phase) * 3.5)
        _move_toward(patrol_target, speed * 0.45)
    elif state == "CHASE":
        _move_toward(target.global_position, speed)
    else:
        velocity = Vector3.ZERO
        look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
        if attack_timer <= 0.0:
            attack_timer = 1.0
            callout_timer = 1.5
            if target.has_method("take_damage"):
                target.take_damage(8)
                hit_player.emit(8)

func _move_toward(destination: Vector3, move_speed: float) -> void:
    var offset := destination - global_position
    offset.y = 0
    if offset.length() > 0.8:
        var direction := offset.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        look_at(global_position + direction, Vector3.UP)
        move_and_slide()
    else:
        velocity = Vector3.ZERO

func take_damage(amount: int) -> void:
    health -= amount
    hit_flash_timer = 0.08
    body_mesh.modulate = Color(1.0, 0.25, 0.25)
    if health <= 0:
        died.emit()
        queue_free()
