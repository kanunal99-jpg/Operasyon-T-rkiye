extends CharacterBody3D

# Lightweight fictional combat-support actor. Uses procedural primitives so
# the system stays asset-free and mobile-friendly.
signal support_hit(amount: int)

var role := "ARMOR"
var country := "Türkiye"
var target: Node3D
var speed := 5.0
var health := 180
var cooldown := 0.0
var lifetime := 18.0
var mesh_root: Node3D

func configure(vehicle_role: String, country_name: String, target_node: Node3D) -> void:
    role = vehicle_role
    country = country_name
    target = target_node
    speed = 10.0 if role == "AIR" else 4.5
    health = 120 if role == "AIR" else 180

func _ready() -> void:
    mesh_root = Node3D.new()
    add_child(mesh_root)
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    if role == "ARMOR":
        box.size = Vector3(2.8, 1.0, 4.0)
    elif role == "AIR":
        box.size = Vector3(1.4, 0.35, 3.2)
    else:
        box.size = Vector3(2.0, 0.6, 3.0)
    body.mesh = box
    mesh_root.add_child(body)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#46534a") if role == "ARMOR" else Color("#56616b")
    body.material_override = mat
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    add_child(collision)

func _physics_process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()
        return
    if not is_instance_valid(target): return
    if role == "AIR":
        global_position += Vector3(0, 0.0, -speed) * delta
        rotate_y(delta * 0.7)
    else:
        var offset := target.global_position - global_position
        offset.y = 0
        if offset.length() > 8.0:
            velocity = offset.normalized() * speed
            move_and_slide()
            look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
    if cooldown <= 0.0 and global_position.distance_to(target.global_position) < (35.0 if role == "AIR" else 18.0):
        cooldown = 2.0 if role == "AIR" else 1.4
        if target.has_method("take_damage"):
            var amount := 12 if role == "AIR" else 18
            target.take_damage(amount)
            support_hit.emit(amount)
