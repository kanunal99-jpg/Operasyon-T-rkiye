extends Node

signal alliance_changed(country: String, partner: String, allied: bool)
signal diplomacy_changed(message: String)

var alliances: Dictionary = {}
var relations: Dictionary = {}
var war_alert := 0

func _ready() -> void:
    _seed_relations()

func _seed_relations() -> void:
    relations = {
        "Türkiye": {"Almanya": 25, "Fransa": 20, "Birleşik Krallık": 15, "ABD": 20, "Azerbaycan": 60, "Yunanistan": 5},
        "Almanya": {"Türkiye": 25, "Fransa": 55, "Birleşik Krallık": 45, "ABD": 50},
        "Fransa": {"Türkiye": 20, "Almanya": 55, "Birleşik Krallık": 35, "ABD": 55},
        "ABD": {"Türkiye": 20, "Birleşik Krallık": 65, "Fransa": 55, "Almanya": 50, "Kanada": 70},
        "Yunanistan": {"Türkiye": 5},
        "Azerbaycan": {"Türkiye": 60},
        "Birleşik Krallık": {"ABD": 65, "Fransa": 35, "Almanya": 45},
        "Kanada": {"ABD": 70}
    }

func get_relation(country_a: String, country_b: String) -> int:
    if relations.has(country_a) and relations[country_a].has(country_b):
        return int(relations[country_a][country_b])
    if relations.has(country_b) and relations[country_b].has(country_a):
        return int(relations[country_b][country_a])
    return 0

func set_relation(country_a: String, country_b: String, value: int) -> void:
    if not relations.has(country_a): relations[country_a] = {}
    relations[country_a][country_b] = clampi(value, -100, 100)
    if not relations.has(country_b): relations[country_b] = {}
    relations[country_b][country_a] = clampi(value, -100, 100)

func can_form_alliance(country_a: String, country_b: String) -> bool:
    return country_a != country_b and country_b not in get_allies(country_a) and get_relation(country_a, country_b) >= 25

func propose_alliance(country_a: String, country_b: String) -> bool:
    if not can_form_alliance(country_a, country_b):
        diplomacy_changed.emit("İTTİFAK TEKLİFİ REDDEDİLDİ • İLİŞKİ YETERSİZ")
        return false
    if not alliances.has(country_a): alliances[country_a] = []
    if country_b not in alliances[country_a]: alliances[country_a].append(country_b)
    if not alliances.has(country_b): alliances[country_b] = []
    if country_a not in alliances[country_b]: alliances[country_b].append(country_a)
    set_relation(country_a, country_b, get_relation(country_a, country_b) + 10)
    alliance_changed.emit(country_a, country_b, true)
    diplomacy_changed.emit("İTTİFAK KURULDU • %s ↔ %s" % [country_a, country_b])
    return true

func break_alliance(country_a: String, country_b: String) -> void:
    if alliances.has(country_a): alliances[country_a].erase(country_b)
    if alliances.has(country_b): alliances[country_b].erase(country_a)
    set_relation(country_a, country_b, get_relation(country_a, country_b) - 25)
    alliance_changed.emit(country_a, country_b, false)
    diplomacy_changed.emit("İTTİFAK SONA ERDİ • %s ↔ %s" % [country_a, country_b])

func get_allies(country: String) -> Array:
    return alliances.get(country, []).duplicate()

func get_support_summary(country: String) -> String:
    var allies := get_allies(country)
    if allies.is_empty(): return "Müttefik desteği yok"
    return "Müttefik desteği: %s" % ", ".join(allies)

func get_diplomacy_state(country: String) -> String:
    var allies := get_allies(country)
    if not allies.is_empty():
        return "İTTİFAKLI • %d ülke" % allies.size()
    var best := -101
    for item in GlobalMap.COUNTRIES:
        var other := str(item[0])
        if other != country:
            best = maxi(best, get_relation(country, other))
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
    if state.has("alliances"): alliances = state["alliances"].duplicate(true)
    if state.has("relations"): relations = state["relations"].duplicate(true)
    war_alert = clampi(int(state.get("war_alert", 0)), 0, 100)
