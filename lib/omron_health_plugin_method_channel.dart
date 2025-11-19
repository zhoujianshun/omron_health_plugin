import 'package:omron_health_plugin/omron/omron_bind_result.dart';
import 'package:omron_health_plugin/omron/omron_config.dart';
import 'package:omron_health_plugin/omron/omron_connection_status.dart';
import 'package:omron_health_plugin/omron/omron_device_category.dart';
import 'package:omron_health_plugin/omron/omron_plugin.dart';
import 'package:omron_health_plugin/omron/omron_result.dart';
import 'package:omron_health_plugin/omron/omron_scan_event.dart';
import 'package:omron_health_plugin/omron/omron_scanned_device.dart';
import 'package:omron_health_plugin/omron/omron_sync_device.dart';

import 'omron_health_plugin_platform_interface.dart';

/// An implementation of [OmronHealthPluginPlatform] that uses method channels.
class MethodChannelOmronHealthPlugin extends OmronHealthPluginPlatform {
  /// The method channel used to interact with the native platform.
  // @visibleForTesting
  // final methodChannel = const MethodChannel('omron_health_plugin');

  // @override
  // Future<String?> getPlatformVersion() async {
  //   final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
  //   return version;
  // }

  @override
  Future<void> initSdk() {
    return OmronPlugin.instance.initSdk();
  }

  @override
  Future<OmronInitResult> register(OmronConfig config) {
    return OmronPlugin.instance.register(config);
  }

  /// 开始监听蓝牙连接状态
  /// 
  /// 返回一个Stream，用于接收连接状态变化
  /// 可以多次调用，会复用同一个Stream
  /// 
  /// 使用示例:
  /// ```dart
  /// OmronPlugin.instance.startConnectionStatusListener().listen((status) {
  ///   print('连接状态: ${status.message}');
  /// });
  /// ```
  @override
  Stream<OmronConnectionStatus> startConnectionStatusListener() {
    return OmronPlugin.instance.startConnectionStatusListener();
  }
  
  /// 开始扫描绑定状态的设备
  /// 
  /// [category] 设备类别，指定要扫描的设备类型
  /// [timeout] 扫描超时时间（秒），默认60秒
  /// 
  /// 返回一个Stream，推送扫描事件（设备发现、扫描完成等）
  /// 可以多次调用，会复用同一个Stream
  /// 
  /// 使用示例:
  /// ```dart
  /// OmronPlugin.instance.startBindScan(OmronDeviceCategory.bloodPressure, 30).listen((event) {
  ///   if (event.isDeviceFound) {
  ///     print('扫描到设备: ${event.device.deviceName}');
  ///   } else if (event.isScanFinished) {
  ///     print('扫描完成');
  ///   }
  /// });
  /// ```
  @override
  Stream<OmronScanEvent<OmronScannedDevice>> startBindScan(OmronDeviceCategory category, {int timeout = 60}) {
    return OmronPlugin.instance.startBindScan(category, timeout: timeout);
  }
  
  /// 停止扫描设备（绑定扫描）
  /// 
  /// 调用此方法会停止当前正在进行的设备扫描
  @override
  Future<void> stopScan() {
    return OmronPlugin.instance.stopScan();
  }
  
  /// 开始扫描同步状态的设备
  /// 
  /// [devices] 已绑定的设备列表，扫描这些设备的同步状态
  /// [scanPeriod] 扫描周期（秒），最小1s，最大300s，默认60秒
  /// 
  /// 返回一个Stream，推送扫描事件（设备发现、扫描完成等）
  /// 会自动过滤重复设备，只展示唯一设备
  /// 
  /// 使用示例:
  /// ```dart
  /// final devices = [
  ///   OmronSyncDevice(deviceType: 'BLOOD_PRESSURE', deviceSerialNum: '00:11:22:33:44:55'),
  /// ];
  /// OmronPlugin.instance.startSyncScan(devices, scanPeriod: 30).listen((event) {
  ///   if (event.isDeviceFound) {
  ///     print('扫描到同步设备: ${event.device.deviceName}');
  ///   } else if (event.isScanFinished) {
  ///     print('同步扫描完成');
  ///   }
  /// });
  /// ```
  @override
  Stream<OmronScanEvent<OmronScannedDevice>> startSyncScan(List<OmronSyncDevice> devices, {int scanPeriod = 60}) {
    return OmronPlugin.instance.startSyncScan(devices, scanPeriod: scanPeriod);
  }
  
  /// 停止同步扫描
  /// 
  /// 调用此方法会停止当前正在进行的同步扫描
  @override
  Future<void> stopSyncScan() {
    return OmronPlugin.instance.stopSyncScan();
  }
  
  /// 绑定血压计设备
  /// 
  /// [deviceType] 设备类型
  /// [deviceSerialNum] 设备序列号（可选，Android为MAC地址）
  /// 
  /// 返回绑定结果，包含设备信息和测量数据
  /// 
  /// 使用示例:
  /// ```dart
  /// final result = await OmronPlugin.instance.bindBpDevice('BLEPeripheral', '00:11:22:33:44:55');
  /// if (result.isSuccess) {
  ///   print('绑定成功，获取到${result.dataCount}条数据');
  /// }
  /// ```
  @override
  Future<OmronBindResult> bindBpDevice({
    required String deviceType,
    String? deviceSerialNum,
  }) {
   return OmronPlugin.instance.bindBpDevice(deviceType: deviceType, deviceSerialNum: deviceSerialNum);
  }
  
  /// 同步血压计测量数据
  /// 
  /// 获取血压计中所有未同步过的血压数据
  /// 
  /// [deviceType] 设备类型
  /// [deviceSerialNum] 设备序列号/唯一标识
  ///   - Android: 设备名称和MAC地址（用分号分隔，如 "deviceName;00:11:22:33:44:55"）
  ///   - iOS: 绑定接口返回的设备唯一码（deviceSerialNum）
  /// 
  /// 返回同步结果，包含状态和测量数据列表
  /// 
  /// 使用示例:
  /// ```dart
  /// // Android
  /// final result = await OmronPlugin.instance.getBpDeviceData(
  ///   deviceType: 'BLEPeripheral',
  ///   deviceSerialNum: 'MyDevice;00:11:22:33:44:55',
  /// );
  /// 
  /// // iOS
  /// final result = await OmronPlugin.instance.getBpDeviceData(
  ///   deviceType: 'BLEPeripheral',
  ///   deviceSerialNum: 'E0B99180439E',
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   print('同步成功，获取到${result.dataCount}条数据');
  ///   for (var data in result.bpDataList) {
  ///     print('血压: ${data.systolic}/${data.diastolic}, 心率: ${data.heartRate}');
  ///   }
  /// }
  /// ```
  @override
  Future<OmronBindResult> getBpDeviceData({
    required String deviceType,
    required String deviceSerialNum,
  }) {
    return OmronPlugin.instance.getBpDeviceData(deviceType: deviceType, deviceSerialNum: deviceSerialNum);
  }
}
