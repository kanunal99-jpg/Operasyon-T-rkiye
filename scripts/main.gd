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

var player: CharacterBody3D
var city_arena: Node3D
var mission_manager: Node
var game_manager: Node
var save_manager: Node
var alliance_manager: Node
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

func _build_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)
    score_label = Label.new(); score_label.position = Vector2(28,18); hud.add_child(score_label)
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
    alliance_button = Button.new(); alliance_button.position = Vector2(395,555); alliance_button.size = Vector2(350,48); alliance_button.pressed.connect(_propose_next_alliance); map_panel.add_child(alliance_button)
    _refresh_country_list(); _refresh_operation_list(); _update_voice_button(); _update_alliance_button()
    _add_hold_button(hud,"▲",Vector2(125,510),"move_forward"); _add_hold_button(hud,"▼",Vector2(125,600),"move_back"); _add_hold_button(hud,"◀",Vector2(35,555),"move_left"); _add_hold_button(hud,"▶",Vector2(215,555),"move_right")
    var fire := Button.new(); fire.text = "ATEŞ"; fire.position = Vector2(1080,545); fire.size = Vector2(150,100); fire.button_down.connect(func(): player.touch_fire=true); fire.button_up.connect(func(): player.touch_fire=false); hud.add_child(fire)
    var reload := Button.new(); reload.text = "ŞARJÖR"; reload.position = Vector2(930,585); reload.size = Vector2(130,70); reload.pressed.connect(func(): player.reload()); hud.add_child(reload)
    var weapon_a := Button.new(); weapon_a.text = "1 • TÜFEK"; weapon_a.position = Vector2(760,545); weapon_a.size = Vector2(150,55); weapon_a.pressed.connect(func(): player.equip_weapon("TAARRUZ TÜFEĞİ")); hud.add_child(weapon_a)
    var weapon_b := Button.new(); weapon_b.text = "2 • MAKİNELİ"; weapon_b.position = Vector2(760,605); weapon_b.size = Vector2(150,55); weapon_b.pressed.connect(func(): player.equip_weapon("HAFİF MAKİNELİ")); hud.add_child(weapon_b)
    var weapon_c := Button.new(); weapon_c.text = "3 • KESKİN"; weapon_c.position = Vector2(930,515); weapon_c.size = Vector2(130,55); weapon_c.pressed.connect(func(): player.equip_weapon("KESKİN NİŞANCI")); hud.add_child(weapon_c)

func _refresh_country_list() -> void:
    if not is_instance_valid(country_list): return
    for child in country_list.get_children(): child.queue_free()
    for continent in ["AVRUPA","ASYA/AVRUPA","ASYA","AFRİKA","KUZEY AMERİKA","GÜNEY AMERİKA","OKYANUSYA"]:
        var header := Label.new(); header.text = "— %s —" % continent; country_list.add_child(header)
        for item in GlobalMap.countries_by_continent(continent):
            var button := Button.new()
            var country := str(item[0])
            button.text = "%s | %s | %s | %s" % [country,item[2],"AKTİF" if country==GlobalMap.selected_country else ("AÇIK" if GlobalMap.is_unlocked(country) else "KİLİTLİ"),alliance_manager.get_diplomacy_state(country)]
            button.disabled = not GlobalMap.is_unlocked(country) and country != "Türkiye"
            button.pressed.connect(func(): _select_country(country))
            country_list.add_child(button)

func _refresh_operation_list() -> void:
    if not is_instance_valid(operation_list): return
    for child in operation_list.get_children(): child.queue_free()
    var header := Label.new(); header.text = "ŞEHİR / OPERASYON"; operation_list.add_child(header)
    var operations := OperationData.get_operations(GlobalMap.selected_country)
    for i in range(operations.size()):
        var item := operations[i]
        var done := " ✓" if save_manager != null and save_manager.is_operation_completed(GlobalMap.selected_country, i) else ""
        var button := Button.new(); button.text = "%s • %s • Zorluk %d%s" % [item[0],item[1],item[3],done]; button.pressed.connect(func(): _select_operation(i)); operation_list.add_child(button)

func _build_briefing_cards(country: String, city: String, operation: String) -> Array[Dictionary]:
    var ally_count := alliance_manager.get_allies(country).size()
    var state := alliance_manager.get_diplomacy_state(country)
    var relation_note := "Diplomatik kanallar açık." if state != "GERİLİM" else "Başkentlerde gerilim yükseliyor."
    return [
        {"category":"DÜNYA HABERLERİ • SON DAKİKA", "headline":"%s HATTINDA KRİZ ALARMI" % country.to_upper(), "body":"%s çevresinde yeni gelişmeler yaşanıyor. %s Operasyon merkezi birlikleri %s görevi için hazırlıyor." % [city, relation_note, operation], "location":"CANLI YAYIN • %s" % city},
        {"category":"BAŞKANLIK AÇIKLAMASI", "headline":"KURGUSAL HÜKÜMETTEN ACİL AÇIKLAMA", "body":"Kurgusal devlet başkanı, vatandaşların güvenliği için gerekli tedbirlerin alındığını açıkladı. Kriz yönetim masası gece boyunca açık kalacak.", "location":"BAŞKENT • ULUSAL BASIN MERKEZİ"},
        {"category":"İTTİFAK MASASI", "headline":"MÜTTEFİKLER HAZIRLIK TOPLANTISINDA", "body":"Mevcut müttefik sayısı: %d. İstihbarat, lojistik ve savunma desteği seçenekleri değerlendiriliyor. Yeni diplomatik teklifler masada." % ally_count, "location":"ORTAK KRİZ MASASI • ALARM %s" % alliance_manager.get_alert_text()},
        {"category":"GAZETE • ÖZEL BASKI", "headline":"DÜNYA YENİ BİR OPERASYONU BEKLİYOR", "body":"Başkentlerde diplomasi sürerken sahadaki birlikler görev emrini bekliyor. Şimdi karar zamanı: görev başlıyor.", "location":"ULUSLARARASI BASIN • GECE BASKISI"}
    ]

func _select_operation(index: int) -> void:
    var operations := OperationData.get_operations(GlobalMap.selected_country)
    operation_index = clampi(index, 0, operations.size() - 1)
    var op := OperationData.get_operation(GlobalMap.selected_country, operation_index)
    mission_finished = false
    mission_label.text = "%s • %s" % [op[0],op[1]]
    status_label.text = "GÖREV: %s" % op[2]
    _rebuild_city()
    if is_instance_valid(save_manager):
        save_manager.selected_country = GlobalMap.selected_country
        save_manager.selected_operation = operation_index
        save_manager.save_game()
    if is_instance_valid(mission_manager): mission_manager.start(op)
    if is_instance_valid(game_manager):
        game_manager.start_mission(int(op[3]))
        if mission_manager.objective_type == "DEFEND" or mission_manager.objective_type == "SURVIVE":
            game_manager.set_endless_waves()
        _spawn_wave(game_manager.base_enemy_count)
    alliance_manager.raise_alert(int(op[3]) * 3)
    _update_objective_marker()
    if is_instance_valid(news_cutscene):
        news_cutscene.play_briefing(GlobalMap.selected_country, op[0], op[1], alliance_manager.get_allies(GlobalMap.selected_country).size(), _build_briefing_cards(GlobalMap.selected_country, op[0], op[1]))

func _update_objective_marker() -> void:
    if not is_instance_valid(objective_marker) or not is_instance_valid(mission_manager): return
    objective_marker.visible = mission_manager.objective_type == "REACH" or mission_manager.objective_type == "DEFEND"
    if mission_manager.objective_type == "DEFEND":
        objective_marker.scale = Vector3(1.8,1.0,1.8)
    else:
        objective_marker.scale = Vector3.ONE

func _select_country(country: String) -> void:
    if GlobalMap.select_country(country):
        operation_index = 0
        alliance_candidate_index = 0
        selected_voice = CountryProfile.get_profile(country).voice
        _refresh_country_list(); _refresh_operation_list(); _select_operation(0); _update_voice_button(); _update_alliance_button()

func _cycle_voice_language() -> void:
    var profile := CountryProfile.get_profile(GlobalMap.selected_country)
    selected_voice = profile.language if selected_voice == "tr" else "tr"
    _update_voice_button()
    status_label.text = "SES: %s" % ("TÜRKÇE DUBLAJ" if selected_voice == "tr" else "ÜLKE DİLİ")

func _update_voice_button() -> void:
    if not is_instance_valid(language_button): return
    var profile := CountryProfile.get_profile(GlobalMap.selected_country)
    language_button.text = "SES / DUBLAJ: %s" % ("TÜRKÇE" if selected_voice == "tr" else profile.language.to_upper())

func _get_alliance_candidates() -> Array:
    var candidates: Array = []
    for item in GlobalMap.COUNTRIES:
        var country := str(item[0])
        if country != GlobalMap.selected_country and GlobalMap.is_unlocked(country) and alliance_manager.can_form_alliance(GlobalMap.selected_country, country): candidates.append(country)
    return candidates

func _update_alliance_button() -> void:
    if not is_instance_valid(alliance_button): return
    var candidates := _get_alliance_candidates()
    if candidates.is_empty():
        alliance_button.text = "İTTİFAK: UYGUN TEKLİF YOK"; alliance_button.disabled = true; return
    alliance_candidate_index = clampi(alliance_candidate_index, 0, candidates.size() - 1)
    alliance_button.text = "İTTİFAK TEKLİFİ: %s" % candidates[alliance_candidate_index]
    alliance_button.disabled = false

func _propose_next_alliance() -> void:
    var candidates := _get_alliance_candidates()
    if candidates.is_empty(): _update_alliance_button(); return
    var candidate := candidates[alliance_candidate_index]
    if alliance_manager.propose_alliance(GlobalMap.selected_country, candidate):
        save_manager.set_diplomacy_state(alliance_manager.export_state()); alliance_candidate_index = 0
    else:
        alliance_candidate_index = (alliance_candidate_index + 1) % candidates.size()
    _update_alliance_button(); _refresh_country_list()

func _on_diplomacy_changed(message: String) -> void:
    if is_instance_valid(status_label): status_label.text = message
    _update_alliance_button()
    if is_instance_valid(save_manager): save_manager.set_diplomacy_state(alliance_manager.export_state())

func _toggle_world_map() -> void:
    map_open = not map_open; map_panel.visible = map_open
    if map_open: _refresh_country_list(); _refresh_operation_list(); _update_alliance_button()

func _add_hold_button(hud: CanvasLayer,text: String,pos: Vector2,action: String) -> void:
    var button := Button.new(); button.text=text; button.position=pos; button.size=Vector2(80,80); button.button_down.connect(func(): Input.action_press(action)); button.button_up.connect(func(): Input.action_release(action)); hud.add_child(button)

func _on_player_hud_changed(health: int,ammo: int,reserve: int) -> void:
    if is_instance_valid(health_label): health_label.text="CAN %d" % health
    if is_instance_valid(ammo_label): ammo_label.text="%02d / %02d" % [ammo,reserve]
    if is_instance_valid(score_label): score_label.text="SKOR %d" % score

func _on_weapon_changed(name: String) -> void:
    if is_instance_valid(weapon_label): weapon_label.text = "SİLAH: %s" % name

func _on_objective_changed(title: String,progress: String) -> void:
    if is_instance_valid(objective_label): objective_label.text="%s [%s]" % [title,progress]
    _update_objective_marker()

func _on_enemy_died() -> void:
    score += 100
    if is_instance_valid(mission_manager): mission_manager.register_kill()
    if is_instance_valid(game_manager): game_manager.register_enemy_killed()
    if is_instance_valid(save_manager): save_manager.score = score
    if is_instance_valid(score_label): score_label.text="SKOR %d" % score

func _on_wave_changed(wave_number: int, remaining: int) -> void:
    if is_instance_valid(status_label): status_label.text="DALGA %d • KALAN %d" % [wave_number, remaining]

func _on_wave_completed(wave_number: int) -> void:
    if is_instance_valid(status_label): status_label.text="DALGA %d TAMAMLANDI" % wave_number
    if is_instance_valid(game_manager) and game_manager.active:
        call_deferred("_spawn_next_wave")

func _spawn_next_wave() -> void:
    if not is_instance_valid(game_manager) or not game_manager.active or mission_finished: return
    _spawn_wave(game_manager.get_next_wave_count())

func _on_game_mission_changed(text: String) -> void:
    if is_instance_valid(status_label): status_label.text=text

func _on_all_waves_completed() -> void:
    if is_instance_valid(mission_manager) and mission_manager.active:
        return
    _clear_enemies()
    _finish_operation()

func _on_mission_completed(_reward: int) -> void:
    if mission_finished: return
    if is_instance_valid(game_manager): game_manager.stop_mission()
    _clear_enemies()
    _finish_operation()

func _finish_operation() -> void:
    if mission_finished: return
    mission_finished = true
    if is_instance_valid(mission_manager): mission_manager.active = false
    var op := OperationData.get_operation(GlobalMap.selected_country, operation_index)
    var reward := int(op[3]) * 250
    if is_instance_valid(save_manager):
        save_manager.complete_operation(GlobalMap.selected_country, operation_index, reward)
        score = save_manager.score
    alliance_manager.lower_alert(10)
    if is_instance_valid(save_manager): save_manager.set_diplomacy_state(alliance_manager.export_state())
    status_label.text="OPERASYON TAMAMLANDI • +%d XP" % reward
    objective_label.text="HEDEF TAMAMLANDI"
    if GlobalMap.selected_country == "Türkiye" and mission_id <= WorldMap.MISSIONS.size():
        WorldMap.complete_mission(mission_id)
        if mission_id < WorldMap.MISSIONS.size(): mission_id += 1
    _refresh_country_list(); _refresh_operation_list()
    if is_instance_valid(news_cutscene):
        news_cutscene.play_result(GlobalMap.selected_country, op[0], op[1], score, save_manager.xp, alliance_manager.get_allies(GlobalMap.selected_country).size(), alliance_manager.get_alert_text())
