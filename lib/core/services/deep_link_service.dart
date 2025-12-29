import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 딥링크 처리 서비스
/// 
/// 지원하는 스킴:
/// - coworkfit://logrun/join?code=XXXXXX - 통나무런 초대 링크
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  
  // 딥링크 이벤트 스트림
  final _deepLinkController = StreamController<DeepLinkData>.broadcast();
  Stream<DeepLinkData> get deepLinkStream => _deepLinkController.stream;
  
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// 딥링크 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    AppLogger.info('DeepLinkService', 'Initializing deep link service');

    // 앱이 종료된 상태에서 딥링크로 시작된 경우
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.info('DeepLinkService', 'Initial deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      AppLogger.error('DeepLinkService', 'Error getting initial link', e);
    }

    // 앱이 실행 중일 때 딥링크 수신
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        AppLogger.info('DeepLinkService', 'Received deep link: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        AppLogger.error('DeepLinkService', 'Error in deep link stream', error);
      },
    );
  }

  /// 딥링크 처리
  void _handleDeepLink(Uri uri) {
    // coworkfit://logrun/join?code=XXXXXX
    if (uri.scheme != 'coworkfit') return;

    final path = uri.host + uri.path;
    
    switch (path) {
      case 'logrun/join':
        final inviteCode = uri.queryParameters['code'];
        if (inviteCode != null && inviteCode.isNotEmpty) {
          _deepLinkController.add(DeepLinkData(
            type: DeepLinkType.logRunJoin,
            data: {'inviteCode': inviteCode},
          ));
        }
        break;
      default:
        AppLogger.warning('DeepLinkService', 'Unknown deep link path: $path');
    }
  }

  /// 통나무런 초대 링크 생성
  static String createLogRunInviteLink(String inviteCode) {
    return 'coworkfit://logrun/join?code=$inviteCode';
  }

  /// 서비스 정리
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
    _isInitialized = false;
  }
}

/// 딥링크 타입
enum DeepLinkType {
  logRunJoin,
}

/// 딥링크 데이터
class DeepLinkData {
  final DeepLinkType type;
  final Map<String, dynamic> data;

  DeepLinkData({
    required this.type,
    required this.data,
  });
}

