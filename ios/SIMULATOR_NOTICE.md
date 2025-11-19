# ⚠️ 模拟器支持说明

## 🔍 检测结果

当前的 `OMRONLib.framework` **只包含 arm64 架构**,这意味着:

```
架构支持:
✅ arm64 (真机: iPhone 5s 及以后的设备)
❌ x86_64 (Intel 模拟器)
❌ arm64-simulator (Apple Silicon 模拟器)
```

## 📱 影响

- ✅ **可以在真实 iOS 设备上运行**
- ❌ **不能在模拟器上运行** (无论是 Intel Mac 还是 Apple Silicon Mac)

## 🚀 解决方案

### 方案 1: 使用真机测试 (推荐)

```bash
# 连接 iPhone 到电脑
# 查看设备列表
flutter devices

# 在真机上运行
flutter run -d <your-device-id>
```

### 方案 2: 排除模拟器架构 (已配置)

podspec 已经配置了排除模拟器架构,但编译时仍然会失败:

```ruby
s.pod_target_xcconfig = { 
  'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
}
```

### 方案 3: 联系 OMRON 获取完整 Framework

向 OMRON 官方申请包含模拟器架构的 framework 版本:
- x86_64 (Intel Mac 模拟器)
- arm64-simulator (Apple Silicon Mac 模拟器)

完整的 framework 应该支持:
```
Architectures: arm64 x86_64 arm64-simulator
```

## 🛠️ 如何在真机上运行

### 步骤 1: 配置开发者账号

1. 打开 Xcode
2. Preferences → Accounts → 添加 Apple ID
3. 在项目中选择 Team

### 步骤 2: 配置 Bundle ID

在 `example/ios/Runner.xcworkspace` 中:
1. 选择 Runner target
2. Signing & Capabilities
3. 勾选 "Automatically manage signing"
4. 选择你的 Team
5. 修改 Bundle Identifier (如果需要)

### 步骤 3: 信任开发者证书

首次在真机运行时:
1. iPhone 设置 → 通用 → VPN 与设备管理
2. 找到开发者应用
3. 点击"信任"

### 步骤 4: 运行

```bash
cd example

# 查看连接的设备
flutter devices

# 输出示例:
# iPhone 14 Pro (mobile) • 00008110-001234567890001E • ios • iOS 17.0

# 运行到真机
flutter run
# 或者指定设备
flutter run -d 00008110-001234567890001E
```

## 🔧 调试技巧

### 查看设备日志

```bash
# 实时查看设备日志
flutter logs

# 或使用 Xcode
# Window → Devices and Simulators → 选择设备 → Open Console
```

### 编译到真机但不运行

```bash
flutter build ios --debug
```

### Release 模式

```bash
flutter run --release
```

## 📝 CI/CD 注意事项

如果你使用持续集成:
- ✅ 可以进行代码编译检查
- ❌ 无法运行自动化 UI 测试 (因为需要真机)
- 建议使用真机或 OMRON 提供的支持模拟器的 SDK

## 💡 建议

1. **开发阶段**: 使用真机测试 OMRON 相关功能
2. **单元测试**: 可以 mock OMRON SDK 接口在模拟器上测试业务逻辑
3. **申请完整 SDK**: 向 OMRON 申请包含模拟器架构的 framework

## ✅ 当前配置状态

- ✅ podspec 已正确配置
- ✅ Swift import 已添加
- ✅ Framework 已链接
- ⚠️ 只能在真机上运行

## 🎯 下一步

使用真机进行测试:

```bash
cd example
flutter run  # 如果只有一个设备,会自动选择
```

如果遇到签名问题,在 Xcode 中配置好 Team 后再运行。

