extends Node3D

const ContentController = preload("res://scripts/content_controller.gd")

func _ready() -> void:
    var controller := ContentController.new()
    controller.name = "ContentController"
    add_child(controller)
