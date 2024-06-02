"""
    Asset: Godot Color Dither
    File: sample_menu.gd
    Description: Manages the demo scene.
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
"""

extends Node

@export var samples:ItemList
@export var palettes:ItemList
@export var color_picker:ColorPicker

@onready var _sample_containers:Array = [
    $SampleOriginal,
    $Sample2D, 
    $Sample2DPost, 
    $Sample3D, 
    $Sample3DPost,
]

@onready var _dither_palettes:Array = [
    preload('res://color_dither/textures/palettes/commodore64.png'),
    preload('res://color_dither/textures/palettes/color-graphics-adapter.png'),
    preload('res://color_dither/textures/palettes/cga-palette-0-high.png'),
    preload('res://color_dither/textures/palettes/sweetie-16.png'),
    preload('res://color_dither/textures/palettes/1bit-monitor-glow.png'),
]

var _materials:Array = []

func _ready() -> void:
    _find_materials(self)

    samples.select(1)
    palettes.select(0)
    
    samples.connect('item_selected', _handle_sample_selected)
    palettes.connect('item_selected', _handle_palette_selected)
    color_picker.connect('color_changed', _handle_color_changed)
    
    _handle_sample_selected(1)
    _handle_palette_selected(0)

func _handle_sample_selected(index:int) -> void:
    for i in _sample_containers.size():
        _sample_containers[i].visible = i == index
    _handle_color_changed(Color('#ffffff') / 3.0)

func _handle_palette_selected(index:int) -> void:
    for material in _materials:
        material.set_shader_parameter('dither_palette', _dither_palettes[index])
    _handle_color_changed(Color('#ffffff') / 3.0)

func _handle_color_changed(color:Color) -> void:
    for material in _materials:
        var old_color = material.get_shader_parameter('albedo')
        if old_color != null:
            var new_color:Color = color * 3
            new_color.a = old_color.a
            material.set_shader_parameter('albedo', new_color)

func _find_materials(node:Node):
    if node.has_method('get_material') or node.has_method('get_active_material'):
        var material = node.get_material() if node.has_method('get_material') else node.get_active_material(0)
        if material is ShaderMaterial:
            _materials.push_back(material)

    for child in node.get_children():
        _find_materials(child)
