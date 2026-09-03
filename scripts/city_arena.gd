extends Node3D

# Mobile-first procedural city arena. Themes are fictionalized gameplay spaces.
var country := "Türkiye"
var city := "İstanbul"
var operation := "Boğaz Hattı"
var theme := "urban"
var seed_value := 1

func configure(country_name: String, city_name: String, operation_name: String) -> void:
    country = country_name
    city = city_name
    operation = operation_name
    theme = _get_theme(country_name, city_name, operation_name)
    seed_value = abs(hash(country_name + ":" + city_name + ":" + operation_name))

func build() -> void:
    _clear_generated()
    _add_ground()
    _add_roads()
    _add_buildings()
    _add_landmarks()
    _add_objective()
    _add_spawn_markers()

func _clear_generated() -> void:
    for child in get_children():
        child.queue_free()

func _add_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "CityGround"
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(90, 0.4, 90)
    mesh.mesh = box
    mesh.material_override = _material(_ground_color())
    mesh.position.y = -0.2
    ground.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(90, 0.4, 90)
    collision.shape = shape
    collision.position.y = -0.2
    ground.add_child(collision)
    add_child(ground)

func _add_roads() -> void:
    _add_box("RoadMain", Vector3(0, 0.02, 0), Vector3(90, 0.08, 8), Color("#202326"), false)
    _add_box("RoadCross", Vector3(0, 0.025, 0), Vector3(8, 0.09, 90), Color("#202326"), false)
    if theme == "coastal":
        _add_box("CoastalRoad", Vector3(0, 0.03, -35), Vector3(90, 0.1, 5), Color("#303436"), false)

func _add_buildings() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var count := 22 if theme == "urban" or theme == "industrial" else 16
    for i in range(count):
        var side := -1.0 if i % 2 == 0 else 1.0
        var x := side * (13.0 + float((i * 7) % 18))
        var z := -32.0 + float((i * 13) % 62)
        if abs(x) < 10 or abs(z) < 6:
            continue
        var width := rng.randf_range(6.0, 12.0)
        var depth := rng.randf_range(6.0, 12.0)
        var height := rng.randf_range(5.0, 15.0)
        if theme == "desert":
            height *= 0.7
        if theme == "snow":
            height *= 0.8
        _add_box("Building_%d" % i, Vector3(x, height * 0.5, z), Vector3(width, height, depth), _building_color(i), true)

func _add_landmarks() -> void:
    if theme == "coastal":
        _add_box("HarborWarehouse", Vector3(0, 3, -32), Vector3(22, 6, 7), Color("#6d6659"), true)
        _add_box("Dock", Vector3(0, 0.4, -39), Vector3(70, 0.8, 5), Color("#49443d"), true)
    elif theme == "desert":
        _add_box("Checkpoint", Vector3(0, 2, -25), Vector3(18, 4, 4), Color("#6e604c"), true)
    elif theme == "snow":
        _add_box("ColdStorage", Vector3(0, 4, -25), Vector3(18, 8, 12), Color("#7b8080"), true)
    elif theme == "industrial":
        _add_box("FactoryBlock", Vector3(0, 5, -27), Vector3(24, 10, 14), Color("#565b5b"), true)
    else:
        _add_box("MissionBlock", Vector3(0, 3, -27), Vector3(18, 6, 10), Color("#686d6c"), true)

func _add_objective() -> void:
    var marker := MeshInstance3D.new()
    marker.name = "MissionObjective"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.7
    mesh.bottom_radius = 0.7
    mesh.height = 2.0
    marker.mesh = mesh
    marker.position = Vector3(0, 1, -18)
    marker.material_override = _material(Color("#d9a441"), true)
    add_child(marker)

func _add_spawn_markers() -> void:
    for p in [Vector3(-30, 1, -30), Vector3(30, 1, -30), Vector3(-30, 1, 30), Vector3(30, 1, 30)]:
        var marker := Marker3D.new()
        marker.position = p
        marker.name = "EnemySpawn"
        add_child(marker)

func _add_box(node_name: String, pos: Vector3, size: Vector3, color: Color, collision_enabled: bool) -> void:
    var body: Node3D = StaticBody3D.new() if collision_enabled else Node3D.new()
    body.name = node_name
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = _material(color)
    body.add_child(mesh)
    if collision_enabled:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    add_child(body)

func _material(color: Color, glow := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    if glow:
        material.emission_enabled = true
        material.emission = color * 0.35
    return material

func _get_theme(country_name: String, city_name: String, operation_name: String) -> String:
    var text := (country_name + " " + city_name + " " + operation_name).to_lower()
    if text.contains("sydney") or text.contains("mumbai") or text.contains("miami") or text.contains("mersin") or text.contains("izmir"):
        return "coastal"
    if text.contains("riyad") or text.contains("cidde") or text.contains("kahire") or text.contains("rabat") or text.contains("mexico"):
        return "desert"
    if text.contains("erzurum") or text.contains("norveç") or text.contains("ottawa"):
        return "snow"
    if text.contains("hamburg") or text.contains("milano") or text.contains("seul") or text.contains("berlin"):
        return "industrial"
    return "urban"

func _ground_color() -> Color:
    if theme == "desert": return Color("#88775d")
    if theme == "snow": return Color("#9ca4a3")
    if theme == "coastal": return Color("#777b76")
    if theme == "industrial": return Color("#626766")
    return Color("#6b6d68")

func _building_color(index: int) -> Color:
    var palettes := {
        "urban": [Color("#74787b"), Color("#6c716f"), Color("#7d7770")],
        "coastal": [Color("#8b8172"), Color("#777d79"), Color("#81776d")],
        "desert": [Color("#8b765b"), Color("#796750"), Color("#9a8364")],
        "snow": [Color("#777d7e"), Color("#697274"), Color("#858b8a")],
        "industrial": [Color("#5d6263"), Color("#666b6a"), Color("#555a5b")]
    }
    var palette: Array = palettes.get(theme, palettes["urban"])
    return palette[index % palette.size()]
