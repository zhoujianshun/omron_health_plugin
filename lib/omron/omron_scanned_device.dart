/// OMRON 扫描到的设备信息
/// 封装从原生平台返回的设备数据
class OmronScannedDevice {
  /// 设备类型（如："BLEPeripheral"）
  final String? deviceType;
  
  /// 设备名称
  final String deviceName;
  
  /// 设备ID
  final String? userIndex;
  
  /// 设备序列号
  final String deviceSerialNum;
  
  /// 信号强度（RSSI），仅Android返回
  final int? rssi;
  
  /// 设备分类（血压计、体脂仪等）
  final String? category;
  
  /// 扫描时间戳
  final DateTime scannedAt;
  
  /// 构造函数
  OmronScannedDevice({
    this.deviceType,
    required this.deviceName,
    this.userIndex,
    required this.deviceSerialNum,
    this.rssi,
    this.category,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();
  
  /// 从Map创建实例（原生平台数据转换）
  factory OmronScannedDevice.fromMap(Map<String, dynamic> map) {
    return OmronScannedDevice(
      deviceType: map['deviceType'] as String?,
      deviceName: map['deviceName'] as String? ?? '未知设备',
      userIndex: map['userIndex'] as String?,
      deviceSerialNum: map['deviceSerialNum'] as String? ?? '',
      rssi: map['rssi'] as int?,
      category: map['category'] as String?,
    );
  }
  
  /// 转换为Map（用于序列化）
  Map<String, dynamic> toMap() {
    return {
      'deviceType': deviceType,
      'deviceName': deviceName,
      'userIndex': userIndex,
      'deviceSerialNum': deviceSerialNum,
      'rssi': rssi,
      'category': category,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }
  
  /// 获取信号强度描述
  String get rssiDescription {
    if (rssi == null) return '未知';
    if (rssi! >= -50) return '极强';
    if (rssi! >= -60) return '强';
    if (rssi! >= -70) return '中等';
    if (rssi! >= -80) return '弱';
    return '极弱';
  }
  
  /// 获取显示用的完整设备信息
  String get displayInfo {
    final parts = <String>[];
    parts.add(deviceName);
    if (deviceSerialNum.isNotEmpty) {
      parts.add('序列号: $deviceSerialNum');
    }
    if (rssi != null) {
      parts.add('信号: $rssiDescription ($rssi dBm)');
    }
    return parts.join('\n');
  }
  
  @override
  String toString() {
    return 'OmronScannedDevice(name: $deviceName, serialNum: $deviceSerialNum, rssi: $rssi)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OmronScannedDevice &&
        other.deviceSerialNum == deviceSerialNum;
  }
  
  @override
  int get hashCode => deviceSerialNum.hashCode;
}

