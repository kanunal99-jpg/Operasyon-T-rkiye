extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const WorldMap = preload("res://scripts/world_map.gd")
const GlobalMap = preload("res://scripts/global_world_map.gd")
const CountryProfile = preload("res://scripts/country_profile.gd")
const OperationData = preload("res://scripts/operation_data.gd")
const CityArena = preload("res://scripts/city_arena.gd")
const MissionManager = preload("res://scripts/mission_manager.gd")
const GameManager = preload("res://scripts/game_manager.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const AllianceManager = preload("res://scripts/alliance_manager.gd")
const NewsCutsceneManager = preload("res://scripts/news_cutscene_manager.gd")
const MobileQuality = preload("res://scripts/mobile_quality.gd")

var player: CharacterBody3D
var city_arena: Node3D
var mission_manager: Node
var game_manager: Node
var save_manager: Node
var alliance_manager: Node
var mobile_quality: Node
var news_cutscene: CanvasLayer
var objective_marker: MeshInstance3D
var score := 0
var mission_id := 1
var operation_index := 0
var score_label: Label
var status_label: Label
var health_label: Label
var ammo_label: Label
var mission_label: Label
var objective_label: Label
var weapon_label: Label
var crosshair: Label
var map_panel: Panel
var map_label: Label
var country_list: VBoxContainer
var operation_list: VBoxContainer
var language_button: Button
var alliance_button: Button
var map_open := false
var selected_voice := "tr"
var alliance_candidate_index := 0
var spawned_enemies: Array[Node] = []
var mission_finished := false

func _ready() -> void:
    mobile_quality = MobileQuality.new()
    add_child(mobile_quality)
    save_manager = SaveManager.new()
    add_child(save_manager)
    for saved_country in save_manager.unlocked_countries:
        GlobalMap.unlock_country(str(saved_country))
    if save_manager.selected_country != "" and GlobalMap.is_unlocked(save_manager.selected_country):
        GlobalMap.select_country(save_manager.selected_country)
    alliance_manager = AllianceManager.new()
    add_child(alliance_manager)
    alliance_manager.import_state(save_manager.diplomacy_state)
    news_cutscene = NewsCutsceneManager.new()
    add_child(news_cutscene)
    _build_world()
    _spawn_player()
    _build_hud()
    mission_manager = MissionManager.new()
    add_child(mission_manager)
    game_manager = GameManager.new()
    add_child(game_manager)
    mission_manager.objective_changed.connect(_on_objective_changed)
    mission_manager.mission_completed.connect(_on_mission_completed)
    game_manager.wave_changed.connect(_on_wave_changed)
    game_manager.wave_completed.connect(_on_wave_completed)
    game_manager.all_waves_completed.connect(_on_all_waves_completed)
    game_manager.mission_changed.connect(_on_game_mission_changed)
    player.hud_changed.connect(_on_player_hud_changed)
    player.weapon_changed.connect(_on_weapon_changed)
    alliance_manager.diplomacy_changed.connect(_on_diplomacy_changed)
    score = save_manager.score
    operation_index = save_manager.selected_operation
    _on_player_hud_changed(player.health, player.ammo, player.reserve_ammo)
    _on_weapon_changed(player.weapon_name)
    _refresh_country_list()
    _refresh_operation_list()
    _update_alliance_button()
    _select_operation(operation_index)

func _process(_delta: float) -> void:
    if not is_instance_valid(mission_manager) or not mission_manager.active:
        return
    var objective_point := city_arena.get_objective_position() if is_instance_valid(city_arena) else Vector3(0, 1, -18)
    objective_point.y = player.global_position.y
    var distance := player.global_position.distance_to(objective_point)
    if mission_manager.objective_type == "REACH":
        if distance <= 3.0:
            mission_manager.register_reach()
    elif mission_manager.objective_type == "DEFEND":
        mission_manager.set_defend_presence(distance <= 7.0)

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#202832")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#aebdca")
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.1
    sun.shadow_enabled = mobile_quality.should_use_shadows()
    add_child(sun)
    city_arena = Node3D.new()
    city_arena.set_script(CityArena)
    add_child(city_arena)
    _rebuild_city()

func _rebuild_city() -> void:
    if not is_instance_valid(city_arena):
        return
    var op := OperationData.get_operation(GlobalMap.selected_country, operation_index)
    city_arena.configure(GlobalMap.selected_country, op[0], op[1])
    city_arena.build()
    _build_objective_marker()

func _build_objective_marker() -> void:
    if is_instance_valid(objective_marker):
        objective_marker.queue_free()
        objective_marker = null
    if not is_instance_valid(city_arena):
        return
    objective_marker = MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 3.5
    cylinder.bottom_radius = 3.5
    cylinder.height = 0.08
    objective_marker.mesh = cylinder
    objective_marker.position = city_arena.get_objective_position()
    objective_marker.position.y = 0.06
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#2ed573")
    material.emission_enabled = true
    material.emission = Color("#123f25")
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.55
    objective_marker.material_override = material
    city_arena.add_child(objective_marker)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(Player)
    player.position = Vector3(0, 1.2, 25)
    add_child(player)

func _clear_enemies() -> void:
    for enemy in spawned_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    spawned_enemies.clear()

func _spawn_wave(enemy_count: int) -> void:
    _clear_enemies()
    var positions: Array[Vector3] = city_arena.get_enemy_spawn_positions() if is_instance_valid(city_arena) else [Vector3(-20,1,-20),Vector3(20,1,-20)]
    if positions.is_empty():
        positions = [Vector3(-20,1,-20), Vector3(20,1,-20)]
    var support_level := alliance_manager.get_support_level(GlobalMap.selected_country)
    var enemy_reduction := alliance_manager.get_enemy_reduction(GlobalMap.selected_country)
    var adjusted_count := maxi(2, enemy_count - enemy_reduction)
    adjusted_count = mini(adjusted_count, positions.size())
    adjusted_count = mini(adjusted_count, mobile_quality.get_enemy_budget())
    var damage_bonus := alliance_manager.get_damage_bonus(GlobalMap.selected_country)
    var intel_bonus := alliance_manager.get_intel_bonus(GlobalMap.selected_country)
    for i in range(adjusted_count):
        var enemy := CharacterBody3D.new()
        enemy.set_script(Enemy)
        enemy.position = positions[i]
        enemy.target = player
        enemy.configure_country(GlobalMap.selected_country)
        enemy.apply_support_bonus(damage_bonus, intel_bonus)
        enemy.died.connect(_on_enemy_died)
        add_child(enemy)
        spawned_enemies.append(enemy)
    if is_instance_valid(game_manager):
        game_manager.set_wave_enemy_count(spawned_enemies.size())
    if is_instance_valid(status_label):
        status_label.text = "DALGA %d • %d DÜŞMAN • DESTEK %d" % [game_manager.wave, spawned_enemies.size(), support_level]
