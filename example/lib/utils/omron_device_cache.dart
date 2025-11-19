import 'dart:convert';
import 'package:omron_health_plugin/omron/omron_sync_device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

/// Omron设备缓存管理类
/// 用于保存和读取已绑定的设备信息
class OmronDeviceCache {
  static const String _keyBoundDevices = 'omron_bound_devices';
  
  /// 获取所有已绑定的设备
  static Future<List<OmronSyncDevice>> getBoundDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? devicesJson = prefs.getString(_keyBoundDevices);
      
      if (devicesJson == null || devicesJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> devicesList = jsonDecode(devicesJson);
      return devicesList
          .map((json) => OmronSyncDevice.fromMap(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      Logger.error('读取已绑定设备失败', tag: 'DeviceCache', error: e);
      return [];
    }
  }
  
  /// 保存已绑定的设备
  static Future<bool> saveBoundDevices(List<OmronSyncDevice> devices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> devicesList = 
          devices.map((device) => device.toMap()).toList();
      final String devicesJson = jsonEncode(devicesList);
      
      return await prefs.setString(_keyBoundDevices, devicesJson);
    } catch (e) {
      Logger.error('保存已绑定设备失败', tag: 'DeviceCache', error: e);
      return false;
    }
  }
  
  /// 添加一个已绑定的设备
  static Future<bool> addBoundDevice(OmronSyncDevice device) async {
    try {
      final devices = await getBoundDevices();
      
      // 检查是否已存在（根据序列号判断）
      final exists = devices.any(
        (d) => d.deviceSerialNum == device.deviceSerialNum,
      );
      
      if (exists) {
        Logger.warning('设备已存在: ${device.deviceSerialNum}', tag: 'DeviceCache');
        return false;
      }
      
      devices.add(device);
      return await saveBoundDevices(devices);
    } catch (e) {
      Logger.error('添加已绑定设备失败', tag: 'DeviceCache', error: e);
      return false;
    }
  }
  
  /// 移除一个已绑定的设备
  static Future<bool> removeBoundDevice(String deviceSerialNum) async {
    try {
      final devices = await getBoundDevices();
      devices.removeWhere((d) => d.deviceSerialNum == deviceSerialNum);
      return await saveBoundDevices(devices);
    } catch (e) {
      Logger.error('移除已绑定设备失败', tag: 'DeviceCache', error: e);
      return false;
    }
  }
  
  /// 清空所有已绑定的设备
  static Future<bool> clearBoundDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyBoundDevices);
    } catch (e) {
      Logger.error('清空已绑定设备失败', tag: 'DeviceCache', error: e);
      return false;
    }
  }
  
  /// 检查设备是否已绑定
  static Future<bool> isDeviceBound(String deviceSerialNum) async {
    try {
      final devices = await getBoundDevices();
      return devices.any((d) => d.deviceSerialNum == deviceSerialNum);
    } catch (e) {
      Logger.error('检查设备绑定状态失败', tag: 'DeviceCache', error: e);
      return false;
    }
  }
  
  /// 获取已绑定设备数量
  static Future<int> getBoundDeviceCount() async {
    try {
      final devices = await getBoundDevices();
      return devices.length;
    } catch (e) {
      Logger.error('获取已绑定设备数量失败', tag: 'DeviceCache', error: e);
      return 0;
    }
  }
}

