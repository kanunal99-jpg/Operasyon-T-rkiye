extends CharacterBody3D

signal died
signal hit_player(amount: int)

var target: Node3D
var health := 100
var speed := 2.2
var attack_timer := 0.0
var attack_range := 12.0
var hit_flash_timer := 0.0
var body_mesh: MeshInstance3D

func _ready() -> void:
    body_mesh = MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    body_mesh.mesh = capsule
    body_mesh.position.y = 0.0
    add_child(body_mesh)

    var shape := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    shape.shape = capsule_shape
    add_child(shape)

func _physics_process(delta: float) -> void:
    if hit_flash_timer > 0.0:
        hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
        if hit_flash_timer == 0.0:
            body_mesh.modulate = Color.WHITE
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
