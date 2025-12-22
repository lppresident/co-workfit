# UI Structure Guide

Co-WorkFit의 일관된 UI 구조를 위한 가이드입니다.

## 🏗️ UI Architecture Principles

### 1. **일관성 (Consistency)**
- 모든 페이지는 동일한 패턴을 따름
- 동일한 상황에 동일한 UI 컴포넌트 사용
- 예측 가능한 사용자 경험

### 2. **재사용성 (Reusability)**
- 공통 컴포넌트 최대한 활용
- Mixin을 통한 기능 공유
- 중복 코드 최소화

### 3. **확장성 (Scalability)**
- 새로운 페이지 추가가 쉬움
- Base 클래스를 통한 표준화
- 변경사항이 전체에 자동 반영

## 📦 Core Components

### BasePage & BasePageState

모든 페이지의 기본 구조를 제공합니다.

```dart
class MyPage extends BasePage {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends BasePageState<MyPage> {
  @override
  void loadInitialData() {
    // 데이터 로드 (WidgetsBinding.addPostFrameCallback 자동 처리)
    context.read<MyBloc>().add(LoadDataEvent());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'My Page',
      actions: [/* AppBar actions */],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        // UI 구성
      },
    );
  }
}
```

**주요 기능**:
- `loadInitialData()`: 안전한 초기 데이터 로딩 (자동으로 addPostFrameCallback 처리)
- `buildAppBar()`: AppBar 구성
- `buildBody()`: Body 컨텐츠
- `buildFloatingActionButton()`: FAB (optional)
- `buildBottomNavigationBar()`: Bottom Nav (optional)

### StandardAppBar

일관된 AppBar 디자인을 제공합니다.

```dart
StandardAppBar(
  title: '페이지 제목',
  actions: [
    AppBarActions.refresh(() => _refresh()),
    AppBarActions.filter(() => _openFilter()),
  ],
  bottom: TabBar(...), // optional
)
```

**제공하는 공통 액션**:
- `AppBarActions.refresh()` - 새로고침
- `AppBarActions.filter()` - 필터
- `AppBarActions.sort()` - 정렬
- `AppBarActions.search()` - 검색
- `AppBarActions.settings()` - 설정
- `AppBarActions.menu()` - 팝업 메뉴

## 🎭 Mixins

페이지에서 자주 사용하는 패턴을 Mixin으로 제공합니다.

### TabbedMixin

TabBar를 사용하는 페이지에 적용합니다.

```dart
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {

  @override
  int get tabCount => 3;

  @override
  List<String> get tabLabels => ['탭1', '탭2', '탭3'];

  @override
  List<Widget> get tabViews => [Tab1Widget(), Tab2Widget(), Tab3Widget()];

  @override
  void onTabChanged(int index) {
    // 탭 변경 시 동작
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'Tabbed Page',
      bottom: buildTabBar(), // TabbedMixin 제공
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildTabBarView(); // TabbedMixin 제공
  }
}
```

**자동 처리**:
- TabController 생성 및 dispose
- TabBar / TabBarView 구성
- Tab 변경 이벤트 처리

### RefreshableMixin

Pull-to-refresh 기능을 제공합니다.

```dart
class _MyPageState extends BasePageState<MyPage> with RefreshableMixin {

  @override
  Future<void> onRefresh() async {
    // 새로고침 로직
    context.read<MyBloc>().add(RefreshEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildRefreshableContent(
      child: ListView(...),
    );
  }
}
```

**기능**:
- RefreshIndicator 자동 적용
- 중복 새로고침 방지
- 로딩 상태 자동 관리

### LoadableMixin

로딩/에러/빈 상태 UI를 제공합니다.

```dart
class _MyPageState extends BasePageState<MyPage> with LoadableMixin {

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<MyBloc, MyState>(
      builder: (context, state) {
        return handleStates<MyState>(
          state: state,
          isLoading: (s) => s is MyLoading,
          isError: (s) => s is MyError,
          isEmpty: (s) => s is MyLoaded && s.items.isEmpty,
          getErrorMessage: (s) => (s as MyError).message,
          buildContent: (s) => _buildList((s as MyLoaded).items),
          loadingMessage: 'Loading data...',
          emptyMessage: 'No data available',
          emptyIcon: Icons.inbox,
          onRetry: () => context.read<MyBloc>().add(LoadEvent()),
        );
      },
    );
  }
}
```

**제공하는 위젯**:
- `buildLoadingState()` - 로딩 UI
- `buildErrorState()` - 에러 UI (재시도 포함)
- `buildEmptyState()` - 빈 상태 UI
- `handleStates()` - 통합 상태 처리

## 📐 Page Structure Patterns

### Pattern 1: Simple Page (단순 페이지)

```dart
class SimplePage extends BasePage {
  @override
  State<SimplePage> createState() => _SimplePageState();
}

class _SimplePageState extends BasePageState<SimplePage> {
  @override
  void loadInitialData() {
    context.read<SimpleBloc>().add(LoadData());
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'Simple Page',
      actions: [AppBarActions.refresh(() => loadInitialData())],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<SimpleBloc, SimpleState>(
      builder: (context, state) {
        if (state is SimpleLoading) {
          return const CommonLoadingWidget();
        }
        if (state is SimpleLoaded) {
          return ListView(...);
        }
        return const SizedBox();
      },
    );
  }
}
```

**사용처**: 단일 화면, 간단한 목록

### Pattern 2: Tabbed Page (탭 페이지)

```dart
class TabbedPage extends BasePage {
  @override
  State<TabbedPage> createState() => _TabbedPageState();
}

class _TabbedPageState extends BasePageState<TabbedPage>
    with SingleTickerProviderStateMixin, TabbedMixin {

  @override
  int get tabCount => 2;

  @override
  List<String> get tabLabels => ['Tab 1', 'Tab 2'];

  @override
  List<Widget> get tabViews => [Tab1Widget(), Tab2Widget()];

  @override
  void loadInitialData() {
    // Load data for all tabs
  }

  @override
  void onTabChanged(int index) {
    // Reload data for current tab if needed
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
    return BlocListener<TabbedBloc, TabbedState>(
      listener: (context, state) {
        // Handle side effects (SnackBar, etc.)
      },
      child: buildTabBarView(),
    );
  }
}
```

**사용처**: 여러 카테고리, 다중 뷰

**Examples**: FriendsPage (4 tabs), LeaderboardPage (2 tabs)

### Pattern 3: Refreshable List Page (새로고침 가능한 목록)

```dart
class RefreshableListPage extends BasePage {
  @override
  State<RefreshableListPage> createState() => _RefreshableListPageState();
}

class _RefreshableListPageState extends BasePageState<RefreshableListPage>
    with RefreshableMixin, LoadableMixin {

  @override
  void loadInitialData() {
    context.read<ListBloc>().add(LoadList());
  }

  @override
  Future<void> onRefresh() async {
    context.read<ListBloc>().add(RefreshList());
    // Wait for new state
    await context.read<ListBloc>().stream.firstWhere(
      (state) => state is! ListLoading,
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: 'List Page',
      actions: [
        AppBarActions.filter(() => _showFilterDialog()),
        AppBarActions.sort(() => _showSortMenu()),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<ListBloc, ListState>(
      builder: (context, state) {
        return buildRefreshableContent(
          child: handleStates(
            state: state,
            isLoading: (s) => s is ListLoading,
            isError: (s) => s is ListError,
            isEmpty: (s) => s is ListLoaded && s.items.isEmpty,
            getErrorMessage: (s) => (s as ListError).message,
            buildContent: (s) => ListView.builder(
              itemCount: (s as ListLoaded).items.length,
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

**사용처**: 데이터 목록, Pull-to-refresh 필요

## 🎨 Common UI Components

### 1. Loading States

```dart
// Simple loading
const CommonLoadingWidget()

// Loading with message
const CommonLoadingWidget(message: 'Loading data...')
```

### 2. Error States

```dart
CommonErrorWidget(
  message: 'Failed to load data',
  onRetry: () => _retry(),
)
```

### 3. Empty States

```dart
const CommonEmptyWidget(
  icon: Icons.inbox,
  message: 'No data available',
  actionText: 'Add New',
  onAction: () => _addNew(),
)
```

### 4. Cards & Lists

```dart
Card(
  margin: const EdgeInsets.symmetric(
    horizontal: AppConstants.defaultPadding,
    vertical: 8,
  ),
  child: ListTile(...),
)
```

## 📝 Best Practices

### DO ✅

1. **항상 BasePage를 상속**
```dart
class MyPage extends BasePage {
  // ✅ Good
}
```

2. **loadInitialData() 사용**
```dart
@override
void loadInitialData() {
  // ✅ Good - 안전하게 BLoC 접근
  context.read<MyBloc>().add(LoadEvent());
}
```

3. **Common widgets 사용**
```dart
// ✅ Good
const CommonLoadingWidget()

// ❌ Bad
const Center(child: CircularProgressIndicator())
```

4. **StandardAppBar 사용**
```dart
// ✅ Good
StandardAppBar(
  title: 'My Page',
  actions: [AppBarActions.refresh(onRefresh)],
)

// ❌ Bad
AppBar(
  title: const Text('My Page'),
  actions: [IconButton(...)],
)
```

5. **Mixin 활용**
```dart
// ✅ Good - TabbedMixin for tabs
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  // Automatic TabController management
}
```

### DON'T ❌

1. **initState에서 직접 BLoC 접근하지 않기**
```dart
// ❌ Bad
@override
void initState() {
  super.initState();
  context.read<MyBloc>().add(LoadEvent()); // Risky!
}

// ✅ Good
@override
void loadInitialData() {
  context.read<MyBloc>().add(LoadEvent()); // Safe
}
```

2. **수동으로 TabController 관리하지 않기**
```dart
// ❌ Bad
late TabController _tabController;

@override
void initState() {
  _tabController = TabController(...);
}

// ✅ Good - Use TabbedMixin
class _MyPageState extends BasePageState<MyPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  // Automatic!
}
```

3. **커스텀 로딩/에러 UI 만들지 않기**
```dart
// ❌ Bad
Center(
  child: Column(
    children: [
      const Icon(Icons.error),
      Text(error.message),
      ElevatedButton(...),
    ],
  ),
)

// ✅ Good
CommonErrorWidget(
  message: error.message,
  onRetry: onRetry,
)
```

## 🚀 Quick Reference

### 페이지 타입별 템플릿

| 페이지 타입 | Base Class | Mixins | 예제 |
|------------|-----------|--------|------|
| **단순 페이지** | `BasePage` | - | 상세 페이지, 설정 |
| **탭 페이지** | `BasePage` | `TabbedMixin` | FriendsPage, LeaderboardPage |
| **목록 페이지** | `BasePage` | `RefreshableMixin`, `LoadableMixin` | WorkoutListPage |
| **폼 페이지** | `BasePage` | - | LoginPage, SignUpPage |

### Mixin 조합

```dart
// Tabs only
with SingleTickerProviderStateMixin, TabbedMixin

// Refresh only
with RefreshableMixin

// Loadable only
with LoadableMixin

// Tabs + Loadable
with SingleTickerProviderStateMixin, TabbedMixin, LoadableMixin

// Refresh + Loadable
with RefreshableMixin, LoadableMixin
```

## 📊 Migration Checklist

기존 페이지를 새 구조로 마이그레이션할 때:

- [ ] `extends StatefulWidget` → `extends BasePage`
- [ ] `State<MyPage>` → `BasePageState<MyPage>`
- [ ] `initState` 로직 → `loadInitialData()` 오버라이드
- [ ] `AppBar(...)` → `StandardAppBar(...)`
- [ ] `Scaffold` 제거 (BasePage에서 자동 제공)
- [ ] TabBar 사용 시 → `TabbedMixin` 추가
- [ ] RefreshIndicator 사용 시 → `RefreshableMixin` 추가
- [ ] 로딩/에러 UI → `LoadableMixin` 또는 Common widgets
- [ ] `flutter analyze` 실행하여 에러 확인

---

**Remember**: 일관성이 핵심입니다. 모든 페이지가 동일한 패턴을 따라야 유지보수가 쉽고 버그가 적습니다!
