import 'device_info_helper.dart';

Future<DeviceSpecs> getPlatformSpecs() async {
  return DeviceSpecs(
    totalStorageGB: 256.0,
    freeStorageGB: 120.0,
    totalRamGB: 8.0,
    usedRamGB: 4.2,
  );
}
