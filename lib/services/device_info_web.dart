import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'device_info_helper.dart';

Future<DeviceSpecs> getPlatformSpecs() async {
  double totalStorage = 256.0;
  double freeStorage = 180.0;
  double totalRam = 8.0;
  double usedRam = 3.5;

  try {
    // Access globalContext (which is the window on web)
    final window = globalContext;
    if (window.hasProperty('navigator'.toJS).toDart) {
      final navigator = window.getProperty('navigator'.toJS) as JSObject;

      // Get approximate RAM
      if (navigator.hasProperty('deviceMemory'.toJS).toDart) {
        final ramValue = navigator.getProperty('deviceMemory'.toJS);
        if (ramValue != null) {
          totalRam = double.tryParse(ramValue.toString()) ?? 8.0;
          usedRam = totalRam * 0.45;
        }
      }

      // Get approximate Storage using storage manager estimate
      if (navigator.hasProperty('storage'.toJS).toDart) {
        final storage = navigator.getProperty('storage'.toJS) as JSObject;
        if (storage.hasProperty('estimate'.toJS).toDart) {
          final estimatePromise = storage.callMethod('estimate'.toJS) as JSPromise;
          final estimate = await estimatePromise.toDart;
          if (estimate != null && estimate is JSObject) {
            if (estimate.hasProperty('quota'.toJS).toDart) {
              final quotaValue = estimate.getProperty('quota'.toJS);
              final usageValue = estimate.getProperty('usage'.toJS);
              if (quotaValue != null) {
                final quotaBytes = double.tryParse(quotaValue.toString()) ?? 0.0;
                final usageBytes = double.tryParse(usageValue?.toString() ?? '0') ?? 0.0;
                if (quotaBytes > 0) {
                  totalStorage = quotaBytes / (1024.0 * 1024.0 * 1024.0);
                  freeStorage = (quotaBytes - usageBytes) / (1024.0 * 1024.0 * 1024.0);
                }
              }
            }
          }
        }
      }
    }
  } catch (e) {
    debugPrint("Error loading device specifications on web: $e");
  }

  return DeviceSpecs(
    totalStorageGB: totalStorage,
    freeStorageGB: freeStorage,
    totalRamGB: totalRam,
    usedRamGB: usedRam,
  );
}
