/// 用于同步扫描的设备信息
/// 
/// 该类用于向原生端传递已绑定设备的信息，
/// 以便扫描这些设备的同步状态
class OmronSyncDevice {
  /// 设备类型（如：BLOOD_PRESSURE）
  final String deviceType;
  
  /// 设备序列号
  final String deviceSerialNum;
  
  /// 设备ID（可选）
  final String? deviceId;
  
  /// 设备名称（可选，Android同步数据时需要）
  final String? deviceName;
  
  const OmronSyncDevice({
    required this.deviceType,
    required this.deviceSerialNum,
    this.deviceId,
    this.deviceName,
  });
  
  /// 从Map创建对象
  factory OmronSyncDevice.fromMap(Map<String, dynamic> map) {
    return OmronSyncDevice(
      deviceType: map['deviceType'] as String,
      deviceSerialNum: map['deviceSerialNum'] as String,
      deviceId: map['deviceId'] as String?,
      deviceName: map['deviceName'] as String?,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'deviceType': deviceType,
      'deviceSerialNum': deviceSerialNum,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
    };
  }
  
  /// 获取用于同步数据的标识符
  /// - Android: "deviceName;macAddress"
  /// - iOS: deviceSerialNum
  String getSyncIdentifier() {
    if (deviceName != null && deviceName!.isNotEmpty) {
      // Android格式：设备名称;MAC地址
      return '$deviceName;$deviceSerialNum';
    }
    // iOS格式：直接使用deviceSerialNum
    return deviceSerialNum;
  }
  
  @override
  String toString() {
    return 'OmronSyncDevice(deviceType: $deviceType, deviceSerialNum: $deviceSerialNum, deviceId: $deviceId, deviceName: $deviceName)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OmronSyncDevice &&
        other.deviceType == deviceType &&
        other.deviceSerialNum == deviceSerialNum &&
        other.deviceId == deviceId &&
        other.deviceName == deviceName;
  }
  
  @override
  int get hashCode {
    return deviceType.hashCode ^
        deviceSerialNum.hashCode ^
        (deviceId?.hashCode ?? 0) ^
        (deviceName?.hashCode ?? 0);
  }
}

