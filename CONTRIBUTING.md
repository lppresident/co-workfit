# Contributing Guide for AI Assistants

이 가이드는 AI Assistant가 Co-WorkFit 프로젝트에 기여할 때 따라야 할 규칙과 패턴을 정의합니다.

## 🎯 Core Principles for AI Development

### 1. **Always Follow Clean Architecture**
- Domain Layer는 외부 의존성을 가지지 않음
- Data Layer는 Domain을 구현
- Presentation Layer는 Domain을 사용

### 2. **Use Existing Patterns**
- 새로운 패턴을 만들지 말고 기존 패턴을 따름
- 비슷한 기능이 있으면 그 구조를 참고
- 코드 중복보다 일관성이 더 중요

### 3. **Be Explicit, Not Clever**
- 명확한 코드가 영리한 코드보다 좋음
- 복잡한 로직에는 주석 필수
- 변수/함수 이름은 설명적으로

## 📋 Development Checklist

새 기능을 추가할 때 다음 체크리스트를 따르세요:

### Phase 1: Planning
- [ ] 기능 요구사항 이해
- [ ] 비슷한 기존 기능 찾기 (참고용)
- [ ] 필요한 Entity 파악
- [ ] 필요한 UseCase 나열

### Phase 2: Domain Layer
- [ ] `{feature}/domain/entities/` - Entity 생성
- [ ] `{feature}/domain/repositories/` - Repository 인터페이스 생성
- [ ] `{feature}/domain/usecases/` - UseCase들 생성

### Phase 3: Data Layer
- [ ] `{feature}/data/models/` - Model 생성 (fromJson, toJson)
- [ ] `{feature}/data/datasources/` - DataSource 생성
- [ ] `{feature}/data/repositories/` - Repository 구현체 생성

### Phase 4: Presentation Layer
- [ ] `{feature}/presentation/bloc/` - Event, State, BLoC 생성
- [ ] `{feature}/presentation/widgets/` - 재사용 가능한 위젯 생성
- [ ] `{feature}/presentation/pages/` - Page 생성

### Phase 5: Integration
- [ ] `core/di/injection.dart` - 의존성 등록
- [ ] `main.dart` - BlocProvider 추가
- [ ] 관련 페이지에 네비게이션 추가

### Phase 6: Quality Assurance
- [ ] `flutter analyze` - 0 errors 확인
- [ ] Common widgets 사용 확인 (Loading, Error, Empty)
- [ ] AppLogger 사용 확인 (print 금지)
- [ ] Constants 사용 확인 (magic numbers 금지)
- [ ] 주석 추가 (복잡한 로직)

## 🏗️ Feature Template

새 기능을 추가할 때 이 템플릿을 사용하세요:

### 1. Entity Template
```dart
import 'package:equatable/equatable.dart';

/// {Description of the entity}
class {Name}Entity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const {Name}Entity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt];

  {Name}Entity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return {Name}Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### 2. Repository Interface Template
```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/features/{feature}/domain/entities/{name}_entity.dart';

/// Repository for {description}
abstract class {Name}Repository {
  /// Get all {items}
  Future<Either<Failure, List<{Name}Entity>>> getAll();

  /// Get {item} by ID
  Future<Either<Failure, {Name}Entity>> getById(String id);

  /// Create new {item}
  Future<Either<Failure, void>> create({Name}Entity entity);

  /// Update existing {item}
  Future<Either<Failure, void>> update({Name}Entity entity);

  /// Delete {item}
  Future<Either<Failure, void>> delete(String id);
}
```

### 3. UseCase Template
```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/{feature}/domain/entities/{name}_entity.dart';
import 'package:co_workfit/features/{feature}/domain/repositories/{name}_repository.dart';

/// UseCase for {description}
class {Action}{Name} implements UseCase<{ReturnType}, {ParamsType}> {
  final {Name}Repository repository;

  {Action}{Name}(this.repository);

  @override
  Future<Either<Failure, {ReturnType}>> call({ParamsType} params) async {
    return await repository.{methodName}(params);
  }
}
```

### 4. Model Template
```dart
import 'package:co_workfit/features/{feature}/domain/entities/{name}_entity.dart';

/// Data model for {Name}
class {Name}Model extends {Name}Entity {
  const {Name}Model({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  /// Create model from JSON
  factory {Name}Model.fromJson(Map<String, dynamic> json) {
    return {Name}Model(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create model from entity
  factory {Name}Model.fromEntity({Name}Entity entity) {
    return {Name}Model(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }
}
```

### 5. BLoC Event Template
```dart
import 'package:equatable/equatable.dart';

/// Events for {Name}BLoC
abstract class {Name}Event extends Equatable {
  const {Name}Event();

  @override
  List<Object?> get props => [];
}

/// Load all {items}
class Load{Name}s extends {Name}Event {
  const Load{Name}s();
}

/// Create new {item}
class Create{Name} extends {Name}Event {
  final String name;

  const Create{Name}({required this.name});

  @override
  List<Object?> get props => [name];
}

/// Update existing {item}
class Update{Name} extends {Name}Event {
  final String id;
  final String name;

  const Update{Name}({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

/// Delete {item}
class Delete{Name} extends {Name}Event {
  final String id;

  const Delete{Name}({required this.id});

  @override
  List<Object?> get props => [id];
}
```

### 6. BLoC State Template
```dart
import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/{feature}/domain/entities/{name}_entity.dart';

/// States for {Name}BLoC
abstract class {Name}State extends Equatable {
  const {Name}State();

  @override
  List<Object?> get props => [];
}

/// Initial state
class {Name}Initial extends {Name}State {
  const {Name}Initial();
}

/// Loading state
class {Name}Loading extends {Name}State {
  const {Name}Loading();
}

/// Loaded state with data
class {Name}Loaded extends {Name}State {
  final List<{Name}Entity> items;

  const {Name}Loaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Error state
class {Name}Error extends {Name}State {
  final String message;
  final {Name}Loaded? previousState;

  const {Name}Error(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}

/// Action in progress (optimistic update)
class {Name}ActionInProgress extends {Name}State {
  final {Name}Loaded currentState;

  const {Name}ActionInProgress(this.currentState);

  @override
  List<Object?> get props => [currentState];
}

/// Action success
class {Name}ActionSuccess extends {Name}State {
  final {Name}Loaded newState;
  final String message;

  const {Name}ActionSuccess(this.newState, this.message);

  @override
  List<Object?> get props => [newState, message];
}
```

### 7. BLoC Template
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/{feature}/domain/usecases/{action}_{name}.dart';
import 'package:co_workfit/features/{feature}/presentation/bloc/{name}_event.dart';
import 'package:co_workfit/features/{feature}/presentation/bloc/{name}_state.dart';

/// BLoC for {Name} feature
class {Name}Bloc extends Bloc<{Name}Event, {Name}State> {
  final Load{Name}s _load{Name}s;
  final Create{Name} _create{Name};
  final Update{Name} _update{Name};
  final Delete{Name} _delete{Name};

  {Name}Bloc({
    required Load{Name}s load{Name}s,
    required Create{Name} create{Name},
    required Update{Name} update{Name},
    required Delete{Name} delete{Name},
  })  : _load{Name}s = load{Name}s,
        _create{Name} = create{Name},
        _update{Name} = update{Name},
        _delete{Name} = delete{Name},
        super(const {Name}Initial()) {
    on<Load{Name}s>(_onLoad{Name}s);
    on<Create{Name}>(_onCreate{Name});
    on<Update{Name}>(_onUpdate{Name});
    on<Delete{Name}>(_onDelete{Name});
  }

  Future<void> _onLoad{Name}s(
    Load{Name}s event,
    Emitter<{Name}State> emit,
  ) async {
    AppLogger.info('{Name}Bloc', 'Loading {items}');
    emit(const {Name}Loading());

    final result = await _load{Name}s(const NoParams());

    result.fold(
      (failure) {
        AppLogger.error('{Name}Bloc', 'Failed to load {items}', failure);
        emit({Name}Error(failure.message));
      },
      (items) {
        AppLogger.info('{Name}Bloc', 'Loaded ${items.length} {items}');
        emit({Name}Loaded(items));
      },
    );
  }

  Future<void> _onCreate{Name}(
    Create{Name} event,
    Emitter<{Name}State> emit,
  ) async {
    // Implementation
  }

  Future<void> _onUpdate{Name}(
    Update{Name} event,
    Emitter<{Name}State> emit,
  ) async {
    // Implementation
  }

  Future<void> _onDelete{Name}(
    Delete{Name} event,
    Emitter<{Name}State> emit,
  ) async {
    // Implementation
  }
}
```

## 🎨 Code Style Guide

### Naming Conventions

#### Variables & Functions
```dart
// ✅ GOOD
final userName = 'John';
final workoutCount = 10;
Future<void> loadUserProfile() async {}

// ❌ BAD
final name = 'John';  // Too generic
final x = 10;  // Meaningless
Future<void> load() async {}  // Not descriptive
```

#### Classes
```dart
// ✅ GOOD - Descriptive and follows pattern
class UserProfileEntity {}
class WorkoutRepositoryImpl {}
class GetRecentWorkouts {}

// ❌ BAD - Too generic or unclear
class Profile {}
class Repo {}
class Get {}
```

#### Files
```dart
// ✅ GOOD - Snake case, descriptive
user_profile_entity.dart
workout_repository_impl.dart
get_recent_workouts.dart

// ❌ BAD
UserProfile.dart  // Should be snake_case
workout.dart  // Too generic
usecase.dart  // Not descriptive
```

### Comments

```dart
// ✅ GOOD - Explains WHY, not WHAT
// Health Connect sometimes returns false even when permission exists
// So we need to verify with actual data access
if (!authorized) {
  await verifyWithDataAccess();
}

// ❌ BAD - Explains obvious WHAT
// Check if authorized is false
if (!authorized) {
  await verifyWithDataAccess();
}
```

### Error Handling

```dart
// ✅ GOOD - Specific error types, logging
try {
  await repository.getData();
} on ServerException catch (e) {
  AppLogger.error('Tag', 'Server error occurred', e);
  return Left(ServerFailure(e.message));
} on CacheException catch (e) {
  AppLogger.error('Tag', 'Cache error occurred', e);
  return Left(CacheFailure(e.message));
} catch (e) {
  AppLogger.error('Tag', 'Unexpected error', e);
  return Left(UnexpectedFailure(e.toString()));
}

// ❌ BAD - Generic catch, no logging
try {
  await repository.getData();
} catch (e) {
  return Left(Failure(e.toString()));
}
```

## 📊 Common Patterns

### Pattern 1: Optimistic Updates

```dart
// Show loading state while keeping current data
Future<void> _onDeleteFriend(
  DeleteFriend event,
  Emitter<SocialState> emit,
) async {
  final currentState = state;
  if (currentState is! SocialLoaded) return;

  // Show action in progress
  emit(SocialActionInProgress(currentState));

  final result = await _deleteFriend(event.friendId);

  result.fold(
    (failure) => emit(SocialError(failure.message, previousState: currentState)),
    (_) {
      final updatedFriends = currentState.friends
          .where((f) => f.id != event.friendId)
          .toList();
      emit(SocialActionSuccess(
        currentState.copyWith(friends: updatedFriends),
        '친구가 삭제되었습니다',
      ));
    },
  );
}
```

### Pattern 2: Pull-to-Refresh

```dart
// In widget
RefreshIndicator(
  onRefresh: () async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<SocialBloc>().add(RefreshFriends(authState.user.id));

      // Wait for state change
      await context.read<SocialBloc>().stream.firstWhere(
        (state) => state is! SocialLoading,
      );
    }
  },
  child: ListView(...),
)
```

### Pattern 3: Common Widget Usage

```dart
// ✅ GOOD - Use common widgets
BlocBuilder<WorkoutBloc, WorkoutState>(
  builder: (context, state) {
    if (state is WorkoutLoading) {
      return const CommonLoadingWidget(message: 'Loading workouts...');
    }

    if (state is WorkoutError) {
      return CommonErrorWidget(
        message: state.message,
        onRetry: () => context.read<WorkoutBloc>().add(LoadWorkouts()),
      );
    }

    if (state is WorkoutLoaded && state.workouts.isEmpty) {
      return const CommonEmptyWidget(
        icon: Icons.fitness_center,
        message: 'No workouts yet',
      );
    }

    // ... render data
  },
)

// ❌ BAD - Custom implementation
if (state is WorkoutLoading) {
  return Center(child: CircularProgressIndicator());
}
```

## 🚫 Common Mistakes to Avoid

### 1. Don't Use print()
```dart
// ❌ BAD
print('Loading data...');

// ✅ GOOD
AppLogger.info('Tag', 'Loading data...');
```

### 2. Don't Use Magic Numbers
```dart
// ❌ BAD
padding: EdgeInsets.all(16.0)
Color(0xFFFFD700)

// ✅ GOOD
padding: EdgeInsets.all(AppConstants.defaultPadding)
Color(AppConstants.goldColor)
```

### 3. Don't Skip Error States
```dart
// ❌ BAD - Only handles success
if (state is Loaded) {
  return DataWidget(state.data);
}
return SizedBox();

// ✅ GOOD - Handles all states
if (state is Loading) return CommonLoadingWidget();
if (state is Error) return CommonErrorWidget(...);
if (state is Loaded) return DataWidget(state.data);
return SizedBox();
```

### 4. Don't Forget Dependency Injection
```dart
// ❌ BAD - Direct instantiation
class MyBloc extends Bloc {
  final repository = MyRepositoryImpl();  // Wrong!
}

// ✅ GOOD - Inject dependency
class MyBloc extends Bloc {
  final MyRepository repository;
  MyBloc({required this.repository});
}

// In injection.dart
sl.registerFactory(() => MyBloc(repository: sl()));
```

## 📝 Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types
- `feat`: 새 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `docs`: 문서 변경
- `test`: 테스트 추가/수정
- `chore`: 빌드, 설정 변경

### Example
```
feat: Add user profile management

Implemented complete user profile feature including:
- Profile viewing and editing
- Avatar upload
- Display name update
- Email verification

Closes #123

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 🔍 Code Review Checklist

Before creating PR, verify:

- [ ] `flutter analyze` shows 0 errors
- [ ] No `print()` statements (use `AppLogger`)
- [ ] No magic numbers (use `AppConstants`)
- [ ] Common widgets used where appropriate
- [ ] All states handled (Loading, Error, Empty, Success)
- [ ] Error handling in place
- [ ] Dependency injection configured
- [ ] Comments added for complex logic
- [ ] Naming conventions followed
- [ ] Architecture layers respected
- [ ] No code duplication

## 🎓 Learning Resources

- `ARCHITECTURE.md` - Architecture guide
- `lib/features/social/` - Reference implementation
- `lib/core/` - Common utilities and base classes
- Existing BLoCs - State management patterns

## 💡 Tips for AI Assistants

1. **Always check existing code first** - Don't reinvent the wheel
2. **Follow patterns exactly** - Consistency > Cleverness
3. **Use templates** - Copy-paste and modify from templates above
4. **Test as you go** - Run `flutter analyze` frequently
5. **Document decisions** - Add comments explaining complex logic
6. **Ask for clarification** - If requirements are unclear, ask the user
7. **Break down large tasks** - Use TodoWrite to track progress
8. **Be systematic** - Complete one layer before moving to next

---

**Remember**: Clean, consistent, and maintainable code is more important than clever optimizations!
