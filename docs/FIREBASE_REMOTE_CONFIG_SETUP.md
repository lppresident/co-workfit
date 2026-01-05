# Firebase Remote Config 설정 가이드

## 개요
Co-WorkFit 앱의 버전 관리를 위한 Firebase Remote Config 설정 방법입니다.

## Firebase Console 설정

### 1. Remote Config 접속
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. Co-WorkFit 프로젝트 선택
3. 좌측 메뉴에서 `원격 구성` (Remote Config) 선택

### 2. 파라미터 생성

#### minimum_app_version
앱 진입을 위한 최소 요구 버전을 설정합니다.

| 항목 | 값 |
|------|------|
| **매개변수 키** | `minimum_app_version` |
| **설명** | 앱 사용을 위한 최소 버전 (이 버전보다 낮으면 업데이트 필수) |
| **데이터 유형** | 문자열 |
| **기본값** | `0.0.1` |

**설정 방법:**
1. `매개변수 추가` 버튼 클릭
2. 매개변수 키: `minimum_app_version` 입력
3. 기본값: `0.0.1` 입력 (semantic versioning 형식)
4. 설명 추가 (선택사항)
5. `저장` 클릭

#### current_latest_version (선택사항)
현재 최신 버전을 표시합니다 (정보 제공용).

| 항목 | 값 |
|------|------|
| **매개변수 키** | `current_latest_version` |
| **설명** | 현재 최신 앱 버전 |
| **데이터 유형** | 문자열 |
| **기본값** | `0.0.1` |

### 3. 변경사항 게시
1. 파라미터 추가 후 `변경사항 게시` 버튼 클릭
2. 변경 요약 확인 후 `게시` 클릭

---

## 버전 형식

Semantic Versioning (MAJOR.MINOR.PATCH) 형식을 사용합니다.

### 예시
- `0.0.1` - 초기 버전
- `0.0.2` - 패치 업데이트
- `0.1.0` - 마이너 업데이트
- `1.0.0` - 메이저 업데이트

### 버전 비교 로직
```
1.0.0 > 0.9.9
0.2.0 > 0.1.9
0.0.2 > 0.0.1
```

---

## 사용 시나리오

### 시나리오 1: 긴급 업데이트 강제
사용자가 버전 `0.0.15`를 사용 중이고, 심각한 버그가 발견되어 `0.0.16` 이상으로 업데이트가 필요한 경우:

1. Firebase Console → Remote Config
2. `minimum_app_version` 값을 `0.0.16`으로 변경
3. 변경사항 게시

**결과:**
- `0.0.15` 이하 버전 사용자: 업데이트 다이얼로그 표시, 앱 진입 차단
- `0.0.16` 이상 버전 사용자: 정상 진입

### 시나리오 2: 점진적 롤아웃
특정 버전 이하 사용자에게만 업데이트 요구:

1. `minimum_app_version`을 원하는 버전으로 설정
2. 조건 추가 기능으로 특정 사용자 그룹에만 적용 가능

---

## 앱 동작

### 버전 체크 시점
앱 시작 시 인증 상태 확인 직후 1회만 체크합니다.

### 업데이트 필수 시
1. 다이얼로그 표시:
   ```
   업데이트 필요

   현재 버전: 0.0.15
   최소 요구 버전: 0.0.16

   앱을 사용하려면 최신 버전으로 업데이트해주세요.

   [확인]
   ```
2. 뒤로가기 버튼 비활성화
3. `확인` 버튼 클릭 시 앱 종료

### 업데이트 불필요 시
정상적으로 앱에 진입합니다.

---

## 테스트 방법

### 1. 로컬 테스트
```dart
// lib/core/services/version_check_service.dart
// 테스트용으로 minimum_app_version을 높게 설정
await _remoteConfig.setDefaults({
  'minimum_app_version': '99.99.99', // 현재 버전보다 높게
});
```

### 2. Firebase Console 테스트
1. Remote Config에서 `minimum_app_version`을 현재 앱 버전보다 높게 설정
2. 앱 재시작
3. 업데이트 다이얼로그가 표시되는지 확인
4. 확인 버튼 클릭 시 앱이 종료되는지 확인

### 3. 정상 동작 확인
1. `minimum_app_version`을 현재 앱 버전보다 낮게 설정
2. 앱 재시작
3. 정상적으로 앱에 진입하는지 확인

---

## 트러블슈팅

### Remote Config 값이 반영되지 않는 경우
1. **캐시 문제**: Remote Config는 기본적으로 12시간 캐시를 사용합니다.
   - 해결: `version_check_service.dart`의 `minimumFetchInterval`을 0으로 설정 (개발 중)
   - 프로덕션: 기본값(12시간) 또는 적절한 값으로 변경

2. **네트워크 문제**: 인터넷 연결이 없는 경우 기본값 사용
   - 기본값: `0.0.1` (모든 버전 허용)

3. **Firebase 초기화 실패**: Firebase가 제대로 초기화되지 않은 경우
   - `main.dart`에서 Firebase 초기화 로그 확인
   - `google-services.json` (Android) 또는 `GoogleService-Info.plist` (iOS) 파일 확인

### 앱이 종료되지 않는 경우
- **Android**: `SystemNavigator.pop()` 사용 (백그라운드로 이동)
- **iOS**: `exit(0)` 사용 (앱 종료)
- 플랫폼별 동작 차이가 있을 수 있음

---

## 주의사항

1. **버전 형식**: 반드시 semantic versioning 형식 (`X.Y.Z`) 사용
2. **하위 호환성**: `minimum_app_version`을 높이면 이전 버전 사용자는 앱 사용 불가
3. **점진적 배포**: 급격한 버전 요구 변경은 사용자 경험에 부정적 영향
4. **테스트**: 프로덕션에 배포하기 전 충분한 테스트 필요
5. **롤백**: Remote Config는 버전 히스토리를 제공하므로 이전 값으로 롤백 가능

---

## 참고 문서

- [Firebase Remote Config 공식 문서](https://firebase.google.com/docs/remote-config)
- [Flutter Firebase Remote Config 패키지](https://pub.dev/packages/firebase_remote_config)
- [Semantic Versioning](https://semver.org/)

---

_v1.0 | 2026-01-06_
