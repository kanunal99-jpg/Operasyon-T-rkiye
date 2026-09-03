extends CharacterBody3D

signal died
signal hit_player(amount: int)

const CountryProfile = preload("res://scripts/country_profile.gd")

var target: Node3D
var health := 100
var max_health := 100
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
var combat_phase := 0.0
var preferred_range := 7.5
var strafe_direction := 1.0
var intelligence_bonus := 0
var damage_multiplier := 1.0
var last_seen_position := Vector3.ZERO
var has_line_of_sight := false
var lost_target_timer := 0.0
var defense_target := Vector3.ZERO
var defense_active := false
var objective_attack_timer := 0.0
var role := "ASSAULT"
var cover_position := Vector3.ZERO
var flank_position := Vector3.ZERO
var tactical_timer := 0.0
var soldier_visual: Node3D
var weapon_mesh: MeshInstance3D

func configure_country(country_name: String) -> void:
    country = country_name
    if is_instance_valid(body_mesh): _apply_country_look()

func configure_role(role_name: String) -> void:
    role = role_name.to_upper()
    match role:
        "SUPPORT":
            preferred_range = 10.5
            attack_range = 16.0
        "FLANKER":
            preferred_range = 6.5
            speed = maxf(speed, 2.6)
        _:
            role = "ASSAULT"

func apply_support_bonus(incoming_damage_multiplier: float = 1.0, incoming_intelligence_bonus: int = 0) -> void:
    damage_multiplier = maxf(1.0, incoming_damage_multiplier)
    intelligence_bonus = maxi(0, incoming_intelligence_bonus)
    health = maxi(50, int(round(max_health / damage_multiplier)))
    speed = maxf(1.5, 2.2 - float(intelligence_bonus) * 0.003)
    preferred_range = clampf(preferred_range + float(intelligence_bonus) * 0.02, 6.0, 12.0)

func configure_defense_target(position: Vector3) -> void:
    defense_target = position
    defense_active = true

func _ready() -> void:
    spawn_position = global_position
    patrol_phase = float(get_instance_id() % 100) * 0.1
    combat_phase = float(get_instance_id() % 17) * 0.37
    strafe_direction = -1.0 if get_instance_id() % 2 == 0 else 1.0
    var role_roll := get_instance_id() % 10
    if role_roll < 2: configure_role("FLANKER")
    elif role_roll < 4: configure_role("SUPPORT")
    else: configure_role("ASSAULT")
    _create_soldier_model()
    var shape := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.38
    capsule_shape.height = 1.75
    shape.shape = capsule_shape
    shape.position.y = 0.88
    add_child(shape)

func _create_soldier_model() -> void:
    soldier_visual = Node3D.new()
    soldier_visual.name = "SoldierModel"
    soldier_visual.position.y = 0.0
    add_child(soldier_visual)

    body_mesh = MeshInstance3D.new()
    var torso := BoxMesh.new()
    torso.size = Vector3(0.72, 0.82, 0.42)
    body_mesh.mesh = torso
    body_mesh.position = Vector3(0, 1.12, 0)
    soldier_visual.add_child(body_mesh)

    var vest := MeshInstance3D.new()
    var vest_mesh := BoxMesh.new()
    vest_mesh.size = Vector3(0.78, 0.55, 0.47)
    vest.mesh = vest_mesh
    vest.position = Vector3(0, 1.18, -0.015)
    soldier_visual.add_child(vest)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.22
    head_mesh.height = 0.44
    head.mesh = head_mesh
    head.position = Vector3(0, 1.72, 0)
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#b78362")
    skin.roughness = 0.9
    head.material_override = skin
    soldier_visual.add_child(head)

    var helmet := MeshInstance3D.new()
    var helmet_mesh := SphereMesh.new()
    helmet_mesh.radius = 0.27
    helmet_mesh.height = 0.22
    helmet.mesh = helmet_mesh
    helmet.position = Vector3(0, 1.91, 0)
    soldier_visual.add_child(helmet)

    var limb_material := StandardMaterial3D.new()
    limb_material.albedo_color = Color("#3e493b")
    limb_material.roughness = 0.9
    _add_limb(Vector3(-0.48, 1.12, 0), Vector3(0.18, 0.72, 0.18), limb_material, "LeftArm")
    _add_limb(Vector3(0.48, 1.12, 0), Vector3(0.18, 0.72, 0.18), limb_material, "RightArm")
    _add_limb(Vector3(-0.2, 0.48, 0), Vector3(0.22, 0.75, 0.22), limb_material, "LeftLeg")
    _add_limb(Vector3(0.2, 0.48, 0), Vector3(0.22, 0.75, 0.22), limb_material, "RightLeg")

    weapon_mesh = MeshInstance3D.new()
    var rifle := BoxMesh.new()
    rifle.size = Vector3(0.12, 0.12, 0.85)
    weapon_mesh.mesh = rifle
    weapon_mesh.position = Vector3(0.33, 1.02, -0.42)
    weapon_mesh.rotation_degrees = Vector3(-8, 0, 8)
    var weapon_material := StandardMaterial3D.new()
    weapon_material.albedo_color = Color("#202428")
    weapon_mesh.material_override = weapon_material
    soldier_visual.add_child(weapon_mesh)

    _apply_country_look()

func _add_limb(pos: Vector3, size: Vector3, material: Material, limb_name: String) -> void:
    var limb := MeshInstance3D.new()
    limb.name = limb_name
    var mesh := BoxMesh.new()
    mesh.size = size
    limb.mesh = mesh
    limb.position = pos
    limb.material_override = material
    soldier_visual.add_child(limb)

func _apply_country_look() -> void:
    var profile := CountryProfile.get_profile(country)
    var material := StandardMaterial3D.new()
    material.albedo_color = _country_color(str(profile.get("uniform", "generic_modern")))
    material.roughness = 0.78
    body_mesh.material_override = material
    for child in soldier_visual.get_children():
        if child is MeshInstance3D and child != weapon_mesh and child.name not in ["SoldierModel"]:
            if child.name in ["Head"]: continue
            if child.name.begins_with("Left") or child.name.begins_with("Right") or child.name == "Vest":
                child.material_override = material
    callout_text = CountryProfile.get_callout(country, "contact")

func _country_color(uniform_id: String) -> Color:
    var palette := {
        "modern_turkish": Color("#53634f"), "modern_greek": Color("#536b73"), "modern_bulgarian": Color("#596456"), "modern_german": Color("#3f464b"), "modern_french": Color("#3d4c5f"), "modern_italian": Color("#536052"), "modern_spanish": Color("#665f4d"), "modern_british": Color("#4b5563"), "modern_us": Color("#4f5d4b"), "modern_canadian": Color("#55624e"), "modern_mexican": Color("#53604c"), "modern_brazilian": Color("#53634f"), "modern_argentine": Color("#58646a"), "modern_egyptian": Color("#6b634f"), "modern_moroccan": Color("#655d4d"), "modern_south_african": Color("#4d5d4f"), "modern_saudi": Color("#4f5c50"), "modern_uae": Color("#4f5d53"), "modern_iranian": Color("#4d5b4f"), "modern_iraqi": Color("#5d604d"), "modern_indian": Color("#53624e"), "modern_pakistani": Color("#4e624f"), "modern_chinese": Color("#4b5552"), "modern_japanese": Color("#4e575c"), "modern_south_korean": Color("#4e5a62"), "modern_indonesian": Color("#53614f"), "modern_australian": Color("#56624f"), "modern_new_zealand": Color("#505c54")
    }
    if palette.has(uniform_id): return palette[uniform_id]
    var hash_value := absi(hash(uniform_id))
    var shade := 0.28 + float(hash_value % 35) / 100.0
    return Color(shade, shade + 0.03, shade - 0.01)

func _get_defense_context() -> Node:
    var root := get_tree().current_scene
    if root == null: return null
    for child in root.get_children():
        if child != self and child.has_method("damage_defend_objective"): return child
    return null

func _get_objective_position() -> Vector3:
    var root := get_tree().current_scene
    if root != null:
        for child in root.get_children():
            if child.has_method("get_objective_position"): return child.get_objective_position()
    return defense_target

func _physics_process(delta: float) -> void:
    if hit_flash_timer > 0.0:
        hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
        if hit_flash_timer == 0.0: _apply_country_look()
    if callout_timer > 0.0: callout_timer = maxf(0.0, callout_timer - delta)
    if not is_instance_valid(target): return
    attack_timer = maxf(0.0, attack_timer - delta)
    objective_attack_timer = maxf(0.0, objective_attack_timer - delta)
    tactical_timer = maxf(0.0, tactical_timer - delta)
    combat_phase += delta
    var offset := target.global_position - global_position; offset.y = 0
    var distance := offset.length()
    has_line_of_sight = _has_line_of_sight()
    if has_line_of_sight:
        last_seen_position = target.global_position; lost_target_timer = 0.0
    else: lost_target_timer += delta

    var mission := _get_defense_context()
    var defending: bool = mission != null and mission.get("objective_type") == "DEFEND" and mission.get("active")
    if defending:
        defense_active = true; defense_target = _get_objective_position()
    var objective_distance := global_position.distance_to(defense_target) if defense_active else 9999.0
    var player_from_objective := target.global_position.distance_to(defense_target) if defense_active else 9999.0
    if defending and objective_distance <= 4.0 and player_from_objective > 6.0:
        state = "PRESSURE_OBJECTIVE"
    elif distance <= 16.0:
        if role == "FLANKER" and distance > 5.0 and has_line_of_sight:
            state = "FLANK"
        elif distance <= attack_range: state = "ATTACK"
        else: state = "CHASE"
    elif not has_line_of_sight and lost_target_timer < 2.5:
        state = "SEARCH"
    else: state = "PATROL"
    if health <= max_health * 0.3 and distance < 10.0: state = "RETREAT"

    match state:
        "PATROL": _patrol(delta)
        "SEARCH": _search()
        "CHASE": _chase()
        "ATTACK": _combat(delta, distance)
        "FLANK": _flank()
        "PRESSURE_OBJECTIVE": _pressure_objective(delta)
        "RETREAT": _retreat()

func _has_line_of_sight() -> bool:
    var space := get_world_3d().direct_space_state
    if space == null: return false
    var from := global_position + Vector3.UP * 0.8
    var to := target.global_position + Vector3.UP * 0.8
    var query := PhysicsRayQueryParameters3D.create(from, to); query.exclude = [self]
    var hit := space.intersect_ray(query)
    return not hit.has("collider") or hit.collider == target

func _patrol(delta: float) -> void:
    patrol_phase += delta * 0.55
    _move_toward(spawn_position + Vector3(cos(patrol_phase) * 3.5, 0, sin(patrol_phase) * 3.5), speed * 0.45)

func _search() -> void: _move_toward(last_seen_position, speed * 0.8)
func _chase() -> void: _move_toward(target.global_position, speed * 1.15)

func _combat(delta: float, distance: float) -> void:
    var to_target := target.global_position - global_position; to_target.y = 0
    if to_target.length() <= 0.01: return
    var direction := to_target.normalized()
    var side := Vector3(-direction.z, 0, direction.x) * strafe_direction
    var desired := direction if distance > preferred_range + 1.0 else (-direction * 0.65 if distance < preferred_range - 1.0 else Vector3.ZERO)
    desired += side * (0.45 + sin(combat_phase * 1.7) * 0.15)
    if desired.length() > 0.05: _move_toward(global_position + desired.normalized() * 2.0, speed)
    else: velocity = Vector3.ZERO
    look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
    if has_line_of_sight and attack_timer <= 0.0:
        attack_timer = maxf(0.65, 1.0 - float(intelligence_bonus) * 0.004)
        callout_timer = 1.5
        if target.has_method("take_damage"):
            var damage := maxi(3, int(round(8.0 / damage_multiplier)))
            target.take_damage(damage); hit_player.emit(damage)

func _flank() -> void:
    if flank_position == Vector3.ZERO or tactical_timer <= 0.0:
        var to_target := target.global_position - global_position; to_target.y = 0
        var direction := to_target.normalized() if to_target.length() > 0.1 else Vector3.FORWARD
        var side := Vector3(-direction.z, 0, direction.x) * strafe_direction
        flank_position = target.global_position + side * 9.0 + direction * 2.0
        tactical_timer = 2.5
    _move_toward(flank_position, speed * 1.2)
    if global_position.distance_to(flank_position) < 1.5: state = "ATTACK"

func _pressure_objective(delta: float) -> void:
    _move_toward(defense_target, speed * 0.9)
    look_at(Vector3(defense_target.x, global_position.y, defense_target.z), Vector3.UP)
    var mission := _get_defense_context()
    if mission == null or not mission.get("active") or mission.get("objective_type") != "DEFEND": return
    if global_position.distance_to(defense_target) <= 4.2 and objective_attack_timer <= 0.0:
        objective_attack_timer = 1.15
        mission.damage_defend_objective(7.0 + float(intelligence_bonus) * 0.03)

func _retreat() -> void:
    var away := global_position - target.global_position; away.y = 0
    if away.length() > 0.1: _move_toward(global_position + away.normalized() * 3.0, speed * 1.1)

func _move_toward(destination: Vector3, move_speed: float) -> void:
    var offset := destination - global_position; offset.y = 0
    if offset.length() > 0.8:
        var direction := offset.normalized(); velocity.x = direction.x * move_speed; velocity.z = direction.z * move_speed; look_at(global_position + direction, Vector3.UP); move_and_slide()
    else: velocity = Vector3.ZERO

func take_damage(amount: int) -> void:
    health -= amount
    hit_flash_timer = 0.08
    body_mesh.modulate = Color(1.0, 0.25, 0.25)
    if health <= 0:
        died.emit(); queue_free()