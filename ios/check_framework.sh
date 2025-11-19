#!/bin/bash

# OMRONLib.framework 检查脚本
# 用于验证 framework 是否正确配置

echo "🔍 检查 OMRONLib.framework 配置..."
echo ""

# 检查 Frameworks 目录
if [ ! -d "Frameworks" ]; then
    echo "❌ Frameworks 目录不存在"
    echo "   请创建: mkdir -p Frameworks"
    exit 1
fi

echo "✅ Frameworks 目录存在"

# 检查 OMRONLib.framework
if [ ! -d "Frameworks/OMRONLib.framework" ]; then
    echo "❌ OMRONLib.framework 不存在"
    echo "   请将 framework 复制到: ios/Frameworks/"
    echo ""
    echo "   命令示例:"
    echo "   cp -r /path/to/OMRONLib.framework ./Frameworks/"
    exit 1
fi

echo "✅ OMRONLib.framework 存在"

# 检查 framework 二进制文件
if [ ! -f "Frameworks/OMRONLib.framework/OMRONLib" ]; then
    echo "❌ framework 二进制文件不存在"
    echo "   framework 结构可能不完整"
    exit 1
fi

echo "✅ framework 二进制文件存在"

# 显示支持的架构
echo ""
echo "📱 支持的架构:"
lipo -info Frameworks/OMRONLib.framework/OMRONLib

# 检查 Headers
if [ -d "Frameworks/OMRONLib.framework/Headers" ]; then
    echo ""
    echo "📄 头文件:"
    ls -1 Frameworks/OMRONLib.framework/Headers/ | head -5
    header_count=$(ls -1 Frameworks/OMRONLib.framework/Headers/ | wc -l)
    if [ $header_count -gt 5 ]; then
        echo "   ... 以及其他 $((header_count - 5)) 个文件"
    fi
fi

# 检查 podspec 配置
echo ""
echo "📝 检查 podspec 配置..."
if grep -q "vendored_frameworks.*OMRONLib.framework" omron_health_plugin.podspec; then
    echo "✅ podspec 已配置 vendored_frameworks"
else
    echo "❌ podspec 未配置 vendored_frameworks"
    echo "   请在 podspec 中添加:"
    echo "   s.vendored_frameworks = 'Frameworks/OMRONLib.framework'"
fi

# 显示 framework 大小
echo ""
framework_size=$(du -sh Frameworks/OMRONLib.framework | cut -f1)
echo "📦 Framework 大小: $framework_size"

echo ""
echo "✨ 配置检查完成!"
echo ""
echo "🚀 下一步:"
echo "   1. cd ../example/ios"
echo "   2. pod install"
echo "   3. cd ../.."
echo "   4. flutter run"

