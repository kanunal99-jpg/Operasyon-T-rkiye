extends Node

signal objective_changed(title: String, progress: String)
signal mission_completed(reward: int)
signal country_unlocked(country: String)

var objective_type := "ELIMINATE"
var target_kills := 5
var kills := 0
var active := false
var reward := 500

func start(operation: Array) -> void:
    kills = 0
    target_kills = maxi(3, int(operation[3]) + 3)
    reward = int(operation[3]) * 250
    objective_type = "ELIMINATE"
    active = true
    objective_changed.emit("HEDEF: DÜŞMAN BİRLİĞİNİ ETKİSİZ HALE GETİR", "%d / %d" % [kills, target_kills])

func register_kill() -> bool:
    if not active: return false
    kills += 1
    objective_changed.emit("HEDEF: DÜŞMAN BİRLİĞİNİ ETKİSİZ HALE GETİR", "%d / %d" % [kills, target_kills])
    if kills >= target_kills:
        active = false
        mission_completed.emit(reward)
        return true
    return false
