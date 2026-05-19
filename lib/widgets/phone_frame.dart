import 'package:flutter/material.dart';

/// PhoneFrame 的布局信息：用于把“设计稿像素坐标”映射到屏幕 global 坐标
class PhoneFrameLayout {
  final Rect frameRectGlobal; // PhoneFrame 容器 global rect
  final Rect imageRectGlobal; // phone_frame.png 实际绘制区域 global rect（fit: contain 后的区域）
  final double scale;         // 设计稿 -> 实际显示的缩放
  final EdgeInsets screenPad; // 内屏 pad（已乘 scale）

  const PhoneFrameLayout({
    required this.frameRectGlobal,
    required this.imageRectGlobal,
    required this.scale,
    required this.screenPad,
  });

  /// 把设计稿坐标（以 designSize 为坐标系）转换到屏幕 global 坐标
  Offset designToGlobal(Offset designPx) {
    final localInImage = Offset(designPx.dx * scale, designPx.dy * scale);
    return imageRectGlobal.topLeft + localInImage;
  }

  /// 设计稿 Rect -> global Rect（比如你想要整块区域）
  Rect designRectToGlobal(Rect designRect) {
    final tl = designToGlobal(designRect.topLeft);
    final br = designToGlobal(designRect.bottomRight);
    return Rect.fromPoints(tl, br);
  }
}

class PhoneFrame extends StatelessWidget {
  final Widget child;

  /// 你的手机框 PNG 的“设计稿尺寸”（按图片真实像素填）
  final Size designSize;

  /// “设计稿尺寸”下的内屏边距（用设计稿像素填）
  final EdgeInsets designScreenPadding;

  /// 控制手机整体宽高比（最好和 PNG 宽高一致：w/h）
  final double aspectRatio;

  /// 内屏圆角（会随 scale 缩放）
  final double designInnerRadius;

  /// ✅ 新增：把布局信息（含 imageRectGlobal/scale）回传给外部
  final void Function(PhoneFrameLayout layout)? onLayout;

  const PhoneFrame({
    super.key,
    required this.child,
    required this.designSize,
    required this.designScreenPadding,
    required this.aspectRatio,
    this.designInnerRadius = 18,
    this.onLayout,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          // 以设计稿为基准做等比缩放（避免拉伸导致 padding 不准）
          final sx = w / designSize.width;
          final sy = h / designSize.height;
          final s = sx < sy ? sx : sy;

          final pad = EdgeInsets.fromLTRB(
            designScreenPadding.left * s,
            designScreenPadding.top * s,
            designScreenPadding.right * s,
            designScreenPadding.bottom * s,
          );

          final innerRadius = designInnerRadius * s;

          // ✅ 关键：BoxFit.contain 下，图片实际绘制区域会“居中 + 留边”
          final imgW = designSize.width * s;
          final imgH = designSize.height * s;
          final imgLocalRect = Rect.fromLTWH(
            (w - imgW) / 2,
            (h - imgH) / 2,
            imgW,
            imgH,
          );

          // ✅ 把布局信息回传（global rect）
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (onLayout == null) return;
            final ro = ctx.findRenderObject();
            if (ro is! RenderBox || !ro.hasSize) return;
            //debugPrint('PhoneFrame onLayout fired, size=${ro.size}, scale=$s');

            final topLeft = ro.localToGlobal(Offset.zero);
            final frameRectGlobal = topLeft & ro.size;
            final imageRectGlobal = imgLocalRect.shift(topLeft);

            onLayout!(
              PhoneFrameLayout(
                frameRectGlobal: frameRectGlobal,
                imageRectGlobal: imageRectGlobal,
                scale: s,
                screenPad: pad,
              ),
            );
          });

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1) 内屏内容（裁剪在内屏区域）
              Positioned.fill(
                child: Padding(
                  padding: pad,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(innerRadius),
                    child: Material(
                      color: Colors.white,
                      child: Builder(
                        builder: (innerCtx) {
                          final mq = MediaQuery.of(innerCtx);
                          return MediaQuery(
                            data: mq.copyWith(
                              padding: EdgeInsets.zero,
                              viewPadding: EdgeInsets.zero,
                            ),
                            child: child,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 2) 手机框 PNG（盖在最上层）
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Image.asset(
                    'assets/ui/phone_frame.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}