# 回声 Resonance

一个本地优先的 Flutter RSS 阅读器。

## 当前状态
- 已完成桌面端与移动端共用的应用壳层、导航、文章列表、阅读详情和设置页。
- 已支持手动添加、编辑、删除订阅源，拉取并解析 RSS / Atom，本地保存阅读状态。
- 已补上基础编码自适应：优先识别 BOM、HTTP `charset`、XML 声明中的 `encoding`，避免服务端漏写 `charset` 时出现乱码。
- 已支持界面语言切换：跟随系统、中文(中国)、中文(港台)、English。

## 运行方式
在项目根目录执行：

```bash
flutter pub get
flutter run
```

常用检查命令：

```bash
flutter analyze
flutter test
```

## 已实现范围
- 手动添加、编辑、删除订阅源
- 拉取并解析 RSS / Atom
- 按发布时间倒序展示文章
- 已读 / 未读、收藏、稍后读
- 本地 JSON 持久化
- 可配置启动页、主题、移动端侧栏模式、桌面端侧栏折叠
- 桌面三栏工作区与移动端单主内容流

## 后续建议
- 接入 WebDAV 同步层
- 增加 HTML 正文提取
- 增加 OPML 导入导出
- 增加全文抓取和规则过滤
