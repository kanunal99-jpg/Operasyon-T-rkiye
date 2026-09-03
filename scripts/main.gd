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

var player: CharacterBody3D
var city_arena: Node3D
var mission_manager: Node
var game_manager: Node
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
var map_open := false
var selected_voice := "tr"
var spawned_enemies: Array[Node] = []

func _ready() -> void:
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
    _on_player_hud_changed(player.health, player.ammo, player.reserve_ammo)
    _on_weapon_changed(player.weapon_name)
    _select_operation(0)

func _process(_delta: float) -> void:
    if is_instance_valid(mission_manager) and mission_manager.active and mission_manager.objective_type == "REACH":
        var objective_point := Vector3(0, player.global_position.y, -18)
        if player.global_position.distance_to(objective_point) <= 3.0:
            mission_manager.register_reach()

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
    add_child(sun)
    city_arena = Node3D.new()
    city_arena.set_script(CityArena)
    add_child(city_arena)
    _rebuild_city()

func _rebuild_city() -> void:
    if is_instance_valid(city_arena):
        var op := OperationData.get_operation(GlobalMap.selected_country, operation_index)
        city_arena.configure(GlobalMap.selected_country, op[0], op[1])
        city_arena.build()

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(Player)
    player.position = Vector3(0, 1.2, 25)
    add_child(player)

func _clear_enemies() -> void:
    for enemy in spawned_enemies:
        if is_instance_valid(enemy): enemy.queue_free()
    spawned_enemies.clear()

func _spawn_wave(enemy_count: int) -> void:
    _clear_enemies()
    var positions := [Vector3(-20,1,-20), Vector3(20,1,-20), Vector3(-30,1,15), Vector3(30,1,5), Vector3(0,1,-30), Vector3(-12,1,-34), Vector3(14,1,-34), Vector3(0,1,12), Vector3(25,1,-12), Vector3(-25,1,-12)]
    for i in range(mini(enemy_count, positions.size())):
        var enemy := CharacterBody3D.new()
        enemy.set_script(Enemy)
        enemy.position = positions[i]
        enemy.target = player
        enemy.country = GlobalMap.selected_country
        enemy.died.connect(_on_enemy_died)
        add_child(enemy)
        spawned_enemies.append(enemy)

func _build_hud() -> void:
    var hud := CanvasLayer.new(); hud.name = "HUD"; add_child(hud)
    score_label = Label.new(); score_label.position = Vector2(28,18); score_label.text = "SKOR 0"; hud.add_child(score_label)
    status_label = Label.new(); status_label.position = Vector2(28,55); hud.add_child(status_label)
    mission_label = Label.new(); mission_label.position = Vector2(28,105); hud.add_child(mission_label)
    objective_label = Label.new(); objective_label.position = Vector2(28,135); hud.add_child(objective_label)
    health_label = Label.new(); health_label.position = Vector2(28,165); hud.add_child(health_label)
    weapon_label = Label.new(); weapon_label.position = Vector2(900,70); hud.add_child(weapon_label)
    ammo_label = Label.new(); ammo_label.position = Vector2(1050,30); hud.add_child(ammo_label)
    crosshair = Label.new(); crosshair.text = "+"; crosshair.position = Vector2(632,330); hud.add_child(crosshair)
    var map_button := Button.new(); map_button.text = "DÜNYA / ÜLKE SEÇ"; map_button.position = Vector2(28,205); map_button.size = Vector2(210,55); map_button.pressed.connect(_toggle_world_map); hud.add_child(map_button)
    map_panel = Panel.new(); map_panel.position = Vector2(250,45); map_panel.size = Vector2(780,630); map_panel.visible = false; hud.add_child(map_panel)
    map_label = Label.new(); map_label.position = Vector2(25,18); map_panel.add_child(map_label)
    country_list = VBoxContainer.new(); country_list.position = Vector2(25,65); country_list.size = Vector2(720,260); map_panel.add_child(country_list)
    operation_list = VBoxContainer.new(); operation_list.position = Vector2(25,330); operation_list.size = Vector2(720,170); map_panel.add_child(operation_list)
    language_button = Button.new(); language_button.position = Vector2(25,555); language_button.size = Vector2(350,48); language_button.pressed.connect(_cycle_voice_language); map_panel.add_child(language_button)
    _refresh_country_list(); _refresh_operation_list(); _update_voice_button()
    _add_hold_button(hud,"▲",Vector2(125,510),"move_forward"); _add_hold_button(hud,"▼",Vector2(125,600),"move_back"); _add_hold_button(hud,"◀",Vector2(35,555),"move_left"); _add_hold_button(hud,"▶",Vector2(215,555),"move_right")
    var fire := Button.new(); fire.text = "ATEŞ"; fire.position = Vector2(1080,545); fire.size = Vector2(150,100); fire.button_down.connect(func(): player.touch_fire=true); fire.button_up.connect(func(): player.touch_fire=false); hud.add_child(fire)
    var reload := Button.new(); reload.text = "ŞARJÖR"; reload.position = Vector2(930,585); reload.size = Vector2(130,70); reload.pressed.connect(func(): player.reload()); hud.add_child(reload)
    var weapon_a := Button.new(); weapon_a.text = "1 • TÜFEK"; weapon_a.position = Vector2(760,545); weapon_a.size = Vector2(150,55); weapon_a.pressed.connect(func(): player.equip_weapon("TAARRUZ TÜFEĞİ")); hud.add_child(weapon_a)
    var weapon_b := Button.new(); weapon_b.text = "2 • MAKİNELİ"; weapon_b.position = Vector2(760,605); weapon_b.size = Vector2(150,55); weapon_b.pressed.connect(func(): player.equip_weapon("HAFİF MAKİNELİ")); hud.add_child(weapon_b)

func _refresh_country_list() -> void:
    if not is_instance_valid(country_list): return
    for child in country_list.get_children(): child.queue_free()
    for continent in ["AVRUPA","ASYA/AVRUPA","ASYA","AFRİKA","KUZEY AMERİKA","GÜNEY AMERİKA","OKYANUSYA"]:
        var header := Label.new(); header.text = "— %s —" % continent; country_list.add_child(header)
        for item in GlobalMap.countries_by_continent(continent):
            var button := Button.new()
            button.text = "%s | %s | %s" % [item[0],item[2],"AKTİF" if item[0]==GlobalMap.selected_country else ("AÇIK" if GlobalMap.is_unlocked(item[0]) else "KİLİTLİ")]
            button.disabled = not GlobalMap.is_unlocked(item[0]) and item[0] != "Türkiye"
            button.pressed.connect(func(): _select_country(item[0]))
            country_list.add_child(button)

func _refresh_operation_list() -> void:
    if not is_instance_valid(operation_list): return
    for child in operation_list.get_children(): child.queue_free()
    var header := Label.new(); header.text = "ŞEHİR / OPERASYON"; operation_list.add_child(header)
    var operations := OperationData.get_operations(GlobalMap.selected_country)
    for i in range(operations.size()):
        var item := operations[i]
        var button := Button.new(); button.text = "%s • %s • Zorluk %d" % [item[0],item[1],item[3]]; button.pressed.connect(func(): _select_operation(i)); operation_list.add_child(button)

func _select_operation(index: int) -> void:
    operation_index = index
    var op := OperationData.get_operation(GlobalMap.selected_country, operation_index)
    mission_label.text = "%s • %s" % [op[0],op[1]]
    status_label.text = "GÖREV: %s" % op[2]
    map_label.text = "%s → %s\n%s" % [GlobalMap.selected_country,op[0],op[2]]
    _rebuild_city()
    if is_instance_valid(mission_manager): mission_manager.start(op)
    if is_instance_valid(game_manager):
        game_manager.start_mission(int(op[3]))
        _spawn_wave(game_manager.base_enemy_count)

func _select_country(country: String) -> void:
    if GlobalMap.select_country(country):
        operation_index = 0
        selected_voice = CountryProfile.get_profile(country).voice
        _refresh_country_list(); _refresh_operation_list(); _select_operation(0); _update_voice_button()

func _cycle_voice_language() -> void:
    var profile := CountryProfile.get_profile(GlobalMap.selected_country)
    selected_voice = profile.language if selected_voice == "tr" else "tr"
    _update_voice_button()
    status_label.text = "SES: %s" % ("TÜRKÇE DUBLAJ" if selected_voice == "tr" else "ÜLKE DİLİ")

func _update_voice_button() -> void:
    if not is_instance_valid(language_button): return
    var profile := CountryProfile.get_profile(GlobalMap.selected_country)
    language_button.text = "SES / DUBLAJ: %s" % ("TÜRKÇE" if selected_voice == "tr" else profile.language.to_upper())

func _toggle_world_map() -> void:
    map_open = not map_open; map_panel.visible = map_open
    if map_open: _refresh_country_list(); _refresh_operation_list()

func _add_hold_button(hud: CanvasLayer,text: String,pos: Vector2,action: String) -> void:
    var button := Button.new(); button.text=text; button.position=pos; button.size=Vector2(80,80); button.button_down.connect(func(): Input.action_press(action)); button.button_up.connect(func(): Input.action_release(action)); hud.add_child(button)

func _on_player_hud_changed(health: int,ammo: int,reserve: int) -> void:
    if is_instance_valid(health_label): health_label.text="CAN %d" % health
    if is_instance_valid(ammo_label): ammo_label.text="%02d / %02d" % [ammo,reserve]

func _on_weapon_changed(name: String) -> void:
    if is_instance_valid(weapon_label): weapon_label.text = "SİLAH: %s" % name

func _on_objective_changed(title: String,progress: String) -> void:
    if is_instance_valid(objective_label): objective_label.text="%s [%s]" % [title,progress]

func _on_enemy_died() -> void:
    score += 100
    if is_instance_valid(score_label): score_label.text="SKOR %d" % score
    if is_instance_valid(mission_manager): mission_manager.register_kill()
    if is_instance_valid(game_manager): game_manager.register_enemy_killed()

func _on_wave_changed(wave_number: int, remaining: int) -> void:
    status_label.text="DALGA %d • KALAN %d" % [wave_number, remaining]

func _on_wave_completed(wave_number: int) -> void:
    status_label.text="DALGA %d TAMAMLANDI" % wave_number
    if is_instance_valid(game_manager) and game_manager.active:
        call_deferred("_spawn_next_wave")

func _spawn_next_wave() -> void:
    if not is_instance_valid(game_manager) or not game_manager.active: return
    _spawn_wave(game_manager.get_next_wave_count())

func _on_game_mission_changed(text: String) -> void:
    status_label.text=text

func _on_all_waves_completed() -> void:
    _clear_enemies()
    if is_instance_valid(mission_manager): mission_manager.active = false
    status_label.text="OPERASYON TAMAMLANDI • TÜM DALGALAR"
    objective_label.text="HEDEF TAMAMLANDI"

func _on_mission_completed(reward: int) -> void:
    score += reward
    status_label.text="GÖREV TAMAMLANDI • +%d XP" % reward
    objective_label.text="HEDEF TAMAMLANDI"
    if GlobalMap.selected_country == "Türkiye" and mission_id <= WorldMap.MISSIONS.size():
        WorldMap.complete_mission(mission_id)
        if mission_id < WorldMap.MISSIONS.size(): mission_id += 1
    _refresh_country_list()
