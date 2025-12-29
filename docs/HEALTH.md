# Health 시스템 가이드

> HealthKit (iOS) / Health Connect (Android) 권한 및 데이터 연동

---

## 📋 개요

Co-WorkFit은 iOS와 Android에서 각각 다른 Health 플랫폼을 사용합니다:

| 플랫폼 | Health API | 특징 |
|--------|------------|------|
| iOS | HealthKit | 앱 내에서 권한 요청 |
| Android | Health Connect | 별도 앱 설치 필요 |

---

## 🚀 Quick Start

### 초기화

```dart
@override
void loadInitialData() {
  context.read<HealthBloc>().add(const HealthInitializeEvent());
}
```

### 앱 복귀 시 상태 체크

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    context.read<HealthBloc>().add(const HealthAppResumedEvent());
  }
}
```

---

## 📋 Events

```dart
// 초기화
HealthInitializeEvent()

// 권한 상태 확인
HealthCheckPermissionEvent()

// 권한 요청
HealthRequestPermissionEvent()

// 데이터 조회
HealthFetchWorkoutDataEvent(startDate: start, endDate: end)

// 새로고침
HealthRefreshEvent(days: 7)

// 앱 복귀
HealthAppResumedEvent()

// Android: Health Connect 설치
HealthInstallHealthConnectEvent()

// Android: 설정 열기
HealthOpenSettingsEvent()

// iOS: Health 앱 열기
HealthOpenIOSHealthAppEvent()
```

---

## 🎨 UI 상태 처리

```dart
BlocBuilder<HealthBloc, HealthBlocState>(
  builder: (context, state) {
    switch (state.uiState) {
      case HealthUIState.loading:
        return const CommonLoadingWidget();
        
      case HealthUIState.permissionRequired:
        return _buildPermissionUI();
        
      case HealthUIState.ready:
        return _buildWorkoutList(state.workouts);
        
      case HealthUIState.error:
        return CommonErrorWidget(message: state.errorMessage);
        
      // Android 전용
      case HealthUIState.healthConnectNotInstalled:
        return _buildInstallHealthConnectUI();
    }
  },
)
```

---

## 📱 플랫폼별 동작

### iOS (HealthKit)

1. 앱 시작 → 권한 상태 확인
2. 권한 없음 → 권한 요청 UI 표시
3. 사용자 승인 → 데이터 로드
4. 설정 앱에서 권한 변경 → 앱 복귀 시 자동 재확인

### Android (Health Connect)

1. 앱 시작 → Health Connect 설치 확인
2. 미설치 → Play Store 유도
3. 설치됨 → 권한 상태 확인
4. 권한 없음 → 권한 요청 UI 표시
5. 사용자 승인 → 데이터 로드

---

## 📂 관련 파일

```
lib/features/workout/
├── domain/
│   ├── entities/health_state.dart
│   ├── entities/health_event.dart
│   ├── repositories/health_repository.dart
│   └── usecases/
│       ├── check_health_permission.dart
│       ├── request_health_permission.dart
│       └── fetch_workout_data.dart
├── data/
│   ├── datasources/
│   │   ├── health_kit_datasource.dart
│   │   ├── health_connect_datasource.dart
│   │   └── health_data_mapper.dart
│   └── repositories/health_repository_impl.dart
└── presentation/
    └── bloc/
        ├── health_bloc.dart
        └── health_bloc_state.dart
```

---

## ⚠️ 주의사항

### iOS
- Info.plist에 `NSHealthShareUsageDescription` 필수
- 백그라운드에서 권한 변경 시 앱 복귀 시 자동 감지

### Android
- Health Connect 앱 설치 필수 (API 28+)
- 권한 요청은 Health Connect 앱에서 처리
- Samsung Health 연동은 Health Connect 통해서

---

_v1.0 | 2025-12-29_

