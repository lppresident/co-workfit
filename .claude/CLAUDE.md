# Co-WorkFit AI Development Rules

> **이 파일은 Claude Code가 자동으로 읽어들이는 AI 개발 규칙입니다.**
>
> 모든 AI Assistant는 코딩 전에 반드시 이 파일과 문서들을 확인해야 합니다.

---

## 📋 목차 (빠른 탐색)

1. [프로젝트 개요](#-프로젝트-개요)
2. [문서 우선 순위](#-문서-우선-순위)
3. [핵심 원칙](#-핵심-원칙)
4. [UI 구조 규칙](#-ui-구조-규칙-필수)
5. [Clean Architecture 규칙](#️-clean-architecture-규칙)
6. [Naming Conventions](#-naming-conventions-절대-규칙)
7. [Git 워크플로우](#-git-워크플로우)
8. [개발 체크리스트](#-개발-체크리스트)
9. [빠른 참조](#-빠른-참조)
10. [자주 하는 실수](#-자주-하는-실수)

---

## 🚀 프로젝트 개요

- **이름**: Co-WorkFit (Flutter 기반 운동 관리 앱)
- **아키텍처**: Clean Architecture + BLoC Pattern
- **상태 관리**: flutter_bloc
- **DI**: GetIt
- **백엔드**: Firebase (Auth, Firestore)
- **현재 상태**: Phase 4 완료, Phase 5 준비 중

### 프로젝트 구조
```
lib/
├── core/
│   ├── di/injection.dart              # GetIt DI 설정
│   ├── error/failures.dart            # Failure 클래스들
│   ├── usecases/usecase.dart          # UseCase 베이스
│   ├── utils/logger.dart              # AppLogger
│   ├── constants/app_constants.dart   # 상수
│   ├── widgets/                       # Common 위젯
│   └── presentation/
│       ├── base_page.dart             # BasePage
│       ├── mixins/                    # TabbedMixin, RefreshableMixin 등
│       └── widgets/                   # StandardAppBar 등
├── features/
│   ├── workout/                       # 운동 데이터
│   ├── calibration/                   # 캘리브레이션
│   ├── auth/                          # 인증
│   ├── social/                        # 소셜 (친구, 리더보드)
│   └── (log_run, ghost_run 예정)     # Phase 5
└── main.dart
```

---

## 📚 문서 우선 순위

코딩하기 전에 **반드시** 다음 순서로 문서를 확인하세요:

### 1단계: UI 구조 확인 (가장 먼저!)
- **`.claude/docs/UI_STRUCTURE.md`** ← 페이지 만들 때 필수

### 2단계: 빠른 템플릿
- **`.claude/docs/AI_QUICK_REFERENCE.md`** ← 코드 템플릿 복사

### 3단계: 상세 가이드
- **`.claude/docs/CONTRIBUTING.md`** ← 전체 기여 가이드
- **`.claude/docs/ARCHITECTURE.md`** ← Clean Architecture 패턴

### 4단계: 기존 코드 참고
- `lib/features/social/` - 친구, 리더보드 참고용
- `lib/features/auth/` - 인증 참고용
- `lib/features/workout/` - 운동 데이터 참고용

---

## 🔧 개발 환경 설정

### Android 개발 환경

Android 관련 작업(SHA-1 확인, Gradle 빌드, 서명 등)을 수행하기 전에 **반드시** 환경 설정이 필요합니다:

```bash
# 환경 변수 설정 (매번 새 터미널 세션마다 실행)
source scripts/setup-env.sh
```

이 스크립트는:
- Java 경로를 자동 설정 (`JAVA_HOME`)
- Android 개발 도구 경로를 PATH에 추가
- 설정 완료 여부를 확인 및 출력

**워크트리를 사용하는 경우 필수!**
- 매번 새 워크트리가 생성될 때마다 환경변수가 초기화됨
- `source scripts/setup-env.sh` 실행 없이 `keytool`, `./gradlew` 등 실행 시 에러 발생

**관련 파일:**
- `scripts/setup-env.sh` - 환경 설정 스크립트
- `.envrc` - 환경 변수 정의 (git ignored)

---

## 🎯 핵심 원칙

### 1. 문서를 먼저 확인하라
- 추측하지 말고, 문서를 읽을 것
- 비슷한 기능이 있는지 먼저 찾을 것
- 새로운 패턴을 만들지 말 것

### 2. 일관성이 최우선
- 기존 코드 스타일을 따를 것
- 같은 패턴을 반복할 것
- 의심스러우면 문서 확인

### 3. 기존 코드를 참고하라
- `lib/features/social/` - 가장 최신, 가장 잘 정리됨
- 같은 구조를 그대로 따를 것
- BasePage + Mixins 패턴 필수

### 4. 과도한 엔지니어링 금지
- 요청받지 않은 기능 추가 금지
- 필요 이상의 리팩토링 금지
- 간단하고 명확하게 작성

---

## 📐 UI 구조 규칙 (필수!)

### ✅ MUST DO (반드시 해야 함)

#### 1️⃣ 모든 페이지는 BasePage 사용

```dart
// ✅ CORRECT
class MyPage extends BasePage {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BasePageState<MyPage> {
  @override
  void loadInitialData() {
    // 여기서 BLoC 이벤트 발생
    context.read<MyBloc>().add(LoadEvent());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(title: 'My Page');
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        // UI 구현
      },
    );
  }
}

// ❌ WRONG - 직접 StatefulWidget 사용 금지
class MyPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(...); // 절대 금지!
  }
}
```

#### 2️⃣ StandardAppBar 사용

```dart
// ✅ CORRECT
@override
PreferredSizeWidget buildAppBar(BuildContext context) {
  return StandardAppBar(
    title: '페이지 제목',
    actions: [
      AppBarActions.refresh(() => _refresh()),
      AppBarActions.filter(() => _filter()),
    ],
  );
}

// ❌ WRONG - 직접 AppBar 만들기 금지
AppBar(
  title: const Text('페이지 제목'),
  actions: [IconButton(...)], // 금지!
)
```

#### 3️⃣ loadInitialData() 사용 (initState 금지!)

```dart
// ✅ CORRECT - loadInitialData()에서 초기화
@override
void loadInitialData() {
  final authState = context.read<AuthBloc>().state;
  if (authState is Authenticated) {
    context.read<MyBloc>().add(LoadEvent());
  }
}

// ❌ WRONG - initState에서 BLoC 호출 금지 (BuildContext 위험!)
@override
void initState() {
  super.initState();
  context.read<MyBloc>().add(LoadEvent()); // 위험함! 절대 금지!
}
```

#### 4️⃣ Mixin 사용

**탭이 있는 페이지 (TabbedMixin):**

```dart
// ✅ CORRECT
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {

  @override
  int get tabCount => 3;

  @override
  List<String> get tabLabels => ['탭1', '탭2', '탭3'];

  @override
  List<Widget> get tabViews => [Tab1(), Tab2(), Tab3()];

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'My Page',
      bottom: buildTabBar(), // TabbedMixin 제공
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildTabBarView(); // TabbedMixin 제공
  }
}

// ❌ WRONG - 수동 TabController 관리 금지
late TabController _tabController;
@override
void initState() {
  _tabController = TabController(...); // 금지!
}
```

**Pull-to-refresh가 필요한 페이지 (RefreshableMixin):**

```dart
// ✅ CORRECT
class _MyPageState extends BasePageState<MyPage> with RefreshableMixin {

  @override
  Future<void> onRefresh() async {
    context.read<MyBloc>().add(RefreshEvent());
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildRefreshableContent(
      child: ListView(...),
    );
  }
}

// ❌ WRONG - 직접 RefreshIndicator 만들기
RefreshIndicator(
  onRefresh: () async { ... }, // 금지! RefreshableMixin 사용
  child: ...,
)
```

#### 5️⃣ Common Widgets 사용

```dart
// ✅ CORRECT - Common Widgets 사용
if (state is Loading) {
  return const CommonLoadingWidget(message: 'Loading...');
}

if (state is Error) {
  return CommonErrorWidget(
    message: state.message,
    onRetry: () => loadInitialData(),
  );
}

if (state is Loaded && state.items.isEmpty) {
  return const CommonEmptyWidget(
    icon: Icons.inbox,
    message: 'No data',
  );
}

// ❌ WRONG - 커스텀 UI 만들기 금지
Center(
  child: Column(
    children: [
      const Icon(Icons.error),
      Text(error.message),
      ElevatedButton(...),
    ],
  ),
) // 절대 금지! CommonErrorWidget 사용할 것
```

#### 6️⃣ AppLogger 사용 (print 금지!)

```dart
// ✅ CORRECT
AppLogger.info('MyBloc', 'Loading data');
AppLogger.error('MyBloc', 'Failed to load', error, stackTrace);
AppLogger.debug('MyBloc', 'Debug info');
AppLogger.performance('MyBloc', 'Load data', durationMs);

// ❌ WRONG - print/debugPrint 절대 사용 금지!
print('Loading data');        // 절대 금지!
debugPrint('Loading data');   // 절대 금지!
```

#### 7️⃣ AppConstants 사용 (매직 넘버 금지)

```dart
// ✅ CORRECT
padding: EdgeInsets.all(AppConstants.defaultPadding),
Color(AppConstants.goldColor),
timeout: Duration(seconds: AppConstants.defaultTimeoutSeconds),

// ❌ WRONG - 매직 넘버 사용 금지
padding: EdgeInsets.all(16.0),     // 금지!
Color(0xFFFFD700),                 // 금지!
timeout: Duration(seconds: 10),    // 금지!
```

---

## 🏗️ Clean Architecture 규칙

### Layer 순서 (반드시 지킬 것)

새 기능 추가 시 **반드시 이 순서대로** 작업:

#### 1. Domain Layer (먼저 작성)

```
lib/features/{feature}/domain/
├── entities/
│   └── {name}_entity.dart        # Entity 정의 (비즈니스 객체)
├── repositories/
│   └── {name}_repository.dart    # Repository 인터페이스 (추상)
└── usecases/
    └── {action}_{object}.dart    # UseCase (get_users.dart)
```

**예시:**
```dart
// 1. Entity
abstract class UserEntity extends Equatable {
  final String id;
  final String email;
  const UserEntity({required this.id, required this.email});
}

// 2. Repository Interface
abstract class UserRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers();
}

// 3. UseCase
class GetUsers extends UseCase<List<UserEntity>, NoParams> {
  final UserRepository repository;
  GetUsers(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) {
    return repository.getUsers();
  }
}
```

#### 2. Data Layer (두 번째)

```
lib/features/{feature}/data/
├── models/
│   └── {name}_model.dart         # Model (extends Entity, fromJson/toJson)
├── datasources/
│   └── {source}_{name}_datasource.dart  # DataSource (Firestore, API)
└── repositories/
    └── {name}_repository_impl.dart      # Repository 구현체
```

**예시:**
```dart
// 1. Model
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], email: json['email']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }
}

// 2. DataSource
abstract class FirestoreUserDataSource {
  Future<List<UserModel>> getUsers();
}

// 3. Repository Implementation
class UserRepositoryImpl implements UserRepository {
  final FirestoreUserDataSource dataSource;
  UserRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers() async {
    try {
      final users = await dataSource.getUsers();
      return Right(users);
    } catch (e) {
      return Left(e.toFailure());
    }
  }
}
```

#### 3. Presentation Layer (세 번째)

```
lib/features/{feature}/presentation/
├── bloc/
│   ├── {name}_event.dart         # Event 정의
│   ├── {name}_state.dart         # State 정의
│   └── {name}_bloc.dart          # BLoC 로직
├── pages/
│   └── {name}_page.dart          # BasePage 사용 (필수!)
└── widgets/
    └── {name}_widget.dart        # 재사용 위젯
```

**예시:**
```dart
// 1. Event
abstract class UserEvent extends Equatable {}
class LoadUsers extends UserEvent {}

// 2. State
abstract class UserState extends Equatable {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final List<UserEntity> users;
  UserLoaded(this.users);
}
class UserError extends UserState {
  final String message;
  UserError(this.message);
}

// 3. BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsers getUsers;

  UserBloc({required this.getUsers}) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await getUsers(NoParams());
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (users) => emit(UserLoaded(users)),
    );
  }
}

// 4. Page (BasePage 사용!)
class UserPage extends BasePage {
  const UserPage({super.key});
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends BasePageState<UserPage> {
  @override
  void loadInitialData() {
    context.read<UserBloc>().add(LoadUsers());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(title: 'Users');
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoading) return const CommonLoadingWidget();
        if (state is UserError) return CommonErrorWidget(message: state.message, onRetry: loadInitialData);
        if (state is UserLoaded) {
          if (state.users.isEmpty) return const CommonEmptyWidget(message: 'No users');
          return ListView.builder(...);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

#### 4. Dependency Injection (통합)

```dart
// lib/core/di/injection.dart
void init() {
  // DataSource
  getIt.registerLazySingleton<FirestoreUserDataSource>(
    () => FirestoreUserDataSourceImpl(firestore: getIt()),
  );

  // Repository
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(dataSource: getIt()),
  );

  // UseCase
  getIt.registerLazySingleton(() => GetUsers(getIt()));

  // BLoC
  getIt.registerFactory(() => UserBloc(getUsers: getIt()));
}

// lib/main.dart
BlocProvider(
  create: (context) => getIt<UserBloc>(),
  child: UserPage(),
)
```

### ❌ 절대 하지 말 것

1. **Domain이 Data나 Presentation에 의존** - 절대 금지!
2. **UI에서 직접 DataSource 호출** - 반드시 BLoC 거칠 것
3. **Repository 건너뛰기** - 항상 Repository 통해 데이터 접근
4. **UseCase 없이 Repository 직접 호출** - BLoC에서 UseCase 사용
5. **initState에서 BLoC 호출** - loadInitialData() 사용할 것

---

## 📝 Naming Conventions (절대 규칙)

### File Naming

| Type | Format | Example |
|------|--------|---------|
| Entity | `{name}_entity.dart` | `user_entity.dart` |
| Model | `{name}_model.dart` | `user_model.dart` |
| Repository Interface | `{name}_repository.dart` | `user_repository.dart` |
| Repository Impl | `{name}_repository_impl.dart` | `user_repository_impl.dart` |
| UseCase | `{action}_{object}.dart` | `get_users.dart` |
| DataSource | `{source}_{name}_datasource.dart` | `firestore_user_datasource.dart` |
| BLoC | `{name}_bloc.dart` | `user_bloc.dart` |
| Event | `{name}_event.dart` | `user_event.dart` |
| State | `{name}_state.dart` | `user_state.dart` |
| Page | `{name}_page.dart` | `user_page.dart` |
| Widget | `{name}_widget.dart` | `user_card_widget.dart` |
| Tab | `{name}_tab.dart` | `user_list_tab.dart` |

### Class Naming

| Type | Format | Example |
|------|--------|---------|
| Entity | `{Name}Entity` | `UserEntity` |
| Model | `{Name}Model` | `UserModel` |
| Repository | `{Name}Repository` | `UserRepository` |
| UseCase | `{Action}{Object}` | `GetUsers`, `CreateUser` |
| Event | `{Action}{Object}` | `LoadUsers`, `CreateUser` |
| State | `{Name}{Status}` | `UserLoading`, `UserLoaded` |
| BLoC | `{Name}Bloc` | `UserBloc` |
| Page | `{Name}Page` | `UserPage` |

---

## 🔀 Git 워크플로우

### 1 Issue = 1 Branch = 1 PR 원칙

#### 1️⃣ Issue 생성

**제목 형식:**
```
[Phase X] 기능명
```

**예시:**
```
[Phase 5] 통나무런 기능 구현
[Testing] Social Features 테스트 작성
```

**내용:**
- 작업 내용 명시
- 체크리스트 포함
- 관련 파일 경로 명시

#### 2️⃣ Branch 명명

**형식:**
```
feature/{기능명}-{issue번호}
```

**예시:**
```
feature/log-run-22
feature/social-tests-21
```

#### 3️⃣ Commit 규칙

**포맷:**
```
type: 간단한 설명 (#issue번호)
```

**Type:**
- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `refactor`: 리팩토링
- `style`: 코드 포맷팅
- `test`: 테스트 추가
- `chore`: 빌드, 설정 변경

**예시:**
```
feat: 친구 관리 UI 구현 (#5)
fix: 리더보드 정렬 버그 수정 (#10)
docs: API 문서 업데이트 (#12)
```

#### 4️⃣ Pull Request

**제목:** Issue 제목과 동일

**본문:**
```markdown
## 변경 사항
- 구현한 내용 요약

## 테스트
- [ ] flutter analyze (0 errors)
- [ ] 빌드 테스트 통과

Closes #이슈번호
```

---

## 🔍 개발 체크리스트

새 기능 추가 시 **반드시** 이 순서대로:

- [ ] **1. 문서 확인**
  - [ ] `UI_STRUCTURE.md` 읽기 (페이지 만들 때)
  - [ ] `AI_QUICK_REFERENCE.md` 템플릿 확인
  - [ ] `CONTRIBUTING.md` 프로세스 확인

- [ ] **2. 기존 코드 참고**
  - [ ] `lib/features/social/` 구조 확인
  - [ ] 비슷한 기능 찾기
  - [ ] 같은 패턴 따르기

- [ ] **3. Domain Layer 작성**
  - [ ] Entity 정의
  - [ ] Repository 인터페이스
  - [ ] UseCases 작성

- [ ] **4. Data Layer 작성**
  - [ ] Model (fromJson/toJson)
  - [ ] DataSource (Firestore)
  - [ ] Repository 구현체

- [ ] **5. Presentation Layer 작성**
  - [ ] Event 정의
  - [ ] State 정의
  - [ ] BLoC 로직

- [ ] **6. UI 작성**
  - [ ] **BasePage 사용 (필수!)**
  - [ ] Mixins 활용 (TabbedMixin, RefreshableMixin 등)
  - [ ] StandardAppBar 사용
  - [ ] Common Widgets 사용

- [ ] **7. DI 설정**
  - [ ] `lib/core/di/injection.dart` 등록
  - [ ] `lib/main.dart` BlocProvider 추가

- [ ] **8. 품질 확인**
  - [ ] `flutter analyze` 실행 (0 errors)
  - [ ] Common Widgets 사용 확인
  - [ ] AppLogger 사용 확인 (print 없는지)
  - [ ] AppConstants 사용 확인 (매직 넘버 없는지)

---

## ⚡ 빠른 참조

### 페이지 타입별 템플릿

| 필요한 기능 | Base | Mixins | 참고 파일 |
|------------|------|--------|----------|
| 단순 페이지 | `BasePage` | - | `UI_STRUCTURE.md` Simple Page |
| 탭 페이지 (2-4개) | `BasePage` | `TabbedMixin` | `friends_page.dart` (4탭) |
| 새로고침 목록 | `BasePage` | `RefreshableMixin` | `UI_STRUCTURE.md` Refreshable |
| 상태 관리 복잡 | `BasePage` | `LoadableMixin` | `UI_STRUCTURE.md` Pattern 3 |

### 자주 사용하는 import

```dart
// Base & Mixins
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/mixins/tabbed_mixin.dart';
import 'package:co_workfit/core/presentation/mixins/refreshable_mixin.dart';
import 'package:co_workfit/core/presentation/mixins/loadable_mixin.dart';

// Common Widgets
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';

// UI Components
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';

// Utils
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

// Clean Architecture
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';

// Packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
```

### StandardAppBar Actions

```dart
AppBarActions.refresh(() => _refresh())
AppBarActions.filter(() => _filter())
AppBarActions.sort(() => _sort())
AppBarActions.search(() => _search())
AppBarActions.settings(() => _settings())
AppBarActions.menu<T>(
  items: [
    PopupMenuItem(value: T.value1, child: Text('Option 1')),
    PopupMenuItem(value: T.value2, child: Text('Option 2')),
  ],
  onSelected: (value) => _handleMenu(value),
)
```

---

## 🚨 자주 하는 실수

### ❌ 실수 1: initState에서 BLoC 호출

```dart
// ❌ WRONG - BuildContext 위험!
@override
void initState() {
  super.initState();
  context.read<MyBloc>().add(LoadEvent()); // 위험함!
}

// ✅ CORRECT - loadInitialData() 사용
@override
void loadInitialData() {
  context.read<MyBloc>().add(LoadEvent()); // 안전함
}
```

### ❌ 실수 2: Scaffold 직접 만들기

```dart
// ❌ WRONG - Scaffold 직접 사용
class MyPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: ...,
    );
  }
}

// ✅ CORRECT - BasePage 사용
class MyPage extends BasePage {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BasePageState<MyPage> {
  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(title: 'My Page');
  }

  @override
  Widget buildBody(BuildContext context) {
    return ...; // UI 구현
  }
}
```

### ❌ 실수 3: TabController 수동 관리

```dart
// ❌ WRONG - 수동 TabController
late TabController _tabController;

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);
}

@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}

// ✅ CORRECT - TabbedMixin 사용
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {

  @override
  int get tabCount => 3;

  @override
  List<String> get tabLabels => ['탭1', '탭2', '탭3'];

  @override
  List<Widget> get tabViews => [Tab1(), Tab2(), Tab3()];
  // TabController는 자동 관리됨!
}
```

### ❌ 실수 4: print 사용

```dart
// ❌ WRONG
print('Loading data');
debugPrint('Error: $e');

// ✅ CORRECT
AppLogger.info('MyBloc', 'Loading data');
AppLogger.error('MyBloc', 'Error occurred', e, stackTrace);
```

### ❌ 실수 5: 매직 넘버

```dart
// ❌ WRONG
padding: EdgeInsets.all(16.0),
Color(0xFFFFD700),
timeout: Duration(seconds: 10),

// ✅ CORRECT
padding: EdgeInsets.all(AppConstants.defaultPadding),
Color(AppConstants.goldColor),
timeout: Duration(seconds: AppConstants.defaultTimeoutSeconds),
```

### ❌ 실수 6: 커스텀 Loading/Error UI

```dart
// ❌ WRONG
Center(
  child: Column(
    children: [
      const CircularProgressIndicator(),
      const Text('Loading...'),
    ],
  ),
)

// ✅ CORRECT
const CommonLoadingWidget(message: 'Loading...')
```

### ❌ 실수 7: Layer 의존성 위반

```dart
// ❌ WRONG - Domain이 Data에 의존
import 'package:co_workfit/features/user/data/models/user_model.dart'; // 금지!

// ✅ CORRECT - Domain은 독립적
import 'package:co_workfit/features/user/domain/entities/user_entity.dart'; // OK!
```

---

## 📚 학습 순서 (처음 시작하는 AI)

1. **이 파일 (`.claud`)** 읽기 (30분) - 가장 먼저!
2. **`UI_STRUCTURE.md`** 읽기 (30분) - UI 패턴 익히기
3. **`AI_QUICK_REFERENCE.md`** 읽기 (15분) - 템플릿 익히기
4. **`lib/features/social/presentation/pages/friends_page.dart`** 코드 읽기 (10분) - 실제 예제
5. **`lib/features/social/presentation/pages/leaderboard_page.dart`** 코드 읽기 (10분) - 또 다른 예제
6. **`CONTRIBUTING.md`** 읽기 (20분) - 전체 프로세스
7. **`ARCHITECTURE.md`** 읽기 (20분) - Clean Architecture

**총 소요 시간**: 약 2시간 (하지만 이후 개발 속도 3배 향상!)

---

## ⚖️ 우선순위

코드 작성 시 우선순위:

1. **일관성** (Consistency) - 가장 중요! 새로운 패턴 만들지 말 것
2. **문서 준수** (Follow Docs) - 문서가 법
3. **기존 패턴** (Existing Patterns) - 기존 코드 따르기
4. **간결성** (Simplicity) - 복잡하게 만들지 말 것
5. **성능** (Performance) - 일관성이 우선

---

## 🎓 Remember

> **"완벽한 코드보다 일관된 코드가 낫다"**
>
> **"새로운 패턴보다 기존 패턴이 낫다"**
>
> **"영리한 코드보다 명확한 코드가 낫다"**

---

## ⚠️ 중요

**이 규칙을 어기면 코드 리뷰에서 거부됩니다!**

문서를 읽고, 예제를 보고, 패턴을 따르세요.

그러면 완벽한 코드를 작성할 수 있습니다. ✨

---

## 📖 추가 참고 자료

- **Full Documentation**: `.claude/docs/ARCHITECTURE.md`, `.claude/docs/CONTRIBUTING.md`, `.claude/docs/UI_STRUCTURE.md`
- **Quick Templates**: `.claude/docs/AI_QUICK_REFERENCE.md`
- **Example Code**: `lib/features/social/`

---

_Last Updated: 2025-12-22_
_Version: 2.1 (Moved to .claude/CLAUDE.md)_
