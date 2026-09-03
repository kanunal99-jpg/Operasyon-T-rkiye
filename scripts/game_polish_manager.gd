extends Node

# Runtime polish layer: keeps the existing systems intact while improving readability,
# touch ergonomics, combat feedback and small-screen resilience.

var controller: Node
var player: Node
var hud: CanvasLayer
var top_bar: PanelContainer
var health_label: Label
var ammo_label: Label
var mission_label: Label
var crosshair: Label
var hit_marker: Label
var hint_label: Label
var last_health := -1
var last_ammo := -1
var last_reserve := -1
var hit_timer := 0.0
var last_mission_text := ""
var last_wave := -1

func _ready() -> void:
    call_deferred("_bind_runtime")

func _bind_runtime() -> void:
    controller = get_parent()
    await get_tree().process_frame
    if controller == null:
        return
    player = controller.get("player")
    if not is_instance_valid(player):
        await get_tree().create_timer(0.35).timeout
        player = controller.get("player")
    _build_hud()
    _connect_signals()
    _layout()

func _connect_signals() -> void:
    if not is_instance_valid(player):
        return
    if player.has_signal("hud_changed"):
        player.hud_changed.connect(_on_hud_changed)
    if player.has_signal("damage_feedback"):
        player.damage_feedback.connect(_on_damage_feedback)
    var waves: Node = controller.get("waves")
    if is_instance_valid(waves) and waves.has_signal("wave_changed"):
        waves.wave_changed.connect(_on_wave_changed)
    var mission: Node = controller.get("mission")
    if is_instance_valid(mission) and mission.has_signal("objective_changed"):
        mission.objective_changed.connect(_on_mission_changed)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "GameplayPolishHUD"
    hud.layer = 45
    add_child(hud)

    top_bar = PanelContainer.new()
    top_bar.name = "StatusBar"
    top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(top_bar)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 22)
    top_bar.add_child(row)

    health_label = Label.new()
    health_label.text = "CAN 100"
    health_label.add_theme_font_size_override("font_size", 18)
    row.add_child(health_label)

    ammo_label = Label.new()
    ammo_label.text = "MÜHİMMAT 30 / 90"
    ammo_label.add_theme_font_size_override("font_size", 18)
    row.add_child(ammo_label)

    mission_label = Label.new()
    mission_label.text = "HAZIR"
    mission_label.add_theme_font_size_override("font_size", 17)
    row.add_child(mission_label)

    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crosshair.add_theme_font_size_override("font_size", 28)
    hud.add_child(crosshair)

    hit_marker = Label.new()
    hit_marker.text = "✕"
    hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hit_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hit_marker.visible = false
    hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hit_marker.add_theme_font_size_override("font_size", 34)
    hud.add_child(hit_marker)

    hint_label = Label.new()
    hint_label.text = "NİŞAN • ATEŞ • DOLDUR"
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hint_label.add_theme_font_size_override("font_size", 13)
    hud.add_child(hint_label)

func _layout() -> void:
    if hud == null:
        return
    var size := get_viewport().get_visible_rect().size
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var scale_factor := clampf(minf(size.x / 1280.0, size.y / 720.0), 0.70, 1.20)
    top_bar.position = Vector2(16.0 * scale_factor, 12.0 * scale_factor)
    top_bar.size = Vector2(minf(size.x - 32.0 * scale_factor, 570.0 * scale_factor), 46.0 * scale_factor)
    crosshair.position = Vector2(size.x * 0.5 - 24.0 * scale_factor, size.y * 0.5 - 24.0 * scale_factor)
    crosshair.size = Vector2(48.0 * scale_factor, 48.0 * scale_factor)
    hit_marker.position = crosshair.position
    hit_marker.size = crosshair.size
    hint_label.position = Vector2(size.x * 0.5 - 150.0 * scale_factor, size.y - 38.0 * scale_factor)
    hint_label.size = Vector2(300.0 * scale_factor, 24.0 * scale_factor)

    _layout_touch_controls(size, scale_factor)

func _layout_touch_controls(size: Vector2, s: float) -> void:
    if not is_instance_valid(player):
        return
    var layer: Control = player.get("mobile_controls")
    if not is_instance_valid(layer):
        return
    var joystick = player.get("move_joystick")
    var sprint = player.get("sprint_button")
    var crouch = player.get("crouch_button")
    var slide = player.get("slide_button")
    var jump = player.get("jump_button")
    var aim = player.get("aim_button")
    var fire = player.get("fire_button")
    var reload = player.get("reload_button")
    if not is_instance_valid(joystick) or not is_instance_valid(fire):
        return

    # Four clear touch zones: movement, mobility, combat, reload. The combat cluster
    # never shares the fire-button rectangle with aim/reload.
    var pad := 18.0 * s
    var js := 164.0 * s
    joystick.position = Vector2(pad, size.y - js - pad)
    joystick.size = Vector2(js, js)

    var bw := 82.0 * s
    var bh := 48.0 * s
    var mobility_x := pad + js + 10.0 * s
    var mobility_y := size.y - (bh * 3.0 + 20.0 * s) - pad
    _place_button(sprint, mobility_x, mobility_y, bw, bh)
    _place_button(crouch, mobility_x, mobility_y + bh + 8.0 * s, bw, bh)
    _place_button(slide, mobility_x, mobility_y + (bh + 8.0 * s) * 2.0, bw, bh)
    _place_button(jump, mobility_x + bw + 10.0 * s, mobility_y, bw, bh * 2.15)

    var fire_size := 108.0 * s
    var fire_x := size.x - fire_size - pad
    var fire_y := size.y - fire_size - pad
    _place_button(fire, fire_x, fire_y, fire_size, fire_size)
    _place_button(aim, fire_x - 142.0 * s, fire_y - 70.0 * s, 132.0 * s, 58.0 * s)
    _place_button(reload, fire_x - 92.0 * s, fire_y + fire_size + 8.0 * s, 82.0 * s, 48.0 * s)

func _place_button(button: Control, x: float, y: float, w: float, h: float) -> void:
    if is_instance_valid(button):
        button.position = Vector2(x, y)
        button.size = Vector2(w, h)

func _process(delta: float) -> void:
    if hud == null:
        return
    if hit_timer > 0.0:
        hit_timer -= delta
        hit_marker.visible = true
        hit_marker.modulate.a = clampf(hit_timer * 6.0, 0.0, 1.0)
    else:
        hit_marker.visible = false

    var map_menu = controller.get("map_menu") if is_instance_valid(controller) else null
    var gameplay_layer = player.get("mobile_controls") if is_instance_valid(player) else null
    var map_open: bool = is_instance_valid(map_menu) and map_menu.visible
    if is_instance_valid(gameplay_layer):
        gameplay_layer.visible = not map_open
    _layout()

func _on_hud_changed(health: int, ammo: int, reserve: int) -> void:
    last_health = health
    last_ammo = ammo
    last_reserve = reserve
    health_label.text = "CAN %d" % health
    ammo_label.text = "MÜHİMMAT %d / %d" % [ammo, reserve]

func _on_damage_feedback(_amount: int, health: int) -> void:
    health_label.text = "CAN %d" % health
    hit_timer = 0.20

func _on_wave_changed(wave: int, remaining: int) -> void:
    last_wave = wave
    mission_label.text = "DALGA %d • %d DÜŞMAN" % [wave, remaining]

func _on_mission_changed(text: String) -> void:
    last_mission_text = text
    mission_label.text = text

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        call_deferred("_layout")
