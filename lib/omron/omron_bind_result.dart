import 'omron_status.dart';
import 'omron_device_info.dart';
import 'omron_bp_data.dart';

/// OMRON 设备绑定结果
/// 封装设备绑定后返回的所有信息
class OmronBindResult {
  /// 绑定状态
  final OmronStatus status;
  
  /// 设备类型
  final String deviceType;
  
  /// 设备序列号
  final String deviceSerialNum;
  
  /// 设备ID
  final String? deviceId;
  
  /// 设备信息
  final OmronDeviceInfo? deviceInfo;
  
  /// 血压测量数据列表
  final List<OmronBpData>? bpDataList;
  
  /// 详细信息
  final String message;
  
  /// 构造函数
  OmronBindResult({
    required this.status,
    required this.deviceType,
    required this.deviceSerialNum,
    this.deviceId,
    this.deviceInfo,
    this.bpDataList,
    String? message,
  }) : message = message ?? status.message;
  
  /// 从Map创建实例（原生平台数据转换）
  factory OmronBindResult.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'unknown';
    final status = OmronStatus.fromString(statusStr);
    
    // 解析设备信息
    OmronDeviceInfo? deviceInfo;
    if (map['deviceInfo'] != null) {
      deviceInfo = OmronDeviceInfo.fromMap(
        Map<String, dynamic>.from(map['deviceInfo'] as Map)
      );
    }
    
    // 解析血压数据列表
    List<OmronBpData>? bpDataList;
    if (map['bpDataList'] != null) {
      final dataList = map['bpDataList'] as List;
      bpDataList = dataList
          .map((item) => OmronBpData.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    
    return OmronBindResult(
      status: status,
      deviceType: map['deviceType'] as String? ?? '',
      deviceSerialNum: map['deviceSerialNum'] as String? ?? '',
      deviceId: map['deviceId'] as String?,
      deviceInfo: deviceInfo,
      bpDataList: bpDataList,
      message: map['message'] as String?,
    );
  }
  
  /// 转换为Map（用于序列化）
  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'deviceType': deviceType,
      'deviceSerialNum': deviceSerialNum,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceInfo != null) 'deviceInfo': deviceInfo!.toMap(),
      if (bpDataList != null) 
        'bpDataList': bpDataList!.map((data) => data.toMap()).toList(),
      'message': message,
    };
  }
  
  /// 是否绑定成功
  bool get isSuccess => status.isSuccess;
  
  /// 获取数据数量
  int get dataCount => bpDataList?.length ?? 0;
  
  @override
  String toString() {
    return 'OmronBindResult(status: $status, device: $deviceType, serialNum: $deviceSerialNum, dataCount: $dataCount)';
  }
}

