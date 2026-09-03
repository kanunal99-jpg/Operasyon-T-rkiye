extends CharacterBody3D

var speed := 6.0
var gravity := 18.0
var health := 100
var ammo := 30
var reserve_ammo := 90
var fire_cooldown := 0.0
var touch_fire := false
var camera: Camera3D
var weapon: MeshInstance3D

func _ready() -> void:
    camera = Camera3D.new()
    camera.position = Vector3(0, 0.65, 0)
    camera.current = true
    add_child(camera)

    weapon = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.18, 0.18, 0.9)
    weapon.mesh = mesh
    weapon.position = Vector3(0.35, -0.25, -0.65)
    camera.add_child(weapon)

    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    shape.shape = capsule
    shape.position.y = -0.1
    add_child(shape)

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := Vector3(input_vec.x, 0, input_vec.y)
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0
    move_and_slide()
    if Input.is_action_pressed("fire") or touch_fire:
        shoot()
    if Input.is_action_just_pressed("reload"):
        reload()

func shoot() -> void:
    if fire_cooldown > 0.0 or ammo <= 0:
        return
    ammo -= 1
    fire_cooldown = 0.12
    var from := camera.global_position
    var to := from + (-camera.global_transform.basis.z * 80.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.has("collider") and hit.collider.has_method("take_damage"):
        hit.collider.take_damage(34)

func reload() -> void:
    if ammo >= 30 or reserve_ammo <= 0:
        return
    var needed := 30 - ammo
    var loaded := mini(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        health = 100
        ammo = 30
        global_position = Vector3(0, 1.2, 12)
