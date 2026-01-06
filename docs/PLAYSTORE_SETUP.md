# Play Store 배포 설정 가이드

## 1. Play Console 초기 설정

### 1.1 Play Console 계정 등록
1. [Google Play Console](https://play.google.com/console)에 접속
2. 25달러 결제하고 개발자 계정 등록
3. 앱 생성 (이미 존재하는 경우 스킵)

### 1.2 첫 릴리스 수동 업로드 (필수)
Play Store API를 사용하려면 **최소 1번은 수동으로 APK/AAB를 업로드**해야 합니다.

1. Flutter로 AAB 빌드:
   ```bash
   flutter build appbundle --release
   ```

2. Play Console에서 `내부 테스트` 트랙 선택
3. `build/app/outputs/bundle/release/app-release.aab` 파일 업로드
4. 릴리스 노트 작성 후 검토 → 출시

## 2. Google Cloud 서비스 계정 생성

### 2.1 서비스 계정 만들기
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 (Play Console과 연결된 프로젝트)
3. `IAM 및 관리자` → `서비스 계정` 메뉴
4. `서비스 계정 만들기` 클릭
   - 이름: `github-actions-play-store`
   - 역할: 없음 (나중에 Play Console에서 설정)
5. 서비스 계정 생성 완료

### 2.2 JSON 키 다운로드
1. 생성한 서비스 계정 클릭
2. `키` 탭 → `키 추가` → `새 키 만들기`
3. 키 유형: `JSON` 선택
4. 생성 버튼 클릭 → JSON 파일 다운로드 (안전한 곳에 보관)

## 3. Play Console에서 API 액세스 설정

### 3.1 서비스 계정 연결
1. [Play Console](https://play.google.com/console) 접속
2. `설정` → `API 액세스` 메뉴
3. `Google Cloud 프로젝트 연결` (이미 연결된 경우 스킵)
4. `서비스 계정` 섹션에서 방금 만든 계정 확인
5. `액세스 권한 부여` 클릭

### 3.2 권한 설정
서비스 계정에 다음 권한 부여:
- ✅ 앱 액세스: `Co-WorkFit` 앱 선택
- ✅ 계정 권한:
  - `릴리스 만들기 및 수정` (필수)
  - `프로덕션 릴리스 관리` (선택)
  - `내부 앱 공유 사용자 관리` (선택)

저장 후 완료.

## 4. GitHub Secrets 설정

### 4.1 필요한 Secrets
GitHub 저장소의 `Settings` → `Secrets and variables` → `Actions`에 추가:

| Secret 이름 | 설명 | 값 |
|-------------|------|-----|
| `PLAY_STORE_CONFIG_JSON` | Play Store 서비스 계정 JSON 키 전체 내용 | 2.2에서 다운로드한 JSON 파일 내용 복사 |
| `RELEASE_KEYSTORE_BASE64` | (기존) Release keystore 파일 | Base64로 인코딩된 keystore |
| `RELEASE_KEYSTORE_PASSWORD` | (기존) Keystore 비밀번호 | - |
| `RELEASE_KEY_ALIAS` | (기존) Key alias | - |
| `RELEASE_KEY_PASSWORD` | (기존) Key 비밀번호 | - |

### 4.2 JSON 키 설정 방법
터미널에서 JSON 파일 내용 복사:
```bash
cat ~/Downloads/your-service-account-key.json
```

출력된 JSON 전체를 복사하여 `PLAY_STORE_CONFIG_JSON`에 붙여넣기.

## 5. 배포 방법

### 5.1 GitHub Actions로 배포
GitHub 저장소의 `Actions` 탭에서 `Deploy` 워크플로우 실행:

| 옵션 | 설명 |
|------|------|
| **배포 대상** | |
| `android-playstore` | Play Store만 배포 (내부 테스트 트랙) |
| `android` | Firebase + Play Store 둘 다 배포 |
| `all` | Android (Firebase + Play Store) + iOS |
| **버전 증가** | `build`, `patch`, `minor`, `major` |
| **릴리스 노트** | 사용자에게 표시될 변경사항 |

### 5.2 배포 후 확인
1. [Play Console](https://play.google.com/console) → 앱 선택
2. `테스트` → `내부 테스트` 메뉴
3. 새 버전이 업로드되었는지 확인
4. 테스터에게 공유 (내부 테스트 링크)

## 6. 트랙 변경 (선택)

기본적으로 `internal` 트랙에 배포됩니다. 다른 트랙으로 변경하려면:

`android/app/build.gradle.kts` 파일 수정:
```kotlin
play {
    track.set("internal")  // internal, alpha, beta, production
}
```

또는 GitHub Actions에서 동적으로 변경 가능 (고급).

## 7. 문제 해결

### 7.1 "The caller does not have permission" 에러
- Play Console에서 서비스 계정 권한 재확인
- `릴리스 만들기 및 수정` 권한이 있는지 확인

### 7.2 "Package not found" 에러
- Play Console에서 최소 1번은 수동으로 AAB를 업로드해야 함 (1.2 참고)
- `applicationId`가 Play Console의 앱 ID와 일치하는지 확인

### 7.3 "Version code has already been used" 에러
- 버전 번호가 이전보다 높은지 확인
- `pubspec.yaml`의 `version: x.x.x+BUILD_NUMBER`에서 BUILD_NUMBER를 증가

## 8. 참고 링크

- [Google Play Console](https://play.google.com/console)
- [Gradle Play Publisher 문서](https://github.com/Triple-T/gradle-play-publisher)
- [Flutter 공식 배포 가이드](https://docs.flutter.dev/deployment/android)
