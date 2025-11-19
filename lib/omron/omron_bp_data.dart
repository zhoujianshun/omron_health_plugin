/// OMRON 血压测量数据
/// 封装从血压计读取的测量数据
class OmronBpData {
  /// 收缩压 (mmHg)
  final int systolic;
  
  /// 舒张压 (mmHg)
  final int diastolic;
  
  /// 脉搏 (bpm)
  final int pulse;
  
  /// 心律不齐标志 (0: 正常; 1: 异常)
  final int arrhythmiaFlag;
  
  /// 身体移动标志 (0: 未移动; 1: 移动)
  final int bodyMovementFlag;
  
  /// 袖带佩戴标志 (0: 正常; 1: 异常)
  final int cuffWrapFlag;
  
  /// 测量用户 (0: 未设置; 1: 用户A; 2: 用户B)
  final int measureUser;
  
  /// 测量时间（时间戳，毫秒）
  final int measureTime;
  
  /// 房颤模式 (0: 不支持; 1: 支持)
  final int afibMode;
  
  /// 房颤标志 (0: 无房颤; 1: 有房颤)
  final int afibFlag;
  
  /// 设备类型
  final String? deviceType;
  
  /// 构造函数
  OmronBpData({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.arrhythmiaFlag,
    required this.bodyMovementFlag,
    required this.cuffWrapFlag,
    required this.measureUser,
    required this.measureTime,
    required this.afibMode,
    required this.afibFlag,
    this.deviceType,
  });
  
  /// 从Map创建实例（原生平台数据转换）
  factory OmronBpData.fromMap(Map<String, dynamic> map) {
    return OmronBpData(
      systolic: map['systolic'] as int? ?? 0,
      diastolic: map['diastolic'] as int? ?? 0,
      pulse: map['pulse'] as int? ?? 0,
      arrhythmiaFlag: map['arrhythmiaFlag'] as int? ?? 0,
      bodyMovementFlag: map['bodyMovementFlag'] as int? ?? 0,
      cuffWrapFlag: map['cuffWrapFlag'] as int? ?? 0,
      measureUser: map['measureUser'] as int? ?? 0,
      measureTime: map['measureTime'] as int? ?? 0,
      afibMode: map['afibMode'] as int? ?? 0,
      afibFlag: map['afibFlag'] as int? ?? 0,
      deviceType: map['deviceType'] as String?,
    );
  }
  
  /// 转换为Map（用于序列化）
  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'arrhythmiaFlag': arrhythmiaFlag,
      'bodyMovementFlag': bodyMovementFlag,
      'cuffWrapFlag': cuffWrapFlag,
      'measureUser': measureUser,
      'measureTime': measureTime,
      'afibMode': afibMode,
      'afibFlag': afibFlag,
      if (deviceType != null) 'deviceType': deviceType,
    };
  }
  
  /// 获取测量时间的DateTime对象
  DateTime? get measureDateTime {
    if (measureTime > 0) {
      return DateTime.fromMillisecondsSinceEpoch(measureTime);
    }
    return null;
  }
  
  /// 获取格式化的测量时间
  String get formattedMeasureTime {
    final dt = measureDateTime;
    if (dt == null) return '未知';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
  
  /// 获取血压等级描述
  String get bloodPressureLevel {
    if (systolic < 120 && diastolic < 80) {
      return '正常';
    } else if (systolic < 130 && diastolic < 85) {
      return '正常偏高';
    } else if (systolic < 140 || diastolic < 90) {
      return '轻度高血压';
    } else if (systolic < 160 || diastolic < 100) {
      return '中度高血压';
    } else {
      return '重度高血压';
    }
  }
  
  /// 获取格式化的血压值
  String get formattedBloodPressure => '$systolic/$diastolic mmHg';
  
  /// 获取格式化的脉搏
  String get formattedPulse => '$pulse bpm';
  
  /// 是否有心律不齐
  bool get hasArrhythmia => arrhythmiaFlag == 1;
  
  /// 是否有身体移动
  bool get hasBodyMovement => bodyMovementFlag == 1;
  
  /// 是否袖带佩戴异常
  bool get hasCuffWrapIssue => cuffWrapFlag == 1;
  
  /// 是否有房颤
  bool get hasAfib => afibFlag == 1;
  
  /// 是否支持房颤检测
  bool get supportsAfib => afibMode == 1;
  
  /// 获取用户名称
  String get userName {
    switch (measureUser) {
      case 1:
        return '用户A';
      case 2:
        return '用户B';
      default:
        return '未设置';
    }
  }
  
  @override
  String toString() {
    return 'OmronBpData(systolic: $systolic, diastolic: $diastolic, pulse: $pulse, time: $formattedMeasureTime)';
  }
}

