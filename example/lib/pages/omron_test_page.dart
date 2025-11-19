import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omron_health_plugin/omron/omron_bind_result.dart';
import 'package:omron_health_plugin/omron/omron_config.dart';
import 'package:omron_health_plugin/omron/omron_connection_status.dart';
import 'package:omron_health_plugin/omron/omron_device_category.dart';
import 'package:omron_health_plugin/omron/omron_result.dart';
import 'package:omron_health_plugin/omron/omron_scan_event.dart';
import 'package:omron_health_plugin/omron/omron_scanned_device.dart';
import 'package:omron_health_plugin/omron/omron_sync_device.dart';
import 'package:omron_health_plugin/omron_health_plugin.dart';
import 'package:omron_health_plugin_example/utils/omron_device_cache.dart';
import 'package:omron_health_plugin_example/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';

import 'omron_sync_scan_test_page.dart';

/// OMRON SDK 测试页面
class OmronTestPage extends StatefulWidget {
  const OmronTestPage({super.key});

  @override
  State<OmronTestPage> createState() => _OmronTestPageState();
}

class _OmronTestPageState extends State<OmronTestPage> {
  // 表单控制器
  final _appKeyController = TextEditingController(text: '');
  // final _ekiKeyController = TextEditingController();
  final _packageNameController = TextEditingController(text: '');
  final _packageSecretController = TextEditingController(text: '');
  final _licenseController = TextEditingController();
  final _thirdUserIdController = TextEditingController();
  
  // 状态变量
  bool _isInitializing = false;
  bool _isRegistering = false;
  bool _initSdkSuccess = false;
  OmronInitResult? _registerResult;
  String? _errorMessage;
  
  // 连接状态监听相关
  bool _isListening = false;
  OmronConnectionStatus? _currentStatus;
  DateTime? _lastStatusTime;
  StreamSubscription<OmronConnectionStatus>? _statusSubscription;
  final List<Map<String, dynamic>> _statusHistory = [];
  
  // 设备扫描相关
  OmronDeviceCategory _selectedCategory = OmronDeviceCategory.all;
  bool _isScanning = false;
  final List<OmronScannedDevice> _scannedDevices = [];
  StreamSubscription<OmronScanEvent<OmronScannedDevice>>? _scanSubscription;
  
  // 设备绑定相关
  bool _isBinding = false;
  OmronBindResult? _bindResult;

  @override
  void dispose() {
    _appKeyController.dispose();
    // _ekiKeyController.dispose();
    _packageNameController.dispose();
    _packageSecretController.dispose();
    _licenseController.dispose();
    _thirdUserIdController.dispose();
    _statusSubscription?.cancel();
    _scanSubscription?.cancel();
    super.dispose();
  }

  /// 步骤1：初始化SDK（仅Android需要）
  Future<void> _initializeSdk() async {
    Logger.log('🔘 [TestPage] _initializeSdk 按钮被点击');
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      Logger.log('⏳ [TestPage] 开始调用 OmronHealthPlugin.instance.initSdk()');
      await OmronHealthPlugin.instance.initSdk();
      Logger.log('✅ [TestPage] initSdk 调用成功');
      
      setState(() {
        _initSdkSuccess = true;
        _isInitializing = false;
      });
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SDK初始化成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.log('❌ [TestPage] initSdk 异常: $e');
      setState(() {
        _errorMessage = 'SDK初始化失败: $e';
        _isInitializing = false;
      });
    }
  }

  /// 步骤2：注册SDK
  Future<void> _registerSdk() async {
    Logger.log('🔘 [TestPage] _registerSdk 按钮被点击');
    setState(() {
      _isRegistering = true;
      _registerResult = null;
      _errorMessage = null;
    });

    try {
      // 创建配置对象
      Logger.log('⏳ [TestPage] 创建 OmronConfig');
      final config = OmronConfig(
        appKey: _appKeyController.text.trim(),
        packageName: _packageNameController.text.trim(),
        packageSecret: _packageSecretController.text.trim(),
        license: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
        thirdUserId: _thirdUserIdController.text.trim().isEmpty ? null : _thirdUserIdController.text.trim(),
      );
      Logger.log('✅ [TestPage] OmronConfig 创建成功: $config');

      // 调用注册
      Logger.log('⏳ [TestPage] 开始调用 OmronHealthPlugin.instance.register()');
      final result = await OmronHealthPlugin.instance.register(config);
      Logger.log('✅ [TestPage] register 调用成功: $result');

      setState(() {
        _registerResult = result;
        _isRegistering = false;
      });
    } catch (e) {
      Logger.log('❌ [TestPage] register 异常: $e');
      setState(() {
        _errorMessage = e.toString();
        _isRegistering = false;
      });
    }
  }

  /// 步骤3：开始监听连接状态
  Future<void> _startConnectionListener() async {
    Logger.log('🔘 [TestPage] _startConnectionListener 按钮被点击');
    
    if (_isListening) {
      Logger.log('⚠️ [TestPage] 已经在监听中');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已经在监听连接状态'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isListening = true;
      _statusHistory.clear();
    });
    
    try {
      Logger.log('⏳ [TestPage] 开始订阅状态流');
      final stream = OmronHealthPlugin.instance.startConnectionStatusListener();
      
      _statusSubscription = stream.listen(
        (status) {
          Logger.log('📥 [TestPage] 收到状态: ${status.name} - ${status.message}');
          setState(() {
            _currentStatus = status;
            _lastStatusTime = DateTime.now();
            _statusHistory.insert(0, {
              'status': status,
              'time': _lastStatusTime,
            });
            // 只保留最近20条记录
            if (_statusHistory.length > 20) {
              _statusHistory.removeLast();
            }
          });
        },
        onError: (error) {
          Logger.log('❌ [TestPage] 状态流错误: $error');
          setState(() {
            _errorMessage = '状态监听错误: $error';
          });
        },
      );
      
      Logger.log('✅ [TestPage] 状态监听启动成功');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接状态监听已启动'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // 自动启动监听的代码（已注释）
      // if (_registerResult != null && _registerResult!.isSuccess) {
      //   _startConnectionListener();
      // }
      
    } catch (e) {
      Logger.log('❌ [TestPage] 启动监听异常: $e');
      setState(() {
        _errorMessage = '启动状态监听失败: $e';
        _isListening = false;
      });
    }
  }

  /// 检查并申请蓝牙相关权限
  Future<bool> _checkAndRequestPermissions() async {
    Logger.log('🔐 [TestPage] 开始检查权限');
    
    if (Platform.isAndroid) {
      // Android 需要的权限列表
      List<Permission> requiredPermissions = [];
      Map<Permission, PermissionStatus> statuses = {};
      String permissionTip = '';
      
      // 根据Android版本判断需要的权限
      // Android 12 (API 31) 及以上
      try {
        // 尝试检查Android 12+的蓝牙权限
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;
        
        // 如果这些权限存在（Android 12+），则使用新的蓝牙权限
        Logger.log('📱 [TestPage] 检测到Android 12+，使用新蓝牙权限');
        if (scanStatus.isDenied || scanStatus.isPermanentlyDenied) {
          requiredPermissions.add(Permission.bluetoothScan);
        }
        if (connectStatus.isDenied || connectStatus.isPermanentlyDenied) {
          requiredPermissions.add(Permission.bluetoothConnect);
        }
        permissionTip = '扫描蓝牙设备需要以下权限：\n\n• 蓝牙扫描权限 (BLUETOOTH_SCAN)\n• 蓝牙连接权限 (BLUETOOTH_CONNECT)\n\n是否前往设置页面授予权限？';
      } catch (e) {
        // 如果抛出异常，说明是Android 11及以下，需要定位权限
        Logger.log('📱 [TestPage] 检测到Android 11及以下，需要定位权限');
        final locationStatus = await Permission.location.status;
        if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
          requiredPermissions.add(Permission.location);
        }
        // Android 11及以下还需要传统蓝牙权限（但这些在manifest中声明即可，不需要运行时申请）
        permissionTip = '扫描蓝牙设备需要以下权限：\n\n• 定位权限 (LOCATION)\n  Android 11及以下版本需要定位权限来扫描蓝牙设备\n\n是否前往设置页面授予权限？';
      }
      
      // 申请所需权限
      if (requiredPermissions.isNotEmpty) {
        Logger.log('🔑 [TestPage] 需要申请权限: $requiredPermissions');
        for (var permission in requiredPermissions) {
          statuses[permission] = await permission.request();
        }
        
        Logger.log('📋 [TestPage] 权限申请结果: $statuses');
        
        // 检查是否所有权限都已授予
        bool allGranted = true;
        for (var status in statuses.values) {
          if (!status.isGranted) {
            allGranted = false;
            break;
          }
        }
        
        if (!allGranted) {
          Logger.log('❌ [TestPage] 权限未全部授予');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要蓝牙相关权限才能扫描设备'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
            
            // 显示对话框引导用户去设置
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('需要权限'),
                content: Text(permissionTip),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('去设置'),
                  ),
                ],
              ),
            );
            
            if (shouldOpenSettings == true) {
              await openAppSettings();
            }
          }
          return false;
        }
      } else {
        Logger.log('✅ [TestPage] 所有权限已授予');
      }
      
      return true;
    } else if (Platform.isIOS) {
      // iOS 权限检查
      final bluetoothStatus = await Permission.bluetooth.status;
      if (bluetoothStatus.isDenied) {
        Logger.log('🔑 [TestPage] iOS需要蓝牙权限');
        final result = await Permission.bluetooth.request();
        if (!result.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('需要蓝牙权限才能扫描设备'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }
      Logger.log('✅ [TestPage] iOS权限已授予');
      return true;
    }
    
    return true;
  }
  
  /// 步骤4：开始扫描设备
  Future<void> _startDeviceScan() async {
    Logger.log('🔘 [TestPage] _startDeviceScan 按钮被点击');
    
    if (_isScanning) {
      Logger.log('⚠️ [TestPage] 已经在扫描中');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已经在扫描设备'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 检查权限
    final hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      Logger.log('❌ [TestPage] 权限检查失败，取消扫描');
      return;
    }
    
    setState(() {
      _isScanning = true;
      _scannedDevices.clear();
    });
    
    try {
      Logger.log('⏳ [TestPage] 开始订阅扫描流，类别: ${_selectedCategory.displayName}');
      final stream = OmronHealthPlugin.instance.startBindScan(_selectedCategory);
      
      _scanSubscription = stream.listen(
        (event) {
          // 处理扫描事件
          if (event.isDeviceFound) {
            // 设备发现事件
            final device = event.device as OmronScannedDevice;
            Logger.log('📥 [TestPage] 扫描到设备: ${device.deviceName} - ${device.deviceSerialNum}');
            setState(() {
              // 使用Set去重，避免重复添加相同序列号的设备
              final existingIndex = _scannedDevices.indexWhere(
                (d) => d.deviceSerialNum == device.deviceSerialNum
              );
              if (existingIndex >= 0) {
                // 更新现有设备
                _scannedDevices[existingIndex] = device;
              } else {
                // 添加新设备
                _scannedDevices.add(device);
              }
            });
          } else if (event.isScanFinished) {
            // 扫描完成事件
            Logger.log('🏁 [TestPage] 扫描周期结束: ${event.message}');
            setState(() {
              _isScanning = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${event.message}，共发现 ${_scannedDevices.length} 个设备'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else if (event.isScanError) {
            // 扫描错误事件
            Logger.log('❌ [TestPage] 扫描错误: ${event.message}');
            setState(() {
              _errorMessage = '设备扫描错误: ${event.message}';
              _isScanning = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(event.message ?? '扫描失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onError: (error) {
          Logger.log('❌ [TestPage] 扫描流错误: $error');
          setState(() {
            _errorMessage = '设备扫描异常: $error';
            _isScanning = false;
          });
        },
        onDone: () {
          Logger.log('🏁 [TestPage] 扫描流结束');
          setState(() {
            _isScanning = false;
          });
        },
      );
      
      Logger.log('✅ [TestPage] 设备扫描启动成功');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始扫描${_selectedCategory.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      Logger.log('❌ [TestPage] 启动扫描异常: $e');
      setState(() {
        _errorMessage = '启动设备扫描失败: $e';
        _isScanning = false;
      });
    }
  }

  /// 步骤5：停止扫描设备
  Future<void> _stopDeviceScan() async {
    Logger.log('🔘 [TestPage] _stopDeviceScan 按钮被点击');
    
    if (!_isScanning) {
      Logger.log('⚠️ [TestPage] 当前没有在扫描');
      return;
    }
    
    try {
      Logger.log('⏳ [TestPage] 调用停止扫描');
      await OmronHealthPlugin.instance.stopScan();
      
      setState(() {
        _isScanning = false;
      });
      
      Logger.log('✅ [TestPage] 停止扫描成功');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已停止扫描'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      Logger.log('❌ [TestPage] 停止扫描异常: $e');
      setState(() {
        _errorMessage = '停止扫描失败: $e';
      });
    }
  }
  
  /// 步骤6：绑定血压计设备
  Future<void> _bindBpDevice(OmronScannedDevice device) async {
    Logger.log('🔘 [TestPage] _bindBpDevice 被调用');
    Logger.log('📦 [TestPage] 设备: ${device.deviceType} - ${device.deviceSerialNum}');
    
    if (_isBinding) {
      Logger.log('⚠️ [TestPage] 已经在绑定中');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已经在绑定设备'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isBinding = true;
      _bindResult = null;
      _errorMessage = null;
    });
    
    try {
      Logger.log('⏳ [TestPage] 调用 bindBpDevice');
      final result = await OmronHealthPlugin.instance.bindBpDevice(
        deviceType: (device.deviceType?.isNotEmpty ?? false) ? device.deviceType! : 'BLEPeripheral',
        deviceSerialNum: device.deviceSerialNum.isNotEmpty ? device.deviceSerialNum : '',
      );
      
      Logger.log('✅ [TestPage] 绑定完成: $result');
      
      setState(() {
        _bindResult = result;
        _isBinding = false;
      });
      
      // 如果绑定成功，保存设备信息到缓存
      if (result.isSuccess) {
        try {
          final syncDevice = OmronSyncDevice(
            deviceType: result.deviceType,
            deviceSerialNum: result.deviceSerialNum,
            deviceId: result.deviceId,
          );
          
          final saved = await OmronDeviceCache.addBoundDevice(syncDevice);
          if (saved) {
            Logger.log('✅ [TestPage] 设备信息已保存到缓存');
          } else {
            Logger.log('⚠️ [TestPage] 设备已存在缓存中');
          }
        } catch (e) {
          Logger.log('❌ [TestPage] 保存设备信息失败: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSuccess ? Colors.green : Colors.red,
          ),
        );
      }
      
    } catch (e) {
      Logger.log('❌ [TestPage] 绑定异常: $e');
      setState(() {
        _errorMessage = '绑定设备失败: $e';
        _isBinding = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('绑定失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMRON SDK 测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 跳转到同步扫描测试页面
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '同步扫描测试',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OmronSyncScanTestPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            const Text(
              'SDK 初始化参数',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // AppKey 输入
            TextField(
              controller: _appKeyController,
              decoration: const InputDecoration(
                labelText: 'App Key *',
                hintText: '请输入应用密钥',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // EkiKey 输入
            // TextField(
            //   controller: _ekiKeyController,
            //   decoration: const InputDecoration(
            //     labelText: 'Eki Key *',
            //     hintText: '请输入设备密钥',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // const SizedBox(height: 12),

            // PackageName 输入
            TextField(
              controller: _packageNameController,
              decoration: const InputDecoration(
                labelText: 'Package Name *',
                hintText: '应用包名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // PackageSecret 输入
            TextField(
              controller: _packageSecretController,
              decoration: const InputDecoration(
                labelText: 'Package Secret *',
                hintText: '请输入应用秘钥',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            // License 输入（可选）
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'License（可选）',
                hintText: '离线授权文件',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // ThirdUserId 输入（可选）
            TextField(
              controller: _thirdUserIdController,
              decoration: const InputDecoration(
                labelText: 'Third User ID（可选）',
                hintText: '第三方用户识别码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 步骤1：初始化SDK按钮
            ElevatedButton(
              onPressed: _isInitializing ? null : _initializeSdk,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _initSdkSuccess ? Colors.green : null,
              ),
              child: _isInitializing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_initSdkSuccess) 
                          const Icon(Icons.check_circle, size: 20)
                        else
                          const Text('1'),
                        const SizedBox(width: 8),
                        const Text(
                          '初始化 SDK (仅Android需要)',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // 步骤2：注册SDK按钮
            ElevatedButton(
              onPressed: _isRegistering ? null : _registerSdk,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isRegistering
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('2'),
                        SizedBox(width: 8),
                        Text(
                          '注册 SDK',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // 步骤3：监听连接状态按钮
            ElevatedButton(
              onPressed: _isListening ? null : _startConnectionListener,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isListening ? Colors.blue : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isListening) 
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Text('3'),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? '正在监听连接状态...' : '开始监听连接状态',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Divider(),
            const SizedBox(height: 16),
            
            // 设备扫描区域
            const Text(
              '设备扫描',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 设备类别选择
            Row(
              children: [
                const Text(
                  '设备类别:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<OmronDeviceCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: OmronDeviceCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(category.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isScanning ? null : (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 扫描控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startDeviceScan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isScanning ? Colors.green : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isScanning)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          const Text('4'),
                        const SizedBox(width: 8),
                        Text(
                          _isScanning ? '正在扫描...' : '开始扫描设备',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? _stopDeviceScan : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '停止扫描',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 扫描结果显示
            if (_isScanning || _scannedDevices.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '扫描到的设备 (${_scannedDevices.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_scannedDevices.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _scannedDevices.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('清空'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _scannedDevices.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                '正在搜索设备...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _scannedDevices.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = _scannedDevices[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.bluetooth,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            title: Text(
                              device.deviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (device.deviceSerialNum.isNotEmpty)
                                  Text('序列号: ${device.deviceSerialNum}'),
                                if (device.rssi != null)
                                  Text('信号强度: ${device.rssiDescription} (${device.rssi} dBm)'),
                                if (device.category != null)
                                  Text('类别: ${device.category}'),
                              ],
                            ),
                            trailing: ElevatedButton.icon(
                              onPressed: _isBinding ? null : () => _bindBpDevice(device),
                              icon: const Icon(Icons.link, size: 16),
                              label: const Text('绑定'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
            ],

            // 当前连接状态显示
            if (_currentStatus != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '当前连接状态',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentStatus!.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _currentStatus!.color),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentStatus!.icon,
                      color: _currentStatus!.color,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentStatus!.message,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _currentStatus!.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_lastStatusTime != null)
                            Text(
                              '时间: ${_lastStatusTime!.hour.toString().padLeft(2, '0')}:${_lastStatusTime!.minute.toString().padLeft(2, '0')}:${_lastStatusTime!.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 状态历史记录
            if (_statusHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '状态历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _statusHistory.length,
                  itemBuilder: (context, index) {
                    final item = _statusHistory[index];
                    final status = item['status'] as OmronConnectionStatus;
                    final time = item['time'] as DateTime;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        status.icon,
                        color: status.color,
                        size: 20,
                      ),
                      title: Text(
                        status.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: status.color,
                        ),
                      ),
                      trailing: Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 结果显示区域
            if (_registerResult != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '注册结果',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _registerResult!.isSuccess 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _registerResult!.isSuccess 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _registerResult!.isSuccess 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _registerResult!.isSuccess 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _registerResult!.isSuccess ? '成功' : '失败',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _registerResult!.isSuccess 
                                ? Colors.green.shade900 
                                : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '状态码: ${_registerResult!.status.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '信息: ${_registerResult!.message}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            
            // 绑定结果显示区域
            if (_bindResult != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '绑定结果',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bindResult!.isSuccess 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _bindResult!.isSuccess 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _bindResult!.isSuccess 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _bindResult!.isSuccess 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _bindResult!.message,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _bindResult!.isSuccess 
                                  ? Colors.green.shade900 
                                  : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('设备类型', _bindResult!.deviceType),
                    _buildInfoRow('设备序列号', _bindResult!.deviceSerialNum),
                    if (_bindResult!.deviceId != null)
                      _buildInfoRow('设备ID', _bindResult!.deviceId!),
                    
                    // 设备信息
                    if (_bindResult!.deviceInfo != null) ...[
                      const Divider(),
                      const Text(
                        '设备信息',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_bindResult!.deviceInfo!.modelName != null)
                        _buildInfoRow('型号名称', _bindResult!.deviceInfo!.modelName!),
                      if (_bindResult!.deviceInfo!.modelNumber != null)
                        _buildInfoRow('型号编号', _bindResult!.deviceInfo!.modelNumber!),
                      if (_bindResult!.deviceInfo!.serialNumber != null)
                        _buildInfoRow('序列号', _bindResult!.deviceInfo!.serialNumber!),
                      if (_bindResult!.deviceInfo!.manufacturerName != null)
                        _buildInfoRow('制造商', _bindResult!.deviceInfo!.manufacturerName!),
                      if (_bindResult!.deviceInfo!.hardwareVersion != null)
                        _buildInfoRow('硬件版本', _bindResult!.deviceInfo!.hardwareVersion!),
                      if (_bindResult!.deviceInfo!.softwareVersion != null)
                        _buildInfoRow('软件版本', _bindResult!.deviceInfo!.softwareVersion!),
                      if (_bindResult!.deviceInfo!.firmwareVersion != null)
                        _buildInfoRow('固件版本', _bindResult!.deviceInfo!.firmwareVersion!),
                      if (_bindResult!.deviceInfo!.batteryLevel != null)
                        _buildInfoRow('电池电量', '${_bindResult!.deviceInfo!.batteryLevel}% (${_bindResult!.deviceInfo!.batteryLevelDescription})'),
                      if (_bindResult!.deviceInfo!.powerSupplyMode != null)
                        _buildInfoRow('供电模式', _bindResult!.deviceInfo!.powerSupplyMode!),
                      if (_bindResult!.deviceInfo!.systemID != null && _bindResult!.deviceInfo!.systemID!.isNotEmpty)
                        _buildInfoRow('系统ID', _bindResult!.deviceInfo!.systemID!),
                    ],
                    
                    // 血压数据列表
                    if (_bindResult!.bpDataList != null && _bindResult!.bpDataList!.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        '测量数据 (共${_bindResult!.dataCount}条)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bindResult!.bpDataList!.length,
                        itemBuilder: (context, index) {
                          final bpData = _bindResult!.bpDataList![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '测量 ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          bpData.bloodPressureLevel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('血压', bpData.formattedBloodPressure),
                                  _buildInfoRow('脉搏', bpData.formattedPulse),
                                  _buildInfoRow('测量时间', bpData.formattedMeasureTime),
                                  _buildInfoRow('测量用户', bpData.userName),
                                  if (bpData.hasArrhythmia)
                                    const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text('检测到心律不齐', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                      ],
                                    ),
                                  if (bpData.hasBodyMovement)
                                    const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text('检测到身体移动', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                      ],
                                    ),
                                  if (bpData.hasCuffWrapIssue)
                                    const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange, size: 16),
                                        SizedBox(width: 4),
                                        Text('袖带佩戴不当', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                      ],
                                    ),
                                  if (bpData.hasAfib)
                                    const Row(
                                      children: [
                                        Icon(Icons.favorite, color: Colors.purple, size: 16),
                                        SizedBox(width: 4),
                                        Text('检测到房颤', style: TextStyle(fontSize: 12, color: Colors.purple)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // 错误信息显示
            if (_errorMessage != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '错误',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // 说明文字
            const Text(
              '使用说明',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '步骤：\n'
              '1. 点击"初始化SDK"按钮（仅Android需要，iOS会自动跳过）\n'
              '2. 填写所有必填参数\n'
              '3. 点击"注册SDK"按钮完成注册\n'
              '4. 点击"开始监听连接状态"按钮启动蓝牙状态监听\n'
              '5. 选择设备类别，点击"开始扫描设备"搜索附近的设备\n'
              '6. 首次扫描会请求蓝牙和定位权限，请授予权限\n'
              '7. 扫描到设备后，列表会显示发现的血压计\n'
              '8. 点击设备右侧的"绑定"按钮连接血压计\n'
              '9. 绑定成功后会显示设备信息和历史测量数据\n\n'
              '设备类别说明：\n'
              '• 所有设备 - 扫描所有类型的欧姆龙设备\n'
              '• 血压计 - 只扫描血压计设备\n'
              '• 血糖仪 - 只扫描血糖仪设备\n'
              '• 体脂仪 - 只扫描体脂秤设备\n'
              '• 血氧仪 - 只扫描血氧仪设备\n\n'
              '连接状态说明：\n'
              '• 开始扫描设备 - SDK正在搜索附近的蓝牙设备\n'
              '• 开始连接设备 - 找到设备并开始建立连接\n'
              '• 开始数据同步 - 连接成功，正在同步数据\n'
              '• 数据同步成功 - 数据已成功读取\n'
              '• 数据同步失败 - 数据读取过程中出现错误\n'
              '• 设备已断开连接 - 蓝牙连接已断开\n\n'
              '权限说明：\n'
              '• Android需要蓝牙扫描权限（BLUETOOTH_SCAN）\n'
              '• Android需要蓝牙连接权限（BLUETOOTH_CONNECT）\n'
              '• Android 11及以下需要定位权限（LOCATION）\n'
              '• iOS需要蓝牙权限（Bluetooth）\n'
              '• 首次使用时会自动弹出权限申请\n\n'
              '注意事项：\n'
              '• Android需要先将 OmronBleSdk.jar 放入 android/app/libs/ 目录\n'
              '• iOS需要先将 OMRONLib.framework 集成到项目\n'
              '• 带 * 的字段为必填项\n'
              '• Package Name 应与欧姆龙开放平台注册的包名一致\n'
              '• 所有密钥信息请从欧姆龙开放平台获取\n'
              '• 扫描过程中无法切换设备类别，需要先停止扫描\n'
              '• 扫描会自动去重，相同序列号的设备只显示一次\n'
              '• 扫描默认超时时间为60秒，可在代码中自定义',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建信息行辅助方法
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

