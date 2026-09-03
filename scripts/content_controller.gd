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
var selected_continent := "ASYA/AVRUPA"
var status: Label
var objective: Label
var info: Label
var support_status: Label
var support_panel: Control

func _ready() -> void:
    quality = MobileQuality.new(); add_child(quality)
    save = SaveManager.new(); add_child(save)
    score = save.score
    global_map = GlobalMap.new(); global_map.name = "GlobalWorldMap"; add_child(global_map)
    for saved_country in save.unlocked_countries:
        global_map.unlock_country(str(saved_country))
    selected_country = save.selected_country if save.selected_country != "" else "Türkiye"
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
    _build_hud()
    _show_map_selection()

func _build_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    hud.layer = 10
    add_child(hud)

    status = Label.new(); status.name = "Status"; status.position = Vector2(24, 20); status.add_theme_font_size_override("font_size", 20); hud.add_child(status)
    objective = Label.new(); objective.name = "Objective"; objective.position = Vector2(24, 55); objective.add_theme_font_size_override("font_size", 18); hud.add_child(objective)
    info = Label.new(); info.name = "Info"; info.position = Vector2(24, 88); info.add_theme_font_size_override("font_size", 16); hud.add_child(info)
    support_status = Label.new(); support_status.name = "SupportStatus"; support_status.position = Vector2(24, 118); support_status.add_theme_font_size_override("font_size", 15); hud.add_child(support_status)

    support_panel = Control.new()
    support_panel.name = "SupportPanel"
    support_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    hud.add_child(support_panel)
    var air := Button.new(); air.name = "Air"; air.text = "HAVA"; air.focus_mode = Control.FOCUS_NONE; air.pressed.connect(_request_air_support); support_panel.add_child(air)
    var armor := Button.new(); armor.name = "Armor"; armor.text = "ZIRH"; armor.focus_mode = Control.FOCUS_NONE; armor.pressed.connect(_request_armor_support); support_panel.add_child(armor)
    var strategic := Button.new(); strategic.name = "Strategic"; strategic.text = "ALARM"; strategic.focus_mode = Control.FOCUS_NONE; strategic.pressed.connect(_raise_strategic_alert); support_panel.add_child(strategic)
    _layout_hud()

func _layout_hud() -> void:
    if support_panel == null: return
    var size := get_viewport().get_visible_rect().size
    var scale_factor := clampf(minf(size.x / 1280.0, size.y / 720.0), 0.72, 1.35)
    var button_w := 78.0 * scale_factor
    var button_h := 42.0 * scale_factor
    var gap := 8.0 * scale_factor
    support_panel.position = Vector2(maxf(12.0, size.x - (button_w * 3.0 + gap * 2.0) - 18.0), 20.0 * scale_factor)
    support_panel.size = Vector2(button_w * 3.0 + gap * 2.0, button_h)
    for i in range(3):
        var child := support_panel.get_child(i) as Button
        child.position = Vector2(i * (button_w + gap), 0)
        child.size = Vector2(button_w, button_h)
        child.add_theme_font_size_override("font_size", 14)

func _show_map_selection() -> void:
    map_menu = CanvasLayer.new()
    map_menu.name = "MapSelection"
    map_menu.layer = 100
    add_child(map_menu)
    _rebuild_map_menu()

func _rebuild_map_menu() -> void:
    if map_menu == null: return
    for child in map_menu.get_children(): child.queue_free()
    await get_tree().process_frame

    var backdrop := ColorRect.new()
    backdrop.name = "Backdrop"
    backdrop.color = Color(0.012, 0.018, 0.028, 0.98)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    map_menu.add_child(backdrop)

    var size := get_viewport().get_visible_rect().size
    var title := Label.new()
    title.text = "OPERASYON TÜRKİYE"
    title.position = Vector2(0, 24)
    title.size = Vector2(size.x, 48)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", clampi(int(size.x / 30.0), 24, 36))
    map_menu.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "DÜNYA HARİTASI  •  BÖLGE: %s  •  ÜLKE: %s" % [selected_continent, selected_country]
    subtitle.position = Vector2(20, 72)
    subtitle.size = Vector2(size.x - 40, 36)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 16)
    map_menu.add_child(subtitle)

    var continents := ["ASYA/AVRUPA", "AVRİKA", "KUZEY AMERİKA", "GÜNEY AMERİKA", "OKYANUSYA"]
    var continent_scroll := HScrollBar.new()
    continent_scroll.visible = false
    map_menu.add_child(continent_scroll)
    var tab_y := 112.0
    var tab_w := minf(180.0, maxf(110.0, (size.x - 60.0) / 5.0))
    var tab_gap := 8.0
    var total := tab_w * continents.size() + tab_gap * (continents.size() - 1)
    var start_x := maxf(10.0, (size.x - total) * 0.5)
    for i in range(continents.size()):
        var tab := Button.new()
        tab.text = continents[i]
        tab.position = Vector2(start_x + i * (tab_w + tab_gap), tab_y)
        tab.size = Vector2(tab_w, 40)
        tab.focus_mode = Control.FOCUS_NONE
        tab.pressed.connect(_select_continent.bind(continents[i]))
        map_menu.add_child(tab)

    var countries := global_map.countries_by_continent(selected_continent)
    var scroll := ScrollContainer.new()
    scroll.name = "CountryScroll"
    scroll.position = Vector2(18, 162)
    scroll.size = Vector2(size.x - 36, size.y - 300)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    map_menu.add_child(scroll)
    var grid := GridContainer.new()
    grid.name = "CountryGrid"
    grid.columns = 3 if size.x >= 900 else 2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    scroll.add_child(grid)

    for item in countries:
        var country_name := str(item[0])
        var capital := str(item[2])
        var difficulty := int(item[3])
        var unlocked := global_map.is_unlocked(country_name)
        var card := Button.new()
        card.text = ("✓ " if unlocked else "🔒 ") + country_name + "\n" + capital + " • Zorluk %d" % difficulty
        card.custom_minimum_size = Vector2(maxf(140.0, (size.x - 70.0) / float(grid.columns)), 72)
        card.focus_mode = Control.FOCUS_NONE
        card.disabled = not unlocked
        if unlocked: card.pressed.connect(_select_country.bind(country_name))
        grid.add_child(card)

    var selected := Label.new()
    selected.name = "SelectedCountry"
    selected.text = "SEÇİLİ: %s  •  Sonraki adım: operasyon haritası" % selected_country
    selected.position = Vector2(20, size.y - 125)
    selected.size = Vector2(size.x - 40, 32)
    selected.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    map_menu.add_child(selected)

    var operations_button := Button.new()
    operations_button.text = "OPERASYONLARA GEÇ"
    operations_button.position = Vector2(maxf(20, size.x * 0.5 - 170), size.y - 82)
    operations_button.size = Vector2(340, 58)
    operations_button.focus_mode = Control.FOCUS_NONE
    operations_button.pressed.connect(_show_operation_selection)
    map_menu.add_child(operations_button)

func _select_continent(continent: String) -> void:
    selected_continent = continent
    _rebuild_map_menu()

func _select_country(country_name: String) -> void:
    if not global_map.select_country(country_name): return
    selected_country = country_name
    save.selected_country = selected_country
    save.save_game()
    _rebuild_map_menu()

func _show_operation_selection() -> void:
    if map_menu == null: return
    for child in map_menu.get_children(): child.queue_free()
    await get_tree().process_frame
    var size := get_viewport().get_visible_rect().size
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.012, 0.018, 0.028, 0.98)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    map_menu.add_child(backdrop)

    var title := Label.new(); title.text = "%s • OPERASYON HARİTALARI" % selected_country; title.position = Vector2(20, 32); title.size = Vector2(size.x - 40, 55); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 28); map_menu.add_child(title)
    var operations: Array = OperationData.get_operations(selected_country)
    var card_w := minf(350.0, (size.x - 70.0) / 3.0)
    var gap := 12.0
    var total := card_w * 3.0 + gap * 2.0
    var start_x := maxf(20.0, (size.x - total) * 0.5)
    for i in range(mini(3, operations.size())):
        var op: Array = operations[i]
        var card := Button.new()
        card.name = "OperationCard%d" % i
        var completed := save.is_operation_completed(selected_country, i)
        card.text = "%s\n%s\n\n%s\nZORLUK %d\n%s" % [str(op[0]), str(op[1]), str(op[2]), int(op[3]), "✓ TAMAMLANDI" if completed else "HAZIR"]
        card.position = Vector2(start_x + i * (card_w + gap), 145)
        card.size = Vector2(card_w, 285)
        card.focus_mode = Control.FOCUS_NONE
        card.add_theme_font_size_override("font_size", 18)
        card.pressed.connect(_select_map.bind(i))
        map_menu.add_child(card)

    var back := Button.new(); back.text = "‹ DÜNYA HARİTASINA DÖN"; back.position = Vector2(20, size.y - 70); back.size = Vector2(230, 50); back.focus_mode = Control.FOCUS_NONE; back.pressed.connect(_rebuild_map_menu); map_menu.add_child(back)

func _select_map(index: int) -> void:
    operation_index = clampi(index, 0, 2)
    save.selected_operation = operation_index
    save.selected_country = selected_country
    save.save_game()
    if is_instance_valid(map_menu): map_menu.queue_free()
    _start_operation(operation_index)

func _start_operation(index: int) -> void:
    operation_index = clampi(index, 0, 2)
    mission_finished = false
    score = save.score
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
    objective_marker.name = "ObjectiveMarker"
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
    var p: Vector3 = city.get_objective_position(); p.y = player.global_position.y
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
    score += 100
    mission.register_kill(); waves.register_enemy_killed()
    save.score = score; save.save_game()

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
