import 'package:flutter/material.dart';

/// OMRON 蓝牙连接状态枚举
/// 统一Android和iOS的连接状态
enum OmronConnectionStatus {
  /// 开始扫描
  scan,
  
  /// 开始连接
  connect,
  
  /// 开始数据同步
  syncData,
  
  /// 数据同步成功
  syncDataSuccess,
  
  /// 数据同步失败
  syncDataError,
  
  /// 断开连接
  disconnected,
  
  /// 未知状态
  unknown;
  
  /// 从字符串转换为枚举
  static OmronConnectionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scan':
        return OmronConnectionStatus.scan;
      case 'connect':
        return OmronConnectionStatus.connect;
      case 'syncdata':
        return OmronConnectionStatus.syncData;
      case 'syncdatasuccess':
        return OmronConnectionStatus.syncDataSuccess;
      case 'syncdataerror':
        return OmronConnectionStatus.syncDataError;
      case 'disconnected':
        return OmronConnectionStatus.disconnected;
      default:
        return OmronConnectionStatus.unknown;
    }
  }
  
  /// 获取状态描述信息
  String get message {
    switch (this) {
      case OmronConnectionStatus.scan:
        return '开始扫描设备';
      case OmronConnectionStatus.connect:
        return '开始连接设备';
      case OmronConnectionStatus.syncData:
        return '开始数据同步';
      case OmronConnectionStatus.syncDataSuccess:
        return '数据同步成功';
      case OmronConnectionStatus.syncDataError:
        return '数据同步失败';
      case OmronConnectionStatus.disconnected:
        return '设备已断开连接';
      case OmronConnectionStatus.unknown:
        return '未知状态';
    }
  }
  
  /// 获取状态对应的图标
  IconData get icon {
    switch (this) {
      case OmronConnectionStatus.scan:
        return Icons.search;
      case OmronConnectionStatus.connect:
        return Icons.bluetooth_searching;
      case OmronConnectionStatus.syncData:
        return Icons.sync;
      case OmronConnectionStatus.syncDataSuccess:
        return Icons.check_circle;
      case OmronConnectionStatus.syncDataError:
        return Icons.error;
      case OmronConnectionStatus.disconnected:
        return Icons.bluetooth_disabled;
      case OmronConnectionStatus.unknown:
        return Icons.help_outline;
    }
  }
  
  /// 获取状态对应的颜色
  Color get color {
    switch (this) {
      case OmronConnectionStatus.scan:
        return Colors.blue;
      case OmronConnectionStatus.connect:
        return Colors.orange;
      case OmronConnectionStatus.syncData:
        return Colors.purple;
      case OmronConnectionStatus.syncDataSuccess:
        return Colors.green;
      case OmronConnectionStatus.syncDataError:
        return Colors.red;
      case OmronConnectionStatus.disconnected:
        return Colors.grey;
      case OmronConnectionStatus.unknown:
        return Colors.blueGrey;
    }
  }
}

