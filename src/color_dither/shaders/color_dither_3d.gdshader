/*
    Asset: Godot Multi Dither
    File: color_dither_3d.gdshader
    Description: A color dither shader with the following properties:
        Used as a regular spatial material for 3D meshes.
        Uses a fixed 4x4 dither (max 16 colors).
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
*/

shader_type spatial;
render_mode unshaded;

#include "./color_dither_include.gdshaderinc"

uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;

void fragment() {
    vec4 color = get_albedo(texture_albedo, UV);
    vec2 pixel = get_pixel_center(texture_albedo, UV);
    float dither_value = get_dither_value(pixel);
    if (color.a <= dither_value) {
        discard;
    }
    ALBEDO = get_dither_color(dither_value, color).rgb;
}
