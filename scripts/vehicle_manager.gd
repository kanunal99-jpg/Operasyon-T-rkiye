extends Node3D

signal support_event(title: String, detail: String)

const ROLE_AIR := "AIR"
const ROLE_ARMOR := "ARMOR"
const ROLE_AIR_DEFENSE := "AIR_DEFENSE"
const ROLE_STRATEGIC := "STRATEGIC"
const VehicleActor = preload("res://scripts/vehicle_actor.gd")

var country := "Türkiye"
var profile: Dictionary = {}
var active_support: Array[Dictionary] = []
var spawned_support: Array[Node] = []
var target: Node3D
var airfield_integrity := 100.0
var strategic_alert := 0
var strategic_capability := false

func setup(country_name: String, country_profile: Dictionary = {}, target_node: Node3D = null) -> void:
    country = country_name
    profile = country_profile
    target = target_node
    _clear_support()
    active_support.clear()
    airfield_integrity = 100.0
    strategic_alert = 0
    strategic_capability = bool(profile.get("strategic_capability", false))

func get_vehicle_roster() -> Array[Dictionary]:
    var roster: Array[Dictionary] = []
    roster.append({"role": ROLE_ARMOR, "name": str(profile.get("armor", "Zırhlı Muharebe Aracı")), "strength": int(profile.get("armor_strength", 60))})
    roster.append({"role": ROLE_AIR, "name": str(profile.get("air_support", "Hava Destek Filosu")), "strength": int(profile.get("air_strength", 55))})
    roster.append({"role": ROLE_AIR_DEFENSE, "name": str(profile.get("air_defense", "Hava Savunma Birliği")), "strength": int(profile.get("air_defense_strength", 65))})
    if strategic_capability:
        roster.append({"role": ROLE_STRATEGIC, "name": "Stratejik Caydırıcılık", "strength": 100})
    return roster

func request_air_support() -> bool:
    if not _can_deploy(ROLE_AIR): return false
    var unit := _find_role(ROLE_AIR)
    active_support.append(unit)
    _spawn_actor(ROLE_AIR)
    support_event.emit("HAVA DESTEĞİ", "%s operasyon bölgesine yönlendirildi." % unit.name)
    return true

func request_armor_support() -> bool:
    if not _can_deploy(ROLE_ARMOR): return false
    var unit := _find_role(ROLE_ARMOR)
    active_support.append(unit)
    _spawn_actor(ROLE_ARMOR)
    support_event.emit("ZIRHLI DESTEK", "%s operasyon bölgesine ulaştı." % unit.name)
    return true

func _spawn_actor(role: String) -> void:
    if not is_instance_valid(target): return
    var actor := CharacterBody3D.new()
    actor.set_script(VehicleActor)
    actor.position = target.global_position + (Vector3(-10, 0.5, -12) if role == ROLE_ARMOR else Vector3(0, 12, -25))
    add_child(actor)
    actor.configure(role, country, target)
    actor.support_hit.connect(_on_support_hit)
    spawned_support.append(actor)

func _on_support_hit(amount: int) -> void:
    support_event.emit("DESTEK VURUŞU", "%d hasar uygulandı." % amount)

func protect_airfield(amount: float) -> float:
    var defense := int(profile.get("air_defense_strength", 65))
    airfield_integrity = clampf(airfield_integrity + amount * float(defense) / 100.0, 0.0, 100.0)
    return airfield_integrity

func damage_airfield(amount: float) -> bool:
    var defense := int(profile.get("air_defense_strength", 65))
    var mitigated := amount * (1.0 - clampf(float(defense) / 180.0, 0.15, 0.65))
    airfield_integrity = clampf(airfield_integrity - mitigated, 0.0, 100.0)
    if airfield_integrity <= 30.0: support_event.emit("HAVA ÜSSÜ ALARMI", "Hava operasyonları kritik seviyede.")
    return airfield_integrity > 0.0

func raise_strategic_alert() -> void:
    strategic_alert = mini(5, strategic_alert + 1)
    support_event.emit("STRATEJİK ALARM", "Caydırıcılık seviyesi %d/5." % strategic_alert)

func get_status_text() -> String:
    var strategic := "AKTİF" if strategic_capability else "YOK"
    return "HAVA ÜSSÜ %d%% • STRATEJİK %s • ALARM %d/5" % [int(round(airfield_integrity)), strategic, strategic_alert]

func _clear_support() -> void:
    for actor in spawned_support:
        if is_instance_valid(actor): actor.queue_free()
    spawned_support.clear()

func _find_role(role: String) -> Dictionary:
    for unit in get_vehicle_roster():
        if str(unit.get("role", "")) == role: return unit
    return {}

func _can_deploy(role: String) -> bool:
    if _find_role(role).is_empty(): return false
    for unit in active_support:
        if str(unit.get("role", "")) == role: return false
    return true
