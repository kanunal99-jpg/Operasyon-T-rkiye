extends Node

signal objective_changed(title: String, progress: String)
signal mission_completed(reward: int)
signal country_unlocked(country: String)

const TYPES := ["ELIMINATE", "DEFEND", "REACH", "SURVIVE"]
var objective_type := "ELIMINATE"
var target_kills := 5
var kills := 0
var survive_seconds := 45
var survive_elapsed := 0.0
var active := false
var reward := 500

func start(operation: Array) -> void:
    kills = 0
    survive_elapsed = 0.0
    target_kills = maxi(3, int(operation[3]) + 3)
    reward = int(operation[3]) * 250
    objective_type = TYPES[(int(operation[3]) + operation[0].length()) % TYPES.size()]
    active = true
    _emit_progress()

func _process(delta: float) -> void:
    if not active: return
    if objective_type == "SURVIVE":
        survive_elapsed += delta
        _emit_progress()
        if survive_elapsed >= survive_seconds:
            _complete()

func register_kill() -> bool:
    if not active: return false
    if objective_type == "ELIMINATE" or objective_type == "DEFEND":
        kills += 1
        _emit_progress()
        if kills >= target_kills:
            _complete()
            return true
    return false

func register_reach() -> bool:
    if not active or objective_type != "REACH": return false
    _complete()
    return true

func _emit_progress() -> void:
    match objective_type:
        "ELIMINATE": objective_changed.emit("HEDEF: DÜŞMAN BİRLİĞİNİ ETKİSİZ HALE GETİR", "%d / %d" % [kills, target_kills])
        "DEFEND": objective_changed.emit("HEDEF: BÖLGEYİ SAVUN", "%d / %d DÜŞMAN" % [kills, target_kills])
        "REACH": objective_changed.emit("HEDEF: BULUŞMA NOKTASINA ULAŞ", "NOKTA AKTİF")
        "SURVIVE": objective_changed.emit("HEDEF: HAYATTA KAL", "%02d / %02d sn" % [int(survive_elapsed), survive_seconds])

func _complete() -> void:
    if not active: return
    active = false
    mission_completed.emit(reward)
