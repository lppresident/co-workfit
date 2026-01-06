# 앱 생명주기 관리

> Co-WorkFit의 앱 생명주기 및 정산 자동화 시스템 문서

## 📋 개요

앱 생명주기를 전역적으로 관리하여 bg→fg 전환 시 자동 정산 체크 및 앱 상태 복구를 수행합니다.

---

## 🎯 주요 기능

### 1. bg→fg 전환 감지
- `WidgetsBindingObserver` 구현
- 백그라운드 전환 시 현재 시간 저장
- 포그라운드 복귀 시 상태 체크

### 2. 날짜 변경 감지 및 자동 정산
- 마지막 활성 날짜와 현재 날짜 비교
- 날짜가 바뀌었으면 자동 정산 체크 (`CheckPendingSettlementsEvent`)
- 사용자가 앱을 재시작하지 않아도 정산 받을 수 있음

### 3. 장시간 미사용 감지
- 기본값: **6시간** 이상 미사용 시 앱 초기화
- Currency 데이터 새로고침
- 필요 시 다른 BLoC 리셋 가능

---

## 🏗️ 구조

### AppLifecycleService

**파일**: `lib/core/services/app_lifecycle_service.dart`

```dart
class AppLifecycleService with WidgetsBindingObserver {
  // 의존성
  final SharedPreferences _prefs;
  final CurrencyBloc _currencyBloc;

  // 설정
  static const int resetThresholdHours = 6;

  // 주요 메서드
  void initialize();                  // 서비스 초기화
  void dispose();                     // 서비스 정리
  void didChangeAppLifecycleState();  // 생명주기 이벤트 처리
}
```

### SharedPreferences 키

| 키 | 타입 | 설명 |
|---|------|------|
| `last_active_time` | String (ISO 8601) | 마지막 활성 시간 |
| `last_active_date` | String (yyyy-MM-dd) | 마지막 활성 날짜 |

---

## 🔄 동작 흐름

### 1. 초기화 (앱 시작 시)

```
사용자 로그인 완료 (Authenticated)
  ↓
AppLifecycleService 초기화 (main.dart)
  ↓
WidgetsBinding.instance.addObserver(service)
  ↓
현재 시간/날짜 저장
```

### 2. 백그라운드 전환 (Paused)

```
사용자가 홈 버튼 누름 / 다른 앱으로 전환
  ↓
didChangeAppLifecycleState(paused)
  ↓
_saveLastActiveTime()
  ↓
SharedPreferences에 현재 시간/날짜 저장
```

### 3. 포그라운드 복귀 (Resumed)

```
사용자가 앱으로 돌아옴
  ↓
didChangeAppLifecycleState(resumed)
  ↓
마지막 활성 시간/날짜 조회
  ↓
┌─────────────────────────────┬──────────────────────────────┐
│ 날짜 변경 감지?              │ 장시간 미사용 (6시간+)?       │
│ → CheckPendingSettlements   │ → Currency 데이터 새로고침    │
│ → 정산 다이얼로그 표시       │ → 정산 체크도 함께 수행       │
└─────────────────────────────┴──────────────────────────────┘
  ↓
현재 시간/날짜 저장 (다음 체크를 위해)
```

---

## 💡 사용 예시

### 시나리오 1: 날짜 변경 정산

```
Day 1, 23:50 - 앱 사용 중
Day 1, 23:55 - 백그라운드 전환
  → lastActiveTime: 2026-01-01 23:55
  → lastActiveDate: 2026-01-01

Day 2, 00:10 - 포그라운드 복귀
  → 날짜 변경 감지 (2026-01-01 → 2026-01-02)
  → CheckPendingSettlementsEvent 발동
  → Day 1 정산 수행 ✅
```

### 시나리오 2: 장시간 미사용

```
Day 2, 08:00 - 백그라운드 전환
  → lastActiveTime: 2026-01-02 08:00

Day 2, 15:00 - 포그라운드 복귀 (7시간 후)
  → 장시간 미사용 감지 (7시간 >= 6시간)
  → 앱 초기화 수행
  → Currency 데이터 새로고침
  → 정산 체크도 수행 ✅
```

---

## 🔧 설정

### 미사용 기준 시간 변경

`lib/core/services/app_lifecycle_service.dart`:

```dart
class AppLifecycleService with WidgetsBindingObserver {
  // 기본값: 6시간
  static const int resetThresholdHours = 6;

  // 변경 예시:
  // static const int resetThresholdHours = 3;  // 3시간
  // static const int resetThresholdHours = 12; // 12시간
}
```

### 추가 BLoC 리셋

앱 초기화 시 다른 BLoC도 리셋하려면:

```dart
Future<void> _resetApp() async {
  AppLogger.info('AppLifecycle', '앱 초기화 시작');

  // Currency
  _currencyBloc.add(const LoadCurrencySummaryEvent());

  // 추가 BLoC 리셋
  // _socialBloc.add(const RefreshSocialDataEvent());
  // _workoutBloc.add(const RefreshWorkoutDataEvent());

  onAppReset?.call();
}
```

---

## 🔗 DI 등록

### injection.dart

```dart
Future<void> initializeDependencies() async {
  // SharedPreferences (Core Dependency)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ... 다른 등록들 ...

  // AppLifecycleService (마지막에 등록)
  sl.registerLazySingleton<AppLifecycleService>(
    () => AppLifecycleService(
      prefs: sl(),
      currencyBloc: sl(), // CurrencyBloc에 의존
    ),
  );
}
```

### main.dart

```dart
// 인증 완료 시 초기화
if (state is Authenticated) {
  // ... Currency 초기화 ...

  // AppLifecycleService 초기화 (1회만)
  if (_appLifecycleService == null) {
    _appLifecycleService = di.sl<AppLifecycleService>();
    _appLifecycleService!.initialize();
  }
}

// dispose 시 정리
@override
void dispose() {
  _appLifecycleService?.dispose();
  super.dispose();
}
```

---

## 📝 로컬 저장소 정책

### SharedPreferences 사용 원칙

| 데이터 타입 | 저장 위치 | 이유 |
|------------|----------|------|
| **앱 생명주기 데이터** | SharedPreferences | 로컬만으로 충분, 빠른 접근 |
| **재화 (wood/iron/soil)** | Firestore | 멀티 디바이스 동기화 필수 |
| **정산 기록** | Firestore | 서버 검증 필수, 중복 방지 |
| **lastSettlementDate** | Firestore | 중복 정산 방지 (보안) |

### 향후 로컬 캐시 후보

다음 데이터는 로컬 캐시 추가 고려 가능:
- `equippedItems` - 캐릭터 렌더링 캐시
- `isNicknameSet` - 온보딩 분기용

(별도 Issue로 진행 예정)

---

## ⚠️ 주의사항

### 1. CurrencyBloc 의존성

AppLifecycleService는 CurrencyBloc에 의존하므로:
- DI 등록 순서: **CurrencyBloc 먼저, AppLifecycleService 나중에**
- `registerLazySingleton` 사용으로 실제 사용 시점에 생성

### 2. 인증 후 초기화

AppLifecycleService는 **인증 완료 후**에만 초기화:
- 인증 전: CurrencyBloc 없음 → 초기화 불가
- 인증 후: 1회만 초기화 (`_appLifecycleService == null` 체크)

### 3. BuildContext 사용 금지

`didChangeAppLifecycleState`에서는 BuildContext 사용 불가:
- BLoC 이벤트 발동으로 상태 변경
- 다이얼로그는 BlocListener에서 표시

---

## 🐛 트러블슈팅

### Q1. 날짜 변경했는데 정산 안 됨

**확인 사항:**
1. 앱이 포그라운드 복귀했는지 확인
2. AppLogger로 로그 확인: `날짜 변경 감지`
3. CurrencyBloc이 정상 등록되었는지 확인

### Q2. 장시간 미사용인데 리셋 안 됨

**확인 사항:**
1. 미사용 시간이 6시간 이상인지 확인
2. AppLogger로 로그 확인: `장시간 미사용 감지`
3. SharedPreferences에 시간이 저장되었는지 확인

### Q3. 앱 시작 시 에러 발생

**확인 사항:**
1. SharedPreferences가 DI에 등록되었는지 확인
2. CurrencyBloc이 먼저 등록되었는지 확인
3. 인증 완료 후에 초기화되는지 확인

---

## 📚 관련 문서

- [CURRENCY_SYSTEM.md](CURRENCY_SYSTEM.md) - 재화 및 정산 시스템
- [TEMPLATES.md](TEMPLATES.md) - Clean Architecture 템플릿

---

## 🔗 관련 Issue/PR

- Issue #74: 앱 생명주기 관리 및 bg→fg 정산 체크 구현
- PR #75: feat: 앱 생명주기 관리 및 bg→fg 정산 체크 구현

---

_v1.0 | 2026-01-07_
