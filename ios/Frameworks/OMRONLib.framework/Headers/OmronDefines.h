//
//  OmronDefines.h
//  OMRONLib 测量设备状态信息
//
//  Created by 俞多多 on 2022/11/4.
//  Copyright © 2022 Calvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark 蓝牙设备状态
typedef NS_ENUM(NSInteger, OMRONBLESStaus){
    OMRON_BLE_SCANING,//扫描中
    OMRON_BLE_SCANED,//扫描到设备
    OMRON_BLE_CONNECTING,//链接中
    OMRON_BLE_CONNECTED,//连接上设备
    OMRON_BLE_DISCONNECTING,//正在断开连接
    OMRON_BLE_DISCONNECTED,//断开连接
};

/*
 *  OMRONLib链接状态
 */

typedef NS_ENUM(NSInteger, OMRONLibStatus) {
    OMRONLIB_SCAN,                //开始扫描
    OMRONLIB_CONNECT,             //开始链接
    OMRONLIB_SYNC_DATA,            //开始数据同步
    OMRONLIB_SYNC_DATA_SUCCESS,    //数据同步成功
    OMRONLIB_SYNC_DATA_ERROR,      //数据同步失败
    OMRONLIB_DISCONNECTED          //断开链接
};

#pragma mark 蓝牙设备目标状态
typedef NS_ENUM(NSInteger, OMRONTargetDeviceState){
    STATE_ALL,
    STATE_PAIRING,
    STATE_SYNCING
};

#pragma mark 蓝牙设备连接状态
typedef NS_ENUM(NSInteger, OMRONBLEDeviceState){
    STATE_CONNECTING,
    STATE_CONNECTED,
    STATE_DISCONNECTING,
    STATE_DISCONNECTED
};

#pragma mark 设备状态字符串描述
extern NSString * OMRONBLEDeviceStateDescription(OMRONBLEDeviceState value);

#pragma mark 蓝牙设备类别
typedef NS_ENUM(NSInteger, OMRONDeviceCategory) {
    ALL_OMRON_DEVICE = 0,
    BLOOD_PRESSURE = 1, // 血压计
    BLOOD_GLUCOSE = 2,    // 血糖仪
    BODY_FAT = 4,  // 体脂仪
    BLOOD_OXYGEN = 5
};

#pragma mark 蓝牙设备类别名称
extern NSString * OMRONDeviceCategoryName(OMRONDeviceCategory value);

#pragma mark sdk状态
typedef NS_ENUM(NSInteger, OMRONSDKStatus){
    OMRON_SDK_Success,
    OMRON_SDK_UnRegister,
    OMRON_SDK_InValidKey,
    OMRON_SDK_NoNet,
    OMRON_SDK_UnOpenBlueTooth,
    OMRON_SDK_BlueToothError,
    OMRON_SDK_UnSupportDevice,
    OMRON_SDK_UnSupportDeviceCategory,
    OMRON_SDK_UnBind,
    OMRON_SDK_PINCodeError,
    OMRON_SDK_BOND_Invalid,
    OMRON_SDK_BOND_Cancel,
    OMRON_SDK_Disconnected,
    OMRON_SDK_BindFail,
    OMRON_SDK_NoDevice,
    OMRON_SDK_ConnectFail,
    OMRON_SDK_ScanTimeOut
};

#pragma mark sdk状态描述
extern NSString * OMRONSDKStatusDescription(OMRONSDKStatus value);

#pragma mark 体脂设备用户编号索引
@protocol OMRONBFAppendUserIndexDelegate
-(void)appendUserIndex:(NSInteger)index;
@end

#pragma mark 设备信息
@interface OMRONDeviceInfo : NSObject
@property (nonatomic, copy) NSString *modelName; // 设备类型
@property (nonatomic, copy) NSString *serialNumber; // 设备序列号
@property (nonatomic, copy) NSString *hardwareVersion; // 硬件版本号
@property (nonatomic, copy) NSString *softwareVersion; // 软件版本号
@property (nonatomic, copy) NSString *firmwareVersion; // 固件版本号
@property (nonatomic, strong) NSNumber *batteryLevel; // 设备电量
@property (nonatomic, copy) NSString *powerSupplyMode; // 供电模式
@property (nonatomic, copy) NSString *manufacturerName; // 制造商名称
@property (nonatomic, copy) NSString *modelNumber; // 设备代号
@property (nonatomic, copy) NSString *systemID; // 设备系统ID
@end

#pragma mark 血糖测量数据
@interface OMRONBGObject : NSObject
@property (nonatomic, assign) NSInteger   sequenceNumber;//序号
@property (nonatomic ,assign) long measureDate;//测量时间
@property (nonatomic, copy) NSString   *measureUnit;//测量单位
@property (nonatomic, assign) NSInteger    measureType;//测量类型
@property (nonatomic, copy) NSString   *measureValue;//测量值
@property (nonatomic, copy) NSString    *measureTypeDsc;// 测量状态
@property (nonatomic, copy) NSString    *meal;//用餐状态
@property (nonatomic, copy) NSString *device_type;//设备类型
@end

#pragma mark 血压测量数据
@interface OMRONBPObject : NSObject
@property (nonatomic, assign) NSInteger   sbp;
@property (nonatomic, assign) NSInteger   dbp;
@property (nonatomic, assign) NSInteger   pulse;
@property (nonatomic, assign) NSInteger   ihb_flg;// 0: normal; 1 abnormal
@property (nonatomic, assign) NSInteger   bm_flg;// 0:not move; 1 move
@property (nonatomic, assign) NSInteger   cws_flg;// 0: normal; 1 abnormal
@property (nonatomic, assign) NSInteger   measureUser;// 0:unset; 1:userA; 2:userB
@property (nonatomic, assign) NSInteger   afMode;// 0:not support; 1 support
@property (nonatomic, assign) NSInteger   af_flg;// 0:not af; 1 af
@property (nonatomic, assign) long        measure_at;
@property (nonatomic, copy) NSString *device_type;

//在这里添加需要扩展的字段

@end

#pragma mark 体脂测量数据
@interface OMRONBFObject: NSObject
@property (nonatomic, copy) NSString *bmi;//bmi
@property (nonatomic, assign) NSInteger basal_metabolism;//基础代谢
@property (nonatomic, assign) NSInteger body_age;//体年龄
@property (nonatomic, assign) CGFloat fat_rate;//体脂率
@property (nonatomic, assign) CGFloat weight;//体重
@property (nonatomic, assign) NSInteger userIndex;
@property (nonatomic, assign) NSInteger visceral_fat;//内脏脂肪水平
@property (nonatomic, assign) CGFloat skeletal_muscles_rate;//骨骼肌率
@property (nonatomic, assign) long measure_at;//测量时间
@property (nonatomic, copy) NSString *device_type;//设备类型
@property (nonatomic, assign) CGFloat height;//身高
@property (nonatomic, copy) NSString *birthday;//生日
@property (nonatomic, copy) NSString *gender;//0.男, 1.女
@end

#pragma mark 血氧测量数据
@interface OMRONBOObject : NSObject
@property (nonatomic, assign) NSInteger   spo;
@property (nonatomic, assign) NSInteger   pulse;
@property (nonatomic, assign) long        measure_at;
@property (nonatomic, copy) NSString *device_type;
@end

#pragma mark 欧姆龙通用蓝牙设备
@interface OMRONBleDevice : NSObject
@property (nonatomic, copy) NSString *localName;//设备名称
@property (nonatomic, copy) NSString *deviceType;// 类型名称
@property (nonatomic) OMRONDeviceCategory deviceCategory;// 设备种类
@property (nonatomic, copy) NSString *serialNum;// 设备序列号
@property (nonatomic, copy) NSString *userIndex;

- (instancetype)initWith:(NSString *)localName
              deviceType:(NSString *)deviceType
          deviceCategory:(OMRONDeviceCategory) deviceCategory;
- (instancetype)initWith:(NSString *)localName
              deviceType:(NSString *)deviceType
          deviceCategory:(OMRONDeviceCategory) deviceCategory
               userIndex:(NSString *)userIndex;

@end

NS_ASSUME_NONNULL_END
