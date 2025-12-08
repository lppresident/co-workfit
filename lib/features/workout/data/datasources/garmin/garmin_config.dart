/// Garmin Health API 설정
///
/// Garmin Developer Program 승인 후 발급받은 credentials를 여기에 설정합니다.
/// https://developer.garmin.com/gc-developer-program/
///
/// ## 설정 방법
/// 1. https://developer.garmin.com/ 에서 개발자 계정 생성
/// 2. Garmin Connect Developer Program 신청 및 승인
/// 3. Consumer Key와 Consumer Secret 발급
/// 4. 아래 상수에 값 설정 (또는 환경변수 사용)
class GarminConfig {
  // TODO: Garmin Developer Program 승인 후 실제 값으로 교체
  // 보안을 위해 환경변수나 secure storage 사용 권장
  static const String consumerKey = 'YOUR_GARMIN_CONSUMER_KEY';
  static const String consumerSecret = 'YOUR_GARMIN_CONSUMER_SECRET';

  // OAuth 1.0a endpoints (Garmin은 OAuth 1.0a 사용)
  static const String requestTokenUrl =
      'https://connectapi.garmin.com/oauth-service/oauth/request_token';
  static const String authorizeUrl =
      'https://connect.garmin.com/oauthConfirm';
  static const String accessTokenUrl =
      'https://connectapi.garmin.com/oauth-service/oauth/access_token';

  // API Base URL
  static const String apiBaseUrl = 'https://apis.garmin.com';

  // Callback URL (앱에서 처리할 딥링크)
  static const String callbackUrl = 'coworkfit://garmin/callback';

  // API Endpoints
  static const String activitiesEndpoint = '/wellness-api/rest/activities';
  static const String dailiesEndpoint = '/wellness-api/rest/dailies';
  static const String epochsEndpoint = '/wellness-api/rest/epochs';
  static const String sleepEndpoint = '/wellness-api/rest/sleeps';
  static const String bodyCompositionEndpoint = '/wellness-api/rest/bodyComps';
  static const String stressEndpoint = '/wellness-api/rest/stressDetails';
  static const String userMetricsEndpoint = '/wellness-api/rest/userMetrics';

  /// 설정이 완료되었는지 확인
  static bool get isConfigured =>
      consumerKey != 'YOUR_GARMIN_CONSUMER_KEY' &&
      consumerSecret != 'YOUR_GARMIN_CONSUMER_SECRET';
}

/// Garmin 운동 타입 매핑
class GarminActivityType {
  static const Map<String, String> activityTypeMap = {
    'running': 'running',
    'cycling': 'cycling',
    'swimming': 'swimming',
    'walking': 'walking',
    'hiking': 'hiking',
    'strength_training': 'weightTraining',
    'yoga': 'yoga',
    'elliptical': 'other',
    'stair_climbing': 'other',
    'rowing': 'other',
    'pilates': 'yoga',
    'other': 'other',
  };

  static String mapToWorkoutType(String garminType) {
    return activityTypeMap[garminType.toLowerCase()] ?? 'other';
  }
}
