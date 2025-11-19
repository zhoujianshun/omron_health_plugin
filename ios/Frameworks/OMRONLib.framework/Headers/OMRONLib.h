//
//  OMRONLib.h
//  OMRONLib
//
//  Created by Calvin on 2019/5/8.
//  Copyright © 2019 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "OmronDefines.h"

NS_ASSUME_NONNULL_BEGIN

/*
 *  用户敏感信息可见等级设置
 */
typedef NS_ENUM(NSInteger, OMRONSensitiveLogLevel){
    OMRONLOG_NONE,       //完全不可见：release环境默认
    OMRONLOG_DEFAULT,    //敏感信息后一半可见，其他部分用“*”代替
    OMRONLOG_ALL,        //完全可见：debug环境默认
};

/*
 *  日志可见等级设置
 */
typedef NS_ENUM(NSInteger, OMRONLogPrintLevel){
    OMRONLOG_PRINT_DEBUG,     //全部日志: debug环境默认
    OMRONLOG_PRINT_INFO,      //过滤掉部分的日志
    OMRONLOG_PRINT_WARN,      //包含警告的日志
    OMRONLOG_PRINT_ERROR,     //包含错误的日志: release环境默认
    OMRONLOG_PRINT_FATAL      //异常的日志: 可能导致程序异常,需要注意
};

/*
 *  OMRONLib初始化状态
 */
typedef NS_ENUM(NSInteger, OMRONLibRegisterStatus) {
    OMRONLIB_UNREGISTERED,           //OMRONLib未初始化
    OMRONLIB_REGISTER_SUCCESS,       //OMRONLib初始化成功
    OMRONLIB_KEY_ERROR,              //appKey或ekiKey错误
    OMRONLIB_EKIKEY_EXPIRED,          //ekiKey过期
    OMRONLIB_PACKAGE_ERROR,          //包名验证失败
    OMRONLIB_THIRD_USER_BLOCKED,    //当前用户已冻结
    OMRONLIB_FAILED_TO_OVER_FINGERPRINT, //指纹授权量超过
    OMRONLIB_ONLINE_ERROR,         //网络异常
    OMRONLIB_FINGER_ERROR          //指纹验证失败
};

@interface OMRONLib : NSObject

// 敏感信息可见等级：debug环境完全可见，release环境部分可见
@property (nonatomic, assign) OMRONSensitiveLogLevel logLevel;

// 控制台日志可见等级：debug环境所有日志完全可见，release环境部分可见
@property (nonatomic, assign) OMRONLogPrintLevel logPrintLevel;

// OMRONLib链接状态
@property (nonatomic, copy) void (^statusBlock)(OMRONLibStatus status);


/*
 *  获取OMRONLib 对象
 *  @return  返回OBROMLib 对象
 */
+ (instancetype)shareInstance;

/*
 *  @appKey OMRON 厂商Key
 *  @license OMRON 设备授权license
 *  @packageName app包名
 *  @thirdUserId 第三方id
 *  @packageSecret 包名密码
 */
- (OMRONLibRegisterStatus)registerApp:(NSString *)appKey
                              license:(NSString * _Nullable)license
                          packageName:(NSString *)packageName
                        packageSecret:(NSString *)packageSecret
                          thirdUserId:(NSString * _Nullable)thirdUserId;


/*
 *  取消注册
 */
-(void)unRegister;

//app是否注册
- (BOOL)isRegistered;


#pragma mark 获取可配对的设备类型列表
- (NSArray *)getDeviceTypeList:(OMRONDeviceCategory) deviceCategory;

#pragma mark 根据设备类别搜索设备
-(void)scanAllDevicescomplete:(OMRONDeviceCategory) deviceCategory
                   deviceType:(NSString * _Nullable) deviceType
              deviceSerialNum:(NSString * _Nullable) deviceSerialNum
                     complete:(void(^)(OMRONSDKStatus status,NSString *deviceName,NSString *deviceId,NSString *deviceSerialNum,CBPeripheral *peripheral))complete;

-(void)scanBgDevicescomplete:(NSArray <OMRONBleDevice *> *)bgDeviceArray
                    complete:(void(^)(OMRONSDKStatus status,NSString *deviceName, NSString *deviceType, NSString *deviceId, NSString *deviceSerialNum,CBPeripheral *peripheral))complete;

#pragma mark 搜索指定的设备
-(void)scanTargetDevicescomplete:(NSArray *)deviceArray
                        complete:(void(^)(OMRONSDKStatus status,NSString *deviceName,NSString *deviceId,NSString *deviceSerialNum,CBPeripheral *peripheral))complete;

#pragma mark 搜索指定的绑定状态的设备
-(void)scanBindDevices:(OMRONDeviceCategory)deviceCategory
              complete:(void(^)(OMRONSDKStatus status, OMRONBleDevice  * _Nullable bleDevice))complete;
#pragma mark 停止绑定状态设备的搜索
- (void)stopScanBindDevices;

#pragma mark 搜索指定的同步状态的设备
-(void)scanSyncDevices:(NSArray *)deviceArray
              complete:(void(^)(OMRONSDKStatus status, OMRONBleDevice  * _Nullable bleDevice))complete;
#pragma mark 停止同步状态设备的搜索
-(void)stopScanSyncDevices;

#pragma mark 停止扫描周围设备
- (void)stopScanAllDevices;

#pragma mark 停止绑定设备
-(void)stopConnect:(void(^)(BOOL isCancel))complete;

#pragma mark 血压设备绑定
- (void)bindBpDevice:(NSString * _Nonnull) deviceType
     deviceSerialNum:(NSString * _Nullable)deviceSerialNum
            complete:(void(^)(OMRONSDKStatus status,NSString *deviceType,NSString *deviceSerialNum,NSString *deviceId, OMRONDeviceInfo * deviceInfo,NSArray<OMRONBPObject *> *datas))complete;

#pragma mark 获取血压设备数据
- (void)getBpDeviceData:(NSString *)deviceType
        deviceSerialNum:(NSString *)deviceSerialNum
               complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBPObject *> *datas))complete;

#pragma mark 血压设备监听回调函数
typedef void (^BpObserverBlock)(OMRONSDKStatus status, NSArray<OMRONBPObject *> * _Nullable datas);

#pragma mark 多个血压设备监听回调函数
typedef void (^BpsObserverBlock)(OMRONSDKStatus status, OMRONBleDevice * _Nullable bpDevice, NSArray<OMRONBPObject *> * _Nullable datas);

#pragma mark 开启血压设备监听
- (void)startBpMonitoring:(NSString *)deviceType deviceSerialNum:(NSString *)deviceSerialNum complete:(BpObserverBlock) complete;

#pragma mark 开启多个血压设备监听
- (void)startBpMonitoring:(NSArray<OMRONBleDevice*> *)bpDeviceArray complete:(BpObserverBlock)complete;

#pragma mark 体脂设备绑定
- (void)bindBfDevice:(NSString *) deviceType
              status:(void(^)(OMRONBLESStaus statue))status
      userIndexBlock:(void(^)(NSString *deviceId,id<OMRONBFAppendUserIndexDelegate> indexData))userIndexBlock
            birthday:(NSDate *)birthday
              height:(CGFloat)height
              isMale:(BOOL)isMale
            complete:(void(^)(OMRONSDKStatus status,NSString *deviceType,NSInteger userIndex,NSString *deviceSerialNum, NSDictionary *userInfo,OMRONDeviceInfo * deviceInfo,NSArray<OMRONBPObject *> *datas))complete;

#pragma mark 获取体脂设备数据
-(void)getBfDeviceData:(NSString *) deviceType deviceSerialNum:(NSString *)deviceSerialNum userIndex:(NSInteger)userIndex birthday:(NSDate *)birthday height:(CGFloat)height isMale:(BOOL)isMale complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBFObject *> *datas, NSDictionary *userInfo))complete;

#pragma mark 获取体脂设备数据
-(void)getBfDeviceData:(NSArray <OMRONBleDevice *> *)bfDeviceArray birthday:(NSDate *)birthday height:(CGFloat)height isMale:(BOOL)isMale complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBFObject *> *datas, NSDictionary *userInfo))complete;

#pragma mark 体脂设备监听回调函数
typedef void (^BfObserverBlock)(OMRONSDKStatus status, NSArray<OMRONBFObject *> * _Nullable datas, NSDictionary * _Nullable userInfo);

#pragma mark 开启体脂仪监听
- (void)startBfMonitoring:(NSString *) deviceType deviceSerialNum:(NSString *)deviceSerialNum userIndex:(NSInteger)userIndex birthday:(NSDate *)birthday height:(CGFloat)height isMale:(BOOL)isMale complete:(BfObserverBlock) complete;

#pragma mark 开启体脂仪监听
- (void)startBfMonitoring:(NSArray <OMRONBleDevice *> *)bfDeviceArray birthday:(NSDate *)birthday height:(CGFloat)height isMale:(BOOL)isMale complete:(BfObserverBlock) complete;

// 绑定血氧仪设备
- (void)bindBoDevice:(NSString * _Nonnull) deviceType
     deviceSerialNum:(NSString * _Nullable)deviceSerialNum
            complete:(void(^)(OMRONSDKStatus status,NSString *deviceType,NSString *deviceSerialNum,NSString *deviceId, OMRONDeviceInfo * deviceInfo,NSArray<OMRONBOObject *> *datas))complete;

#pragma mark 获取血氧设备数据
- (void)getBoDeviceData:(NSArray <OMRONBleDevice *> *)boDeviceArray
               complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBOObject *> *datas))complete;

#pragma mark 获取血氧设备数据
- (void)getBoDeviceData:(NSString *) deviceType
        deviceSerialNum:(NSString *)deviceSerialNum
               complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBOObject *> *datas))complete;

#pragma mark 血氧设备监听回调函数
typedef void (^BoObserverBlock)(OMRONSDKStatus status, NSArray<OMRONBOObject *> * _Nullable datas);

#pragma mark 开启血氧设备监听
- (void)startBoMonitoring:(NSString *)deviceType
          deviceSerialNum:(NSString *)deviceSerialNum
                 complete:(BoObserverBlock)complete;

#pragma mark 开启血氧设备监听
- (void)startBoMonitoring:(NSArray <OMRONBleDevice *> *)boDeviceArray
                 complete:(BoObserverBlock)complete;

#pragma mark 停止监听
- (void)stopMonitoring;

#pragma mark 监听是否已开启
- (BOOL)isMonitoring;

#pragma mark 是否正在同步数据
- (BOOL)isSyncing;

#pragma mark 绑定血糖仪
- (void)bindBgDevice:(NSString * _Nonnull) deviceType
     deviceSerialNum:(NSString * _Nonnull)deviceSerialNum
          peripheral:(CBPeripheral * _Nonnull) peripheral
            complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBGObject *> * _Nullable datas, OMRONDeviceInfo * _Nullable deviceInfo))complete;

#pragma mark 获取血糖仪测量数据
- (void)getBgDeviceData:(NSString * _Nonnull) deviceType
        deviceSerialNum:(NSString * _Nonnull)deviceSerialNum
             peripheral:(CBPeripheral * _Nonnull) peripheral
               complete:(void(^)(OMRONSDKStatus status,NSArray<OMRONBGObject *> * _Nullable datas))complete;

#pragma mark 血糖仪监听回调函数
typedef void (^BgObserverBlock)(OMRONSDKStatus status, NSArray<OMRONBGObject *> * _Nullable datas);

#pragma mark 开启血糖仪监听
- (void)startBgMonitoring:(NSString *) deviceType deviceSerialNum:(NSString *)deviceSerialNum complete:(BgObserverBlock) complete;

#pragma mark 开启血糖仪监听
- (void)startBgMonitoring:(NSArray <OMRONBleDevice *> *)bgDeviceArray complete:(BgObserverBlock) complete;

#pragma mark 删除离线设备
- (void)deleteDeviceByUnlineNetList:(NSString *)deviceDigitalId;

#pragma mark 获取指纹数据
- (NSString *)getDeviceIDInKeychainUUID;


@end

NS_ASSUME_NONNULL_END
