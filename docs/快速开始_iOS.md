# 🚀 iOS 集成快速开始

## ✅ 好消息

iOS 端 OMRONLib.framework 配置已经全部完成!编译测试通过! 🎉

## 📋 配置清单

- ✅ podspec 配置完成
- ✅ Framework 文件已放置
- ✅ Swift 代码已更新
- ✅ 编译成功验证

## ⚠️ 重要提醒

**当前 framework 只支持真机,不支持模拟器!**

必须使用真实的 iPhone/iPad 设备进行测试。

## 🎯 如何运行

### 第一步: 连接 iPhone

用数据线将 iPhone 连接到 Mac 电脑。

### 第二步: 配置签名 (首次需要)

打开 Xcode:
```bash
cd example/ios
open Runner.xcworkspace
```

在 Xcode 中:
1. 选择 Runner 项目
2. Signing & Capabilities 标签
3. 勾选 "Automatically manage signing"
4. 选择你的 Apple ID Team

### 第三步: 运行

```bash
cd example

# 查看设备
flutter devices

# 运行到 iPhone
flutter run
```

### 第四步: 信任证书 (首次需要)

在 iPhone 上:
- 设置 → 通用 → VPN与设备管理
- 点击信任你的开发者应用

## 📱 测试代码

```dart
import 'package:omron_health_plugin/omron_health_plugin.dart';

// 初始化 SDK
await OmronPlugin.instance.initSdk();

// 注册
final result = await OmronPlugin.instance.register(
  config: OmronConfig(
    appKey: '你的appKey',
    packageName: '你的包名',
    packageSecret: '你的密钥',
    license: '你的license',
  ),
);

if (result.status == OmronStatus.success) {
  print('✅ 注册成功');
} else {
  print('❌ 注册失败: ${result.message}');
}
```

## 🔍 验证 Framework

运行检查脚本:
```bash
cd ios
./check_framework.sh
```

输出应该显示:
```
✅ Frameworks 目录存在
✅ OMRONLib.framework 存在
✅ framework 二进制文件存在
📱 支持的架构: arm64
✅ podspec 已配置 vendored_frameworks
```

## 🐛 常见问题

### Q: 为什么不能在模拟器上运行?

**A**: 当前 framework 只包含 arm64 架构(真机),不包含模拟器架构。如需模拟器支持,请联系 OMRON 官方获取完整版 SDK。

### Q: 编译错误 "Cannot find type 'OMRONLib...'"

**A**: 重新安装 Pod:
```bash
cd example/ios
rm -rf Pods Podfile.lock
pod install
```

### Q: 签名错误

**A**: 在 Xcode 中配置好 Team (Apple ID)。免费账号也可以用于开发测试。

### Q: 找不到设备

**A**: 
1. 确保 iPhone 已连接并信任电脑
2. 运行 `flutter devices` 查看设备列表
3. 检查 iPhone 是否解锁

## 📚 详细文档

如需了解更多细节,请查看:

- 📘 [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - 完整配置说明
- 📗 [SETUP_iOS.md](SETUP_iOS.md) - 设置指南
- 📙 [ios/SIMULATOR_NOTICE.md](ios/SIMULATOR_NOTICE.md) - 模拟器说明

## 💡 提示

1. **开发建议**: 准备一台测试 iPhone,专门用于 OMRON 设备功能开发
2. **蓝牙权限**: 确保在 Info.plist 中配置了蓝牙权限
3. **位置权限**: iOS 扫描蓝牙设备需要位置权限
4. **日志查看**: 使用 `flutter logs` 查看实时日志

## 🎉 完成

现在你可以在真机上开发和测试 OMRON 健康设备功能了!

如有问题,欢迎查看详细文档或提 Issue。

