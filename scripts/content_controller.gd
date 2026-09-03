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
const EnvironmentManager = preload("res://scripts/environment_manager.gd")
const GlobalMap = preload("res://scripts/global_world_map.gd")
const CountryProfile = preload("res://scripts/country_profile.gd")
const VehicleManager = preload("res://scripts/vehicle_manager.gd")

var player: CharacterBody3D
var city: Node3D
var mission: Node
var waves: Node
var save: Node
var diplomacy: Node
var quality: Node
var atmosphere: Node
var vehicles: Node
var global_map: Node
var news: CanvasLayer
var objective_marker: MeshInstance3D
var map_menu: CanvasLayer
var enemies: Array[Node] = []
var score := 0
var operation_index := 0
var mission_finished := false
var selected_country := "Türkiye"
var status: Label
var objective: Label
var info: Label
var support_status: Label

func _ready() -> void:
    quality = MobileQuality.new(); add_child(quality)
    save = SaveManager.new(); add_child(save)
    global_map = GlobalMap.new(); global_map.name = "GlobalWorldMap"; add_child(global_map)
    selected_country = save.selected_country if save.selected_country != "" else "Türkiye"
    for saved_country in save.unlocked_countries:
        global_map.unlock_country(str(saved_country))
    if not global_map.is_unlocked(selected_country): selected_country = "Türkiye"
    global_map.select_country(selected_country)
    diplomacy = AllianceManager.new(); add_child(diplomacy); diplomacy.import_state(save.diplomacy_state)
    news = NewsCutsceneManager.new(); add_child(news)
    atmosphere = EnvironmentManager.new(); add_child(atmosphere)
    vehicles = VehicleManager.new(); vehicles.name = "VehicleManager"; add_child(vehicles)
    vehicles.support_event.connect(_on_support_event)
    city = Node3D.new(); city.set_script(CityArena); add_child(city)
    player = CharacterBody3D.new(); player.set_script(Player); player.position = Vector3(0, 1.2, 25); add_child(player)
    mission = MissionManager.new(); add_child(mission)
    waves = GameManager.new(); add_child(waves)
    mission.objective_changed.connect(_on_objective)
    mission.mission_completed.connect(_on_complete)
    mission.mission_failed.connect(_on_failed)
    waves.wave_completed.connect(_on_wave_completed)
    waves.all_waves_completed.connect(_on_all_waves_completed)
    atmosphere.environment_changed.connect(_on_environment_changed)
    _build_world(); _build_hud(); _show_map_selection()

func _build_world() -> void:
    pass

func _build_hud() -> void:
    var hud := CanvasLayer.new(); hud.name = "HUD"; hud.layer = 20; add_child(hud)
    status = Label.new(); status.position = Vector2(28, 24); status.add_theme_font_size_override("font_size", 22); hud.add_child(status)
    objective = Label.new(); objective.position = Vector2(28, 60); objective.add_theme_font_size_override("font_size", 20); hud.add_child(objective)
    info = Label.new(); info.position = Vector2(28, 100); info.add_theme_font_size_override("font_size", 18); hud.add_child(info)
    support_status = Label.new(); support_status.position = Vector2(28, 135); support_status.add_theme_font_size_override("font_size", 17); hud.add_child(support_status)
    # Combat/weapon buttons are owned by player.gd. Keeping a second set here caused
    # overlapping mobile controls, so the HUD only contains support actions.
    var air := Button.new(); air.text = "HAVA DESTEĞİ"; air.position = Vector2(28, 175); air.size = Vector2(180, 52); air.button_down.connect(_request_air_support); hud.add_child(air)
    var armor := Button.new(); armor.text = "ZIRHLI DESTEK"; armor.position = Vector2(218, 175); armor.size = Vector2(180, 52); armor.button_down.connect(_request_armor_support); hud.add_child(armor)
    var strategic := Button.new(); strategic.text = "STRATEJİK ALARM"; strategic.position = Vector2(408, 175); strategic.size = Vector2(180, 52); strategic.button_down.connect(_raise_strategic_alert); hud.add_child(strategic)

func _show_map_selection() -> void:
    map_menu = CanvasLayer.new()
    map_menu.name = "MapSelection"
    map_menu.layer = 100
    add_child(map_menu)

    var backdrop := ColorRect.new()
    backdrop.color = Color(0.015, 0.025, 0.04, 0.96)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    map_menu.add_child(backdrop)

    var title := Label.new()
    title.text = "OPERASYON TÜRKİYE"
    title.position = Vector2(0, 45)
    title.size = Vector2(1280, 60)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    map_menu.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "HARİTA / OPERASYON SEÇ • %s" % selected_country
    subtitle.position = Vector2(0, 105)
    subtitle.size = Vector2(1280, 45)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 21)
    map_menu.add_child(subtitle)

    var operations: Array = OperationData.get_operations(selected_country)
    for i in range(mini(3, operations.size())):
        var op: Array = operations[i]
        var card := Button.new()
        card.name = "MapCard%d" % i
        card.text = "HARİTA %d\n%s\n%s\nZORLUK %d" % [i + 1, str(op[0]), str(op[1]), int(op[3])]
        card.position = Vector2(95 + i * 385, 205)
        card.size = Vector2(350, 245)
        card.add_theme_font_size_override("font_size", 22)
        card.focus_mode = Control.FOCUS_NONE
        card.pressed.connect(_select_map.bind(i))
        map_menu.add_child(card)

    var footer := Label.new()
    footer.text = "Seçimini yap: Harita seçildiğinde operasyon alanı kurulacak."
    footer.position = Vector2(0, 500)
    footer.size = Vector2(1280, 45)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 17)
    map_menu.add_child(footer)
    _layout_map_selection()

func _layout_map_selection() -> void:
    if map_menu == null: return
    var size := get_viewport().get_visible_rect().size
    var scale_factor := clampf(minf(size.x / 1280.0, size.y / 720.0), 0.72, 1.35)
    var title := map_menu.get_node_or_null("Label")
    if title != null: title.position = Vector2(0, 35 * scale_factor); title.size = Vector2(size.x, 60 * scale_factor)
    var cards := map_menu.find_children("MapCard*", "Button", true, false)
    var card_w := minf(350.0 * scale_factor, (size.x - 80.0) / 3.0)
    var gap := 16.0 * scale_factor
    var total_w := card_w * 3.0 + gap * 2.0
    var start_x := maxf(20.0, (size.x - total_w) * 0.5)
    for i in range(cards.size()):
        var card := cards[i] as Button
        card.position = Vector2(start_x + i * (card_w + gap), 180.0 * scale_factor)
        card.size = Vector2(card_w, 220.0 * scale_factor)

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        call_deferred("_layout_map_selection")

func _select_map(index: int) -> void:
    operation_index = clampi(index, 0, 2)
    save.selected_operation = operation_index
    save.selected_country = selected_country
    save.save_game()
    if is_instance_valid(map_menu): map_menu.queue_free()
    _start_operation(operation_index)

func _start_operation(index: int) -> void:
    operation_index = clampi(index, 0, 2); mission_finished = false
    var op: Array = OperationData.get_operation(selected_country, operation_index)
    city.configure(selected_country, str(op[0]), str(op[1])); city.build()
    atmosphere.setup(city.theme, city.seed_value)
    vehicles.setup(selected_country, CountryProfile.get_profile(selected_country), player)
    _build_marker()
    mission.start(op)
    waves.start_mission(int(op[3]))
    if mission.objective_type == "DEFEND" or mission.objective_type == "SURVIVE": waves.set_endless_waves()
    _spawn_wave(waves.base_enemy_count)
    status.text = "%s • %s • %s" % [selected_country, str(op[0]), atmosphere.get_status_text()]
    support_status.text = vehicles.get_status_text()
    news.play_briefing(selected_country, str(op[0]), str(op[1]), diplomacy.get_allies(selected_country).size())

func _build_marker() -> void:
    if is_instance_valid(objective_marker): objective_marker.queue_free()
    objective_marker = MeshInstance3D.new()
    var mesh := CylinderMesh.new(); mesh.top_radius = 3.5; mesh.bottom_radius = 3.5; mesh.height = 0.08; objective_marker.mesh = mesh
    objective_marker.position = city.get_objective_position(); objective_marker.position.y = 0.06; city.add_child(objective_marker)

func _spawn_wave(count: int) -> void:
    for e in enemies:
        if is_instance_valid(e): e.queue_free()
    enemies.clear()
    var positions: Array[Vector3] = city.get_enemy_spawn_positions()
    var support: int = diplomacy.get_enemy_reduction(selected_country)
    var total: int = mini(positions.size(), mini(quality.get_enemy_budget(), maxi(2, count - support)))
    for i in range(total):
        var enemy: CharacterBody3D = CharacterBody3D.new()
        enemy.set_script(Enemy)
        enemy.position = positions[i]
        enemy.target = player
        enemy.configure_country(selected_country)
        if total >= 4 and i % 5 == 0: enemy.configure_role("FLANKER")
        elif i % 3 == 0: enemy.configure_role("SUPPORT")
        else: enemy.configure_role("ASSAULT")
        enemy.apply_support_bonus(diplomacy.get_damage_bonus(selected_country), diplomacy.get_intel_bonus(selected_country))
        enemy.died.connect(_on_enemy_died)
        add_child(enemy)
        enemies.append(enemy)
    waves.set_wave_enemy_count(enemies.size())
    status.text = "DALGA %d • %d DÜŞMAN • DESTEK %d • %s" % [waves.wave, enemies.size(), diplomacy.get_support_level(selected_country), atmosphere.get_status_text()]

func _process(_delta: float) -> void:
    if is_instance_valid(support_status) and is_instance_valid(vehicles): support_status.text = vehicles.get_status_text()
    if not is_instance_valid(mission) or not mission.active: return
    var p: Vector3 = city.get_objective_position()
    p.y = player.global_position.y
    var d: float = player.global_position.distance_to(p)
    if mission.objective_type == "REACH" and d <= 3.0: mission.register_reach()
    elif mission.objective_type == "DEFEND": mission.set_defend_presence(d <= 7.0)

func _request_air_support() -> void:
    if is_instance_valid(vehicles) and vehicles.request_air_support(): status.text = "HAVA DESTEĞİ AKTİF • %s" % selected_country
    else: status.text = "HAVA DESTEĞİ HAZIR DEĞİL"

func _request_armor_support() -> void:
    if is_instance_valid(vehicles) and vehicles.request_armor_support(): status.text = "ZIRHLI DESTEK AKTİF • %s" % selected_country
    else: status.text = "ZIRHLI DESTEK HAZIR DEĞİL"

func _raise_strategic_alert() -> void:
    if is_instance_valid(vehicles): vehicles.raise_strategic_alert()

func _on_support_event(title: String, detail: String) -> void:
    status.text = "%s • %s" % [title, detail]

func _on_enemy_died() -> void:
    score += 100; mission.register_kill(); waves.register_enemy_killed(); save.score = score; save.save_game()

func _on_objective(title: String, progress: String) -> void:
    objective.text = "%s  [%s]" % [title, progress]

func _on_environment_changed(time_phase: String, weather: String) -> void:
    if is_instance_valid(info): info.text = "ATMOSFER • %s • %s" % [time_phase, weather]

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
    var op: Array = OperationData.get_operation(selected_country, operation_index)
    var reward: int = int(op[3]) * 250
    save.complete_operation(selected_country, operation_index, reward); score = save.score
    status.text = "OPERASYON TAMAMLANDI • +%d XP" % reward; objective.text = "HEDEF TAMAMLANDI"
    news.play_result(selected_country, str(op[0]), str(op[1]), score, save.xp, diplomacy.get_allies(selected_country).size(), diplomacy.get_alert_text())

func _clear_enemies() -> void:
    for e in enemies:
        if is_instance_valid(e): e.queue_free()
    enemies.clear()