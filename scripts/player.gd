extends CharacterBody3D

signal hud_changed(health: int, ammo: int, reserve: int)
signal weapon_changed(name: String)
signal damage_feedback(amount: int, health: int)
signal critical_health_changed(active: bool)

class MobileJoystick extends Control:
    signal value_changed(value: Vector2)
    var radius := 68.0
    var knob_radius := 28.0
    var deadzone := 0.12
    var value := Vector2.ZERO
    var active := false
    var touch_id := -1

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP
        queue_redraw()

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
            if event.pressed and not active:
                active = true
                touch_id = event.index
                _update_value(event.position)
                accept_event()
            elif not event.pressed and active and event.index == touch_id:
                _reset()
                accept_event()
        elif event is InputEventScreenDrag and active and event.index == touch_id:
            _update_value(event.position)
            accept_event()

    func _reset() -> void:
        active = false
        touch_id = -1
        value = Vector2.ZERO
        value_changed.emit(value)
        queue_redraw()

    func force_reset() -> void:
        if active or value != Vector2.ZERO:
            _reset()

    func _update_value(local_position: Vector2) -> void:
        var center := size * 0.5
        var offset := local_position - center
        if offset.length() > radius:
            offset = offset.normalized() * radius
        value = Vector2(offset.x / radius, offset.y / radius)
        if value.length() < deadzone:
            value = Vector2.ZERO
        elif value.length() > 0.0:
            var strength := (value.length() - deadzone) / (1.0 - deadzone)
            value = value.normalized() * clampf(strength, 0.0, 1.0)
        value_changed.emit(value)
        queue_redraw()

    func _draw() -> void:
        var center := size * 0.5
        draw_circle(center, radius, Color(0.05, 0.08, 0.12, 0.58))
        draw_arc(center, radius, 0.0, TAU, 48, Color(0.8, 0.9, 1.0, 0.65), 3.0)
        draw_circle(center + value * radius, knob_radius, Color(0.9, 0.95, 1.0, 0.9))
        draw_circle(center + value * radius, knob_radius - 6.0, Color(0.18, 0.25, 0.32, 0.9))

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
var slide_pressed := false
var aim_pressed := false
var slide_timer := 0.0
var stand_height := 1.8
var crouch_height := 1.15
var current_height := 1.8
var mobile_move := Vector2.ZERO
var damage_overlay: ColorRect
var critical_label: Label
var damage_flash_timer := 0.0
var critical_pulse := 0.0
var critical_active := false
var mobile_controls: CanvasLayer
var move_joystick: MobileJoystick
var sprint_button: Button
var crouch_button: Button
var jump_button: Button
var slide_button: Button
var aim_button: Button
var fire_button: Button
var reload_button: Button

func _ready() -> void:
    camera = Camera3D.new()
    camera.position = Vector3(0, 0.95, 0)
    camera.fov = 78.0
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
    _create_damage_feedback()
    _layout_mobile_controls()
    call_deferred("_hide_legacy_direction_buttons")
    _emit_hud()
    weapon_changed.emit(weapon_name)

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        call_deferred("_layout_mobile_controls")

func _viewport_size() -> Vector2:
    return get_viewport().get_visible_rect().size

func _layout_mobile_controls() -> void:
    if mobile_controls == null:
        return
    var size := _viewport_size()
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var scale_factor := clampf(minf(size.x / 1280.0, size.y / 720.0), 0.72, 1.35)
    var pad := 24.0 * scale_factor
    var joystick_size := 170.0 * scale_factor
    var action_w := 88.0 * scale_factor
    var action_h := 52.0 * scale_factor
    move_joystick.position = Vector2(pad, size.y - joystick_size - pad)
    move_joystick.size = Vector2(joystick_size, joystick_size)
    sprint_button.position = Vector2(pad + joystick_size + 12.0 * scale_factor, size.y - joystick_size - pad + 5.0 * scale_factor)
    sprint_button.size = Vector2(action_w, action_h)
    crouch_button.position = Vector2(sprint_button.position.x, sprint_button.position.y + action_h + 8.0 * scale_factor)
    crouch_button.size = Vector2(action_w, action_h)
    slide_button.position = Vector2(sprint_button.position.x, crouch_button.position.y + action_h + 8.0 * scale_factor)
    slide_button.size = Vector2(action_w, 48.0 * scale_factor)
    jump_button.position = Vector2(sprint_button.position.x + action_w + 12.0 * scale_factor, sprint_button.position.y)
    jump_button.size = Vector2(action_w, action_h * 2.15)

    var right_pad := 24.0 * scale_factor
    var fire_size := 112.0 * scale_factor
    fire_button.position = Vector2(size.x - fire_size - right_pad, size.y - fire_size - right_pad)
    fire_button.size = Vector2(fire_size, fire_size)
    aim_button.position = Vector2(size.x - 150.0 * scale_factor - right_pad, fire_button.position.y - 78.0 * scale_factor)
    aim_button.size = Vector2(150.0 * scale_factor, 64.0 * scale_factor)
    reload_button.position = Vector2(fire_button.position.x - 96.0 * scale_factor, fire_button.position.y + 8.0 * scale_factor)
    reload_button.size = Vector2(84.0 * scale_factor, 52.0 * scale_factor)

    if damage_overlay != null:
        damage_overlay.size = size
    if critical_label != null:
        critical_label.position = Vector2(size.x * 0.5 - 200.0 * scale_factor, 90.0 * scale_factor)
        critical_label.size = Vector2(400.0 * scale_factor, 55.0 * scale_factor)

func _create_damage_feedback() -> void:
    var layer := CanvasLayer.new()
    layer.name = "DamageFeedback"
    layer.layer = 30
    add_child(layer)
    damage_overlay = ColorRect.new()
    damage_overlay.position = Vector2.ZERO
    damage_overlay.size = _viewport_size()
    damage_overlay.color = Color(0.75, 0.0, 0.0, 0.0)
    damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(damage_overlay)
    critical_label = Label.new()
    critical_label.text = "KRİTİK CAN • SIĞIN / GERİ ÇEKİL"
    critical_label.position = Vector2(440, 90)
    critical_label.size = Vector2(400, 55)
    critical_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    critical_label.visible = false
    layer.add_child(critical_label)

func _hide_legacy_direction_buttons() -> void:
    var root := get_parent()
    if root == null:
        return
    for node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text in ["▲", "▼", "◀", "▶"]:
            button.visible = false
            button.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func _configure_button(button: Button, text: String) -> void:
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.add_theme_font_size_override("font_size", 18)
    mobile_controls.add_child(button)

func _create_mobile_movement_controls() -> void:
    mobile_controls = CanvasLayer.new()
    mobile_controls.name = "MobileMovementControls"
    mobile_controls.layer = 20
    add_child(mobile_controls)

    move_joystick = MobileJoystick.new()
    move_joystick.name = "MoveJoystick"
    move_joystick.value_changed.connect(func(value: Vector2): mobile_move = value)
    mobile_controls.add_child(move_joystick)

    sprint_button = Button.new()
    _configure_button(sprint_button, "KOŞ")
    sprint_button.button_down.connect(func(): sprint_pressed = true)
    sprint_button.button_up.connect(func(): sprint_pressed = false)

    crouch_button = Button.new()
    _configure_button(crouch_button, "ÇÖMEL")
    crouch_button.button_down.connect(func(): crouch_pressed = true)
    crouch_button.button_up.connect(func(): crouch_pressed = false)

    jump_button = Button.new()
    _configure_button(jump_button, "ZIPLA")
    jump_button.pressed.connect(func(): jump_pressed = true)

    slide_button = Button.new()
    _configure_button(slide_button, "KAY")
    slide_button.pressed.connect(func(): slide_pressed = true)

    aim_button = Button.new()
    _configure_button(aim_button, "NİŞAN")
    aim_button.button_down.connect(func(): aim_pressed = true)
    aim_button.button_up.connect(func(): aim_pressed = false)

    fire_button = Button.new()
    _configure_button(fire_button, "ATEŞ")
    fire_button.button_down.connect(func(): touch_fire = true)
    fire_button.button_up.connect(func(): touch_fire = false)

    reload_button = Button.new()
    _configure_button(reload_button, "DOLDUR")
    reload_button.pressed.connect(func(): reload())

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _apply_look(event.relative)
    elif event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x > _viewport_size().x * 0.34 and look_touch_id == -1:
                look_touch_id = event.index
                look_last = event.position
        elif event.index == look_touch_id:
            look_touch_id = -1
            look_last = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == look_touch_id:
        var drag_delta: Vector2 = event.position - look_last
        look_last = event.position
        _apply_look(drag_delta)

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_1:
            equip_weapon("TAARRUZ TÜFEĞİ")
        elif event.keycode == KEY_2:
            equip_weapon("HAFİF MAKİNELİ")
        elif event.keycode == KEY_3:
            equip_weapon("KESKİN NİŞANCI")

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not event.pressed:
        if event.index == look_touch_id:
            look_touch_id = -1
            look_last = Vector2.ZERO
        # Defensive release: prevents a stuck combat button after an interrupted touch.
        if not fire_button.get_global_rect().has_point(event.position):
            touch_fire = false
        if not aim_button.get_global_rect().has_point(event.position):
            aim_pressed = false
        if not sprint_button.get_global_rect().has_point(event.position):
            sprint_pressed = false
        if not crouch_button.get_global_rect().has_point(event.position):
            crouch_pressed = false

func _apply_look(delta: Vector2) -> void:
    rotation.y -= delta.x * look_sensitivity
    pitch = clampf(pitch - delta.y * look_sensitivity, -1.35, 1.35)
    camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    reload_timer = maxf(0.0, reload_timer - delta)
    slide_timer = maxf(0.0, slide_timer - delta)
    damage_flash_timer = maxf(0.0, damage_flash_timer - delta)
    if damage_overlay != null:
        var flash_alpha := clampf(damage_flash_timer * 4.5, 0.0, 0.38)
        damage_overlay.color.a = flash_alpha
    if health <= 25:
        critical_pulse += delta
        if critical_label != null:
            critical_label.visible = true
            critical_label.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(critical_pulse * 5.0))
    elif critical_label != null:
        critical_label.visible = false

    var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_vec := mobile_move if mobile_move.length() > 0.05 else keyboard_input
    var direction := Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, rotation.y)
    var wants_sprint := sprint_pressed or Input.is_key_pressed(KEY_SHIFT)
    var wants_crouch := crouch_pressed or Input.is_key_pressed(KEY_CTRL)
    var wants_slide := slide_pressed or (wants_sprint and wants_crouch)

    if wants_sprint and input_vec.length() > 0.1 and not wants_crouch and is_on_floor():
        speed = sprint_speed
    elif wants_crouch:
        speed = crouch_speed
    else:
        speed = 6.0

    _set_crouched(wants_crouch or slide_timer > 0.0)

    if jump_pressed or Input.is_action_just_pressed("ui_accept"):
        if is_on_floor() and not wants_crouch and slide_timer <= 0.0:
            velocity.y = jump_velocity
        jump_pressed = false

    if wants_slide and input_vec.length() > 0.1 and is_on_floor() and slide_timer <= 0.0:
        slide_timer = 0.35
        slide_pressed = false
        velocity.x = direction.x * 11.0
        velocity.z = direction.z * 11.0

    if slide_timer <= 0.0:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()

    camera.fov = lerpf(camera.fov, 62.0 if aim_pressed else 78.0, minf(1.0, delta * 12.0))
    var sensitivity_target := 0.0025 if aim_pressed else 0.004
    look_sensitivity = lerpf(look_sensitivity, sensitivity_target, minf(1.0, delta * 10.0))

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
        if ammo <= 0:
            reload()
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
    _emit_hud()
    weapon_changed.emit(weapon_name)

func reload() -> void:
    if reload_timer > 0.0 or ammo >= int(WEAPONS[weapon_name]["magazine"]) or reserve_ammo <= 0:
        return
    reload_timer = float(WEAPONS[weapon_name]["reload"])
    var needed := int(WEAPONS[weapon_name]["magazine"]) - ammo
    var loaded := mini(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    _emit_hud()

func take_damage(amount: int) -> void:
    if amount <= 0 or health <= 0:
        return
    health = maxi(0, health - amount)
    damage_flash_timer = 0.25
    critical_active = health <= 25
    damage_feedback.emit(amount, health)
    critical_health_changed.emit(critical_active)
    _emit_hud()

func _emit_hud() -> void:
    hud_changed.emit(health, ammo, reserve_ammo)
