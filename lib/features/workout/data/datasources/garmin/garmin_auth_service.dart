import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';
import 'garmin_config.dart';

/// Garmin OAuth 1.0a 인증 서비스
///
/// Garmin API는 OAuth 1.0a를 사용합니다.
/// 이 서비스는 토큰 발급, 저장, 갱신을 담당합니다.
class GarminAuthService {
  static const String _accessTokenKey = 'garmin_access_token';
  static const String _accessTokenSecretKey = 'garmin_access_token_secret';
  static const String _userIdKey = 'garmin_user_id';

  String? _requestToken;
  String? _requestTokenSecret;

  /// 저장된 Access Token 가져오기
  Future<GarminTokens?> getSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final accessTokenSecret = prefs.getString(_accessTokenSecretKey);
    final userId = prefs.getString(_userIdKey);

    if (accessToken != null && accessTokenSecret != null) {
      return GarminTokens(
        accessToken: accessToken,
        accessTokenSecret: accessTokenSecret,
        userId: userId,
      );
    }
    return null;
  }

  /// Access Token 저장
  Future<void> saveTokens(GarminTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    await prefs.setString(_accessTokenSecretKey, tokens.accessTokenSecret);
    if (tokens.userId != null) {
      await prefs.setString(_userIdKey, tokens.userId!);
    }
  }

  /// 저장된 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_accessTokenSecretKey);
    await prefs.remove(_userIdKey);
  }

  /// 인증 여부 확인
  Future<bool> isAuthenticated() async {
    final tokens = await getSavedTokens();
    return tokens != null;
  }

  /// OAuth 1.0a Step 1: Request Token 요청
  Future<Either<String, String>> startAuthorization() async {
    if (!GarminConfig.isConfigured) {
      return Left('Garmin API credentials가 설정되지 않았습니다.');
    }

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final nonce = _generateNonce();

      final params = {
        'oauth_consumer_key': GarminConfig.consumerKey,
        'oauth_signature_method': 'HMAC-SHA1',
        'oauth_timestamp': timestamp,
        'oauth_nonce': nonce,
        'oauth_version': '1.0',
        'oauth_callback': GarminConfig.callbackUrl,
      };

      final signature = _generateSignature(
        'POST',
        GarminConfig.requestTokenUrl,
        params,
        GarminConfig.consumerSecret,
        '',
      );

      params['oauth_signature'] = signature;

      final response = await http.post(
        Uri.parse(GarminConfig.requestTokenUrl),
        headers: {
          'Authorization': _buildAuthHeader(params),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseParams = Uri.splitQueryString(response.body);
        _requestToken = responseParams['oauth_token'];
        _requestTokenSecret = responseParams['oauth_token_secret'];

        if (_requestToken != null) {
          // 사용자를 Garmin 인증 페이지로 리다이렉트
          final authUrl = '${GarminConfig.authorizeUrl}?oauth_token=$_requestToken';
          return Right(authUrl);
        }
      }

      return Left('Request Token 요청 실패: ${response.statusCode}');
    } catch (e) {
      return Left('인증 시작 실패: ${e.toString()}');
    }
  }

  /// 브라우저에서 인증 URL 열기
  Future<Either<String, bool>> launchAuthorizationUrl(String authUrl) async {
    try {
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return Right(true);
      }
      return Left('브라우저를 열 수 없습니다.');
    } catch (e) {
      return Left('인증 URL 열기 실패: ${e.toString()}');
    }
  }

  /// OAuth 1.0a Step 3: Access Token 요청 (콜백 처리 후)
  Future<Either<String, GarminTokens>> handleCallback(String oauthVerifier) async {
    if (_requestToken == null || _requestTokenSecret == null) {
      return Left('Request Token이 없습니다. 인증을 다시 시작해주세요.');
    }

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final nonce = _generateNonce();

      final params = {
        'oauth_consumer_key': GarminConfig.consumerKey,
        'oauth_token': _requestToken!,
        'oauth_signature_method': 'HMAC-SHA1',
        'oauth_timestamp': timestamp,
        'oauth_nonce': nonce,
        'oauth_version': '1.0',
        'oauth_verifier': oauthVerifier,
      };

      final signature = _generateSignature(
        'POST',
        GarminConfig.accessTokenUrl,
        params,
        GarminConfig.consumerSecret,
        _requestTokenSecret!,
      );

      params['oauth_signature'] = signature;

      final response = await http.post(
        Uri.parse(GarminConfig.accessTokenUrl),
        headers: {
          'Authorization': _buildAuthHeader(params),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final responseParams = Uri.splitQueryString(response.body);
        final accessToken = responseParams['oauth_token'];
        final accessTokenSecret = responseParams['oauth_token_secret'];

        if (accessToken != null && accessTokenSecret != null) {
          final tokens = GarminTokens(
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret,
          );

          await saveTokens(tokens);

          // Request Token 정리
          _requestToken = null;
          _requestTokenSecret = null;

          return Right(tokens);
        }
      }

      return Left('Access Token 요청 실패: ${response.statusCode}');
    } catch (e) {
      return Left('Access Token 요청 실패: ${e.toString()}');
    }
  }

  /// OAuth 1.0a 서명 생성
  String _generateSignature(
    String method,
    String url,
    Map<String, String> params,
    String consumerSecret,
    String tokenSecret,
  ) {
    // 파라미터 정렬
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // 파라미터 문자열 생성
    final paramString = sortedParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    // Base String 생성
    final baseString = [
      method.toUpperCase(),
      Uri.encodeComponent(url),
      Uri.encodeComponent(paramString),
    ].join('&');

    // Signing Key 생성
    final signingKey = '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(tokenSecret)}';

    // HMAC-SHA1 서명
    final hmac = Hmac(sha1, utf8.encode(signingKey));
    final digest = hmac.convert(utf8.encode(baseString));

    return base64.encode(digest.bytes);
  }

  /// Authorization Header 생성
  String _buildAuthHeader(Map<String, String> params) {
    final headerParams = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}="${Uri.encodeComponent(e.value)}"')
        .join(', ');

    return 'OAuth $headerParams';
  }

  /// Nonce 생성
  String _generateNonce() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    return base64.encode(bytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }
}

/// Garmin OAuth Tokens
class GarminTokens {
  final String accessToken;
  final String accessTokenSecret;
  final String? userId;

  GarminTokens({
    required this.accessToken,
    required this.accessTokenSecret,
    this.userId,
  });
}
