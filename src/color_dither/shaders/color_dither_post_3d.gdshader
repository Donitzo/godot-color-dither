/*
    Asset: Godot Color Dither
    File: color_dither_post_3d.gdshader
    Description: A color dither shader with the following properties:
        Used in 3D postprocessing.
        Should be assigned to a 2x2 Quad mesh.
        Uses a fixed 4x4 dither (max 16 colors).
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
*/

shader_type spatial;
render_mode shadows_disabled, depth_test_disabled, unshaded, cull_front;

#define IS_POSTPROCESSOR

#include "./color_dither_include.gdshaderinc"

void vertex() {
    POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
    // screen_texture access inlined due to bug in shader compiler in Godot 4.2.2
    vec4 color = texture(screen_texture, SCREEN_UV) * vec4(albedo.rgb * albedo_strength, 1.0);
    vec2 pixel = floor(SCREEN_UV * vec2(textureSize(screen_texture, 0)) / dither_pixel_size + dither_pixel_offset) + 0.5;

    float dither_value = get_dither_value(pixel);
    ALBEDO = get_dither_color(dither_value, color).rgb;
}
