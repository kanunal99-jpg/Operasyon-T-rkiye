extends Node

# Lightweight local campaign save for Android and desktop.
const SAVE_PATH := "user://operasyon_turkiye_save.cfg"

var score := 0
var xp := 0
var selected_country := "Türkiye"
var selected_operation := 0
var unlocked_countries: Array[String] = ["Türkiye"]
var completed_operations: Array[String] = []
var diplomacy_state: Dictionary = {}

func _ready() -> void:
    load_game()

func operation_key(country: String, index: int) -> String:
    return "%s:%d" % [country, index]

func is_operation_completed(country: String, index: int) -> bool:
    return operation_key(country, index) in completed_operations

func complete_operation(country: String, index: int, reward: int) -> void:
    var key := operation_key(country, index)
    if key not in completed_operations:
        completed_operations.append(key)
        xp += reward
        score += reward
    save_game()

func unlock_country(country: String) -> void:
    if country not in unlocked_countries:
        unlocked_countries.append(country)
    save_game()

func set_diplomacy_state(state: Dictionary) -> void:
    diplomacy_state = state.duplicate(true)
    save_game()

func save_game() -> void:
    var config := ConfigFile.new()
    config.set_value("player", "score", score)
    config.set_value("player", "xp", xp)
    config.set_value("player", "selected_country", selected_country)
    config.set_value("player", "selected_operation", selected_operation)
    config.set_value("campaign", "unlocked_countries", unlocked_countries)
    config.set_value("campaign", "completed_operations", completed_operations)
    config.set_value("diplomacy", "state", diplomacy_state)
    config.save(SAVE_PATH)

func load_game() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return
    score = int(config.get_value("player", "score", 0))
    xp = int(config.get_value("player", "xp", 0))
    selected_country = str(config.get_value("player", "selected_country", "Türkiye"))
    selected_operation = int(config.get_value("player", "selected_operation", 0))
    unlocked_countries = config.get_value("campaign", "unlocked_countries", ["Türkiye"])
    completed_operations = config.get_value("campaign", "completed_operations", [])
    diplomacy_state = config.get_value("diplomacy", "state", {})
