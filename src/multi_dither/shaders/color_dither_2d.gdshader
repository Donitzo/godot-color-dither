/*
    Asset: Godot Multi Dither
    File: color_dither_2d.gdshader
    Description: A color dither shader with the following properties:
        Used as a regular canvas_item material for Sprites and TextureRect.
        Uses a fixed 4x4 dither (max 16 colors).
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
*/

shader_type canvas_item;
render_mode unshaded;

#define IS_CANVAS_ITEM

#include "./color_dither_include.gdshaderinc"

// Pixel offset used only for alpha dithering
uniform vec2 alpha_dither_pixel_offset = vec2(0.0);

void fragment() {
    vec4 color = get_albedo(TEXTURE, UV);
    vec2 pixel = get_pixel_center(TEXTURE, UV);
    float dither_value_alpha = get_dither_value(pixel + alpha_dither_pixel_offset);
    if (color.a <= dither_value_alpha) {
        discard;
    }
    float dither_value = get_dither_value(pixel);
    COLOR = get_dither_color(dither_value, color);
}