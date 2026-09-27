# LingoSwift

一个干净利落的 macOS 中英翻译应用，基于 Apple 的端上翻译引擎 —— 免费、离线、无需 API Key，文本不离开你的电脑。

A clean English ⇄ Chinese translator for macOS, powered by Apple's on-device translation engine. Free, private, offline after the one-time language pack download, and no API keys.

![macOS 15+](https://img.shields.io/badge/macOS-15.0%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## 中文说明

### 功能

- **英语 ⇄ 简体中文 / 繁体中文**互译，支持自动检测源语言
- **端上翻译**：使用 Apple `Translation` 框架，翻译在本机完成，不上传文本、不需要账号
- **边打字边翻译**：自动翻译可开关，延迟可调
- **历史记录侧边栏**：可搜索、点击回填、可清空
- **朗读**：调用系统语音朗读原文或译文
- **中文 / 英文界面**：跟随系统语言自动切换
- 常用快捷键：`⌘↩` 翻译、`⌘⇧S` 交换语言、`⌘⇧C` 复制译文、`⌘K` 清空

### 系统要求

- macOS 15.0 (Sequoia) 或更高版本
- Apple 芯片或 Intel 芯片均可（通用二进制）

### 安装

1. 从 [Releases](https://github.com/Lives0808/LingoSwift/releases) 下载 `LingoSwift-x.y.z.dmg`（或 `.zip`）。
2. 打开 DMG，把 **LingoSwift** 拖进「应用程序」文件夹。
3. 首次打开时，因为应用是自签名（没有 Apple 开发者付费证书），macOS 会提示"无法验证开发者"。任选其一：
   - 在「应用程序」里 **右键点按 LingoSwift → 打开 → 再点"打开"**；或
   - 在终端运行一次：`xattr -dr com.apple.quarantine /Applications/LingoSwift.app`

### 首次使用：下载语言包

Apple 的翻译模型由系统管理。第一次翻译某个语言方向时，macOS 会弹出系统对话框询问是否下载语言包，确认后等待下载完成（一次性，之后完全离线可用）。右上角的徽标会显示当前语言对的语言包状态。

### 从源码构建

只需要 macOS 自带的 Xcode Command Line Tools（无需完整 Xcode）：

```bash
git clone https://github.com/Lives0808/LingoSwift.git
cd LingoSwift
VERSION=1.0.0 ./Scripts/package.sh     # 生成 build/LingoSwift-1.0.0.dmg 和 .zip
open build/LingoSwift.app
```

调试运行：`swift run`

自检（查看语言包状态，语言包已安装时会执行一次真实翻译）：

```bash
build/LingoSwift.app/Contents/MacOS/LingoSwift --doctor
```

### 项目结构

```
Sources/LingoSwift/
  App/        应用入口、菜单命令
  Models/     语言模型、状态管理 (AppStore)、历史记录
  Views/      主界面、历史侧边栏、设置
  Support/    本地化辅助、诊断模式
Resources/    en.lproj / zh-Hans.lproj 界面文案
Packaging/    Info.plist 模板
Scripts/      图标生成、打包脚本
```

### 隐私

LingoSwift 不联网、不收集任何数据，也没有任何第三方依赖。翻译完全由 macOS 在本机完成，历史记录只保存在本机的 `UserDefaults` 里。

---

## English

### Features

- **English ⇄ Simplified / Traditional Chinese** with automatic source language detection
- **On-device translation** via Apple's `Translation` framework — no accounts, no API keys, nothing leaves your Mac
- **Translate as you type** with a configurable debounce delay
- **Searchable history sidebar** — click an entry to load it back into the editor
- **Speak** the source text or the translation using system voices
- **English / Chinese UI** that follows the system language
- Shortcuts: `⌘↩` translate, `⌘⇧S` swap languages, `⌘⇧C` copy translation, `⌘K` clear

### Requirements

- macOS 15.0 (Sequoia) or later
- Apple silicon or Intel (universal binary)

### Install

1. Download `LingoSwift-x.y.z.dmg` (or `.zip`) from [Releases](https://github.com/Lives0808/LingoSwift/releases).
2. Open the DMG and drag **LingoSwift** into Applications.
3. The app is self-signed (there is no paid Apple Developer certificate), so the first launch is blocked by Gatekeeper. Either **right-click LingoSwift → Open → Open**, or run once:
   `xattr -dr com.apple.quarantine /Applications/LingoSwift.app`

### First run

Apple manages the translation models. The first time you translate a language pair, macOS asks whether to download the language pack. Accept once, and everything works offline afterwards. The badge in the toolbar shows the current state of the pack.

### Build from source

Only the Xcode Command Line Tools are required (no full Xcode):

```bash
git clone https://github.com/Lives0808/LingoSwift.git
cd LingoSwift
VERSION=1.0.0 ./Scripts/package.sh     # produces build/LingoSwift-1.0.0.dmg and .zip
```

Run in development with `swift run`, or check the engine with `--doctor`.

### Privacy

LingoSwift makes no network requests, collects no data and has no third-party dependencies. Translation happens entirely on your Mac and history stays in local `UserDefaults`.

---

## License

MIT © 2026 Lives0808 — see [LICENSE](LICENSE).
