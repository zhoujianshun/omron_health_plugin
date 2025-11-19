/// Omron扫描事件类型
enum OmronScanEventType {
  /// 扫描到设备
  deviceFound,
  
  /// 扫描周期结束
  scanFinished,
  
  /// 扫描失败
  scanError,
}

/// Omron扫描事件
/// 用于区分设备数据和扫描状态事件
class OmronScanEvent<T> {
  /// 事件类型
  final OmronScanEventType type;
  
  /// 扫描到的设备（仅当type为deviceFound时有值）
  final T? device;
  
  /// 消息（用于scanFinished和scanError）
  final String? message;
  
  /// 错误信息（仅当type为scanError时有值）
  final dynamic error;
  
  const OmronScanEvent({
    required this.type,
    this.device,
    this.message,
    this.error,
  });
  
  /// 创建设备发现事件
  factory OmronScanEvent.deviceFound(dynamic device) {
    return OmronScanEvent(
      type: OmronScanEventType.deviceFound,
      device: device,
    );
  }
  
  /// 创建扫描完成事件
  factory OmronScanEvent.scanFinished({String? message}) {
    return OmronScanEvent(
      type: OmronScanEventType.scanFinished,
      message: message ?? '扫描周期结束',
    );
  }
  
  /// 创建扫描错误事件
  factory OmronScanEvent.scanError({String? message, dynamic error}) {
    return OmronScanEvent(
      type: OmronScanEventType.scanError,
      message: message ?? '扫描失败',
      error: error,
    );
  }
  
  /// 是否是设备发现事件
  bool get isDeviceFound => type == OmronScanEventType.deviceFound;
  
  /// 是否是扫描完成事件
  bool get isScanFinished => type == OmronScanEventType.scanFinished;
  
  /// 是否是扫描错误事件
  bool get isScanError => type == OmronScanEventType.scanError;
  
  @override
  String toString() {
    switch (type) {
      case OmronScanEventType.deviceFound:
        return 'OmronScanEvent.deviceFound(device: $device)';
      case OmronScanEventType.scanFinished:
        return 'OmronScanEvent.scanFinished(message: $message)';
      case OmronScanEventType.scanError:
        return 'OmronScanEvent.scanError(message: $message, error: $error)';
    }
  }
}

