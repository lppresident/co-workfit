# Co-WorkFit 프로젝트 컨텍스트 관리 규칙

## 프로젝트 개요
- **이름**: Co-WorkFit
- **타입**: Flutter 앱 (Clean Architecture + BLoC)
- **목적**: 멀티 플랫폼 헬스 데이터 연동 및 소셜 피트니스 트래킹

## 작업 진행 방식

### Issue & PR 관리 전략

#### 1. 메인 Tracking Issue (예: #3)
- **목적**: 전체 Phase별 진행 상황 추적
- **내용**: 큰 틀의 완료/미완료 상태만 표시
- **사용**: 새 Claude 세션 시작 시 참조용
- **업데이트**: 직접 수정하지 않고, 세부 Issue 링크만 관리

#### 2. 세부 Task Issue → PR 워크플로우
각 구체적인 작업은 다음 순서로 진행:

```
Issue 생성 → Branch 생성 → 작업 → Commit → PR 생성 → Merge → Issue 자동 Close
```

**Issue 생성**
- 제목: `[Phase X] 기능명` (예: `[Phase 4] 인증 UI 구현`)
- 내용: 작업 내용, 체크리스트, 관련 파일
- 라벨: 필요시 추가 (선택사항)

**Branch 명명 규칙**
```
feature/{기능명}-{issue번호}
예: feature/auth-ui-4
예: feature/workout-list-detail-ui-8
```

**Commit 메시지 규칙**
```
타입: 간단한 설명 (#issue번호)

## 상세 내용
- 항목 1
- 항목 2

Closes #issue번호 (또는 Relates to #issue번호)
```

**PR 생성 시**
- 제목: Issue 제목과 동일하게
- 본문에 `Closes #issue번호` 포함 (자동 연결)
- PR이 머지되면 자동으로 Issue가 닫힘

#### 3. Issue와 PR의 관계
- **1 Issue = 1 PR** 원칙
- Issue는 "무엇을 할지" 정의
- PR은 "어떻게 했는지" 보여줌
- PR 머지 시 Issue 자동 Close로 중복 관리 불필요

### 컨텍스트 복원 시 (새 Claude 세션)
1. 메인 Tracking Issue 번호만 참조
   - 예: "GitHub Issue #3 보고 작업해줘"
2. Issue를 읽어 현재 Phase와 전체 상태 파악
3. 작업할 세부 항목은 새 Issue 생성 또는 기존 열린 Issue 확인
4. 불필요한 히스토리는 읽지 않음

### 작업 시작 시 체크리스트
1. [ ] Issue 생성 (또는 기존 Issue 확인)
2. [ ] Branch 생성 (`feature/{기능명}-{issue번호}`)
3. [ ] 작업 수행
4. [ ] Commit (메시지에 `#issue번호` 포함)
5. [ ] PR 생성 (본문에 `Closes #issue번호`)
6. [ ] 테스트 및 검토
7. [ ] PR Merge (→ Issue 자동 Close)

## 프로젝트 구조 (토큰 절약용 요약)

### 핵심 아키텍처
```
lib/
├── core/
│   ├── di/injection.dart          # GetIt DI 설정
│   └── config/firebase_config.dart
├── features/
│   ├── workout/                   # Phase 1-2: 운동 데이터 연동
│   │   ├── data/datasources/
│   │   │   ├── health_kit_datasource.dart      # iOS HealthKit
│   │   │   ├── health_connect_datasource.dart  # Android Health Connect
│   │   │   └── garmin/                         # Garmin (승인 대기)
│   │   └── domain/entities/workout_entity.dart
│   ├── calibration/               # Phase 1: 점수 계산
│   ├── auth/                      # Phase 3: Firebase 인증 (완료)
│   │   ├── data/datasources/firebase_auth_datasource.dart
│   │   └── presentation/bloc/auth_bloc.dart
│   └── social/                    # Phase 3: 친구/리더보드 (완료)
│       └── data/datasources/firestore_social_datasource.dart
└── main.dart
```

### 완료된 Phase
- **Phase 1**: 기반 구축 (Clean Architecture, BLoC, 캘리브레이션) ✅
- **Phase 2**: 플랫폼 연동 (HealthKit, Health Connect, Garmin 구조) ✅
- **Phase 3**: 소셜 백엔드 (Firebase Auth, 친구 시스템, 리더보드) ✅

### 현재 Phase
- **Phase 4**: UI 구현 (인증 UI, 친구 관리 UI, 리더보드 UI, 프로필 UI)

### 대기 중
- Garmin API 승인
- Firebase 프로젝트 실제 설정

## 기술 스택 (참고용)
- Flutter + Dart
- Clean Architecture + BLoC (flutter_bloc)
- GetIt (DI), dartz (Either)
- Firebase (Auth, Firestore)
- health 패키지 (iOS/Android)

## 코딩 규칙
- Clean Architecture 계층 준수 (domain/data/presentation)
- BLoC 패턴 사용 (Event → Bloc → State)
- Either<Failure, Success> 사용
- 에러 처리: try-catch → Left(Failure)

## 참고 문서 (필요 시만 읽기)
- README.md: 프로젝트 개요 및 캘리브레이션 알고리즘
- GitHub Issue #3: 전체 개발 현황 및 로드맵

## 작업 시 주의사항
1. 기존 코드 읽지 않고 제안하지 말 것
2. 변경 전 항상 파일 읽기
3. 토큰 절약: 불필요한 파일 탐색 최소화
4. Issue 작성 시 간결하게 (핵심만)
