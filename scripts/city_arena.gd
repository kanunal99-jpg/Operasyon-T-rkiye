extends Node3D

# Procedural city arena: lightweight mobile-first geometry with country/city themes.
var country := "Türkiye"
var city := "İstanbul"
var operation := "Boğaz Hattı"

func configure(country_name: String, city_name: String, operation_name: String) -> void:
    country = country_name
    city = city_name
    operation = operation_name

func build() -> void:
    _clear_generated()
    _add_ground()
    _add_roads()
    _add_buildings()
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

func _add_buildings() -> void:
    var theme := _theme_color(country)
    var positions := [Vector3(-25, 6, -22), Vector3(24, 8, -23), Vector3(-27, 5, 22), Vector3(25, 7, 22), Vector3(-12, 4, -28), Vector3(12, 5, 28)]
    var sizes := [Vector3(12, 12, 12), Vector3(14, 16, 10), Vector3(11, 10, 13), Vector3(15, 14, 11), Vector3(9, 8, 12), Vector3(10, 10, 13)]
    for i in range(positions.size()):
        _add_box("Building_%d" % i, positions[i], sizes[i], theme, true)

func _add_objective() -> void:
    var marker := MeshInstance3D.new()
    marker.name = "MissionObjective"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.7
    mesh.bottom_radius = 0.7
    mesh.height = 2.0
    marker.mesh = mesh
    marker.position = Vector3(0, 1, -22)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#d9a441")
    material.emission_enabled = true
    material.emission = Color("#5a4218")
    marker.material_override = material
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
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    mesh.material_override = material
    body.add_child(mesh)
    if collision_enabled:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    add_child(body)

func _theme_color(country_name: String) -> Color:
    var themes := {
        "Türkiye": Color("#7a7568"), "Yunanistan": Color("#7b827c"), "Almanya": Color("#656a6c"),
        "Fransa": Color("#72777c"), "İtalya": Color("#80796d"), "İspanya": Color("#827768"),
        "ABD": Color("#686d70"), "Japonya": Color("#707477"), "Çin": Color("#6e6a63"),
        "Hindistan": Color("#7b7468"), "Avustralya": Color("#73766e")
    }
    return themes.get(country_name, Color("#70746f"))
