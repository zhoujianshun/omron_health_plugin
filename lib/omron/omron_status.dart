/// OMRON SDK 状态枚举
/// 统一Android和iOS的状态码
enum OmronStatus {
  /// 成功
  success,
  
  /// 未注册
  unRegister,
  
  /// 厂商ID无效
  inValidKey,
  
  /// 无网络连接
  noNet,
  
  /// 蓝牙未开启
  unOpenBlueTooth,
  
  /// 蓝牙异常
  blueToothError,
  
  /// 不支持当前设备
  unSupportDevice,
  
  /// 不支持该设备类别
  unSupportDeviceCategory,
  
  /// 未绑定设备
  unBind,
  
  /// PIN码错误
  pinCodeError,
  
  /// 绑定状态错误
  bondInvalid,
  
  /// 配对取消
  bondCancel,
  
  /// 蓝牙连接断开
  disconnected,
  
  /// 绑定失败
  bindFail,
  
  /// 未找到设备
  noDevice,
  
  /// 连接失败
  connectFail,
  
  /// 扫描超时
  scanTimeOut,
  
  /// 未知错误
  unknown;
  
  /// 从字符串转换为枚举
  static OmronStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return OmronStatus.success;
      case 'unregister':
        return OmronStatus.unRegister;
      case 'invalidkey':
        return OmronStatus.inValidKey;
      case 'nonet':
        return OmronStatus.noNet;
      case 'unopenbluetooth':
        return OmronStatus.unOpenBlueTooth;
      case 'bluetootherror':
        return OmronStatus.blueToothError;
      case 'unsupportdevice':
        return OmronStatus.unSupportDevice;
      case 'unsupportdevicecategory':
        return OmronStatus.unSupportDeviceCategory;
      case 'unbind':
        return OmronStatus.unBind;
      case 'pincodeerror':
        return OmronStatus.pinCodeError;
      case 'bondinvalid':
        return OmronStatus.bondInvalid;
      case 'bondcancel':
        return OmronStatus.bondCancel;
      case 'disconnected':
        return OmronStatus.disconnected;
      case 'bindfail':
        return OmronStatus.bindFail;
      case 'nodevice':
        return OmronStatus.noDevice;
      case 'connectfail':
        return OmronStatus.connectFail;
      case 'scantimeout':
        return OmronStatus.scanTimeOut;
      default:
        return OmronStatus.unknown;
    }
  }
  
  /// 获取状态描述信息
  String get message {
    switch (this) {
      case OmronStatus.success:
        return '初始化成功';
      case OmronStatus.unRegister:
        return '未注册';
      case OmronStatus.inValidKey:
        return '厂商ID无效';
      case OmronStatus.noNet:
        return '请在网络连接状态下进行操作';
      case OmronStatus.unOpenBlueTooth:
        return '蓝牙未开启，请开启蓝牙';
      case OmronStatus.blueToothError:
        return '蓝牙异常';
      case OmronStatus.unSupportDevice:
        return '不支持当前设备';
      case OmronStatus.unSupportDeviceCategory:
        return '不支持该设备类别';
      case OmronStatus.unBind:
        return '请先绑定正确的设备';
      case OmronStatus.pinCodeError:
        return 'PIN码错误';
      case OmronStatus.bondInvalid:
        return '绑定状态错误，请在蓝牙列表中取消配对后再试';
      case OmronStatus.bondCancel:
        return '配对取消';
      case OmronStatus.disconnected:
        return '蓝牙连接断开';
      case OmronStatus.bindFail:
        return '绑定失败';
      case OmronStatus.noDevice:
        return '未找到设备';
      case OmronStatus.connectFail:
        return '连接失败';
      case OmronStatus.scanTimeOut:
        return '扫描超时';
      case OmronStatus.unknown:
        return '未知错误';
    }
  }
  
  /// 是否为成功状态
  bool get isSuccess => this == OmronStatus.success;
}

