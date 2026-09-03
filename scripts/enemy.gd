extends CharacterBody3D

signal died

var target: Node3D
var health := 100
var speed := 2.2
var attack_timer := 0.0
var attack_range := 12.0

func _ready() -> void:
    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    mesh.mesh = capsule
    mesh.position.y = 0.0
    add_child(mesh)

    var shape := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    shape.shape = capsule_shape
    add_child(shape)

func _physics_process(delta: float) -> void:
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

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        died.emit()
        queue_free()
