import 'package:flutter/material.dart';

/// OMRON 设备类别枚举
/// 用于指定要扫描或操作的设备类型
enum OmronDeviceCategory {
  /// 所有欧姆龙设备
  all,
  
  /// 血压计
  bloodPressure,
  
  /// 血糖仪
  bloodGlucose,
  
  /// 体脂仪
  bodyFat,
  
  /// 血氧仪
  bloodOxygen;
  
  /// 转换为整数值（Android使用）
  int toValue() {
    switch (this) {
      case OmronDeviceCategory.all:
        return 0;
      case OmronDeviceCategory.bloodPressure:
        return 1;
      case OmronDeviceCategory.bloodGlucose:
        return 2;
      case OmronDeviceCategory.bodyFat:
        return 4;
      case OmronDeviceCategory.bloodOxygen:
        return 5;
    }
  }
  
  /// 转换为字符串（iOS使用）
  String toStringValue() {
    switch (this) {
      case OmronDeviceCategory.all:
        return 'ALL_OMRON_DEVICE';
      case OmronDeviceCategory.bloodPressure:
        return 'BLOOD_PRESSURE';
      case OmronDeviceCategory.bloodGlucose:
        return 'BLOOD_GLUCOSE';
      case OmronDeviceCategory.bodyFat:
        return 'BODY_FAT';
      case OmronDeviceCategory.bloodOxygen:
        return 'BLOOD_OXYGEN';
    }
  }
  
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case OmronDeviceCategory.all:
        return '所有设备';
      case OmronDeviceCategory.bloodPressure:
        return '血压计';
      case OmronDeviceCategory.bloodGlucose:
        return '血糖仪';
      case OmronDeviceCategory.bodyFat:
        return '体脂仪';
      case OmronDeviceCategory.bloodOxygen:
        return '血氧仪';
    }
  }
  
  /// 获取图标
  IconData get icon {
    switch (this) {
      case OmronDeviceCategory.all:
        return Icons.devices;
      case OmronDeviceCategory.bloodPressure:
        return Icons.favorite;
      case OmronDeviceCategory.bloodGlucose:
        return Icons.water_drop;
      case OmronDeviceCategory.bodyFat:
        return Icons.monitor_weight;
      case OmronDeviceCategory.bloodOxygen:
        return Icons.air;
    }
  }
}

