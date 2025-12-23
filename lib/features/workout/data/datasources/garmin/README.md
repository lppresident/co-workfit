# Garmin Health API Integration

Co-WorkFit 앱의 Garmin Health API 통합 구현입니다.

## 📋 현재 상태

**Phase 1 완료**: 기본 구조 및 OAuth 인증 구현
- ✅ OAuth 1.0a 인증 플로우
- ✅ Token Storage (Secure Storage)
- ✅ API Client (Activities, Dailies 등)
- ✅ DataSource 인터페이스

**다음 단계**: Garmin Developer 계정 설정 및 테스트

---

## 🚀 Garmin Developer 계정 설정

### 1단계: 개발자 계정 생성

1. [Garmin Developer Portal](https://developer.garmin.com/) 접속
2. 계정 생성 또는 로그인
3. "Garmin Connect Developer Program" 선택

### 2단계: 앱 등록

1. Developer Portal > Applications > Create New App
2. 앱 정보 입력:
   - **App Name**: Co-WorkFit
   - **Description**: 운동 관리 및 소셜 경쟁 앱
   - **Website**: https://your-website.com (실제 URL)
   - **Callback URL**: `coworkfit://garmin/callback`
3. Health API 승인 요청
   - Request Access to Health API
   - 사용 목적 설명 (운동 데이터 동기화)

### 3단계: Credentials 발급

승인 완료 후:
1. Consumer Key 복사
2. Consumer Secret 복사
3. `garmin_config.dart` 파일에 값 설정:

```dart
class GarminConfig {
  static const String consumerKey = 'YOUR_ACTUAL_CONSUMER_KEY';
  static const String consumerSecret = 'YOUR_ACTUAL_CONSUMER_SECRET';
  // ...
}
```

**⚠️ 보안 주의**: 실제 프로덕션에서는 환경변수나 외부 설정 파일 사용 권장

---

## 📐 아키텍처

```
garmin/
├── garmin_config.dart              # API 설정 (Keys, URLs)
├── garmin_auth_service.dart        # OAuth 1.0a 인증
├── garmin_api_client.dart          # HTTP API 호출
├── garmin_datasource.dart          # DataSource 구현
├── garmin_oauth_service.dart       # OAuth 헬퍼 (신규)
├── garmin_token_storage.dart       # 토큰 저장 (신규)
└── models/
    ├── garmin_credentials.dart     # 인증 토큰 모델 (신규)
    └── (기타 모델들...)
```

### 데이터 플로우

```
User → OAuth WebView → Garmin Login
                ↓
        Request Token 발급
                ↓
        Authorization (사용자 승인)
                ↓
        Access Token 발급
                ↓
        Token Storage (Secure)
                ↓
        API Client (OAuth 서명)
                ↓
        Garmin Health API
                ↓
        WorkoutEntity 변환
```

---

## 🔧 Android Deep Link 설정

Garmin OAuth callback을 처리하기 위해 Deep Link 설정이 필요합니다.

### android/app/src/main/AndroidManifest.xml

```xml
<activity
    android:name=".MainActivity"
    ...>
    <!-- 기존 intent-filter는 유지 -->

    <!-- Garmin OAuth Callback -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <data
            android:scheme="coworkfit"
            android:host="garmin"
            android:pathPrefix="/callback" />
    </intent-filter>
</activity>
```

---

## 📱 사용 방법

### 1. 사용자 인증

```dart
final garminOAuthService = GarminOAuthService(tokenStorage);

// OAuth 플로우 시작
final credentials = await garminOAuthService.authenticate(context);

if (credentials != null) {
  print('Garmin 연동 성공: ${credentials.userId}');
} else {
  print('Garmin 연동 실패 또는 취소');
}
```

### 2. Activities 조회

```dart
final garminDataSource = GarminDataSource(
  apiClient: garminApiClient,
  tokenStorage: tokenStorage,
);

final result = await garminDataSource.fetchWorkoutDataWithSource(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

result.fold(
  (error) => print('Error: $error'),
  (workouts) => print('${workouts.length} workouts fetched'),
);
```

### 3. 연동 해제

```dart
await garminOAuthService.disconnect();
```

---

## 🧪 테스트

### 1. OAuth 플로우 테스트

```bash
# 1. 앱 실행
flutter run

# 2. Garmin 연동 화면으로 이동
# 3. "Garmin 연동" 버튼 클릭
# 4. WebView에서 Garmin 계정 로그인
# 5. 권한 승인
# 6. Callback 확인 (토큰 저장)
```

### 2. API 호출 테스트

Health Debug Page에 Garmin 테스트 추가 예정:
- Activities 조회
- Token 상태 확인
- 연동 해제

---

## 📚 API 엔드포인트

### Activities (운동 데이터)
- **URL**: `/wellness-api/rest/activities`
- **Parameters**:
  - `uploadStartTimeInSeconds`: Unix timestamp (초)
  - `uploadEndTimeInSeconds`: Unix timestamp (초)
- **Response**: Array of Activity objects

### Dailies (일일 요약)
- **URL**: `/wellness-api/rest/dailies`
- **Parameters**: 날짜 범위
- **Response**: 걸음, 거리, 칼로리 등

### 기타
- Sleep, Stress, Body Composition 등 추가 가능

---

## 🔍 트러블슈팅

### 문제: "Consumer Key not configured"

**원인**: `garmin_config.dart`에 실제 키가 설정되지 않음

**해결**:
```dart
static const String consumerKey = '실제_발급받은_키';
static const String consumerSecret = '실제_발급받은_시크릿';
```

### 문제: OAuth 웹뷰에서 "Invalid callback URL"

**원인**: Garmin Developer Portal의 Callback URL 설정 불일치

**해결**:
1. Developer Portal에서 Callback URL 확인
2. `coworkfit://garmin/callback` 정확히 일치해야 함

### 문제: API 호출 시 401 Unauthorized

**원인**:
- Token 만료
- OAuth 서명 오류

**해결**:
1. Token Storage 초기화: `tokenStorage.deleteCredentials()`
2. 재인증 필요
3. Consumer Key/Secret 확인

---

## 📖 참고 자료

- [Garmin Developer Portal](https://developer.garmin.com/)
- [Garmin Health API Documentation](https://developer.garmin.com/gc-developer-program/health-api/)
- [OAuth 1.0a Specification](https://oauth.net/core/1.0a/)
- [Flutter OAuth1 Package](https://pub.dev/packages/oauth1)

---

## 🎯 다음 단계 (Phase 2-5)

1. **Repository 통합** (Phase 2)
   - `health_repository_impl.dart`에 Garmin DataSource 추가
   - Platform 분기 로직
   - DI 설정

2. **Health Connect 제거** (Phase 3)
   - Android에서 Health Connect 대신 Garmin 사용
   - 관련 코드 정리

3. **UI 개선** (Phase 4)
   - Garmin 연동 화면
   - Settings에 연동 상태 표시
   - Health Debug Page에 Garmin 테스트 추가

4. **Samsung Health 통합** (Phase 5, 선택)
   - Garmin 미연동 사용자를 위한 대체 수단

---

_Last Updated: 2025-12-23_
_Version: 1.0 - Initial Implementation_
