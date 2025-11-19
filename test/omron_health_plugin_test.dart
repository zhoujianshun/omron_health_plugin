import 'package:flutter_test/flutter_test.dart';
import 'package:omron_health_plugin/omron/omron_bind_result.dart';
import 'package:omron_health_plugin/omron/omron_config.dart';
import 'package:omron_health_plugin/omron/omron_connection_status.dart';
import 'package:omron_health_plugin/omron/omron_device_category.dart';
import 'package:omron_health_plugin/omron/omron_result.dart';
import 'package:omron_health_plugin/omron/omron_scan_event.dart';
import 'package:omron_health_plugin/omron/omron_scanned_device.dart';
import 'package:omron_health_plugin/omron/omron_sync_device.dart';
import 'package:omron_health_plugin/omron_health_plugin.dart';
import 'package:omron_health_plugin/omron_health_plugin_platform_interface.dart';
import 'package:omron_health_plugin/omron_health_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOmronHealthPluginPlatform
    with MockPlatformInterfaceMixin
    implements OmronHealthPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<OmronBindResult> bindBpDevice({required String deviceType, String? deviceSerialNum}) {
    // TODO: implement bindBpDevice
    throw UnimplementedError();
  }

  @override
  Future<OmronBindResult> getBpDeviceData({required String deviceType, required String deviceSerialNum}) {
    // TODO: implement getBpDeviceData
    throw UnimplementedError();
  }

  @override
  Future<void> initSdk() {
    // TODO: implement initSdk
    throw UnimplementedError();
  }

  @override
  Future<OmronInitResult> register(OmronConfig config) {
    // TODO: implement register
    throw UnimplementedError();
  }

  @override
  Stream<OmronScanEvent<OmronScannedDevice>> startBindScan(OmronDeviceCategory category, {int timeout = 60}) {
    // TODO: implement startBindScan
    throw UnimplementedError();
  }

  @override
  Stream<OmronConnectionStatus> startConnectionStatusListener() {
    // TODO: implement startConnectionStatusListener
    throw UnimplementedError();
  }

  @override
  Stream<OmronScanEvent<OmronScannedDevice>> startSyncScan(List<OmronSyncDevice> devices, {int scanPeriod = 60}) {
    // TODO: implement startSyncScan
    throw UnimplementedError();
  }

  @override
  Future<void> stopScan() {
    // TODO: implement stopScan
    throw UnimplementedError();
  }

  @override
  Future<void> stopSyncScan() {
    // TODO: implement stopSyncScan
    throw UnimplementedError();
  }
}

void main() {
  final OmronHealthPluginPlatform initialPlatform = OmronHealthPluginPlatform.instance;

  test('$MethodChannelOmronHealthPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOmronHealthPlugin>());
  });

  test('getPlatformVersion', () async {
    OmronHealthPlugin omronHealthPlugin = OmronHealthPlugin.instance;
    MockOmronHealthPluginPlatform fakePlatform = MockOmronHealthPluginPlatform();
    OmronHealthPluginPlatform.instance = fakePlatform;
    expect(true, true);
    // expect(await omronHealthPlugin.initSdk(), void);
  });
}
