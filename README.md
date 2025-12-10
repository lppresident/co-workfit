# Co-WorkFit

동료와 함께하는 운동 성취 공유 앱 - 당신의 완벽한 운동 동반자!

## 🎯 핵심 기능

### 1. 멀티 플랫폼 데이터 통합
- **Garmin Connect**: 전문 운동 트래커 데이터
- **Apple HealthKit**: iPhone/Apple Watch 건강 데이터
- **Google Fit**: Android 기기 피트니스 데이터
- **Samsung Health**: 삼성 헬스 앱 데이터
- **수동 입력**: 직접 운동 기록 추가

### 2. 스마트 캘리브레이션 시스템 ⚖️
각 플랫폼마다 다른 측정 방식을 표준화하여 공정한 비교를 가능하게 합니다:

- **플랫폼별 보정 계수**: 각 플랫폼의 측정 특성 반영
- **다차원 분석**: 칼로리, 심박수, 시간, 거리를 종합적으로 평가
- **운동 타입별 난이도**: 수영, 러닝, 사이클링 등 운동 강도 차이 반영
- **표준화된 점수**: 누구나 공정하게 비교할 수 있는 workload 지수

### 3. 소셜 기능 🤝
- 동료와 성취 공유
- 리더보드 및 순위
- 그룹 챌린지
- 운동 기록 타임라인

## 🏗️ 프로젝트 구조

```
lib/
├── core/                    # 핵심 유틸리티
│   ├── constants/
│   ├── utils/
│   └── errors/
├── features/                # 기능별 모듈 (Clean Architecture)
│   ├── auth/               # 사용자 인증
│   ├── workout/            # 운동 데이터 관리
│   ├── calibration/        # 캘리브레이션 로직
│   └── social/             # 소셜 기능
└── shared/                  # 공유 위젯 & 테마
    ├── widgets/
    └── theme/
```

각 feature는 Clean Architecture 원칙을 따릅니다:
- `data/`: 데이터 소스 및 모델
- `domain/`: 비즈니스 로직 (엔티티, 유스케이스)
- `presentation/`: UI 레이어 (BLoC, 페이지, 위젯)

## 🛠️ 기술 스택

### 아키텍처 & 상태 관리
- **Clean Architecture**: 계층 분리 및 의존성 역전
- **BLoC Pattern**: 상태 관리 (flutter_bloc)
- **Dependency Injection**: GetIt

### 헬스 플랫폼 통합
- **Health Package**: 멀티 플랫폼 헬스 데이터 통합
- **Firebase**: 인증 및 Firestore

### UI
- **Material 3**: 최신 디자인 시스템

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.10.0

### 설치

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 테스트

```bash
# 전체 테스트 실행
flutter test

# 코드 분석
flutter analyze
```

## 📊 캘리브레이션 알고리즘

Co-WorkFit의 핵심은 공정한 운동 평가입니다. 각 플랫폼의 데이터를 다음과 같이 처리합니다:

### 1. 정규화 (0-100 스케일)
- **칼로리**: 800kcal = 100점
- **심박수**: 안정시(60) ~ 고강도(160) 범위
- **운동 시간**: 90분 = 100점
- **거리**: 운동 타입별 기준 (러닝 10km, 사이클링 30km 등)

### 2. 가중치 적용
```dart
workload = (칼로리 × 0.35) + (심박수 × 0.30) +
           (시간 × 0.20) + (거리 × 0.15)
```

### 3. 플랫폼 보정
- Garmin: 0.95 (칼로리 높게 측정 경향)
- Apple Health: 1.0 (기준)
- Google Fit: 1.05 (보수적 측정)
- Samsung Health: 1.0
- 수동 입력: 0.90 (보수적 평가)

### 4. 운동 타입 난이도
- 수영: 1.2 (높은 난이도)
- 웨이트 트레이닝: 1.1
- 러닝: 1.0 (기준)
- 사이클링: 0.9
- 걷기: 0.7

## 📋 개발 현황

자세한 개발 진행 상황 및 로드맵은 [GitHub Issue #3](https://github.com/lppresident/co-workfit/issues/3)에서 확인하세요.

## 📝 라이선스

Private Project

---

**Co-WorkFit** - 함께 운동하고, 함께 성장하세요! 💪
