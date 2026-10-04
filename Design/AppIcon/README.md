# 拾光拼图应用图标

当前版本：可爱水晶风格。单枚圆润亮青蓝拼图块，粉紫折射边缘，糖果粉背景；简洁、明亮、易识别。

- `pieceful-ios-source.png`：内置 ImageGen 编辑的原图，背景全不透明，外部四角不预裁切。
- `pieceful-macos-source.png`：内置 ImageGen 编辑的 Mac 版本，圆角底板外保留透明留白。
- 发布资源位于 `../../ShiguangPuzzle/Resources/Assets.xcassets/AppIcon.appiconset`，使用 macOS `sips` 缩放导出。20 个 PNG 覆盖 iPhone、iPad、App Store 和 Mac 的 28 个图标槽位。
- Xcode 主应用的 Debug / Release 均使用 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`。
- 旧版风景图标的原图及生成记录保留在 `archive/classic/`。

## iOS 风格修改提示词

```text
Use case: style-transfer
Asset type: final square app icon for the jigsaw puzzle game 拾光拼图 / Pieceful.
Edit target: the supplied old green-and-gold app icon. Preserve only the central single jigsaw-piece concept and its instantly recognizable silhouette. Completely redesign its material, colors and background to match the user's new brief: 可爱水晶风格，颜色亮丽，简单明了 (cute crystal style, bright cheerful colors, simple and clear).
Primary request: one adorable plump crystal-glass jigsaw piece, with soft generously rounded edges, a wide glossy bevel and smooth transparent candy-glass depth. Make it a bold modern playful icon with an immediately legible single silhouette.
Color and material: luminous vivid aqua / cyan crystal body, with a little iridescent lilac and candy-pink refraction along the lower edge. A few broad clean white specular highlights reveal the polished glass. Broad simple color regions and restrained crystal refraction; no intricate shards or busy facets.
Background: clean luminous pale candy pink, a very gentle peach-to-pink gradient, full-bleed opaque square. Soft short lavender contact shadow under the piece creates friendly toy-like volume. Bright, airy and cheerful.
Composition: one centered nearly front-facing jigsaw piece, very slight playful tilt, roughly 72 percent of the total canvas in width and height, balanced generous margin, clear round tabs and sockets, strong readable contour at 32 pixels. A single object, very simple.
Remove all landscape imagery, mountains, sun, wood grain, painterly texture, dark green and antique gold from the old image.
Constraints: output just one production-ready icon, at least 1024 by 1024 square. The entire background must be opaque to all four corners; do not round the outer canvas. No text, letters, faces, extra pieces, stars, floating decorations, glitter particles, complex scene, sharp spiky gems, frame, border, watermark, grid or device mockup. The puzzle piece itself should be translucent colorful crystal, while the final square image is fully opaque.
```

## macOS 适配提示词

```text
Use case: precise-object-edit
Asset type: macOS application icon variant of the just-generated cute crystal Pieceful icon.
Input image: the most recent bright cyan crystal jigsaw piece on an opaque candy-pink background. This is the edit target.
Change only the outer canvas treatment. Keep the complete original artwork unchanged: the exact single cyan glass jigsaw silhouette, all white highlights, lilac and pink edge refraction, pink/peach gradient background, lighting and proportions.
Scale the complete square artwork uniformly to fit a centered rounded-square tile occupying 84 percent of the square canvas width and height. Use beautifully smooth generous macOS-style continuous rounded corners, with a corner radius about 22 percent of the tile width. The pink background reaches the tile's edges, and the whole tile stays opaque.
Outside this rounded-square tile, use genuinely transparent alpha, plus only a subtle short soft shadow under the tile.
No redesign of the central artwork, no extra objects, no new highlights, no words, no frame, no fake transparency checkerboard, no mockup. Output one square PNG at least 1024 by 1024 with real transparency.
```

## macOS 透明边缘修整提示词

```text
Use case: precise-object-edit
Edit target: the most recent Mac app icon showing a cyan glass puzzle piece on a pink rounded-square tile.
Repair only the outer edge and transparent surroundings. The previous output has unwanted stray red/pink/white pixels and detached specks ABOVE and around the tile. Remove every stray speck and noisy fringe outside the rounded square. Remove the exterior drop shadow completely so the cutout edge is pristine and extremely simple.
Everything outside the single smooth rounded-square tile should have exactly zero alpha, perfectly clean with no floating pixels, no haze, no color islands, and no shadow. Use a clean antialiased alpha edge with a narrow transition only at the tile contour.
Preserve the central cyan crystal puzzle artwork, pink gradient tile, highlights, proportions, position, size and colors unchanged. Keep the tile fully opaque internally. Same square canvas and original generous transparent outer margins. Do not add, redraw or move any design element.
Output a single production PNG with truly transparent surroundings. No checkerboard, no background color, no mockup.
```
