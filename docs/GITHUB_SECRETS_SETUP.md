# GitHub Secrets 설정 가이드

이 문서는 Co-WorkFit iOS 배포를 위한 GitHub Secrets 설정 방법을 단계별로 안내합니다.

## 📋 목차

1. [GitHub Secrets 설정 위치](#github-secrets-설정-위치)
2. [Firebase Secrets](#firebase-secrets)
3. [Apple Secrets](#apple-secrets)
4. [설정 확인](#설정-확인)

---

## GitHub Secrets 설정 위치

1. GitHub 리포지토리 접속: https://github.com/lppresident/co-workfit
2. **Settings** 탭 클릭
3. 좌측 메뉴에서 **Secrets and variables** → **Actions** 클릭
4. **New repository secret** 버튼으로 각 Secret 추가

---

## Firebase Secrets

### 1️⃣ FIREBASE_IOS_APP_ID

Firebase iOS 앱 ID를 설정합니다.

#### 찾는 방법:

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **co-workfit** 프로젝트 선택
3. 좌측 상단 톱니바퀴 아이콘 → **프로젝트 설정** 클릭
4. **일반** 탭에서 아래로 스크롤
5. **내 앱** 섹션에서 iOS 앱 찾기
   - **앱이 없으면**: "앱 추가" → iOS 선택 → Bundle ID: `com.hansol.coworkfit` 입력
6. **앱 ID** 복사

**형식 예시:**
```
1:123456789012:ios:abcdef1234567890abcdef
```

#### GitHub Secret 추가:
- **Name**: `FIREBASE_IOS_APP_ID`
- **Secret**: 위에서 복사한 앱 ID

---

### 2️⃣ FIREBASE_SERVICE_ACCOUNT

Firebase Admin SDK 서비스 계정 JSON 파일입니다.

#### 찾는 방법:

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **co-workfit** 프로젝트 선택
3. 좌측 상단 톱니바퀴 아이콘 → **프로젝트 설정** 클릭
4. **서비스 계정** 탭 클릭
5. **새 비공개 키 생성** 버튼 클릭
6. **키 생성** 확인 → JSON 파일 다운로드됨
7. 다운로드한 JSON 파일을 텍스트 에디터로 열기
8. **전체 내용** 복사

**JSON 형식 예시:**
```json
{
  "type": "service_account",
  "project_id": "co-workfit",
  "private_key_id": "abcdef1234567890...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBg...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@co-workfit.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

#### GitHub Secret 추가:
- **Name**: `FIREBASE_SERVICE_ACCOUNT`
- **Secret**: JSON 파일 전체 내용 붙여넣기 (줄바꿈 포함)

---

## Apple Secrets

### 3️⃣ APPLE_ID

Apple Developer 계정의 Apple ID (이메일 주소)입니다.

#### 찾는 방법:

Apple Developer Program에 가입할 때 사용한 이메일 주소입니다.

**예시:**
```
your-email@example.com
```

#### GitHub Secret 추가:
- **Name**: `APPLE_ID`
- **Secret**: Apple ID 이메일 주소

---

### 4️⃣ APPLE_APP_SPECIFIC_PASSWORD

App Store Connect용 앱 전용 암호입니다.

#### 생성 방법:

1. [Apple ID 계정 페이지](https://appleid.apple.com/) 접속
2. Apple ID로 로그인
3. **로그인 및 보안** 섹션으로 이동
4. **앱 암호** (App-Specific Passwords) 클릭
5. **+** 버튼 또는 **암호 생성** 클릭
6. 레이블 입력 (예: `GitHub Actions CoWorkfit`)
7. **생성** 클릭
8. 생성된 암호 복사 (다시 볼 수 없으니 바로 복사!)

**형식 예시:**
```
abcd-efgh-ijkl-mnop
```

⚠️ **중요**: 이 암호는 생성 후 다시 볼 수 없습니다! 바로 복사하여 저장하세요.

#### GitHub Secret 추가:
- **Name**: `APPLE_APP_SPECIFIC_PASSWORD`
- **Secret**: 생성된 앱 전용 암호

---

### 5️⃣ APPLE_TEAM_ID

Apple Developer Team ID입니다.

#### 찾는 방법:

**방법 1: Apple Developer Portal**
1. [Apple Developer Portal](https://developer.apple.com/account) 접속
2. 로그인
3. 우측 상단 사용자 이름 아래에 Team ID 표시됨
   - 또는 **Membership** 메뉴 클릭
4. **Team ID** 복사 (10자리 영문/숫자)

**방법 2: App Store Connect**
1. [App Store Connect](https://appstoreconnect.apple.com/) 접속
2. **Users and Access** 클릭
3. **Keys** 탭 클릭 (또는 **Integrations** → **API Keys**)
4. Issuer ID 아래에 있는 항목 확인
   - 또는 상단에 Team ID가 표시됨

**방법 3: Xcode**
1. Xcode에서 프로젝트 열기
2. **Signing & Capabilities** 탭
3. **Team** 드롭다운 옆에 Team ID 표시

**형식 예시:**
```
A1B2C3D4E5
```

#### GitHub Secret 추가:
- **Name**: `APPLE_TEAM_ID`
- **Secret**: 10자리 Team ID

---

## 설정 확인

### 모든 Secrets 확인

GitHub 리포지토리 → Settings → Secrets and variables → Actions에서 다음 항목들이 모두 있는지 확인:

#### Firebase (iOS Dev 배포용)
- ✅ `FIREBASE_IOS_APP_ID`
- ✅ `FIREBASE_SERVICE_ACCOUNT`

#### Apple (TestFlight 배포용)
- ✅ `APPLE_ID`
- ✅ `APPLE_APP_SPECIFIC_PASSWORD`
- ✅ `APPLE_TEAM_ID`

### 기존 Android Secrets (이미 설정되어 있어야 함)
- ✅ `FIREBASE_APP_ID` (Android 앱 ID)

---

## 배포 실행

모든 Secrets 설정이 완료되면:

### iOS Dev/QA 배포 (Firebase App Distribution)

1. GitHub 리포지토리 → **Actions** 탭
2. **Deploy iOS (Dev/QA)** 워크플로우 선택
3. **Run workflow** 버튼 클릭
4. 옵션 선택:
   - **version_bump**: `build` (첫 배포)
   - **release_notes**: `iOS 첫 배포 테스트`
   - **deploy_to_firebase**: ✅ true
   - **deploy_to_github**: ✅ true
5. **Run workflow** 버튼 클릭

**필요한 Secrets:**
- `FIREBASE_IOS_APP_ID`
- `FIREBASE_SERVICE_ACCOUNT`

---

### iOS Beta 배포 (TestFlight)

1. GitHub 리포지토리 → **Actions** 탭
2. **Deploy iOS (Beta)** 워크플로우 선택
3. **Run workflow** 버튼 클릭
4. 옵션 선택:
   - **version_bump**: `build`
   - **release_notes**: `TestFlight 베타 테스트`
   - **upload_to_testflight**: ✅ true
   - **deploy_to_github**: ✅ true
5. **Run workflow** 버튼 클릭

**필요한 Secrets:**
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

---

## 트러블슈팅

### "Secret not found" 에러
- GitHub Settings → Secrets에서 Secret 이름 철자 확인
- 대소문자 구분 확인 (정확히 일치해야 함)

### Firebase 배포 실패
- `FIREBASE_IOS_APP_ID` 형식 확인 (콜론 `:` 포함)
- `FIREBASE_SERVICE_ACCOUNT` JSON 전체 복사 확인

### Apple 인증 실패
- `APPLE_APP_SPECIFIC_PASSWORD`가 올바른지 확인
- Apple ID에서 2단계 인증이 활성화되어 있는지 확인
- `APPLE_TEAM_ID`가 10자리인지 확인

### 인증서/프로비저닝 에러
- Xcode에서 Signing & Capabilities 설정 확인
- Apple Developer Portal에서 인증서 상태 확인

---

## 참고 자료

- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Apple ID 계정 페이지](https://appleid.apple.com/)

---

**작성일**: 2025-12-26
**버전**: 1.0
