/// 设计 token：集中管理间距与圆角，避免散落各处的 magic number。
///
/// 渐进式采用——新写或改动的 UI 一律引用这里的常量，旧代码逐步迁移。
class AppDimens {
  AppDimens._();

  // 间距阶梯
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  // 圆角阶梯
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusPill = 999;

  // 移动端最小触控目标（无障碍）
  static const double minTouchTarget = 40;
}
