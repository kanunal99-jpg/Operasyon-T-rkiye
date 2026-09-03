extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")

var player: CharacterBody3D
var score := 0
var score_label: Label
var status_label: Label

func _ready() -> void:
    _build_world()
    _spawn_player()
    _spawn_enemies()
    _build_hud()

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
    var positions := [Vector3(-9,1, -10), Vector3(9,1,-10), Vector3(-14,1,10), Vector3(14,1,1), Vector3(0,1,-17)]
    for p in positions:
        var enemy := CharacterBody3D.new()
        enemy.set_script(Enemy)
        enemy.position = p
        enemy.target = player
        enemy.died.connect(_on_enemy_died)
        add_child(enemy)

func _build_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)

    score_label = Label.new()
    score_label.position = Vector2(28, 24)
    score_label.add_theme_font_size_override("font_size", 28)
    score_label.text = "SKOR 0"
    hud.add_child(score_label)

    status_label = Label.new()
    status_label.position = Vector2(28, 62)
    status_label.add_theme_font_size_override("font_size", 20)
    status_label.text = "OPERASYON BAŞLADI"
    hud.add_child(status_label)

    var fire := Button.new()
    fire.text = "ATEŞ"
    fire.position = Vector2(1080, 560)
    fire.size = Vector2(150, 100)
    fire.add_theme_font_size_override("font_size", 24)
    fire.button_down.connect(func(): player.touch_fire = true)
    fire.button_up.connect(func(): player.touch_fire = false)
    hud.add_child(fire)

    var reload := Button.new()
    reload.text = "ŞARJÖR"
    reload.position = Vector2(930, 590)
    reload.size = Vector2(130, 70)
    reload.pressed.connect(func(): player.reload())
    hud.add_child(reload)

    var hint := Label.new()
    hint.position = Vector2(28, 650)
    hint.text = "PC: WASD + fare | Mobil: ekrandaki kontroller"
    hint.add_theme_font_size_override("font_size", 16)
    hud.add_child(hint)

func _on_enemy_died() -> void:
    score += 100
    if is_instance_valid(score_label):
        score_label.text = "SKOR %d" % score
    if score >= 500:
        status_label.text = "GÖREV TAMAMLANDI"
