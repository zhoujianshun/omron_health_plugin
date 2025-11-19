/// OMRON SDK 配置类
/// 封装初始化所需的所有参数
class OmronConfig {
  /// 应用密钥（厂商key）
  final String appKey;
  
  /// 设备密钥（设备授权key）
  // final String ekiKey;
  
  /// 应用包名
  final String packageName;
  
  /// 应用秘钥（包名密码）
  final String packageSecret;
  
  /// 设备独立授权的离线License文件（可选）
  final String? license;
  
  /// 第三方用户识别码（可选，长度不超过64位）
  final String? thirdUserId;
  
  /// 构造函数
  OmronConfig({
    required this.appKey,
    // required this.ekiKey,
    required this.packageName,
    required this.packageSecret,
    this.license,
    this.thirdUserId,
  }) {
    // 参数验证
    if (appKey.isEmpty) {
      throw ArgumentError('appKey不能为空');
    }
    // if (ekiKey.isEmpty) {
    //   throw ArgumentError('ekiKey不能为空');
    // }
    if (packageName.isEmpty) {
      throw ArgumentError('packageName不能为空');
    }
    if (packageSecret.isEmpty) {
      throw ArgumentError('packageSecret不能为空');
    }
    if (thirdUserId != null && thirdUserId!.length > 64) {
      throw ArgumentError('thirdUserId长度不能超过64位');
    }
  }
  
  /// 转换为Map，用于传递给原生平台
  Map<String, dynamic> toMap() {
    return {
      'appKey': appKey,
      // 'ekiKey': ekiKey,
      'packageName': packageName,
      'packageSecret': packageSecret,
      if (license != null) 'license': license,
      if (thirdUserId != null) 'thirdUserId': thirdUserId,
    };
  }
  
  @override
  String toString() {
    return 'OmronConfig(appKey: $appKey, packageName: $packageName)';
  }
}

