/*
    Asset: Godot Color Dither
    File: color_dither_post_2d.gdshader
    Description: A color dither shader with the following properties:
        Used in 2D postprocessing.
        Should be assigned to a canvas_item covering the screen.
        Uses a fixed 4x4 dither (max 16 colors).
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
*/

shader_type canvas_item;
render_mode unshaded;

#define IS_POSTPROCESSOR

#include "./color_dither_include.gdshaderinc"

void fragment() {
    vec4 color = get_albedo(SCREEN_UV);
    vec2 pixel = get_pixel_center(SCREEN_UV);
    float dither_value = get_dither_value(pixel);
    COLOR = get_dither_color(dither_value, color);
}