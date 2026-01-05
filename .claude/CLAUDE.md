# Co-WorkFit 개발 규칙

> Claude Code가 자동으로 읽는 AI 개발 규칙입니다.

## 프로젝트 정보

| 항목 | 내용 |
|------|------|
| **앱** | Co-WorkFit - 동료와 함께하는 운동 성취 공유 앱 |
| **스택** | Flutter 3.10+ + BLoC + Clean Architecture + Firebase |
| **상태관리** | flutter_bloc (^8.1.6) |
| **DI** | GetIt (^8.0.2) + Injectable (^2.5.0) |
| **Backend** | Firebase (Auth, Firestore) |
| **Health** | health package (^13.2.1) - HealthKit/Health Connect |
| **현재 버전** | 0.0.1+19 |

## 🎯 3줄 핵심 규칙

```
1. BasePage 사용 (Scaffold 직접 사용 금지)
2. 기존 코드 패턴 따르기 (lib/features/social/ 참고)
3. print 금지 → AppLogger 사용
```

---

## 📁 프로젝트 구조

```
lib/
├── core/
│   ├── config/              # 앱 설정
│   ├── constants/           # 상수 (AppConstants)
│   ├── di/                  # DI 설정 (injection.dart)
│   ├── error/               # 에러 처리
│   ├── platform/            # 플랫폼별 코드
│   ├── presentation/        # BasePage, TabbedMixin
│   ├── services/            # 공통 서비스
│   ├── usecases/            # UseCase 추상 클래스
│   ├── utils/               # AppLogger, 유틸리티
│   └── widgets/             # CommonLoadingWidget 등
├── features/
│   ├── auth/                # 인증 (Google, Apple Sign-In)
│   ├── craft/               # 제작 시스템 (30종 아이템)
│   ├── currency/            # 재화 공통 (wood, iron, soil)
│   ├── iron/                # 쇠 재화 상수
│   ├── log_run/             # 챌린지 시스템
│   ├── profile/             # 프로필 및 사용자 정보
│   ├── social/              # 소셜 (친구, 프로필) ⭐ 참고용
│   ├── soil/                # 흙 재화 상수
│   ├── wood/                # 통나무 재화 시스템
│   └── workout/             # 운동 기록 (HealthKit/Health Connect)
└── shared/
    └── theme/               # 앱 테마

각 feature 구조:
feature/
├── domain/      # Entity, Repository(추상), UseCase
├── data/        # Model, DataSource, Repository(구현)
└── presentation/ # BLoC, Page, Widget
```

---

## 💰 재화 시스템

| 재화 | 획득 방법 | 용도 | 위치 |
|------|----------|------|------|
| 🪵 통나무 | 달리기 챌린지 | 달리기 장비 10종 | `lib/features/wood/` |
| 🔩 쇠 | 헬스 챌린지 | 헬스 장비 10종 | `lib/features/iron/` |
| 🌱 흙 | 명상/요가 챌린지 | 명상 장비 6종 | `lib/features/soil/` |

상세: [CURRENCY_SYSTEM.md](../docs/CURRENCY_SYSTEM.md)

---

## 🏃 챌린지 시스템

| 타입 | 측정 | 재화 |
|------|------|------|
| `running` | 거리 (km) | 🪵 통나무 |
| `strengthTraining` | 강도 점수 | 🔩 쇠 |
| `mindfulness` | 시간 (분) | 🌱 흙 |

위치: `lib/features/log_run/`

---

## 🗄️ Firestore 구조

| 컬렉션 | 설명 |
|--------|------|
| `/users/{userId}` | 사용자 프로필, 재화, 장착 아이템 |
| `/workouts/{workoutId}` | 운동 기록 (top-level, userId 필드로 소유자 구분) |
| `/challenges/{challengeId}` | 챌린지 정보 |
| `/challenges/{id}/contributions/{id}` | 챌린지 기여 기록 |

---

## ✅ 필수 규칙

### 1. BasePage 사용 (Scaffold 금지)
```dart
class MyPage extends BasePage { ... }
class _MyPageState extends BasePageState<MyPage> {
  @override void loadInitialData() { /* BLoC 이벤트 */ }
  @override PreferredSizeWidget buildAppBar(BuildContext context) { ... }
  @override Widget buildBody(BuildContext context) { ... }
}
```

### 2. Common Widgets 사용
- `CommonLoadingWidget` / `CommonErrorWidget` / `CommonEmptyWidget`

### 3. AppLogger 사용 (print 금지)
```dart
AppLogger.info('Tag', 'message');
AppLogger.error('Tag', 'message', error, stackTrace);
```

### 4. Clean Architecture
- Domain: Entity (Equatable) / Repository (추상) / UseCase
- Data: Model / DataSource / Repository Impl (Either<Failure, T>)
- Presentation: BLoC / Page (BasePage) / Widget

---

## 🏗️ 새 기능 추가 순서

```
1. Domain  → Entity, Repository(추상), UseCase
2. Data    → Model, DataSource, Repository(구현)
3. BLoC    → Event, State, Bloc
4. UI      → BasePage + StandardAppBar
5. DI      → injection.dart 등록 → main.dart Provider 추가
6. 확인    → flutter analyze (0 errors)
```

템플릿: [TEMPLATES.md](docs/TEMPLATES.md)

---

## ❌ 절대 하지 말 것

| 금지 사항 | 대신 사용 |
|----------|----------|
| `Scaffold` 직접 사용 | `BasePage` |
| `print()` / `debugPrint()` | `AppLogger` |
| `initState`에서 BLoC 호출 | `loadInitialData()` |
| 매직 넘버 (16.0, 8.0) | `AppConstants` |
| 직접 Firebase 호출 | `DataSource` 레이어 |
| `Either` 없이 에러 처리 | `Either<Failure, T>` |

---

## 📚 참고 코드

| 기능 | 파일 |
|------|------|
| 탭 페이지 | `features/social/presentation/pages/community_page.dart` |
| 기본 페이지 | `features/log_run/presentation/pages/challenge_page.dart` |
| BLoC 패턴 | `features/social/presentation/bloc/social_bloc.dart` |
| 프로필 페이지 | `features/social/presentation/pages/profile_page.dart` |
| Health 연동 | `features/workout/presentation/bloc/health_bloc.dart` |
| 캐릭터 렌더링 | `features/craft/presentation/widgets/character_painter.dart` |

---

## 🛠️ 환경 설정

```bash
source scripts/setup-env.sh        # Android 작업 전
flutter pub get                    # 의존성 설치
flutter pub run build_runner build --delete-conflicting-outputs  # 코드 생성
```

---

## 📖 추가 문서

- [TEMPLATES.md](docs/TEMPLATES.md) - 코드 템플릿
- [CURRENCY_SYSTEM.md](../docs/CURRENCY_SYSTEM.md) - 재화 시스템
- [HEALTH.md](../docs/HEALTH.md) - Health 연동

---

_v6.0 | 2026-01-05_
