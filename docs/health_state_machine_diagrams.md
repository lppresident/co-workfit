# Health State Machine - Visual Diagrams

**Version:** 1.0
**Date:** 2025-12-09

This document provides visual representations of the health permission and data state machines for iOS and Android.

---

## Complete State Machine Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      App Entry Points                           │
│  • App Launch  • Refresh Button  • Background→Foreground        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Platform Check │
                    └─────────────────┘
                    ↙                ↘
              iOS Flow            Android Flow
```

---

## iOS (HealthKit) Complete Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                         iOS HEALTHKIT FLOW                           │
└──────────────────────────────────────────────────────────────────────┘

    [App Start / Refresh / BG→FG]
                ↓
         ┌──────────┐
         │ LOADING  │ ← Show loading indicator
         └──────────┘
                ↓
    Check HealthKit Authorization
                ↓
    ┌─────────────────────────┐
    │ Authorization Status?   │
    └─────────────────────────┘
           /          \
          /            \
   notDetermined    determined
         │               │
         ↓               │
  ┌──────────────┐      │
  │   Request    │      │
  │  Permission  │      │
  └──────────────┘      │
         │               │
         └───────┬───────┘
                 ↓
        Fetch Workout Data
                 ↓
         ┌───────────────┐
         │  Data Empty?  │
         └───────────────┘
           /           \
          /             \
       Yes              No
        │                │
        ↓                ↓
┌──────────────────┐  ┌──────────────┐
│ IOS_WORKOUT_     │  │  WORKOUT_    │
│    EMPTY         │  │   LOADED     │
├──────────────────┤  ├──────────────┤
│ • Permission UI  │  │ • Show list  │
│ • Empty state    │  │ • Summary    │
│ • Settings btn   │  │ • Refresh    │
└──────────────────┘  └──────────────┘

NOTE: iOS cannot distinguish between "no data" and "no permission"
      when data is empty. Always show permission guidance.
```

---

## Android (Health Connect) Complete Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                    ANDROID HEALTH CONNECT FLOW                       │
└──────────────────────────────────────────────────────────────────────┘

    [App Start / Refresh / BG→FG]
                ↓
         ┌──────────┐
         │ LOADING  │ ← Show loading indicator
         └──────────┘
                ↓
  Check Health Connect Installation
                ↓
     ┌──────────────────────┐
     │  HC Installed?       │
     └──────────────────────┘
           /           \
          /             \
        No              Yes
         │               │
         ↓               ↓
┌────────────────────┐  Check Permissions
│ ANDROID_HC_NOT_    │         ↓
│   INSTALLED        │  ┌──────────────────┐
├────────────────────┤  │ All Permissions  │
│ • Install guide    │  │    Granted?      │
│ • Play Store btn   │  └──────────────────┘
└────────────────────┘      /          \
                           /            \
                         No             Yes
                          │              │
                          ↓              ↓
              ┌────────────────────┐  Fetch Workout Data
              │ ANDROID_PERM_      │         ↓
              │   REQUIRED         │  ┌──────────────┐
              ├────────────────────┤  │ Data Empty?  │
              │ • Permission UI    │  └──────────────┘
              │ • Grant btn        │      /        \
              └────────────────────┘     /          \
                                       Yes          No
                                        │            │
                                        ↓            ↓
                            ┌──────────────────┐  ┌──────────────┐
                            │ ANDROID_WORKOUT_ │  │  WORKOUT_    │
                            │     EMPTY        │  │   LOADED     │
                            ├──────────────────┤  ├──────────────┤
                            │ • Just empty msg │  │ • Show list  │
                            │ • No perm UI     │  │ • Sources    │
                            │ • Refresh btn    │  │ • Summary    │
                            └──────────────────┘  └──────────────┘

NOTE: Android CAN distinguish between permission issues and empty data.
      Only show permission UI when actually needed.
```

---

## Background-to-Foreground State Comparison

```
┌──────────────────────────────────────────────────────────────────────┐
│              BACKGROUND → FOREGROUND TRANSITION LOGIC                │
└──────────────────────────────────────────────────────────────────────┘

        App Returns from Background
                    ↓
        ┌───────────────────────┐
        │ Load Previous State   │
        │ from Persistence      │
        └───────────────────────┘
                    ↓
        ┌───────────────────────┐
        │ Get Current State     │
        │ • Authorization       │
        │ • Installation (AND)  │
        └───────────────────────┘
                    ↓
        ┌───────────────────────┐
        │ Previous State Null?  │
        └───────────────────────┘
            /              \
          Yes              No
           │                │
           ↓                ↓
      [REFRESH]    ┌───────────────────┐
                   │ States Different? │
                   └───────────────────┘
                       /            \
                     Yes            No
                      │              │
                      ↓              ↓
                 [REFRESH]      [KEEP CURRENT]
                                (prevent flicker)

iOS Comparison:
  • previousAuthorizationStatus vs currentAuthorizationStatus

Android Comparison:
  • previousAuthorizationStatus vs currentAuthorizationStatus
  • previousInstallStatus vs currentInstallStatus
  • Both must match to skip refresh
```

---

## State Transition Matrix

### iOS State Transitions

```
┌─────────────────────────┬──────────────────────┬────────────────────┐
│      Current State      │       Event          │    Next State      │
├─────────────────────────┼──────────────────────┼────────────────────┤
│ Initial                 │ HealthInitialize     │ Loading            │
│ Loading                 │ Auth Check Complete  │ (depends on data)  │
│ IOSWorkoutEmpty         │ HealthRefresh        │ Loading            │
│ WorkoutLoaded           │ HealthRefresh        │ Loading            │
│ WorkoutLoaded           │ HealthAppResumed     │ Loading or Same    │
│ Any                     │ Error Occurred       │ Error              │
│ Error                   │ HealthClearError     │ Initial            │
└─────────────────────────┴──────────────────────┴────────────────────┘
```

### Android State Transitions

```
┌─────────────────────────┬──────────────────────┬────────────────────┐
│      Current State      │       Event          │    Next State      │
├─────────────────────────┼──────────────────────┼────────────────────┤
│ Initial                 │ HealthInitialize     │ Loading            │
│ Loading                 │ HC Not Installed     │ AndroidHCNotInst   │
│ Loading                 │ HC Installed         │ (check perm)       │
│ AndroidHCNotInstalled   │ HealthInstallHC      │ (open Play Store)  │
│ AndroidHCNotInstalled   │ HealthAppResumed     │ Loading or Same    │
│ AndroidPermRequired     │ HealthRequestPerm    │ Loading            │
│ AndroidWorkoutEmpty     │ HealthRefresh        │ Loading            │
│ WorkoutLoaded           │ HealthRefresh        │ Loading            │
│ WorkoutLoaded           │ HealthAppResumed     │ Loading or Same    │
│ Any                     │ Error Occurred       │ Error              │
│ Error                   │ HealthClearError     │ Initial            │
└─────────────────────────┴──────────────────────┴────────────────────┘
```

---

## UI State Mapping

```
┌──────────────────────────────────────────────────────────────────────┐
│                         UI STATE MAPPING                             │
└──────────────────────────────────────────────────────────────────────┘

HealthUIState                          UI Components
─────────────────────────────────────────────────────────────────────
initial                        →       Welcome message

loading                        →       CircularProgressIndicator

iosPermissionRequired          →       • Permission guidance card
iosWorkoutEmpty                        • "Open Settings" button
                                       • Empty state illustration

androidHCNotInstalled          →       • Installation guide card
                                       • "Install HC" button
                                       • Play Store link

androidPermissionRequired      →       • Permission request card
                                       • "Grant Permission" button
                                       • Settings link

androidWorkoutEmpty            →       • Simple empty message
                                       • No permission UI
                                       • Refresh button

workoutLoaded                  →       • Summary card (score, cal, time)
                                       • Workout list
                                       • Pull-to-refresh
                                       • Refresh button

error                          →       • Error message
                                       • Retry button
                                       • Error icon
```

---

## Event Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                          EVENT FLOW                                  │
└──────────────────────────────────────────────────────────────────────┘

User Action              Event                     BLoC Handler
───────────────────────────────────────────────────────────────────────
App Launch        →   HealthInitializeEvent   →   _onInitialize
                                                   • Platform check
                                                   • Run iOS/Android flow

Refresh Button    →   HealthRefreshEvent      →   _onRefresh
                                                   • Ignore state compare
                                                   • Always refresh

BG → FG           →   HealthAppResumedEvent   →   _onAppResumed
                                                   • Compare states
                                                   • Conditional refresh

Permission Btn    →   HealthRequestPerm...    →   _onRequestPermission
(iOS)                                              • Show system dialog
                                                   • Re-run flow

Grant Perm Btn    →   HealthRequestPerm...    →   _onRequestPermission
(Android)                                          • Show HC screen
                                                   • Re-run flow

Install HC Btn    →   HealthInstallHC...      →   _onInstallHealthConnect
(Android)                                          • Open Play Store

Settings Btn      →   HealthOpenSettings...   →   _onOpenSettings
(Android)                                          • Open HC settings

Settings Btn      →   HealthOpenIOSHealth...  →   _onOpenIOSHealthApp
(iOS)                                              • Open Health app

Clear Error       →   HealthClearErrorEvent   →   _onClearError
                                                   • Reset to initial
```

---

## Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         DATA FLOW                                    │
└──────────────────────────────────────────────────────────────────────┘

UI Layer (Widgets)
       ↓ dispatch event
  ───────────────────
 │   HealthBloc    │
  ───────────────────
       ↓ call use case
  ───────────────────
 │   Use Cases     │
  ───────────────────
       ↓ call repository
  ───────────────────
 │ HealthRepository│
  ───────────────────
       ↓ route by platform
  ─────────────────────────
 │   iOS         Android  │
 │ HealthKit  HealthConnect│
  ─────────────────────────
       ↓ fetch data
  ───────────────────
 │   health pkg    │
  ───────────────────
       ↓ return data
  ───────────────────
 │  Mapper (Entity)│
  ───────────────────
       ↓ emit state
  ───────────────────
 │  BLoC State     │
  ───────────────────
       ↓ rebuild
  ───────────────────
 │   UI Updates    │
  ───────────────────
```

---

## Permission Request Flow Comparison

### iOS Permission Flow

```
User Taps "Grant Permission"
           ↓
HealthRequestPermissionEvent
           ↓
      HealthBloc
           ↓
RequestHealthPermission UseCase
           ↓
   HealthRepository
           ↓
  HealthKitDataSource
           ↓
  health.requestAuthorization()
           ↓
   System Permission Dialog
           ↓
 User Grants/Denies (or app decides)
           ↓
    Return to BLoC
           ↓
  Fetch Workout Data
    (regardless of permission)
           ↓
    Emit State Based on Data
```

### Android Permission Flow

```
User Taps "Grant Permission"
           ↓
HealthRequestPermissionEvent
           ↓
      HealthBloc
           ↓
RequestHealthPermission UseCase
           ↓
   HealthRepository
           ↓
HealthConnectDataSource
           ↓
  health.requestAuthorization()
           ↓
  Health Connect Permission Screen
           ↓
   User Grants/Denies
           ↓
    Return to BLoC
           ↓
   Re-check Permissions
           ↓
  If Granted → Fetch Data
  If Denied → Show Permission UI
```

---

## State Persistence Lifecycle

```
┌──────────────────────────────────────────────────────────────────────┐
│                    STATE PERSISTENCE LIFECYCLE                       │
└──────────────────────────────────────────────────────────────────────┘

App Launch
    ↓
HealthStatePersistence created
    ↓
previousAuthorizationStatus = null
previousInstallStatus = null (Android)
    ↓
First Permission Check
    ↓
Store current state:
    • previousAuthorizationStatus = granted
    • previousInstallStatus = installed (Android)
    ↓
App goes to Background
    (state retained in memory)
    ↓
App returns to Foreground
    ↓
HealthAppResumedEvent
    ↓
Get current state
    ↓
Compare with previous
    ↓
    ├─ Changed? → Refresh → Update persistence
    └─ Same? → Keep current state
    ↓
App Killed/Terminated
    ↓
Persistence cleared (in-memory only)
    ↓
Next Launch → Start from null again
```

---

## Error Handling Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                       ERROR HANDLING                                 │
└──────────────────────────────────────────────────────────────────────┘

Operation (Permission/Fetch)
         ↓
   Try-Catch Block
         ↓
    ┌────────────┐
    │ Error?     │
    └────────────┘
      /        \
    No         Yes
     │          │
     ↓          ↓
 Success    Parse Error
  State         ↓
           ┌─────────────────────┐
           │ Error Type?         │
           └─────────────────────┘
              ↙      ↓      ↘
    Timeout    Permission  Network
       │           │           │
       ↓           ↓           ↓
   Return      Return      Return
   Left(err)   Left(err)   Left(err)
       │           │           │
       └───────────┴───────────┘
                   ↓
            Emit HealthBlocError
                   ↓
            Show Error UI
                   ↓
            User Taps Retry
                   ↓
          HealthRefreshEvent
                   ↓
            Try Again
```

---

## Refresh Button Logic

```
┌──────────────────────────────────────────────────────────────────────┐
│                      REFRESH BUTTON FLOW                             │
└──────────────────────────────────────────────────────────────────────┘

User Taps Refresh Button
         ↓
  HealthRefreshEvent(days: 7)
         ↓
    Emit Loading
         ↓
  ┌─────────────────┐
  │ Platform Check  │
  └─────────────────┘
    ↙            ↘
  iOS           Android
   │              │
   ↓              ↓
_runIOSFlow    _runAndroidFlow
   │              │
   ↓              ↓
Check Auth    Check HC Install
   ↓              ↓
Request if    Check Permissions
notDetermined      ↓
   ↓          Fetch if All OK
Fetch Data         ↓
   ↓          Emit State
Emit State
   │              │
   └──────┬───────┘
          ↓
    Update UI

NOTE: Refresh ALWAYS re-runs full flow
      Ignores previous state comparison
      Ensures fresh data
```

---

## Summary: Key Architectural Decisions

### 1. State-Driven Design
- All behavior controlled by explicit states
- No complex conditionals in UI
- Clear separation of concerns

### 2. Platform-Specific Flows
- iOS and Android have separate flow logic
- Policy compliance built into flows
- Platform detection at runtime

### 3. Smart BG→FG Handling
- State comparison prevents unnecessary refreshes
- Improves performance and UX
- User can always manually refresh

### 4. Predictable User Experience
- Always: Permission Check → Data Load
- Clear guidance at every step
- Consistent across all entry points

### 5. Testability
- State transitions explicit
- Easy to mock and test
- Clear acceptance criteria

---

**End of State Machine Diagrams**
