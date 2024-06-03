# Godot Color Dither

![Sample](https://github.com/Donitzo/godot-color-dither/blob/main/images/sample.png)

## Description

This project contains a set of multicolored dithering shaders for Godot 4. The shaders work by replacing the colors of 2D nodes, 3D nodes or the entire screen in the case of postprocessing. The colors are replaced with a pre-planned dithering pattern of one or more colors taken from a "dither palette" image. The resulting dither mix roughly approximates the original color, giving the scene an old-school retro look.

The dithering algorithms used in color selection for the dither palette images is derived from code and algorithms by Joel Yliluoma. You can read more about his algorithms in this article: [Joel Yliluoma's arbitrary-palette positional dithering algorithm](https://bisqwit.iki.fi/story/howto/dither/jy/). A dithering pattern with over 2 colors uses the gamma-corrected algorithm 3, while algorithm 2 is used for dithering patterns with 2 colors.

## Demo

The [demo project](https://donitz.itch.io/godot-color-dither) is hosted on Itch.io, where you can try out the different types of dithering available.

## Instructions

The demo project is available in the `src` directory. Import the project into Godot 4 to test the shaders. To use the color dither shaders in your project, you will need to include the shader files located at `src/color_dither/shaders`. Assign the appropriate shader variant to your node’s material, then select a dither palette image for the material. There are some additional uniforms used in dither placement (See the next section).

## Locality and transparency

There are two types of shaders: Postprocessors and regular shaders. 

- The postprocessors operate in screen space, meaning that the color dither will appear to be *fixed*. Sprites will have the dither scroll across them as they move.
- The regular shaders operate in local space, meaning that the dither will follow the sprite/mesh. This causes less flickering, but may be undesirable for transparency. Imagine, for example two overlapping 50% opaque sprites randomly being 100% opaque or 50% opaque depending on how the alpha dither (screendoor transparency) overlaps.

To accommodate the case where you want to both have fixed and non-fixed dithering, you should use the regular shaders (non-postprocessing), and instead offset the dither using the uniforms called `pixel_offset` and `alpha_pixel_offset`. These uniforms simply offset the dither in local space. See the `tweener.gd` script for a sample how to use these parameters to make the dither static in the world. Note that this is less performant as the shader uniforms must be updated each frame for moving sprites.

## Dither palette

What I have chosen to call "dither palette" images serve as lookup tables for color mixes, translating the original color into a UV coordinate on the dither palette image. The red component selects one of 16 columns, each containing pixels arranged in a 16x16xN grid, where N represents the number of mixing colors. A dither value selects the row, and the blue and green components select a pixel within the 16x16 tile. As the dither value changes, the tile row changes, resulting in a mix of the colors from each tile row.

![Dither palette](https://github.com/Donitzo/godot-color-dither/blob/main/images/dither_palette.png)

To create your own dither palette, you can use the `dither_palette_generator.gd` editor script. Assign it to the scene, and assign a `palette_image` containing the original colors in the inspector, and the `dither_color_count` with the number of colors to mix together to approximate the original color. Using 1 color would make the dithering shader a simple color replacement shader. For dithering, 2 to 4 colors seems appropriate.

The following is an example of a four color mix (rows) dither palette [CGA Palette 0](https://lospec.com/palette-list/cga-palette-0-high):

![Sample](https://github.com/Donitzo/godot-color-dither/blob/main/src/color_dither/textures/palettes/cga-palette-0-high.png)

Other palettes included are [Steam Lords](https://lospec.com/palette-list/steam-lords), [CGA](https://lospec.com/palette-list/color-graphics-adapter), [1bit Monitor Glow](https://lospec.com/palette-list/1bit-monitor-glow), [Sweetie 16](https://lospec.com/palette-list/sweetie-16).

The shaders work best at low resolutions or low-resolution viewports and *does not inherently pixelize* the screen. There is a `pixel_size` uniform in the shaders, but it should only be used when the actual sprite art has scaled pixels.

## Shaders

There are four shader variations:

- **color_dither_2d**: Dithering shader for [Sprites](https://docs.godotengine.org/en/3.5/classes/class_sprite.html), [TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html) and other [CanvasItems](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) using the TEXTURE uniform. Supports screendoor transparency.
- **color_dither_post_2d**: Dithering postprocessing shader for 2D which applies dithering to the entire screen. Does not support screendoor transparency. The easiest way to use this shader is to assign it to a fullscreen [ColorRect](https://docs.godotengine.org/en/stable/classes/class_colorrect.html). You will have to handle automatic resizing yourself.
- **color_dither_3d**: Dithering shader for 3D nodes such as [MeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html). Supports screendoor transparency. Note that the dithering is still in UV space.
- **color_dither_post_3d**: Dithering postprocessing shader for 3D which applies dithering to the entire screen. Does not support screendoor transparency. The easiest way to use the shader is to assign it to a [MeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html) with a 2x2 [QuadMesh](https://docs.godotengine.org/en/stable/classes/class_quadmesh.html).

## Feedback & Bug Reports

If there are additional variations you would find useful, or if you find any bugs or have other feedback, please [open an issue](https://github.com/Donitzo/godot-simple-portal-system/issues).
