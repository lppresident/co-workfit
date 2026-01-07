import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/currency/presentation/bloc/currency_bloc.dart';
import '../../features/currency/presentation/bloc/currency_event.dart';
import '../utils/logger.dart';
import 'version_check_service.dart';

/// 앱 생명주기를 관리하는 서비스
///
/// 주요 기능:
/// 1. bg→fg 전환 감지
/// 2. 마지막 활성 시간/날짜 로컬 저장
/// 3. 날짜 변경 시 정산 체크 트리거
/// 4. 장시간 미사용 시 앱 초기화 및 버전 체크
class AppLifecycleService with WidgetsBindingObserver {
  final SharedPreferences _prefs;
  final CurrencyBloc _currencyBloc;
  final VersionCheckService _versionCheckService;

  // 설정값
  static const int resetThresholdHours = 6; // 6시간 미사용 시 초기화

  // SharedPreferences 키
  static const String _keyLastActiveTime = 'last_active_time';
  static const String _keyLastActiveDate = 'last_active_date';

  // 콜백
  void Function()? onAppResumed;
  void Function()? onAppReset;
  void Function(VersionCheckResult)? onVersionCheckRequired;

  AppLifecycleService({
    required SharedPreferences prefs,
    required CurrencyBloc currencyBloc,
    required VersionCheckService versionCheckService,
  })  : _prefs = prefs,
        _currencyBloc = currencyBloc,
        _versionCheckService = versionCheckService;

  /// 서비스 초기화
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.info('AppLifecycle', '앱 생명주기 서비스 초기화 완료');
  }

  /// 서비스 정리
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.info('AppLifecycle', '앱 생명주기 서비스 정리 완료');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 특별한 처리 없음
        break;
    }
  }

  /// 앱이 백그라운드로 전환될 때 처리
  void _handleAppPaused() {
    _saveLastActiveTime();
    AppLogger.info('AppLifecycle', '앱 백그라운드 전환 → 마지막 활성 시간 저장');
  }

  /// 앱이 포그라운드로 복귀할 때 처리
  Future<void> _handleAppResumed() async {
    final now = DateTime.now();
    final lastActiveTime = _getLastActiveTime();
    final lastActiveDate = _getLastActiveDate();

    AppLogger.info(
      'AppLifecycle',
      '앱 포그라운드 복귀 (마지막 활성: ${lastActiveTime ?? "없음"})',
    );

    // 1. 장시간 미사용 체크
    if (_shouldResetApp(now, lastActiveTime)) {
      await _resetApp();
    }

    // 2. 날짜 변경 체크
    if (_isDateChanged(now, lastActiveDate)) {
      await _checkSettlements(lastActiveDate);
    }

    // 3. 현재 시간 저장
    _saveLastActiveTime();

    // 4. 콜백 실행
    onAppResumed?.call();
  }

  /// 마지막 활성 시간 저장
  void _saveLastActiveTime() {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final nowDate = DateFormat('yyyy-MM-dd').format(now);

    _prefs.setString(_keyLastActiveTime, nowIso);
    _prefs.setString(_keyLastActiveDate, nowDate);
  }

  /// 마지막 활성 시간 조회
  DateTime? _getLastActiveTime() {
    final timeStr = _prefs.getString(_keyLastActiveTime);
    if (timeStr == null) return null;

    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      AppLogger.error(
        'AppLifecycle',
        '마지막 활성 시간 파싱 실패: $timeStr',
        e,
      );
      return null;
    }
  }

  /// 마지막 활성 날짜 조회
  String? _getLastActiveDate() {
    return _prefs.getString(_keyLastActiveDate);
  }

  /// 앱 초기화가 필요한지 확인 (장시간 미사용)
  bool _shouldResetApp(DateTime now, DateTime? lastActive) {
    if (lastActive == null) return false;

    final hoursSinceLastActive = now.difference(lastActive).inHours;
    final shouldReset = hoursSinceLastActive >= resetThresholdHours;

    if (shouldReset) {
      AppLogger.info(
        'AppLifecycle',
        '장시간 미사용 감지: ${hoursSinceLastActive}시간 >= $resetThresholdHours시간',
      );
    }

    return shouldReset;
  }

  /// 날짜가 변경되었는지 확인
  bool _isDateChanged(DateTime now, String? lastDate) {
    if (lastDate == null) return true;

    final nowDate = DateFormat('yyyy-MM-dd').format(now);
    final isChanged = nowDate != lastDate;

    if (isChanged) {
      AppLogger.info(
        'AppLifecycle',
        '날짜 변경 감지: $lastDate → $nowDate',
      );
    }

    return isChanged;
  }

  /// 앱 초기화 수행 (경량 리셋)
  Future<void> _resetApp() async {
    AppLogger.info('AppLifecycle', '앱 초기화 시작 (장시간 미사용)');

    // Currency BLoC 데이터 새로고침
    _currencyBloc.add(const LoadCurrencySummaryEvent());

    // 추가 BLoC 리셋 로직은 필요 시 여기 추가
    // 예: _socialBloc.add(const RefreshSocialDataEvent());

    // 버전 체크 수행
    await _checkVersion();

    onAppReset?.call();

    AppLogger.info('AppLifecycle', '앱 초기화 완료');
  }

  /// 버전 체크 수행
  Future<void> _checkVersion() async {
    try {
      AppLogger.info('AppLifecycle', '버전 체크 시작');
      final result = await _versionCheckService.checkVersion();

      if (result.isUpdateRequired) {
        AppLogger.info(
          'AppLifecycle',
          '업데이트 필요: ${result.currentVersion} → ${result.minimumVersion}',
        );
        onVersionCheckRequired?.call(result);
      } else {
        AppLogger.info('AppLifecycle', '최신 버전 사용 중');
      }
    } catch (e, stackTrace) {
      AppLogger.error('AppLifecycle', '버전 체크 실패', e, stackTrace);
    }
  }

  /// 정산 체크 트리거
  Future<void> _checkSettlements(String? lastDate) async {
    AppLogger.info(
      'AppLifecycle',
      '날짜 변경으로 인한 정산 체크 (이전 날짜: ${lastDate ?? "없음"})',
    );

    _currencyBloc.add(const CheckPendingSettlementsEvent());
  }

  /// 현재 저장된 마지막 활성 시간 조회 (디버깅용)
  String getLastActiveTimeDebug() {
    final time = _getLastActiveTime();
    final date = _getLastActiveDate();
    return 'Time: ${time?.toString() ?? "없음"}, Date: ${date ?? "없음"}';
  }
}
