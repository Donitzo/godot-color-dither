"""
    Asset: Godot Color Dither
    File: tweener.gd
    Description: Left/right motion tweener.
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
"""

extends Sprite2D

@export var left_move_distance:float
@export var right_move_distance:float
@export var velocity:float
@export var max_velocity:float
@export var acceleration:float
@export var flip:bool
@export var moving_left:bool
@export var world_dither:bool

@onready var _original_scale:float = scale.x
@onready var _left_x:float = position.x - left_move_distance
@onready var _right_x:float = position.x + right_move_distance

func _process(delta:float) -> void:
    if moving_left:
        velocity = max(-max_velocity, velocity - acceleration * delta)
        position.x += velocity * delta
        moving_left = position.x > _left_x
    else:
        velocity = min(max_velocity, velocity + acceleration * delta)
        position.x += velocity * delta
        moving_left = position.x > _right_x
        
    if flip:
        scale.x = _original_scale * sign(velocity)

    if world_dither and material != null:
        var v:Vector2 = Vector2(floor(-position.x), floor(-position.y))
        material.set_shader_parameter('dither_pixel_offset', v)
        material.set_shader_parameter('alpha_pixel_offset', v)
