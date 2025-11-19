# omron_health_plugin

[![pub package](https://img.shields.io/pub/v/omron_health_plugin.svg)](https://pub.dev/packages/omron_health_plugin)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue.svg)](https://github.com/your-username/omron_health_plugin)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

一个用于集成 OMRON（欧姆龙）健康设备的 Flutter 插件，支持通过蓝牙连接血压计等健康监测设备，实现设备扫描、配对绑定和数据同步功能。

## ✨ 功能特性

- 🔍 **设备扫描** - 支持蓝牙设备扫描和发现
- 🔗 **设备绑定** - 快速配对和绑定 OMRON 设备
- 📊 **数据同步** - 自动同步血压、心率等健康数据
- 📱 **双平台支持** - 完整支持 Android 和 iOS 平台
- 🔄 **实时监听** - 连接状态实时反馈
- 💾 **本地缓存** - 支持已绑定设备的本地管理
- 🎯 **两种扫描模式** - 绑定扫描和同步扫描

## 📱 支持的设备

目前支持 OMRON 系列蓝牙血压计，包括但不限于：
- OMRON 血压计（蓝牙版本）
- 其他支持 OMRON SDK 的健康设备

## 🚀 快速开始

### 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  omron_health_plugin: ^0.0.1
  permission_handler: ^11.3.1  # 权限处理
```

### 权限配置

**Android** - 在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**iOS** - 在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接 OMRON 健康设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要使用蓝牙连接 OMRON 健康设备</string>
```

### 最小示例

```dart
import 'package:omron_health_plugin/omron_health_plugin.dart';
import 'package:omron_health_plugin/omron/omron_config.dart';

// 1. 初始化 SDK (仅 Android 需要)
await OmronHealthPlugin.instance.initSdk();

// 2. 注册配置
final config = OmronConfig(
  appKey: 'YOUR_APP_KEY',
  packageName: 'com.example.app',
  packageSecret: 'YOUR_SECRET',
);
final result = await OmronHealthPlugin.instance.register(config);

// 3. 扫描设备
OmronHealthPlugin.instance
    .startBindScan(OmronDeviceCategory.bloodPressure)
    .listen((event) {
  if (event.isDeviceFound) {
    print('发现设备: ${event.device?.deviceName}');
  }
});

// 4. 绑定设备
final bindResult = await OmronHealthPlugin.instance.bindBpDevice(
  deviceType: 'BLEPeripheral',
  deviceSerialNum: 'DEVICE_MAC_ADDRESS',
);

if (bindResult.isSuccess) {
  print('绑定成功，获取到 ${bindResult.dataCount} 条数据');
}
```

## 🔧 平台配置

### Android 配置

#### 1. 添加 OMRON SDK

将 `OmronBleSdk.jar` 文件放置到 `android/libs/` 目录（已包含在插件中）。

#### 2. Gradle 配置

插件已自动配置以下依赖，无需手动添加：

```gradle
dependencies {
    implementation files("libs/OmronBleSdk.jar")
    implementation 'com.google.code.gson:gson:2.8.6'
    implementation 'commons-codec:commons-codec:1.14'
    implementation 'com.squareup.okhttp3:okhttp:3.4.2'
}
```

#### 3. 最低版本要求

```gradle
android {
    compileSdk 36
    defaultConfig {
        minSdk 24
        targetSdk 36
    }
}
```

#### 4. 混淆规则（如果启用 ProGuard）

在 `android/app/proguard-rules.pro` 中添加：

```
-keep class jp.co.omron.** { *; }
-dontwarn jp.co.omron.**
```

### iOS 配置

#### 1. Framework 已配置完成

OMRON SDK (`OMRONLib.framework`) 已集成到插件中，位于 `ios/Frameworks/` 目录。

#### 2. 最低版本要求

```ruby
platform :ios, '13.0'
```

#### 3. ⚠️ 重要提示

**iOS Framework 仅支持真机，不支持模拟器！**

必须使用真实的 iPhone/iPad 设备进行开发和测试。

详细的 iOS 配置说明请参考：[快速开始_iOS.md](./快速开始_iOS.md)

## 📚 核心 API

### 初始化与注册

| 方法 | 说明 | 平台 |
|------|------|------|
| `initSdk()` | 初始化 SDK | Android only |
| `register(config)` | 注册配置信息 | Android & iOS |

### 设备扫描

| 方法 | 说明 | 返回类型 |
|------|------|----------|
| `startBindScan(category, timeout)` | 开始绑定扫描 | `Stream<OmronScanEvent>` |
| `startSyncScan(devices, scanPeriod)` | 开始同步扫描 | `Stream<OmronScanEvent>` |
| `stopScan()` | 停止绑定扫描 | `Future<void>` |
| `stopSyncScan()` | 停止同步扫描 | `Future<void>` |

### 设备操作

| 方法 | 说明 | 返回类型 |
|------|------|----------|
| `bindBpDevice({deviceType, deviceSerialNum})` | 绑定血压计设备 | `Future<OmronBindResult>` |
| `getBpDeviceData({deviceType, deviceSerialNum})` | 同步血压数据 | `Future<OmronBindResult>` |

### 状态监听

| 方法 | 说明 | 返回类型 |
|------|------|----------|
| `startConnectionStatusListener()` | 监听连接状态 | `Stream<OmronConnectionStatus>` |

## 💡 使用示例

### 完整工作流程

```dart
import 'package:flutter/material.dart';
import 'package:omron_health_plugin/omron_health_plugin.dart';
import 'package:omron_health_plugin/omron/omron_config.dart';
import 'package:omron_health_plugin/omron/omron_device_category.dart';
import 'package:permission_handler/permission_handler.dart';

class OmronExample extends StatefulWidget {
  @override
  _OmronExampleState createState() => _OmronExampleState();
}

class _OmronExampleState extends State<OmronExample> {
  final _plugin = OmronHealthPlugin.instance;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  // 1. 初始化流程
  Future<void> _initialize() async {
    // 请求蓝牙权限
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    
    // 初始化 SDK (Android)
    try {
      await _plugin.initSdk();
      print('SDK 初始化成功');
    } catch (e) {
      print('SDK 初始化失败: $e');
    }
    
    // 注册配置
    final config = OmronConfig(
      appKey: 'YOUR_APP_KEY',
      packageName: 'com.example.app',
      packageSecret: 'YOUR_SECRET',
      licenseKey: 'YOUR_LICENSE', // iOS 需要
    );
    
    final result = await _plugin.register(config);
    if (result.isSuccess) {
      print('注册成功');
    }
  }
  
  // 2. 扫描设备
  void _scanDevices() {
    _plugin.startBindScan(OmronDeviceCategory.bloodPressure, timeout: 30)
        .listen(
      (event) {
        if (event.isDeviceFound) {
          final device = event.device!;
          print('发现设备: ${device.deviceName}');
          print('序列号: ${device.deviceSerialNum}');
        } else if (event.isScanFinished) {
          print('扫描完成');
        } else if (event.isScanError) {
          print('扫描错误: ${event.message}');
        }
      },
      onError: (error) => print('扫描异常: $error'),
    );
  }
  
  // 3. 绑定设备
  Future<void> _bindDevice(String deviceSerialNum) async {
    try {
      final result = await _plugin.bindBpDevice(
        deviceType: 'BLEPeripheral',
        deviceSerialNum: deviceSerialNum,
      );
      
      if (result.isSuccess) {
        print('绑定成功');
        print('数据条数: ${result.dataCount}');
        
        // 处理血压数据
        for (var data in result.bpDataList) {
          print('收缩压: ${data.systolic}');
          print('舒张压: ${data.diastolic}');
          print('心率: ${data.heartRate}');
          print('测量时间: ${data.measurementDate}');
        }
      } else {
        print('绑定失败: ${result.message}');
      }
    } catch (e) {
      print('绑定异常: $e');
    }
  }
  
  // 4. 同步已绑定设备的数据
  Future<void> _syncDeviceData(String deviceSerialNum) async {
    try {
      final result = await _plugin.getBpDeviceData(
        deviceType: 'BLEPeripheral',
        deviceSerialNum: deviceSerialNum,
      );
      
      if (result.isSuccess) {
        print('同步成功，获取到 ${result.dataCount} 条新数据');
      }
    } catch (e) {
      print('同步失败: $e');
    }
  }
  
  // 5. 监听连接状态
  void _startStatusListener() {
    _plugin.startConnectionStatusListener().listen((status) {
      print('连接状态: ${status.status}');
      print('消息: ${status.message}');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OMRON 设备测试')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _scanDevices,
              child: Text('扫描设备'),
            ),
            ElevatedButton(
              onPressed: _startStatusListener,
              child: Text('监听状态'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 同步扫描示例

同步扫描用于周期性检测已绑定设备的在线状态：

```dart
// 准备已绑定设备列表
final devices = [
  OmronSyncDevice(
    deviceType: 'BLEPeripheral',
    deviceSerialNum: '00:11:22:33:44:55',
  ),
];

// 开始同步扫描，每 60 秒一个周期
_plugin.startSyncScan(devices, scanPeriod: 60).listen((event) {
  if (event.isDeviceFound) {
    print('检测到已绑定设备: ${event.device?.deviceName}');
    // 可以立即同步数据
  } else if (event.isScanFinished) {
    print('本轮扫描完成，等待下一轮...');
  }
});

// 停止同步扫描
await _plugin.stopSyncScan();
```

## 📖 参考资源

### 官方文档

- [OMRON Android SDK 集成文档](https://public.omronhealthcare.com.cn/b2bsdk/doc/%E9%80%9A%E4%BF%A1SDK%20android%E9%9B%86%E6%88%90%E6%96%87%E6%A1%A3.html)
- [OMRON iOS SDK 集成文档](https://public.omronhealthcare.com.cn/b2bsdk/doc/%E9%80%9A%E4%BF%A1SDK%20iOS%E9%9B%86%E6%88%90%E6%96%87%E6%A1%A3.html)

### 项目文档

- [快速开始_iOS.md](./快速开始_iOS.md) - iOS 平台详细配置指南
- [CHANGELOG.md](./CHANGELOG.md) - 版本更新日志

### 示例项目

完整的示例应用位于 [example](./example) 目录，包含：
- 完整的设备扫描、绑定、同步流程
- 已绑定设备的本地缓存管理
- 连接状态实时监听
- 错误处理和用户提示

运行示例：

```bash
cd example
flutter run
```

## ❓ 常见问题

### 1. iOS 模拟器无法运行

**原因：** OMRON SDK Framework 不支持模拟器架构。

**解决方案：** 必须使用真实 iPhone/iPad 设备进行开发和测试。

### 2. Android 蓝牙权限问题

**原因：** Android 12+ 需要新的蓝牙权限。

**解决方案：** 确保申请了 `BLUETOOTH_SCAN` 和 `BLUETOOTH_CONNECT` 权限，并在运行时请求授权。

### 3. 设备扫描不到

**检查项：**
- ✅ 蓝牙是否已开启
- ✅ 权限是否已授权
- ✅ 设备是否在配对模式
- ✅ SDK 是否已正确初始化和注册

### 4. 如何获取 AppKey 和 License

请联系 OMRON 官方获取商业授权：
- 访问 OMRON 健康医疗官网
- 申请 B2B SDK 开发者账号
- 获取必要的授权密钥

### 5. Android 和 iOS 数据格式差异

**设备序列号格式：**
- **Android**: 通常是蓝牙 MAC 地址，如 `00:11:22:33:44:55`
- **iOS**: 设备唯一标识符，如 `E0B99180439E`

**同步数据时的标识符：**
- **Android**: 使用 `deviceName;macAddress` 格式
- **iOS**: 使用绑定时返回的 `deviceSerialNum`

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

在提交 PR 之前，请确保：
- 代码通过 `flutter analyze` 检查
- 添加了必要的测试
- 更新了相关文档

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

## 🔗 相关链接

- [pub.dev](https://pub.dev/packages/omron_health_plugin)
- [GitHub](https://github.com/zhoujianshun/omron_health_plugin)
- [问题反馈](https://github.com/zhoujianshun/omron_health_plugin/issues)

---

**注意事项：**
- ⚠️ 本插件仅用于集成 OMRON SDK，不提供医疗诊断建议
- ⚠️ 使用前请确保已获得 OMRON 官方授权
- ⚠️ 请遵守相关医疗设备法规和数据隐私法规
