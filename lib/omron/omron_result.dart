import 'omron_status.dart';

/// OMRON SDK 初始化结果
class OmronInitResult {
  /// 初始化状态
  final OmronStatus status;
  
  /// 详细信息
  final String message;
  
  /// 构造函数
  OmronInitResult({
    required this.status,
    required this.message,
  });
  
  /// 从Map创建实例
  factory OmronInitResult.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'unknown';
    final status = OmronStatus.fromString(statusStr);
    final message = map['message'] as String? ?? status.message;
    
    return OmronInitResult(
      status: status,
      message: message,
    );
  }
  
  /// 是否初始化成功
  bool get isSuccess => status.isSuccess;
  
  @override
  String toString() {
    return 'OmronInitResult(status: $status, message: $message)';
  }
}

