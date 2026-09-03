extends Node3D

# Mobile-friendly procedural soldier visual.
# Uses rounded human proportions and military equipment while keeping the
# current project dependency-free. A future GLB/VRM rig can replace this node
# without changing Enemy AI.

var skin_material: StandardMaterial3D
var uniform_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var helmet_material: StandardMaterial3D

func _ready() -> void:
    _build()

func _mat(color: Color, roughness := 0.82) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _part(name: String, mesh: Mesh, pos: Vector3, material: Material, parent: Node3D = self) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    parent.add_child(n)
    return n

func _capsule(name: String, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return _part(name, mesh, pos, material)

func _build() -> void:
    skin_material = _mat(Color("#a96f4f"), 0.92)
    uniform_material = _mat(Color("#465542"), 0.9)
    dark_material = _mat(Color("#20251f"), 0.82)
    helmet_material = _mat(Color("#303b30"), 0.8)

    var left_leg := _capsule("LeftLeg", 0.115, 0.72, Vector3(-0.19, 0.48, 0), uniform_material)
    var right_leg := _capsule("RightLeg", 0.115, 0.72, Vector3(0.19, 0.48, 0), uniform_material)

    var boot := BoxMesh.new()
    boot.size = Vector3(0.25, 0.14, 0.42)
    _part("LeftBoot", boot, Vector3(-0.19, 0.12, -0.06), dark_material)
    _part("RightBoot", boot, Vector3(0.19, 0.12, -0.06), dark_material)

    var hips := BoxMesh.new()
    hips.size = Vector3(0.55, 0.28, 0.34)
    _part("Hips", hips, Vector3(0, 0.88, 0), uniform_material)

    var torso := CapsuleMesh.new()
    torso.radius = 0.30
    torso.height = 0.78
    var torso_node := _part("Torso", torso, Vector3(0, 1.25, 0), uniform_material)

    var plate := BoxMesh.new()
    plate.size = Vector3(0.58, 0.48, 0.10)
    var vest := _part("Vest", plate, Vector3(0, 1.30, -0.29), dark_material)

    _capsule("Neck", 0.10, 0.18, Vector3(0, 1.70, 0), skin_material)
    var head := SphereMesh.new()
    head.radius = 0.205
    head.height = 0.43
    var head_node := _part("Head", head, Vector3(0, 1.91, 0), skin_material)

    var helmet := SphereMesh.new()
    helmet.radius = 0.27
    helmet.height = 0.27
    var helmet_node := _part("Helmet", helmet, Vector3(0, 2.10, 0), helmet_material)

    var arm_l := _capsule("LeftArm", 0.105, 0.70, Vector3(-0.40, 1.27, -0.01), uniform_material)
    arm_l.rotation.z = deg_to_rad(-10.0)
    var arm_r := _capsule("RightArm", 0.105, 0.70, Vector3(0.40, 1.27, -0.01), uniform_material)
    arm_r.rotation.z = deg_to_rad(10.0)

    var shoulder := SphereMesh.new()
    shoulder.radius = 0.14
    shoulder.height = 0.20
    _part("LeftShoulder", shoulder, Vector3(-0.39, 1.54, 0), uniform_material)
    _part("RightShoulder", shoulder, Vector3(0.39, 1.54, 0), uniform_material)

    var glove := SphereMesh.new()
    glove.radius = 0.105
    glove.height = 0.18
    _part("LeftGlove", glove, Vector3(-0.46, 0.98, -0.16), dark_material)
    _part("RightGlove", glove, Vector3(0.46, 0.98, -0.16), dark_material)

    var rifle := BoxMesh.new()
    rifle.size = Vector3(0.10, 0.10, 0.86)
    var gun := _part("Rifle", rifle, Vector3(0.25, 1.08, -0.40), dark_material)
    gun.rotation_degrees = Vector3(-8, 0, 8)

    var stock := BoxMesh.new()
    stock.size = Vector3(0.14, 0.14, 0.28)
    var stock_node := _part("RifleStock", stock, Vector3(0.13, 1.15, -0.12), dark_material)
    stock_node.rotation_degrees.y = 8

    # Feed the compatibility references expected by Enemy so the new visual
    # can replace the old block model without changing AI/combat code.
    var enemy := get_parent()
    if enemy != null and enemy.has_method("_apply_country_look"):
        enemy.set("body_mesh", torso_node)
        enemy.set("left_arm", arm_l)
        enemy.set("right_arm", arm_r)
        enemy.set("left_leg", left_leg)
        enemy.set("right_leg", right_leg)
        enemy.set("head_mesh", head_node)
        enemy.set("helmet_mesh", helmet_node)
        enemy.set("weapon_mesh", gun)
