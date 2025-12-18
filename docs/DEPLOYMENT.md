# APK 배포 가이드

CoWorkfit 앱을 테스트용 APK로 빌드하고 배포하는 방법을 설명합니다.

## 목차
- [로컬에서 수동 배포](#로컬에서-수동-배포)
- [자동화 스크립트 사용](#자동화-스크립트-사용)
- [GitHub Actions 사용](#github-actions-사용)
- [Firebase App Distribution 설정](#firebase-app-distribution-설정)
- [테스터 안내 문서](#테스터-안내-문서)

---

## 로컬에서 수동 배포

### 1. APK 빌드

```bash
# 의존성 설치
flutter pub get

# 릴리스 APK 빌드
flutter build apk --release

# 빌드된 APK 위치
# build/app/outputs/flutter-apk/app-release.apk
```

### 2. APK 배포 방법

#### Option A: 직접 전달
1. APK 파일을 Google Drive, Dropbox 등에 업로드
2. 공유 링크 생성
3. 친구들에게 링크 전달

#### Option B: GitHub Release
```bash
gh release create v0.0.1 build/app/outputs/flutter-apk/app-release.apk \
  --title "CoWorkfit v0.0.1" \
  --notes "첫 번째 테스트 버전" \
  --prerelease
```

---

## 자동화 스크립트 사용

`scripts/deploy_apk.sh` 스크립트를 사용하면 빌드부터 배포까지 자동화할 수 있습니다.

### 기본 사용법

```bash
# 로컬 빌드만 (기본값)
./scripts/deploy_apk.sh

# 빌드 번호만 증가 (0.0.1+1 → 0.0.1+2)
./scripts/deploy_apk.sh build "버그 수정"

# 패치 버전 증가 (0.0.1 → 0.0.2)
./scripts/deploy_apk.sh patch "UI 개선"

# 마이너 버전 증가 (0.0.1 → 0.1.0)
./scripts/deploy_apk.sh minor "새로운 기능 추가"

# 메이저 버전 증가 (0.0.1 → 1.0.0)
./scripts/deploy_apk.sh major "첫 정식 릴리스"
```

### Firebase App Distribution에 배포

```bash
# 환경 변수 설정
export FIREBASE_APP_ID="your-firebase-app-id"
export FIREBASE_TESTER_GROUPS="testers"
export DEPLOY_METHOD="firebase"

# 배포 실행
./scripts/deploy_apk.sh build "새 버전 테스트"
```

### GitHub Release 생성

```bash
export DEPLOY_METHOD="github"
./scripts/deploy_apk.sh build "GitHub Release"
```

### Firebase와 GitHub 동시 배포

```bash
export DEPLOY_METHOD="both"
./scripts/deploy_apk.sh build "모든 플랫폼에 배포"
```

---

## GitHub Actions 사용

GitHub Actions를 사용하면 브라우저에서 버튼 클릭만으로 배포할 수 있습니다.

### 초기 설정

#### 1. Firebase 설정 (선택사항)

Firebase App Distribution을 사용하려면 다음 Secret을 설정해야 합니다:

1. Firebase 콘솔에서 앱 ID 확인
   - Project Settings → General → Your apps → App ID

2. Firebase 서비스 계정 키 생성
   ```bash
   firebase login
   firebase projects:list
   # Service Account 키 다운로드
   ```

3. GitHub Repository Secrets 설정
   - Settings → Secrets and variables → Actions
   - `FIREBASE_APP_ID`: Firebase 앱 ID
   - `FIREBASE_SERVICE_ACCOUNT`: 서비스 계정 JSON 내용

#### 2. GitHub Actions 실행 권한 설정

1. Settings → Actions → General
2. "Workflow permissions"에서 "Read and write permissions" 선택
3. "Allow GitHub Actions to create and approve pull requests" 체크

### 배포 실행 방법

1. GitHub 저장소로 이동
2. **Actions** 탭 클릭
3. 왼쪽에서 **Deploy APK** 워크플로우 선택
4. **Run workflow** 버튼 클릭
5. 옵션 선택:
   - **버전 증가 타입**: build / patch / minor / major
   - **릴리스 노트**: 변경 사항 설명
   - **Firebase 배포**: 체크/해제
   - **GitHub Release**: 체크/해제
6. **Run workflow** 실행

### 워크플로우 동작

1. 버전 자동 증가 (pubspec.yaml)
2. Flutter APK 빌드
3. Firebase App Distribution 배포 (선택시)
4. GitHub Release 생성 (선택시)
5. 버전 변경사항 자동 커밋
6. APK를 Artifact로 저장 (30일 보관)

---

## Firebase App Distribution 설정

Firebase App Distribution을 사용하면 테스터 관리와 배포가 훨씬 편리합니다.

### 1. Firebase CLI 설치

```bash
npm install -g firebase-tools
```

### 2. Firebase 로그인

```bash
firebase login
```

### 3. Firebase 프로젝트 초기화

```bash
firebase init appdistribution
```

### 4. 테스터 그룹 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택
3. App Distribution 메뉴
4. "Testers & Groups" 탭
5. "Create Group" 클릭
6. 그룹 이름: `testers`
7. 테스터 이메일 추가

### 5. 수동 배포

```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_APP_ID> \
  --groups "testers" \
  --release-notes "테스트 버전"
```

### 6. 테스터가 받는 방법

1. 이메일로 초대 링크 수신
2. Firebase App Tester 앱 설치 (Android)
3. 앱에서 CoWorkfit 찾아서 설치
4. 새 버전이 배포되면 자동으로 알림 수신

---

## 테스터 안내 문서

친구들에게 다음 내용을 전달하세요:

### Android APK 설치 방법

#### 1. 출처 불명 앱 허용 설정

**Android 8.0 이상:**
1. APK 파일 다운로드
2. 설치 시 "이 출처를 허용" 메시지 → **설정** 클릭
3. "이 출처에서 허용" 토글 활성화
4. 뒤로 가기 후 설치 진행

**Android 7.1 이하:**
1. 설정 → 보안
2. "알 수 없는 출처" 허용
3. APK 설치

#### 2. APK 설치

1. 다운로드한 APK 파일 실행
2. "설치" 버튼 클릭
3. 설치 완료 후 "열기" 클릭

#### 3. 업데이트 방법

- 새 버전 APK 다운로드 후 바로 설치
- 기존 데이터는 유지됨
- 앱 삭제하지 않아도 됨

### Firebase App Distribution 사용 (권장)

1. 초대 이메일에서 "Get started" 클릭
2. Google Play에서 "Firebase App Tester" 설치
3. Firebase App Tester 앱 열기
4. Google 계정으로 로그인 (초대받은 이메일)
5. CoWorkfit 앱 찾아서 "Download" 클릭
6. 설치 후 사용

**장점:**
- 새 버전 자동 알림
- 설치 간편
- 앱 관리 편리

### 주의사항

- Google Play 스토어 앱이 아니므로 자동 업데이트 안 됨
- 테스트 버전이므로 버그가 있을 수 있음
- 피드백은 GitHub Issues나 연락처로 전달

---

## 버전 관리 규칙

### 버전 번호 형식

`MAJOR.MINOR.PATCH+BUILD`

예: `0.0.1+1`

- **MAJOR**: 큰 변경사항 (API 변경, 주요 기능 추가)
- **MINOR**: 기능 추가
- **PATCH**: 버그 수정
- **BUILD**: 빌드 번호 (내부 버전)

### 테스트 단계 버전

- `0.0.x`: 초기 개발 및 내부 테스트
- `0.1.x`: 친구들 베타 테스트
- `0.2.x`: 공개 베타
- `1.0.0`: 첫 정식 릴리스

### 버전 증가 시기

- **build**: 매 배포마다 (가장 자주)
- **patch**: 버그 수정
- **minor**: 새 기능 추가
- **major**: 큰 변경사항

---

## 트러블슈팅

### 빌드 실패

```bash
# Flutter 클린
flutter clean
flutter pub get

# Gradle 캐시 클리어
cd android
./gradlew clean
cd ..
```

### Firebase 배포 실패

```bash
# Firebase 로그인 다시
firebase logout
firebase login

# 프로젝트 ID 확인
firebase projects:list
```

### GitHub Actions 실패

1. Actions 탭에서 실패한 워크플로우 확인
2. 로그에서 오류 메시지 확인
3. Secrets 설정 확인
4. 권한 설정 확인

---

## 추가 자료

- [Flutter 공식 문서 - 안드로이드 릴리스 빌드](https://docs.flutter.dev/deployment/android)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GitHub CLI](https://cli.github.com/)
