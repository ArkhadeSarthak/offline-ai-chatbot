import 'device_info_stub.dart'
    if (dart.library.html) 'device_info_web.dart'
    if (dart.library.io) 'device_info_io.dart';

class DeviceSpecs {
  final double totalStorageGB;
  final double freeStorageGB;
  final double totalRamGB;
  final double usedRamGB;

  DeviceSpecs({
    required this.totalStorageGB,
    required this.freeStorageGB,
    required this.totalRamGB,
    required this.usedRamGB,
  });
}

class DeviceInfoHelper {
  static Future<DeviceSpecs> getDeviceSpecs() async {
    return getPlatformSpecs();
  }
}
