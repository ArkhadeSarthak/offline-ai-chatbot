import 'dart:io';
import 'package:flutter/foundation.dart';
import 'device_info_helper.dart';

Future<DeviceSpecs> getPlatformSpecs() async {
  double totalStorage = 64.0;
  double freeStorage = 32.0;
  double totalRam = 6.0;
  double usedRam = 3.0;

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

      usedRam = totalRam * 0.50;
    } else if (Platform.isMacOS) {
      final ramResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      if (ramResult.exitCode == 0) {
        final bytes = double.tryParse(ramResult.stdout.toString().trim());
        if (bytes != null) {
          totalRam = bytes / (1024.0 * 1024.0 * 1024.0);
        }
      }
      usedRam = totalRam * 0.50;
    } else if (Platform.isLinux || Platform.isAndroid) {
      final meminfo = File('/proc/meminfo');
      if (await meminfo.exists()) {
        final lines = await meminfo.readAsLines();
        double? memTotalKb;
        double? memAvailKb;
        for (var line in lines) {
          if (line.startsWith('MemTotal:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) memTotalKb = double.tryParse(parts[1]);
          } else if (line.startsWith('MemAvailable:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) memAvailKb = double.tryParse(parts[1]);
          }
        }
        if (memTotalKb != null) {
          totalRam = memTotalKb / (1024.0 * 1024.0);
          if (memAvailKb != null) {
            final freeRam = memAvailKb / (1024.0 * 1024.0);
            usedRam = (totalRam - freeRam).clamp(0.1, totalRam);
          } else {
            usedRam = totalRam * 0.55;
          }
        }
      }
    }
  } catch (e) {
    debugPrint("Error loading device specifications: $e");
  }

  return DeviceSpecs(
    totalStorageGB: totalStorage,
    freeStorageGB: freeStorage,
    totalRamGB: totalRam,
    usedRamGB: usedRam,
  );
}
