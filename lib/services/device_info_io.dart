import 'dart:io';
import 'package:flutter/foundation.dart';
import 'device_info_helper.dart';

Future<DeviceSpecs> getPlatformSpecs() async {
  double totalStorage = 256.0;
  double freeStorage = 120.0;
  double totalRam = 8.0;
  double usedRam = 4.2;

  try {
    if (Platform.isWindows) {
      // Query total RAM bytes
      final ramResult = await Process.run('powershell', [
        '-Command',
        '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory'
      ]);
      if (ramResult.exitCode == 0) {
        final bytes = double.tryParse(ramResult.stdout.toString().trim());
        if (bytes != null) {
          totalRam = bytes / (1024.0 * 1024.0 * 1024.0);
        }
      }

      // Query total C: drive space in bytes
      final storageResult = await Process.run('powershell', [
        '-Command',
        "Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:' | Select-Object -ExpandProperty Size"
      ]);
      if (storageResult.exitCode == 0) {
        final bytes = double.tryParse(storageResult.stdout.toString().trim());
        if (bytes != null) {
          totalStorage = bytes / (1024.0 * 1024.0 * 1024.0);
        }
      }

      // Query free C: drive space in bytes
      final freeResult = await Process.run('powershell', [
        '-Command',
        "Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:' | Select-Object -ExpandProperty FreeSpace"
      ]);
      if (freeResult.exitCode == 0) {
        final bytes = double.tryParse(freeResult.stdout.toString().trim());
        if (bytes != null) {
          freeStorage = bytes / (1024.0 * 1024.0 * 1024.0);
        }
      }

      usedRam = totalRam * 0.48; // Estimate typical system load
    } else if (Platform.isMacOS) {
      final ramResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      if (ramResult.exitCode == 0) {
        final bytes = double.tryParse(ramResult.stdout.toString().trim());
        if (bytes != null) {
          totalRam = bytes / (1024.0 * 1024.0 * 1024.0);
        }
      }
      usedRam = totalRam * 0.52;
    } else if (Platform.isLinux) {
      final file = File('/proc/meminfo');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          if (line.startsWith('MemTotal:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                totalRam = kb / (1024.0 * 1024.0);
              }
            }
            break;
          }
        }
      }
      usedRam = totalRam * 0.45;
    } else if (Platform.isAndroid || Platform.isIOS) {
      totalStorage = 128.0;
      freeStorage = 74.0;
      totalRam = 6.0;
      usedRam = 3.1;
    }
  } catch (e) {
    debugPrint("Error loading device specifications on native: $e");
  }

  return DeviceSpecs(
    totalStorageGB: totalStorage,
    freeStorageGB: freeStorage,
    totalRamGB: totalRam,
    usedRamGB: usedRam,
  );
}
