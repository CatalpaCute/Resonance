# RssTool

一个本地优先的 RSS 阅读器首版。

## 当前状态

- 已落地 Flutter 源码层：主题、导航壳、RSS 拉取与解析、本地 JSON 持久化、文章阅读流。
- 当前机器未安装 Flutter SDK，因此本次没有生成 Android/iOS/Windows/macOS/Linux 的平台壳目录，也无法在本机运行 `flutter test` 或 `flutter analyze`。

## 初始化方式

在安装 Flutter SDK 后，在项目根目录执行：

```bash
flutter create .
flutter pub get
flutter run
```

如果只想补平台目录，不覆盖已有 `lib/` 源码，可以执行：

```bash
flutter create --platforms=android,ios,windows,linux,macos .
```

## 已实现范围

- 手动添加、编辑、删除订阅源
- 拉取并解析 RSS / Atom
- 按发布时间倒序展示文章
- 已读 / 未读、收藏、稍后读
- 本地 JSON 持久化
- 可配置启动页、主题、移动端侧栏模式、桌面端侧栏折叠
- 三栏桌面工作区

## 后续建议

- 接 WebDAV 同步层
- 引入 HTML 正文渲染
- 增加 OPML 导入导出
- 增加全文抓取和规则过滤
