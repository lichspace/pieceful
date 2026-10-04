# 拾光拼图

Apple 原生多平台拼图 MVP，目标平台为 iPhone、iPad 和 Mac。

## 已实现

- SwiftUI 分类首页：动物、建筑、交通工具、自然、太空、机甲、海洋。
- 分类图片列表和 12 / 24 / 48 / 96 片难度选择。
- SpriteKit 棋盘、拖拽、吸附、放置锁定和完成庆祝动画。
- 奶油白、浅杏色与陶橙色的统一浅色主题，覆盖首页、弹层、棋盘和托盘。
- 完成庆祝、完整图片和用时 / 移动 / 提示统计合并在同一个结果弹层中。
- Codable 本地存档，12 / 24 / 48 / 96 片难度首版全部开放。
- 配乐、拿起、放下、吸附、提示和完成音效；设置中可分别开关。
- 竖向/横向响应式棋盘，iPad 和 Mac 窗口缩放时自动重排。
- 现有 4 张图片及新增 52 张 4:3 插画，共 56 张；机甲分类含 6 张图片，主题图片数量从资源自动统计。

## 打开工程

在安装完整 Xcode 的 Mac 上打开 `ShiguangPuzzle.xcodeproj`，选择 `ShiguangPuzzle` scheme，然后选择 iPhone、iPad 或 Mac 目标运行。

已通过 macOS Debug 构建（`CODE_SIGNING_ALLOWED=NO`），拼图目录与图片资源引用检查通过。新增插画的生成提示词保存在 `Design/PuzzleArtwork/prompts.json`。

浅色主题与统一结果弹层已通过 macOS、iOS Simulator 构建及 20 项核心测试，并在 Mac 上验证了完成、返回列表和重新开始流程。运行 macOS 测试时使用 `MACOSX_DEPLOYMENT_TARGET=13.0`，与应用的最低系统版本保持一致。

## GitHub Actions 无签名构建

推送到 `main`、推送 `v*` 标签或向 `main` 提交 PR 时，会运行 [Unsigned builds](https://github.com/lichspace/pieceful/actions/workflows/build-unsigned.yml)。也可以在 Actions 页面选择 **Run workflow** 手动触发。构建使用 macOS 15 / Xcode 16.4，不需要配置 Apple 证书、描述文件或签名 Secrets。

构建完成后，在该次运行的 **Artifacts** 中下载（保留 14 天）：

| 产物 | 内容 |
| --- | --- |
| `ShiguangPuzzle-macOS-unsigned` | Release `.app.zip`，包含 Apple Silicon 和 Intel 两种架构 |
| `ShiguangPuzzle-iOS-unsigned` | iPhone / iPad 真机 arm64 Release `.ipa`，需自行签名后安装 |

每份产物附带 SHA-256 校验文件。Mac 版本未使用开发者证书签名或公证；iOS 版本不能直接安装或提交 App Store。构建日志单独保存 7 天。

本地使用同一脚本构建，输出位于 `dist/`：

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
bash Tools/build_unsigned.sh macos
bash Tools/build_unsigned.sh ios
```

## 替换试产资源

将正式图片放进 `ShiguangPuzzle/Resources/Images`，并在 `PuzzleCatalog.swift` 中增加 `PuzzleDefinition`。音频放进 `ShiguangPuzzle/Resources/Audio`，文件名沿用 `AudioEvent` 的资源名即可替换正式授权素材。

`Tools/generate_audio.py` 只用于生成当前 MVP 的原创程序化占位音频，方便无外部音频资源时直接演示。
