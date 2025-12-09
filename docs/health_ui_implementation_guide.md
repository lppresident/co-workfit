# Health UI Implementation Guide

**Version:** 1.0
**Date:** 2025-12-09

---

## Overview

This guide provides step-by-step instructions for implementing the UI layer that consumes the refactored HealthBloc state machine.

---

## Architecture Overview

```
┌─────────────────────────────────────┐
│         DashboardPage               │
│  (AppLifecycleState Observer)      │
└─────────────────────────────────────┘
                  │
                  │ BlocProvider
                  ▼
┌─────────────────────────────────────┐
│          HealthBloc                 │
│    (State Machine Controller)       │
└─────────────────────────────────────┘
                  │
                  │ State Stream
                  ▼
┌─────────────────────────────────────┐
│       BlocBuilder/BlocConsumer      │
│   (State-based UI Rendering)        │
└─────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌─────────────┐     ┌─────────────┐
│ iOS Widgets │     │ Android     │
│             │     │ Widgets     │
└─────────────┘     └─────────────┘
```

---

## Step 1: Update DashboardPage

### 1.1 Add AppLifecycleState Observer

The dashboard page must observe app lifecycle to detect background→foreground transitions.

```dart
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize health state on first launch
    context.read<HealthBloc>().add(const HealthInitializeEvent());
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App returned from background → Trigger state comparison
      context.read<HealthBloc>().add(const HealthAppResumedEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
}
```

### 1.2 Build AppBar with Refresh Button

```dart
PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: const Text('Co-WorkFit'),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          // Trigger manual refresh
          context.read<HealthBloc>().add(
            const HealthRefreshEvent(days: 7),
          );
        },
        tooltip: 'Refresh',
      ),
      IconButton(
        icon: const Icon(Icons.person),
        onPressed: () {
          // Navigate to profile
        },
        tooltip: 'Profile',
      ),
    ],
  );
}
```

### 1.3 Build Body with BlocConsumer

```dart
Widget _buildBody() {
  return BlocConsumer<HealthBloc, HealthBlocState>(
    // Listener for side effects (dialogs, snackbars)
    listener: (context, state) {
      if (state is HealthBlocError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthRefreshEvent(),
                );
              },
            ),
          ),
        );
      }
    },

    // Builder for main UI
    builder: (context, state) {
      return _buildStateBasedUI(context, state);
    },
  );
}
```

---

## Step 2: State-Based UI Rendering

### 2.1 Main UI Switch

```dart
Widget _buildStateBasedUI(BuildContext context, HealthBlocState state) {
  switch (state.uiState) {
    case HealthUIState.initial:
      return const Center(child: Text('Welcome to Co-WorkFit'));

    case HealthUIState.loading:
      return const Center(child: CircularProgressIndicator());

    case HealthUIState.iosPermissionRequired:
    case HealthUIState.iosWorkoutEmpty:
      return IOSPermissionCard(state: state);

    case HealthUIState.androidHCNotInstalled:
      return AndroidInstallCard(state: state);

    case HealthUIState.androidPermissionRequired:
      return AndroidPermissionCard(state: state);

    case HealthUIState.androidWorkoutEmpty:
      return AndroidEmptyCard();

    case HealthUIState.workoutLoaded:
      return WorkoutLoadedView(state: state);

    case HealthUIState.error:
      return ErrorCard(state: state);
  }
}
```

---

## Step 3: iOS-Specific Widgets

### 3.1 IOSPermissionCard

```dart
class IOSPermissionCard extends StatelessWidget {
  final HealthBlocState state;

  const IOSPermissionCard({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                size: 60,
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'HealthKit Access Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Co-WorkFit needs access to your HealthKit data to track your workouts and calculate your fitness score.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Button
            ElevatedButton.icon(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthOpenIOSHealthAppEvent(),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Health Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Secondary button
            TextButton(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthRefreshEvent(),
                );
              },
              child: const Text('I\'ve granted permission'),
            ),

            const SizedBox(height: 32),

            // Empty state message (if applicable)
            if (state.uiState == HealthUIState.iosWorkoutEmpty)
              Text(
                'No workout data found. Start a workout to see your data here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 4: Android-Specific Widgets

### 4.1 AndroidInstallCard

```dart
class AndroidInstallCard extends StatelessWidget {
  final HealthBlocState state;

  const AndroidInstallCard({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download,
                size: 60,
                color: Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Health Connect Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Install Health Connect to sync data from Google Fit, Samsung Health, Garmin, and other fitness apps.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Install button
            ElevatedButton.icon(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthInstallHealthConnectEvent(),
                );
              },
              icon: const Icon(Icons.shop),
              label: const Text('Install Health Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Refresh button
            TextButton(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthRefreshEvent(),
                );
              },
              child: const Text('I\'ve installed it'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 AndroidPermissionCard

```dart
class AndroidPermissionCard extends StatelessWidget {
  final HealthBlocState state;

  const AndroidPermissionCard({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open,
                size: 60,
                color: Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Permission Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Grant Co-WorkFit access to read your workout data from Health Connect.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Grant button
            ElevatedButton.icon(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthRequestPermissionEvent(),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings button (alternative)
            TextButton.icon(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthOpenSettingsEvent(),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.3 AndroidEmptyCard

```dart
class AndroidEmptyCard extends StatelessWidget {
  const AndroidEmptyCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'No Workout Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Start a workout or connect a fitness app like Google Fit or Samsung Health to see your data here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Refresh button
            OutlinedButton.icon(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthRefreshEvent(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 5: Workout Loaded View

### 5.1 WorkoutLoadedView

```dart
class WorkoutLoadedView extends StatelessWidget {
  final HealthBlocState state;

  const WorkoutLoadedView({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HealthBloc>().add(
          const HealthRefreshEvent(),
        );

        // Wait for loading to complete
        await context.read<HealthBloc>().stream.firstWhere(
          (state) => !state.isLoading,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary card
          _buildSummaryCard(context),

          const SizedBox(height: 16),

          // Section title
          Text(
            'Recent Workouts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Workout list
          ...state.workouts.map((workout) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: WorkoutListItem(workout: workout),
            );
          }).toList(),

          // Empty space for scrolling
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.star,
                  'Score',
                  state.totalScore.toString(),
                  Colors.amber,
                ),
                _buildStatItem(
                  context,
                  Icons.local_fire_department,
                  'Calories',
                  state.totalCalories.toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  Icons.timer,
                  'Minutes',
                  state.totalDurationMinutes.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
```

---

## Step 6: Error Card

```dart
class ErrorCard extends StatelessWidget {
  final HealthBlocState state;

  const ErrorCard({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),

            const SizedBox(height: 24),

            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              state.errorMessage ?? 'An unexpected error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () {
                context.read<HealthBloc>().add(
                  const HealthRefreshEvent(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 7: Dependency Injection Setup

### 7.1 Update injection.dart

```dart
// Add new dependencies
void _setupHealthFeature() {
  // Use Cases
  sl.registerLazySingleton(() => CheckHealthPermission(sl()));
  sl.registerLazySingleton(() => RequestHealthPermission(sl()));
  sl.registerLazySingleton(() => FetchWorkoutData(sl()));
  sl.registerLazySingleton(() => CheckHealthConnectInstallation(sl()));

  // Repository
  sl.registerLazySingleton<HealthRepository>(
    () => HealthRepositoryImpl(
      healthKitDataSource: sl(),
      healthConnectDataSource: sl(),
      healthDataMapper: sl(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => HealthBloc(
      checkHealthPermission: sl(),
      requestHealthPermission: sl(),
      fetchWorkoutData: sl(),
      checkHealthConnectInstallation: sl(),
    ),
  );
}
```

### 7.2 Update main.dart

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HealthBloc>(
          create: (context) => sl<HealthBloc>(),
        ),
        // Other BLoCs...
      ],
      child: MaterialApp(
        title: 'Co-WorkFit',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const DashboardPage(),
      ),
    );
  }
}
```

---

## Step 8: Platform Detection Helper

### 8.1 Optional: Platform-aware helper methods

```dart
extension PlatformExtension on BuildContext {
  bool get isIOS => Platform.isIOS;
  bool get isAndroid => Platform.isAndroid;

  String get platformName => isIOS ? 'iOS' : 'Android';

  String get healthServiceName => isIOS
      ? 'HealthKit'
      : 'Health Connect';
}
```

---

## Testing Checklist

### Widget Tests

```dart
testWidgets('IOSPermissionCard displays correctly', (tester) async {
  final state = HealthBlocIOSPermissionRequired(
    authStatus: HealthAuthorizationStatus.denied,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: IOSPermissionCard(state: state),
      ),
    ),
  );

  expect(find.text('HealthKit Access Required'), findsOneWidget);
  expect(find.byIcon(Icons.settings), findsOneWidget);
});

testWidgets('AndroidInstallCard displays correctly', (tester) async {
  final state = HealthBlocAndroidHCNotInstalled();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AndroidInstallCard(state: state),
      ),
    ),
  );

  expect(find.text('Health Connect Required'), findsOneWidget);
  expect(find.text('Install Health Connect'), findsOneWidget);
});

testWidgets('WorkoutLoadedView displays workout list', (tester) async {
  final mockWorkouts = [
    WorkoutEntity(...), // Mock data
  ];

  final state = HealthBlocWorkoutLoaded(
    authStatus: HealthAuthorizationStatus.granted,
    workouts: mockWorkouts,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WorkoutLoadedView(state: state),
      ),
    ),
  );

  expect(find.text('Recent Workouts'), findsOneWidget);
  expect(find.byType(WorkoutListItem), findsNWidgets(mockWorkouts.length));
});
```

---

## Performance Considerations

1. **Avoid Unnecessary Rebuilds**
   - Use `BlocBuilder` with `buildWhen` to filter state changes
   - Example: Only rebuild workout list when workout data changes

2. **Lazy Loading**
   - Consider pagination for large workout lists
   - Implement virtual scrolling if needed

3. **Image Optimization**
   - Use cached network images for user avatars
   - Compress workout source badges

4. **State Comparison**
   - HealthState uses Equatable for efficient comparison
   - Prevents unnecessary widget rebuilds

---

## Accessibility

1. **Semantic Labels**
   ```dart
   Semantics(
     label: 'Refresh workouts',
     child: IconButton(...),
   )
   ```

2. **Screen Reader Support**
   - All interactive elements have labels
   - State changes announced

3. **Color Contrast**
   - Ensure text meets WCAG AA standards
   - Don't rely solely on color for information

---

## Localization (Future Enhancement)

```dart
// Using intl package
Text(
  AppLocalizations.of(context).healthKitAccessRequired,
  ...
)
```

---

**End of UI Implementation Guide**
