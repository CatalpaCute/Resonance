# GitHub Actions 发布构建说明

这个仓库的自动构建只在 GitHub Release 被正式发布时触发，不会在普通 `push` 时启动。

## 触发方式

正确流程：

1. 在 GitHub 上创建一个 Draft Release。
2. 为它选择或新建一个 tag，例如 `v0.7.0`。
3. 检查 Release 内容。
4. 点击 `Publish release`。

触发后，Actions 会自动执行三项构建：

- Android `release` APK（1 个 universal + 3 个按 ABI 拆分）
- Linux `release` bundle 压缩包（x64 + arm64）
- Windows `release` 打包压缩包（x64 + arm64）

构建完成后，产物会自动上传回当前这个 Release。

## 必要 Secrets

在仓库 `Settings -> Secrets and variables -> Actions` 中配置下面 4 个 secrets：

- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

Android 签名文件会在 CI 运行时临时还原为 `android/upload-keystore.jks`，不会写回仓库。

## 产物命名

工作流会从 `pubspec.yaml` 读取软件版本号，并把版本号和 Release tag 一起写进最终文件名。

- Android universal：`Resonance-android-<version>-<tag>-universal.apk`
- Android arm64：`Resonance-android-<version>-<tag>-arm64-v8a.apk`
- Android armv7：`Resonance-android-<version>-<tag>-armeabi-v7a.apk`
- Android x64：`Resonance-android-<version>-<tag>-x86_64.apk`
- Linux x64：`Resonance-linux-<version>-<tag>-x64.zip`
- Linux arm64：`Resonance-linux-<version>-<tag>-arm64.zip`
- Windows x64：`Resonance-windows-<version>-<tag>-x64.zip`
- Windows arm64：`Resonance-windows-<version>-<tag>-arm64.zip`

例如当前 `pubspec.yaml` 里是 `0.7.0+13`，tag 是 `Testv10`，那么产物文件名会是：

- `Resonance-android-0.7.0+13-Testv10-universal.apk`
- `Resonance-android-0.7.0+13-Testv10-arm64-v8a.apk`
- `Resonance-android-0.7.0+13-Testv10-armeabi-v7a.apk`
- `Resonance-android-0.7.0+13-Testv10-x86_64.apk`
- `Resonance-linux-0.7.0+13-Testv10-x64.zip`
- `Resonance-linux-0.7.0+13-Testv10-arm64.zip`
- `Resonance-windows-0.7.0+13-Testv10-x64.zip`
- `Resonance-windows-0.7.0+13-Testv10-arm64.zip`

Linux 当前输出的是 Flutter `linux` 的 `bundle` 目录压缩包，分别提供 `x64` 和 `arm64` 两种架构。解压后可直接运行其中名为 `Resonance` 的可执行文件，但目标机器仍需要系统级 GTK 运行库。CI 会先在 runner 的临时目录生成这些 zip，再把它们作为 Release 资产上传回当前发布。

Windows 当前输出的是 Flutter `windows` 发布目录压缩包，分别提供 `x64` 和 `arm64` 两种架构，解压后可直接运行。如果后续需要标准安装器，可以再接 `msix` 或 Inno Setup。

## 设计说明

- 工作流使用 `release.published`，因为 GitHub 对 Draft Release 的 `created/edited/deleted` 事件不会触发 workflow。
- Linux 构建依赖按 Flutter 官方 Linux 桌面文档安装，并额外补上 `tray_manager` 需要的 `libayatana-appindicator3-dev`：`clang`、`cmake`、`ninja-build`、`pkg-config`、`libgtk-3-dev`、`libstdc++-12-dev`、`libayatana-appindicator3-dev`。
- Android 构建会同时产出一个 universal APK 和三个按 ABI 拆分的 APK。拆分包体积更小，universal APK 则保留为通用兜底版本。
- Android 构建优先读取 CI 生成的 `android/key.properties`；本地没配正式签名时，会自动回退到 debug 签名，避免影响日常开发。
- Linux 与 Windows 现在都通过 GitHub 官方 arm64 hosted runner 额外产出 `arm64` 版本，因此 Release 中会同时看到 `x64` 和 `arm64` 两套桌面包。
