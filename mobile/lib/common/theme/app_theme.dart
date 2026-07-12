import 'package:flutter/material.dart';

/// 宝子 App 主题配置
///
/// 字体策略：优先使用系统自带的简体中文字体（零额外加载）
/// - iOS/macOS → PingFang SC（苹方）
/// - Android   → Noto Sans SC / HarmonyOS Sans
/// - 兜底      → sans-serif
///
/// 如需自定义字体（如思源黑体分包），将字体放入 assets/fonts/，
/// 在 pubspec.yaml 中注册后，修改 fontFamily 为注册的名称即可。
class AppTheme {
  AppTheme._();

  /// 自定义简体中文字体 — Noto Sans SC (思源黑体)
  static const String _fontFamily = 'NotoSansSC';

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6366F1), // 靛蓝主色
        fontFamily: _fontFamily,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF818CF8),
        fontFamily: _fontFamily,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
