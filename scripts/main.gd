extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const WorldMap = preload("res://scripts/world_map.gd")
const GlobalMap = preload("res://scripts/global_world_map.gd")
const CountryProfile = preload("res://scripts/country_profile.gd")
const OperationData = preload("res://scripts/operation_data.gd")

var player: CharacterBody3D
var score := 0
var mission_id := 1
var operation_index := 0
var score_label: Label
var status_label: Label
var health_label: Label
var ammo_label: Label
var mission_label: Label
var crosshair: Label
var map_panel: Panel
var map_label: Label
var country_list: VBoxContainer
var operation_list: VBoxContainer
var language_button: Button
var map_open := false
var selected_voice := "tr"

func _ready() -> void:
    _build_world()
    _spawn_player()
    _spawn_enemies()
    _build_hud()
    player.hud_changed.connect(_on_player_hud_changed)
    _on_player_hud_changed(player.health, player.ammo, player.reserve_ammo)
    _refresh_operation_list()

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
    var floor := StaticBody3D.new()
    floor.name = "ArenaFloor"
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(45, 0.4, 45)
    mesh.mesh = box
    mesh.position.y = -0.2
    floor.add_child(mesh)
    var shape := CollisionShape3D.new()
    var collider := BoxShape3D.new()
    collider.size = Vector3(45, 0.4, 45)
    shape.shape = collider
    shape.position.y = -0.2
    floor.add_child(shape)
    add_child(floor)
    for data in [[Vector3(0,1,-8),Vector3(12,2,2)], [Vector3(-10,1,4),Vector3(2,2,12)], [Vector3(10,1,7),Vector3(2,2,10)]]:
        _add_cover(data[0], data[1])

func _add_cover(pos: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    body.add_child(mesh)
    var shape := CollisionShape3D.new()
    var collider := BoxShape3D.new()
    collider.size = size
    shape.shape = collider
    body.add_child(shape)
    add_child(body)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(Player)
    player.position = Vector3(0, 1.2, 12)
    add_child(player)

func _spawn_enemies() -> void:
    var positions := [Vector3(-9,1,-10), Vector3(9,1,-10), Vector3(-14,1,10), Vector3(14,1,1), Vector3(0,1,-17)]
    for p in positions:
        var enemy := CharacterBody3D.new()
        enemy.set_script(Enemy)
        enemy.position = p
        enemy.target = player
        enemy.country = GlobalMap.selected_country
        enemy.died.connect(_on_enemy_died)
        add_child(enemy)

func _build_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)
    score_label = Label.new()
    score_label.position = Vector2(28, 18)
    score_label.add_theme_font_size_override("font_size", 28)
    score_label.text = "SKOR 0"
    hud.add_child(score_label)
    status_label = Label.new()
    status_label.position = Vector2(28, 55)
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.text = "OPERASYON BAŞLADI"
    hud.add_child(status_label)
    mission_label = Label.new()
    mission_label.position = Vector2(28, 115)
    mission_label.add_theme_font_size_override("font_size", 17)
    mission_label.text = "GÖREV %d • %s" % [mission_id, WorldMap.get_mission(mission_id).title]
    hud.add_child(mission_label)
    health_label = Label.new()
    health_label.position = Vector2(28, 145)
    health_label.add_theme_font_size_override("font_size", 22)
    hud.add_child(health_label)
    ammo_label = Label.new()
    ammo_label.position = Vector2(1050, 30)
    ammo_label.add_theme_font_size_override("font_size", 24)
    hud.add_child(ammo_label)
    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.position = Vector2(632, 330)
    crosshair.add_theme_font_size_override("font_size", 28)
    hud.add_child(crosshair)
    var map_button := Button.new()
    map_button.text = "DÜNYA / ÜLKE SEÇ"
    map_button.position = Vector2(28, 190)
    map_button.size = Vector2(210, 55)
    map_button.pressed.connect(_toggle_world_map)
    hud.add_child(map_button)
    map_panel = Panel.new()
    map_panel.position = Vector2(250, 45)
    map_panel.size = Vector2(780, 630)
    map_panel.visible = false
    hud.add_child(map_panel)
    map_label = Label.new()
    map_label.position = Vector2(25, 18)
    map_label.add_theme_font_size_override("font_size", 22)
    map_panel.add_child(map_label)
    country_list = VBoxContainer.new()
    country_list.position = Vector2(25, 65)
    country_list.size = Vector2(720, 260)
    map_panel.add_child(country_list)
    operation_list = VBoxContainer.new()
    operation_list.position = Vector2(25, 330)
    operation_list.size = Vector2(720, 170)
    map_panel.add_child(operation_list)
    language_button = Button.new()
    language_button.position = Vector2(25, 555)
    language_button.size = Vector2(350, 48)
    language_button.pressed.connect(_cycle_voice_language)
    map_panel.add_child(language_button)
    _refresh_country_list()
    _update_voice_button()
    _add_hold_button(hud, "▲", Vector2(125, 510), "move_forward")
    _add_hold_button(hud, "▼", Vector2(125, 600), "move_back")
    _add_hold_button(hud, "◀", Vector2(35, 555), "move_left")
    _add_hold_button(hud, "▶", Vector2(215, 555), "move_right")
    var fire := Button.new()
    fire.text = "ATEŞ"
    fire.position = Vector2(1080, 545)
    fire.size = Vector2(150, 100)
    fire.add_theme_font_size_override("font_size", 24)
    fire.button_down.connect(func(): player.touch_fire = true)
    fire.button_up.connect(func(): player.touch_fire = false)
    hud.add_child(fire)
    var reload := Button.new()
    reload.text = "ŞARJÖR"
    reload.position = Vector2(930, 585)
    reload.size = Vector2(130, 70)
    reload.pressed.connect(func(): player.reload())
    hud.add_child(reload)
    var hint := Label.new()
    hint.position = Vector2(28, 675)
    hint.text = "SOL: hareket • SAĞ EKRAN: nişan • ATEŞ • ŞARJÖR"
    hint.add_theme_font_size_override("font_size", 16)
    hud.add_child(hint)

func _refresh_country_list() -> void:
    for child in country_list.get_children():
        child.queue_free()
    var continents := ["AVRUPA", "ASYA/AVRUPA", "ASYA", "AFRİKA", "KUZEY AMERİKA", "GÜNEY AMERİKA", "OKYANUSYA"]
    for continent in continents:
        var header := Label.new()
        header.text = "— %s —" % continent
        header.add_theme_font_size_override("font_size", 18)
        country_list.add_child(header)
        for item in GlobalMap.countries_by_continent(continent):
            var button := Button.new()
            var state := "AKTİF" if item[0] == GlobalMap.selected_country else ("AÇIK" if GlobalMap.is_unlocked(item[0]) else "KİLİTLİ")
            var difficulty := "ZOR" if item[3] == 5 else "NORMAL"
            button.text = "%s | %s | %s | %s" % [item[0], item[2], difficulty, state]
            button.alignment = HORIZONTAL_ALIGNMENT_LEFT
            button.disabled = not GlobalMap.is_unlocked(item[0]) and item[0] != "Türkiye"
            button.pressed.connect(func(): _select_country(item[0]))
            country_list.add_child(button)

func _refresh_operation_list() -> void:
    if not is_instance_valid(operation_list):
        return
    for child in operation_list.get_children():
        child.queue_free()
    var header := Label.new()
    header.text = "ŞEHİR / OPERASYON"
    header.add_theme_font_size_override("font_size", 18)
    operation_list.add_child(header)
    var operations := OperationData.get_operations(GlobalMap.selected_country)
    for i in range(operations.size()):
        var item := operations[i]
        var button := Button.new()
        button.text = "%s • %s • Zorluk %d" % [item[0], item[1], item[3]]
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.pressed.connect(func(): _select_operation(i))
        operation_list.add_child(button)

func _select_operation(index: int) -> void:
    operation_index = index
    var operation := OperationData.get_operation(GlobalMap.selected_country, operation_index)
    mission_label.text = "%s • %s" % [operation[0], operation[1]]
    status_label.text = "GÖREV: %s" % operation[2]
    map_label.text = "%s → %s\n%s" % [GlobalMap.selected_country, operation[0], operation[2]]

func _select_country(country: String) -> void:
    if GlobalMap.select_country(country):
        operation_index = 0
        var profile := CountryProfile.get_profile(country)
        selected_voice = profile.voice
        var operation := OperationData.get_operation(country, 0)
        mission_label.text = "%s • %s" % [operation[0], operation[1]]
        status_label.text = "%s • %s DİLİ • TÜRKÇE DUBLAJ" % [country.to_upper(), profile.language.to_upper()]
        map_label.text = "SEÇİLEN BÖLGE: %s\nBaşkent: %s\nİlk operasyon: %s" % [country, _get_capital(country), operation[1]]
        _update_voice_button()
        _refresh_country_list()
        _refresh_operation_list()

func _get_capital(country: String) -> String:
    for item in GlobalMap.COUNTRIES:
        if item[0] == country:
            return item[2]
    return "—"

func _cycle_voice_language() -> void:
    var profile := CountryProfile.get_profile(GlobalMap.selected_country)
    selected_voice = profile.language if selected_voice == "tr" else "tr"
    _update_voice_button()
    status_label.text = "SES: %s" % ("TÜRKÇE DUBLAJ" if selected_voice == "tr" else "ÜLKE DİLİ")

func _update_voice_button() -> void:
    if not is_instance_valid(language_button):
        return
    var profile := CountryProfile.get_profile(GlobalMap.selected_country)
    language_button.text = "SES / DUBLAJ: %s" % ("TÜRKÇE" if selected_voice == "tr" else profile.language.to_upper())

func _toggle_world_map() -> void:
    map_open = not map_open
    map_panel.visible = map_open
    if map_open:
        _refresh_country_list()
        _refresh_operation_list()

func _add_hold_button(hud: CanvasLayer, text: String, pos: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = text
    button.position = pos
    button.size = Vector2(80, 80)
    button.add_theme_font_size_override("font_size", 28)
    button.button_down.connect(func(): Input.action_press(action))
    button.button_up.connect(func(): Input.action_release(action))
    hud.add_child(button)

func _on_player_hud_changed(health: int, ammo: int, reserve: int) -> void:
    if is_instance_valid(health_label):
        health_label.text = "CAN %d" % health
    if is_instance_valid(ammo_label):
        ammo_label.text = "%02d / %02d" % [ammo, reserve]

func _on_enemy_died() -> void:
    score += 100
    if is_instance_valid(score_label):
        score_label.text = "SKOR %d" % score
    if score >= 500:
        WorldMap.complete_mission(mission_id)
        status_label.text = "GÖREV TAMAMLANDI • YENİ BÖLGE AÇILDI"
        if mission_id < WorldMap.MISSIONS.size():
            mission_id += 1
            mission_label.text = "GÖREV %d • %s" % [mission_id, WorldMap.get_mission(mission_id).title]
        if map_open:
            _refresh_country_list()
