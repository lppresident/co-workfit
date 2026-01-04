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
│   ├── calibration/         # 보정 계수 시스템
│   ├── craft/               # 제작 시스템 (20종 아이템)
│   ├── iron/                # 쇠 재화 상수
│   ├── log_run/             # 챌린지 시스템 (통나무런)
│   ├── profile/             # 프로필 및 사용자 정보
│   ├── social/              # 소셜 (친구, 공유) ⭐ 참고용
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

### 제작 시스템
- 총 20종 아이템 (머리 8 / 상체 6 / 하체 6)
- 위치: `lib/features/craft/`
- 상세 정보: [CURRENCY_SYSTEM.md](../docs/CURRENCY_SYSTEM.md)

---

## 🏃 챌린지 시스템

| 타입 | 측정 | 재화 | Entity |
|------|------|------|--------|
| `running` | 거리 (km) | 🪵 통나무 | `log_run_challenge_entity.dart` |
| `strengthTraining` | 강도 점수 | 🔩 쇠 | `log_run_challenge_entity.dart` |

위치: `lib/features/log_run/`

---

## 🏥 Health 데이터 연동

| 플랫폼 | API | 특징 |
|--------|-----|------|
| iOS | HealthKit | 앱 내 권한 요청 |
| Android | Health Connect | 별도 앱 설치 필요 |

위치: `lib/features/workout/`
상세: [HEALTH.md](../docs/HEALTH.md)

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

### 2. TabbedMixin (TabController 수동 금지)
```dart
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin { ... }
```

### 3. Common Widgets 사용
- `CommonLoadingWidget` / `CommonErrorWidget` / `CommonEmptyWidget`

### 4. AppLogger 사용 (print 금지)
```dart
AppLogger.info('Tag', 'message');
AppLogger.error('Tag', 'message', error, stackTrace);
```

### 5. AppConstants 사용 (매직 넘버 금지)
```dart
EdgeInsets.all(AppConstants.defaultPadding)
```

### 6. Clean Architecture
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

### 템플릿 사용
- [TEMPLATES.md](.claude/docs/TEMPLATES.md) - 모든 레이어 코드 템플릿 제공

---

## 📝 네이밍 규칙

| 타입 | 파일명 | 클래스명 |
|------|--------|----------|
| Entity | `{name}_entity.dart` | `{Name}Entity` |
| Model | `{name}_model.dart` | `{Name}Model` |
| Repository | `{name}_repository.dart` | `{Name}Repository` |
| UseCase | `{action}_{name}.dart` | `{Action}{Name}` |
| BLoC | `{name}_bloc.dart` | `{Name}Bloc` |
| Page | `{name}_page.dart` | `{Name}Page` |

---

## 🎨 제작 아이템 추가

1. `lib/features/craft/domain/entities/item_recipes.dart`에 ItemEntity 추가
2. (선택) `character_painter.dart`에 픽셀아트 렌더링 추가

템플릿: [TEMPLATES.md](.claude/docs/TEMPLATES.md) 참고

---

## 🔀 Git 규칙

**브랜치**: `feature/{기능명}-{issue번호}`
**PR 베이스**: `develop`
**커밋**: `feat/fix/docs/refactor/chore: 설명 (#issue)`

---

## ❌ 절대 하지 말 것

| 금지 사항 | 대신 사용 |
|----------|----------|
| `Scaffold` 직접 사용 | `BasePage` |
| `print()` / `debugPrint()` | `AppLogger` |
| `initState`에서 BLoC 호출 | `loadInitialData()` |
| 수동 `TabController` | `TabbedMixin` |
| 매직 넘버 (16.0, 8.0) | `AppConstants` |
| 커스텀 로딩/에러 UI | `CommonLoadingWidget`, `CommonErrorWidget` |
| 직접 Firebase 호출 | `DataSource` 레이어 |
| `Either` 없이 에러 처리 | `Either<Failure, T>` |

---

## 📚 참고 코드

| 기능 | 파일 | 특징 |
|------|------|------|
| 탭 페이지 | `features/social/presentation/pages/community_page.dart` | TabbedMixin 사용 |
| 기본 페이지 | `features/log_run/presentation/pages/log_run_page.dart` | BasePage 패턴 |
| BLoC 패턴 | `features/social/presentation/bloc/social_bloc.dart` | 상태관리 예시 |
| 제작 시스템 | `features/craft/presentation/pages/craft_page.dart` | 재화 선택 UI |
| Health 연동 | `features/workout/presentation/bloc/health_bloc.dart` | 플랫폼별 Health 처리 |
| 캐릭터 렌더링 | `features/craft/presentation/widgets/character_painter.dart` | CustomPainter |
| 재화 정산 | `features/wood/domain/usecases/settle_daily_rewards.dart` | 비즈니스 로직 |

---

## 🛠️ 환경 설정

**Android 작업 전**: `source scripts/setup-env.sh`
**의존성**: `flutter pub get`
**코드 생성**: `flutter pub run build_runner build --delete-conflicting-outputs`

---

## 📖 추가 문서

**필요할 때 읽을 것:**
- [TEMPLATES.md](.claude/docs/TEMPLATES.md) - 코드 템플릿
- [CURRENCY_SYSTEM.md](../docs/CURRENCY_SYSTEM.md) - 재화 시스템
- [HEALTH.md](../docs/HEALTH.md) - Health 연동
- [DEPLOYMENT.md](../docs/DEPLOYMENT.md) - 배포
- [APPLE_SIGNIN_SETUP.md](../docs/APPLE_SIGNIN_SETUP.md) - Apple 로그인
- [FASTLANE_MATCH_SETUP.md](../docs/FASTLANE_MATCH_SETUP.md) - iOS 인증서

---

_v5.0 | 2026-01-05_
