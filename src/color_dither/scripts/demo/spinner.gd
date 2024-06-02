"""
    Asset: Godot Color Dither
    File: spinner.gd
    Description: Spins a 3D node.
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
"""

extends Node3D

@export var spin:Vector3

func _process(delta:float) -> void:
    rotation += spin * delta
