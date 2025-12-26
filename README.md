# Co-WorkFit

동료와 함께하는 운동 성취 공유 앱 - 당신의 완벽한 운동 동반자!

## 🎯 핵심 기능

### 1. 멀티 플랫폼 데이터 통합
- **Garmin Connect**: 전문 운동 트래커 데이터
- **Apple HealthKit**: iPhone/Apple Watch 건강 데이터
- **Google Fit**: Android 기기 피트니스 데이터
- **Samsung Health**: 삼성 헬스 앱 데이터
- **수동 입력**: 직접 운동 기록 추가

### 2. 스마트 캘리브레이션 시스템 ⚖️
각 플랫폼마다 다른 측정 방식을 표준화하여 공정한 비교를 가능하게 합니다:

- **플랫폼별 보정 계수**: 각 플랫폼의 측정 특성 반영
- **다차원 분석**: 칼로리, 심박수, 시간, 거리를 종합적으로 평가
- **운동 타입별 난이도**: 수영, 러닝, 사이클링 등 운동 강도 차이 반영
- **표준화된 점수**: 누구나 공정하게 비교할 수 있는 workload 지수

### 3. 소셜 기능 🤝
- 동료와 성취 공유
- 리더보드 및 순위
- 그룹 챌린지
- 운동 기록 타임라인

### 4. 간편한 로그인 🔐
- **Google Sign-In**: Google 계정으로 간편 로그인
- **Apple Sign-In**: Apple ID로 안전한 로그인 (iOS)
- Firebase Authentication 통합

## 🏗️ 프로젝트 구조

```
lib/
├── core/                    # 공통 기능
│   ├── constants/          # 앱 전역 상수
│   ├── di/                 # 의존성 주입
│   ├── error/              # 에러 정의
│   ├── platform/           # 플랫폼별 코드
│   ├── usecases/           # UseCase 베이스 클래스
│   ├── utils/              # 유틸리티 (Logger 등)
│   └── widgets/            # 공통 위젯 (Loading, Error, Empty)
├── features/                # 기능별 모듈 (Clean Architecture)
│   ├── auth/               # 사용자 인증
│   ├── workout/            # 운동 데이터 관리
│   ├── profile/            # 사용자 프로필
│   └── social/             # 소셜 기능 (친구, 리더보드)
└── shared/                  # 공유 리소스
    └── theme/              # 테마 설정
```

각 feature는 Clean Architecture 원칙을 따릅니다:
- `domain/`: 비즈니스 로직 (엔티티, Repository 인터페이스, UseCases)
- `data/`: 데이터 접근 (모델, DataSources, Repository 구현체)
- `presentation/`: UI 레이어 (BLoC, 페이지, 위젯)

**📚 개발자 가이드**:
- [`UI_STRUCTURE.md`](UI_STRUCTURE.md) - UI 구조 가이드 (BasePage, Mixins, Patterns)
- [`ARCHITECTURE.md`](ARCHITECTURE.md) - 상세한 아키텍처 가이드
- [`CONTRIBUTING.md`](CONTRIBUTING.md) - 기여 가이드 (AI Assistant용)
- [`AI_QUICK_REFERENCE.md`](AI_QUICK_REFERENCE.md) - 빠른 참조 가이드

## 🛠️ 기술 스택

### 아키텍처 & 상태 관리
- **Clean Architecture**: 계층 분리 및 의존성 역전
- **BLoC Pattern**: 상태 관리 (flutter_bloc)
- **Dependency Injection**: GetIt

### 헬스 플랫폼 통합
- **Health Package**: 멀티 플랫폼 헬스 데이터 통합
- **Firebase**: 인증 및 Firestore

### UI
- **Material 3**: 최신 디자인 시스템

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.10.0
- Firebase 프로젝트 설정

### 설치

```bash
# 의존성 설치
flutter pub get

# Firebase 설정
flutterfire configure

# 앱 실행
flutter run
```

### 인증 설정 (Apple Sign-In)

Apple Sign-In을 사용하려면 추가 설정이 필요합니다:

```bash
# Apple Sign-In 설정 확인 스크립트 실행
./scripts/check_apple_signin_setup.sh
```

**필수 단계**:
1. **Apple Developer Program 가입** ($99/년)
2. **Apple Developer Portal** 설정
   - App ID에 Sign in with Apple capability 활성화
3. **Firebase Console** 설정
   - Authentication > Sign-in method > Apple 활성화

자세한 설정 방법은 [`docs/APPLE_SIGNIN_SETUP.md`](docs/APPLE_SIGNIN_SETUP.md)를 참고하세요.

### Android 개발 환경 설정

Android 관련 작업(SHA-1 확인, Gradle 빌드 등)을 수행하기 전에 환경 설정이 필요합니다:

```bash
# 환경 변수 설정 (매번 새 터미널 세션마다 실행)
source scripts/setup-env.sh
```

이 스크립트는 자동으로 Java 경로를 설정하고 Android 개발 도구를 사용할 수 있게 합니다.

### 개발

```bash
# 코드 분석
flutter analyze

# 테스트 실행
flutter test

# 빌드
flutter build ios
flutter build apk
```

### AI Assistant 개발 가이드

이 프로젝트는 AI Assistant와 협업하기 위해 최적화되어 있습니다.

**Claude Code를 사용하는 경우:**
- Claude Code는 자동으로 [`.claud`](.claud) 파일을 읽어들입니다
- 모든 개발 규칙과 패턴이 이 파일에 통합되어 있습니다

**새 기능을 추가하거나 코드를 수정할 때 참고 문서:**

1. **개발 규칙**: [`.claud`](.claud) - AI 개발 규칙 (Claude Code 자동 참조)
2. **UI 구조**: [`UI_STRUCTURE.md`](UI_STRUCTURE.md) - 페이지/위젯 패턴
3. **빠른 템플릿**: [`AI_QUICK_REFERENCE.md`](AI_QUICK_REFERENCE.md) - 코드 스니펫
4. **아키텍처**: [`ARCHITECTURE.md`](ARCHITECTURE.md) - Clean Architecture 패턴
5. **기여 가이드**: [`CONTRIBUTING.md`](CONTRIBUTING.md) - 전체 프로세스

**기본 워크플로우**:
```
1. Domain Layer  → Entity, Repository, UseCases 작성
2. Data Layer    → Model, DataSource, Repository 구현
3. Presentation  → Event, State, BLoC 작성
4. UI Layer      → BasePage + Mixins 사용 (필수!)
5. DI Setup      → injection.dart 및 main.dart 등록
6. Quality Check → flutter analyze (0 errors)
```

## 📊 캘리브레이션 알고리즘

Co-WorkFit의 핵심은 공정한 운동 평가입니다. 각 플랫폼의 데이터를 다음과 같이 처리합니다:

### 1. 정규화 (0-100 스케일)
- **칼로리**: 800kcal = 100점
- **심박수**: 안정시(60) ~ 고강도(160) 범위
- **운동 시간**: 90분 = 100점
- **거리**: 운동 타입별 기준 (러닝 10km, 사이클링 30km 등)

### 2. 가중치 적용
```dart
workload = (칼로리 × 0.35) + (심박수 × 0.30) +
           (시간 × 0.20) + (거리 × 0.15)
```

### 3. 플랫폼 보정
- Garmin: 0.95 (칼로리 높게 측정 경향)
- Apple Health: 1.0 (기준)
- Google Fit: 1.05 (보수적 측정)
- Samsung Health: 1.0
- 수동 입력: 0.90 (보수적 평가)

### 4. 운동 타입 난이도
- 수영: 1.2 (높은 난이도)
- 웨이트 트레이닝: 1.1
- 러닝: 1.0 (기준)
- 사이클링: 0.9
- 걷기: 0.7

## 📋 개발 현황

자세한 개발 진행 상황 및 로드맵은 [GitHub Issue #3](https://github.com/lppresident/co-workfit/issues/3)에서 확인하세요.

## 📝 라이선스

Private Project

---

**Co-WorkFit** - 함께 운동하고, 함께 성장하세요! 💪
