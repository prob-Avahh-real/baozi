import 'dart:convert';

import 'package:flutter/services.dart';

/// 字体分块描述（来自 chunk_map.json）
class FontChunk {
  final String file;
  final int size;
  final String unicode;
  final String family;
  final List<UnicodeRange> ranges;

  FontChunk({
    required this.file,
    required this.size,
    required this.unicode,
    required this.family,
    required this.ranges,
  });

  factory FontChunk.fromJson(Map<String, dynamic> json) {
    final ranges = _parseRanges(json['unicode'] as String);
    return FontChunk(
      file: json['file'] as String,
      size: json['size'] as int,
      unicode: json['unicode'] as String,
      family: json['family'] as String,
      ranges: ranges,
    );
  }

  /// 检查此分块是否包含指定字符
  bool containsChar(int codePoint) {
    for (final range in ranges) {
      if (codePoint >= range.start && codePoint <= range.end) {
        return true;
      }
    }
    return false;
  }
}

class UnicodeRange {
  final int start;
  final int end;
  const UnicodeRange(this.start, this.end);
}

/// 解析 CSS unicode-range，如 "U+4E00-9FFF, U+3400-4DBF"
List<UnicodeRange> _parseRanges(String unicode) {
  final ranges = <UnicodeRange>[];
  // 移除 U+ 前缀并拆分
  final parts = unicode.replaceAll('U+', '').split(',').map((s) => s.trim());
  for (final part in parts) {
    if (part.contains('-')) {
      final split = part.split('-');
      ranges.add(UnicodeRange(
        int.parse(split[0], radix: 16),
        int.parse(split[1], radix: 16),
      ));
    } else if (part.isNotEmpty) {
      final cp = int.parse(part, radix: 16);
      ranges.add(UnicodeRange(cp, cp));
    }
  }
  return ranges;
}

/// 动态字体加载管理器
///
/// 策略：
/// 1. 启动时加载 chunk_map.json，构建字符→分块索引
/// 2. 「核心分块」立即加载（ASCII + 常用标点）
/// 3. 中文文本渲染时按需加载对应分块
///
/// 用法：
/// ```dart
/// await FontManager.instance.init();
/// await FontManager.instance.ensureLoaded('欢迎使用宝子');
/// ```
class FontManager {
  FontManager._();

  static final FontManager instance = FontManager._();

  final List<FontChunk> _chunks = [];
  final Set<String> _loadedChunks = {};
  final Set<int> _loadedCodepoints = {};
  bool _initialized = false;
  bool _fontFamilyLoaded = false;

  bool get isReady => _fontFamilyLoaded;

  /// 初始化：加载分块索引并预载核心字符
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. 加载分块索引
    final jsonStr =
        await rootBundle.loadString('assets/fonts/chunks/chunk_map.json');
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    for (final entry in map.entries) {
      final list = entry.value as List<dynamic>;
      for (final item in list) {
        _chunks.add(FontChunk.fromJson(item as Map<String, dynamic>));
      }
    }

    // 2. 预载核心分块（ASCII 区块：Latin、数字、常用符号）
    await _loadCoreChunks();
  }

  /// 预载核心字符分块（ASCII + 常用标点，覆盖 U+0020-U+02FF）
  Future<void> _loadCoreChunks() async {
    final loader = _FontLoaderHelper('NotoSansSC');
    final coreChunks = _chunks.where((c) {
      // 分块包含基本 Latin / 标点字符即视为核心块
      return c.ranges.any((r) => r.start < 0x3000);
    }).toList();

    for (final chunk in coreChunks) {
      await loader.addChunk(chunk);
      _loadedChunks.add(chunk.file);
      for (final range in chunk.ranges) {
        for (int cp = range.start; cp <= range.end; cp++) {
          _loadedCodepoints.add(cp);
        }
      }
    }

    await loader.commit();
    _fontFamilyLoaded = true;
  }

  /// 确保指定文本的所有字符对应的分块已加载
  Future<void> ensureLoaded(String text) async {
    if (!_initialized) await init();

    final neededChunks = <FontChunk>{};
    final missingCodepoints = <int>{};

    for (final rune in text.runes) {
      if (_loadedCodepoints.contains(rune)) continue;
      missingCodepoints.add(rune);

      for (final chunk in _chunks) {
        if (_loadedChunks.contains(chunk.file)) continue;
        if (chunk.containsChar(rune)) {
          neededChunks.add(chunk);
          break; // 一个字符只会在一个分块中
        }
      }
    }

    if (neededChunks.isEmpty) return;

    final loader = _FontLoaderHelper('NotoSansSC');
    for (final chunk in neededChunks) {
      await loader.addChunk(chunk);
      _loadedChunks.add(chunk.file);
    }

    await loader.commit();

    // 标记这些字符已加载
    for (final chunk in neededChunks) {
      for (final range in chunk.ranges) {
        for (int cp = range.start; cp <= range.end; cp++) {
          _loadedCodepoints.add(cp);
        }
      }
    }
  }

  /// 预载所有分块（用于需要保证全字符集可用的场景）
  Future<void> preloadAll() async {
    final unloaded = _chunks.where((c) => !_loadedChunks.contains(c.file));
    if (unloaded.isEmpty) return;

    final loader = _FontLoaderHelper('NotoSansSC');
    for (final chunk in unloaded) {
      await loader.addChunk(chunk);
      _loadedChunks.add(chunk.file);
    }
    await loader.commit();
    _fontFamilyLoaded = true;
  }
}

/// 辅助类：处理 FontLoader 的字节添加与提交
class _FontLoaderHelper {
  final String family;
  final List<Future<ByteData>> _futures = [];

  _FontLoaderHelper(this.family);

  Future<void> addChunk(FontChunk chunk) async {
    final data = await rootBundle.load('assets/fonts/chunks/${chunk.file}');
    _futures.add(Future.value(data));
  }

  Future<void> commit() async {
    if (_futures.isEmpty) return;

    // 创建新的 FontLoader 实例来加载这批分块
    // 注意：同一个 family 的多个 FontLoader 会合并字形
    final fontLoader = FontLoader(family);
    for (final future in _futures) {
      fontLoader.addFont(future);
    }
    await fontLoader.load();
    _futures.clear();
  }
}
