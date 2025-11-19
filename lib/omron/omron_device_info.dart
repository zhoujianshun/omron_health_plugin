/// OMRON 设备信息
/// 封装设备的配置和状态信息
class OmronDeviceInfo {
  /// 设备型号名称
  final String? modelName;
  
  /// 序列号
  final String? serialNumber;
  
  /// 硬件版本
  final String? hardwareVersion;
  
  /// 软件版本
  final String? softwareVersion;
  
  /// 固件版本
  final String? firmwareVersion;
  
  /// 电池电量
  final int? batteryLevel;
  
  /// 供电模式
  final String? powerSupplyMode;
  
  /// 制造商名称
  final String? manufacturerName;
  
  /// 型号编号
  final String? modelNumber;
  
  /// 系统ID
  final String? systemID;
  
  /// 构造函数
  OmronDeviceInfo({
    this.modelName,
    this.serialNumber,
    this.hardwareVersion,
    this.softwareVersion,
    this.firmwareVersion,
    this.batteryLevel,
    this.powerSupplyMode,
    this.manufacturerName,
    this.modelNumber,
    this.systemID,
  });
  
  /// 从Map创建实例（原生平台数据转换）
  factory OmronDeviceInfo.fromMap(Map<String, dynamic> map) {
    return OmronDeviceInfo(
      modelName: map['modelName'] as String?,
      serialNumber: map['serialNumber'] as String?,
      hardwareVersion: map['hardwareVersion'] as String?,
      softwareVersion: map['softwareVersion'] as String?,
      firmwareVersion: map['firmwareVersion'] as String?,
      batteryLevel: map['batteryLevel'] as int?,
      powerSupplyMode: map['powerSupplyMode'] as String?,
      manufacturerName: map['manufacturerName'] as String?,
      modelNumber: map['modelNumber'] as String?,
      systemID: map['systemID'] as String?,
    );
  }
  
  /// 转换为Map（用于序列化）
  Map<String, dynamic> toMap() {
    return {
      if (modelName != null) 'modelName': modelName,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (hardwareVersion != null) 'hardwareVersion': hardwareVersion,
      if (softwareVersion != null) 'softwareVersion': softwareVersion,
      if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (powerSupplyMode != null) 'powerSupplyMode': powerSupplyMode,
      if (manufacturerName != null) 'manufacturerName': manufacturerName,
      if (modelNumber != null) 'modelNumber': modelNumber,
      if (systemID != null) 'systemID': systemID,
    };
  }
  
  /// 获取电池电量描述
  String get batteryLevelDescription {
    if (batteryLevel == null) return '未知';
    if (batteryLevel! >= 80) return '充足';
    if (batteryLevel! >= 50) return '良好';
    if (batteryLevel! >= 20) return '偏低';
    return '电量不足';
  }
  
  /// 获取设备显示名称
  String get displayName {
    return modelName ?? modelNumber ?? manufacturerName ?? '未知设备';
  }
  
  @override
  String toString() {
    return 'OmronDeviceInfo(model: $modelName, serialNumber: $serialNumber, battery: $batteryLevel%)';
  }
}

