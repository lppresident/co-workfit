# Android Google Sign-In 수정 가이드

## 문제 상황
안드로이드에서 구글 로그인 시도 후 앱으로 복귀하면 로그인이 완료되지 않는 이슈

## 원인
`android/app/google-services.json`에 OAuth 클라이언트 설정이 누락됨

## 해결 방법

### 1단계: SHA-1 인증서 지문 확인

#### Debug용 SHA-1 (개발/테스트)
```bash
cd android
./gradlew signingReport
```

또는:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Release용 SHA-1 (프로덕션)
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

SHA-1 지문을 복사해두세요. 예시:
```
SHA1: 12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78
```

### 2단계: Firebase Console에서 SHA-1 등록

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **co-workfit** 프로젝트 선택
3. 좌측 메뉴에서 **프로젝트 설정** (⚙️) 클릭
4. **일반** 탭 선택
5. **내 앱** 섹션에서 Android 앱 찾기
6. **SHA 인증서 지문** 섹션에서 **지문 추가** 클릭
7. Debug SHA-1과 Release SHA-1 둘 다 추가

### 3단계: OAuth 2.0 클라이언트 ID 생성

Firebase Console에서 SHA-1을 추가하면 자동으로 OAuth 클라이언트가 생성됩니다.

또는 수동으로:

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. **co-workfit** 프로젝트 선택
3. **APIs & Services** > **사용자 인증 정보** 메뉴
4. **+ 사용자 인증 정보 만들기** > **OAuth 클라이언트 ID** 클릭
5. 애플리케이션 유형: **Android** 선택
6. 이름: `Co-WorkFit Android`
7. 패키지 이름: `com.coworkfit.co_workfit`
8. SHA-1 인증서 지문 입력
9. **만들기** 클릭

### 4단계: google-services.json 다운로드 및 교체

1. Firebase Console > 프로젝트 설정 > 일반
2. **내 앱** 섹션에서 Android 앱 선택
3. **google-services.json 다운로드** 클릭
4. 다운로드한 파일을 `android/app/google-services.json`에 덮어쓰기

새 파일에는 `oauth_client` 배열이 채워져 있어야 합니다:
```json
"oauth_client": [
  {
    "client_id": "89240730998-xxxxxxxxxxxxx.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

### 5단계: 빌드 후 테스트

```bash
# 클린 빌드
flutter clean
flutter pub get

# 안드로이드 빌드 및 실행
flutter run
```

## 추가 확인 사항

### Google Sign-In 플러그인 버전 확인
`pubspec.yaml`에서:
```yaml
dependencies:
  google_sign_in: ^6.2.2  # ✅ 최신 버전 사용 중
```

### AndroidManifest.xml 확인
특별한 설정 불필요 - Google Sign-In 플러그인이 자동으로 처리

### 디버깅 로그 추가 (선택사항)
문제가 계속되면 로그를 추가하여 원인 파악:

`lib/features/auth/data/datasources/firebase_auth_datasource.dart`의 `signInWithGoogle()` 메서드에:

```dart
try {
  AppLogger.info('GoogleSignIn', 'Starting Google sign-in flow');
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

  if (googleUser == null) {
    AppLogger.warning('GoogleSignIn', 'User cancelled sign-in');
    return const Left('Google 로그인이 취소되었습니다.');
  }

  AppLogger.info('GoogleSignIn', 'Google user signed in: ${googleUser.email}');
  // ... 나머지 코드
} catch (e) {
  AppLogger.error('GoogleSignIn', 'Sign-in failed: $e');
  return Left('Google 로그인에 실패했습니다: $e');
}
```

## 체크리스트

- [ ] SHA-1 지문 확인 (Debug & Release)
- [ ] Firebase Console에 SHA-1 등록
- [ ] OAuth 2.0 클라이언트 ID 생성 확인
- [ ] 새 google-services.json 다운로드 및 교체
- [ ] oauth_client 배열이 비어있지 않은지 확인
- [ ] Clean build 및 재실행
- [ ] 안드로이드 기기에서 Google 로그인 테스트

## 참고 자료

- [Firebase Android 설정](https://firebase.google.com/docs/android/setup)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start)
- [Flutter google_sign_in 플러그인](https://pub.dev/packages/google_sign_in)
