import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omron_health_plugin/omron_health_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelOmronHealthPlugin platform = MethodChannelOmronHealthPlugin();
  const MethodChannel channel = MethodChannel('omron_health_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    // expect(await platform.getPlatformVersion(), '42');
  });
}
