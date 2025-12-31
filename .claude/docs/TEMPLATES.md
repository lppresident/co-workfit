# 코드 템플릿

> 새 기능 추가 시 복사해서 사용하세요.

---

## 📁 Feature 폴더 구조

```
lib/features/{feature_name}/
├── domain/
│   ├── entities/{name}_entity.dart
│   ├── repositories/{name}_repository.dart
│   └── usecases/{action}_{name}.dart
├── data/
│   ├── models/{name}_model.dart
│   ├── datasources/firestore_{name}_datasource.dart
│   └── repositories/{name}_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── {name}_bloc.dart
    │   ├── {name}_event.dart
    │   └── {name}_state.dart
    ├── pages/{name}_page.dart
    └── widgets/{name}_widget.dart
```

---

## 1️⃣ Entity

```dart
import 'package:equatable/equatable.dart';

class ItemEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const ItemEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt];

  ItemEntity copyWith({String? id, String? name, DateTime? createdAt}) {
    return ItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

---

## 2️⃣ Repository (추상)

```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';

abstract class ItemRepository {
  Future<Either<Failure, List<ItemEntity>>> getItems(String userId);
  Future<Either<Failure, void>> createItem(ItemEntity item);
  Future<Either<Failure, void>> deleteItem(String id);
}
```

---

## 3️⃣ UseCase

```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';

class GetItems implements UseCase<List<ItemEntity>, String> {
  final ItemRepository repository;
  GetItems(this.repository);

  @override
  Future<Either<Failure, List<ItemEntity>>> call(String userId) {
    return repository.getItems(userId);
  }
}
```

---

## 4️⃣ Model

```dart
class ItemModel extends ItemEntity {
  const ItemModel({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ItemModel.fromEntity(ItemEntity entity) {
    return ItemModel(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }
}
```

---

## 5️⃣ DataSource

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/utils/logger.dart';

class FirestoreItemDataSource {
  final FirebaseFirestore firestore;
  FirestoreItemDataSource(this.firestore);

  Future<List<ItemModel>> getItems(String userId) async {
    AppLogger.info('ItemDataSource', 'Fetching items for $userId');
    final snapshot = await firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ItemModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> createItem(ItemModel item) async {
    await firestore.collection('items').doc(item.id).set(item.toJson());
  }

  Future<void> deleteItem(String id) async {
    await firestore.collection('items').doc(id).delete();
  }
}
```

---

## 6️⃣ Repository 구현체

```dart
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/utils/logger.dart';

class ItemRepositoryImpl implements ItemRepository {
  final FirestoreItemDataSource dataSource;
  ItemRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<ItemEntity>>> getItems(String userId) async {
    try {
      final items = await dataSource.getItems(userId);
      return Right(items);
    } catch (e, st) {
      AppLogger.error('ItemRepository', 'Failed to get items', e, st);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createItem(ItemEntity item) async {
    try {
      await dataSource.createItem(ItemModel.fromEntity(item));
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('ItemRepository', 'Failed to create item', e, st);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    try {
      await dataSource.deleteItem(id);
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('ItemRepository', 'Failed to delete item', e, st);
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

---

## 7️⃣ BLoC Event

```dart
import 'package:equatable/equatable.dart';

abstract class ItemEvent extends Equatable {
  const ItemEvent();
  @override
  List<Object?> get props => [];
}

class LoadItems extends ItemEvent {
  final String userId;
  const LoadItems(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CreateItem extends ItemEvent {
  final String name;
  const CreateItem(this.name);
  @override
  List<Object?> get props => [name];
}

class DeleteItem extends ItemEvent {
  final String id;
  const DeleteItem(this.id);
  @override
  List<Object?> get props => [id];
}
```

---

## 8️⃣ BLoC State

```dart
import 'package:equatable/equatable.dart';

abstract class ItemState extends Equatable {
  const ItemState();
  @override
  List<Object?> get props => [];
}

class ItemInitial extends ItemState {}

class ItemLoading extends ItemState {}

class ItemLoaded extends ItemState {
  final List<ItemEntity> items;
  const ItemLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class ItemError extends ItemState {
  final String message;
  const ItemError(this.message);
  @override
  List<Object?> get props => [message];
}
```

---

## 9️⃣ BLoC

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  final GetItems _getItems;
  final CreateItem _createItem;
  final DeleteItem _deleteItem;

  ItemBloc({
    required GetItems getItems,
    required CreateItem createItem,
    required DeleteItem deleteItem,
  })  : _getItems = getItems,
        _createItem = createItem,
        _deleteItem = deleteItem,
        super(ItemInitial()) {
    on<LoadItems>(_onLoad);
    on<CreateItem>(_onCreate);
    on<DeleteItem>(_onDelete);
  }

  Future<void> _onLoad(LoadItems event, Emitter<ItemState> emit) async {
    emit(ItemLoading());
    final result = await _getItems(event.userId);
    result.fold(
      (failure) => emit(ItemError(failure.message)),
      (items) => emit(ItemLoaded(items)),
    );
  }

  Future<void> _onCreate(CreateItem event, Emitter<ItemState> emit) async {
    // 구현
  }

  Future<void> _onDelete(DeleteItem event, Emitter<ItemState> emit) async {
    // 구현
  }
}
```

---

## 🔟 Page (기본)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

class ItemPage extends BasePage {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends BasePageState<ItemPage> {
  @override
  void loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ItemBloc>().add(LoadItems(authState.user.id));
    }
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '아이템',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: loadInitialData,
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<ItemBloc, ItemState>(
      builder: (context, state) {
        if (state is ItemLoading) {
          return const CommonLoadingWidget();
        }
        if (state is ItemError) {
          return CommonErrorWidget(
            message: state.message,
            onRetry: loadInitialData,
          );
        }
        if (state is ItemLoaded) {
          if (state.items.isEmpty) {
            return const CommonEmptyWidget(
              icon: Icons.inbox,
              message: '아이템이 없습니다',
            );
          }
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ListTile(title: Text(item.name));
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

---

## 🔟+1 Page (탭 있는 경우)

```dart
class TabbedPage extends BasePage {
  const TabbedPage({super.key});

  @override
  State<TabbedPage> createState() => _TabbedPageState();
}

class _TabbedPageState extends BasePageState<TabbedPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  @override
  int get tabCount => 3;

  @override
  List<String> get tabLabels => ['탭1', '탭2', '탭3'];

  @override
  List<Widget> get tabViews => [
    _buildTab1(),
    _buildTab2(),
    _buildTab3(),
  ];

  @override
  void loadInitialData() {
    // 데이터 로드
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '탭 페이지',
      bottom: buildTabBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildTabBarView();
  }

  Widget _buildTab1() => const Center(child: Text('탭 1'));
  Widget _buildTab2() => const Center(child: Text('탭 2'));
  Widget _buildTab3() => const Center(child: Text('탭 3'));
}
```

---

## 🔟+2 DI 등록

```dart
// lib/core/di/injection.dart에 추가

// DataSource
sl.registerLazySingleton(() => FirestoreItemDataSource(sl()));

// Repository
sl.registerLazySingleton<ItemRepository>(() => ItemRepositoryImpl(sl()));

// UseCases
sl.registerLazySingleton(() => GetItems(sl()));
sl.registerLazySingleton(() => CreateItem(sl()));
sl.registerLazySingleton(() => DeleteItem(sl()));

// BLoC
sl.registerFactory(() => ItemBloc(
  getItems: sl(),
  createItem: sl(),
  deleteItem: sl(),
));
```

```dart
// lib/main.dart의 MultiBlocProvider에 추가

BlocProvider<ItemBloc>(
  create: (_) => sl<ItemBloc>(),
),
```

---

## 🔟+3 제작 아이템 추가

### 통나무 아이템

```dart
// lib/features/craft/domain/entities/item_recipes.dart
// headItems, bodyItems, legsItems 리스트에 추가

const ItemEntity(
  id: 'head_unique_id',        // 유니크 ID (접두사: head_, body_, legs_)
  name: '아이템 이름',
  description: '아이템 설명',
  category: ItemCategory.clothing,
  clothingSlot: ClothingSlot.head,  // head, body, legs
  woodCost: 100,               // 통나무 비용
  iconEmoji: '🎩',             // 이모지 아이콘
  estimatedDays: 7,            // 예상 획득 기간
),
```

### 쇠 아이템

```dart
// lib/features/craft/domain/entities/item_recipes.dart
// ironHeadItems, ironBodyItems, ironLegsItems 리스트에 추가

const ItemEntity(
  id: 'iron_head_unique_id',   // 접두사: iron_head_, iron_body_, iron_legs_
  name: '아이템 이름',
  description: '아이템 설명',
  category: ItemCategory.clothing,
  clothingSlot: ClothingSlot.head,
  ironCost: 100,               // 쇠 비용 (woodCost 대신)
  iconEmoji: '⛑️',
  estimatedDays: 10,
),
```

### 픽셀아트 렌더링 (선택)

```dart
// lib/features/craft/presentation/widgets/character_painter.dart
// _drawEquippedItems 메서드에 추가

case 'new_item_id':
  _drawNewItem(canvas, size);
  break;

void _drawNewItem(Canvas canvas, Size size) {
  final pixelSize = size.width / 16;
  // 픽셀 그리기 로직
  _drawPixel(canvas, x, y, pixelSize, color);
}
```

---

## 🔟+4 챌린지 타입 확장

### 새 챌린지 타입 추가

```dart
// lib/features/log_run/domain/entities/log_run_challenge_entity.dart

enum LogRunChallengeType {
  running,           // 달리기 → 통나무
  strengthTraining,  // 헬스 → 쇠
  newType,          // 새 타입 → 새 재화
}

extension LogRunChallengeTypeExtension on LogRunChallengeType {
  String get displayName {
    switch (this) {
      case LogRunChallengeType.running:
        return '달리기';
      case LogRunChallengeType.strengthTraining:
        return '헬스';
      case LogRunChallengeType.newType:
        return '새 타입';
    }
  }

  String get emoji {
    switch (this) {
      case LogRunChallengeType.running:
        return '🏃';
      case LogRunChallengeType.strengthTraining:
        return '🏋️';
      case LogRunChallengeType.newType:
        return '🆕';
    }
  }
}
```

---

_v2.0 | 2026-01-01_

