extends CharacterBody3D

signal hud_changed(health: int, ammo: int, reserve: int)

var speed := 6.0
var gravity := 18.0
var health := 100
var ammo := 30
var reserve_ammo := 90
var fire_cooldown := 0.0
var touch_fire := false
var look_touch_id := -1
var look_last := Vector2.ZERO
var look_delta := Vector2.ZERO
var look_sensitivity := 0.004
var pitch := 0.0
var camera: Camera3D
var weapon: MeshInstance3D
var muzzle_flash: MeshInstance3D

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

    muzzle_flash = MeshInstance3D.new()
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.08
    flash_mesh.height = 0.16
    muzzle_flash.mesh = flash_mesh
    muzzle_flash.position = Vector3(0.35, -0.25, -1.08)
    muzzle_flash.visible = false
    camera.add_child(muzzle_flash)

    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    shape.shape = capsule
    shape.position.y = -0.1
    add_child(shape)
    _emit_hud()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _apply_look(event.relative)
    elif event is InputEventScreenTouch:
        if event.pressed and event.position.x > 430.0:
            look_touch_id = event.index
            look_last = event.position
        elif not event.pressed and event.index == look_touch_id:
            look_touch_id = -1
    elif event is InputEventScreenDrag and event.index == look_touch_id:
        var delta := event.position - look_last
        look_last = event.position
        _apply_look(delta)

func _apply_look(delta: Vector2) -> void:
    rotation.y -= delta.x * look_sensitivity
    pitch = clampf(pitch - delta.y * look_sensitivity, -1.35, 1.35)
    camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := Vector3(input_vec.x, 0, input_vec.y)
    direction = direction.rotated(Vector3.UP, rotation.y)
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
    if muzzle_flash.visible:
        muzzle_flash.visible = false

func shoot() -> void:
    if fire_cooldown > 0.0 or ammo <= 0:
        return
    ammo -= 1
    fire_cooldown = 0.12
    muzzle_flash.visible = true
    var from := camera.global_position
    var to := from + (-camera.global_transform.basis.z * 80.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.has("collider") and hit.collider.has_method("take_damage"):
        hit.collider.take_damage(34)
    _emit_hud()

func reload() -> void:
    if ammo >= 30 or reserve_ammo <= 0:
        return
    var needed := 30 - ammo
    var loaded := mini(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    _emit_hud()

func take_damage(amount: int) -> void:
    health -= amount
    _emit_hud()
    if health <= 0:
        health = 100
        ammo = 30
        reserve_ammo = 90
        global_position = Vector3(0, 1.2, 12)
        rotation = Vector3.ZERO
        pitch = 0.0
        camera.rotation = Vector3.ZERO
        _emit_hud()

func _emit_hud() -> void:
    hud_changed.emit(health, ammo, reserve_ammo)
