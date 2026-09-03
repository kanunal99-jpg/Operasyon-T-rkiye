extends Node

signal mission_changed(text: String)
signal wave_changed(wave: int, remaining: int)
signal wave_completed(wave: int)
signal all_waves_completed

var wave := 1
var remaining := 0
var total_kills := 0
var max_waves := 3
var base_enemy_count := 4
var active := false

func start_mission(difficulty: int) -> void:
    wave = 1
    total_kills = 0
    max_waves = clampi(difficulty + 1, 2, 5)
    base_enemy_count = clampi(difficulty + 3, 4, 8)
    active = true
    mission_changed.emit("DALGA 1 BAŞLADI")
    start_wave(base_enemy_count)

func start_wave(enemy_count: int) -> void:
    remaining = maxi(0, enemy_count)
    wave_changed.emit(wave, remaining)
    if remaining == 0 and active:
        _complete_current_wave()

func register_enemy_killed() -> void:
    if not active:
        return
    remaining = maxi(0, remaining - 1)
    total_kills += 1
    wave_changed.emit(wave, remaining)
    if remaining == 0:
        _complete_current_wave()

func _complete_current_wave() -> void:
    wave_completed.emit(wave)
    if wave >= max_waves:
        active = false
        mission_changed.emit("TÜM DALGALAR TAMAMLANDI")
        all_waves_completed.emit()
    else:
        wave += 1
        mission_changed.emit("DALGA %d HAZIR" % wave)

func get_next_wave_count() -> int:
    return clampi(base_enemy_count + wave - 1, 4, 10)

func set_wave_enemy_count(enemy_count: int) -> void:
    if not active:
        return
    remaining = maxi(0, enemy_count)
    wave_changed.emit(wave, remaining)
    if remaining == 0:
        _complete_current_wave()
