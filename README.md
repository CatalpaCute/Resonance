# Resonance

<p align="center">
  <strong>回声 · Resonance</strong><br/>
  A local-first RSS reader built with Flutter for desktop and mobile.
</p>

<p align="center">
  <a href="#中文">中文</a> · <a href="#english">English</a>
</p>

<p align="center">
  <a href="https://github.com/CatalpaCute/Resonance/releases"><img src="https://img.shields.io/github/v/release/CatalpaCute/Resonance?display_name=tag" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.4%2B-02569B?logo=flutter&logoColor=white" alt="Flutter 3.4+" />
  <img src="https://img.shields.io/badge/Dart-3.4%2B-0175C2?logo=dart&logoColor=white" alt="Dart 3.4+" />
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20Windows-6C757D" alt="Platforms" />
</p>

---

## 中文

### 项目简介

**Resonance（回声）** 是一个使用 Flutter 构建的 **local-first RSS 阅读器**。  
它更偏向一个轻量、安静、可持续迭代的个人阅读工作台：管理订阅、拉取内容、筛选未读、沉浸阅读，并把阅读状态与设置保存在本地，而不是依赖账号系统或后端服务。

当前项目已经完成 RSS / Atom 订阅解析、本地 JSON 持久化、桌面三栏阅读工作区、移动端适配、文章富文本渲染与文本模式、主题与语言切换等核心能力，已经具备比较完整的阅读闭环。

### 项目定位

Resonance 不是“什么都做”的内容平台，而是一个偏个人效率和阅读体验的 RSS 阅读器。  
它的重点是：

- 用 Flutter 同时覆盖桌面端与移动端
- 保持 local-first，减少外部依赖
- 用更清晰的界面组织订阅、文章列表和阅读详情
- 让项目可以在现有基础上持续扩展，例如同步、通知、引导、字体调节等能力

### Features

#### 已实现

- 手动添加、编辑、删除、刷新、重排订阅源
- 支持 RSS / Atom 解析
- 本地 JSON 持久化保存订阅、文章、阅读状态与设置
- 文章按发布时间倒序展示
- 已读 / 未读、收藏、稍后读
- 未读筛选
- 桌面端三栏工作区：订阅源、文章列表、阅读面板
- 移动端适配，支持抽屉 / rail / 自适应侧栏模式
- 文章支持富文本阅读与纯文本阅读模式
- 支持换行、图片等媒体适配
- 安卓状态栏沉浸
- 安卓包名更换
- 订阅源页部分和添加订阅合并
- 支持主题切换，并已提供当前主题方案
- 支持界面语言切换：简体中文 / 繁体中文 / English
- Windows 桌面端窗口样式适配

#### 计划中

- [ ] 订阅源内选择是否通知
- [ ] 订阅源文章页选择
- [ ] 设置页面独立
- [ ] 添加更多主题，并进一步优化 UI
- [ ] WebDAV 同步
- [ ] 自动更新订阅，提醒
- [ ] 字体大小 px 调节
- [ ] 新手引导 + 动画
- [ ] OPML 导入 / 导出
- [ ] 更完整的全文内容提取
- [ ] 文章搜索

### 技术栈

- **Flutter** + **Dart**
- `http`
- `xml`
- `flutter_widget_from_html_core`
- `path_provider`
- `url_launcher`
- `window_manager`

### 项目结构

```text
lib/
├─ main.dart                  # 应用入口
└─ src/
   ├─ localization/           # 语言模式与文案
   ├─ models/                 # 文章、订阅源、路由、设置
   ├─ services/               # JSON 持久化、RSS / Atom 解析
   ├─ state/                  # ReaderController 状态管理
   ├─ theme/                  # 主题与调色板
   └─ ui/                     # 应用壳层、页面、组件
```

### 运行方式

```bash
flutter pub get
flutter run
```

### 常用检查

```bash
flutter analyze
flutter test
```

### 构建

#### Android

```bash
flutter build apk --release
```

#### Windows

```bash
flutter build windows --release
```

### 发布说明

仓库当前已经整理了基于 GitHub Release 的发布流程。  
正式发布时可自动构建：

- Android Release APK
- Windows Release ZIP

---

## English

### Overview

**Resonance** is a **local-first RSS reader** built with Flutter.  
It is designed as a lightweight personal reading workspace: manage subscriptions, fetch articles, filter unread items, read in a focused interface, and keep reading state and preferences locally instead of relying on an account system or backend service.

At its current stage, the project already includes RSS / Atom parsing, local JSON persistence, a desktop three-pane reading workspace, mobile adaptation, rich article rendering with text-only fallback, and theme / language switching. In other words, the core reading loop is already in place.

### Positioning

Resonance is not trying to be an all-in-one content platform.  
It is a reading-focused product with a few clear priorities:

- one Flutter codebase for desktop and mobile
- a local-first foundation with minimal external dependency
- a cleaner structure for subscriptions, article lists, and reading detail
- room for future expansion such as sync, notifications, onboarding, and typography controls

### Features

#### Implemented

- Manual feed management: add, edit, delete, refresh, and reorder sources
- RSS / Atom support
- Local JSON persistence for feeds, articles, reading state, and settings
- Reverse chronological article list
- Read / unread, starred, and read-later actions
- Unread-only filtering
- Desktop three-pane workspace: sources, article list, and reader panel
- Mobile adaptation with drawer / rail / adaptive sidebar modes
- Rich article rendering with a text-only reading mode
- Better media adaptation, including line breaks and images
- Immersive Android status bar
- Updated Android package name
- Merged subscription management with the add-subscription flow
- Theme switching with the current built-in theme set
- Interface language switching: Simplified Chinese / Traditional Chinese / English
- Windows desktop window styling support

#### Planned

- [ ] Per-source notification toggle
- [ ] Source-specific article page selection
- [ ] A more independent settings page
- [ ] More themes and further UI refinement
- [ ] WebDAV sync
- [ ] Automatic subscription refresh and reminders
- [ ] Adjustable font size in px
- [ ] Onboarding flow and animations
- [ ] OPML import / export
- [ ] Better full-content extraction
- [ ] Article search

### Tech stack

- **Flutter** + **Dart**
- `http`
- `xml`
- `flutter_widget_from_html_core`
- `path_provider`
- `url_launcher`
- `window_manager`

### Project structure

```text
lib/
├─ main.dart                  # app entry
└─ src/
   ├─ localization/           # language mode and strings
   ├─ models/                 # article, feed source, route, settings
   ├─ services/               # JSON persistence and RSS / Atom parsing
   ├─ state/                  # ReaderController state management
   ├─ theme/                  # themes and palette
   └─ ui/                     # app shell, views, widgets
```

### Getting started

```bash
flutter pub get
flutter run
```

### Useful checks

```bash
flutter analyze
flutter test
```

### Build

#### Android

```bash
flutter build apk --release
```

#### Windows

```bash
flutter build windows --release
```

### Release notes

The repository is already structured around a GitHub Release based build flow.  
For formal releases, it can build:

- Android Release APK
- Windows Release ZIP
