# 배포 자동화 가이드

이 문서는 CoWorkfit 앱의 GitHub Actions를 사용한 자동 배포 설정 방법을 설명합니다.

## 워크플로우 종류

### 1. Android 배포 (`deploy-android.yml`)
- APK 빌드 및 배포
- Firebase App Distribution에 배포
- GitHub Release 생성

### 2. iOS 개발/QA 배포 (`deploy-ios-dev.yml`)
- IPA 빌드 (Ad-Hoc)
- Firebase App Distribution에 배포 (빠른 테스트용)
- GitHub Release 생성

### 3. iOS 베타 배포 (`deploy-ios-beta.yml`)
- IPA 빌드 (App Store)
- TestFlight에 업로드 (최종 검증용)
- GitHub Release 생성

### 4. 전체 플랫폼 배포 (`deploy-all.yml`)
- Android와 iOS를 동시에 빌드 및 배포
- iOS는 Firebase 또는 TestFlight 선택 가능
- 통합 GitHub Release 생성

## 필요한 GitHub Secrets 설정

리포지토리 Settings > Secrets and variables > Actions에서 다음 secrets를 설정해야 합니다:

### Android 배포용 Secrets

#### `FIREBASE_APP_ID`
Firebase 앱 ID입니다.

**설정 방법:**
1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 프로젝트 선택
3. Project Settings > General로 이동
4. Android 앱 선택
5. "App ID" 복사 (형식: `1:123456789:android:abcdef123456`)

#### `FIREBASE_SERVICE_ACCOUNT`
Firebase Admin SDK 서비스 계정 JSON 파일입니다.

**설정 방법:**
1. Firebase Console > Project Settings > Service Accounts
2. "Generate new private key" 클릭
3. 다운로드한 JSON 파일 전체 내용을 복사
4. GitHub Secret에 JSON 전체를 붙여넣기

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "...",
  ...
}
```

### iOS 배포용 Secrets

#### Firebase 배포용 (deploy-ios-dev.yml)

##### `FIREBASE_IOS_APP_ID`
Firebase iOS 앱 ID입니다.

**설정 방법:**
1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 프로젝트 선택
3. Project Settings > General로 이동
4. iOS 앱 선택 (없으면 "Add app" > iOS 선택하여 추가)
5. "App ID" 복사 (형식: `1:123456789:ios:abcdef123456`)

**참고:** Android와 동일한 `FIREBASE_SERVICE_ACCOUNT`를 사용합니다.

#### TestFlight 배포용 (deploy-ios-beta.yml)

##### `APPLE_ID`
Apple Developer 계정의 Apple ID (이메일)입니다.

**예시:**
```
developer@example.com
```

##### `APPLE_APP_SPECIFIC_PASSWORD`
App Store Connect API용 앱별 암호입니다.

**설정 방법:**
1. [Apple ID 계정 페이지](https://appleid.apple.com/)에 로그인
2. Sign-In and Security > App-Specific Passwords
3. "Generate an app-specific password" 클릭
4. 이름 입력 (예: "GitHub Actions")
5. 생성된 암호 복사 (형식: `xxxx-xxxx-xxxx-xxxx`)

##### `APPLE_TEAM_ID`
Apple Developer Team ID입니다.

**설정 방법:**
1. [Apple Developer](https://developer.apple.com/account)에 로그인
2. Membership 섹션에서 Team ID 확인 (10자리 영숫자)

**예시:**
```
AB12CD34EF
```

**참고:** TestFlight 배포는 Apple Developer 유료 계정($99/year)이 필요합니다.

## iOS 코드 서명 설정

Xcode에서 코드 서명을 설정해야 합니다:

1. Xcode에서 프로젝트 열기
2. Runner 타겟 선택 > Signing & Capabilities
3. "Automatically manage signing" 활성화
4. 개발 팀 선택
5. Bundle Identifier 확인: `com.hansol.coworkfit`

### 배포 방식별 요구사항

- **Firebase (Ad-Hoc)**: Apple Developer 유료 계정 필요 ($99/year)
- **TestFlight (App Store)**: Apple Developer 유료 계정 필요 ($99/year)

**참고:** 두 방식 모두 Apple Developer 유료 계정이 필요하지만, 사용 목적이 다릅니다:
- Firebase: 빠른 내부 테스트 (심사 없음)
- TestFlight: 광범위한 베타 테스트 및 앱스토어 준비

## 워크플로우 실행 방법

### 수동 실행

1. GitHub 리포지토리의 **Actions** 탭으로 이동
2. 왼쪽에서 실행할 워크플로우 선택:
   - **"Deploy Android"** - Android만 배포 (Firebase)
   - **"Deploy iOS (Dev/QA)"** - iOS 개발/QA 배포 (Firebase, 빠른 테스트)
   - **"Deploy iOS (Beta/TestFlight)"** - iOS 베타 배포 (TestFlight, 최종 검증)
   - **"Deploy All Platforms"** - 양쪽 모두 배포 (Firebase + 선택적 TestFlight)
3. **Run workflow** 버튼 클릭
4. 옵션 선택:
   - **version_bump**: 버전 증가 방식 선택
     - `build`: 빌드 번호만 증가 (0.0.1+1 → 0.0.1+2)
     - `patch`: 패치 버전 증가 (0.0.1 → 0.0.2)
     - `minor`: 마이너 버전 증가 (0.0.1 → 0.1.0)
     - `major`: 메이저 버전 증가 (0.0.1 → 1.0.0)
   - **release_notes**: 릴리스 노트 입력
   - **배포 옵션**: 원하는 배포 대상 선택
5. **Run workflow** 버튼 클릭

## 버전 관리

- 앱 버전은 `pubspec.yaml` 파일에서 관리됩니다
- 형식: `major.minor.patch+build` (예: `0.0.1+1`)
- 워크플로우 실행 시 자동으로 버전이 증가하고 커밋됩니다

## 현재 프로젝트 설정

- **Flutter 버전**: 3.38.1 (stable)
- **앱 버전**: 0.0.1+1
- **Bundle ID (iOS)**: com.hansol.coworkfit
- **Display Name**: Co-WorkFit
- **Java 버전**: 17 (Android 빌드용)

## 트러블슈팅

### Android 빌드 실패
- Firebase secrets가 올바르게 설정되었는지 확인
- `google-services.json` 파일이 프로젝트에 있는지 확인
- `FIREBASE_APP_ID`가 Android 앱 ID인지 확인

### iOS 빌드 실패

#### Firebase 배포 실패
- Firebase iOS secrets가 올바르게 설정되었는지 확인
- `FIREBASE_IOS_APP_ID`가 iOS 앱 ID인지 확인
- Xcode 프로젝트에서 signing이 설정되어 있는지 확인
- `GoogleService-Info.plist` 파일이 iOS 프로젝트에 있는지 확인
- Ad-Hoc 배포를 위한 Provisioning Profile이 있는지 확인

#### TestFlight 배포 실패
- Apple secrets가 올바르게 설정되었는지 확인
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` 확인
- App Store Connect에서 앱이 등록되어 있는지 확인
- Bundle ID가 일치하는지 확인
- App Store 배포를 위한 Distribution Certificate가 있는지 확인

### 버전 커밋 실패
- GitHub Actions가 리포지토리에 push 권한이 있는지 확인
- Settings > Actions > General > Workflow permissions에서 "Read and write permissions" 활성화

## 참고 자료

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [GitHub Actions 문서](https://docs.github.com/en/actions)

## 문의

배포 관련 문제가 있으면 이슈를 생성해 주세요.
