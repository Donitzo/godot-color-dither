"""
    Asset: Godot Color Dither
    File: dither_palette_generator.gd
    Description:
        Generates a dither palette for the color dither shaders.
        The mixing planner is derived from algorithms and code by Joel Yliluoma:
            http://bisqwit.iki.fi/story/howto/dither/jy/
    Repository: https://github.com/Donitzo/godot-color-dither
    License:
MIT License

Copyright (c) 2024 Donitzo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

@tool
extends Node

@export var palette_image:Image
@export var output_png_path:String = 'res://my_dither_palette.png'
@export_range (1, 16) var dither_color_count:int = 4
@export var create_dither_palette:bool:
    set(value):
        if value:
            create_dither_palette = false

            _create_dither_palette()

# Creates a dither palette image from the unique colors in another image.
#
# The palette image structure:
#
# |  |  |  |  |  |  |  |    row of 16 16x16 tiles with the third mix color
# |__|__|__|__|__|__|__|__
# |  |  |  |  |  |  |  |    row of 16 16x16 tiles with the second mix color
# |__|__|__|__|__|__|__|__
# |  |  |  |  |  |  |  |    row of 16 16x16 tiles with the first mix color
# |__|__|__|__|__|__|__|__
#
# Each horizontal tile has a fixed red component: 0/15 to 15/15.
# The blue component increases from 0 to 1 horizontally over a tile.
# The green component increases from 0 to 1 vertically over a tile.
#
# The palette image is used in the dither shaders to convert a single color to several dithered colors.
# The dithered colors are mixed together in a dithering pattern to produce an approximation of the original color.
#
# The steps to create the palette image:
# 1. Load the color image
# 2. Create a list of all the unique colors in the image
# 3. a) Loop through each pixel in the palette image and determine the color for that pixel
#    b) Device a mixing plan to approximate the color
#    c) Save the dither colors in the tile column
# 4. Save the palette image
func _create_dither_palette() -> void:
    print('Creating dither palette image with %d mixed colors' % dither_color_count)

    palette_image.decompress()

    var palette:Array = []

    for y in range(palette_image.get_height()):
        for x in range(palette_image.get_width()):
            var color:Color = palette_image.get_pixel(x, y)
            if not palette.has(color):
                palette.push_back(color)

    print('Palette has %d unique colors' % palette.size())
    if palette.size() == 2:
        print('Generating dither palette using Yliluoma\'s ordered dithering algorithm 2 (colors == 2)')
    else:
        print('Generating dither palette using Yliluoma\'s ordered dithering algorithm 3 (colors > 2)')

    var gamma_correct:Callable = func(x:float): return pow(x, 2.2)
    var gamma_uncorrect:Callable = func(x:float): return pow(x, 1.0 / 2.2)

    var luminance:Array = []
    var gamma_corrected:Array = []

    for color in palette:
        luminance.push_back(color.r8 * 299 + color.g8 * 587 + color.b8 * 114)
        gamma_corrected.push_back([gamma_correct.call(color.r), gamma_correct.call(color.g), gamma_correct.call(color.b)])

    var color_compare:Callable = func(r1:int, g1:int, b1:int, r2:int, g2:int, b2:int) -> float:
        var luma_1:float = (r1 * 299 + g1 * 587 + b1 * 114) / (255.0 * 1000)
        var luma_2:float = (r2 * 299 + g2 * 587 + b2 * 114) / (255.0 * 1000)
        var luma_diff:float = luma_1 - luma_2
        var diff_r:float = (r1 - r2) / 255.0
        var diff_g:float = (g1 - g2) / 255.0
        var diff_b:float = (b1 - b2) / 255.0
        return (diff_r * diff_r * 0.299 + diff_g * diff_g * 0.587 + diff_b * diff_b * 0.114) * 0.75 + luma_diff * luma_diff

    var devise_best_mixing_plan:Callable = func(target_color:Color) -> Array:
        var input_r:int = target_color.r8
        var input_g:int = target_color.g8
        var input_b:int = target_color.b8

        var mixing_plan:Array = []
        for i in dither_color_count:
            mixing_plan.push_back(0)

        if palette.size() == 2:
            # Use an alternative planning algorithm if the palette only has 2 colors
            # Yliluoma's ordered dithering algorithm 2

            var so_far:Array = [0, 0, 0]
            var proportion_total:int = 0

            while proportion_total < dither_color_count:
                var chosen_amount:int = 1
                var chosen_index:int = 0

                var max_test_count:int = max(1, proportion_total)

                var least_penalty:float = -1

                for i in palette.size():
                    var color:Color = palette[i]
                    var sum:Array = so_far.duplicate()
                    var add:Array = [color.r8, color.g8, color.b8]
                    var p:int = 1
                    while p <= max_test_count:
                        for c in 3:
                            sum[c] += add[c]
                        for c in 3:
                            add[c] += add[c]

                        var t:int = proportion_total + p

                        var penalty:float = color_compare.call(
                            input_r, input_g, input_b,
                            int(sum[0] / t), int(sum[1] / t), int(sum[2] / t))

                        if penalty < least_penalty or least_penalty < 0:
                            least_penalty = penalty
                            chosen_index = i
                            chosen_amount = p

                        p *= 2

                for p in chosen_amount:
                    if proportion_total >= dither_color_count:
                        break
                    mixing_plan[proportion_total] = chosen_index
                    proportion_total += 1

                var chosen:Color = palette[chosen_index]
                so_far[0] += chosen.r8 * chosen_amount
                so_far[1] += chosen.g8 * chosen_amount
                so_far[2] += chosen.b8 * chosen_amount
        else:
            # Use the gamma-corrected planning algorithm if the palette has more than 2 colors
            # Yliluoma's ordered dithering algorithm 3

            var solution:Dictionary = {}

            var current_penalty:float = -1
            var chosen_index:int

            for i in palette.size():
                var color:Color = palette[i]
                var penalty:float = color_compare.call(
                    input_r, input_g, input_b, 
                    color.r8, color.g8, color.b8)
                if penalty < current_penalty or current_penalty < 0:
                    current_penalty = penalty
                    chosen_index = i

            solution[chosen_index] = dither_color_count

            var dbl_limit:float = 1.0 / dither_color_count
            while current_penalty != 0:
                var best_penalty:float = current_penalty
                var best_split_from:int = 0
                var best_split_to:Array = [0, 0]

                for split_color in solution:
                    var split_count:int = solution[split_color]

                    var sum:Array = [0.0, 0.0, 0.0]

                    for split_color_2 in solution:
                        if split_color == split_color_2:
                            continue
                        var split_count_2:int = solution[split_color_2]
                        sum[0] += gamma_corrected[split_color_2][0] * split_count_2 * dbl_limit
                        sum[1] += gamma_corrected[split_color_2][1] * split_count_2 * dbl_limit
                        sum[2] += gamma_corrected[split_color_2][2] * split_count_2 * dbl_limit

                    var portion_1:float = (split_count / floor(2)) * dbl_limit
                    var portion_2:float = (split_count - split_count / floor(2)) * dbl_limit

                    for a in palette.size():
                        var first_b:int = a + 1 if portion_1 == portion_2 else 0
                        for b in range(first_b, palette.size()):
                            if a == b:
                                continue
                            var luma_diff:int = luminance[a] - luminance[b]
                            if luma_diff < 0:
                                luma_diff = -luma_diff
                            if luma_diff > 80000:
                                continue

                            var test:Array = [
                                gamma_uncorrect.call(sum[0] + gamma_corrected[a][0] * portion_1 + gamma_corrected[b][0] * portion_2),
                                gamma_uncorrect.call(sum[1] + gamma_corrected[a][1] * portion_1 + gamma_corrected[b][1] * portion_2),
                                gamma_uncorrect.call(sum[2] + gamma_corrected[a][2] * portion_1 + gamma_corrected[b][2] * portion_2),
                            ]

                            var penalty:float = color_compare.call(
                                input_r, input_g, input_b, 
                                test[0] * 255, test[1] * 255, test[2] * 255)

                            if penalty < best_penalty:
                                best_penalty = penalty
                                best_split_from = split_color
                                best_split_to[0] = a
                                best_split_to[1] = b

                            if portion_2 == 0:
                                 break

                if best_penalty == current_penalty:
                    break

                var best_split_count:int = solution[best_split_from]
                var split_1:int = best_split_count / floor(2)
                var split_2:int = best_split_count - split_1
                solution.erase(best_split_from)
                if split_1 > 0:
                    if solution.has(best_split_to[0]):
                        solution[best_split_to[0]] += split_1
                    else:
                        solution[best_split_to[0]] = split_1
                if split_2 > 0:
                    if solution.has(best_split_to[1]):
                        solution[best_split_to[1]] += split_2
                    else:
                        solution[best_split_to[1]] = split_2
                current_penalty = best_penalty

            var n:int = 0
            for color_index in solution:
                var split_count:int = solution[color_index]
                for i in split_count:
                    mixing_plan[n] = color_index
                    n += 1

        var sorted_mixing_plan:Array = []
        for i in mixing_plan:
            sorted_mixing_plan.push_back([palette[i], luminance[i]])
        sorted_mixing_plan.sort_custom(func(a, b): return a[1] < b[1])

        var mixing_plan_colors:Array = []
        for element in sorted_mixing_plan:
            mixing_plan_colors.push_back(element[0])

        return mixing_plan_colors

    var dither_palette_image:Image = Image.create(16 * 16, 16 * dither_color_count, false, Image.FORMAT_RGB8)

    for x in 16 * 16:
        for y in 16:
            var color:Color = Color(floor(x / floor(16)) / 15.0, y / 15.0, fmod(x, 16.0) / 15.0)
            var mixing_plan:Array = devise_best_mixing_plan.call(color)
            for i in dither_color_count:
                dither_palette_image.set_pixel(x, y + i * 16, mixing_plan[i])

    dither_palette_image.save_png(output_png_path)

    print('Dither palette image saved at "%s"' % output_png_path)
