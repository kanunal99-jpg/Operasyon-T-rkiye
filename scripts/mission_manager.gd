extends Node

signal objective_changed(title: String, progress: String)
signal mission_completed(reward: int)
signal mission_failed
signal country_unlocked(country: String)

const TYPES := ["ELIMINATE", "DEFEND", "REACH", "SURVIVE"]
var objective_type := "ELIMINATE"
var target_kills := 5
var kills := 0
var survive_seconds := 45.0
var survive_elapsed := 0.0
var defend_seconds := 30.0
var defend_elapsed := 0.0
var defend_presence := false
var defend_integrity := 100.0
var active := false
var reward := 500

func start(operation: Array) -> void:
    kills = 0
    survive_elapsed = 0.0
    defend_elapsed = 0.0
    defend_presence = false
    defend_integrity = 100.0
    target_kills = maxi(3, int(operation[3]) + 3)
    reward = int(operation[3]) * 250
    objective_type = TYPES[(int(operation[3]) + operation[0].length()) % TYPES.size()]
    active = true
    _emit_progress()

func _process(delta: float) -> void:
    if not active:
        return
    if objective_type == "SURVIVE":
        survive_elapsed += delta
        _emit_progress()
        if survive_elapsed >= survive_seconds:
            _complete()
    elif objective_type == "DEFEND" and defend_presence:
        defend_elapsed += delta
        _emit_progress()
        if defend_elapsed >= defend_seconds:
            _complete()

func register_kill() -> bool:
    if not active:
        return false
    if objective_type == "ELIMINATE":
        kills += 1
        _emit_progress()
        if kills >= target_kills:
            _complete()
            return true
    elif objective_type == "DEFEND":
        kills += 1
        _emit_progress()
    return false

func set_defend_presence(is_inside: bool) -> void:
    if not active or objective_type != "DEFEND":
        return
    if defend_presence != is_inside:
        defend_presence = is_inside
        _emit_progress()

func damage_defend_objective(amount: float) -> void:
    if not active or objective_type != "DEFEND":
        return
    defend_integrity = maxf(0.0, defend_integrity - maxf(0.0, amount))
    _emit_progress()
    if defend_integrity <= 0.0:
        active = false
        mission_failed.emit()

func register_reach() -> bool:
    if not active or objective_type != "REACH":
        return false
    _complete()
    return true

func _emit_progress() -> void:
    match objective_type:
        "ELIMINATE": objective_changed.emit("HEDEF: DÜŞMAN BİRLİĞİNİ ETKİSİZ HALE GETİR", "%d / %d" % [kills, target_kills])
        "DEFEND":
            var state := "BÖLGEDE" if defend_presence else "BÖLGEYE DÖN"
            objective_changed.emit("HEDEF: SAVUNMA BÖLGESİNİ KORU", "%s • %02d / %02d sn • DAYANIKLILIK %d%% • %d etkisiz" % [state, int(defend_elapsed), int(defend_seconds), int(defend_integrity), kills])
        "REACH": objective_changed.emit("HEDEF: BULUŞMA NOKTASINA ULAŞ", "NOKTA AKTİF")
        "SURVIVE": objective_changed.emit("HEDEF: HAYATTA KAL", "%02d / %02d sn" % [int(survive_elapsed), int(survive_seconds)])

func _complete() -> void:
    if not active:
        return
    active = false
    mission_completed.emit(reward)
