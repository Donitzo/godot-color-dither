# Godot Color Dither

![Sample](https://github.com/Donitzo/godot-color-dither/blob/main/images/sample.png)

## Description

Multicolored dithering shaders for Godot 4. These shaders replace the colors on the screen with dithering patterns of one or more indexed colors taken from a `dither palette` image.

## Dither palette

The dither palette images are generated with the `dither_palette_generator.gd` editor script. These images act as look-up tables for dithering color mixes. This is done by converting the original color into a UV coordinate on the dither palette image. Red translates to one of 16 columns, where each column contains 16x16xN pixels, where N is the number mixing colors. A dither value points to which row to use, and the blue and green color components points to pixel in the 16x16 tile.

The following is an example of a four color dither palette [CGA Palette 0](https://lospec.com/palette-list/cga-palette-0-high):

![Sample](https://github.com/Donitzo/godot-color-dither/blob/main/src/color_dither/textures/palettes/cga-palette-0-high.png)

The dithering algorithms used in color selection for the dither palette images are based on code and algorithms by Joel Yliluoma. A dithering pattern with over 2 colors uses the gamma-corrected algorithm, while an alternative algorithm is used for dithering patterns with 2 colors.

The shaders work best at low resolutions or low-resolution viewports and *does not pixelize* the screen.

## Shaders

There are four shader variations:

- color_dither_2d: Dithering shader for [Sprites](https://docs.godotengine.org/en/3.5/classes/class_sprite.html) and [TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html). Supports screendoor transparency.
- color_dither_post_2d: Dithering postprocessing shader for 2D which applies dithering to the entire screen. Does not support screendoor transparency. Easiest way to use is to assign it to a fullscreen [ColorRect](https://docs.godotengine.org/en/stable/classes/class_colorrect.html)
- color_dither_3d: Dithering shader for 3D nodes such as [MeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html). Supports screendoor transparency.
- color_dither_post_3d: Dithering postprocessing shader for 3D which applies dithering to the entire screen. Does not support screendoor transparency. Easiest way to use is to assign it to a [MeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html) with a 2x2 [QuadMesh](https://docs.godotengine.org/en/stable/classes/class_quadmesh.html)

## Feedback & Bug Reports

If there are additional variations you would find useful, or if you find any bugs or have other feedback, please [open an issue](https://github.com/Donitzo/godot-simple-portal-system/issues).
