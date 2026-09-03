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

func configure_country(country_name: String) -> void:
    country = country_name

func _ready() -> void:
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
    material.albedo_color = _country_color(profile.uniform)
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
    return palette.get(uniform_id, Color("#56605a"))

func _physics_process(delta: float) -> void:
    if hit_flash_timer > 0.0:
        hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
        if hit_flash_timer == 0.0:
            _apply_country_look()
    if callout_timer > 0.0:
        callout_timer = maxf(0.0, callout_timer - delta)
    if not is_instance_valid(target):
        return
    attack_timer = maxf(0.0, attack_timer - delta)
    var offset := target.global_position - global_position
    offset.y = 0
    var distance := offset.length()
    if distance > 2.5:
        var direction := offset.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        look_at(global_position + direction, Vector3.UP)
        move_and_slide()
    else:
        velocity = Vector3.ZERO
    if distance <= attack_range and attack_timer <= 0.0:
        attack_timer = 1.0
        callout_timer = 1.5
        if target.has_method("take_damage"):
            target.take_damage(8)
            hit_player.emit(8)

func take_damage(amount: int) -> void:
    health -= amount
    hit_flash_timer = 0.08
    body_mesh.modulate = Color(1.0, 0.25, 0.25)
    if health <= 0:
        died.emit()
        queue_free()
