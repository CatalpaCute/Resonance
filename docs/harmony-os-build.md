# HarmonyOS / OpenHarmony 打包适配

本文说明 Resonance 的 `ohos/` 工程骨架如何配合 OpenHarmony 适配版 Flutter SDK 生成 HAP 包。仓库只提交可维护的工程配置，`har/`、`oh_modules/`、`build/` 等产物由本地或 CI 构建生成，不纳入版本库。

## 前置条件

- 使用支持 `ohos` 平台的 Flutter SDK，例如参考仓库中的 OpenHarmony Flutter 适配分支。
- DevEco Studio / OpenHarmony SDK / ohpm / hdc 已配置到环境变量。
- 项目当前 `pubspec.lock` 显示 SDK 下限为 Dart `>=3.11.1`、Flutter `>=3.38.4`。如果使用较旧的 OHOS Flutter SDK，需要重新解析依赖或降级不兼容的插件版本。

## 工程入口

- `ohos/AppScope/app.json5` 使用现有包名 `work.czzzz.reader`，版本跟随 `pubspec.yaml` 的 `0.16.0+29`。
- `ohos/entry/src/main/ets/entryability/EntryAbility.ets` 继承 `FlutterAbility`，并调用 `GeneratedPluginRegistrant.registerWith` 注册 Flutter 插件。
- `ohos/entry/src/main/ets/pages/Index.ets` 通过 `FlutterPage` 承载 Dart 入口。
- `ohos/entry/src/main/module.json5` 声明了 `ohos.permission.INTERNET`，用于 RSS 拉取、WebDAV 和云同步请求。
- `ohos/entry/src/main/resources/rawfile/buildinfo.json5` 显式开启 Impeller 渲染开关，便于在不同 OHOS Flutter 分支间保持行为可见。

## 插件适配检查

Resonance 的核心 Dart 逻辑可以在 OHOS 平台运行，但下列依赖属于平台插件，打包时需要确认 OpenHarmony 适配版本是否可用：

- `path_provider`：本地 JSON 持久化依赖应用文档目录。
- `url_launcher`：文章外链和仓库链接打开依赖系统跳转能力。
- `file_selector`：头像选择依赖平台文件选择器。
- `flutter_local_notifications`：当前 Dart 逻辑不会在 OHOS 上启用通知，但如果未来要启用，需要使用 OHOS 适配插件并补权限与 ArkTS 注册。
- `window_manager`、`tray_manager`、`workmanager`：当前代码只在 Windows、Linux、Android 等平台启用对应能力，OHOS 上应保持跳过。

如果 `flutter pub get` 后 `ohos/entry/oh-package.json5` 没有出现某个插件的 HAR 依赖，优先查找 OpenHarmony SIG 或 TPC 的适配版插件，再用 `dependency_overrides` 做 OHOS 构建专用覆盖。

## 构建命令

在已切换到 OpenHarmony 适配版 Flutter SDK 的环境中执行：

```bash
flutter pub get
flutter build hap --release --target-platform ohos-arm64
```

如需保留应用内版本号显示，可追加：

```bash
flutter build hap --release --target-platform ohos-arm64 --dart-define=APP_VERSION=0.16.0+29
```

常见 HAP 产物路径：

```text
ohos/entry/build/default/outputs/default/entry-default-signed.hap
```

## 签名说明

当前 `ohos/build-profile.json5` 只保留默认签名占位，不提交证书、Profile 或密钥。发布前请在 DevEco Studio 的 Signing Configs 中配置正式签名，或在 CI 中注入签名材料后再执行构建。

## 调试签名与真机安装

HAP 安装到 HarmonyOS 真机前必须带签名。开发阶段建议先使用 DevEco Studio 自动签名，流程更短，也不需要把证书文件提交到仓库。

### 方式一：DevEco Studio 自动签名

1. 用 DevEco Studio 打开仓库里的 `ohos/` 目录。
2. 等待工程同步完成。如果提示缺少 `har/flutter.har` 或插件 HAR，先在 OpenHarmony Flutter SDK 环境执行 `flutter pub get`，让工具生成 OHOS 依赖。
3. 打开 `File > Project Structure > Project > Signing Configs`。
4. 选择 `default` 签名配置，勾选 `Automatically generate signature`。如果界面有 `Support HarmonyOS`，也一并勾选。
5. 登录华为开发者账号，确认后让 DevEco Studio 自动生成调试证书和 Profile。
6. 连接手机，在 DevEco Studio 顶部选择设备，点击 Run。IDE 会构建、签名并安装到设备。

这个方式适合日常调试。生成出来的签名信息通常会写入 `ohos/build-profile.json5` 或 DevEco 的本地配置；涉及私钥、证书、Profile 的文件不要提交。

### 方式二：手动签名

手动签名适合团队协作、离线构建、发布构建或自动签名失败的情况。

1. 在 DevEco Studio 或 AppGallery Connect 里生成密钥和证书请求文件。
2. 在 AppGallery Connect 创建 HarmonyOS 应用，包名保持为 `work.czzzz.reader`。
3. 申请或下载签名材料：
   - `.p12`：私钥文件。
   - `.cer`：数字证书。
   - `.p7b`：Provisioning Profile，调试 Profile 需要包含测试设备 UDID。
4. 回到 `File > Project Structure > Project > Signing Configs`，取消自动签名。
5. 给 `default` 配置填入 `.p12`、`.cer`、`.p7b` 和密钥密码。
6. 确认 `ohos/build-profile.json5` 的 product 仍指向 `"signingConfig": "default"`。

手动签名时，bundle name、证书、Profile、设备 UDID 必须互相匹配。任意一个不匹配，都可能出现安装失败或签名校验失败。

## 真机安装方式

### 使用 DevEco Studio 安装

这是最省事的安装方式：

1. 手机开启开发者模式。
2. 开启 USB 调试；如果系统提供“允许通过 USB 安装”或类似开关，也需要打开。
3. USB 连接电脑，手机弹窗里允许调试。
4. DevEco Studio 识别到设备后，点击 Run。

### 使用 hdc 命令安装

如果已经拿到了签名后的 HAP，可以用 hdc 安装：

```bash
hdc list targets
hdc install -r path/to/entry-default-signed.hap
```

如果直接安装失败，也可以先推送到设备，再用 Bundle Manager 安装：

```bash
hdc file send path/to/entry-default-signed.hap /data/local/tmp/
hdc shell bm install -r -p /data/local/tmp/entry-default-signed.hap
```

卸载当前应用：

```bash
hdc uninstall work.czzzz.reader
```

常见签名或安装问题：

- 找不到设备：先执行 `hdc list targets`，检查手机是否允许 USB 调试。
- 签名不匹配：确认 `work.czzzz.reader` 与 AppGallery Connect / Profile 中的包名一致。
- 设备不在 Profile 中：调试签名的 `.p7b` 需要包含当前手机 UDID。
- 覆盖安装失败：先用 `hdc uninstall work.czzzz.reader` 卸载旧包，再安装。
- HAP 未签名：回到 DevEco Studio Signing Configs，确认 `default` 签名已配置并重新构建。
