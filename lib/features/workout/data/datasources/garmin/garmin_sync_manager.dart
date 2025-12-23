import 'package:shared_preferences/shared_preferences.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Garmin API Rate Limit을 고려한 동기화 관리자
///
/// - 하루 1-2회 자동 동기화
/// - 사용자 수동 새로고침
/// - 마지막 동기화 시간 추적
/// - 배치 데이터 조회
class GarminSyncManager {
  static const String _keyLastSyncTime = 'garmin_last_sync_time';
  static const String _keyLastSyncData = 'garmin_last_sync_data';
  static const String _keySyncCount = 'garmin_sync_count_today';
  static const String _keySyncDate = 'garmin_sync_date';

  // Rate limit 설정
  static const int maxSyncPerDay = 2; // 하루 최대 자동 동기화 횟수
  static const Duration minSyncInterval = Duration(hours: 6); // 최소 동기화 간격
  static const Duration manualSyncCooldown = Duration(minutes: 5); // 수동 새로고침 쿨다운

  final SharedPreferences _prefs;

  GarminSyncManager(this._prefs);

  /// 마지막 동기화 시간
  DateTime? get lastSyncTime {
    final timestamp = _prefs.getInt(_keyLastSyncTime);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// 마지막 동기화 시간 저장
  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setInt(_keyLastSyncTime, time.millisecondsSinceEpoch);
    AppLogger.info('GarminSyncManager', 'Last sync time updated: $time');
  }

  /// 오늘 동기화 횟수
  int get todaySyncCount {
    final savedDate = _prefs.getString(_keySyncDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // 날짜가 바뀌면 초기화
      _prefs.setString(_keySyncDate, today);
      _prefs.setInt(_keySyncCount, 0);
      return 0;
    }

    return _prefs.getInt(_keySyncCount) ?? 0;
  }

  /// 동기화 횟수 증가
  Future<void> incrementSyncCount() async {
    final count = todaySyncCount + 1;
    await _prefs.setInt(_keySyncCount, count);
    AppLogger.debug('GarminSyncManager', 'Sync count incremented: $count');
  }

  /// 자동 동기화 가능 여부 확인
  bool canAutoSync() {
    // 1. 오늘 동기화 횟수 확인
    if (todaySyncCount >= maxSyncPerDay) {
      AppLogger.warning(
        'GarminSyncManager',
        'Daily sync limit reached: $todaySyncCount/$maxSyncPerDay',
      );
      return false;
    }

    // 2. 마지막 동기화 이후 시간 확인
    final lastSync = lastSyncTime;
    if (lastSync != null) {
      final elapsed = DateTime.now().difference(lastSync);
      if (elapsed < minSyncInterval) {
        AppLogger.warning(
          'GarminSyncManager',
          'Sync interval too short: ${elapsed.inHours}h < ${minSyncInterval.inHours}h',
        );
        return false;
      }
    }

    return true;
  }

  /// 수동 동기화 가능 여부 확인
  bool canManualSync() {
    final lastSync = lastSyncTime;
    if (lastSync != null) {
      final elapsed = DateTime.now().difference(lastSync);
      if (elapsed < manualSyncCooldown) {
        final remaining = manualSyncCooldown - elapsed;
        AppLogger.warning(
          'GarminSyncManager',
          'Manual sync cooldown: ${remaining.inMinutes}분 남음',
        );
        return false;
      }
    }

    return true;
  }

  /// 동기화 필요 여부 (앱 시작 시 확인)
  bool shouldAutoSync() {
    if (!canAutoSync()) {
      return false;
    }

    // 마지막 동기화가 없거나 6시간 이상 지난 경우
    final lastSync = lastSyncTime;
    if (lastSync == null) {
      return true;
    }

    final elapsed = DateTime.now().difference(lastSync);
    return elapsed >= minSyncInterval;
  }

  /// 동기화 시작 날짜 계산 (마지막 동기화 이후 데이터만)
  DateTime getSyncStartDate() {
    final lastSync = lastSyncTime;
    if (lastSync != null) {
      // 마지막 동기화 시간부터
      return lastSync.subtract(const Duration(hours: 1)); // 1시간 여유
    } else {
      // 처음 동기화: 최근 30일
      return DateTime.now().subtract(const Duration(days: 30));
    }
  }

  /// 동기화 완료 기록
  Future<void> recordSyncComplete() async {
    await setLastSyncTime(DateTime.now());
    await incrementSyncCount();
  }

  /// 동기화 실패 기록
  Future<void> recordSyncFailure(String error) async {
    AppLogger.error('GarminSyncManager', 'Sync failed', error);
    // 실패해도 횟수는 증가 (rate limit 보호)
    await incrementSyncCount();
  }

  /// 다음 자동 동기화 시간
  DateTime? get nextAutoSyncTime {
    if (todaySyncCount >= maxSyncPerDay) {
      // 내일 00:00
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + 1);
    }

    final lastSync = lastSyncTime;
    if (lastSync != null) {
      return lastSync.add(minSyncInterval);
    }

    return DateTime.now();
  }

  /// 동기화 통계 로그
  void logSyncStats() {
    AppLogger.info(
      'GarminSyncManager',
      '동기화 통계:\n'
      '  마지막 동기화: ${lastSyncTime ?? "없음"}\n'
      '  오늘 동기화 횟수: $todaySyncCount/$maxSyncPerDay\n'
      '  자동 동기화 가능: ${canAutoSync()}\n'
      '  수동 동기화 가능: ${canManualSync()}\n'
      '  다음 자동 동기화: ${nextAutoSyncTime}',
    );
  }

  /// 동기화 정책 초기화 (테스트용)
  Future<void> reset() async {
    await _prefs.remove(_keyLastSyncTime);
    await _prefs.remove(_keySyncCount);
    await _prefs.remove(_keySyncDate);
    AppLogger.info('GarminSyncManager', 'Sync policy reset');
  }
}
