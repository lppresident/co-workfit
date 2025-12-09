# Health Permission System - Quick Reference

**Version:** 1.0
**Date:** 2025-12-09

Quick reference guide for developers working with the refactored health permission system.

---

## 🚀 Quick Start

### Initialize on App Launch

```dart
@override
void initState() {
  super.initState();
  context.read<HealthBloc>().add(const HealthInitializeEvent());
}
```

### Add Lifecycle Observer

```dart
class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HealthBloc>().add(const HealthAppResumedEvent());
    }
  }
}
```

---

## 📋 Available Events

```dart
// Initialize system
HealthInitializeEvent()

// Check current permission status
HealthCheckPermissionEvent()

// Request permissions from user
HealthRequestPermissionEvent()

// Fetch workout data for date range
HealthFetchWorkoutDataEvent(
  startDate: startDate,
  endDate: endDate,
)

// Manual refresh (always re-runs full flow)
HealthRefreshEvent(days: 7)

// App returned from background
HealthAppResumedEvent()

// Android: Install Health Connect
HealthInstallHealthConnectEvent()

// Android: Open Health Connect settings
HealthOpenSettingsEvent()

// iOS: Open Health app
HealthOpenIOSHealthAppEvent()

// Clear error state
HealthClearErrorEvent()
```

---

## 🎨 UI State Handling

### State-Based Rendering

```dart
Widget build(BuildContext context) {
  return BlocBuilder<HealthBloc, HealthBlocState>(
    builder: (context, state) {
      switch (state.uiState) {
        case HealthUIState.loading:
          return const CircularProgressIndicator();

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

        default:
          return const SizedBox();
      }
    },
  );
}
```

### State Properties

```dart
// Access UI state
state.uiState

// Access authorization status
state.authorizationStatus

// Access installation status (Android)
state.installStatus

// Check if has data
state.hasWorkoutData

// Get error message
state.errorMessage

// Get workout count
state.workoutCount

// Access workout list
state.workouts

// Get computed statistics
state.totalScore
state.totalCalories
state.totalDurationMinutes

// Convenience checks
state.isLoading
state.isError
state.isShowingWorkouts
state.isPermissionRequired
```

---

## 🔧 Common Operations

### Manual Refresh

```dart
ElevatedButton(
  onPressed: () {
    context.read<HealthBloc>().add(
      const HealthRefreshEvent(days: 7),
    );
  },
  child: const Text('Refresh'),
)
```

### Request Permission

```dart
ElevatedButton(
  onPressed: () {
    context.read<HealthBloc>().add(
      const HealthRequestPermissionEvent(),
    );
  },
  child: const Text('Grant Permission'),
)
```

### Open Settings (iOS)

```dart
TextButton(
  onPressed: () {
    context.read<HealthBloc>().add(
      const HealthOpenIOSHealthAppEvent(),
    );
  },
  child: const Text('Open Health Settings'),
)
```

### Install Health Connect (Android)

```dart
ElevatedButton(
  onPressed: () {
    context.read<HealthBloc>().add(
      const HealthInstallHealthConnectEvent(),
    );
  },
  child: const Text('Install Health Connect'),
)
```

---

## 🧪 Testing

### Mock States for Testing

```dart
// iOS Permission Required
final mockState1 = HealthBlocIOSWorkoutEmpty(
  authStatus: HealthAuthorizationStatus.denied,
);

// Android HC Not Installed
final mockState2 = HealthBlocAndroidHCNotInstalled();

// Android Permission Required
final mockState3 = HealthBlocAndroidPermissionRequired();

// Workout Loaded
final mockState4 = HealthBlocWorkoutLoaded(
  authStatus: HealthAuthorizationStatus.granted,
  installStatus: HealthConnectInstallStatus.installed,
  workouts: mockWorkouts,
);

// Error State
final mockState5 = HealthBlocError(
  message: 'Test error',
  authStatus: HealthAuthorizationStatus.unknown,
);
```

### Widget Test Example

```dart
testWidgets('Shows loading indicator', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<HealthBloc>(
        create: (_) => mockHealthBloc,
        child: DashboardPage(),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## 🐛 Debugging

### Enable Logging

```dart
// In HealthBloc
print('[HealthBloc] Current state: $state');
print('[HealthBloc] Event: $event');

// In Repository
print('[HealthRepo] Fetching data: $startDate to $endDate');
print('[HealthRepo] Platform: ${Platform.isIOS ? "iOS" : "Android"}');
```

### Check State Transitions

```dart
BlocProvider<HealthBloc>(
  create: (_) => HealthBloc(...)
    ..stream.listen((state) {
      print('State changed: ${state.uiState}');
    }),
  child: ...,
)
```

---

## ⚠️ Common Issues

### Issue: State not updating after BG→FG

**Solution:** Make sure AppLifecycleState observer is properly registered:
```dart
WidgetsBinding.instance.addObserver(this);
```

### Issue: iOS always shows permission UI even with permission

**Solution:** This is correct! iOS cannot distinguish empty data from no permission.

### Issue: Android shows permission UI but permission was granted

**Solution:** Check if Health Connect is actually installed:
```dart
await _checkHealthConnectInstallation();
```

### Issue: Refresh button doesn't work

**Solution:** Make sure event is dispatched correctly:
```dart
context.read<HealthBloc>().add(const HealthRefreshEvent());
```

---

## 📱 Platform-Specific Notes

### iOS

✅ **DO:**
- Always show permission guidance if data is empty
- Use HealthKit permission dialog
- Handle all authorization states

❌ **DON'T:**
- Try to explicitly check permission status (not possible)
- Assume empty data means no permission
- Force permission revocation

### Android

✅ **DO:**
- Check Health Connect installation first
- Use explicit permission checks
- Distinguish empty data from permission issues
- Support multiple data sources

❌ **DON'T:**
- Skip installation check
- Assume HC is always installed
- Show permission UI when data is just empty

---

## 🔍 State Enum Reference

```dart
enum HealthUIState {
  initial,                    // App just launched
  loading,                    // Operation in progress
  iosPermissionRequired,      // iOS: Show permission guide
  iosWorkoutEmpty,           // iOS: Empty + permission guide
  androidHCNotInstalled,      // Android: HC not installed
  androidPermissionRequired,  // Android: Permissions needed
  androidWorkoutEmpty,        // Android: Just empty (perms OK)
  workoutLoaded,             // Success - show workouts
  error,                     // Error occurred
}

enum HealthAuthorizationStatus {
  notDetermined,  // iOS: Never requested
  denied,         // User denied or no permissions
  granted,        // All permissions granted
  unknown,        // Cannot determine
}

enum HealthConnectInstallStatus {
  installed,      // HC app is installed
  notInstalled,   // HC app not installed
  unknown,        // Cannot determine
}
```

---

## 📚 File Locations

### Domain Layer
```
lib/features/workout/domain/
├── entities/
│   ├── health_state.dart          # Core state definitions
│   └── health_event.dart          # Event definitions
├── repositories/
│   └── health_repository.dart     # Repository interface
└── usecases/
    ├── check_health_permission.dart
    ├── request_health_permission.dart
    ├── fetch_workout_data.dart
    └── check_health_connect_installation.dart
```

### Presentation Layer
```
lib/features/workout/presentation/
└── bloc/
    ├── health_bloc.dart           # Main BLoC
    └── health_bloc_state.dart     # BLoC states
```

### Data Layer
```
lib/features/workout/data/
├── repositories/
│   └── health_repository_impl.dart  # Repository implementation
└── datasources/
    ├── health_kit_datasource.dart   # iOS
    └── health_connect_datasource.dart # Android
```

---

## 🎯 Best Practices

1. **Always handle all states**
   ```dart
   switch (state.uiState) {
     case HealthUIState.loading:
       // Handle loading
     case HealthUIState.error:
       // Handle error
     // ... handle ALL states
   }
   ```

2. **Use BlocConsumer for side effects**
   ```dart
   BlocConsumer<HealthBloc, HealthBlocState>(
     listener: (context, state) {
       if (state.isError) {
         ScaffoldMessenger.of(context).showSnackBar(...);
       }
     },
     builder: (context, state) => ...,
   )
   ```

3. **Dispatch events, don't access repository directly**
   ```dart
   // ✅ Correct
   context.read<HealthBloc>().add(HealthRefreshEvent());

   // ❌ Wrong
   await repository.fetchWorkoutData();
   ```

4. **Let BLoC manage state**
   ```dart
   // ✅ Correct - BLoC manages state
   BlocBuilder<HealthBloc, HealthBlocState>(...)

   // ❌ Wrong - Manual state management
   StatefulWidget with manual state variables
   ```

---

## 📖 Further Reading

- **Main Specification:** `docs/health_permission_refactoring.md`
- **Test Scenarios:** `docs/health_test_scenarios.md`
- **UI Guide:** `docs/health_ui_implementation_guide.md`
- **State Diagrams:** `docs/health_state_machine_diagrams.md`
- **Summary:** `docs/health_refactoring_summary.md`

---

**Quick Reference Version:** 1.0
**Last Updated:** 2025-12-09
