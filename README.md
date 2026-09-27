# LingoSwift

中英翻译应用，两个平台：

| 平台 | 状态 | 引擎 | 安装方式 |
|---|---|---|---|
| **Android** | ✅ 1.0.0 | Google ML Kit 端上模型（离线、免费、无需 Key） | 下载 APK 直接安装 |
| **macOS** | ✅ 1.0.0 | Apple `Translation` 框架（端上、离线、免费） | 下载 DMG 拖入应用程序 |

A clean English ⇄ Chinese translator for **Android** and **macOS**. Both versions translate entirely on-device: no accounts, no API keys, no telemetry, and no data leaving your phone or Mac.

![Android 8.0+](https://img.shields.io/badge/Android-8.0%2B-3DDC84) ![macOS 15+](https://img.shields.io/badge/macOS-15.0%2B-blue) ![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## Android 版

### 功能

- **英语 ⇄ 中文**互译，可自动检测源语言
- **端上翻译**：使用 Google ML Kit 离线模型，翻译在手机上完成，不上传文本
- **边输入边翻译**：自动翻译可开关，延迟可调
- **历史记录**：可搜索、点击回填、单条删除、一键清空
- **朗读**：系统 TTS 朗读原文或译文
- **Material 3 界面**：支持深色模式与动态取色，中文 / 英文自动切换
- 常用操作都在一屏内：交换语言、复制、清空

### 系统要求

- Android 8.0（API 26）或更高版本，arm64 / x86_64 设备均可
- 首次使用某个语言方向需要联网下载模型（约 30 MB），之后**完全离线**
- 国内网络下载模型需要能访问 Google 服务（模型由 Google 托管）；下载一次后就再也不用联网了

### 安装

1. 从 [Releases](https://github.com/Lives0808/LingoSwift/releases) 下载 `LingoSwift-android-x.y.z.apk`，传到手机（微信/数据线/网盘都行）。
2. 用手机上的文件管理器点开 APK，按提示允许「安装未知应用」。
3. 打开 LingoSwift，点「下载模型」等它跑完，就可以开始翻译了。

APK 用仓库里的自签名密钥签名（`android/keystore/`），所以后续版本可以直接覆盖安装。

### 从源码构建

需要 JDK 17 和 Android SDK（`platforms;android-35`、`build-tools;35.0.0`）：

```bash
cd android
./gradlew assembleDebug     # 或 ./gradlew assembleRelease
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

国内网络需要在 `~/.gradle/gradle.properties` 里给 Gradle 配代理才能拉取 Google Maven 依赖：

```properties
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=7890
```

### 与 macOS 版的差异

- ML Kit 只有 `zh` 一个中文模型，所以 Android 版是**简体中文**，没有简体/繁体选项
- macOS 版用 Apple 的翻译模型，Android 版用 Google 的，译文风格会有些差异

---

## 中文说明（macOS 版）

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
VERSION=1.0.0 ./Scripts/package.sh     # 生成 build/LingoSwift-1.0.0.dmg 和 .zip
open build/LingoSwift.app
```

调试运行：`swift run`。自检（查看语言包状态）：

```bash
build/LingoSwift.app/Contents/MacOS/LingoSwift --doctor
```

---

## 项目结构

```
android/                  Android 应用（Kotlin + Jetpack Compose + ML Kit）
  app/src/main/java/com/lives0808/lingoswift/
    data/                 语言模型、翻译引擎、历史记录、状态管理
    ui/                   主界面、历史记录、设置、主题
  keystore/               APK 签名密钥（公开，便于覆盖安装）
Sources/LingoSwift/       macOS 应用（SwiftUI + Apple Translation）
  App/ Models/ Views/ Support/
Resources/                macOS 界面文案（en / zh-Hans）
Packaging/                macOS Info.plist 模板
Scripts/                  图标生成、打包脚本（macOS + Android 图标）
```

## 隐私

两个版本都不收集任何数据，也没有第三方统计 SDK。翻译完全在设备上完成：历史记录只保存在本机（macOS 用 `UserDefaults`，Android 用 `SharedPreferences`）。唯一需要联网的时刻是首次下载翻译模型。

## License

MIT © 2026 Lives0808 — see [LICENSE](LICENSE).
