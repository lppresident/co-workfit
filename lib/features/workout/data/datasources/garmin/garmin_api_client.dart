import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'garmin_config.dart';
import 'garmin_auth_service.dart';

/// Garmin Health API 클라이언트
///
/// OAuth 1.0a 인증된 API 요청을 처리합니다.
class GarminApiClient {
  final GarminAuthService _authService;

  GarminApiClient({GarminAuthService? authService})
      : _authService = authService ?? GarminAuthService();

  /// 인증된 GET 요청
  Future<Either<String, Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final tokens = await _authService.getSavedTokens();
    if (tokens == null) {
      return Left('Garmin 인증이 필요합니다.');
    }

    try {
      var url = '${GarminConfig.apiBaseUrl}$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await _makeAuthenticatedRequest(
        'GET',
        url,
        tokens,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Right(data is List ? {'data': data} : data);
      } else if (response.statusCode == 401) {
        return Left('인증이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        return Left('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      return Left('API 요청 실패: ${e.toString()}');
    }
  }

  /// OAuth 1.0a 인증된 HTTP 요청
  Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String url,
    GarminTokens tokens,
  ) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _generateNonce();

    final oauthParams = {
      'oauth_consumer_key': GarminConfig.consumerKey,
      'oauth_token': tokens.accessToken,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp': timestamp,
      'oauth_nonce': nonce,
      'oauth_version': '1.0',
    };

    // URL에서 쿼리 파라미터 추출
    final uri = Uri.parse(url);
    final allParams = Map<String, String>.from(oauthParams);
    allParams.addAll(uri.queryParameters);

    final signature = _generateSignature(
      method,
      '${uri.scheme}://${uri.host}${uri.path}',
      allParams,
      GarminConfig.consumerSecret,
      tokens.accessTokenSecret,
    );

    oauthParams['oauth_signature'] = signature;

    final headers = {
      'Authorization': _buildAuthHeader(oauthParams),
      'Content-Type': 'application/json',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(Uri.parse(url), headers: headers);
      case 'POST':
        return await http.post(Uri.parse(url), headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  /// OAuth 서명 생성
  String _generateSignature(
    String method,
    String url,
    Map<String, String> params,
    String consumerSecret,
    String tokenSecret,
  ) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final paramString = sortedParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final baseString = [
      method.toUpperCase(),
      Uri.encodeComponent(url),
      Uri.encodeComponent(paramString),
    ].join('&');

    final signingKey =
        '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(tokenSecret)}';

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

/// Garmin Activity 모델
class GarminActivity {
  final String? activityId;
  final String? activityType;
  final DateTime? startTime;
  final int? durationInSeconds;
  final double? distanceInMeters;
  final int? activeKilocalories;
  final int? averageHeartRateInBeatsPerMinute;
  final int? maxHeartRateInBeatsPerMinute;
  final int? steps;
  final double? elevationGainInMeters;

  GarminActivity({
    this.activityId,
    this.activityType,
    this.startTime,
    this.durationInSeconds,
    this.distanceInMeters,
    this.activeKilocalories,
    this.averageHeartRateInBeatsPerMinute,
    this.maxHeartRateInBeatsPerMinute,
    this.steps,
    this.elevationGainInMeters,
  });

  factory GarminActivity.fromJson(Map<String, dynamic> json) {
    return GarminActivity(
      activityId: json['activityId']?.toString(),
      activityType: json['activityType'] as String?,
      startTime: json['startTimeInSeconds'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['startTimeInSeconds'] as int) * 1000)
          : null,
      durationInSeconds: json['durationInSeconds'] as int?,
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble(),
      activeKilocalories: json['activeKilocalories'] as int?,
      averageHeartRateInBeatsPerMinute:
          json['averageHeartRateInBeatsPerMinute'] as int?,
      maxHeartRateInBeatsPerMinute:
          json['maxHeartRateInBeatsPerMinute'] as int?,
      steps: json['steps'] as int?,
      elevationGainInMeters:
          (json['elevationGainInMeters'] as num?)?.toDouble(),
    );
  }

  /// 운동 종료 시간 계산
  DateTime? get endTime {
    if (startTime != null && durationInSeconds != null) {
      return startTime!.add(Duration(seconds: durationInSeconds!));
    }
    return null;
  }

  /// 운동 시간 (분)
  int get durationMinutes => (durationInSeconds ?? 0) ~/ 60;

  /// 거리 (km)
  double get distanceKm => (distanceInMeters ?? 0) / 1000;
}

/// Garmin Daily Summary 모델
class GarminDailySummary {
  final DateTime? calendarDate;
  final int? steps;
  final double? distanceInMeters;
  final int? activeKilocalories;
  final int? floorsClimbed;
  final int? minHeartRateInBeatsPerMinute;
  final int? maxHeartRateInBeatsPerMinute;
  final int? averageHeartRateInBeatsPerMinute;
  final int? restingHeartRateInBeatsPerMinute;

  GarminDailySummary({
    this.calendarDate,
    this.steps,
    this.distanceInMeters,
    this.activeKilocalories,
    this.floorsClimbed,
    this.minHeartRateInBeatsPerMinute,
    this.maxHeartRateInBeatsPerMinute,
    this.averageHeartRateInBeatsPerMinute,
    this.restingHeartRateInBeatsPerMinute,
  });

  factory GarminDailySummary.fromJson(Map<String, dynamic> json) {
    return GarminDailySummary(
      calendarDate: json['calendarDate'] != null
          ? DateTime.tryParse(json['calendarDate'] as String)
          : null,
      steps: json['steps'] as int?,
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble(),
      activeKilocalories: json['activeKilocalories'] as int?,
      floorsClimbed: json['floorsClimbed'] as int?,
      minHeartRateInBeatsPerMinute:
          json['minHeartRateInBeatsPerMinute'] as int?,
      maxHeartRateInBeatsPerMinute:
          json['maxHeartRateInBeatsPerMinute'] as int?,
      averageHeartRateInBeatsPerMinute:
          json['averageHeartRateInBeatsPerMinute'] as int?,
      restingHeartRateInBeatsPerMinute:
          json['restingHeartRateInBeatsPerMinute'] as int?,
    );
  }
}
