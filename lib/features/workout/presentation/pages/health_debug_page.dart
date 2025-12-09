/// Health Connect Debug Page
///
/// 안드로이드 Health Connect 권한 및 데이터 로딩 문제를 디버깅하기 위한 페이지

import 'package:flutter/material.dart';
import 'package:co_workfit/features/workout/data/datasources/health_connect_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_data_mapper.dart';
import 'package:co_workfit/core/platform/health_connect_checker.dart';
import 'package:health/health.dart';

class HealthDebugPage extends StatefulWidget {
  const HealthDebugPage({Key? key}) : super(key: key);

  @override
  State<HealthDebugPage> createState() => _HealthDebugPageState();
}

class _HealthDebugPageState extends State<HealthDebugPage> {
  final _healthConnect = HealthConnectDataSource();
  final _mapper = HealthDataMapper();

  String _log = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      _log += '[$timestamp] $message\n';
    });
    print('[HealthDebug] $message');
  }

  void _clearLog() {
    setState(() {
      _log = '';
    });
  }

  Future<void> _testHealthConnectInstallation() async {
    _addLog('=== Health Connect 설치 확인 테스트 ===');
    setState(() => _isLoading = true);

    try {
      final isInstalled = await HealthConnectChecker.isHealthConnectInstalled();
      _addLog('✅ Health Connect 설치됨: $isInstalled');
    } catch (e) {
      _addLog('❌ 에러: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testHealthConnectAvailability() async {
    _addLog('=== Health Connect 사용 가능 여부 테스트 ===');
    setState(() => _isLoading = true);

    try {
      final isAvailable = await _healthConnect.isHealthConnectAvailable();
      _addLog('✅ Health Connect 사용 가능: $isAvailable');
    } catch (e) {
      _addLog('❌ 에러: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testPermissionRequest() async {
    _addLog('=== 권한 요청 테스트 ===');
    setState(() => _isLoading = true);

    try {
      final result = await _healthConnect.requestAuthorization();

      result.fold(
        (error) => _addLog('❌ 권한 요청 실패: $error'),
        (granted) => _addLog('✅ 권한 요청 성공: $granted'),
      );
    } catch (e) {
      _addLog('❌ 예외 발생: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testDirectHealthPackageAccess() async {
    _addLog('=== Health 패키지 직접 테스트 ===');
    setState(() => _isLoading = true);

    try {
      final health = Health();

      // 1. 권한 요청
      _addLog('권한 요청 중...');
      final types = [HealthDataType.WORKOUT];
      final permissions = [HealthDataAccess.READ];

      final authorized = await health.requestAuthorization(
        types,
        permissions: permissions,
      );
      _addLog('⚠️ requestAuthorization 결과: $authorized');

      // 1-1. false여도 실제 데이터 접근 테스트
      if (!authorized) {
        _addLog('⚠️ false 반환됨 - 실제 데이터 접근 테스트 중...');
        try {
          final testSteps = await health
              .getHealthDataFromTypes(
                types: [HealthDataType.STEPS],
                startTime: DateTime.now().subtract(const Duration(days: 1)),
                endTime: DateTime.now(),
              )
              .timeout(const Duration(seconds: 3));
          _addLog('✅ 실제로는 데이터 접근 가능! (테스트: ${testSteps.length}개 STEPS)');
        } catch (e) {
          _addLog('❌ 실제 데이터 접근도 실패: $e');
        }
      }

      // 2. 데이터 조회
      _addLog('WORKOUT 데이터 조회 중...');
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      final healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: lastWeek,
        endTime: now,
      );

      _addLog('✅ 조회된 WORKOUT 데이터: ${healthData.length}개');

      for (var i = 0; i < healthData.length && i < 5; i++) {
        final point = healthData[i];
        final duration = point.dateTo.difference(point.dateFrom);
        _addLog('  [$i] ${point.type}');
        _addLog('      시작: ${point.dateFrom.toString().substring(11, 16)}');
        _addLog('      종료: ${point.dateTo.toString().substring(11, 16)}');
        _addLog('      시간: ${duration.inMinutes}분');
        _addLog('      출처: ${point.sourceName}');
        _addLog('      ID: ${point.sourceId}');
      }

      if (healthData.length > 5) {
        _addLog('  ... 외 ${healthData.length - 5}개');
      }

      if (healthData.isEmpty) {
        _addLog('⚠️ WORKOUT 데이터가 없습니다.');
        _addLog('   다른 타입 데이터 확인 중...');

        // STEPS 데이터 확인
        final stepsData = await health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: lastWeek,
          endTime: now,
        );
        _addLog('   STEPS 데이터: ${stepsData.length}개');

        if (stepsData.isNotEmpty) {
          final sample = stepsData.first;
          _addLog('   예시: ${sample.value} (${sample.sourceName})');
        }
      }
    } catch (e) {
      _addLog('❌ 예외 발생: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testFetchWorkoutData() async {
    _addLog('=== Workout 데이터 fetch 테스트 ===');
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      _addLog('조회 기간: ${lastWeek.toString().substring(0, 10)} ~ ${now.toString().substring(0, 10)}');

      final result = await _healthConnect.fetchWorkoutDataWithSource(
        startDate: lastWeek,
        endDate: now,
      );

      result.fold(
        (error) => _addLog('❌ 데이터 조회 실패: $error'),
        (dataPoints) {
          _addLog('✅ 데이터 조회 성공: ${dataPoints.length}개');

          for (var i = 0; i < dataPoints.length && i < 5; i++) {
            final data = dataPoints[i];
            final point = data.healthDataPoint;
            _addLog('  [$i] ${point.type}');
            _addLog('      시간: ${point.dateFrom.toString().substring(11, 16)} ~ ${point.dateTo.toString().substring(11, 16)}');
            _addLog('      출처: ${data.detectedSource}');
            _addLog('      Source Name: ${point.sourceName}');
          }

          if (dataPoints.length > 5) {
            _addLog('  ... 외 ${dataPoints.length - 5}개');
          }
        },
      );
    } catch (e) {
      _addLog('❌ 예외 발생: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testConnectedSources() async {
    _addLog('=== 연결된 소스 확인 ===');
    setState(() => _isLoading = true);

    try {
      final sources = await _healthConnect.getConnectedSources();
      _addLog('✅ 연결된 소스: ${sources.length}개');

      for (var source in sources) {
        _addLog('  - $source');
      }

      if (sources.isEmpty) {
        _addLog('⚠️ 연결된 소스가 없습니다.');
        _addLog('   Google Fit이나 Samsung Health를 Health Connect에 연결해주세요.');
      }
    } catch (e) {
      _addLog('❌ 에러: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _runFullDiagnostic() async {
    _clearLog();
    _addLog('=== 전체 진단 시작 ===\n');

    await _testHealthConnectInstallation();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testHealthConnectAvailability();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testConnectedSources();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testDirectHealthPackageAccess();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testFetchWorkoutData();

    _addLog('\n=== 전체 진단 완료 ===');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connect Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLog,
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runFullDiagnostic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('전체 진단'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testHealthConnectInstallation,
                        child: const Text('설치 확인'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testPermissionRequest,
                        child: const Text('권한 요청'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testFetchWorkoutData,
                        child: const Text('데이터 조회'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testConnectedSources,
                        child: const Text('소스 확인'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testDirectHealthPackageAccess,
                        child: const Text('직접 테스트'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const LinearProgressIndicator(),

          // Log Display
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: SelectableText(
                  _log.isEmpty ? '테스트를 시작하려면 위 버튼을 눌러주세요.' : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
