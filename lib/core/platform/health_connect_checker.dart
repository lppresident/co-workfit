import 'dart:io';
import 'package:flutter/services.dart';

/// Health Connect 앱 설치 여부를 확인하는 플랫폼 채널 헬퍼
class HealthConnectChecker {
  static const MethodChannel _channel =
      MethodChannel('com.coworkfit.co_workfit/health_connect');

  /// Health Connect 앱이 설치되어 있는지 확인
  ///
  /// iOS에서는 항상 false를 반환합니다 (HealthKit은 시스템에 내장)
  /// Android에서는 PackageManager를 통해 실제 설치 여부를 확인합니다.
  ///
  /// Returns:
  /// - true: Health Connect 앱이 설치되어 있음
  /// - false: Health Connect 앱이 설치되지 않음 (또는 iOS)
  static Future<bool> isHealthConnectInstalled() async {
    // iOS에서는 HealthKit이 시스템에 내장되어 있으므로 확인 불필요
    if (Platform.isIOS) {
      return true;
    }

    try {
      final bool? isInstalled =
          await _channel.invokeMethod('isHealthConnectInstalled');
      return isInstalled ?? false;
    } on PlatformException catch (e) {
      print('[HealthConnectChecker] 플랫폼 예외: ${e.message}');
      return false;
    } catch (e) {
      print('[HealthConnectChecker] 예외 발생: $e');
      return false;
    }
  }
}
