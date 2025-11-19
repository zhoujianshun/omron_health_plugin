
import 'package:omron_health_plugin/omron/omron_bind_result.dart';
import 'package:omron_health_plugin/omron/omron_config.dart';
import 'package:omron_health_plugin/omron/omron_connection_status.dart';
import 'package:omron_health_plugin/omron/omron_device_category.dart';
import 'package:omron_health_plugin/omron/omron_result.dart';
import 'package:omron_health_plugin/omron/omron_scan_event.dart';
import 'package:omron_health_plugin/omron/omron_scanned_device.dart';
import 'package:omron_health_plugin/omron/omron_sync_device.dart';

import 'omron_health_plugin_platform_interface.dart';

class OmronHealthPlugin {


  static final OmronHealthPlugin instance = OmronHealthPlugin._();

  OmronHealthPlugin._();

  // Future<String?> getPlatformVersion() {
  //   return OmronHealthPluginPlatform.instance.getPlatformVersion();
  // }

  Future<void> initSdk() {
    return OmronHealthPluginPlatform.instance.initSdk();
  }

  Future<OmronInitResult> register(OmronConfig config) {
    return OmronHealthPluginPlatform.instance.register(config);
  }

  Stream<OmronConnectionStatus> startConnectionStatusListener() {
    return OmronHealthPluginPlatform.instance.startConnectionStatusListener();
  }

  Stream<OmronScanEvent<OmronScannedDevice>> startBindScan(OmronDeviceCategory category, {int timeout = 60}) {
    return OmronHealthPluginPlatform.instance.startBindScan(category, timeout: timeout);
  }

  Future<void> stopScan() {
    return OmronHealthPluginPlatform.instance.stopScan();
  }

  Stream<OmronScanEvent<OmronScannedDevice>> startSyncScan(List<OmronSyncDevice> devices, {int scanPeriod = 60}) {
    return OmronHealthPluginPlatform.instance.startSyncScan(devices, scanPeriod: scanPeriod);
  }

  Future<void> stopSyncScan() {
    return OmronHealthPluginPlatform.instance.stopSyncScan();
  }

  Future<OmronBindResult> bindBpDevice({required String deviceType, required String deviceSerialNum}) {
    return OmronHealthPluginPlatform.instance.bindBpDevice(deviceType: deviceType, deviceSerialNum: deviceSerialNum);
  }

  Future<OmronBindResult> getBpDeviceData({required String deviceType, required String deviceSerialNum}) {
    return OmronHealthPluginPlatform.instance.getBpDeviceData(deviceType: deviceType, deviceSerialNum: deviceSerialNum);
  }
}
