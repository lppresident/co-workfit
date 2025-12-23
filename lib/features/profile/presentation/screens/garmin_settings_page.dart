import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Garmin Connect 설정 페이지
///
/// Garmin 연동 상태 확인, 연결/해제, 동기화 등
class GarminSettingsPage extends BasePage {
  const GarminSettingsPage({super.key});

  @override
  State<GarminSettingsPage> createState() => _GarminSettingsPageState();
}

class _GarminSettingsPageState extends BasePageState<GarminSettingsPage> {
  final _repository = GetIt.instance<WorkoutRepositoryImpl>();

  bool _isLoading = false;
  bool _isConnected = false;
  bool _isConfigured = false;
  String? _errorMessage;

  @override
  void loadInitialData() {
    _checkGarminStatus();
  }

  Future<void> _checkGarminStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connected = await _repository.isGarminConnected();
      final configured = _repository.isGarminConfigured;

      setState(() {
        _isConnected = connected;
        _isConfigured = configured;
        _isLoading = false;
      });

      AppLogger.info('GarminSettings', 'Connected: $connected, Configured: $configured');
    } catch (e, stackTrace) {
      AppLogger.error('GarminSettings', 'Failed to check status', e, stackTrace);
      setState(() {
        _errorMessage = 'Failed to check Garmin status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectGarmin() async {
    if (!_isConfigured) {
      _showErrorDialog(
        'Garmin Connect 연동이 아직 준비되지 않았습니다.\n\n'
        '개발자에게 문의해주세요.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get authorization URL
      final authUrlResult = await _repository.startGarminAuth();

      await authUrlResult.fold(
        (error) async {
          AppLogger.error('GarminSettings', 'Auth URL failed: $error');
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        },
        (authUrl) async {
          // 2. Launch URL in browser
          final launchResult = await _repository.launchGarminAuthUrl(authUrl);

          launchResult.fold(
            (error) {
              AppLogger.error('GarminSettings', 'Launch URL failed: $error');
              setState(() {
                _errorMessage = error;
                _isLoading = false;
              });
            },
            (success) {
              AppLogger.info('GarminSettings', 'Auth URL launched successfully');

              // Show instruction dialog
              _showAuthInstructionDialog();

              setState(() {
                _isLoading = false;
              });
            },
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('GarminSettings', 'Connect failed', e, stackTrace);
      setState(() {
        _errorMessage = 'Failed to connect: $e';
        _isLoading = false;
      });
    }
  }

  void _showAuthInstructionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Garmin 계정 연동'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '다음 단계를 따라주세요:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStep(1, '브라우저에서 Garmin 계정으로 로그인'),
            _buildStep(2, 'Co-WorkFit 앱의 권한 요청을 승인'),
            _buildStep(3, '승인 후 자동으로 앱으로 돌아옵니다'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Garmin 계정이 없으시면 먼저 garmin.com에서 회원가입해주세요.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // User will complete auth in browser and come back via deep link
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _checkGarminStatus(); // Check after some delay
                }
              });
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectGarmin() async {
    final confirmed = await _showConfirmDialog(
      '연결 해제',
      'Garmin Connect 연결을 해제하시겠습니까?\n'
      '저장된 인증 정보가 삭제됩니다.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.disconnectGarmin();

      AppLogger.info('GarminSettings', 'Disconnected successfully');

      setState(() {
        _isConnected = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Garmin 연결이 해제되었습니다')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('GarminSettings', 'Disconnect failed', e, stackTrace);
      setState(() {
        _errorMessage = 'Failed to disconnect: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.manualRefreshGarmin();

      result.fold(
        (error) {
          AppLogger.error('GarminSettings', 'Manual sync failed: $error');
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        },
        (workouts) {
          AppLogger.info('GarminSettings', 'Manual sync success: ${workouts.length} workouts');
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${workouts.length}개의 운동 데이터를 동기화했습니다')),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('GarminSettings', 'Manual sync exception', e, stackTrace);
      setState(() {
        _errorMessage = 'Sync failed: $e';
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'Garmin Connect',
      actions: [
        if (_isConnected)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _manualSync,
            tooltip: 'Manual Sync',
          ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_isLoading) {
      return const CommonLoadingWidget(message: 'Loading...');
    }

    if (_errorMessage != null) {
      return CommonErrorWidget(
        message: _errorMessage!,
        onRetry: loadInitialData,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.cancel,
                      color: _isConnected ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected ? '연결됨' : '연결 안 됨',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isConnected
                                ? 'Garmin 계정이 연동되어 있습니다'
                                : 'Garmin 계정을 연동하세요',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : (_isConnected ? _disconnectGarmin : _connectGarmin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                    label: Text(_isConnected ? '연결 해제' : 'Garmin 연동하기'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Info Section
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.watch_outlined, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Garmin Connect란?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Garmin 워치나 피트니스 기기를 사용하시나요?\n\n'
                  'Garmin Connect를 연동하면 기기에서 측정된 정확한 운동 데이터를 '
                  '자동으로 Co-WorkFit과 동기화할 수 있습니다.\n\n'
                  '심박수, 거리, 페이스 등 상세한 운동 기록을 바탕으로 '
                  '더 정확한 운동 점수를 받아보세요!',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Features List
        const Text(
          '주요 기능',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const _FeatureItem(
          icon: Icons.sync,
          title: '자동 동기화',
          description: '하루 최대 2회 자동으로 운동 데이터를 가져옵니다 (6시간 간격)',
        ),
        const _FeatureItem(
          icon: Icons.refresh,
          title: '수동 새로고침',
          description: '언제든지 수동으로 동기화할 수 있습니다 (5분 쿨다운)',
        ),
        const _FeatureItem(
          icon: Icons.trending_up,
          title: '증분 동기화',
          description: '마지막 동기화 이후의 새로운 데이터만 가져와 빠르고 효율적입니다',
        ),
        const _FeatureItem(
          icon: Icons.shield_outlined,
          title: '안전한 연동',
          description: 'OAuth 인증으로 Garmin 계정 정보를 안전하게 보호합니다',
        ),

        if (!_isConfigured) ...[
          const SizedBox(height: 24),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        '서비스 준비 중',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Garmin Connect 연동 서비스가 아직 활성화되지 않았습니다.\n\n'
                    '서비스 이용을 원하시면 앱 개발팀에 문의해주세요.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
