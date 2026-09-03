extends Node

# Global diplomacy layer. Countries are fictionalized as game actors; real-world
# countries are used only as selectable campaign identities.
signal alliance_changed(country: String, partner: String, allied: bool)
signal diplomacy_changed(message: String)

var alliances: Dictionary = {}
var relations: Dictionary = {}
var pending_offers: Array[String] = []

func _ready() -> void:
    _seed_relations()

func _seed_relations() -> void:
    relations = {
        "Türkiye": {"Almanya": 25, "Fransa": 20, "Birleşik Krallık": 15, "ABD": 20, "Azerbaycan": 60, "Yunanistan": 5},
        "Almanya": {"Türkiye": 25, "Fransa": 55, "Birleşik Krallık": 45},
        "Fransa": {"Türkiye": 20, "Almanya": 55, "Birleşik Krallık": 35},
        "ABD": {"Türkiye": 20, "Birleşik Krallık": 65, "Fransa": 55, "Almanya": 50},
        "Yunanistan": {"Türkiye": 5},
        "Azerbaycan": {"Türkiye": 60}
    }

func get_relation(country_a: String, country_b: String) -> int:
    if relations.has(country_a) and relations[country_a].has(country_b):
        return int(relations[country_a][country_b])
    if relations.has(country_b) and relations[country_b].has(country_a):
        return int(relations[country_b][country_a])
    return 0

func can_form_alliance(country_a: String, country_b: String) -> bool:
    return country_a != country_b and get_relation(country_a, country_b) >= 25

func propose_alliance(country_a: String, country_b: String) -> bool:
    if not can_form_alliance(country_a, country_b):
        diplomacy_changed.emit("İTTİFAK TEKLİFİ REDDEDİLDİ: İLİŞKİ SEVİYESİ YETERSİZ")
        return false
    if not alliances.has(country_a):
        alliances[country_a] = []
    if country_b not in alliances[country_a]:
        alliances[country_a].append(country_b)
    if not alliances.has(country_b):
        alliances[country_b] = []
    if country_a not in alliances[country_b]:
        alliances[country_b].append(country_a)
    alliance_changed.emit(country_a, country_b, true)
    diplomacy_changed.emit("İTTİFAK KURULDU: %s ↔ %s" % [country_a, country_b])
    return true

func break_alliance(country_a: String, country_b: String) -> void:
    if alliances.has(country_a): alliances[country_a].erase(country_b)
    if alliances.has(country_b): alliances[country_b].erase(country_a)
    alliance_changed.emit(country_a, country_b, false)
    diplomacy_changed.emit("İTTİFAK SONA ERDİ: %s ↔ %s" % [country_a, country_b])

func get_allies(country: String) -> Array:
    return alliances.get(country, []).duplicate()

func get_support_summary(country: String) -> String:
    var allies := get_allies(country)
    if allies.is_empty():
        return "Müttefik desteği yok"
    return "Müttefik desteği: %s" % ", ".join(allies)
