extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const CityArena = preload("res://scripts/city_arena.gd")
const OperationData = preload("res://scripts/operation_data.gd")
const MissionManager = preload("res://scripts/mission_manager.gd")
const GameManager = preload("res://scripts/game_manager.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const AllianceManager = preload("res://scripts/alliance_manager.gd")
const MobileQuality = preload("res://scripts/mobile_quality.gd")
const NewsCutsceneManager = preload("res://scripts/news_cutscene_manager.gd")

var player: CharacterBody3D
var city: Node3D
var mission: Node
var waves: Node
var save: Node
var diplomacy: Node
var quality: Node
var news: CanvasLayer
var objective_marker: MeshInstance3D
var enemies: Array[Node] = []
var score := 0
var operation_index := 0
var mission_finished := false
var status: Label
var objective: Label
var info: Label

func _ready() -> void:
    quality = MobileQuality.new(); add_child(quality)
    save = SaveManager.new(); add_child(save)
    diplomacy = AllianceManager.new(); add_child(diplomacy)
    diplomacy.import_state(save.diplomacy_state)
    news = NewsCutsceneManager.new(); add_child(news)
    city = Node3D.new(); city.set_script(CityArena); add_child(city)
    player = CharacterBody3D.new(); player.set_script(Player); player.position = Vector3(0, 1.2, 25); add_child(player)
    mission = MissionManager.new(); add_child(mission)
    waves = GameManager.new(); add_child(waves)
    mission.objective_changed.connect(_on_objective)
    mission.mission_completed.connect(_on_complete)
    mission.mission_failed.connect(_on_failed)
    waves.wave_completed.connect(_on_wave_completed)
    waves.all_waves_completed.connect(_on_all_waves_completed)
    _build_world()
    _build_hud()
    _start_operation(save.selected_operation)

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("#202832"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_energy = 0.8; env.environment = e; add_child(env)
    var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, -25, 0); sun.light_energy = 1.1; sun.shadow_enabled = quality.should_use_shadows(); add_child(sun)

func _build_hud() -> void:
    var hud := CanvasLayer.new(); hud.name = "HUD"; add_child(hud)
    status = Label.new(); status.position = Vector2(28, 24); status.add_theme_font_size_override("font_size", 22); hud.add_child(status)
    objective = Label.new(); objective.position = Vector2(28, 60); objective.add_theme_font_size_override("font_size", 20); hud.add_child(objective)
    info = Label.new(); info.position = Vector2(28, 100); info.add_theme_font_size_override("font_size", 18); hud.add_child(info)
    var fire := Button.new(); fire.text = "ATEŞ"; fire.position = Vector2(1080, 545); fire.size = Vector2(150, 100); fire.button_down.connect(func(): player.touch_fire = true); fire.button_up.connect(func(): player.touch_fire = false); hud.add_child(fire)
    var reload := Button.new(); reload.text = "ŞARJÖR"; reload.position = Vector2(930, 585); reload.size = Vector2(130, 70); reload.pressed.connect(player.reload); hud.add_child(reload)
    var w1 := Button.new(); w1.text = "1 • TÜFEK"; w1.position = Vector2(760, 545); w1.size = Vector2(150, 55); w1.pressed.connect(func(): player.equip_weapon("TAARRUZ TÜFEĞİ")); hud.add_child(w1)
    var w2 := Button.new(); w2.text = "2 • MAKİNELİ"; w2.position = Vector2(760, 605); w2.size = Vector2(150, 55); w2.pressed.connect(func(): player.equip_weapon("HAFİF MAKİNELİ")); hud.add_child(w2)
    var w3 := Button.new(); w3.text = "3 • KESKİN"; w3.position = Vector2(930, 515); w3.size = Vector2(130, 55); w3.pressed.connect(func(): player.equip_weapon("KESKİN NİŞANCI")); hud.add_child(w3)

func _start_operation(index: int) -> void:
    var op := OperationData.get_operation("Türkiye", clampi(index, 0, 2))
    operation_index = clampi(index, 0, 2); mission_finished = false
    city.configure("Türkiye", op[0], op[1]); city.build()
    _build_marker()
    mission.start(op)
    waves.start_mission(int(op[3]))
    if mission.objective_type == "DEFEND" or mission.objective_type == "SURVIVE": waves.set_endless_waves()
    _spawn_wave(waves.base_enemy_count)
    status.text = "TÜRKİYE • %s • %s" % [op[0], op[1]]
    news.play_briefing("Türkiye", op[0], op[1], diplomacy.get_allies("Türkiye").size())

func _build_marker() -> void:
    if is_instance_valid(objective_marker): objective_marker.queue_free()
    objective_marker = MeshInstance3D.new()
    var mesh := CylinderMesh.new(); mesh.top_radius = 3.5; mesh.bottom_radius = 3.5; mesh.height = 0.08; objective_marker.mesh = mesh
    objective_marker.position = city.get_objective_position(); objective_marker.position.y = 0.06; city.add_child(objective_marker)

func _spawn_wave(count: int) -> void:
    for e in enemies:
        if is_instance_valid(e): e.queue_free()
    enemies.clear()
    var positions := city.get_enemy_spawn_positions()
    var support := diplomacy.get_enemy_reduction("Türkiye")
    var total := mini(positions.size(), mini(quality.get_enemy_budget(), maxi(2, count - support)))
    for i in range(total):
        var enemy := CharacterBody3D.new(); enemy.set_script(Enemy); enemy.position = positions[i]; enemy.target = player; enemy.configure_country("Türkiye"); enemy.apply_support_bonus(diplomacy.get_damage_bonus("Türkiye"), diplomacy.get_intel_bonus("Türkiye")); enemy.died.connect(_on_enemy_died); add_child(enemy); enemies.append(enemy)
    waves.set_wave_enemy_count(enemies.size())
    status.text = "DALGA %d • %d DÜŞMAN • DESTEK %d" % [waves.wave, enemies.size(), diplomacy.get_support_level("Türkiye")]

func _process(_delta: float) -> void:
    if not is_instance_valid(mission) or not mission.active: return
    var p := city.get_objective_position(); p.y = player.global_position.y
    var d := player.global_position.distance_to(p)
    if mission.objective_type == "REACH" and d <= 3.0: mission.register_reach()
    elif mission.objective_type == "DEFEND": mission.set_defend_presence(d <= 7.0)

func _on_enemy_died() -> void:
    score += 100; mission.register_kill(); waves.register_enemy_killed(); save.score = score; save.save_game()

func _on_objective(title: String, progress: String) -> void:
    objective.text = "%s  [%s]" % [title, progress]

func _on_wave_completed(wave: int) -> void:
    if waves.active and not mission_finished: call_deferred("_next_wave")

func _next_wave() -> void:
    if waves.active and not mission_finished: _spawn_wave(waves.get_next_wave_count())

func _on_all_waves_completed() -> void:
    if not mission.active: _finish_operation()

func _on_complete(_reward: int) -> void:
    if mission_finished: return
    waves.stop_mission(); _finish_operation()

func _on_failed() -> void:
    if mission_finished: return
    mission_finished = true; waves.stop_mission(); _clear_enemies(); status.text = "OPERASYON BAŞARISIZ • SAVUNMA BÖLGESİ KAYBEDİLDİ"; objective.text = "GÖREV BAŞARISIZ"

func _finish_operation() -> void:
    if mission_finished: return
    mission_finished = true; _clear_enemies()
    var op := OperationData.get_operation("Türkiye", operation_index); var reward := int(op[3]) * 250
    save.complete_operation("Türkiye", operation_index, reward); score = save.score
    status.text = "OPERASYON TAMAMLANDI • +%d XP" % reward; objective.text = "HEDEF TAMAMLANDI"
    news.play_result("Türkiye", op[0], op[1], score, save.xp, diplomacy.get_allies("Türkiye").size(), diplomacy.get_alert_text())

func _clear_enemies() -> void:
    for e in enemies:
        if is_instance_valid(e): e.queue_free()
    enemies.clear()
