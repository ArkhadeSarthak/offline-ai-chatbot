import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkHelper {
  static Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true; // Web browser handles its own connectivity, default to true
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
