extends RefCounted

# Country presentation layer. National identity is represented through metadata,
# uniform/equipment presets and language options. Character appearance stays
# varied and non-stereotyped; no ethnicity or religion is inferred from country.
const GlobalMap = preload("res://scripts/global_world_map.gd")

const PROFILES := {
    "Türkiye": {"uniform":"modern_turkish","equipment":"assault","language":"tr","voice":"tr","callsigns":["Bora","Efe","Mert","Selin"],"armor":"Anadolu Zırhlı Birliği","armor_strength":72,"air_support":"Anadolu Hava Filosu","air_strength":68,"air_defense":"Katmanlı Hava Savunma","air_defense_strength":74,"strategic_capability":false},
    "Yunanistan": {"uniform":"modern_greek","equipment":"assault","language":"el","voice":"tr","callsigns":["Nikos","Dimitra","Alex"],"armor":"Ege Zırhlı Birliği","armor_strength":62,"air_support":"Ege Hava Filosu","air_strength":63,"air_defense":"Ada Hava Savunması","air_defense_strength":65,"strategic_capability":false},
    "Almanya": {"uniform":"modern_german","equipment":"rifle","language":"de","voice":"tr","callsigns":["Lukas","Anna","Felix"],"armor":"Avrupa Zırhlı Birliği","armor_strength":78,"air_support":"Avrupa Hava Filosu","air_strength":76,"air_defense":"Entegre Hava Savunması","air_defense_strength":78,"strategic_capability":false},
    "Fransa": {"uniform":"modern_french","equipment":"rifle","language":"fr","voice":"tr","callsigns":["Lucas","Claire","Hugo"],"armor":"Batı Zırhlı Birliği","armor_strength":76,"air_support":"Batı Hava Filosu","air_strength":78,"air_defense":"Ulusal Hava Savunması","air_defense_strength":76,"strategic_capability":true},
    "Birleşik Krallık": {"uniform":"modern_british","equipment":"rifle","language":"en","voice":"tr","callsigns":["James","Oliver","Emily"],"armor":"Ada Zırhlı Birliği","armor_strength":70,"air_support":"Ada Hava Filosu","air_strength":79,"air_defense":"Ada Hava Savunması","air_defense_strength":73,"strategic_capability":true},
    "ABD": {"uniform":"modern_us","equipment":"rifle","language":"en","voice":"tr","callsigns":["Jack","Maya","Ethan"],"armor":"Müttefik Zırhlı Birliği","armor_strength":88,"air_support":"Küresel Hava Filosu","air_strength":92,"air_defense":"Katmanlı Hava Savunma Ağı","air_defense_strength":90,"strategic_capability":true},
    "Çin": {"uniform":"modern_chinese","equipment":"rifle","language":"zh","voice":"tr","callsigns":["Wei","Li","Mei"],"armor":"Doğu Zırhlı Birliği","armor_strength":86,"air_support":"Doğu Hava Filosu","air_strength":88,"air_defense":"Katmanlı Hava Savunma Ağı","air_defense_strength":88,"strategic_capability":true},
    "Hindistan": {"uniform":"modern_indian","equipment":"rifle","language":"hi","voice":"tr","callsigns":["Arjun","Priya","Rahul"],"armor":"Güney Zırhlı Birliği","armor_strength":74,"air_support":"Güney Hava Filosu","air_strength":73,"air_defense":"Bölgesel Hava Savunması","air_defense_strength":72,"strategic_capability":true},
    "Pakistan": {"uniform":"modern_pakistani","equipment":"rifle","language":"ur","voice":"tr","callsigns":["Hamza","Ayesha","Bilal"],"armor":"Sınır Zırhlı Birliği","armor_strength":70,"air_support":"Sınır Hava Filosu","air_strength":72,"air_defense":"Katmanlı Hava Savunması","air_defense_strength":70,"strategic_capability":true},
    "İran": {"uniform":"modern_iranian","equipment":"assault","language":"fa","voice":"tr","callsigns":["Arman","Reza","Sara"],"armor":"Bölgesel Zırhlı Birlik","armor_strength":69,"air_support":"Bölgesel Hava Filosu","air_strength":62,"air_defense":"Katmanlı Hava Savunması","air_defense_strength":75,"strategic_capability":true},
    "İsrail": {"uniform":"modern_israeli","equipment":"rifle","language":"he","voice":"tr","callsigns":["Noam","Maya","Eli"],"armor":"Çöl Zırhlı Birliği","armor_strength":84,"air_support":"Hava Üstünlük Filosu","air_strength":86,"air_defense":"Çok Katmanlı Savunma","air_defense_strength":92,"strategic_capability":true}
}

static func get_profile(country: String) -> Dictionary:
    if PROFILES.has(country): return PROFILES[country]
    var continent := ""
    var difficulty := 3
    for item in GlobalMap.COUNTRIES:
        if str(item[0]) == country:
            continent = str(item[1])
            difficulty = int(item[3])
            break
    var language := _language_for_continent(continent)
    var equipment := "assault" if difficulty >= 4 else "rifle"
    return {"uniform":"modern_" + _slug(country),"equipment":equipment,"language":language,"voice":"tr","callsigns":["Alpha","Bravo","Charlie"],"armor":"Bölgesel Zırhlı Birlik","armor_strength":50 + difficulty * 5,"air_support":"Bölgesel Hava Filosu","air_strength":45 + difficulty * 6,"air_defense":"Bölgesel Hava Savunması","air_defense_strength":50 + difficulty * 5,"strategic_capability":false}

static func _slug(country: String) -> String:
    var value := country.to_lower()
    var replacements := {"ı":"i","ğ":"g","ü":"u","ş":"s","ö":"o","ç":"c","İ":"i","é":"e","á":"a","ñ":"n"}
    for key in replacements: value = value.replace(key, replacements[key])
    value = value.replace(" ","_").replace("-","_").replace("'","")
    return value

static func _language_for_continent(continent: String) -> String:
    match continent:
        "AVRUPA": return "en"
        "ASYA/AVRUPA": return "tr"
        "ASYA": return "en"
        "AFRİKA": return "en"
        "KUZEY AMERİKA": return "en"
        "GÜNEY AMERİKA": return "es"
        "OKYANUSYA": return "en"
    return "en"

static func get_callout(country: String, key: String) -> String:
    var native := {"contact":"Temas var!","reload":"Şarjör değiştiriyorum!","advance":"İlerliyoruz!","hold":"Pozisyonu koru!","target_down":"Hedef etkisiz!"}
    return native.get(key,"Hazır!")
