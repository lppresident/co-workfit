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
        'Garmin API가 설정되지 않았습니다.\n'
        'lib/features/workout/data/datasources/garmin/garmin_config.dart 파일에서\n'
        'Consumer Key와 Consumer Secret을 설정해주세요.',
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
      builder: (context) => AlertDialog(
        title: const Text('Garmin 인증'),
        content: const Text(
          '브라우저에서 Garmin 계정으로 로그인한 후\n'
          '권한을 승인해주세요.\n\n'
          '승인 완료 후 앱으로 자동으로 돌아옵니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkGarminStatus(); // Refresh status after auth
            },
            child: const Text('확인'),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected ? 'Connected' : 'Not Connected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isConnected
                              ? 'Garmin Connect is linked'
                              : 'Link your Garmin account',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isConnected ? _disconnectGarmin : _connectGarmin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isConnected ? 'Disconnect' : 'Connect to Garmin'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Info Section
        const Text(
          'About Garmin Connect',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Garmin Connect allows you to sync your workout data directly from Garmin devices. '
          'This provides more accurate and detailed workout information.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 24),

        // Features List
        const Text(
          'Features',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const _FeatureItem(
          icon: Icons.sync,
          title: 'Auto Sync',
          description: 'Automatically syncs up to 2 times per day (6-hour intervals)',
        ),
        const _FeatureItem(
          icon: Icons.refresh,
          title: 'Manual Refresh',
          description: 'Manually sync anytime (5-minute cooldown)',
        ),
        const _FeatureItem(
          icon: Icons.timeline,
          title: 'Incremental Sync',
          description: 'Only syncs new data since last sync',
        ),
        const _FeatureItem(
          icon: Icons.storage,
          title: 'Rate Limit Optimized',
          description: 'Respects Garmin API rate limits',
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
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Configuration Required',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Garmin API keys are not configured. '
                    'Please set up Consumer Key and Consumer Secret in garmin_config.dart',
                    style: TextStyle(fontSize: 14),
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
