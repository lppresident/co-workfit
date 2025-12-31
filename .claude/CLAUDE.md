# Co-WorkFit 개발 규칙

> Claude Code가 자동으로 읽는 AI 개발 규칙입니다.

## 프로젝트 정보

| 항목 | 내용 |
|------|------|
| **앱** | Co-WorkFit - 동료와 함께하는 운동 앱 |
| **스택** | Flutter + BLoC + Clean Architecture + Firebase |
| **상태관리** | flutter_bloc |
| **DI** | GetIt |

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
│   ├── di/injection.dart         # DI 설정
│   ├── presentation/base_page.dart
│   ├── utils/logger.dart         # AppLogger
│   └── widgets/                  # CommonLoadingWidget 등
├── features/
│   ├── auth/                     # 인증
│   ├── craft/                    # 제작 시스템 ⭐ NEW
│   ├── iron/                     # 쇠 재화 상수
│   ├── log_run/                  # 챌린지 (통나무런)
│   ├── profile/                  # 프로필
│   ├── social/                   # 소셜 (참고용 ⭐)
│   ├── wood/                     # 통나무 재화 시스템
│   └── workout/                  # 운동
└── main.dart
```

각 feature 구조:
```
feature/
├── domain/     # Entity, Repository(추상), UseCase
├── data/       # Model, DataSource, Repository(구현)
└── presentation/  # BLoC, Page, Widget
```

---

## 💰 재화 시스템

### 통나무 (Wood) 🪵
- **획득**: 달리기 챌린지 완료
- **용도**: 달리기 장비 제작 (10종)
- **파일**: `lib/features/wood/`

### 쇠 (Iron) 🔩
- **획득**: 헬스 챌린지 완료
- **용도**: 헬스 장비 제작 (10종)
- **파일**: `lib/features/iron/`

### 제작 시스템 🛠️
- **위치**: `lib/features/craft/`
- **아이템**: 머리 / 상체 / 하체 슬롯
- **UI**: 재화 선택 칩으로 통나무/쇠 전환

---

## 🎮 챌린지 시스템

### 챌린지 타입 (LogRunChallengeType)
| 타입 | 설명 | 재화 |
|------|------|------|
| `running` | 달리기 챌린지 | 🪵 통나무 |
| `strengthTraining` | 헬스 챌린지 | 🔩 쇠 |

### 파일 위치
- Entity: `lib/features/log_run/domain/entities/log_run_challenge_entity.dart`
- BLoC: `lib/features/log_run/presentation/bloc/`

---

## ✅ 필수 규칙

### 1. BasePage 사용

```dart
// ✅ 올바른 방법
class MyPage extends BasePage {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BasePageState<MyPage> {
  @override
  void loadInitialData() {
    context.read<MyBloc>().add(LoadEvent());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(title: '제목');
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(...);
  }
}

// ❌ 금지 - Scaffold 직접 사용
class MyPage extends StatefulWidget { ... }
```

### 2. 탭 페이지 = TabbedMixin

```dart
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  @override
  int get tabCount => 3;
  @override
  List<String> get tabLabels => ['탭1', '탭2', '탭3'];
  @override
  List<Widget> get tabViews => [Tab1(), Tab2(), Tab3()];
}
```

### 3. Common Widgets 사용

```dart
// ✅ 사용
CommonLoadingWidget(message: '로딩중...')
CommonErrorWidget(message: error, onRetry: _retry)
CommonEmptyWidget(icon: Icons.inbox, message: '없음')

// ❌ 금지 - 커스텀 로딩/에러 UI
Center(child: CircularProgressIndicator())
```

### 4. AppLogger 사용

```dart
// ✅ 사용
AppLogger.info('MyBloc', 'Loading');
AppLogger.error('MyBloc', 'Failed', error);

// ❌ 금지
print('...');
debugPrint('...');
```

### 5. AppConstants 사용

```dart
// ✅ 사용
EdgeInsets.all(AppConstants.defaultPadding)

// ❌ 금지 - 매직 넘버
EdgeInsets.all(16.0)
```

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

---

## 📝 네이밍 규칙

| 타입 | 파일명 | 클래스명 |
|------|--------|----------|
| Entity | `user_entity.dart` | `UserEntity` |
| Model | `user_model.dart` | `UserModel` |
| Repository | `user_repository.dart` | `UserRepository` |
| UseCase | `get_users.dart` | `GetUsers` |
| BLoC | `user_bloc.dart` | `UserBloc` |
| Page | `user_page.dart` | `UserPage` |

---

## 🎨 제작 아이템 추가 방법

### 1. 아이템 레시피 등록
```dart
// lib/features/craft/domain/entities/item_recipes.dart

const ItemEntity(
  id: 'unique_id',
  name: '아이템명',
  description: '설명',
  category: ItemCategory.clothing,
  clothingSlot: ClothingSlot.head, // head, body, legs
  woodCost: 100,  // 통나무 아이템
  // 또는
  ironCost: 100,  // 쇠 아이템
  iconEmoji: '🎩',
  estimatedDays: 7,
)
```

### 2. 픽셀아트 추가 (선택)
```dart
// lib/features/craft/presentation/widgets/character_painter.dart
// _drawEquippedItems 메서드에 새 아이템 렌더링 추가
```

---

## 🔀 Git 규칙

**브랜치**: `feature/{기능명}-{issue번호}`
```
feature/iron-items-70
```

**커밋**:
```
feat: 친구 관리 UI 구현 (#5)
fix: 버그 수정 (#10)
docs: 문서 업데이트
refactor: 코드 정리
```

---

## ❌ 절대 하지 말 것

1. `Scaffold` 직접 사용 → `BasePage` 사용
2. `print()` 사용 → `AppLogger` 사용
3. `initState`에서 BLoC 호출 → `loadInitialData()` 사용
4. 수동 `TabController` → `TabbedMixin` 사용
5. 매직 넘버 → `AppConstants` 사용
6. 커스텀 로딩/에러 UI → `Common Widgets` 사용

---

## 📚 참고 코드

| 기능 | 파일 | 특징 |
|------|------|------|
| 탭 페이지 | `social/pages/community_page.dart` | TabbedMixin |
| 기본 페이지 | `log_run/pages/log_run_page.dart` | BasePage |
| BLoC 패턴 | `social/bloc/social_bloc.dart` | 상태관리 |
| 제작 시스템 | `craft/presentation/pages/craft_page.dart` | 재화 선택 UI |
| 캐릭터 렌더링 | `craft/presentation/widgets/character_painter.dart` | CustomPainter |

---

## 🛠️ 환경 설정

Android 작업 전 필수:
```bash
source scripts/setup-env.sh
```

---

## 📖 추가 문서

- `docs/APPLE_SIGNIN_SETUP.md` - Apple 로그인 설정
- `docs/DEPLOYMENT.md` - 배포 가이드
- `docs/CURRENCY_SYSTEM.md` - 재화 시스템 설계

---

_v4.0 | 2026-01-01_
