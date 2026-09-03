extends Node

# Turkish is the default voice/text language. Additional languages can be added
# without changing mission logic or character data.
const LANGUAGES := {
    "tr": "Türkçe",
    "en": "English",
    "de": "Deutsch",
    "fr": "Français",
    "es": "Español",
    "ar": "العربية",
    "ru": "Русский",
    "ja": "日本語",
    "ko": "한국어",
    "zh": "中文"
}

var language := "tr"
var turkish_dub_enabled := true

const LINES := {
    "mission_start": {
        "tr": "Görev başladı. Bölgeyi kontrol altına al.",
        "en": "Mission started. Secure the area."
    },
    "enemy_alert": {
        "tr": "Dikkat! Temas sağlandı.",
        "en": "Contact! Enemy spotted."
    },
    "mission_complete": {
        "tr": "Görev tamamlandı.",
        "en": "Mission complete."
    }
}

func set_language(code: String) -> void:
    if LANGUAGES.has(code):
        language = code

func get_line(key: String) -> String:
    if not LINES.has(key):
        return key
    var line: Dictionary = LINES[key]
    return line.get(language, line.get("tr", key))

func enable_turkish_dub(enabled: bool) -> void:
    turkish_dub_enabled = enabled
