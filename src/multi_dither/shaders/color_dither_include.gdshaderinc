/*
    Asset: Godot Multi Dither
    File: color_dither_include.gdshader
    Description: Common includes for color dither shaders.
    Repository: https://github.com/Donitzo/godot-color-dither
    License: CC0 License
*/

const mat4 bayer_matrix = mat4(
    vec4(00.0 / 16.0, 12.0 / 16.0, 03.0 / 16.0, 15.0 / 16.0),
    vec4(08.0 / 16.0, 04.0 / 16.0, 11.0 / 16.0, 07.0 / 16.0),
    vec4(02.0 / 16.0, 14.0 / 16.0, 01.0 / 16.0, 13.0 / 16.0),
    vec4(10.0 / 16.0, 06.0 / 16.0, 09.0 / 16.0, 05.0 / 16.0));

// Get the dither value from a 4x4 Bayer Matrix
float get_dither_value(vec2 pixel) {
    int x = int(pixel.x - 4.0 * floor(pixel.x / 4.0));
    int y = int(pixel.y - 4.0 * floor(pixel.y / 4.0));
    return bayer_matrix[x][y];
}

// Pixel size used in dithering
uniform float dither_pixel_size = 1.0;
// The pixel offset used for dithering
uniform vec2 dither_pixel_offset = vec2(0.0);

// Albedo color
uniform vec4 albedo : source_color = vec4(1.0);
// Albedo multiplier
uniform float albedo_strength = 1.0;

#if defined(IS_POSTPROCESSOR)
// Used as a screen-reading postprocessor

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

vec4 get_albedo(vec2 uv) {
    return texture(screen_texture, uv) * vec4(albedo.rgb * albedo_strength, 1.0);
}

vec2 get_pixel_center(vec2 uv) {
    return floor(uv * vec2(textureSize(screen_texture, 0)) / dither_pixel_size + dither_pixel_offset) + 0.5;
}
#else
// Used as a regular material

vec4 get_albedo(sampler2D texture_albedo, vec2 uv) {
    return texture(texture_albedo, uv) * albedo * vec4(vec3(albedo_strength), 1.0);
}

vec2 get_pixel_center(sampler2D texture_albedo, vec2 uv) {
    return floor(uv * vec2(textureSize(texture_albedo, 0)) / dither_pixel_size + dither_pixel_offset) + 0.5;
}
#endif

// The dither palette texture
uniform sampler2D dither_palette : source_color, filter_nearest;

// Return the dither value for a color based on only the dither value
vec4 get_dither_color(float dither_value, vec4 color) {
    // Each color tile in the palette is 16x16, so color count = rows = Y / 16
    vec2 palette_size = vec2(textureSize(dither_palette, 0));
    float color_count = floor((palette_size.y + 1.0) / 16.0);

    // The dither value determines which color index (tile row) to use.
    // The green color component determines the vertical color within the targetted 16x16 tile.
    float y = (clamp(color.g * 16.0, 0.5, 15.5) + floor(dither_value * color_count) * 16.0) / palette_size.y;

    // The red color component determines which tile column to use.
    // Finally, the blue color component determines the horizontal color within the targetted 16x16 tile.
    float x = clamp(floor(color.r * 16.0), 0.0, 15.0) / 16.0 + clamp(color.b * 16.0, 0.5, 15.5) / 256.0;

    return vec4(texture(dither_palette, vec2(x, y)).rgb, 1.0);
}