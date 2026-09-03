extends Node

# Final mobile FPS layout: no overlapping controls, landscape-first, thumb-friendly.
var player: Node
var last_size := Vector2.ZERO

func _ready() -> void:
    call_deferred("_apply")

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        player = get_parent().get("player")
    if is_instance_valid(player) and last_size != get_viewport().get_visible_rect().size:
        _apply()

func _apply() -> void:
    if not is_instance_valid(player):
        return
    var controls = player.get("mobile_controls")
    if controls == null:
        return
    var joystick = player.get("move_joystick")
    var sprint = player.get("sprint_button")
    var crouch = player.get("crouch_button")
    var jump = player.get("jump_button")
    var slide = player.get("slide_button")
    var aim = player.get("aim_button")
    var fire = player.get("fire_button")
    var reload = player.get("reload_button")
    if joystick == null or fire == null:
        return

    var size := get_viewport().get_visible_rect().size
    if size.x < 700.0 or size.y < 400.0:
        return
    last_size = size

    var s := clampf(minf(size.x / 1280.0, size.y / 720.0), 0.78, 1.20)
    var pad := 24.0 * s
    var gap := 10.0 * s
    var small_w := 82.0 * s
    var small_h := 50.0 * s
    var joy := 176.0 * s

    # LEFT: movement joystick only + compact movement modifiers above it.
    joystick.position = Vector2(pad, size.y - joy - pad)
    joystick.size = Vector2(joy, joy)

    sprint.position = Vector2(pad, size.y - joy - pad - small_h - gap)
    sprint.size = Vector2(small_w, small_h)
    crouch.position = Vector2(sprint.position.x + small_w + gap, sprint.position.y)
    crouch.size = Vector2(small_w, small_h)
    slide.position = Vector2(crouch.position.x + small_w + gap, crouch.position.y)
    slide.size = Vector2(small_w, small_h)

    # RIGHT: fire is the dominant thumb target. Aim/reload/jump sit around it without overlap.
    var fire_size := 108.0 * s
    var x_right := size.x - pad - fire_size
    var y_bottom := size.y - pad - fire_size
    fire.position = Vector2(x_right, y_bottom)
    fire.size = Vector2(fire_size, fire_size)

    aim.position = Vector2(x_right - 92.0 * s - gap, y_bottom + 26.0 * s)
    aim.size = Vector2(84.0 * s, 54.0 * s)

    reload.position = Vector2(x_right - 92.0 * s - gap, y_bottom - 64.0 * s - gap)
    reload.size = Vector2(84.0 * s, 54.0 * s)

    jump.position = Vector2(x_right, y_bottom - 64.0 * s - gap)
    jump.size = Vector2(fire_size, 54.0 * s)

    # Keep action buttons above the bottom safe area and visually separated.
    last_size = size
