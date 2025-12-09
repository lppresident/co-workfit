# Health Permission & Data Flow - Test Scenarios

**Version:** 1.0
**Date:** 2025-12-09

---

## Overview

This document defines comprehensive test scenarios for the refactored health permission and data loading system. All scenarios must pass to ensure correctness across iOS and Android platforms.

---

## iOS (HealthKit) Test Scenarios

### Scenario 1: First Launch - Permission Not Determined

**Initial State:**
- App never launched before
- HealthKit permission status: `notDetermined`
- No previous state stored

**Expected Flow:**
1. App launches → `HealthInitializeEvent` triggered
2. BLoC emits `HealthBlocLoading`
3. Check authorization → returns `notDetermined`
4. Request permission → Shows HealthKit permission dialog
5. User grants/denies permission
6. Fetch workout data (regardless of permission result)
7. Analyze result:
   - If empty → Emit `HealthBlocIOSWorkoutEmpty`
   - If has data → Emit `HealthBlocWorkoutLoaded`

**Expected UI:**
- Show loading indicator during steps 2-6
- If empty: Show permission guidance card + empty state message
- If has data: Show workout list

**State Persistence:**
- Store current authorization status

---

### Scenario 2: Permission Denied - Empty Data

**Initial State:**
- HealthKit permission previously denied
- Authorization status: `denied`
- No workout data available

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. BLoC emits `HealthBlocLoading`
3. Check authorization → returns `denied`
4. Skip permission request (already determined)
5. Fetch workout data → returns empty
6. Emit `HealthBlocIOSWorkoutEmpty`

**Expected UI:**
- Show permission guidance card with button to open Settings
- Show empty state illustration
- Message: "Allow Co-WorkFit to access HealthKit data"

**User Actions:**
- Tap "Open Settings" → Opens iOS Settings app
- User can manually grant permission in Settings
- When user returns → BG→FG flow triggers (Scenario 5)

---

### Scenario 3: Permission Granted - Has Data

**Initial State:**
- HealthKit permission granted
- Authorization status: `granted`
- Workout data exists in HealthKit

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. BLoC emits `HealthBlocLoading`
3. Check authorization → returns `granted`
4. Skip permission request (already granted)
5. Fetch workout data → returns workout entities
6. Calculate statistics (total score, calories, duration)
7. Emit `HealthBlocWorkoutLoaded` with workout list

**Expected UI:**
- Show loading indicator briefly
- Display workout list with:
  - Today's summary card
  - Individual workout items with details
  - Refresh button in app bar

**Data Validation:**
- All workouts have valid calibrated scores
- Calories, duration, distance displayed correctly
- Source badge shows "Apple Health"

---

### Scenario 4: Refresh Button - Empty Data

**Initial State:**
- Currently showing empty data with permission guidance
- State: `HealthBlocIOSWorkoutEmpty`

**Expected Flow:**
1. User taps refresh button → `HealthRefreshEvent(days: 7)`
2. BLoC emits `HealthBlocLoading`
3. Re-check authorization status
4. Re-fetch workout data
5. If still empty → Emit `HealthBlocIOSWorkoutEmpty`
6. If now has data → Emit `HealthBlocWorkoutLoaded`

**Expected UI:**
- Show loading indicator during refresh
- Update UI based on new state
- Do NOT use pull-to-refresh animation (manual button only)

**Notes:**
- Refresh always re-runs full flow
- Ignores previous state comparison
- User might have added workouts since last check

---

### Scenario 5: BG→FG - Permission Changed

**Initial State:**
- Previous authorization: `denied`
- Current authorization: `granted` (user changed in Settings)
- `previousAuthorizationStatus` stored

**Expected Flow:**
1. App returns from background → `HealthAppResumedEvent`
2. Check current authorization → returns `granted`
3. Compare with previous state → CHANGED
4. Auto-trigger refresh
5. BLoC emits `HealthBlocLoading`
6. Run full iOS flow (check permission → fetch data)
7. Emit appropriate state based on data

**Expected UI:**
- Automatic refresh without user action
- Smooth transition from permission UI to workout list
- Show loading indicator during refresh

**State Update:**
- Update `previousAuthorizationStatus` to `granted`

---

### Scenario 6: BG→FG - No Change

**Initial State:**
- Previous authorization: `granted`
- Current authorization: `granted`
- UI showing workout list

**Expected Flow:**
1. App returns from background → `HealthAppResumedEvent`
2. Check current authorization → returns `granted`
3. Compare with previous state → NO CHANGE
4. Skip refresh
5. Keep current state

**Expected UI:**
- No loading indicator shown
- UI remains stable (prevent flicker)
- Workout list stays as is

**Rationale:**
- Prevents unnecessary API calls
- Better UX (no screen flashing)
- Preserves scroll position

---

### Scenario 7: iOS - Permission Granted but Empty Data

**Initial State:**
- HealthKit permission granted
- Authorization status: `granted`
- No workout data in HealthKit (user hasn't exercised)

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. Check authorization → `granted`
3. Fetch workout data → returns empty array
4. Emit `HealthBlocIOSWorkoutEmpty`

**Expected UI:**
- Show permission guidance card (iOS policy: can't distinguish no-data from no-permission)
- Show empty state message
- Message: "Start a workout to see your data here"

**iOS Policy Reminder:**
- Even with permission granted, if data is empty, show permission guidance
- This is correct per Apple's privacy policy
- Cannot determine if empty is due to "never granted" vs "granted but no data"

---

## Android (Health Connect) Test Scenarios

### Scenario 8: First Launch - HC Not Installed

**Initial State:**
- Health Connect app not installed
- `previousInstallStatus`: null
- `previousAuthorizationStatus`: null

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. BLoC emits `HealthBlocLoading`
3. Check HC installation → returns `false`
4. Emit `HealthBlocAndroidHCNotInstalled`

**Expected UI:**
- Show installation guide card
- Message: "Health Connect Required"
- Description: "Install Health Connect to sync data from Google Fit, Samsung Health, and other apps"
- Button: "Install Health Connect"

**User Actions:**
- Tap button → Opens Play Store
- After installation → BG→FG flow (Scenario 15)

**State Persistence:**
- Store `installStatus: notInstalled`
- Store `authorizationStatus: unknown`

---

### Scenario 9: HC Installed - Permission Denied

**Initial State:**
- Health Connect app installed
- No permissions granted
- `installStatus: installed`
- `authorizationStatus: denied`

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. Check HC installation → returns `true`
3. Check permissions → returns `denied`
4. Emit `HealthBlocAndroidPermissionRequired`

**Expected UI:**
- Show permission request card
- Message: "Permission Required"
- Description: "Grant Co-WorkFit access to your workout data"
- Button: "Grant Permission"

**User Actions:**
- Tap button → Opens Health Connect permission screen
- User grants/denies permissions
- Returns to app → Re-check permissions

---

### Scenario 10: All Permissions Granted - Has Data

**Initial State:**
- Health Connect installed
- All required permissions granted
- Workout data exists

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. Check HC installation → returns `true`
3. Check permissions → returns `granted`
4. Fetch workout data → returns workout entities with source detection
5. Emit `HealthBlocWorkoutLoaded`

**Expected UI:**
- Show workout list
- Each workout has source badge:
  - "Google Fit"
  - "Samsung Health"
  - "Garmin"
  - etc.

**Data Validation:**
- Source detection works correctly
- Multiple sources can coexist
- No duplicate workouts within 5-minute window

---

### Scenario 11: All Permissions Granted - Empty Data

**Initial State:**
- Health Connect installed
- All permissions granted
- No workout data available

**Expected Flow:**
1. App launches → `HealthInitializeEvent`
2. Check HC installation → returns `true`
3. Check permissions → returns `granted`
4. Fetch workout data → returns empty array
5. Emit `HealthBlocAndroidWorkoutEmpty`

**Expected UI:**
- Show simple "No workout data" message
- NO permission guidance (permissions are OK)
- Message: "Start a workout or connect a fitness app"

**Key Difference from iOS:**
- Android can distinguish between permission issues and empty data
- Only show permission UI when actually needed
- Cleaner UX when permissions are fine

---

### Scenario 12: Refresh Button - Permission Required

**Initial State:**
- Currently showing permission required UI
- State: `HealthBlocAndroidPermissionRequired`

**Expected Flow:**
1. User taps refresh button → `HealthRefreshEvent`
2. BLoC emits `HealthBlocLoading`
3. Re-check HC installation → `true`
4. Re-check permissions → still `denied`
5. Emit `HealthBlocAndroidPermissionRequired` again

**Expected UI:**
- Brief loading indicator
- Return to permission request UI
- User can tap "Grant Permission" again

**Notes:**
- Refresh always re-checks full flow
- Useful if user thinks they granted permission but didn't

---

### Scenario 13: BG→FG - Permission Granted

**Initial State:**
- Previous: Permission denied
- Current: User granted permission in Health Connect settings
- `previousAuthorizationStatus: denied`

**Expected Flow:**
1. App returns from background → `HealthAppResumedEvent`
2. Check current authorization → `granted`
3. Compare with previous → CHANGED
4. Auto-trigger refresh
5. Check installation → `true`
6. Check permissions → `granted`
7. Fetch workout data
8. Emit appropriate state

**Expected UI:**
- Automatic refresh
- Transition from permission UI to workout list
- Show loading indicator during transition

**State Update:**
- Update `previousAuthorizationStatus` to `granted`

---

### Scenario 14: BG→FG - No Change

**Initial State:**
- Previous: All conditions met, showing workout list
- Current: Same state
- `previousInstallStatus: installed`
- `previousAuthorizationStatus: granted`

**Expected Flow:**
1. App returns from background → `HealthAppResumedEvent`
2. Check current installation → `installed`
3. Check current authorization → `granted`
4. Compare with previous → NO CHANGE
5. Skip refresh
6. Keep current state

**Expected UI:**
- No loading indicator
- UI remains stable
- Workout list preserved

---

### Scenario 15: BG→FG - HC Installed

**Initial State:**
- Previous: HC not installed
- Current: User installed HC from Play Store
- `previousInstallStatus: notInstalled`

**Expected Flow:**
1. App returns from background → `HealthAppResumedEvent`
2. Check current installation → `installed`
3. Compare with previous → CHANGED
4. Auto-trigger refresh
5. Check permissions → probably `denied` (new install)
6. Emit `HealthBlocAndroidPermissionRequired`

**Expected UI:**
- Automatic transition from install UI to permission UI
- Show loading briefly
- New UI prompts for permission

**State Update:**
- Update `previousInstallStatus` to `installed`
- Update `previousAuthorizationStatus` to `denied`

---

## Cross-Platform Test Scenarios

### Scenario 16: Error Handling - Network Timeout

**Platform:** Both iOS and Android

**Initial State:**
- Permissions granted
- Network/API timeout occurs during data fetch

**Expected Flow:**
1. Fetch workout data → Times out or throws exception
2. Catch error in repository
3. Return `Left(error message)`
4. Emit `HealthBlocError`

**Expected UI:**
- Show error message card
- Display retry button
- Message: "Failed to load workout data. Please try again."

**User Actions:**
- Tap retry → Triggers `HealthRefreshEvent`

---

### Scenario 17: State Persistence Across App Restarts

**Platform:** Both iOS and Android

**Test:**
1. Launch app → Store state in persistence
2. Kill app (swipe away)
3. Relaunch app
4. Should have `previousState == null`
5. Auto-refresh should trigger

**Expected:**
- State persistence is in-memory only (not stored to disk)
- Fresh launch always refreshes
- This is correct behavior

---

### Scenario 18: Multiple Rapid Refresh Attempts

**Platform:** Both iOS and Android

**Test:**
1. User taps refresh button multiple times rapidly
2. BLoC should handle gracefully

**Expected:**
- Only one refresh operation runs at a time
- Subsequent taps ignored while loading
- No duplicate API calls
- No race conditions

**Implementation Note:**
- BLoC should check if already loading before starting new operation

---

### Scenario 19: App in Background for Extended Time

**Platform:** Both iOS and Android

**Test:**
1. Launch app → Show workout data
2. Send app to background for > 1 hour
3. Return to foreground → `HealthAppResumedEvent`
4. State comparison logic executes

**Expected:**
- If state changed → Refresh
- If state same → Keep current data
- Works correctly even after long background time

---

### Scenario 20: Permission Revoked While App in Background

**Platform:** iOS only (Android uses HC app)

**Test:**
1. App showing workout list (permission granted)
2. User goes to iOS Settings → Revokes HealthKit permission
3. User returns to app → BG→FG event

**Expected Flow:**
1. Check current authorization → `denied`
2. Compare with previous (`granted`) → CHANGED
3. Auto-refresh
4. Fetch returns empty or error
5. Show `HealthBlocIOSWorkoutEmpty`

**Expected UI:**
- Smooth transition to permission guidance
- Inform user permission was revoked

---

## Mock Data for Testing

### iOS Mock Workouts

```dart
final mockIOSWorkouts = [
  WorkoutEntity(
    id: 'ios_running_001',
    userId: 'test_user',
    source: WorkoutSource.appleHealth,
    type: WorkoutType.running,
    startTime: DateTime.now().subtract(Duration(hours: 2)),
    endTime: DateTime.now().subtract(Duration(hours: 1)),
    durationMinutes: 60,
    distance: 10.5,
    calories: 650,
    averageHeartRate: 145,
    maxHeartRate: 170,
    calibratedWorkload: 75.0,
    calibratedScore: 75,
    createdAt: DateTime.now(),
  ),
  WorkoutEntity(
    id: 'ios_cycling_002',
    userId: 'test_user',
    source: WorkoutSource.appleHealth,
    type: WorkoutType.cycling,
    startTime: DateTime.now().subtract(Duration(days: 1, hours: 3)),
    endTime: DateTime.now().subtract(Duration(days: 1, hours: 2)),
    durationMinutes: 45,
    distance: 20.0,
    calories: 500,
    averageHeartRate: 135,
    maxHeartRate: 160,
    calibratedWorkload: 68.0,
    calibratedScore: 68,
    createdAt: DateTime.now(),
  ),
];
```

### Android Mock Workouts

```dart
final mockAndroidWorkouts = [
  WorkoutEntity(
    id: 'android_running_001',
    userId: 'test_user',
    source: WorkoutSource.googleFit,
    type: WorkoutType.running,
    startTime: DateTime.now().subtract(Duration(hours: 3)),
    endTime: DateTime.now().subtract(Duration(hours: 2)),
    durationMinutes: 45,
    distance: 8.0,
    calories: 550,
    averageHeartRate: 150,
    calibratedWorkload: 72.0,
    calibratedScore: 72,
    createdAt: DateTime.now(),
  ),
  WorkoutEntity(
    id: 'android_walking_002',
    userId: 'test_user',
    source: WorkoutSource.samsungHealth,
    type: WorkoutType.walking,
    startTime: DateTime.now().subtract(Duration(days: 1, hours: 5)),
    endTime: DateTime.now().subtract(Duration(days: 1, hours: 4)),
    durationMinutes: 30,
    distance: 3.5,
    calories: 200,
    averageHeartRate: 110,
    calibratedWorkload: 45.0,
    calibratedScore: 45,
    createdAt: DateTime.now(),
  ),
];
```

### Mock State Transitions

```dart
// Scenario 1: iOS First Launch
final scenario1States = [
  HealthBlocInitial(),
  HealthBlocLoading(),
  HealthBlocIOSWorkoutEmpty(authStatus: HealthAuthorizationStatus.granted),
];

// Scenario 8: Android HC Not Installed
final scenario8States = [
  HealthBlocInitial(),
  HealthBlocLoading(),
  HealthBlocAndroidHCNotInstalled(),
];

// Scenario 10: Android Success
final scenario10States = [
  HealthBlocInitial(),
  HealthBlocLoading(),
  HealthBlocWorkoutLoaded(
    authStatus: HealthAuthorizationStatus.granted,
    installStatus: HealthConnectInstallStatus.installed,
    workouts: mockAndroidWorkouts,
  ),
];
```

---

## Acceptance Criteria

### All Scenarios Must:

1. ✅ Follow the exact flow defined in specifications
2. ✅ Emit correct state transitions
3. ✅ Display appropriate UI for each state
4. ✅ Handle errors gracefully
5. ✅ Update state persistence correctly
6. ✅ Respect platform policies (iOS privacy, Android HC requirements)
7. ✅ Provide clear user guidance at every step
8. ✅ Support refresh without breaking state
9. ✅ Handle BG→FG transitions correctly
10. ✅ Avoid unnecessary refreshes (performance)

### Platform-Specific:

**iOS:**
- Always show permission guidance if data is empty
- Cannot distinguish "no permission" from "no data"
- Respect HealthKit privacy policy

**Android:**
- Check HC installation before permission
- Show installation UI if needed
- Distinguish empty data from permission issues
- Support multiple data sources with correct detection

---

## Test Execution Checklist

### Unit Tests
- [ ] HealthBloc state transitions for all scenarios
- [ ] HealthRepository method returns
- [ ] Use case implementations
- [ ] State persistence logic
- [ ] State comparison logic (BG→FG)

### Integration Tests
- [ ] iOS full flow (permission → data)
- [ ] Android full flow (installation → permission → data)
- [ ] BG→FG state comparison
- [ ] Refresh button functionality
- [ ] Error handling

### Widget Tests
- [ ] UI renders correctly for each state
- [ ] Buttons trigger correct events
- [ ] Loading indicators show/hide properly
- [ ] Platform-specific widgets display correctly

### Manual Tests
- [ ] Real device testing (iPhone & Android)
- [ ] Permission dialogs appear correctly
- [ ] Health Connect installation flow
- [ ] Data displays accurately
- [ ] Source badges correct
- [ ] BG→FG behavior verified
- [ ] Performance acceptable (no lag)

---

**End of Test Scenarios Document**
