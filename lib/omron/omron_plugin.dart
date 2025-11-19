import 'package:flutter/services.dart';
import 'omron_config.dart';
import 'omron_result.dart';
import 'omron_connection_status.dart';
import 'omron_device_category.dart';
import 'omron_scanned_device.dart';
import 'omron_bind_result.dart';
import 'omron_sync_device.dart';
import 'omron_scan_event.dart';
import 'omron_logger.dart';

/// OMRON插件，用于与原生平台通信
class OmronPlugin {
  // 私有构造函数（单例模式）
  OmronPlugin._();
  
  /// 单例实例
  static final OmronPlugin instance = OmronPlugin._();
  
  /// MethodChannel 用于SDK初始化
  static const MethodChannel _methodChannel = MethodChannel('top.inomo.omron_health_plugin/omron');
  
  /// EventChannel 用于接收连接状态
  static const EventChannel _statusEventChannel = EventChannel('top.inomo.omron_health_plugin/omron_status');
  
  /// EventChannel 用于接收扫描到的设备（绑定扫描）
  static const EventChannel _scanEventChannel = EventChannel('top.inomo.omron_health_plugin/omron_scan');
  
  /// EventChannel 用于接收扫描到的设备（同步扫描）
  static const EventChannel _syncScanEventChannel = EventChannel('top.inomo.omron_health_plugin/omron_sync_scan');
  
  /// 连接状态流
  Stream<OmronConnectionStatus>? _statusStream;
  
  /// 初始化OMRON SDK（仅Android需要，iOS为空实现）
  /// 
  /// Android平台需要在注册前调用此方法进行基础初始化
  /// iOS平台会直接返回成功，无需实际操作
  /// 
  /// 抛出异常：
  /// - [PlatformException] 原生平台错误
  /// - [Exception] 其他未知错误
  Future<void> initSdk() async {
    OmronLogger.debug('[Flutter] 调用 initSdk');
    try {
      final result = await _methodChannel.invokeMethod('initSdk');
      OmronLogger.success('[Flutter] initSdk 返回: $result');
    } on PlatformException catch (e) {
      OmronLogger.error('[Flutter] initSdk PlatformException: ${e.message}');
      throw Exception('OMRON SDK初始化失败: ${e.message}');
    } catch (e) {
      OmronLogger.error('[Flutter] initSdk 错误: $e');
      throw Exception('OMRON SDK初始化时发生未知错误: $e');
    }
  }
  
  /// 注册OMRON SDK
  /// 
  /// [config] 包含SDK注册所需的所有参数
  /// 
  /// Android平台：需要先调用initSdk()方法
  /// iOS平台：可以直接调用此方法
  /// 
  /// 返回注册结果，包含状态码和详细信息
  /// 
  /// 抛出异常：
  /// - [PlatformException] 原生平台错误
  /// - [Exception] 其他未知错误
  Future<OmronInitResult> register(OmronConfig config) async {
    OmronLogger.debug('[Flutter] 调用 register');
    OmronLogger.info('[Flutter] 参数: ${config.toMap()}');
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
        'register',
        config.toMap(),
      );
      OmronLogger.success('[Flutter] register 返回: $result');
      
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);
      final omronResult = OmronInitResult.fromMap(resultMap);
      OmronLogger.info('[Flutter] 解析结果: $omronResult');
      return omronResult;
    } on PlatformException catch (e) {
      OmronLogger.error('[Flutter] register PlatformException: ${e.message}');
      throw Exception('OMRON SDK注册失败: ${e.message}');
    } catch (e) {
      OmronLogger.error('[Flutter] register 错误: $e');
      throw Exception('OMRON SDK注册时发生未知错误: $e');
    }
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
  Stream<OmronConnectionStatus> startConnectionStatusListener() {
    OmronLogger.debug('[Flutter] 调用 startConnectionStatusListener');
    
    // 如果已经创建过Stream，直接返回
    _statusStream ??= _statusEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          OmronLogger.log('📥 [Flutter] 收到状态事件: $event');
          if (event is String) {
            final status = OmronConnectionStatus.fromString(event);
            OmronLogger.success('[Flutter] 状态解析: ${status.name} - ${status.message}');
            return status;
          }
          OmronLogger.log('⚠️ [Flutter] 未知事件类型: ${event.runtimeType}');
          return OmronConnectionStatus.unknown;
        });
    
    return _statusStream!;
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
  Stream<OmronScanEvent<OmronScannedDevice>> startBindScan(OmronDeviceCategory category, {int timeout = 60}) {
    OmronLogger.debug('[Flutter] 调用 startBindScan, category: ${category.displayName}, timeout: $timeout秒');
    
    try {
      // 调用原生方法开始扫描
      _methodChannel.invokeMethod('startBindScan', {
        'categoryValue': category.toValue(),
        'categoryString': category.toStringValue(),
        'timeout': timeout,
      });
      
      // 创建扫描事件流
      return _scanEventChannel
          .receiveBroadcastStream()
          .map((dynamic event) {
            OmronLogger.log('📥 [Flutter] 收到扫描事件: $event');
            
            if (event is Map) {
              final eventMap = Map<String, dynamic>.from(event);
              
              // 检查是否是扫描完成事件
              if (eventMap.containsKey('isFinished') && eventMap['isFinished'] == true) {
                OmronLogger.log('🏁 [Flutter] 扫描周期结束: ${eventMap['message']}');
                return OmronScanEvent.scanFinished(
                  message: eventMap['message'] as String?,
                );
              }
              
              // 正常的设备数据
              final device = OmronScannedDevice.fromMap(eventMap);
              OmronLogger.success('[Flutter] 设备解析: ${device.deviceName} - ${device.deviceSerialNum}');
              return OmronScanEvent.deviceFound(device);
            }
            
            OmronLogger.log('⚠️ [Flutter] 未知事件类型: ${event.runtimeType}');
            return OmronScanEvent.scanError(
              message: '无效的设备数据格式',
              error: event,
            );
          });
    } catch (e) {
      OmronLogger.error('[Flutter] startBindScan 错误: $e');
      rethrow;
    }
  }
  
  /// 停止扫描设备（绑定扫描）
  /// 
  /// 调用此方法会停止当前正在进行的设备扫描
  Future<void> stopScan() async {
    OmronLogger.debug('[Flutter] 调用 stopScan');
    try {
      await _methodChannel.invokeMethod('stopScan');
      OmronLogger.success('[Flutter] stopScan 成功');
    } on PlatformException catch (e) {
      OmronLogger.error('[Flutter] stopScan PlatformException: ${e.message}');
      throw Exception('停止扫描失败: ${e.message}');
    } catch (e) {
      OmronLogger.error('[Flutter] stopScan 错误: $e');
      throw Exception('停止扫描时发生未知错误: $e');
    }
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
  Stream<OmronScanEvent<OmronScannedDevice>> startSyncScan(List<OmronSyncDevice> devices, {int scanPeriod = 60}) {
    OmronLogger.debug('[Flutter] 调用 startSyncScan, devices: ${devices.length}个, scanPeriod: $scanPeriod秒');
    
    // 验证扫描周期
    if (scanPeriod < 1 || scanPeriod > 300) {
      throw ArgumentError('扫描周期必须在1-300秒之间，当前值: $scanPeriod');
    }
    
    try {
      // 调用原生方法开始同步扫描
      _methodChannel.invokeMethod('startSyncScan', {
        'devices': devices.map((d) => d.toMap()).toList(),
        'scanPeriod': scanPeriod,
      });
      
      // 创建同步扫描事件流
      return _syncScanEventChannel
          .receiveBroadcastStream()
          .map((dynamic event) {
            OmronLogger.log('📥 [Flutter] 收到同步扫描事件: $event');
            
            if (event is Map) {
              final eventMap = Map<String, dynamic>.from(event);
              
              // 检查是否是扫描完成事件
              if (eventMap.containsKey('isFinished') && eventMap['isFinished'] == true) {
                OmronLogger.log('🏁 [Flutter] 同步扫描周期结束: ${eventMap['message']}');
                return OmronScanEvent.scanFinished(
                  message: eventMap['message'] as String?,
                );
              }
              
              // 正常的设备数据
              final device = OmronScannedDevice.fromMap(eventMap);
              OmronLogger.success('[Flutter] 同步设备解析: ${device.deviceName} - ${device.deviceSerialNum}');
              return OmronScanEvent.deviceFound(device);
            }
            
            OmronLogger.log('⚠️ [Flutter] 未知事件类型: ${event.runtimeType}');
            return OmronScanEvent.scanError(
              message: '无效的设备数据格式',
              error: event,
            );
          });
    } catch (e) {
      OmronLogger.error('[Flutter] startSyncScan 错误: $e');
      rethrow;
    }
  }
  
  /// 停止同步扫描
  /// 
  /// 调用此方法会停止当前正在进行的同步扫描
  Future<void> stopSyncScan() async {
    OmronLogger.debug('[Flutter] 调用 stopSyncScan');
    try {
      await _methodChannel.invokeMethod('stopSyncScan');
      OmronLogger.success('[Flutter] stopSyncScan 成功');
    } on PlatformException catch (e) {
      OmronLogger.error('[Flutter] stopSyncScan PlatformException: ${e.message}');
      throw Exception('停止同步扫描失败: ${e.message}');
    } catch (e) {
      OmronLogger.error('[Flutter] stopSyncScan 错误: $e');
      throw Exception('停止同步扫描时发生未知错误: $e');
    }
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
  Future<OmronBindResult> bindBpDevice({
    required String deviceType,
    String? deviceSerialNum,
  }) async {
    OmronLogger.debug('[Flutter] 调用 bindBpDevice');
    OmronLogger.info('[Flutter] 参数 - deviceType: $deviceType, serialNum: $deviceSerialNum');
    
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
        'bindBpDevice',
        {
          'deviceType': deviceType,
          if (deviceSerialNum != null) 'deviceSerialNum': deviceSerialNum,
        },
      );
      
      OmronLogger.success('[Flutter] bindBpDevice 返回: $result');
      
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);
      final bindResult = OmronBindResult.fromMap(resultMap);
      OmronLogger.info('[Flutter] 解析结果: $bindResult');
      return bindResult;
    } on PlatformException catch (e) {
      OmronLogger.error('[Flutter] bindBpDevice PlatformException: ${e.message}');
      throw Exception('绑定血压计失败: ${e.message}');
    } catch (e) {
      OmronLogger.error('[Flutter] bindBpDevice 错误: $e');
      throw Exception('绑定血压计时发生未知错误: $e');
    }
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
  Future<OmronBindResult> getBpDeviceData({
    required String deviceType,
    required String deviceSerialNum,
  }) async {
    OmronLogger.debug('[Flutter] 调用 getBpDeviceData');
    OmronLogger.info('[Flutter] 参数 - deviceType: $deviceType, serialNum: $deviceSerialNum');
    
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
        'getBpDeviceData',
        {
          'deviceType': deviceType,
          'deviceSerialNum': deviceSerialNum,
        },
      );
      
      OmronLogger.success('[Flutter] getBpDeviceData 返回: $result');
      
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);
      final syncResult = OmronBindResult.fromMap(resultMap);
      OmronLogger.info('[Flutter] 解析结果: ${syncResult.dataCount}条数据');
      return syncResult;
    } on PlatformException catch (e) {
      OmronLogger.error('[Flutter] getBpDeviceData PlatformException: ${e.message}');
      throw Exception('同步血压数据失败: ${e.message}');
    } catch (e) {
      OmronLogger.error('[Flutter] getBpDeviceData 错误: $e');
      throw Exception('同步血压数据时发生未知错误: $e');
    }
  }
}

