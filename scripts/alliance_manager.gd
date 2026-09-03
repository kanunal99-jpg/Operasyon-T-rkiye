extends Node

signal alliance_changed(country: String, partner: String, allied: bool)
signal diplomacy_changed(message: String)

const GlobalMap = preload("res://scripts/global_world_map.gd")
var alliances: Dictionary = {}
var relations: Dictionary = {}
var war_alert := 0

func _ready() -> void:
    _seed_relations()

func _seed_relations() -> void:
    relations = {}
    # Baseline diplomatic model: countries start neutral, while selected
    # relationships provide a more believable campaign opening. All relations
    # are fictional gameplay values, not statements about real-world policy.
    for item in GlobalMap.COUNTRIES:
        var country := str(item[0])
        relations[country] = {}
    _set_seed("Türkiye", "Azerbaycan", 60)
    _set_seed("Türkiye", "Almanya", 25)
    _set_seed("Türkiye", "Fransa", 20)
    _set_seed("Türkiye", "Birleşik Krallık", 15)
    _set_seed("Türkiye", "ABD", 20)
    _set_seed("Türkiye", "Yunanistan", 5)
    _set_seed("Almanya", "Fransa", 55)
    _set_seed("Almanya", "Birleşik Krallık", 45)
    _set_seed("Almanya", "ABD", 50)
    _set_seed("Fransa", "Birleşik Krallık", 35)
    _set_seed("Fransa", "ABD", 55)
    _set_seed("ABD", "Birleşik Krallık", 65)
    _set_seed("ABD", "Kanada", 70)
    _set_seed("Birleşik Krallık", "Kanada", 50)

func _set_seed(country_a: String, country_b: String, value: int) -> void:
    if not relations.has(country_a): relations[country_a] = {}
    if not relations.has(country_b): relations[country_b] = {}
    relations[country_a][country_b] = value
    relations[country_b][country_a] = value

func get_relation(country_a: String, country_b: String) -> int:
    if relations.has(country_a) and relations[country_a].has(country_b): return int(relations[country_a][country_b])
    if relations.has(country_b) and relations[country_b].has(country_a): return int(relations[country_b][country_a])
    return 0

func set_relation(country_a: String, country_b: String, value: int) -> void:
    if not relations.has(country_a): relations[country_a] = {}
    if not relations.has(country_b): relations[country_b] = {}
    var v := clampi(value, -100, 100)
    relations[country_a][country_b] = v
    relations[country_b][country_a] = v

func can_form_alliance(country_a: String, country_b: String) -> bool:
    return country_a != country_b and country_b not in get_allies(country_a) and get_relation(country_a, country_b) >= 25

func propose_alliance(country_a: String, country_b: String) -> bool:
    if not can_form_alliance(country_a, country_b):
        diplomacy_changed.emit("İTTİFAK TEKLİFİ REDDEDİLDİ • İLİŞKİ YETERSİZ")
        return false
    if not alliances.has(country_a): alliances[country_a] = []
    if not alliances.has(country_b): alliances[country_b] = []
    if country_b not in alliances[country_a]: alliances[country_a].append(country_b)
    if country_a not in alliances[country_b]: alliances[country_b].append(country_a)
    set_relation(country_a, country_b, get_relation(country_a, country_b) + 10)
    lower_alert(3)
    alliance_changed.emit(country_a, country_b, true)
    diplomacy_changed.emit("İTTİFAK KURULDU • %s ↔ %s" % [country_a, country_b])
    return true

func break_alliance(country_a: String, country_b: String) -> void:
    if alliances.has(country_a): alliances[country_a].erase(country_b)
    if alliances.has(country_b): alliances[country_b].erase(country_a)
    set_relation(country_a, country_b, get_relation(country_a, country_b) - 25)
    raise_alert(15)
    alliance_changed.emit(country_a, country_b, false)
    diplomacy_changed.emit("İTTİFAK SONA ERDİ • %s ↔ %s" % [country_a, country_b])

func get_allies(country: String) -> Array:
    return alliances.get(country, []).duplicate()

func get_support_level(country: String) -> int:
    # Each ally adds tangible campaign support, capped for mobile balance.
    return mini(3, get_allies(country).size())

func get_enemy_reduction(country: String) -> int:
    return get_support_level(country)

func get_damage_bonus(country: String) -> float:
    return 1.0 + (0.05 * get_support_level(country))

func get_intel_bonus(country: String) -> int:
    return get_support_level(country) * 10

func get_support_summary(country: String) -> String:
    var allies := get_allies(country)
    if allies.is_empty(): return "Müttefik desteği yok"
    return "Müttefik desteği: %s • DESTEK %d/3" % [", ".join(allies), get_support_level(country)]

func get_diplomacy_state(country: String) -> String:
    var allies := get_allies(country)
    if not allies.is_empty(): return "İTTİFAKLI • %d ülke" % allies.size()
    var best := -101
    for item in GlobalMap.COUNTRIES:
        var other := str(item[0])
        if other != country: best = maxi(best, get_relation(country, other))
    if best >= 50: return "DOSTANE"
    if best >= 25: return "MÜZAKERE"
    if best <= 0: return "GERİLİM"
    return "TEMKİNLİ"

func raise_alert(amount: int = 10) -> void:
    war_alert = clampi(war_alert + amount, 0, 100)

func lower_alert(amount: int = 5) -> void:
    war_alert = clampi(war_alert - amount, 0, 100)

func get_alert_text() -> String:
    if war_alert >= 75: return "KRİTİK"
    if war_alert >= 50: return "YÜKSEK"
    if war_alert >= 25: return "ARTIYOR"
    return "DÜŞÜK"

func export_state() -> Dictionary:
    return {"alliances": alliances.duplicate(true), "relations": relations.duplicate(true), "war_alert": war_alert}

func import_state(state: Dictionary) -> void:
    if state.is_empty(): return
    if state.has("alliances"): alliances = state["alliances"].duplicate(true)
    if state.has("relations"): relations = state["relations"].duplicate(true)
    war_alert = clampi(int(state.get("war_alert", 0)), 0, 100)
