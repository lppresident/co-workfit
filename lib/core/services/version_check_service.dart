import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 버전 체크 결과
class VersionCheckResult {
  final bool isUpdateRequired;
  final String currentVersion;
  final String minimumVersion;

  const VersionCheckResult({
    required this.isUpdateRequired,
    required this.currentVersion,
    required this.minimumVersion,
  });
}

/// 앱 버전 체크 서비스
///
/// Firebase Remote Config를 사용하여 최소 버전을 확인하고
/// 현재 앱 버전과 비교하여 업데이트 필요 여부를 반환
class VersionCheckService {
  static const String _minimumVersionKey = 'minimum_version';
  static const String _defaultMinimumVersion = '0.0.1';

  final FirebaseRemoteConfig _remoteConfig;

  VersionCheckService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Remote Config 초기화
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults({
        _minimumVersionKey: _defaultMinimumVersion,
      });

      await _remoteConfig.fetchAndActivate();

      AppLogger.info('VersionCheckService', 'Remote Config initialized');
    } catch (e, stackTrace) {
      AppLogger.error('VersionCheckService', 'Failed to initialize Remote Config', e, stackTrace);
    }
  }

  /// 버전 체크
  ///
  /// Returns:
  /// - isUpdateRequired: true면 업데이트 필수
  /// - currentVersion: 현재 앱 버전
  /// - minimumVersion: Firebase에 설정된 최소 버전
  Future<VersionCheckResult> checkVersion() async {
    try {
      // 현재 앱 버전 가져오기
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Firebase Remote Config에서 최소 버전 가져오기
      final minimumVersion = _remoteConfig.getString(_minimumVersionKey);

      AppLogger.info('VersionCheckService', 'Current version: $currentVersion');
      AppLogger.info('VersionCheckService', 'Minimum version: $minimumVersion');

      // 버전 비교
      final isUpdateRequired = _compareVersions(currentVersion, minimumVersion) < 0;

      return VersionCheckResult(
        isUpdateRequired: isUpdateRequired,
        currentVersion: currentVersion,
        minimumVersion: minimumVersion,
      );
    } catch (e, stackTrace) {
      AppLogger.error('VersionCheckService', 'Failed to check version', e, stackTrace);

      // 에러 발생 시 업데이트 불필요로 처리 (앱 진입 차단하지 않음)
      return const VersionCheckResult(
        isUpdateRequired: false,
        currentVersion: '0.0.0',
        minimumVersion: '0.0.0',
      );
    }
  }

  /// 버전 문자열 비교
  ///
  /// Returns:
  /// - 음수: version1 < version2 (업데이트 필요)
  /// - 0: version1 == version2
  /// - 양수: version1 > version2
  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

      for (int i = 0; i < maxLength; i++) {
        final v1 = i < v1Parts.length ? v1Parts[i] : 0;
        final v2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (v1 < v2) return -1;
        if (v1 > v2) return 1;
      }

      return 0;
    } catch (e) {
      AppLogger.error('VersionCheckService', 'Failed to compare versions: $version1 vs $version2', e);
      return 0; // 비교 실패 시 동일한 버전으로 간주
    }
  }
}
