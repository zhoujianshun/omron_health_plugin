import 'package:flutter/foundation.dart';

/// OMRON健康插件内部日志工具类
/// 在开发模式下输出日志,生产模式下不输出
class OmronLogger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  static void error(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ $prefix$message');
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $prefix$message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $prefix$message');
    }
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔵 $prefix$message');
    }
  }

  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('✅ $prefix$message');
    }
  }
}

