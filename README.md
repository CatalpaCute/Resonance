# 回声 Resonance

一个 Flutter RSS 阅读器。“回声 Resonance”名字受启发自[林忆莲的巡演](https://zh.wikipedia.org/wiki/%E6%9E%97%E6%86%B6%E8%93%AE%E8%BF%B4%E9%9F%BF_Resonance_2025_%E5%B7%A1%E8%BF%B4%E6%BC%94%E5%94%B1%E6%9C%83)。

## 当前状态
- 已完成桌面端与移动端共用的应用壳层、导航、文章列表、阅读详情和设置页。
- 已支持手动添加、编辑、删除订阅源，拉取并解析 RSS / Atom，本地保存阅读状态。

## 仓库编译测试方式
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
