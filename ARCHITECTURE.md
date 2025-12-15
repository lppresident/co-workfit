# Co-WorkFit Architecture Guide

## 📐 Architecture Overview

이 프로젝트는 **Clean Architecture**와 **BLoC Pattern**을 사용합니다.

```
lib/
├── core/                    # 공통 기능
│   ├── constants/          # 앱 전역 상수
│   ├── di/                 # 의존성 주입 (get_it)
│   ├── platform/           # 플랫폼별 코드
│   ├── utils/              # 유틸리티 (Logger 등)
│   └── widgets/            # 공통 위젯
│
├── features/               # 기능별 모듈
│   └── {feature_name}/     # 각 기능 (workout, auth, social 등)
│       ├── data/
│       │   ├── datasources/    # 데이터 소스 (Firebase, API 등)
│       │   ├── models/         # 데이터 모델 (JSON 매핑)
│       │   └── repositories/   # Repository 구현체
│       ├── domain/
│       │   ├── entities/       # 비즈니스 엔티티
│       │   ├── repositories/   # Repository 인터페이스
│       │   └── usecases/       # 비즈니스 로직 (단일 책임)
│       └── presentation/
│           ├── bloc/           # BLoC (상태 관리)
│           ├── pages/          # 화면
│           └── widgets/        # 기능별 위젯
│
└── shared/                 # 공유 리소스
    └── theme/              # 테마 설정
```

## 🎯 Core Principles

### 1. **의존성 방향**: Domain ← Data, Presentation
- Domain Layer는 다른 레이어에 의존하지 않음
- Data와 Presentation은 Domain에 의존

### 2. **단일 책임 원칙**
- UseCase: 하나의 비즈니스 로직만 처리
- Repository: 데이터 접근 추상화
- BLoC: UI 상태 관리

### 3. **에러 처리**: Either<Failure, Success>
- 모든 Repository와 UseCase는 `Either<Failure, T>` 반환
- Left: 에러 (Failure)
- Right: 성공 (데이터)

## 🧩 Layer Details

### Domain Layer (비즈니스 로직)

#### Entity
```dart
/// 순수한 비즈니스 객체, 외부 의존성 없음
class WorkoutEntity extends Equatable {
  final String id;
  final DateTime date;
  final int duration;

  const WorkoutEntity({
    required this.id,
    required this.date,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, date, duration];
}
```

#### Repository Interface
```dart
/// 데이터 접근 계약
abstract class WorkoutRepository {
  Future<Either<Failure, List<WorkoutEntity>>> getWorkouts(int days);
  Future<Either<Failure, void>> saveWorkout(WorkoutEntity workout);
}
```

#### UseCase
```dart
/// 단일 비즈니스 로직
class GetRecentWorkouts {
  final WorkoutRepository repository;

  GetRecentWorkouts(this.repository);

  Future<Either<Failure, List<WorkoutEntity>>> call(int days) {
    return repository.getWorkouts(days);
  }
}
```

### Data Layer (데이터 접근)

#### Model
```dart
/// JSON ↔ Entity 변환
class WorkoutModel extends WorkoutEntity {
  const WorkoutModel({
    required super.id,
    required super.date,
    required super.duration,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration': duration,
    };
  }
}
```

#### DataSource
```dart
/// 실제 데이터 가져오기 (Firebase, API 등)
class FirestoreWorkoutDataSource {
  final FirebaseFirestore firestore;

  Future<Either<String, List<Map<String, dynamic>>>> getWorkouts(
    String userId,
    int days,
  ) async {
    try {
      final snapshot = await firestore
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .get();

      return Right(snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      return Left('Failed to fetch workouts: $e');
    }
  }
}
```

#### Repository Implementation
```dart
/// Repository 구현체
class WorkoutRepositoryImpl implements WorkoutRepository {
  final FirestoreWorkoutDataSource dataSource;

  WorkoutRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<WorkoutEntity>>> getWorkouts(int days) async {
    final result = await dataSource.getWorkouts(userId, days);

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (data) {
        final workouts = data.map((json) => WorkoutModel.fromJson(json)).toList();
        return Right(workouts);
      },
    );
  }
}
```

### Presentation Layer (UI)

#### BLoC Event
```dart
/// 사용자 액션
abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();
}

class LoadWorkouts extends WorkoutEvent {
  final int days;

  const LoadWorkouts(this.days);

  @override
  List<Object?> get props => [days];
}
```

#### BLoC State
```dart
/// UI 상태
abstract class WorkoutState extends Equatable {
  const WorkoutState();
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutLoaded extends WorkoutState {
  final List<WorkoutEntity> workouts;

  const WorkoutLoaded(this.workouts);

  @override
  List<Object?> get props => [workouts];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### BLoC
```dart
/// 이벤트 → 상태 변환
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final GetRecentWorkouts getRecentWorkouts;

  WorkoutBloc({required this.getRecentWorkouts}) : super(WorkoutInitial()) {
    on<LoadWorkouts>(_onLoadWorkouts);
  }

  Future<void> _onLoadWorkouts(
    LoadWorkouts event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());

    final result = await getRecentWorkouts(event.days);

    result.fold(
      (failure) => emit(WorkoutError(failure.message)),
      (workouts) => emit(WorkoutLoaded(workouts)),
    );
  }
}
```

#### Widget
```dart
/// UI 렌더링
class WorkoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, state) {
        if (state is WorkoutLoading) {
          return const CommonLoadingWidget();
        }

        if (state is WorkoutError) {
          return CommonErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<WorkoutBloc>().add(const LoadWorkouts(7));
            },
          );
        }

        if (state is WorkoutLoaded) {
          return ListView.builder(
            itemCount: state.workouts.length,
            itemBuilder: (context, index) {
              return WorkoutCard(workout: state.workouts[index]);
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}
```

## 🔧 Common Utilities

### AppLogger
```dart
// Debug logging (debug mode only)
AppLogger.debug('Tag', 'Debug message');

// Info logging
AppLogger.info('Tag', 'Info message');

// Warning logging
AppLogger.warning('Tag', 'Warning message');

// Error logging
AppLogger.error('Tag', 'Error message', error);

// Performance logging
AppLogger.performance('Tag', 'Operation', durationMs);
```

### Common Widgets
```dart
// Loading state
const CommonLoadingWidget(message: 'Loading...')

// Error state
CommonErrorWidget(
  message: 'Error occurred',
  onRetry: () => retry(),
)

// Empty state
const CommonEmptyWidget(
  icon: Icons.inbox,
  message: 'No data',
)
```

### Constants
```dart
// Use constants instead of magic numbers
AppConstants.defaultPadding  // 16.0
AppConstants.defaultBorderRadius  // 8.0
AppConstants.goldColor  // 0xFFFFD700
AppConstants.silverColor  // 0xFFC0C0C0
AppConstants.bronzeColor  // 0xFFCD7F32
```

## 📝 Dependency Injection

### Registration (injection.dart)
```dart
Future<void> initializeDependencies() async {
  final sl = GetIt.instance;

  // Data Sources
  sl.registerLazySingleton(() => FirestoreWorkoutDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetRecentWorkouts(sl()));

  // BLoCs
  sl.registerFactory(() => WorkoutBloc(getRecentWorkouts: sl()));

  // External
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}
```

### Usage (main.dart)
```dart
MultiBlocProvider(
  providers: [
    BlocProvider<WorkoutBloc>(create: (_) => sl<WorkoutBloc>()),
  ],
  child: MaterialApp(...),
)
```

## 🎨 Naming Conventions

### Files
- **Entity**: `{name}_entity.dart` (예: `workout_entity.dart`)
- **Model**: `{name}_model.dart` (예: `workout_model.dart`)
- **Repository Interface**: `{name}_repository.dart`
- **Repository Implementation**: `{name}_repository_impl.dart`
- **UseCase**: `{action}_{object}.dart` (예: `get_recent_workouts.dart`)
- **DataSource**: `{source}_{name}_datasource.dart` (예: `firestore_workout_datasource.dart`)
- **BLoC**: `{name}_bloc.dart`, `{name}_event.dart`, `{name}_state.dart`
- **Page**: `{name}_page.dart`
- **Widget**: `{name}_widget.dart` 또는 `{name}_tab.dart`

### Classes
- **Entity**: `{Name}Entity`
- **Model**: `{Name}Model`
- **Repository**: `{Name}Repository`
- **UseCase**: `{Verb}{Object}` (예: `GetRecentWorkouts`, `UpdateUserProfile`)
- **Event**: `{Verb}{Object}` (예: `LoadWorkouts`, `SaveWorkout`)
- **State**: `{Name}{Status}` (예: `WorkoutLoading`, `WorkoutLoaded`)

## 🚀 Development Workflow

### Adding New Feature

1. **Create Feature Structure**
```bash
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

2. **Domain First** (비즈니스 로직)
   - Entity 정의
   - Repository 인터페이스 작성
   - UseCase 작성

3. **Data Layer** (데이터 접근)
   - Model 작성 (fromJson, toJson)
   - DataSource 작성
   - Repository 구현

4. **Presentation Layer** (UI)
   - Event/State 정의
   - BLoC 작성
   - Widget/Page 작성

5. **Dependency Injection**
   - `injection.dart`에 등록
   - `main.dart`에 BlocProvider 추가

## ✅ Best Practices

### DO ✅
- Use `const` constructors whenever possible
- Use `Equatable` for value equality
- Use common widgets (`CommonLoadingWidget`, etc.)
- Use `AppLogger` instead of `print()`
- Use constants from `AppConstants`
- Follow naming conventions
- Write descriptive commit messages
- Add comments for complex logic

### DON'T ❌
- Don't use `print()` - use `AppLogger`
- Don't use magic numbers - use `AppConstants`
- Don't create duplicate widgets - extract to common
- Don't skip error handling
- Don't ignore lint warnings
- Don't bypass dependency injection
- Don't mix business logic with UI

## 🧪 Testing Strategy

### Unit Tests
- UseCases: 비즈니스 로직 테스트
- Repositories: 데이터 변환 테스트

### Widget Tests
- BLoC: 이벤트 → 상태 테스트
- Widgets: UI 렌더링 테스트

### Integration Tests
- End-to-end 시나리오 테스트

## 📚 Additional Resources

- [Flutter BLoC Documentation](https://bloclibrary.dev/)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
