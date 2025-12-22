# AI Quick Reference Guide

빠른 개발을 위한 핵심 정보만 담은 참조 가이드입니다.

## 🚀 Quick Start

### 새 기능 추가 5단계

```
1. Domain  → Entity, Repository Interface, UseCases
2. Data    → Model, DataSource, Repository Implementation
3. BLoC    → Event, State, BLoC
4. UI      → Page, Widgets
5. DI      → injection.dart 등록 → main.dart Provider 추가
```

## 📂 File Structure Cheatsheet

```
features/{feature_name}/
├── domain/
│   ├── entities/{name}_entity.dart
│   ├── repositories/{name}_repository.dart
│   └── usecases/
│       ├── get_{name}s.dart
│       ├── create_{name}.dart
│       ├── update_{name}.dart
│       └── delete_{name}.dart
├── data/
│   ├── models/{name}_model.dart
│   ├── datasources/{source}_{name}_datasource.dart
│   └── repositories/{name}_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── {name}_event.dart
    │   ├── {name}_state.dart
    │   └── {name}_bloc.dart
    ├── pages/{name}_page.dart
    └── widgets/
```

## 🎨 UI Structure

### Quick UI Templates

모든 페이지는 `BasePage`를 사용하여 일관된 구조를 유지합니다.

#### Simple Page (기본 페이지)
```dart
class MyPage extends BasePage {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BasePageState<MyPage> {
  @override
  void loadInitialData() {
    context.read<MyBloc>().add(LoadData());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'My Page',
      actions: [AppBarActions.refresh(() => loadInitialData())],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        if (state is MyLoading) return const CommonLoadingWidget();
        if (state is MyLoaded) return ListView(...);
        return const SizedBox();
      },
    );
  }
}
```

#### Tabbed Page (탭 페이지)
```dart
class MyTabbedPage extends BasePage {
  @override
  State<MyTabbedPage> createState() => _MyTabbedPageState();
}

class _MyTabbedPageState extends BasePageState<MyTabbedPage>
    with SingleTickerProviderStateMixin, TabbedMixin {

  @override
  int get tabCount => 2;

  @override
  List<String> get tabLabels => ['탭1', '탭2'];

  @override
  List<Widget> get tabViews => [Tab1Widget(), Tab2Widget()];

  @override
  void loadInitialData() {
    context.read<MyBloc>().add(LoadAllTabs());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'Tabbed Page',
      bottom: buildTabBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildTabBarView();
  }
}
```

#### Refreshable List Page (새로고침 가능한 목록)
```dart
class MyListPage extends BasePage {
  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends BasePageState<MyListPage>
    with RefreshableMixin, LoadableMixin {

  @override
  void loadInitialData() {
    context.read<MyBloc>().add(LoadList());
  }

  @override
  Future<void> onRefresh() async {
    context.read<MyBloc>().add(RefreshList());
    await context.read<MyBloc>().stream.firstWhere(
      (state) => state is! MyLoading,
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'My List',
      actions: [
        AppBarActions.filter(() => _showFilter()),
        AppBarActions.sort(() => _showSort()),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        return buildRefreshableContent(
          child: handleStates(
            state: state,
            isLoading: (s) => s is MyLoading,
            isError: (s) => s is MyError,
            isEmpty: (s) => s is MyLoaded && s.items.isEmpty,
            getErrorMessage: (s) => (s as MyError).message,
            buildContent: (s) => ListView.builder(
              itemCount: (s as MyLoaded).items.length,
              itemBuilder: (context, index) => _buildItem(s.items[index]),
            ),
            emptyMessage: 'No items',
            onRetry: loadInitialData,
          ),
        );
      },
    );
  }
}
```

### BasePage Usage Examples

**Key Points**:
- `loadInitialData()`: 초기 데이터 로딩 (자동으로 addPostFrameCallback 처리)
- `buildAppBar()`: StandardAppBar 사용
- `buildBody()`: UI 컨텐츠
- `buildFloatingActionButton()`: FAB (optional)
- `buildBottomNavigationBar()`: Bottom Nav (optional)

### Mixin Usage Examples

#### TabbedMixin
```dart
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {

  @override
  int get tabCount => 3;

  @override
  List<String> get tabLabels => ['탭1', '탭2', '탭3'];

  @override
  List<Widget> get tabViews => [Widget1(), Widget2(), Widget3()];

  @override
  void onTabChanged(int index) {
    // 탭 변경 시 동작
  }
}
```

#### RefreshableMixin
```dart
class _MyPageState extends BasePageState<MyPage>
    with RefreshableMixin {

  @override
  Future<void> onRefresh() async {
    context.read<MyBloc>().add(RefreshEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildRefreshableContent(child: ListView(...));
  }
}
```

#### LoadableMixin
```dart
class _MyPageState extends BasePageState<MyPage>
    with LoadableMixin {

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        return handleStates(
          state: state,
          isLoading: (s) => s is MyLoading,
          isError: (s) => s is MyError,
          isEmpty: (s) => s is MyLoaded && s.items.isEmpty,
          getErrorMessage: (s) => (s as MyError).message,
          buildContent: (s) => MyContentWidget(),
          onRetry: () => context.read<MyBloc>().add(LoadEvent()),
        );
      },
    );
  }
}
```

### UI Components Quick Reference

**StandardAppBar Actions**:
```dart
StandardAppBar(
  title: '페이지 제목',
  actions: [
    AppBarActions.refresh(() => _refresh()),
    AppBarActions.filter(() => _openFilter()),
    AppBarActions.sort(() => _openSort()),
    AppBarActions.search(() => _openSearch()),
    AppBarActions.settings(() => _openSettings()),
    AppBarActions.menu([
      PopupMenuItem(value: 1, child: Text('메뉴1')),
      PopupMenuItem(value: 2, child: Text('메뉴2')),
    ], (value) => _handleMenu(value)),
  ],
)
```

**Common Widgets**:
```dart
// Loading
const CommonLoadingWidget(message: 'Loading...')

// Error
CommonErrorWidget(message: 'Error message', onRetry: () => retry())

// Empty
const CommonEmptyWidget(icon: Icons.inbox, message: 'No data')
```

## 🎯 Most Used Code Snippets

### 1. Entity (복사 후 이름만 변경)
```dart
import 'package:equatable/equatable.dart';

class NameEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const NameEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt];

  NameEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return NameEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### 2. Repository Interface
```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';

abstract class NameRepository {
  Future<Either<Failure, List<NameEntity>>> getAll();
  Future<Either<Failure, NameEntity>> getById(String id);
  Future<Either<Failure, void>> create(NameEntity entity);
  Future<Either<Failure, void>> update(NameEntity entity);
  Future<Either<Failure, void>> delete(String id);
}
```

### 3. UseCase (가장 많이 사용)
```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';

class GetNames implements UseCase<List<NameEntity>, NoParams> {
  final NameRepository repository;
  GetNames(this.repository);

  @override
  Future<Either<Failure, List<NameEntity>>> call(NoParams params) {
    return repository.getAll();
  }
}
```

### 4. Model
```dart
import 'package:co_workfit/features/{feature}/domain/entities/name_entity.dart';

class NameModel extends NameEntity {
  const NameModel({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  factory NameModel.fromJson(Map<String, dynamic> json) {
    return NameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

### 5. BLoC State (표준 패턴)
```dart
import 'package:equatable/equatable.dart';

abstract class NameState extends Equatable {
  const NameState();
  @override
  List<Object?> get props => [];
}

class NameInitial extends NameState {}

class NameLoading extends NameState {}

class NameLoaded extends NameState {
  final List<NameEntity> items;
  const NameLoaded(this.items);
  @override
  List<Object?> get props => [items];

  NameLoaded copyWith({List<NameEntity>? items}) {
    return NameLoaded(items ?? this.items);
  }
}

class NameError extends NameState {
  final String message;
  final NameLoaded? previousState;
  const NameError(this.message, {this.previousState});
  @override
  List<Object?> get props => [message, previousState];
}

class NameActionInProgress extends NameState {
  final NameLoaded currentState;
  const NameActionInProgress(this.currentState);
  @override
  List<Object?> get props => [currentState];
}

class NameActionSuccess extends NameState {
  final NameLoaded newState;
  final String message;
  const NameActionSuccess(this.newState, this.message);
  @override
  List<Object?> get props => [newState, message];
}
```

### 6. BLoC Event
```dart
import 'package:equatable/equatable.dart';

abstract class NameEvent extends Equatable {
  const NameEvent();
  @override
  List<Object?> get props => [];
}

class LoadNames extends NameEvent {}

class CreateName extends NameEvent {
  final String name;
  const CreateName(this.name);
  @override
  List<Object?> get props => [name];
}

class DeleteName extends NameEvent {
  final String id;
  const DeleteName(this.id);
  @override
  List<Object?> get props => [id];
}
```

### 7. BLoC (기본 구조)
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';

class NameBloc extends Bloc<NameEvent, NameState> {
  final GetNames _getNames;
  final CreateName _createName;

  NameBloc({
    required GetNames getNames,
    required CreateName createName,
  })  : _getNames = getNames,
        _createName = createName,
        super(NameInitial()) {
    on<LoadNames>(_onLoadNames);
    on<CreateName>(_onCreateName);
  }

  Future<void> _onLoadNames(
    LoadNames event,
    Emitter<NameState> emit,
  ) async {
    AppLogger.info('NameBloc', 'Loading items');
    emit(NameLoading());

    final result = await _getNames(NoParams());

    result.fold(
      (failure) {
        AppLogger.error('NameBloc', 'Failed to load', failure);
        emit(NameError(failure.message));
      },
      (items) {
        AppLogger.info('NameBloc', 'Loaded ${items.length} items');
        emit(NameLoaded(items));
      },
    );
  }

  Future<void> _onCreateName(
    CreateName event,
    Emitter<NameState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NameLoaded) return;

    emit(NameActionInProgress(currentState));

    final result = await _createName(event.name);

    result.fold(
      (failure) => emit(NameError(failure.message, previousState: currentState)),
      (_) {
        // Reload data or update state
        add(LoadNames());
      },
    );
  }
}
```

### 8. Page Template (BasePage 사용)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/widgets/base_page.dart';
import 'package:co_workfit/core/widgets/standard_app_bar.dart';
import 'package:co_workfit/core/widgets/app_bar_actions.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';

class NamePage extends BasePage {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends BasePageState<NamePage> {
  @override
  void loadInitialData() {
    context.read<NameBloc>().add(LoadNames());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'Name Page',
      actions: [
        AppBarActions.refresh(() => loadInitialData()),
        AppBarActions.filter(() => _showFilter()),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<NameBloc, NameState>(
      builder: (context, state) {
        if (state is NameLoading) {
          return const CommonLoadingWidget(message: 'Loading...');
        }

        if (state is NameError && state.previousState == null) {
          return CommonErrorWidget(
            message: state.message,
            onRetry: () => context.read<NameBloc>().add(LoadNames()),
          );
        }

        final items = state is NameLoaded
            ? state.items
            : state is NameActionSuccess
                ? state.newState.items
                : state is NameActionInProgress
                    ? state.currentState.items
                    : state is NameError && state.previousState != null
                        ? state.previousState!.items
                        : <NameEntity>[];

        if (items.isEmpty) {
          return const CommonEmptyWidget(
            icon: Icons.inbox,
            message: 'No items yet',
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(items[index].name));
          },
        );
      },
    );
  }

  void _showFilter() {
    // Show filter dialog
  }
}
```

### 9. Dependency Injection
```dart
// In lib/core/di/injection.dart

Future<void> initializeDependencies() async {
  final sl = GetIt.instance;

  // ... existing code ...

  // Data Sources
  sl.registerLazySingleton(() => FirestoreNameDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<NameRepository>(
    () => NameRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetNames(sl()));
  sl.registerLazySingleton(() => CreateName(sl()));
  sl.registerLazySingleton(() => DeleteName(sl()));

  // BLoC
  sl.registerFactory(() => NameBloc(
    getNames: sl(),
    createName: sl(),
  ));
}
```

```dart
// In lib/main.dart

MultiBlocProvider(
  providers: [
    // ... existing providers ...
    BlocProvider<NameBloc>(create: (_) => sl<NameBloc>()),
  ],
  child: MaterialApp(...),
)
```

## 📋 Common Patterns

### Pattern: Firestore DataSource
```dart
class FirestoreNameDataSource {
  final FirebaseFirestore firestore;

  FirestoreNameDataSource(this.firestore);

  Future<Either<String, List<Map<String, dynamic>>>> getAll(String userId) async {
    try {
      final snapshot = await firestore
          .collection('names')
          .where('userId', isEqualTo: userId)
          .get();

      return Right(snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      AppLogger.error('FirestoreNameDataSource', 'Failed to fetch', e);
      return Left('Failed to fetch data: $e');
    }
  }

  Future<Either<String, void>> create(Map<String, dynamic> data) async {
    try {
      await firestore.collection('names').add(data);
      return const Right(null);
    } catch (e) {
      AppLogger.error('FirestoreNameDataSource', 'Failed to create', e);
      return Left('Failed to create: $e');
    }
  }
}
```

### Pattern: Repository Implementation
```dart
class NameRepositoryImpl implements NameRepository {
  final FirestoreNameDataSource dataSource;

  NameRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<NameEntity>>> getAll() async {
    final result = await dataSource.getAll(userId);

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (data) {
        final items = data.map((json) => NameModel.fromJson(json)).toList();
        return Right(items);
      },
    );
  }

  @override
  Future<Either<Failure, void>> create(NameEntity entity) async {
    final model = NameModel.fromEntity(entity);
    final result = await dataSource.create(model.toJson());

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (_) => const Right(null),
    );
  }
}
```

### Pattern: BLoC Listener (for SnackBar)
```dart
BlocListener<NameBloc, NameState>(
  listener: (context, state) {
    if (state is NameActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (state is NameError && state.previousState != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: BlocBuilder<NameBloc, NameState>(...),
)
```

## 🛠️ Must-Use Utilities

### AppLogger
```dart
AppLogger.info('Tag', 'Information message');
AppLogger.debug('Tag', 'Debug message');
AppLogger.warning('Tag', 'Warning message');
AppLogger.error('Tag', 'Error message', error);
AppLogger.performance('Tag', 'Operation name', durationMs);
```

### Common Widgets
```dart
// Loading
const CommonLoadingWidget(message: 'Loading...')

// Error
CommonErrorWidget(
  message: 'Error message',
  onRetry: () => retry(),
)

// Empty
const CommonEmptyWidget(
  icon: Icons.inbox,
  message: 'No data',
)
```

### AppConstants
```dart
AppConstants.defaultPadding          // 16.0
AppConstants.defaultBorderRadius     // 8.0
AppConstants.defaultElevation        // 2.0
AppConstants.goldRank                // 1
AppConstants.silverRank              // 2
AppConstants.bronzeRank              // 3
AppConstants.goldColor               // 0xFFFFD700
AppConstants.silverColor             // 0xFFC0C0C0
AppConstants.bronzeColor             // 0xFFCD7F32
AppConstants.usersCollection         // 'users'
AppConstants.defaultTimeoutSeconds   // 10
```

## ⚡ Super Quick Commands

### Create New Feature (Manual Steps)
```bash
# 1. Create structure
mkdir -p lib/features/NAME/{domain/{entities,repositories,usecases},data/{models,datasources,repositories},presentation/{bloc,pages,widgets}}

# 2. Follow template from CONTRIBUTING.md

# 3. Register in DI
# Edit lib/core/di/injection.dart

# 4. Add to main.dart
# Add BlocProvider in MultiBlocProvider
```

### Check Code Quality
```bash
flutter analyze  # Should show 0 errors
flutter test     # Run tests
```

## 🎯 Development Workflow

```
1. Plan      → List entities, usecases
2. Domain    → Write interfaces (15 min)
3. Data      → Implement data layer (30 min)
4. BLoC      → State management (30 min)
5. UI        → Build widgets (45 min)
6. DI        → Wire dependencies (10 min)
7. Test      → flutter analyze (5 min)
8. Commit    → Create PR
```

## 🚫 Quick Don'ts

- ❌ `print()` → Use `AppLogger`
- ❌ Magic numbers → Use `AppConstants`
- ❌ Custom error widgets → Use `CommonErrorWidget`
- ❌ Custom loading → Use `CommonLoadingWidget`
- ❌ Direct instantiation → Use DI
- ❌ Skipping states → Handle all (Loading, Error, Empty, Success)

## 📚 Quick Reference Files

- `UI_STRUCTURE.md` - Complete UI structure guide (BasePage, Mixins, Patterns)
- `ARCHITECTURE.md` - Full architecture guide
- `CONTRIBUTING.md` - Detailed contribution guide
- `lib/features/social/` - Reference implementation (FriendsPage, LeaderboardPage)
- `lib/core/widgets/` - Base classes (BasePage, Mixins, Common widgets)

## 🏃‍♂️ Speed Tips for AI

1. **Copy existing feature** - Fastest way to start
2. **Use templates** - Copy from this guide
3. **Follow patterns** - Don't innovate
4. **Check similar code** - See how others did it
5. **Use TodoWrite** - Track progress
6. **Run analyze often** - Catch errors early

---

**Pro Tip**: 기존 코드를 복사해서 이름만 바꾸는 것이 가장 빠르고 안전합니다!
