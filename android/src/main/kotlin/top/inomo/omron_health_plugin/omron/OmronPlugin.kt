import android.util.Log
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.omron.lib.BleScanDevice
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.omron.lib.OMRONLib
import com.omron.lib.bean.OmronStateEnum
import com.omron.lib.common.OMRONBLEErrMsg
import com.omron.lib.BleScanDeviceCallback
import com.omron.lib.device.DeviceCategory
import com.omron.lib.device.DeviceInfo
import com.omron.lib.device.bp.OmronBpBleCallBack
import com.omron.lib.model.BPData
import java.text.SimpleDateFormat
import java.util.Locale


/**
 * OMRON插件
 * 负责管理与 Flutter 的通道通信
 */
class OmronPlugin(private val context: Context) : EventChannel.StreamHandler {
    
    companion object {
        private const val METHOD_CHANNEL_NAME = "top.inomo.omron_health_plugin/omron"
        private const val STATUS_EVENT_CHANNEL_NAME = "top.inomo.omron_health_plugin/omron_status"
        private const val SCAN_EVENT_CHANNEL_NAME = "top.inomo.omron_health_plugin/omron_scan"
        private const val SYNC_SCAN_EVENT_CHANNEL_NAME = "top.inomo.omron_health_plugin/omron_sync_scan"
        private var isInitialized = false
    }
    
    // 主线程Handler，用于在主线程发送事件到Flutter
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // EventChannel的事件发送器 - 状态通道
    private var statusEventSink: EventChannel.EventSink? = null
    
    // EventChannel的事件发送器 - 绑定扫描通道
    private var scanEventSink: EventChannel.EventSink? = null
    
    // EventChannel的事件发送器 - 同步扫描通道
    private var syncScanEventSink: EventChannel.EventSink? = null
    
    // 用于跨多次扫描去重的设备集合
    private val scannedDevicesCache = mutableSetOf<String>()
    
    /**
     * 注册插件到 Flutter 引擎
     * @param flutterEngine Flutter 引擎实例
     */
    fun register(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        setupMethodChannel(messenger)
        setupStatusEventChannel(messenger)
        setupScanEventChannel(messenger)
        setupSyncScanEventChannel(messenger)
    }
    
    /**
     * 配置 MethodChannel
     * @param messenger 二进制消息传递器
     */
    private fun setupMethodChannel(messenger: BinaryMessenger) {
        val methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME)
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initSdk" -> {
                    initSdk(result)
                }
                "register" -> {
                    val params = call.arguments as? Map<String, Any?>
                    if (params == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "注册参数不能为空",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    register(params, result)
                }
                "startBindScan" -> {
                    val params = call.arguments as? Map<String, Any?>
                    if (params == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "扫描参数不能为空",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    startBindScan(params, result)
                }
                "stopScan" -> {
                    stopScan(result)
                }
                "startSyncScan" -> {
                    val params = call.arguments as? Map<String, Any?>
                    if (params == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "同步扫描参数不能为空",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    startSyncScan(params, result)
                }
                "stopSyncScan" -> {
                    stopSyncScan(result)
                }
                "bindBpDevice" -> {
                    val params = call.arguments as? Map<String, Any?>
                    if (params == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "绑定参数不能为空",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    bindBpDevice(params, result)
                }
                "getBpDeviceData" -> {
                    val params = call.arguments as? Map<String, Any?>
                    if (params == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "同步数据参数不能为空",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    getBpDeviceData(params, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * 初始化OMRON SDK（基础初始化）
     * @param result 返回结果
     */
    private fun initSdk(result: MethodChannel.Result) {
        try {
            if (!isInitialized) {
                OMRONLib.init(context)
                isInitialized = true
                result.success(mapOf(
                    "success" to true,
                    "message" to "SDK初始化成功"
                ))
            } else {
                result.success(mapOf(
                    "success" to true,
                    "message" to "SDK已经初始化"
                ))
            }
        } catch (e: Exception) {
            result.error(
                "OMRON_ERROR",
                "OMRON SDK初始化失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 注册OMRON SDK
     * @param params 注册参数
     * @param result 返回结果
     */
    private fun register(params: Map<String, Any?>, result: MethodChannel.Result) {
        try {
            // 提取参数
            val appKey = params["appKey"] as? String
            // val ekiKey = params["ekiKey"] as? String
            val packageName = params["packageName"] as? String
            val packageSecret = params["packageSecret"] as? String
            val license = params["license"] as? String ?: ""
            val thirdUserId = params["thirdUserId"] as? String ?: ""
            
            // 参数验证
            if (appKey.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "appKey不能为空", null)
                return
            }
            // if (ekiKey.isNullOrEmpty()) {
            //     result.error("INVALID_ARGUMENTS", "ekiKey不能为空", null)
            //     return
            // }
            if (packageName.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "packageName不能为空", null)
                return
            }
            if (packageSecret.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "packageSecret不能为空", null)
                return
            }
            
            // 调用requestIdentifier进行注册（异步回调）
            OMRONLib.getInstance().requestIdentifier(
                appKey,
                packageSecret,
                packageName,
                license,
                thirdUserId,
                object : com.omron.lib.IdentifierCallback {

                    override fun onSuccess() {
                      // Log.d("OMRONPlugin", "SDK注册成功")
                        // 注册成功
                        val resultMap = mapOf(
                            "status" to "success",
                            "message" to "SDK注册成功",
                        )
                        result.success(resultMap)
                    }
                    
                    override fun onFail(errMsg: com.omron.lib.common.OMRONBLEErrMsg?) {
                        // 注册失败
                        val errorCode = errMsg?.ordinal ?: -999
                        val errorMessage = errMsg?.name ?: "未知错误"
                        val resultMap = mapOf(
                            "status" to "error",
                            "message" to errorMessage,
                            "code" to errorCode
                        )
                        result.success(resultMap)
                    }
                }
            )
            
        } catch (e: Exception) {
            result.error(
                "OMRON_ERROR",
                "OMRON SDK注册失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 配置状态 EventChannel
     * @param messenger 二进制消息传递器
     */
    private fun setupStatusEventChannel(messenger: BinaryMessenger) {
        val statusEventChannel = EventChannel(messenger, STATUS_EVENT_CHANNEL_NAME)
        statusEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d("OmronPlugin", "🔵 [Android] 状态通道 onListen 被调用")
                statusEventSink = events
                
                // 设置OMRON SDK的状态回调
                OMRONLib.getInstance().setStatusBlock { type ->
                    Log.d("OmronPlugin", "📥 [Android] 收到状态回调: $type")
                    
                    // 将OmronStateEnum转换为字符串
                    val statusString = when (type) {
                        OmronStateEnum.OMRONLIB_SCAN -> "scan"
                        OmronStateEnum.OMRONLIB_CONNECT -> "connect"
                        OmronStateEnum.OMRONLIB_SYNC_DATA -> "syncData"
                        OmronStateEnum.OMRONLIB_SYNC_DATA_SUCCESS -> "syncDataSuccess"
                        OmronStateEnum.OMRONLIB_SYNC_DATA_ERROR -> "syncDataError"
                        OmronStateEnum.OMRONLIB_DISCONNECTED -> "disconnected"
                        else -> "unknown"
                    }
                    
                    Log.d("OmronPlugin", "📤 [Android] 发送状态到Flutter: $statusString")
                    
                    // 在主线程发送状态到Flutter
                    mainHandler.post {
                        statusEventSink?.success(statusString)
                    }
                }
                
                Log.d("OmronPlugin", "✅ [Android] 状态监听已启动")
            }
            
            override fun onCancel(arguments: Any?) {
                Log.d("OmronPlugin", "🔵 [Android] 状态通道 onCancel 被调用")
                statusEventSink = null
                Log.d("OmronPlugin", "✅ [Android] 状态监听已清理")
            }
        })
    }
    
    /**
     * 配置扫描 EventChannel（绑定扫描）
     * @param messenger 二进制消息传递器
     */
    private fun setupScanEventChannel(messenger: BinaryMessenger) {
        val scanEventChannel = EventChannel(messenger, SCAN_EVENT_CHANNEL_NAME)
        scanEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d("OmronPlugin", "🔵 [Android] 绑定扫描通道 onListen 被调用")
                scanEventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                Log.d("OmronPlugin", "🔵 [Android] 绑定扫描通道 onCancel 被调用")
                scanEventSink = null
            }
        })
    }
    
    /**
     * 配置同步扫描 EventChannel
     * @param messenger 二进制消息传递器
     */
    private fun setupSyncScanEventChannel(messenger: BinaryMessenger) {
        val syncScanEventChannel = EventChannel(messenger, SYNC_SCAN_EVENT_CHANNEL_NAME)
        syncScanEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d("OmronPlugin", "🔵 [Android] 同步扫描通道 onListen 被调用")
                syncScanEventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                Log.d("OmronPlugin", "🔵 [Android] 同步扫描通道 onCancel 被调用")
                syncScanEventSink = null
            }
        })
    }
    
    /**
     * 开始扫描绑定状态的设备
     * @param params 扫描参数
     * @param result 返回结果
     */
    private fun startBindScan(params: Map<String, Any?>, result: MethodChannel.Result) {
        try {
            Log.d("OmronPlugin", "🔵 [Android] startBindScan 被调用")
            
            // 提取设备类别参数
            val categoryValue = params["categoryValue"] as? Int ?: 0
            
            // 提取超时时间参数（秒）
            val timeout = params["timeout"] as? Int ?: 60
            val category = when (categoryValue) {
              0 -> DeviceCategory.ALL_SUPPORT
              1 -> DeviceCategory.BLOOD_PRESSURE
              2 -> DeviceCategory.BLOOD_GLUCOSE
              4 -> DeviceCategory.BODY_FAT
              5 -> DeviceCategory.BLOOD_OXYGEN
              else -> DeviceCategory.ALL_SUPPORT
          }
            
            Log.d("OmronPlugin", "📦 [Android] 扫描参数 - 类别: $categoryValue, 超时: ${timeout}秒")
            
            // 调用OMRON SDK开始扫描
            OMRONLib.getInstance().startBindScan(category, timeout, object : BleScanDeviceCallback {
                override fun onBleScan(device: BleScanDevice?, rssi: Int, scanRecord: ByteArray?) {
                    if (device == null) {
                        Log.w("OmronPlugin", "⚠️ [Android] 扫描到的设备为null")
                        return
                    }
                    
                    // Log.d("OmronPlugin", "📥 [Android] 扫描到设备: ${device.name}, 信号: $rssi")
                    
                    // 构造设备信息Map
                    val deviceMap = mapOf(
                        "deviceType" to (device.deviceType ?: ""),
                        "deviceName" to (device.name ?: "未知设备"),
                        "userIndex" to (device.userIndex ?: ""),
                        "deviceSerialNum" to (device.address ?: ""),
                        "rssi" to rssi,
                        "category" to getCategoryName(categoryValue)
                    )
                    
                    // Log.d("OmronPlugin", "📤 [Android] 发送设备到Flutter: ${device.name}")
                    
                    // 在主线程发送到Flutter
                    mainHandler.post {
                        scanEventSink?.success(deviceMap)
                    }
                }
                
                override fun onCycleEnd() {
                    OMRONLib.getInstance().stopScan()
                    Log.d("OmronPlugin", "🔄 [Android] 扫描周期结束")
                    
                    // 发送扫描完成事件到Flutter
                    val scanFinishMap = mapOf(
                        "isFinished" to true,
                        "message" to "扫描周期结束"
                    )
                    mainHandler.post {
                        scanEventSink?.success(scanFinishMap)
                    }
                }
                
                override fun onBleScanFailure(errMsg: OMRONBLEErrMsg?) {
                    OMRONLib.getInstance().stopScan();
                    Log.e("OmronPlugin", "❌ [Android] 扫描失败: ${errMsg?.name}")
                    mainHandler.post {
                        scanEventSink?.error(
                            "SCAN_FAILED",
                            "设备扫描失败: ${errMsg?.name}",
                            null
                        )
                    }
                }
            })
            
            result.success(mapOf("success" to true))
            Log.d("OmronPlugin", "✅ [Android] startBindScan 启动成功")
            
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] startBindScan 异常: ${e.message}")
            result.error(
                "OMRON_ERROR",
                "开始扫描失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 获取设备类别名称
     * @param categoryValue 设备类别值
     * @return 类别名称
     */
    private fun getCategoryName(categoryValue: Int): String {
        return when (categoryValue) {
            0 -> "ALL_SUPPORT"
            1 -> "BLOOD_PRESSURE"
            2 -> "BLOOD_GLUCOSE"
            4 -> "BODY_FAT"
            5 -> "BLOOD_OXYGEN"
            else -> "UNKNOWN"
        }
    }
    
    /**
     * 映射OMRON错误码到统一格式
     * @param errMsg OMRON错误消息枚举
     * @return Pair<状态码, 错误消息>
     */
    private fun mapErrorMessage(errMsg: OMRONBLEErrMsg?): Pair<String, String> {
        if (errMsg == null) {
            return "error" to "未知错误"
        }
        
        // 使用 errMsg 的 name 和 errMsg 属性来构建错误信息
        val errorCode = errMsg.name
        val errorMessage = errMsg.errMsg ?: errorCode
        
        // 根据错误码返回统一格式
        return when {
            errorCode.contains("SUCCESS", ignoreCase = true) -> 
                "success" to "操作成功"
            errorCode.contains("UNREGISTER", ignoreCase = true) -> 
                "unregistered" to "SDK未注册"
            errorCode.contains("INVALID_KEY", ignoreCase = true) || errorCode.contains("KEY_ERROR", ignoreCase = true) -> 
                "invalidKey" to "无效的密钥"
            errorCode.contains("NO_NETWORK", ignoreCase = true) || errorCode.contains("NETWORK", ignoreCase = true) -> 
                "noNetwork" to "无网络连接"
            errorCode.contains("BLUETOOTH_OFF", ignoreCase = true) || errorCode.contains("BLUETOOTH", ignoreCase = true) -> 
                "bluetoothOff" to "蓝牙未开启"
            errorCode.contains("UNSUPPORTED", ignoreCase = true) -> 
                "unsupportedDevice" to "不支持的设备"
            errorCode.contains("NOT_BOUND", ignoreCase = true) || errorCode.contains("UNBIND", ignoreCase = true) -> 
                "notBound" to "设备未绑定"
            errorCode.contains("DISCONNECT", ignoreCase = true) -> 
                "disconnected" to "设备已断开"
            errorCode.contains("BIND", ignoreCase = true) && errorCode.contains("FAIL", ignoreCase = true) -> 
                "bindFailed" to "绑定失败"
            errorCode.contains("CONNECT", ignoreCase = true) && errorCode.contains("FAIL", ignoreCase = true) -> 
                "connectFailed" to "连接失败"
            errorCode.contains("SCAN", ignoreCase = true) && errorCode.contains("TIMEOUT", ignoreCase = true) -> 
                "scanTimeout" to "扫描超时"
            else -> 
                "error" to errorMessage
        }
    }
    
    /**
     * 停止扫描设备
     * @param result 返回结果
     */
    private fun stopScan(result: MethodChannel.Result) {
        try {
            Log.d("OmronPlugin", "🔵 [Android] stopScan 被调用")
            OMRONLib.getInstance().stopScan()
            result.success(mapOf("success" to true))
            Log.d("OmronPlugin", "✅ [Android] stopScan 执行成功")
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] stopScan 异常: ${e.message}")
            result.error(
                "OMRON_ERROR",
                "停止扫描失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 开始同步扫描
     * @param params 扫描参数，包含设备列表和扫描周期
     * @param result 返回结果
     */
    private fun startSyncScan(params: Map<String, Any?>, result: MethodChannel.Result) {
        try {
            Log.d("OmronPlugin", "🔵 [Android] startSyncScan 被调用")
            Log.d("OmronPlugin", "📦 [Android] 参数: $params")
            
            // 提取参数
            val devicesList = params["devices"] as? List<Map<String, Any?>>
            val scanPeriod = params["scanPeriod"] as? Int ?: 60
            
            if (devicesList == null || devicesList.isEmpty()) {
                Log.e("OmronPlugin", "❌ [Android] 设备列表为空")
                mainHandler.post {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "设备列表不能为空",
                        null
                    )
                }
                return
            }
            
            // 验证扫描周期
            if (scanPeriod < 1 || scanPeriod > 300) {
                Log.e("OmronPlugin", "❌ [Android] 扫描周期无效: $scanPeriod")
                mainHandler.post {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "扫描周期必须在1-300秒之间",
                        null
                    )
                }
                return
            }
            
            // 转换设备列表为BleScanDevice对象
            // 根据SDK文档，BleScanDevice构造函数为: BleScanDevice(deviceType, deviceSerialNum, deviceId)
            val bleScanDeviceList = mutableListOf<BleScanDevice>()
            for (deviceMap in devicesList) {
                val deviceType = deviceMap["deviceType"] as? String
                val deviceSerialNum = deviceMap["deviceSerialNum"] as? String
                val deviceId = deviceMap["deviceId"] as? String ?: ""
                
                if (deviceType != null && deviceSerialNum != null) {
                    try {
                        // 使用三参数构造函数: (deviceType, deviceSerialNum, deviceId)
                        val bleScanDevice = BleScanDevice(deviceType, deviceSerialNum, deviceId)
                        bleScanDeviceList.add(bleScanDevice)
                        Log.d("OmronPlugin", "  ✓ 添加设备: $deviceType - $deviceSerialNum - $deviceId")
                    } catch (e: Exception) {
                        Log.w("OmronPlugin", "⚠️ [Android] 创建BleScanDevice失败: ${e.message}")
                    }
                }
            }
            
            if (bleScanDeviceList.isEmpty()) {
                Log.e("OmronPlugin", "❌ [Android] 没有有效的设备")
                mainHandler.post {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "没有有效的设备信息",
                        null
                    )
                }
                return
            }
            
            Log.d("OmronPlugin", "📡 [Android] 开始同步扫描，设备数: ${bleScanDeviceList.size}, 周期: ${scanPeriod}秒")
            
            // 开始新扫描时清空缓存
            scannedDevicesCache.clear()
            
            // 调用SDK的startSyncScan方法
            OMRONLib.getInstance().startSyncScan(
                bleScanDeviceList,
                scanPeriod,
                object : BleScanDeviceCallback {
                    // 扫描到设备时调用 - 正确的签名包含rssi和advertisedData
                    override fun onBleScan(bleScanDevice: BleScanDevice, rssi: Int, advertisedData: ByteArray?) {
                        Log.d("OmronPlugin", "📥 [Android] 同步扫描到设备，RSSI: $rssi")
                        
                        // 使用反射动态获取设备字段
                        // Android字段映射：
                        // deviceType -> deviceType
                        // bleDevice -> (忽略，是BluetoothDevice对象)
                        // name -> deviceName
                        // address -> deviceSerialNum
                        // userIndex -> userIndex
                        
                        val deviceInfo = mutableMapOf<String, Any?>(
                            "deviceName" to "未知设备",
                            "deviceSerialNum" to "",
                            "rssi" to rssi,
                            "scannedAt" to System.currentTimeMillis()
                        )
                        
                        try {
                            // 获取deviceType
                            try {
                                val deviceTypeField = bleScanDevice.javaClass.getDeclaredField("deviceType")
                                deviceTypeField.isAccessible = true
                                val deviceType = deviceTypeField.get(bleScanDevice)
                                if (deviceType != null) {
                                    deviceInfo["deviceType"] = deviceType
                                    Log.d("OmronPlugin", "  ✓ deviceType: $deviceType")
                                }
                            } catch (e: Exception) {
                                Log.w("OmronPlugin", "⚠️ [Android] 获取deviceType失败: ${e.message}")
                            }
                            
                            // 获取name -> deviceName
                            try {
                                val nameField = bleScanDevice.javaClass.getDeclaredField("name")
                                nameField.isAccessible = true
                                val name = nameField.get(bleScanDevice)
                                if (name != null) {
                                    deviceInfo["deviceName"] = name
                                    Log.d("OmronPlugin", "  ✓ name: $name")
                                }
                            } catch (e: Exception) {
                                Log.w("OmronPlugin", "⚠️ [Android] 获取name失败: ${e.message}")
                            }
                            
                            // 获取address -> deviceSerialNum
                            try {
                                val addressField = bleScanDevice.javaClass.getDeclaredField("address")
                                addressField.isAccessible = true
                                val address = addressField.get(bleScanDevice)
                                if (address != null) {
                                    deviceInfo["deviceSerialNum"] = address
                                    Log.d("OmronPlugin", "  ✓ address: $address")
                                }
                            } catch (e: Exception) {
                                Log.w("OmronPlugin", "⚠️ [Android] 获取address失败: ${e.message}")
                            }
                            
                            // 获取userIndex
                            try {
                                val userIndexField = bleScanDevice.javaClass.getDeclaredField("userIndex")
                                userIndexField.isAccessible = true
                                val userIndex = userIndexField.get(bleScanDevice)
                                if (userIndex != null) {
                                    deviceInfo["userIndex"] = userIndex.toString()
                                    Log.d("OmronPlugin", "  ✓ userIndex: $userIndex")
                                }
                            } catch (e: Exception) {
                                Log.w("OmronPlugin", "⚠️ [Android] 获取userIndex失败: ${e.message}")
                            }
                            
                            // 尝试从bleDevice获取更多信息（如果需要）
                            try {
                                val bleDeviceField = bleScanDevice.javaClass.getDeclaredField("bleDevice")
                                bleDeviceField.isAccessible = true
                                val bleDevice = bleDeviceField.get(bleScanDevice) as? android.bluetooth.BluetoothDevice
                                if (bleDevice != null) {
                                    // 可以从BluetoothDevice获取额外信息
                                    Log.d("OmronPlugin", "  ✓ bleDevice: ${bleDevice.name} - ${bleDevice.address}")
                                }
                            } catch (e: Exception) {
                                // bleDevice字段获取失败不影响主要功能
                            }
                            
                        } catch (e: Exception) {
                            Log.e("OmronPlugin", "❌ [Android] 提取设备信息失败: ${e.message}")
                            e.printStackTrace()
                        }
                        
                        // 去重检查：只有第一次扫描到的设备才发送
                        val serialNum = deviceInfo["deviceSerialNum"] as? String ?: ""
                        if (scannedDevicesCache.contains(serialNum)) {
                            Log.d("OmronPlugin", "⏭️ [Android] 跳过重复设备: $serialNum")
                            return
                        }
                        
                        scannedDevicesCache.add(serialNum)
                        Log.d("OmronPlugin", "📤 [Android] 发送同步设备到Flutter (去重后): $deviceInfo")
                        
                        // 在主线程发送事件到Flutter
                        mainHandler.post {
                            syncScanEventSink?.success(deviceInfo)
                        }
                    }
                    
                    // 扫描周期结束时调用
                    override fun onCycleEnd() {
                        Log.d("OmronPlugin", "🏁 [Android] 同步扫描周期结束")
                        
                        val scanFinishMap = mapOf(
                            "isFinished" to true,
                            "message" to "同步扫描周期结束"
                        )
                        
                        // 在主线程发送事件到Flutter
                        mainHandler.post {
                            syncScanEventSink?.success(scanFinishMap)
                        }
                    }
                    
                    // 扫描失败时调用
                    override fun onBleScanFailure(errorMsg: OMRONBLEErrMsg?) {
                        Log.e("OmronPlugin", "❌ [Android] 同步扫描失败: ${errorMsg?.errMsg}")
                        
                        // 停止扫描
                        OMRONLib.getInstance().stopSyncScan()
                        
                        // 在主线程发送错误事件到Flutter
                        mainHandler.post {
                            syncScanEventSink?.error(
                                "SYNC_SCAN_FAILED",
                                "同步扫描失败: ${errorMsg?.errMsg}",
                                null
                            )
                        }
                    }
                }
            )
            
            // 立即返回成功
            mainHandler.post {
                result.success(mapOf("success" to true))
            }
            Log.d("OmronPlugin", "✅ [Android] startSyncScan 启动成功")
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] startSyncScan 异常: ${e.message}")
            e.printStackTrace()
            mainHandler.post {
                result.error(
                    "OMRON_ERROR",
                    "启动同步扫描失败: ${e.message}",
                    null
                )
            }
        }
    }
    
    /**
     * 停止同步扫描
     * @param result 返回结果
     */
    private fun stopSyncScan(result: MethodChannel.Result) {
        try {
            Log.d("OmronPlugin", "🔵 [Android] stopSyncScan 被调用")
            OMRONLib.getInstance().stopSyncScan()
            result.success(mapOf("success" to true))
            Log.d("OmronPlugin", "✅ [Android] stopSyncScan 执行成功")
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] stopSyncScan 异常: ${e.message}")
            result.error(
                "OMRON_ERROR",
                "停止同步扫描失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 提取血压数据字段
     * 使用反射从BPData对象中提取所有字段
     * 
     * @param bp BPData对象
     * @return Map包含所有血压数据字段
     */
    private fun extractBpDataFields(bp: BPData): Map<String, Any?> {
        val bpMap = mutableMapOf<String, Any?>()
        try {
            val bpClass = bp.javaClass
            
            // systolic - 收缩压
            try {
                val field = bpClass.getDeclaredField("systolic")
                field.isAccessible = true
                bpMap["systolic"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取systolic失败: ${e.message}")
                bpMap["systolic"] = 0
            }
            
            // diastolic - 舒张压
            try {
                val field = bpClass.getDeclaredField("diastolic")
                field.isAccessible = true
                bpMap["diastolic"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取diastolic失败: ${e.message}")
                bpMap["diastolic"] = 0
            }
            
            // pulse - 脉搏
            try {
                val field = bpClass.getDeclaredField("pulse")
                field.isAccessible = true
                bpMap["pulse"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取pulse失败: ${e.message}")
                bpMap["pulse"] = 0
            }
            
            // arrhythmiaFlg - 心律不齐标志
            try {
                val field = bpClass.getDeclaredField("arrhythmiaFlg")
                field.isAccessible = true
                bpMap["arrhythmiaFlag"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取arrhythmiaFlg失败: ${e.message}")
                bpMap["arrhythmiaFlag"] = 0
            }
            
            // bmFlg - 身体移动标志
            try {
                val field = bpClass.getDeclaredField("bmFlg")
                field.isAccessible = true
                bpMap["bodyMovementFlag"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取bmFlg失败: ${e.message}")
                bpMap["bodyMovementFlag"] = 0
            }
            
            // cwsFlg - 袖带佩戴标志
            try {
                val field = bpClass.getDeclaredField("cwsFlg")
                field.isAccessible = true
                bpMap["cuffWrapFlag"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取cwsFlg失败: ${e.message}")
                bpMap["cuffWrapFlag"] = 0
            }
            
            // measureUser - 测量用户
            try {
                val field = bpClass.getDeclaredField("measureUser")
                field.isAccessible = true
                bpMap["measureUser"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取measureUser失败: ${e.message}")
                bpMap["measureUser"] = 0
            }
            
            // measureTime - 测量时间（时间戳，毫秒）
            try {
                val field = bpClass.getDeclaredField("measureTime")
                field.isAccessible = true
                val time = field.get(bp)
                bpMap["measureTime"] = if (time is Long) time else 0L
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取measureTime失败: ${e.message}")
                bpMap["measureTime"] = 0L
            }
            
            // afibMode - 房颤模式
            try {
                val field = bpClass.getDeclaredField("afibMode")
                field.isAccessible = true
                bpMap["afibMode"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取afibMode失败: ${e.message}")
                bpMap["afibMode"] = 0
            }
            
            // afibFlg - 房颤标志
            try {
                val field = bpClass.getDeclaredField("afibFlg")
                field.isAccessible = true
                bpMap["afibFlag"] = field.get(bp) ?: 0
            } catch (e: Exception) {
                Log.w("OmronPlugin", "获取afibFlg失败: ${e.message}")
                bpMap["afibFlag"] = 0
            }
            
            Log.d("OmronPlugin", "✅ BP数据: 血压=${bpMap["systolic"]}/${bpMap["diastolic"]}, 脉搏=${bpMap["pulse"]}, 时间=${bpMap["measureTime"]}")
            
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ 提取BP数据失败: ${e.message}")
        }
        
        return bpMap
    }
    
    /**
     * 绑定血压计设备
     * @param params 绑定参数
     * @param result 返回结果
     */
    private fun bindBpDevice(params: Map<String, Any?>, result: MethodChannel.Result) {
        try {
            val deviceType = params["deviceType"] as? String
            val deviceSerialNum = params["deviceSerialNum"] as? String
            
            if (deviceType.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "deviceType不能为空", null)
                return
            }
            
            Log.d("OmronPlugin", "🔵 [Android] bindBpDevice 被调用")
            Log.d("OmronPlugin", "📦 [Android] deviceType: $deviceType, deviceSerialNum: $deviceSerialNum")
            
            OMRONLib.getInstance().bindBpDevice(deviceType, object : OmronBpBleCallBack {

                override fun onFailure(errMsg: OMRONBLEErrMsg?) {
                    // 绑定失败
                    Log.e("OmronPlugin", "❌ [Android] 绑定失败: ${errMsg?.name}")
                    
                    // 使用统一的错误映射
                    val (statusCode, statusMessage) = mapErrorMessage(errMsg)
                    
                    val resultMap = mapOf<String, Any>(
                        "status" to statusCode,
                        "deviceType" to deviceType,
                        "deviceSerialNum" to (deviceSerialNum ?: ""),
                        "message" to statusMessage
                    )
                    
                    // 在主线程返回结果
                    mainHandler.post {
                        result.success(resultMap)
                    }
                }

                override fun onDataReadComplete(
                    p0: String?,
                    p1: String?,
                    p2: String?,
                    p3: List<BPData?>?
                ) {
                    // 暂时不需要实现 - 此回调用于数据读取完成，绑定过程中不需要处理
                }


                override fun onBindComplete(
                    returnDeviceType: String,
                    returnDeviceSerialNum: String,
                    returnDeviceId: String,
                    deviceInfo: DeviceInfo,
                    datas: MutableList<BPData>
                ) {
                    try {
                        // 绑定成功
                        Log.d("OmronPlugin", "✅ [Android] 绑定成功")
                        Log.d("OmronPlugin", "📦 [Android] deviceInfo类: ${deviceInfo.javaClass.simpleName}")
                        Log.d("OmronPlugin", "📦 [Android] BPData类: ${datas.firstOrNull()?.javaClass?.simpleName}")
                        
                        // 构建设备信息 - 使用反射获取所有字段
                        val deviceInfoMap = mutableMapOf<String, Any?>()
                        val deviceInfoClass = deviceInfo.javaClass
                        
                        // 定义需要提取的字段列表
                        val fieldNames = listOf(
                            "modelName",
                            "serialNumber", 
                            "hardwareVersion",
                            "softwareVersion",
                            "firmwareVersion",
                            "batteryLevel",
                            "powerSupplyMode",
                            "manufacturerName",
                            "modelNumber",
                            "systemID"
                        )
                        
                        // 使用反射提取所有字段
                        for (fieldName in fieldNames) {
                            try {
                                val field = deviceInfoClass.getDeclaredField(fieldName)
                                field.isAccessible = true
                                val value = field.get(deviceInfo)
                                if (value != null) {
                                    deviceInfoMap[fieldName] = value
                                    Log.d("OmronPlugin", "  ✓ $fieldName: $value")
                                }
                            } catch (e: Exception) {
                                Log.w("OmronPlugin", "  ✗ 获取${fieldName}失败: ${e.message}")
                            }
                        }
                        
                        // 构建血压数据列表 - 使用辅助函数提取字段
                        val bpDataList = mutableListOf<Map<String, Any?>>()
                        for (bp in datas) {
                            val bpMap = extractBpDataFields(bp)
                            bpDataList.add(bpMap)
                        }
                        
                        // 构建返回结果
                        val resultMap = mapOf<String, Any>(
                            "status" to "success",
                            "deviceType" to returnDeviceType,
                            "deviceSerialNum" to returnDeviceSerialNum,
                            "deviceId" to returnDeviceId,
                            "deviceInfo" to deviceInfoMap,
                            "bpDataList" to bpDataList,
                            "message" to "绑定成功，获取到${bpDataList.size}条数据"
                        )
                        
                        Log.d("OmronPlugin", "📤 [Android] 返回数据: $resultMap")
                        
                        // 在主线程返回结果
                        mainHandler.post {
                            result.success(resultMap)
                        }
                    } catch (e: Exception) {
                        Log.e("OmronPlugin", "❌ [Android] 处理绑定结果异常: ${e.message}")
                        e.printStackTrace()
                        
                        // 在主线程返回错误
                        mainHandler.post {
                            result.error("OMRON_ERROR", "处理绑定结果失败: ${e.message}", null)
                        }
                    }
                }
            }, deviceSerialNum)
            
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] bindBpDevice 异常: ${e.message}")
            result.error(
                "OMRON_ERROR",
                "绑定血压计失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 同步血压计测量数据
     * 获取血压计中所有未同步过的血压数据
     * 
     * Android API:
     * void getBpDeviceData(@NonNull String deviceType, @NonNull String deviceName,
     *                      @NonNull String deviceAddress, @NonNull OmronBpBleCallBack callback)
     * 
     * @param params 参数Map，包含:
     *   - deviceType: 设备类型 (必须)
     *   - deviceSerialNum: "设备名称;MAC地址" 格式，如 "MyDevice;00:11:22:33:44:55" (必须)
     * @param result Flutter结果回调
     */
    private fun getBpDeviceData(params: Map<String, Any?>, result: MethodChannel.Result) {
        try {
            val deviceType = params["deviceType"] as? String
            val deviceSerialNum = params["deviceSerialNum"] as? String
            
            if (deviceType.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "deviceType不能为空", null)
                return
            }
            
            if (deviceSerialNum.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "deviceSerialNum不能为空", null)
                return
            }
            
            // 解析设备名称和MAC地址
            // 格式：deviceName;macAddress
            val parts = deviceSerialNum.split(";")
            if (parts.size != 2) {
                result.error(
                    "INVALID_ARGUMENTS",
                    "deviceSerialNum格式错误，应为'设备名称;MAC地址'，如'MyDevice;00:11:22:33:44:55'",
                    null
                )
                return
            }
            
            val deviceName = parts[0]
            val deviceAddress = parts[1]
            
            Log.d("OmronPlugin", "🔵 [Android] getBpDeviceData 被调用")
            Log.d("OmronPlugin", "📦 [Android] deviceType: $deviceType")
            Log.d("OmronPlugin", "📦 [Android] deviceName: $deviceName")
            Log.d("OmronPlugin", "📦 [Android] deviceAddress: $deviceAddress")
            
            OMRONLib.getInstance().getBpDeviceData(
                deviceType,
                deviceName,
                deviceAddress,
                object : OmronBpBleCallBack {
                    
                    override fun onFailure(errMsg: OMRONBLEErrMsg?) {
                        // 同步失败
                        Log.e("OmronPlugin", "❌ [Android] 同步数据失败: ${errMsg?.name}")
                        
                        // 使用统一的错误映射
                        val (statusCode, statusMessage) = mapErrorMessage(errMsg)
                        
                        val resultMap = mapOf<String, Any>(
                            "status" to statusCode,
                            "deviceType" to deviceType,
                            "deviceSerialNum" to deviceSerialNum,
                            "message" to statusMessage
                        )
                        
                        // 在主线程返回结果
                        mainHandler.post {
                            result.success(resultMap)
                        }
                    }
                    
                    override fun onDataReadComplete(
                        returnDeviceType: String?,
                        returnDeviceSerialNum: String?,
                        returnDeviceId: String?,
                        datas: List<BPData?>?
                    ) {
                        try {
                            // 数据读取完成
                            Log.d("OmronPlugin", "✅ [Android] 数据同步成功")
                            Log.d("OmronPlugin", "📦 [Android] 数据条数: ${datas?.size ?: 0}")
                            
                            // 构建血压数据列表 - 使用辅助函数提取字段
                            val bpDataList = mutableListOf<Map<String, Any?>>()
                            if (datas != null) {
                                for (bp in datas) {
                                    if (bp == null) continue
                                    val bpMap = extractBpDataFields(bp)
                                    bpDataList.add(bpMap)
                                }
                            }
                            
                            Log.d("OmronPlugin", "📊 [Android] 解析得到 ${bpDataList.size} 条数据")
                            
                            // 构建返回结果
                            val resultMap = mapOf<String, Any>(
                                "status" to "success",
                                "deviceType" to (returnDeviceType ?: deviceType),
                                "deviceSerialNum" to (returnDeviceSerialNum ?: deviceSerialNum),
                                "deviceId" to (returnDeviceId ?: ""),
                                "deviceInfo" to emptyMap<String, Any>(), // 同步数据接口不返回设备信息
                                "bpDataList" to bpDataList
                            )
                            
                            // 在主线程返回结果
                            mainHandler.post {
                                result.success(resultMap)
                            }
                            
                        } catch (e: Exception) {
                            Log.e("OmronPlugin", "❌ [Android] 处理同步数据回调异常: ${e.message}")
                            mainHandler.post {
                                result.error(
                                    "DATA_PARSE_ERROR",
                                    "数据解析失败: ${e.message}",
                                    null
                                )
                            }
                        }
                    }
                    
                    override fun onBindComplete(
                        returnDeviceType: String,
                        returnDeviceSerialNum: String,
                        returnDeviceId: String,
                        deviceInfo: DeviceInfo,
                        datas: MutableList<BPData>
                    ) {
                        // 同步数据接口不会触发此回调
                        // 此回调仅在绑定设备时触发
                        Log.w("OmronPlugin", "⚠️ [Android] onBindComplete在同步数据时被调用（不应该发生）")
                    }
                }
            )
            
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] getBpDeviceData 异常: ${e.message}")
            result.error(
                "OMRON_ERROR",
                "同步血压数据失败: ${e.message}",
                null
            )
        }
    }
    
    /**
     * 清理资源和停止所有操作
     * 在应用退出或插件卸载时调用
     */
    fun cleanup() {
        Log.d("OmronPlugin", "🧹 [Android] 开始清理资源")
        
        try {
            // 停止所有扫描
            OMRONLib.getInstance().stopScan()
            OMRONLib.getInstance().stopSyncScan()
            
            // 停止监听 (如果SDK支持)
            // try {
            //     OMRONLib.getInstance().stopMonitoring()
            // } catch (e: Exception) {
            //     Log.w("OmronPlugin", "停止监听失败: ${e.message}")
            // }
            
            // 清空缓存
            scannedDevicesCache.clear()
            
            // 清空事件 sink
            statusEventSink = null
            scanEventSink = null
            syncScanEventSink = null
            
            Log.d("OmronPlugin", "✅ [Android] 资源清理完成")
        } catch (e: Exception) {
            Log.e("OmronPlugin", "❌ [Android] 清理资源失败: ${e.message}")
        }
    }
    
    /**
     * EventChannel.StreamHandler 接口实现（保留兼容性）
     */
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // 不再使用，由独立的StreamHandler处理
    }
    
    override fun onCancel(arguments: Any?) {
        // 不再使用，由独立的StreamHandler处理
    }
}

