# 拾光拼图应用图标

以深森林绿、暖金色拼图块和夕阳山丘呼应现有界面及「一段安静的游戏时光」。

- `pieceful-ios-source.png`：内置 ImageGen 生成的原始图，四角不预裁切，背景不透明。
- `pieceful-macos-source.png`：内置 ImageGen 编辑的 Mac 版本，圆角底板外保留透明留白。
- 发布资源位于 `../../ShiguangPuzzle/Resources/Assets.xcassets/AppIcon.appiconset`，使用 macOS `sips` 从对应原图缩放导出；`Contents.json` 包含 iPhone、iPad、App Store 和 Mac 的尺寸映射。
- Xcode 主应用的 Debug / Release 均使用 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`。

## iOS 原图生成提示词

```text
Use case: logo-brand
Asset type: production app icon for 拾光拼图 (Pieceful), a calm native iPhone/iPad/Mac jigsaw puzzle game.
Primary request: Create one refined, memorable square app icon. A single large recognizable jigsaw puzzle piece holds a warm sunset landscape, suggesting collecting peaceful moments.
Scene/backdrop: full-bleed deep forest green (#10241F) with a very subtle soft lighter center, completely opaque and extending to all four square corners.
Subject: one upright, centered ivory-and-honey jigsaw piece with clearly rounded interlocking tabs and sockets, containing a minimal scene of a luminous golden setting sun and two broad layered sage-green hills. The landscape is contained entirely inside the piece silhouette. A softly beveled edge gives a tactile painted wooden puzzle-piece feeling, with restrained depth and soft short shadow.
Style/medium: premium handcrafted game icon, elegant simplified illustration, clean strong silhouette, subtly painted surfaces, not photorealistic. Fits warm painterly landscapes and a dark forest-green interface with gold accents.
Composition/framing: 1:1 square, front facing, centered piece occupies roughly 72 percent of canvas width and height including tabs; balanced breathing room. Bold readable shapes that remain recognizable at 32 pixels. Sun in the upper portion of the piece, curved hills below.
Color palette: deep forest green, warm ivory (#F7F0D6), honey gold (#D9B875), muted sage green; warm soft sunset light.
Text: none.
Constraints: output only the finished single icon artwork, 1024 by 1024 or larger square; background opaque and full bleed. Do not round or mask the outer canvas corners. No text, letters, watermark, border frame, icon grid, presentation sheet, device mockup, tiny decorative objects, detached extra pieces, sparkles, glossy plastic, harsh neon, or intricate landscape detail.
```

## macOS 版本编辑提示词

```text
Use case: precise-object-edit
Asset type: macOS application icon variant of the supplied Pieceful app icon.
Input image: the just-generated forest-green square app icon with golden sunset landscape jigsaw piece; this is the edit target.
Change only the outer canvas treatment to create a native Mac app icon: keep the entire original artwork, colors, centered jigsaw silhouette, sun, painted hill shapes, bevel and composition unchanged, scale the complete square artwork uniformly to fit a centered rounded-square tile occupying 84% of the canvas width and height, with beautifully smooth generous macOS-style continuous rounded corners (corner radius approximately 22% of tile width). Outside this dark green rounded-square tile, the background must be genuinely transparent alpha. Keep a very subtle short shadow under the tile. The puzzle and dark green background must remain fully opaque within the tile. Preserve original art, do not redraw the central symbol, no new objects, no text, no mockup, no checkerboard. Output one square PNG at least 1024 by 1024 with real transparency.
```
