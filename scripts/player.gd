extends CharacterBody3D

signal hud_changed(health: int, ammo: int, reserve: int)
signal weapon_changed(name: String)

const WeaponData = preload("res://scripts/weapon_data.gd")
const WEAPONS := WeaponData.WEAPONS

var speed := 6.0
var sprint_speed := 9.5
var crouch_speed := 3.2
var gravity := 18.0
var jump_velocity := 7.2
var health := 100
var weapon_name := "TAARRUZ TÜFEĞİ"
var ammo := 30
var reserve_ammo := 90
var fire_cooldown := 0.0
var touch_fire := false
var look_touch_id := -1
var look_last := Vector2.ZERO
var look_sensitivity := 0.004
var pitch := 0.0
var camera: Camera3D
var weapon: MeshInstance3D
var muzzle_flash: MeshInstance3D
var reload_timer := 0.0
var sprint_pressed := false
var crouch_pressed := false
var jump_pressed := false
var slide_timer := 0.0
var stand_height := 1.8
var crouch_height := 1.15
var current_height := 1.8

func _ready() -> void:
    camera = Camera3D.new()
    camera.position = Vector3(0, 0.65, 0)
    camera.current = true
    add_child(camera)
    _create_weapon_mesh()
    muzzle_flash = MeshInstance3D.new()
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.08
    flash_mesh.height = 0.16
    muzzle_flash.mesh = flash_mesh
    muzzle_flash.position = Vector3(0.35, -0.25, -1.08)
    muzzle_flash.visible = false
    camera.add_child(muzzle_flash)
    _create_collision()
    _create_mobile_movement_controls()
    _emit_hud()
    weapon_changed.emit(weapon_name)

func _create_collision() -> void:
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = stand_height
    shape.shape = capsule
    shape.position.y = -0.1
    shape.name = "PlayerCollision"
    add_child(shape)

func _create_weapon_mesh() -> void:
    weapon = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.18, 0.18, 0.9)
    weapon.mesh = mesh
    weapon.position = Vector3(0.35, -0.25, -0.65)
    camera.add_child(weapon)

func _create_mobile_movement_controls() -> void:
    var controls := CanvasLayer.new()
    controls.name = "MovementControls"
    controls.layer = 20
    add_child(controls)

    var sprint := Button.new()
    sprint.text = "KOŞ"
    sprint.position = Vector2(245, 515)
    sprint.size = Vector2(90, 55)
    sprint.button_down.connect(func(): sprint_pressed = true)
    sprint.button_up.connect(func(): sprint_pressed = false)
    controls.add_child(sprint)

    var crouch := Button.new()
    crouch.text = "ÇÖMEL"
    crouch.position = Vector2(245, 580)
    crouch.size = Vector2(90, 55)
    crouch.button_down.connect(func(): crouch_pressed = true)
    crouch.button_up.connect(func(): crouch_pressed = false)
    controls.add_child(crouch)

    var jump := Button.new()
    jump.text = "ZIPLA"
    jump.position = Vector2(340, 515)
    jump.size = Vector2(90, 120)
    jump.pressed.connect(func(): jump_pressed = true)
    controls.add_child(jump)

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
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_1:
            equip_weapon("TAARRUZ TÜFEĞİ")
        elif event.keycode == KEY_2:
            equip_weapon("HAFİF MAKİNELİ")
        elif event.keycode == KEY_3:
            equip_weapon("KESKİN NİŞANCI")

func _apply_look(delta: Vector2) -> void:
    rotation.y -= delta.x * look_sensitivity
    pitch = clampf(pitch - delta.y * look_sensitivity, -1.35, 1.35)
    camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    reload_timer = maxf(0.0, reload_timer - delta)
    slide_timer = maxf(0.0, slide_timer - delta)

    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, rotation.y)
    var wants_sprint := sprint_pressed or Input.is_key_pressed(KEY_SHIFT)
    var wants_crouch := crouch_pressed or Input.is_key_pressed(KEY_CTRL)

    if wants_sprint and input_vec.length() > 0.1 and not wants_crouch and is_on_floor():
        speed = sprint_speed
    elif wants_crouch:
        speed = crouch_speed
    else:
        speed = 6.0

    if wants_crouch:
        _set_crouched(true)
    else:
        _set_crouched(false)

    if jump_pressed or Input.is_action_just_pressed("ui_accept"):
        if is_on_floor() and not crouch_pressed:
            velocity.y = jump_velocity
        jump_pressed = false

    if wants_crouch and wants_sprint and input_vec.length() > 0.1 and is_on_floor() and slide_timer <= 0.0:
        slide_timer = 0.35
        velocity.x = direction.x * 11.0
        velocity.z = direction.z * 11.0

    if slide_timer <= 0.0:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        if velocity.y < 0.0:
            velocity.y = 0.0

    move_and_slide()

    if Input.is_action_pressed("fire") or touch_fire:
        shoot()
    if Input.is_action_just_pressed("reload"):
        reload()
    if muzzle_flash.visible:
        muzzle_flash.visible = false

func _set_crouched(active: bool) -> void:
    var target_height := crouch_height if active else stand_height
    if is_equal_approx(current_height, target_height):
        return
    current_height = target_height
    var collision := get_node_or_null("PlayerCollision") as CollisionShape3D
    if collision != null:
        var capsule := collision.shape as CapsuleShape3D
        if capsule != null:
            capsule.height = target_height
    camera.position.y = 0.65 if active else 0.95

func shoot() -> void:
    if reload_timer > 0.0 or fire_cooldown > 0.0 or ammo <= 0:
        if ammo <= 0: reload()
        return
    var data: Dictionary = WEAPONS[weapon_name]
    ammo -= 1
    fire_cooldown = float(data["cooldown"])
    muzzle_flash.visible = true
    var from := camera.global_position
    var range_value := float(data["range"])
    var to := from + (-camera.global_transform.basis.z * range_value)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.has("collider") and hit.collider.has_method("take_damage"):
        hit.collider.take_damage(int(data["damage"]))
    _emit_hud()

func equip_weapon(name: String) -> void:
    if not WEAPONS.has(name) or weapon_name == name:
        return
    weapon_name = name
    var data: Dictionary = WEAPONS[name]
    ammo = int(data["magazine"])
    reserve_ammo = int(data["reserve"])
    reload_timer = 0.25
    weapon.scale = Vector3(1.0, 1.0, 1.0) if name == "TAARRUZ TÜFEĞİ" else Vector3(0.82, 0.82, 0.72)
    weapon_changed.emit(weapon_name)
    _emit_hud()

func reload() -> void:
    if reload_timer > 0.0:
        return
    var data: Dictionary = WEAPONS[weapon_name]
    var mag := int(data["magazine"])
    if ammo >= mag or reserve_ammo <= 0:
        return
    reload_timer = 0.8
    var needed := mag - ammo
    var loaded := mini(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    _emit_hud()

func take_damage(amount: int) -> void:
    health -= amount
    _emit_hud()
    if health <= 0:
        health = 100
        var data: Dictionary = WEAPONS[weapon_name]
        ammo = int(data["magazine"])
        reserve_ammo = int(data["reserve"])
        global_position = Vector3(0, 1.2, 12)
        rotation = Vector3.ZERO
        pitch = 0.0
        camera.rotation = Vector3.ZERO
        _emit_hud()

func _emit_hud() -> void:
    hud_changed.emit(health, ammo, reserve_ammo)
