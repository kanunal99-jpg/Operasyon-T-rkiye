extends SceneTree

const OperationData = preload("res://scripts/operation_data.gd")
const GlobalMap = preload("res://scripts/global_world_map.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const WeaponData = preload("res://scripts/weapon_data.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const ContentController = preload("res://scripts/content_controller.gd")
const UpdateManager = preload("res://scripts/update_manager.gd")

func _init() -> void:
    var failures: Array[String] = []

    if UpdateManager.CURRENT_VERSION != "0.1.5":
        failures.append("Güncelleme yöneticisi sürümü beklenmeyen değerde")

    var operations: Array = OperationData.get_operations("Türkiye")
    if operations.size() < 3:
        failures.append("Türkiye için en az 3 operasyon bekleniyor")
    else:
        var op: Array = OperationData.get_operation("Türkiye", 0)
        if op.size() < 4:
            failures.append("Operasyon veri formatı geçersiz")

    var world := GlobalMap.new()
    if world.countries_by_continent("AFRİKA").is_empty():
        failures.append("AFRİKA ülke listesi boş")
    if world.countries_by_continent("AVRUPA").is_empty():
        failures.append("AVRUPA ülke listesi boş")
    if not world.is_unlocked("Türkiye"):
        failures.append("Türkiye başlangıç ülkesi açık değil")

    for weapon_name in WeaponData.names():
        var weapon: Dictionary = WeaponData.get_weapon(str(weapon_name))
        for key in ["damage", "cooldown", "magazine", "reserve", "range", "reload"]:
            if not weapon.has(key):
                failures.append("Silah %s eksik alan: %s" % [str(weapon_name), key])

    var save := SaveManager.new()
    if save.operation_key("Türkiye", 0) != "Türkiye:0":
        failures.append("SaveManager operasyon anahtarı hatalı")
    save.queue_free()
    world.queue_free()

    if failures.is_empty():
        print("GAMEPLAY SMOKE TEST: PASS")
        quit(0)
    else:
        for failure in failures:
            push_error("SMOKE: " + failure)
        print("GAMEPLAY SMOKE TEST: FAIL (%d)" % failures.size())
        quit(1)
