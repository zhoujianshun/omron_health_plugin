import Flutter
import UIKit
import OMRONLib

public class OmronHealthPlugin: NSObject, FlutterPlugin {
  // 插件单例,用于保持生命周期
  private static var sharedInstance: OmronHealthPlugin?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let instance = OmronHealthPlugin()
    
    // 保存单例引用,防止被释放
    sharedInstance = instance
    
    // 只在这里设置所有通道,避免重复注册
    instance.setupMethodChannel(with: messenger)
    instance.setupStatusEventChannel(with: messenger)
    instance.setupScanEventChannel(with: messenger)
    instance.setupSyncScanEventChannel(with: messenger)
    
    print("✅ [OmronHealthPlugin] 插件注册完成，通道名: \(OmronHealthPlugin.methodChannelName)")
  }



    private static let methodChannelName = "top.inomo.omron_health_plugin/omron"
    private static let statusEventChannelName = "top.inomo.omron_health_plugin/omron_status"
    private static let scanEventChannelName = "top.inomo.omron_health_plugin/omron_scan"
    private static let syncScanEventChannelName = "top.inomo.omron_health_plugin/omron_sync_scan"
    
    // EventChannel的事件发送器 - 状态通道
    var statusEventSink: FlutterEventSink?
    
    // EventChannel的事件发送器 - 绑定扫描通道
    var scanEventSink: FlutterEventSink?
    
    // EventChannel的事件发送器 - 同步扫描通道
    var syncScanEventSink: FlutterEventSink?
    
    // 用于跨多次扫描去重的设备集合 (如果需要持久化去重)
    private var scannedDevicesCache = Set<String>()
    
    /**
     * 确保所有回调在主线程执行，避免优先级反转
     */
    func dispatchOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
    
    
    
    /**
     * 配置 MethodChannel
     * @param messenger Flutter 二进制消息传递器
     */
    private  func setupMethodChannel(with messenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(
            name: OmronHealthPlugin.methodChannelName,
            binaryMessenger: messenger
        )
        
        methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { 
                print("❌ [OmronHealthPlugin] self 为 nil")
                return 
            }
            
            print("📥 [OmronHealthPlugin] 收到方法调用: \(call.method)")
            
            switch call.method {
            // case "getPlatformVersion":
            //     result("iOS " + UIDevice.current.systemVersion)
            case "initSdk":
                self.initSdk(result: result)
            case "register":
                guard let params = call.arguments as? [String: Any] else {
                    print("❌ [OmronHealthPlugin] 参数转换失败")
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "注册参数不能为空",
                        details: nil
                    ))
                    return
                }
                self.register(params: params, result: result)
            case "startBindScan":
                guard let params = call.arguments as? [String: Any] else {
                    print("❌ [OmronHealthPlugin] 扫描参数转换失败")
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "扫描参数不能为空",
                        details: nil
                    ))
                    return
                }
                self.startBindScan(params: params, result: result)
            case "stopScan":
                self.stopScan(result: result)
            case "startSyncScan":
                guard let params = call.arguments as? [String: Any] else {
                    print("❌ [OmronHealthPlugin] 同步扫描参数转换失败")
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "同步扫描参数不能为空",
                        details: nil
                    ))
                    return
                }
                self.startSyncScan(params: params, result: result)
            case "stopSyncScan":
                self.stopSyncScan(result: result)
            case "bindBpDevice":
                guard let params = call.arguments as? [String: Any] else {
                    print("❌ [OmronHealthPlugin] 绑定参数转换失败")
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "绑定参数不能为空",
                        details: nil
                    ))
                    return
                }
                self.bindBpDevice(params: params, result: result)
            case "getBpDeviceData":
                guard let params = call.arguments as? [String: Any] else {
                    print("❌ [OmronHealthPlugin] 同步数据参数转换失败")
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "同步数据参数不能为空",
                        details: nil
                    ))
                    return
                }
                self.getBpDeviceData(params: params, result: result)
            default:
                print("⚠️ [OmronHealthPlugin] 未实现的方法: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    /**
     * 初始化OMRON SDK（iOS无需此操作，空实现）
     * @param result 返回结果
     */
    private func initSdk(result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] initSdk 被调用")
        // iOS不需要init方法，直接返回成功
        result([
            "success": true,
            "message": "iOS无需初始化"
        ])
        print("✅ [OmronHealthPlugin] initSdk 返回成功")
    }
    
    /**
     * 注册OMRON SDK
     * @param params 注册参数
     * @param result 返回结果
     */
    private func register(params: [String: Any], result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] register 被调用")
        print("📦 [OmronHealthPlugin] 参数: \(params)")
        
        // 提取参数
        guard let appKey = params["appKey"] as? String,
              let packageName = params["packageName"] as? String,
              let packageSecret = params["packageSecret"] as? String else {
            print("❌ [OmronHealthPlugin] 参数验证失败")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "必需参数不能为空",
                details: nil
            ))
            return
        }
        
        let license = params["license"] as? String ?? ""
        let thirdUserId = params["thirdUserId"] as? String ?? ""
        
        print("🔑 [OmronHealthPlugin] appKey: \(appKey)")
        print("📦 [OmronHealthPlugin] packageName: \(packageName)")
        print("🔐 [OmronHealthPlugin] packageSecret: \(packageSecret)")
        print("📜 [OmronHealthPlugin] license: \(license)")
        print("👤 [OmronHealthPlugin] thirdUserId: \(thirdUserId)")
        
        // 调用registerApp进行注册（同步返回）
        print("📞 [OmronHealthPlugin] 开始调用 OMRONLib.shareInstance().registerApp()")
        let status = OMRONLib.shareInstance().registerApp(
            appKey,
            license: license,
            packageName: packageName,
            packageSecret: packageSecret,
            thirdUserId: thirdUserId
        )
        print("✅ [OmronHealthPlugin] registerApp 调用完成，状态码: \(status.rawValue)")
        
        // 映射状态并返回
        let resultMap = mapStatus(status)
        print("📤 [OmronHealthPlugin] 返回结果: \(resultMap)")
        dispatchOnMain {
        result(resultMap)
        }
    }
    
    /**
     * 映射OMRON SDK注册状态码到统一格式
     * @param status OMRONLibRegisterStatus枚举值（Objective-C枚举）
     * @return 包含状态和消息的字典
     */
    private func mapStatus(_ status: OMRONLibRegisterStatus) -> [String: Any] {
        let statusStr: String
        let message: String
        
        // Objective-C枚举在Swift中使用rawValue比较
        switch status {
        case .OMRONLIB_REGISTER_SUCCESS:
            statusStr = "success"
            message = "SDK注册成功"
        case .OMRONLIB_UNREGISTERED:
            statusStr = "unInit"
            message = "OMRONLib未初始化"
        case .OMRONLIB_KEY_ERROR:
            statusStr = "keyError"
            message = "appKey或ekiKey错误"
        case .OMRONLIB_EKIKEY_EXPIRED:
            statusStr = "ekiKeyExpired"
            message = "ekiKey已过期"
        case .OMRONLIB_PACKAGE_ERROR:
            statusStr = "packageError"
            message = "包名验证失败"
        case .OMRONLIB_THIRD_USER_BLOCKED:
            statusStr = "thirdUserBlocked"
            message = "当前用户已被冻结"
        case .OMRONLIB_FAILED_TO_OVER_FINGERPRINT:
            statusStr = "failedToOverFingerprint"
            message = "指纹授权量超过限制"
        case .OMRONLIB_ONLINE_ERROR:
            statusStr = "onlineError"
            message = "网络异常"
        case .OMRONLIB_FINGER_ERROR:
            statusStr = "fingerError"
            message = "指纹验证失败"
        @unknown default:
            statusStr = "unknown"
            message = "未知错误"
        }
        
        return [
            "status": statusStr,
            "message": message
        ]
    }
    
    /**
     * 映射OMRON SDK操作状态码到统一格式
     * @param status OMRONSDKStatus枚举值
     * @return 包含状态和消息的元组
     */
    private func mapSDKStatus(_ status: OMRONSDKStatus) -> (status: String, message: String) {
        switch status {
        case .OMRON_SDK_Success:
            return ("success", "操作成功")
        case .OMRON_SDK_UnRegister:
            return ("unregistered", "SDK未注册")
        case .OMRON_SDK_InValidKey:
            return ("invalidKey", "无效的密钥")
        case .OMRON_SDK_NoNet:
            return ("noNetwork", "无网络连接")
        case .OMRON_SDK_UnOpenBlueTooth:
            return ("bluetoothOff", "蓝牙未开启")
        case .OMRON_SDK_BlueToothError:
            return ("bluetoothError", "蓝牙错误")
        case .OMRON_SDK_UnSupportDevice:
            return ("unsupportedDevice", "不支持的设备")
        case .OMRON_SDK_UnBind:
            return ("notBound", "设备未绑定")
        case .OMRON_SDK_Disconnected:
            return ("disconnected", "设备已断开")
        case .OMRON_SDK_BindFail:
            return ("bindFailed", "绑定失败")
        case .OMRON_SDK_ConnectFail:
            return ("connectFailed", "连接失败")
        case .OMRON_SDK_ScanTimeOut:
            return ("scanTimeout", "扫描超时")
        default:
            return ("error", "未知错误,状态码: \(status.rawValue)")
        }
    }
    
    /**
     * 配置状态 EventChannel
     * @param messenger Flutter 二进制消息传递器
     */
    private func setupStatusEventChannel(with messenger: FlutterBinaryMessenger) {
        let statusEventChannel = FlutterEventChannel(
            name: OmronHealthPlugin.statusEventChannelName,
            binaryMessenger: messenger
        )
        
        statusEventChannel.setStreamHandler(StatusStreamHandler(plugin: self))
    }
    
    /**
     * 配置扫描 EventChannel
     * @param messenger Flutter 二进制消息传递器
     */
    private func setupScanEventChannel(with messenger: FlutterBinaryMessenger) {
        let scanEventChannel = FlutterEventChannel(
            name: OmronHealthPlugin.scanEventChannelName,
            binaryMessenger: messenger
        )
        
        scanEventChannel.setStreamHandler(ScanStreamHandler(plugin: self))
    }
    
    /**
     * 配置同步扫描 EventChannel
     * @param messenger Flutter 二进制消息传递器
     */
    private func setupSyncScanEventChannel(with messenger: FlutterBinaryMessenger) {
        let syncScanEventChannel = FlutterEventChannel(
            name: OmronHealthPlugin.syncScanEventChannelName,
            binaryMessenger: messenger
        )
        
        syncScanEventChannel.setStreamHandler(SyncScanStreamHandler(plugin: self))
    }
    
    /**
     * 开始扫描绑定状态的设备
     * @param params 扫描参数
     * @param result 返回结果
     */
    private func startBindScan(params: [String: Any], result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] startBindScan 被调用")
        print("📦 [OmronHealthPlugin] 参数: \(params)")
        
        // 提取设备类别参数
        guard let categoryString = params["categoryString"] as? String else {
            print("❌ [OmronHealthPlugin] categoryString 参数缺失")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "设备类别参数缺失",
                details: nil
            ))
            return
        }
        
        // 转换为OMRONDeviceCategory
        let category: OMRONDeviceCategory
        switch categoryString {
        case "ALL_OMRON_DEVICE":
            category = .ALL_OMRON_DEVICE
        case "BLOOD_PRESSURE":
            category = .BLOOD_PRESSURE
        case "BLOOD_GLUCOSE":
            category = .BLOOD_GLUCOSE
        case "BODY_FAT":
            category = .BODY_FAT
        case "BLOOD_OXYGEN":
            category = .BLOOD_OXYGEN
        default:
            category = .ALL_OMRON_DEVICE
        }
        
        print("📦 [OmronHealthPlugin] 扫描设备类别: \(category.rawValue)")
        
        // 调用OMRON SDK开始扫描
        OMRONLib.shareInstance().scanBindDevices(category) { [weak self] (status, bleDevice) in
            print("📥 [OmronHealthPlugin] 扫描回调 - 状态: \(status.rawValue)")
            
            // 处理不同的扫描状态
            switch status {
            case .OMRON_SDK_Success:
                // 扫描到设备
                guard let device = bleDevice else {
                    print("⚠️ [OmronHealthPlugin] bleDevice 为 nil")
                    return
                }
                
                let deviceName = device.localName
                print("📥 [OmronHealthPlugin] 扫描到设备: \(deviceName)")
                
                // 构造设备信息Dictionary
                let deviceInfo: [String: Any] = [
                    "deviceType": device.deviceType,
                    "deviceName": deviceName,
                    "userIndex": device.userIndex,
                    "deviceSerialNum": device.serialNum,
                    "category": categoryString
                ]
                
                print("📤 [OmronHealthPlugin] 发送设备到Flutter: \(deviceName)")
                
                // 通过EventSink发送到Flutter
                self?.dispatchOnMain {
                    guard let strongSelf = self else { return }
                    strongSelf.scanEventSink?(deviceInfo)
                }
                
            case .OMRON_SDK_ScanTimeOut:
                // 扫描超时（周期结束）
                print("🔄 [OmronHealthPlugin] 扫描超时/周期结束")
                OMRONLib.shareInstance().stopScanBindDevices()
                
                // 发送扫描完成事件到Flutter
                let scanFinishMap: [String: Any] = [
                    "isFinished": true,
                    "message": "扫描周期结束"
                ]
                self?.dispatchOnMain {
                    guard let strongSelf = self else { return }
                    strongSelf.scanEventSink?(scanFinishMap)
                }
                
            default:
                // 其他错误状态
                print("❌ [OmronHealthPlugin] 扫描失败，状态: \(status.rawValue)")
                OMRONLib.shareInstance().stopScanBindDevices()
                
                self?.dispatchOnMain {
                    guard let strongSelf = self else { return }
                    strongSelf.scanEventSink?(FlutterError(
                        code: "SCAN_FAILED",
                        message: "设备扫描失败，状态码: \(status.rawValue)",
                        details: nil
                    ))
                }
            }
        }
        
        dispatchOnMain {
            result(["success": true])
        }
        print("✅ [OmronHealthPlugin] startBindScan 启动成功")
    }
    
    /**
     * 停止扫描设备
     * @param result 返回结果
     */
    private func stopScan(result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] stopScan 被调用")
        OMRONLib.shareInstance().stopScanBindDevices()
        dispatchOnMain {
            result(["success": true])
        }
        print("✅ [OmronHealthPlugin] stopScan 执行成功")
    }
    
    /**
     * 开始同步扫描
     */
    private func startSyncScan(params: [String: Any], result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] startSyncScan 被调用")
        print("📦 [OmronHealthPlugin] 参数: \(params)")
        
        guard let devicesList = params["devices"] as? [[String: Any]] else {
            print("❌ [OmronHealthPlugin] 设备列表为空或类型错误")
            dispatchOnMain {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "设备列表不能为空",
                    details: nil
                ))
            }
            return
        }
        
        let scanPeriod = params["scanPeriod"] as? Int ?? 60
        
        // 验证扫描周期
        if scanPeriod < 1 || scanPeriod > 300 {
            print("❌ [OmronHealthPlugin] 扫描周期无效: \(scanPeriod)")
            dispatchOnMain {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "扫描周期必须在1-300秒之间",
                    details: nil
                ))
            }
            return
        }
        
        // 转换设备列表为Swift数组
        var deviceArray: [[String: Any]] = []
        for deviceMap in devicesList {
            // 创建设备字典，使用iOS SDK期望的格式
            var deviceDict: [String: Any] = [:]
            
            if let deviceType = deviceMap["deviceType"] as? String {
                deviceDict["deviceType"] = deviceType
            }
            
            if let deviceSerialNum = deviceMap["deviceSerialNum"] as? String {
                deviceDict["deviceSerialNum"] = deviceSerialNum
            }
            
            // deviceId是可选的
            if let deviceId = deviceMap["deviceId"] as? String {
                deviceDict["deviceId"] = deviceId
            }
            
            deviceArray.append(deviceDict)
            print("  ✓ 添加设备: \(deviceDict)")
        }
        
        if deviceArray.isEmpty {
            print("❌ [OmronHealthPlugin] 没有有效的设备")
            dispatchOnMain {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "没有有效的设备信息",
                    details: nil
                ))
            }
            return
        }
        
        print("📡 [OmronHealthPlugin] 开始同步扫描，设备数: \(deviceArray.count)")
        
        // 用于去重的Set（使用deviceSerialNum作为唯一标识）
        var scannedDevices = Set<String>()
        
        // 调用SDK的scanSyncDevices方法
        // 方法签名: scanSyncDevices:complete:，期望一个数组
        OMRONLib.shareInstance().scanSyncDevices(deviceArray) { [weak self] (status, bleDevice) in
            guard let strongSelf = self else { return }
            
            print("📥 [OmronHealthPlugin] 同步扫描回调触发，状态: \(status.rawValue)")
            
            switch status {
            case .OMRON_SDK_Success:
                // 扫描到设备
                if let device = bleDevice {
                    // iOS字段名: serialNum (不是deviceSerialNum)
                    let serialNum = (device.value(forKey: "serialNum") as? String) ?? ""
                    
                    // 去重检查：只有第一次扫描到的设备才发送
                    if !scannedDevices.contains(serialNum) {
                        scannedDevices.insert(serialNum)
                        
                        print("✅ [OmronHealthPlugin] 扫描到新设备（去重后）: \(serialNum)")
                        
                        // 构建设备信息Map - 使用正确的iOS字段名
                        var deviceInfo: [String: Any] = [
                            "deviceName": "未知设备",
                            "deviceSerialNum": serialNum, // Flutter统一使用deviceSerialNum
                            "scannedAt": Date().timeIntervalSince1970 * 1000
                        ]
                        
                        // iOS字段映射：
                        // localName -> deviceName
                        // deviceType -> deviceType
                        // deviceCategory -> category
                        // serialNum -> deviceSerialNum
                        // userIndex -> userIndex
                        
                        if let localName = device.value(forKey: "localName") as? String {
                            deviceInfo["deviceName"] = localName
                            print("  ✓ localName: \(localName)")
                        }
                        
                        if let deviceType = device.value(forKey: "deviceType") as? String {
                            deviceInfo["deviceType"] = deviceType
                            print("  ✓ deviceType: \(deviceType)")
                        }
                        
                        if let deviceCategory = device.value(forKey: "deviceCategory") {
                            // deviceCategory是枚举，转为字符串或数字
                            deviceInfo["category"] = String(describing: deviceCategory)
                            print("  ✓ deviceCategory: \(deviceCategory)")
                        }
                        
                        if let userIndex = device.value(forKey: "userIndex") as? String {
                            deviceInfo["userIndex"] = userIndex
                            print("  ✓ userIndex: \(userIndex)")
                        }
                        
                        print("📤 [OmronHealthPlugin] 发送同步设备到Flutter: \(deviceInfo)")
                        
                        // 发送设备信息到Flutter
                        strongSelf.dispatchOnMain {
                            strongSelf.syncScanEventSink?(deviceInfo)
                        }
                    } else {
                        print("⏭️ [OmronHealthPlugin] 跳过重复设备: \(serialNum)")
                    }
                }
                
            case .OMRON_SDK_ScanTimeOut:
                // 扫描超时（周期结束）
                print("🏁 [OmronHealthPlugin] 同步扫描周期结束")
                
                let scanFinishMap: [String: Any] = [
                    "isFinished": true,
                    "message": "同步扫描周期结束"
                ]
                
                strongSelf.dispatchOnMain {
                    strongSelf.syncScanEventSink?(scanFinishMap)
                }
                
            default:
                // 扫描失败
                print("❌ [OmronHealthPlugin] 同步扫描失败，状态码: \(status.rawValue)")
                
                // 停止扫描
                OMRONLib.shareInstance().stopScanSyncDevices()
                
                strongSelf.dispatchOnMain {
                    strongSelf.syncScanEventSink?(FlutterError(
                        code: "SYNC_SCAN_FAILED",
                        message: "同步扫描失败，状态码: \(status.rawValue)",
                        details: nil
                    ))
                }
            }
        }
        
        // 立即返回成功
        dispatchOnMain {
            result(["success": true])
        }
        print("✅ [OmronHealthPlugin] startSyncScan 启动成功")
    }
    
    /**
     * 停止同步扫描
     */
    private func stopSyncScan(result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] stopSyncScan 被调用")
        OMRONLib.shareInstance().stopScanSyncDevices()
        dispatchOnMain {
            result(["success": true])
        }
        print("✅ [OmronHealthPlugin] stopSyncScan 执行成功")
    }
    
    /**
     * 清理资源和停止所有操作
     */
    func cleanup() {
        print("🧹 [OmronHealthPlugin] 开始清理资源")
        
        // 停止所有扫描
        OMRONLib.shareInstance().stopScanBindDevices()
        OMRONLib.shareInstance().stopScanSyncDevices()
        OMRONLib.shareInstance().stopMonitoring()
        
        // 清空缓存
        scannedDevicesCache.removeAll()
        
        // 清空事件 sink
        statusEventSink = nil
        scanEventSink = nil
        syncScanEventSink = nil
        
        print("✅ [OmronHealthPlugin] 资源清理完成")
    }
    
    /**
     * 提取血压数据字段
     * 直接使用对象属性访问 (更高效,更安全)
     *
     * @param bpObject OMRONBPObject对象
     * @return Dictionary包含所有血压数据字段
     */
    private func extractBpDataFields(_ bpObject: OMRONBPObject) -> [String: Any] {
        // 使用直接属性访问而非 KVC (性能更好,类型安全)
        let bpMap: [String: Any] = [
            "systolic": bpObject.sbp,              // 收缩压
            "diastolic": bpObject.dbp,             // 舒张压
            "pulse": bpObject.pulse,               // 脉搏
            "arrhythmiaFlag": bpObject.ihb_flg,    // 心律不齐标志 (0: 正常; 1: 异常)
            "bodyMovementFlag": bpObject.bm_flg,   // 身体移动标志 (0: 未移动; 1: 移动)
            "cuffWrapFlag": bpObject.cws_flg,      // 袖带佩戴标志 (0: 正常; 1: 异常)
            "measureUser": bpObject.measureUser,   // 测量用户 (0: 未设置; 1: 用户A; 2: 用户B)
            "measureTime": bpObject.measure_at,    // 测量时间（时间戳，毫秒）
            "afibMode": bpObject.afMode,           // 房颤模式 (0: 不支持; 1: 支持)
            "afibFlag": bpObject.af_flg,           // 房颤标志 (0: 无房颤; 1: 有房颤)
            "deviceType": bpObject.device_type ?? ""  // 设备类型
        ]
        
        print("✅ [OmronHealthPlugin] BP数据: 血压=\(bpObject.sbp)/\(bpObject.dbp), 脉搏=\(bpObject.pulse), 时间=\(bpObject.measure_at)")
        
        return bpMap
    }
    
    /**
     * 绑定血压计设备
     * @param params 绑定参数
     * @param result 返回结果
     */
    private func bindBpDevice(params: [String: Any], result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] bindBpDevice 被调用")
        
        guard let deviceType = params["deviceType"] as? String else {
            print("❌ [OmronHealthPlugin] deviceType 为空")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "deviceType不能为空",
                details: nil
            ))
            return
        }
        
        let deviceSerialNum = params["deviceSerialNum"] as? String
        print("📦 [OmronHealthPlugin] deviceType: \(deviceType), deviceSerialNum: \(String(describing: deviceSerialNum))")
        
        // 调用 Omron SDK 绑定血压计
        OMRONLib.shareInstance().bindBpDevice(
            deviceType,
            deviceSerialNum: deviceSerialNum
        ) { [weak self] (status, deviceType, deviceSerialNum, deviceId, deviceInfo, datas) in
            
            print("🔵 [OmronHealthPlugin] bindBpDevice 回调触发")
            print("📦 [OmronHealthPlugin] status: \(status.rawValue)")
            
            // 使用新的状态映射方法
            let mappedStatus = self?.mapSDKStatus(status)
            let statusString = mappedStatus?.status ?? "error"
            let statusMessage = mappedStatus?.message ?? "未知错误"
            
            // 构建设备信息 - 提取所有字段
            var deviceInfoMap: [String: Any] = [:]
            if deviceInfo != nil {
                // 定义需要提取的字段列表
                let fieldNames = [
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
                ]
                
                // 使用KVC提取所有字段
                for fieldName in fieldNames {
                    if let value = deviceInfo.value(forKey: fieldName) {
                        // 检查是否为NSNull
                        if !(value is NSNull) {
                            deviceInfoMap[fieldName] = value
                            print("  ✓ \(fieldName): \(value)")
                        }
                    }
                }
            }
            
            // 构建血压数据列表 - 使用辅助函数提取字段
            var bpDataList: [[String: Any]] = []
            if datas != nil && datas.count > 0 {
                for bpObject in datas {
                    if let bpMap = self?.extractBpDataFields(bpObject) {
                        bpDataList.append(bpMap)
                    }
                }
            }
            
            // 构建返回结果
            let resultMap: [String: Any] = [
                "status": statusString,
                "deviceType": deviceType ?? "",
                "deviceSerialNum": deviceSerialNum ?? "",
                "deviceId": deviceId ?? "",
                "deviceInfo": deviceInfoMap,
                "bpDataList": bpDataList,
                "message": statusString == "success"
                    ? "绑定成功，获取到\(bpDataList.count)条数据"
                    : statusMessage
            ]
            
            print("📤 [OmronHealthPlugin] 返回数据: \(resultMap)")
            self?.dispatchOnMain {
                result(resultMap)
            }
        }
    }
    
    /**
     * 同步血压计测量数据
     * 获取血压计中所有未同步过的血压数据
     *
     * iOS API:
     * getBpDeviceData:(NSString *) deviceType
     *     deviceSerialNum:(NSString *)deviceSerialNum
     *            complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBPObject *> *datas))complete
     *
     * @param params 参数Map，包含:
     *   - deviceType: 设备类型 (必须)
     *   - deviceSerialNum: 绑定接口返回的设备唯一码 (必须)
     * @param result Flutter结果回调
     */
    private func getBpDeviceData(params: [String: Any], result: @escaping FlutterResult) {
        print("🔵 [OmronHealthPlugin] getBpDeviceData 被调用")
        
        guard let deviceType = params["deviceType"] as? String else {
            print("❌ [OmronHealthPlugin] deviceType 为空")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "deviceType不能为空",
                details: nil
            ))
            return
        }
        
        guard let deviceSerialNum = params["deviceSerialNum"] as? String else {
            print("❌ [OmronHealthPlugin] deviceSerialNum 为空")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "deviceSerialNum不能为空",
                details: nil
            ))
            return
        }
        
        print("📦 [OmronHealthPlugin] deviceType: \(deviceType)")
        print("📦 [OmronHealthPlugin] deviceSerialNum: \(deviceSerialNum)")
        
        // 调用 Omron SDK 获取血压数据
        OMRONLib.shareInstance().getBpDeviceData(
            deviceType,
            deviceSerialNum: deviceSerialNum
        ) { [weak self] (status, datas) in
            
            print("🔵 [OmronHealthPlugin] getBpDeviceData 回调触发")
            print("📦 [OmronHealthPlugin] status: \(status.rawValue)")
            print("📦 [OmronHealthPlugin] datas count: \(datas.count)")
            
            // 使用新的状态映射方法
            let mappedStatus = self?.mapSDKStatus(status)
            let statusString = mappedStatus?.status ?? "error"
            let statusMessage = mappedStatus?.message ?? "未知错误"
            
            // 构建血压数据列表 - 使用辅助函数提取字段
            var bpDataList: [[String: Any]] = []
            if datas != nil && datas.count > 0 {
                for bpObject in datas {
                    if let bpMap = self?.extractBpDataFields(bpObject) {
                        bpDataList.append(bpMap)
                    }
                }
            }
            
            print("📊 [OmronHealthPlugin] 解析得到 \(bpDataList.count) 条数据")
            
            // 构建返回结果
            let resultMap: [String: Any] = [
                "status": statusString,
                "deviceType": deviceType,
                "deviceSerialNum": deviceSerialNum,
                "deviceId": "", // 同步数据接口不返回deviceId
                "deviceInfo": [:], // 同步数据接口不返回设备信息
                "bpDataList": bpDataList,
                "message": statusString == "success"
                    ? "同步成功，获取到\(bpDataList.count)条数据"
                    : statusMessage
            ]
            
            print("📤 [OmronHealthPlugin] 返回数据: \(resultMap)")
            self?.dispatchOnMain {
                result(resultMap)
            }
        }
    }
}



// MARK: - 状态StreamHandler
class StatusStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: OmronHealthPlugin?
    
    init(plugin: OmronHealthPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("🔵 [OmronHealthPlugin] 状态通道 onListen 被调用")
        plugin?.statusEventSink = events
        
        // 设置OMRON SDK的状态回调
        OMRONLib.shareInstance().statusBlock = { [weak self] status in
            print("📥 [OmronHealthPlugin] 收到状态回调: \(status.rawValue)")
            
            // 将OMRONLibStatus转换为字符串
            let statusString: String
            switch status {
            case .OMRONLIB_SCAN:
                statusString = "scan"
            case .OMRONLIB_CONNECT:
                statusString = "connect"
            case .OMRONLIB_SYNC_DATA:
                statusString = "syncData"
            case .OMRONLIB_SYNC_DATA_SUCCESS:
                statusString = "syncDataSuccess"
            case .OMRONLIB_SYNC_DATA_ERROR:
                statusString = "syncDataError"
            case .OMRONLIB_DISCONNECTED:
                statusString = "disconnected"
            @unknown default:
                statusString = "unknown"
            }
            
            print("📤 [OmronHealthPlugin] 发送状态到Flutter: \(statusString)")
            
            // 发送状态到Flutter
            if let plugin = self?.plugin {
                plugin.dispatchOnMain {
                    plugin.statusEventSink?(statusString)
                }
            }
        }
        
        print("✅ [OmronHealthPlugin] 状态监听已启动")
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("🔵 [OmronHealthPlugin] 状态通道 onCancel 被调用")
        plugin?.statusEventSink = nil
//        OMRONLib.shareInstance().statusBlock = nil
        print("✅ [OmronHealthPlugin] 状态监听已清理")
        return nil
    }
}

    


// MARK: - 扫描StreamHandler
class ScanStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: OmronHealthPlugin?
    
    init(plugin: OmronHealthPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("🔵 [OmronHealthPlugin] 绑定扫描通道 onListen 被调用")
        plugin?.scanEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("🔵 [OmronHealthPlugin] 绑定扫描通道 onCancel 被调用")
        plugin?.scanEventSink = nil
        return nil
    }
}

// MARK: - 同步扫描StreamHandler
class SyncScanStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: OmronHealthPlugin?
    
    init(plugin: OmronHealthPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("🔵 [OmronHealthPlugin] 同步扫描通道 onListen 被调用")
        plugin?.syncScanEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("🔵 [OmronHealthPlugin] 同步扫描通道 onCancel 被调用")
        plugin?.syncScanEventSink = nil
        return nil
    }
}

