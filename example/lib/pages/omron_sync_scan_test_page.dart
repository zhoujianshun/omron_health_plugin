import 'package:flutter/material.dart';
import 'package:omron_health_plugin/omron/omron_scan_event.dart';
import 'dart:async';

import 'package:omron_health_plugin/omron/omron_scanned_device.dart';
import 'package:omron_health_plugin/omron/omron_sync_device.dart';
import 'package:omron_health_plugin/omron_health_plugin.dart';
import 'package:omron_health_plugin_example/utils/omron_device_cache.dart';
import 'package:omron_health_plugin_example/utils/logger.dart';


/// Omron同步扫描测试页面
class OmronSyncScanTestPage extends StatefulWidget {
  const OmronSyncScanTestPage({super.key});

  @override
  State<OmronSyncScanTestPage> createState() => _OmronSyncScanTestPageState();
}

class _OmronSyncScanTestPageState extends State<OmronSyncScanTestPage> {
  // 同步扫描相关
  bool _isScanning = false;
  final List<OmronScannedDevice> _scannedDevices = [];
  StreamSubscription<OmronScanEvent<OmronScannedDevice>>? _scanSubscription;
  int _scanPeriod = 60; // 默认扫描周期60秒
  
  // 已绑定设备列表（用于同步扫描，从缓存加载）
  final List<OmronSyncDevice> _boundDevices = [];
  
  // 所有可用的已绑定设备（从缓存读取）
  List<OmronSyncDevice> _allBoundDevices = [];
  
  @override
  void initState() {
    super.initState();
    _loadBoundDevices();
  }
  
  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
  
  /// 从缓存加载已绑定的设备
  Future<void> _loadBoundDevices() async {
    try {
      final devices = await OmronDeviceCache.getBoundDevices();
      setState(() {
        _allBoundDevices = devices;
      });
      Logger.info('从缓存加载了 ${devices.length} 个已绑定设备', tag: 'SyncScan');
    } catch (e) {
      Logger.error('加载已绑定设备失败', tag: 'SyncScan', error: e);
      _showSnackBar('加载已绑定设备失败', isError: true);
    }
  }
  
  /// 开始同步扫描
  Future<void> _startSyncScan() async {
    if (_boundDevices.isEmpty) {
      _showSnackBar('请先添加要扫描的设备', isError: true);
      return;
    }
    
    try {
      setState(() {
        _isScanning = true;
        _scannedDevices.clear();
      });
      
      Logger.info('开始同步扫描，设备数: ${_boundDevices.length}, 周期: $_scanPeriod秒', tag: 'SyncScan');
      
      // 取消之前的订阅
      await _scanSubscription?.cancel();

      // 开始同步扫描
      _scanSubscription = OmronHealthPlugin.instance
          .startSyncScan(_boundDevices, scanPeriod: _scanPeriod)
          .listen(
        (event) {
          // 处理扫描事件
          if (event.isDeviceFound) {
            // 设备发现事件
            final device = event.device as OmronScannedDevice;
            Logger.info('扫描到设备: ${device.deviceName} - ${device.deviceSerialNum}', tag: 'SyncScan');
            setState(() {
              // 检查是否已存在，避免重复添加
              final index = _scannedDevices.indexWhere(
                (d) => d.deviceSerialNum == device.deviceSerialNum,
              );
              if (index >= 0) {
                // 更新现有设备信息
                _scannedDevices[index] = device;
              } else {
                // 添加新设备
                _scannedDevices.add(device);
              }
            });
          } else if (event.isScanFinished) {
            // 扫描完成事件
            Logger.info('同步扫描周期结束: ${event.message}', tag: 'SyncScan');
            setState(() {
              _isScanning = false;
            });
            _showSnackBar('${event.message}，共发现 ${_scannedDevices.length} 个设备');
          } else if (event.isScanError) {
            // 扫描错误事件
            Logger.error('同步扫描错误: ${event.message}', tag: 'SyncScan');
            setState(() {
              _isScanning = false;
            });
            _showSnackBar(event.message ?? '扫描失败', isError: true);
          }
        },
        onError: (error) {
          Logger.error('同步扫描异常', tag: 'SyncScan', error: error);
          _showSnackBar('扫描异常: $error', isError: true);
          setState(() {
            _isScanning = false;
          });
        },
        onDone: () {
          Logger.info('同步扫描流结束', tag: 'SyncScan');
          setState(() {
            _isScanning = false;
          });
        },
      );
      
      _showSnackBar('开始同步扫描...');
    } catch (e) {
      Logger.error('启动同步扫描失败', tag: 'SyncScan', error: e);
      _showSnackBar('启动扫描失败: $e', isError: true);
      setState(() {
        _isScanning = false;
      });
    }
  }
  
  /// 停止同步扫描
  Future<void> _stopSyncScan() async {
    try {
      await OmronHealthPlugin.instance.stopSyncScan();
      await _scanSubscription?.cancel();
      setState(() {
        _isScanning = false;
      });      
      _showSnackBar('已停止扫描');
    } catch (e) {
      Logger.error('停止扫描失败', tag: 'SyncScan', error: e);
      _showSnackBar('停止扫描失败: $e', isError: true);
    }
  }
  
  /// 添加绑定设备到扫描列表
  void _addBoundDevice(OmronSyncDevice device) {
    // 检查是否已存在
    final exists = _boundDevices.any(
      (d) => d.deviceSerialNum == device.deviceSerialNum,
    );
    
    if (!exists) {
      setState(() {
        _boundDevices.add(device);
      });
      _showSnackBar('已添加设备到扫描列表');
    } else {
      _showSnackBar('设备已在扫描列表中', isError: true);
    }
  }
  
  /// 移除绑定设备
  void _removeBoundDevice(OmronSyncDevice device) {
    setState(() {
      _boundDevices.remove(device);
    });
    _showSnackBar('已移除设备');
  }
  
  /// 清空扫描结果
  void _clearScannedDevices() {
    setState(() {
      _scannedDevices.clear();
    });
    _showSnackBar('已清空扫描结果');
  }
  
  /// 同步设备数据
  Future<void> _syncDeviceData(OmronScannedDevice device) async {
    Logger.info('开始同步设备数据: ${device.deviceName}', tag: 'SyncScan');
    
    try {
      // 查找对应的绑定设备信息
      final syncDevice = _boundDevices.firstWhere(
        (d) => d.deviceSerialNum == device.deviceSerialNum,
        orElse: () => OmronSyncDevice(
          deviceType: device.deviceType ?? 'BLEPeripheral',
          deviceSerialNum: device.deviceSerialNum,
          deviceName: device.deviceName,
        ),
      );
      
      _showSnackBar('正在同步数据...');
      
      // 调用同步数据接口
      final result = await OmronHealthPlugin.instance.getBpDeviceData(
        deviceType: syncDevice.deviceType,
        deviceSerialNum: syncDevice.getSyncIdentifier(),
      );
      
      if (result.isSuccess) {
        Logger.info('同步成功，获取到 ${result.dataCount} 条数据', tag: 'SyncScan');
        
        // 显示同步结果对话框
        if (mounted) {
          _showSyncResultDialog(device, result);
        }
      } else {
        Logger.error('同步失败: ${result.message}', tag: 'SyncScan');
        _showSnackBar('同步失败: ${result.message}', isError: true);
      }
    } catch (e) {
      Logger.error('同步数据异常', tag: 'SyncScan', error: e);
      _showSnackBar('同步失败: $e', isError: true);
    }
  }
  
  /// 显示同步结果对话框
  void _showSyncResultDialog(OmronScannedDevice device, dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('同步成功'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设备: ${device.deviceName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('获取到 ${result.dataCount} 条血压数据'),
              const Divider(height: 24),
              if (result.bpDataList.isNotEmpty) ...[
                const Text(
                  '最近测量数据：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.bpDataList.take(3).map((data) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${data.systolic}/${data.diastolic} mmHg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.monitor_heart, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text('脉搏: ${data.pulse} bpm'),
                          ],
                        ),
                        Text(
                          '时间: ${data.formattedMeasureTime}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (data.hasArrhythmia)
                          Chip(
                            label: Text('心律不齐', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.orange.shade100,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  /// 显示提示消息
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 构建设备卡片
  Widget _buildDeviceCard(OmronScannedDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansiblePanel(
        header: ListTile(
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
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            device.deviceSerialNum,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.rssi != null && device.rssi! > -70
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  device.rssiDescription,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: device.rssi != null && device.rssi! > -70
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        expandedContent: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('设备类型', device.deviceType ?? '未知'),
              _buildInfoRow('序列号', device.deviceSerialNum),
              if (device.userIndex != null)
                _buildInfoRow('用户索引', device.userIndex!),
              if (device.category != null)
                _buildInfoRow('设备类别', device.category!),
              if (device.rssi != null)
                _buildInfoRow('信号强度', '${device.rssi} dBm'),
              _buildInfoRow(
                '扫描时间',
                '${device.scannedAt.hour.toString().padLeft(2, '0')}:'
                '${device.scannedAt.minute.toString().padLeft(2, '0')}:'
                '${device.scannedAt.second.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 12),
              // 同步数据按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _syncDeviceData(device),
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('同步数据'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步扫描测试'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 扫描控制区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 扫描周期设置
                Row(
                  children: [
                    const Text(
                      '扫描周期:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: _scanPeriod.toDouble(),
                        min: 10,
                        max: 300,
                        divisions: 29,
                        label: '$_scanPeriod秒',
                        onChanged: _isScanning
                            ? null
                            : (value) {
                                setState(() {
                                  _scanPeriod = value.toInt();
                                });
                              },
                      ),
                    ),
                    Text(
                      '$_scanPeriod秒',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 绑定设备数量显示
                Row(
                  children: [
                    const Icon(Icons.devices, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '已添加 ${_boundDevices.length} 个设备',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isScanning ? null : _showAddDeviceDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加设备'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 扫描按钮
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _startSyncScan,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isScanning ? '扫描中...' : '开始扫描'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? _stopSyncScan : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('停止扫描'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 扫描结果标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.list, size: 20),
                const SizedBox(width: 8),
                Text(
                  '扫描结果 (${_scannedDevices.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_scannedDevices.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearScannedDevices,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('清空'),
                  ),
              ],
            ),
          ),
          
          // 扫描结果列表
          Expanded(
            child: _scannedDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning ? Icons.search : Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning ? '正在扫描设备...' : '暂无扫描结果',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!_isScanning && _boundDevices.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '请先添加要扫描的设备',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scannedDevices.length,
                    itemBuilder: (context, index) {
                      return _buildDeviceCard(_scannedDevices[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  /// 显示添加设备对话框
  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加扫描设备'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '从已绑定设备中选择：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: '刷新列表',
                    onPressed: () {
                      Navigator.pop(context);
                      _loadBoundDevices();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _showAddDeviceDialog();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_allBoundDevices.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices_other,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无已绑定设备',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请先在主测试页面绑定设备',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._allBoundDevices.map((device) {
                  final isAdded = _boundDevices.any(
                    (d) => d.deviceSerialNum == device.deviceSerialNum,
                  );
                  return ListTile(
                    leading: Icon(
                      Icons.bluetooth,
                      color: isAdded ? Colors.grey : Colors.blue,
                    ),
                    title: Text(device.deviceSerialNum),
                    subtitle: Text(device.deviceType),
                    trailing: isAdded
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: isAdded
                        ? null
                        : () {
                            Navigator.pop(context);
                            _addBoundDevice(device);
                          },
                  );
                }),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '当前已添加设备：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_boundDevices.isEmpty)
                const Text(
                  '暂无设备',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._boundDevices.map((device) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.devices, size: 20),
                    title: Text(device.deviceSerialNum),
                    subtitle: Text(device.deviceType),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        _removeBoundDevice(device);
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          if (_allBoundDevices.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要清空所有已绑定设备的缓存吗？此操作不可恢复。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  final cleared = await OmronDeviceCache.clearBoundDevices();
                  if (cleared) {
                    setState(() {
                      _allBoundDevices.clear();
                      _boundDevices.clear();
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _showSnackBar('已清空所有已绑定设备缓存');
                    }
                  } else {
                    if (mounted) {
                      _showSnackBar('清空失败', isError: true);
                    }
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('清空缓存'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 可展开面板组件
class ExpansiblePanel extends StatefulWidget {
  final Widget header;
  final Widget expandedContent;
  
  const ExpansiblePanel({
    super.key,
    required this.header,
    required this.expandedContent,
  });
  
  @override
  State<ExpansiblePanel> createState() => _ExpansiblePanelState();
}

class _ExpansiblePanelState extends State<ExpansiblePanel> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Expanded(child: widget.header),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (_isExpanded)
          Column(
            children: [
              const Divider(height: 1),
              widget.expandedContent,
            ],
          ),
      ],
    );
  }
}

