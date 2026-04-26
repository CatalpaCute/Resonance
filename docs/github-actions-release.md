# GitHub Actions 发布构建说明

这个仓库的自动构建只在 GitHub Release 被正式发布时触发，不会在普通 `push` 时启动。

## 触发方式

正确流程：

1. 在 GitHub 上创建一个 Draft Release。
2. 为它选择或新建一个 tag，例如 `v0.7.0`。
3. 检查 Release 内容。
4. 点击 `Publish release`。

触发后，Actions 会自动执行两项构建：

- Android `release` APK
- Windows `release` 打包压缩包

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

- Android：`Resonance-android-<version>-<tag>.apk`
- Windows：`Resonance-windows-<version>-<tag>.zip`

例如当前 `pubspec.yaml` 里是 `0.7.0+13`，tag 是 `Testv10`，那么产物文件名会是：

- `Resonance-android-0.7.0+13-Testv10.apk`
- `Resonance-windows-0.7.0+13-Testv10.zip`

Windows 当前输出的是 Flutter `windows` 发布目录压缩包，解压后可直接运行。如果后续需要标准安装器，可以再接 `msix` 或 Inno Setup。

## 设计说明

- 工作流使用 `release.published`，因为 GitHub 对 Draft Release 的 `created/edited/deleted` 事件不会触发 workflow。
- Android 构建优先读取 CI 生成的 `android/key.properties`；本地没配正式签名时，会自动回退到 debug 签名，避免影响日常开发。
