# OMRONLib.framework 集成指南

## 📦 Framework 放置位置

请将 OMRON 官方提供的 `OMRONLib.framework` 放置到以下目录:

```
omron_health_plugin/
└── ios/
    └── Frameworks/
        └── OMRONLib.framework/    <-- 放在这里
```

## 🔧 已完成的配置

podspec 文件已经配置好以下内容:

1. ✅ `vendored_frameworks` - 引入本地 framework
2. ✅ `ENABLE_BITCODE` 设置为 NO
3. ✅ 排除模拟器 i386 架构

## 📝 完整使用步骤

### 1. 获取 OMRONLib.framework

从 OMRON 官方获取 iOS SDK 的 framework 文件。

### 2. 放置 Framework

```bash
# 在 ios 目录下创建 Frameworks 文件夹
cd omron_health_plugin/ios
mkdir -p Frameworks

# 将 OMRONLib.framework 复制到 Frameworks 目录
cp -r /path/to/OMRONLib.framework ./Frameworks/
```

### 3. 在 Example 项目中清理并重新安装

```bash
cd ../example/ios

# 清理旧的 Pod
rm -rf Pods Podfile.lock

# 重新安装
pod install

# 或者使用 repo update (如果遇到问题)
pod install --repo-update
```

### 4. 验证集成

打开 `example/ios/Runner.xcworkspace`,在 Xcode 中检查:

1. **Pods 项目** → **Development Pods** → **omron_health_plugin** → **Frameworks** 
   - 应该能看到 `OMRONLib.framework`

2. **Build Settings** → 搜索 "Framework Search Paths"
   - 应该包含 framework 的路径

3. **编译测试**
   ```bash
   # 在 example 目录下
   flutter build ios --debug
   ```

## ⚠️ 常见问题

### 问题 1: Framework not found

**原因**: Framework 文件路径不正确

**解决方案**:
- 确认 framework 在 `ios/Frameworks/` 目录下
- 检查目录结构是否正确:
  ```
  OMRONLib.framework/
  ├── OMRONLib (二进制文件)
  ├── Headers/
  ├── Info.plist
  └── Modules/
  ```

### 问题 2: Bitcode 错误

**原因**: Framework 不支持 bitcode

**解决方案**: 已在 podspec 中设置 `ENABLE_BITCODE = NO`

### 问题 3: 模拟器编译失败

**原因**: Framework 可能只包含真机架构

**解决方案**:
- 确认 framework 是否包含模拟器架构 (x86_64, arm64-simulator)
- 或者只在真机上测试

可以使用以下命令检查 framework 支持的架构:
```bash
lipo -info Frameworks/OMRONLib.framework/OMRONLib
```

### 问题 4: 找不到符号 (Symbol not found)

**原因**: Swift/Objective-C 代码中使用的类在 framework 中不存在

**解决方案**:
- 检查 OMRON SDK 版本
- 确认 API 是否正确
- 查看 framework 的头文件

## 🔍 验证 Framework 架构

```bash
cd ios/Frameworks
lipo -info OMRONLib.framework/OMRONLib
```

正常输出示例:
```
Architectures in the fat file: OMRONLib are: armv7 arm64 x86_64 arm64-simulator
```

## 📚 相关文件

- `ios/omron_health_plugin.podspec` - Pod 配置文件
- `ios/Classes/OmronHealthPlugin.swift` - Swift 实现代码
- `example/ios/Podfile` - Example 项目的依赖配置

## 🎯 下一步

集成完成后,可以运行 example 项目测试:

```bash
cd example
flutter run
```

## 💡 提示

- 如果 framework 文件较大,建议添加到 `.gitignore`,不要提交到 Git
- 可以考虑使用 Git LFS 管理大文件
- 生产环境建议使用 CocoaPods 私有仓库管理 SDK

