import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'models/garmin_credentials.dart';
import 'garmin_token_storage.dart';

/// Garmin OAuth 1.0a 인증 서비스
class GarminOAuthService {
  // TODO: Garmin Developer Portal에서 발급받은 키로 교체 필요
  static const String _consumerKey = 'YOUR_CONSUMER_KEY';
  static const String _consumerSecret = 'YOUR_CONSUMER_SECRET';

  // Garmin OAuth endpoints
  static const String _requestTokenUrl = 'https://connectapi.garmin.com/oauth-service/oauth/request_token';
  static const String _authorizeUrl = 'https://connect.garmin.com/oauthConfirm';
  static const String _accessTokenUrl = 'https://connectapi.garmin.com/oauth-service/oauth/access_token';
  static const String _callbackUrl = 'coworkfit://garmin/callback';

  final GarminTokenStorage _tokenStorage;
  late final oauth1.Platform _platform;
  late final oauth1.ClientCredentials _clientCredentials;

  GarminOAuthService(this._tokenStorage) {
    _platform = oauth1.Platform(
      _requestTokenUrl,
      _authorizeUrl,
      _accessTokenUrl,
      oauth1.SignatureMethods.hmacSha1,
    );

    _clientCredentials = oauth1.ClientCredentials(
      _consumerKey,
      _consumerSecret,
    );
  }

  /// 인증 플로우 시작
  Future<GarminCredentials?> authenticate(BuildContext context) async {
    try {
      AppLogger.info('GarminOAuth', 'Starting OAuth flow');

      // 1. Request Token 요청
      final auth = oauth1.Authorization(_clientCredentials, _platform);
      final credentials = await auth.requestTemporaryCredentials(_callbackUrl);

      AppLogger.debug('GarminOAuth', 'Temporary credentials received');

      // 2. Authorization URL 생성
      final authorizationUrl = auth.getResourceOwnerAuthorizationURI(credentials.credentials.token);

      AppLogger.debug('GarminOAuth', 'Authorization URL: $authorizationUrl');

      // 3. 웹뷰에서 사용자 인증
      final verifier = await _showAuthorizationWebView(context, authorizationUrl);

      if (verifier == null) {
        AppLogger.warning('GarminOAuth', 'User cancelled authorization');
        return null;
      }

      AppLogger.debug('GarminOAuth', 'Verifier received: $verifier');

      // 4. Access Token 요청
      final tokenResponse = await auth.requestTokenCredentials(
        credentials.credentials,
        verifier,
      );

      AppLogger.info('GarminOAuth', 'Access token received');

      // 5. User ID 조회 (Garmin Health API specific)
      final userId = await _getUserId(tokenResponse.credentials);

      // 6. Credentials 생성 및 저장
      final garminCredentials = GarminCredentials(
        accessToken: tokenResponse.credentials.token,
        tokenSecret: tokenResponse.credentials.tokenSecret,
        userId: userId,
        expiresAt: DateTime.now().add(const Duration(days: 365)), // Garmin 토큰은 1년 유효
      );

      await _tokenStorage.saveCredentials(garminCredentials);

      AppLogger.info('GarminOAuth', 'Authentication completed successfully');

      return garminCredentials;
    } catch (e, stackTrace) {
      AppLogger.error('GarminOAuth', 'Authentication failed', e, stackTrace);
      return null;
    }
  }

  /// 웹뷰에서 사용자 인증 및 verifier 추출
  Future<String?> _showAuthorizationWebView(
    BuildContext context,
    String authUrl,
  ) async {
    String? verifier;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Garmin 계정 연동'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onNavigationRequest: (NavigationRequest request) {
                    AppLogger.debug('GarminOAuth', 'Navigation: ${request.url}');

                    // Callback URL 감지
                    if (request.url.startsWith(_callbackUrl)) {
                      final uri = Uri.parse(request.url);
                      verifier = uri.queryParameters['oauth_verifier'];

                      AppLogger.debug('GarminOAuth', 'Callback detected, verifier: $verifier');

                      Navigator.of(context).pop();
                      return NavigationDecision.prevent;
                    }

                    return NavigationDecision.navigate;
                  },
                ),
              )
              ..loadRequest(Uri.parse(authUrl)),
          ),
        ),
      ),
    );

    return verifier;
  }

  /// Garmin User ID 조회
  Future<String> _getUserId(oauth1.Credentials tokenCredentials) async {
    try {
      // TODO: Garmin Health API의 /user/id 엔드포인트 호출
      // 현재는 임시로 토큰을 User ID로 사용
      return tokenCredentials.token.substring(0, 10);
    } catch (e, stackTrace) {
      AppLogger.error('GarminOAuth', 'Failed to get user ID', e, stackTrace);
      throw Exception('Failed to get Garmin user ID');
    }
  }

  /// 연동 해제
  Future<void> disconnect() async {
    await _tokenStorage.deleteCredentials();
    AppLogger.info('GarminOAuth', 'Disconnected from Garmin');
  }

  /// 연동 상태 확인
  Future<bool> isConnected() async {
    return await _tokenStorage.hasValidCredentials();
  }
}
