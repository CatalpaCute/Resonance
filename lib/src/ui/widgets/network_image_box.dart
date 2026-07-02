import 'package:flutter/material.dart';

import 'motion.dart';

/// 统一的网络小图组件（favicon / 头像）。
///
/// 设计意图：
/// - 零依赖。仅用 Flutter 自带 `Image.network` + 全局 `ImageCache`（容量在
///   `main.dart` 调大），避免引入 cached_network_image 传递带来的 sqflite 等
///   原生依赖，规避 OHOS 适配风险与包体膨胀。
/// - `decodeWidth` 按显示尺寸降采样解码，favicon/头像只占几十像素却常是大图，
///   降采样能显著省内存、减少缓存驱逐。
/// - 首帧渐进淡入，避免列表滚动时图片"啪"地出现。
/// - 加载失败或 `url` 为空时回退到占位图标，与各调用点既有行为一致。
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    required this.placeholderIcon,
    required this.iconColor,
    required this.iconSize,
    this.fit = BoxFit.cover,
    this.decodeWidth,
  });

  final String? url;
  final IconData placeholderIcon;
  final Color iconColor;
  final double iconSize;
  final BoxFit fit;

  /// 期望显示宽度（逻辑像素）。传入后按设备像素比换算为物理像素做降采样解码。
  final double? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final String? source = url;
    if (source == null || source.isEmpty) {
      return _placeholder();
    }

    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int? cacheWidth = decodeWidth == null
        ? null
        : (decodeWidth! * dpr).round().clamp(1, 4096);

    return Image.network(
      source,
      fit: fit,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _placeholder(),
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: kFluidMotionFastDuration,
          curve: kFluidMotionCurve,
          child: child,
        );
      },
    );
  }

  Widget _placeholder() {
    return Icon(
      placeholderIcon,
      size: iconSize,
      color: iconColor,
    );
  }
}
