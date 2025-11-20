# iOS OMRONLib Framework 快速设置指南

## ✅ 已完成的配置

- ✅ podspec 文件已配置 `vendored_frameworks`
- ✅ Bitcode 已设置为 NO
- ✅ 架构排除已配置
- ✅ Swift import OMRONLib 已添加
- ✅ 模块化配置已完成

## ⚠️ 重要提醒

**当前 OMRONLib.framework 仅支持真机 (arm64),不支持模拟器!**

- ✅ 可以在真实 iOS 设备上运行
- ❌ 无法在模拟器上运行

详见: [ios/SIMULATOR_NOTICE.md](ios/SIMULATOR_NOTICE.md)

## 📦 你需要做的事情

### 步骤 1: 获取 OMRONLib.framework

从 OMRON 官方获取 iOS SDK 的 framework 文件。

### 步骤 2: 放置 Framework

```bash
# 进入 iOS 目录
cd ios

# 创建 Frameworks 目录(如果不存在)
mkdir -p Frameworks

# 将你的 OMRONLib.framework 复制到这里
# 替换 /path/to/your/OMRONLib.framework 为实际路径
cp -r /path/to/your/OMRONLib.framework ./Frameworks/

# 验证文件结构
ls -la Frameworks/OMRONLib.framework/
```

期望的目录结构:
```
omron_health_plugin/
├── ios/
│   ├── Frameworks/
│   │   └── OMRONLib.framework/     ⬅️ 放在这里
│   │       ├── OMRONLib           (二进制)
│   │       ├── Headers/
│   │       ├── Info.plist
│   │       └── Modules/
│   ├── Classes/
│   └── omron_health_plugin.podspec
└── ...
```

### 步骤 3: 运行检查脚本(可选)

```bash
cd ios
./check_framework.sh
```

这个脚本会检查:
- ✅ Frameworks 目录是否存在
- ✅ OMRONLib.framework 是否存在
- ✅ Framework 支持的架构
- ✅ podspec 配置是否正确

### 步骤 4: 重新安装 Pod 依赖

```bash
cd example/ios

# 清理旧的依赖
rm -rf Pods Podfile.lock .symlinks

# 重新安装
pod install

# 如果遇到问题,尝试更新 repo
# pod install --repo-update
```

### 步骤 5: 编译测试

```bash
cd ../..  # 回到 example 目录

# 运行 Flutter 项目
flutter clean
flutter pub get
flutter run
```

## 🔍 验证集成

### 方法 1: 使用 Xcode

1. 打开 `example/ios/Runner.xcworkspace`
2. 展开 **Pods** → **Development Pods** → **omron_health_plugin**
3. 查看 **Frameworks** 分组,应该看到 `OMRONLib.framework`

### 方法 2: 检查架构

```bash
cd ios/Frameworks
lipo -info OMRONLib.framework/OMRONLib
```

输出示例:
```
Architectures in the fat file: OMRONLib are: armv7 arm64 x86_64 arm64-simulator
```

### 方法 3: 编译测试

```bash
cd example
flutter build ios --debug
```

如果没有错误,说明集成成功!

## ⚠️ 常见问题

### ❌ Framework not found OMRONLib

**原因**: Framework 文件不在正确的位置

**解决**:
- 确认 framework 在 `ios/Frameworks/` 目录
- 确认目录名称完全匹配: `OMRONLib.framework`
- 运行检查脚本验证

### ❌ Building for iOS Simulator, but framework only supports arm64

**原因**: Framework 不包含模拟器架构

**解决方案 A** (推荐): 使用真机测试
```bash
flutter run -d <your-device-id>
```

**解决方案 B**: 如果 OMRON 提供了支持模拟器的 framework,替换它

### ❌ Undefined symbols for architecture

**原因**: Framework 版本不匹配或损坏

**解决**:
- 检查 OMRON SDK 版本是否正确
- 重新下载 framework
- 确认 framework 文件完整性

### ❌ Bitcode 相关错误

**解决**: 已在 podspec 中设置 `ENABLE_BITCODE = NO`,如果还有问题:

```bash
# 在 Xcode 中设置
Build Settings → Build Options → Enable Bitcode → No
```

## 📱 测试

集成完成后,可以在 example 项目中测试 OMRON 功能:

```dart
// 初始化 SDK
await OmronPlugin.instance.initSdk();

// 注册
final result = await OmronPlugin.instance.register(
  config: OmronConfig(
    appKey: 'your_app_key',
    packageName: 'your_package_name',
    packageSecret: 'your_package_secret',
  ),
);

print('注册结果: ${result.status}');
```

## 📚 相关文档

- [详细集成指南](ios/README_Framework_Setup.md)
- [检查脚本](ios/check_framework.sh)

## 💡 提示

1. **版本控制**: Framework 文件通常较大,考虑添加到 `.gitignore`:
   ```bash
   # 取消注释 .gitignore 中的这一行:
   ios/Frameworks/*.framework
   ```

2. **多人协作**: 可以将 framework 上传到内部文件服务器,团队成员手动下载

3. **CI/CD**: 在持续集成环境中,需要配置 framework 的下载步骤

## 🎉 完成!

一切配置完成后,你的插件就可以正常使用 OMRON 的 iOS SDK 了!

