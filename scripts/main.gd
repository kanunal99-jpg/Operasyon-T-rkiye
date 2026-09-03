extends Node3D

# Kept as a compatibility placeholder. The active game bootstrap is res://main.gd.
# The previous duplicate controller caused Godot to parse stale class-level map calls
# even though it was not referenced by the active main scene.
func _ready() -> void:
    pass
