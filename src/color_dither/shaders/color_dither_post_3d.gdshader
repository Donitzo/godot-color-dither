/*
    Asset: Godot Multi Dither
    File: color_dither_post_3d.gdshader
    Description: A color dither shader with the following properties:
        Used in 3D postprocessing.
        Should be assigned to a 2x2 Quad mesh.
        Uses a fixed 4x4 dither (max 16 colors).
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
*/

shader_type spatial;
render_mode unshaded, cull_front;

#define IS_POSTPROCESSOR

#include "./color_dither_include.gdshaderinc"

void vertex() {
    POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
    vec4 color = get_albedo(SCREEN_UV);
    vec2 pixel = get_pixel_center(SCREEN_UV);
    float dither_value = get_dither_value(pixel);
    ALBEDO = get_dither_color(dither_value, color).rgb;
}