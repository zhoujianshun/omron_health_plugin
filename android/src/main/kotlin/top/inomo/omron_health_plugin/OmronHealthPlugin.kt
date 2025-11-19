package top.inomo.omron_health_plugin

import OmronPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** OmronHealthPlugin */
class OmronHealthPlugin :
    FlutterPlugin {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    // private lateinit var channel: MethodChannel
    
    // 保存 OmronPlugin 实例以便清理
    private var omronPlugin: OmronPlugin? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // channel = MethodChannel(flutterPluginBinding.binaryMessenger, "omron_health_plugin")
        // channel.setMethodCallHandler(this)
        // 注册OMRON插件
        omronPlugin = OmronPlugin(flutterPluginBinding.applicationContext)
        omronPlugin?.register(flutterPluginBinding.flutterEngine)
    }

    // override fun onMethodCall(
    //     call: MethodCall,
    //     result: Result
    // ) {
    //     if (call.method == "getPlatformVersion") {
    //         result.success("Android ${android.os.Build.VERSION.RELEASE}")
    //     } else {
    //         result.notImplemented()
    //     }
    // }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // channel.setMethodCallHandler(null)
        // 清理 OMRON 插件资源
        omronPlugin?.cleanup()
        omronPlugin = null
    }
}
