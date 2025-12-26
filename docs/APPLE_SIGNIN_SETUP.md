# Apple Sign-In 설정 가이드

이 문서는 Co-WorkFit 앱에서 Apple Sign-In 기능을 활성화하기 위한 단계별 설정 가이드입니다.

## 📋 목차

1. [전제 조건](#-전제-조건)
2. [Apple Developer Portal 설정](#-apple-developer-portal-설정)
3. [Firebase Console 설정](#-firebase-console-설정)
4. [Android 추가 설정 (선택)](#-android-추가-설정-선택)
5. [테스트](#-테스트)
6. [트러블슈팅](#-트러블슈팅)

---

## ⚠️ 전제 조건

### 필수 사항

- **Apple Developer Program 멤버십** ($99/년) 필수
  - [Apple Developer Program 가입](https://developer.apple.com/programs/)
- **Bundle ID**: `com.hansol.coworkfit` (프로젝트에 이미 설정됨)

### 이미 완료된 작업

✅ Flutter 코드 구현 완료
- `sign_in_with_apple` 패키지 추가 (pubspec.yaml)
- Apple Sign-In UseCase 구현 (domain/usecases/sign_in_with_apple.dart)
- BLoC 이벤트/상태 추가 (presentation/bloc/)
- UI 로그인 버튼 추가 (presentation/pages/login_page.dart)

✅ iOS Entitlements 설정 완료
- `ios/Runner/Runner.entitlements`에 Apple Sign-In capability 추가

---

## 🍎 Apple Developer Portal 설정

Apple Sign-In을 사용하려면 Apple Developer Portal에서 App ID에 Sign in with Apple capability를 활성화해야 합니다.

### Step 1: Apple Developer Portal 접속

1. [Apple Developer Portal](https://developer.apple.com/account) 접속
2. Apple ID로 로그인
3. 좌측 사이드바 **"Certificates, Identifiers & Profiles"** 클릭

### Step 2: Identifiers 메뉴 이동

1. 좌측 메뉴 **"Identifiers"** 클릭
2. 기존 App ID 찾기 또는 새로 생성

### Step 2-1: 기존 App ID가 있는 경우 (권장)

기존에 `com.hansol.coworkfit` App ID가 있다면:

1. 목록에서 `com.hansol.coworkfit` 클릭
2. **Capabilities** 섹션에서 아래로 스크롤
3. **"Sign in with Apple"** 항목 찾기
4. 체크박스를 **✅ 체크**
5. **"Save"** 버튼 클릭
6. 확인 다이얼로그에서 **"Confirm"** 클릭

### Step 2-2: 새로운 App ID 생성하는 경우

기존 App ID가 없다면:

1. 우측 상단 파란색 **"+"** 버튼 클릭
2. **"App IDs"** 선택 → **"Continue"** 클릭
3. **"App"** 선택 → **"Continue"** 클릭
4. App ID 정보 입력:
   - **Description**: `Co-WorkFit`
   - **Bundle ID**: `Explicit` 선택
   - **Bundle ID 값**: `com.hansol.coworkfit`
5. **Capabilities** 섹션에서 다음 항목 체크:
   - ✅ **Sign in with Apple** (필수!)
   - ✅ **HealthKit** (이미 사용 중)
   - ✅ **Push Notifications** (향후 사용 예정)
6. **"Continue"** 클릭
7. 설정 확인 후 **"Register"** 클릭

### Step 3: 설정 확인

1. Identifiers 목록에서 `com.hansol.coworkfit` 클릭
2. Capabilities 섹션에서 다음 항목이 활성화되어 있는지 확인:
   - ✅ Sign in with Apple
   - ✅ HealthKit

---

## 🔥 Firebase Console 설정

Firebase Authentication에서 Apple 로그인 제공업체를 활성화해야 합니다.

### Step 1: Firebase Console 접속

1. [Firebase Console](https://console.firebase.google.com) 접속
2. **co-workfit** 프로젝트 선택

### Step 2: Authentication 설정

1. 좌측 메뉴 **"Authentication"** 클릭
2. 상단 탭 **"Sign-in method"** 클릭

### Step 3: Apple 제공업체 활성화

1. 제공업체 목록에서 **"Apple"** 찾기
2. **"Apple"** 행 클릭
3. **"Enable"** (사용 설정) 토글을 **ON**으로 변경
4. **"Save"** 버튼 클릭

### 설정 확인

- Authentication > Sign-in method 탭
- Apple 제공업체 상태가 **"Enabled"** (사용 설정됨)로 표시되어야 함

---

## 📱 Android 추가 설정 (선택)

Android에서도 Apple Sign-In을 지원하려면 추가 설정이 필요합니다.

> **참고**: iOS만 지원하려면 이 섹션을 건너뛰어도 됩니다.

### Step 1: Apple Developer Portal에서 Service ID 생성

1. [Apple Developer Portal](https://developer.apple.com/account) 접속
2. **Certificates, Identifiers & Profiles** 클릭
3. 좌측 메뉴 **"Identifiers"** 클릭
4. 우측 상단 파란색 **"+"** 버튼 클릭
5. **"Services IDs"** 선택 → **"Continue"** 클릭
6. Service ID 정보 입력:
   - **Description**: `Co-WorkFit Web Sign In`
   - **Identifier**: `com.hansol.coworkfit.signin`
7. **"Continue"** 클릭 → **"Register"** 클릭

### Step 2: Service ID 설정

1. 생성된 Service ID (`com.hansol.coworkfit.signin`) 클릭
2. **"Sign in with Apple"** 체크 후 **"Configure"** 버튼 클릭
3. **Primary App ID** 선택: `com.hansol.coworkfit`
4. **Domains and Subdomains** 입력:
   - Firebase Auth 도메인 입력 (예: `co-workfit.firebaseapp.com`)
5. **Return URLs** 입력:
   - `https://{YOUR_PROJECT_ID}.firebaseapp.com/__/auth/handler`
   - 예: `https://co-workfit.firebaseapp.com/__/auth/handler`
6. **"Next"** → **"Done"** → **"Continue"** → **"Save"** 클릭

### Step 3: Firebase Console에 Service ID 추가

1. Firebase Console > Authentication > Sign-in method
2. **Apple** 제공업체 다시 클릭
3. **OAuth code flow configuration** (선택사항) 섹션 펼치기
4. **Service ID** 입력: `com.hansol.coworkfit.signin`
5. **"Save"** 클릭

---

## 🧪 테스트

설정이 완료되면 앱에서 Apple Sign-In을 테스트할 수 있습니다.

### iOS 테스트

**중요**: Apple Sign-In은 **실제 iOS 기기**에서만 테스트 가능합니다. (시뮬레이터 지원 제한적)

```bash
# 연결된 iOS 기기 확인
flutter devices

# 실제 iOS 기기에서 실행 (iOS 13.0 이상)
flutter run -d <ios-device-id>
```

### Android 테스트 (Service ID 설정한 경우)

```bash
# Android 기기/에뮬레이터에서 실행
flutter run -d <android-device-id>
```

### 테스트 체크리스트

- [ ] 로그인 페이지에 Apple 로그인 버튼 표시
- [ ] Apple 로그인 버튼 클릭 시 Apple 인증 화면 표시
- [ ] Apple ID로 로그인 성공
- [ ] 이메일/이름 공유 선택 가능
- [ ] 로그인 후 홈 화면으로 이동
- [ ] Firebase Console > Authentication > Users에 사용자 추가됨
- [ ] 로그아웃 후 재로그인 가능

---

## 🔧 트러블슈팅

### 문제 1: "Sign in with Apple is not configured for this app"

**원인**: Apple Developer Portal에서 App ID에 Sign in with Apple capability가 활성화되지 않음

**해결**:
1. Apple Developer Portal > Identifiers
2. App ID (`com.hansol.coworkfit`) 클릭
3. Sign in with Apple 체크
4. Save

### 문제 2: iOS 시뮬레이터에서 작동하지 않음

**원인**: Apple Sign-In은 실제 기기에서만 완전히 지원됨

**해결**:
- 실제 iOS 기기 (iOS 13.0 이상)에서 테스트
- 시뮬레이터에서는 제한적으로만 작동할 수 있음

### 문제 3: Firebase Console에서 사용자가 생성되지 않음

**원인**: Firebase에서 Apple 제공업체가 활성화되지 않음

**해결**:
1. Firebase Console > Authentication > Sign-in method
2. Apple 제공업체 활성화 확인
3. Enable 토글이 ON인지 확인

### 문제 4: Android에서 "Invalid client"

**원인**: Service ID 설정이 잘못되었거나 Firebase에 등록되지 않음

**해결**:
1. Apple Developer Portal에서 Service ID 생성 확인
2. Service ID의 Return URLs에 Firebase Auth 도메인 올바르게 입력
3. Firebase Console에서 Service ID 입력 확인

### 문제 5: "The operation couldn't be completed"

**원인**: Bundle ID 불일치 또는 Provisioning Profile 문제

**해결**:
1. Xcode에서 Bundle Identifier 확인: `com.hansol.coworkfit`
2. Apple Developer Portal의 App ID와 일치하는지 확인
3. Xcode > Signing & Capabilities 탭에서 Signing 재설정

---

## 📚 참고 자료

### Apple 공식 문서
- [Sign in with Apple 개요](https://developer.apple.com/sign-in-with-apple/)
- [Sign in with Apple 가이드](https://developer.apple.com/documentation/sign_in_with_apple)
- [App ID 설정](https://developer.apple.com/help/account/manage-identifiers/register-an-app-id/)

### Firebase 공식 문서
- [Firebase Apple Sign-In 가이드 (iOS)](https://firebase.google.com/docs/auth/ios/apple)
- [Firebase Apple Sign-In 가이드 (Android)](https://firebase.google.com/docs/auth/android/apple)

### Flutter 패키지
- [sign_in_with_apple 패키지](https://pub.dev/packages/sign_in_with_apple)
- [sign_in_with_apple 예제](https://github.com/aboutyou/dart_packages/tree/master/packages/sign_in_with_apple/sign_in_with_apple)

---

## ✅ 설정 완료 체크리스트

### Apple Developer Portal
- [ ] Apple Developer Program 멤버십 가입 ($99/년)
- [ ] App ID (`com.hansol.coworkfit`) 생성 또는 확인
- [ ] App ID에 Sign in with Apple capability 활성화
- [ ] (Android용) Service ID 생성 및 설정 (선택)

### Firebase Console
- [ ] Authentication > Sign-in method > Apple 활성화
- [ ] (Android용) Service ID 등록 (선택)

### 코드 (이미 완료)
- [x] `sign_in_with_apple` 패키지 추가
- [x] iOS Entitlements 설정
- [x] Apple Sign-In 코드 구현

### 테스트
- [ ] iOS 실기기에서 Apple Sign-In 테스트 성공
- [ ] (Android용) Android에서 Apple Sign-In 테스트 성공 (선택)
- [ ] Firebase Console에서 사용자 생성 확인

---

## 🚀 다음 단계

Apple Sign-In 설정이 완료되면:

1. **iOS 배포 준비** (Issue #35)
   - TestFlight 베타 테스트
   - App Store 제출 준비

2. **App Store 심사 통과**
   - Apple Sign-In은 Google Sign-In을 제공하는 앱에 필수
   - App Store 가이드라인 준수 확인

3. **프로덕션 배포**
   - TestFlight 베타 테스트 완료
   - App Store 정식 출시

---

**작성일**: 2025-12-26
**버전**: 1.0
**관련 이슈**: #41
