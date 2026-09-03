extends Node

signal mission_changed(text: String)
signal wave_changed(wave: int, remaining: int)

var wave := 1
var remaining := 0
var total_kills := 0

func start_wave(enemy_count: int) -> void:
    remaining = enemy_count
    wave_changed.emit(wave, remaining)

func register_enemy_killed() -> void:
    remaining = maxi(0, remaining - 1)
    total_kills += 1
    wave_changed.emit(wave, remaining)
    if remaining == 0:
        wave += 1
        mission_changed.emit("DALGA %d HAZIR" % wave)
