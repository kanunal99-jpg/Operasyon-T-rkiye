extends RefCounted

# Country presentation layer. National identity is represented through metadata,
# uniform/equipment presets and language options. Character appearance stays
# varied and non-stereotyped; no ethnicity or religion is inferred from country.
const GlobalMap = preload("res://scripts/global_world_map.gd")

const PROFILES := {
    "Türkiye": {"uniform": "modern_turkish", "equipment": "assault", "language": "tr", "voice": "tr", "callsigns": ["Bora", "Efe", "Mert", "Selin"]},
    "Yunanistan": {"uniform": "modern_greek", "equipment": "assault", "language": "el", "voice": "tr", "callsigns": ["Nikos", "Dimitra", "Alex"]},
    "Bulgaristan": {"uniform": "modern_bulgarian", "equipment": "assault", "language": "bg", "voice": "tr", "callsigns": ["Ivan", "Mila", "Georgi"]},
    "Almanya": {"uniform": "modern_german", "equipment": "rifle", "language": "de", "voice": "tr", "callsigns": ["Lukas", "Anna", "Felix"]},
    "Fransa": {"uniform": "modern_french", "equipment": "rifle", "language": "fr", "voice": "tr", "callsigns": ["Lucas", "Claire", "Hugo"]},
    "İtalya": {"uniform": "modern_italian", "equipment": "rifle", "language": "it", "voice": "tr", "callsigns": ["Marco", "Luca", "Giulia"]},
    "İspanya": {"uniform": "modern_spanish", "equipment": "rifle", "language": "es", "voice": "tr", "callsigns": ["Carlos", "Lucia", "Diego"]},
    "Birleşik Krallık": {"uniform": "modern_british", "equipment": "rifle", "language": "en", "voice": "tr", "callsigns": ["James", "Oliver", "Emily"]},
    "ABD": {"uniform": "modern_us", "equipment": "rifle", "language": "en", "voice": "tr", "callsigns": ["Jack", "Maya", "Ethan"]},
    "Kanada": {"uniform": "modern_canadian", "equipment": "rifle", "language": "en", "voice": "tr", "callsigns": ["Noah", "Emma", "Liam"]},
    "Meksika": {"uniform": "modern_mexican", "equipment": "assault", "language": "es", "voice": "tr", "callsigns": ["Diego", "Sofia", "Mateo"]},
    "Brezilya": {"uniform": "modern_brazilian", "equipment": "assault", "language": "pt", "voice": "tr", "callsigns": ["Rafael", "Ana", "Lucas"]},
    "Arjantin": {"uniform": "modern_argentine", "equipment": "rifle", "language": "es", "voice": "tr", "callsigns": ["Tomas", "Sofia", "Mateo"]},
    "Mısır": {"uniform": "modern_egyptian", "equipment": "assault", "language": "ar", "voice": "tr", "callsigns": ["Omar", "Youssef", "Mariam"]},
    "Fas": {"uniform": "modern_moroccan", "equipment": "assault", "language": "ar", "voice": "tr", "callsigns": ["Yassin", "Amine", "Salma"]},
    "Güney Afrika": {"uniform": "modern_south_african", "equipment": "rifle", "language": "en", "voice": "tr", "callsigns": ["Thabo", "Lerato", "Daniel"]},
    "Suudi Arabistan": {"uniform": "modern_saudi", "equipment": "assault", "language": "ar", "voice": "tr", "callsigns": ["Fahad", "Omar", "Noura"]},
    "Birleşik Arap Emirlikleri": {"uniform": "modern_uae", "equipment": "rifle", "language": "ar", "voice": "tr", "callsigns": ["Khalid", "Sara", "Omar"]},
    "BAE": {"uniform": "modern_uae", "equipment": "rifle", "language": "ar", "voice": "tr", "callsigns": ["Khalid", "Sara", "Omar"]},
    "İran": {"uniform": "modern_iranian", "equipment": "assault", "language": "fa", "voice": "tr", "callsigns": ["Arman", "Reza", "Sara"]},
    "Irak": {"uniform": "modern_iraqi", "equipment": "assault", "language": "ar", "voice": "tr", "callsigns": ["Ali", "Hassan", "Zahra"]},
    "Hindistan": {"uniform": "modern_indian", "equipment": "rifle", "language": "hi", "voice": "tr", "callsigns": ["Arjun", "Priya", "Rahul"]},
    "Pakistan": {"uniform": "modern_pakistani", "equipment": "rifle", "language": "ur", "voice": "tr", "callsigns": ["Hamza", "Ayesha", "Bilal"]},
    "Çin": {"uniform": "modern_chinese", "equipment": "rifle", "language": "zh", "voice": "tr", "callsigns": ["Wei", "Li", "Mei"]},
    "Japonya": {"uniform": "modern_japanese", "equipment": "rifle", "language": "ja", "voice": "tr", "callsigns": ["Haruto", "Aoi", "Ren"]},
    "Güney Kore": {"uniform": "modern_south_korean", "equipment": "rifle", "language": "ko", "voice": "tr", "callsigns": ["Minjun", "Jisoo", "Hyun"]},
    "Endonezya": {"uniform": "modern_indonesian", "equipment": "assault", "language": "id", "voice": "tr", "callsigns": ["Rizky", "Ayu", "Bima"]},
    "Avustralya": {"uniform": "modern_australian", "equipment": "rifle", "language": "en", "voice": "tr", "callsigns": ["Jack", "Ruby", "Liam"]},
    "Yeni Zelanda": {"uniform": "modern_new_zealand", "equipment": "rifle", "language": "en", "voice": "tr", "callsigns": ["Finn", "Mia", "Theo"]}
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
    return {
        "uniform": "modern_" + _slug(country),
        "equipment": equipment,
        "language": language,
        "voice": "tr",
        "callsigns": ["Alpha", "Bravo", "Charlie"]
    }

static func _slug(country: String) -> String:
    var value := country.to_lower()
    var replacements := {"ı":"i", "ğ":"g", "ü":"u", "ş":"s", "ö":"o", "ç":"c", "İ":"i", "é":"e", "á":"a", "ñ":"n"}
    for key in replacements: value = value.replace(key, replacements[key])
    value = value.replace(" ", "_").replace("-", "_").replace("'", "")
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
    var native := {
        "contact": "Temas var!",
        "reload": "Şarjör değiştiriyorum!",
        "advance": "İlerliyoruz!",
        "hold": "Pozisyonu koru!",
        "target_down": "Hedef etkisiz!"
    }
    return native.get(key, "Hazır!")
