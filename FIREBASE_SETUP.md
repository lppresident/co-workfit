# Firebase 설정 가이드

Phase 3에서 구현된 소셜 기능(인증, 친구 시스템, 리더보드)을 사용하려면 Firebase 프로젝트를 설정해야 합니다.

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `co-workfit` (또는 원하는 이름)
4. Google Analytics 설정 (선택 사항)
5. 프로젝트 생성 완료

## 2. FlutterFire CLI 설정 (권장)

가장 쉬운 방법은 FlutterFire CLI를 사용하는 것입니다:

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 연결
flutterfire configure
```

`flutterfire configure` 명령은 자동으로:
- Firebase 프로젝트 선택
- iOS/Android 앱 등록
- 필요한 구성 파일 생성
- `firebase_options.dart` 파일 생성

## 3. 수동 설정 (선택 사항)

FlutterFire CLI를 사용하지 않는 경우:

### iOS 설정

1. Firebase Console에서 iOS 앱 추가
2. Bundle ID 입력: `com.example.coWorkfit` (또는 `ios/Runner.xcodeproj`에서 확인한 실제 Bundle ID)
3. `GoogleService-Info.plist` 파일 다운로드
4. `ios/Runner/` 폴더에 파일 추가
5. Xcode에서 프로젝트에 파일 추가 (Copy items if needed 체크)

### Android 설정

1. Firebase Console에서 Android 앱 추가
2. 패키지 이름 입력: `com.example.co_workfit` (또는 `android/app/build.gradle`에서 확인)
3. `google-services.json` 파일 다운로드
4. `android/app/` 폴더에 파일 배치

5. `android/build.gradle` 수정:
```gradle
buildscript {
    dependencies {
        // Google Services plugin 추가
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

6. `android/app/build.gradle` 수정:
```gradle
// 파일 최하단에 추가
apply plugin: 'com.google.gms.google-services'
```

## 4. Firebase 서비스 활성화

### Authentication

1. Firebase Console → Authentication → Sign-in method
2. 다음 인증 방법 활성화:
   - 이메일/비밀번호
   - Google (선택 사항)

### Firestore Database

1. Firebase Console → Firestore Database → 데이터베이스 만들기
2. 위치 선택: `asia-northeast3 (Seoul)` 권장
3. 보안 규칙: 테스트 모드로 시작 (나중에 프로덕션 규칙으로 변경)

### 보안 규칙 설정

Firestore Database → 규칙 탭에서 다음 규칙을 설정하세요:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 사용자 문서
    match /users/{userId} {
      // 본인의 문서는 읽기/쓰기 가능
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // 운동 기록
    match /workouts/{workoutId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     request.resource.data.userId == request.auth.uid;
    }

    // 친구 요청
    match /friend_requests/{requestId} {
      // 본인이 보낸 요청이거나 받은 요청만 읽기 가능
      allow read: if request.auth != null && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
      // 본인이 보내는 요청만 생성 가능
      allow create: if request.auth != null &&
                      request.resource.data.senderId == request.auth.uid;
      // 본인이 받은 요청만 업데이트/삭제 가능
      allow update, delete: if request.auth != null && (
        resource.data.senderId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
    }

    // 친구 관계
    match /friends/{friendshipId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     request.resource.data.userId == request.auth.uid;
    }

    // 리더보드는 모든 인증된 사용자가 읽기 가능
    match /leaderboard/{entry} {
      allow read: if request.auth != null;
      allow write: if false; // 서버에서만 업데이트
    }
  }
}
```

## 5. Google Sign-In 설정 (선택 사항)

### iOS

1. `GoogleService-Info.plist`에서 `REVERSED_CLIENT_ID` 확인
2. `ios/Runner/Info.plist`에 URL Scheme 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Android

`android/app/build.gradle`에 이미 설정되어 있습니다 (google-services.json에서 자동 처리).

## 6. 앱 실행 및 테스트

```bash
# 패키지 가져오기
flutter pub get

# 코드 생성
dart run build_runner build --delete-conflicting-outputs

# iOS 실행
flutter run -d ios

# Android 실행
flutter run -d android
```

## 7. Firebase 초기화 확인

앱 실행 시 로그에서 다음 메시지 확인:
```
[Firebase] Firebase initialized successfully
```

에러가 발생하면:
- 구성 파일이 올바른 위치에 있는지 확인
- Bundle ID / Package Name이 일치하는지 확인
- FlutterFire CLI로 재설정: `flutterfire configure`

## 8. Firestore 컬렉션 구조

앱이 자동으로 생성하는 컬렉션:

- `users`: 사용자 정보
  - `id` (문서 ID = Auth UID)
  - `email`, `displayName`, `photoUrl`
  - `totalScore`, `workoutCount`
  - `createdAt`, `lastActiveAt`

- `workouts`: 운동 기록
  - `userId`, `type`, `source`
  - `score`, `calories`, `duration`, `distance`
  - `startTime`, `endTime`

- `friend_requests`: 친구 요청
  - `senderId`, `senderName`, `receiverId`
  - `status`: pending / accepted / rejected
  - `createdAt`, `respondedAt`

- `friends`: 친구 관계 (양방향)
  - `userId`, `friendId`
  - `friendName`, `friendEmail`, `friendPhotoUrl`
  - `createdAt`

## 문제 해결

### "Firebase initialization failed" 에러
- FlutterFire CLI로 재설정: `flutterfire configure`
- iOS: Xcode에서 GoogleService-Info.plist가 프로젝트에 포함되어 있는지 확인
- Android: google-services.json이 android/app/에 있는지 확인

### Google Sign-In이 작동하지 않음
- Firebase Console에서 Google 인증이 활성화되어 있는지 확인
- iOS: REVERSED_CLIENT_ID가 Info.plist에 올바르게 추가되었는지 확인
- Android: SHA-1 fingerprint를 Firebase Console에 등록 (디버그/릴리즈 모두)

### 권한 에러 (permission-denied)
- Firestore 보안 규칙 확인
- 사용자가 로그인되어 있는지 확인

## 다음 단계

Firebase 설정 완료 후:
- Phase 3 UI 구현 (로그인 화면, 친구 목록, 리더보드)
- Phase 4 고급 기능 (그룹 챌린지, 목표 설정, AI 추천 등)

---

문제가 발생하면 [Firebase 공식 문서](https://firebase.google.com/docs/flutter/setup) 참고
