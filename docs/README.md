# Co-WorkFit Documentation Index

이 폴더는 Co-WorkFit 프로젝트의 모든 문서를 포함합니다.

---

## 📚 문서 구조

```
docs/
├── README.md                          # 이 파일 (문서 인덱스)
├── APPLE_SIGNIN_SETUP.md              # Apple Sign-In 설정 가이드
├── DEPLOYMENT.md                      # 배포 가이드
├── FASTLANE_MATCH_SETUP.md            # Fastlane Match 설정
└── health_*.md                        # Health 시스템 문서

.claude/
├── CLAUDE.md                          # 🎯 AI 개발 룰 (메인)
└── docs/
    ├── AI_QUICK_REFERENCE.md          # 빠른 참조 가이드
    ├── ARCHITECTURE.md                # Clean Architecture 가이드
    ├── CONTRIBUTING.md                # 기여 가이드
    └── UI_STRUCTURE.md                # UI 구조 가이드
```

---

## 🎯 AI 개발자를 위한 문서

> **Claude Code 사용 시 `.claude/CLAUDE.md`가 자동으로 로드됩니다.**

### 핵심 문서 (필독)

| 순서 | 문서 | 설명 | 언제 읽나요? |
|------|------|------|-------------|
| 1 | [CLAUDE.md](../.claude/CLAUDE.md) | AI 개발 규칙 (메인) | **가장 먼저!** |
| 2 | [UI_STRUCTURE.md](../.claude/docs/UI_STRUCTURE.md) | BasePage, Mixins, UI 패턴 | 페이지 만들 때 |
| 3 | [AI_QUICK_REFERENCE.md](../.claude/docs/AI_QUICK_REFERENCE.md) | 코드 템플릿, 스니펫 | 코딩할 때 |
| 4 | [ARCHITECTURE.md](../.claude/docs/ARCHITECTURE.md) | Clean Architecture 상세 | 아키텍처 이해 |
| 5 | [CONTRIBUTING.md](../.claude/docs/CONTRIBUTING.md) | 기여 프로세스 전체 | 전체 흐름 파악 |

### 학습 순서

```
1. CLAUDE.md          → 핵심 규칙 (10분)
2. UI_STRUCTURE.md    → UI 패턴 (15분)
3. AI_QUICK_REFERENCE → 템플릿 확인 (10분)
4. 기존 코드 확인     → lib/features/social/ 참고
5. ARCHITECTURE.md    → 필요시 상세 확인
```

---

## 🔧 설정 및 배포 문서

### Apple Sign-In 설정

📄 [APPLE_SIGNIN_SETUP.md](./APPLE_SIGNIN_SETUP.md)

Apple Sign-In을 사용하기 위한 설정 가이드:
- Apple Developer Program 설정
- Firebase Authentication 설정
- Xcode 프로젝트 설정
- 문제 해결 가이드

### 배포 가이드

📄 [DEPLOYMENT.md](./DEPLOYMENT.md)

iOS/Android 앱 배포 프로세스:
- 빌드 설정
- TestFlight / Google Play 배포
- CI/CD 설정

### Fastlane Match 설정

📄 [FASTLANE_MATCH_SETUP.md](./FASTLANE_MATCH_SETUP.md)

iOS 인증서 및 프로비저닝 프로파일 관리:
- Match 초기 설정
- 팀 공유 설정
- 인증서 갱신

---

## 🏥 Health 시스템 문서

Health Permission 시스템 (HealthKit/Health Connect) 관련 상세 문서입니다.

### 문서 목록

| 문서 | 설명 | 대상 |
|------|------|------|
| [health_quick_reference.md](./health_quick_reference.md) | 빠른 참조 가이드 | 개발자 |
| [health_refactoring_summary.md](./health_refactoring_summary.md) | 리팩토링 요약 | 전체 |
| [health_permission_refactoring.md](./health_permission_refactoring.md) | 전체 스펙 | 개발자, QA |
| [health_state_machine_diagrams.md](./health_state_machine_diagrams.md) | 상태 머신 다이어그램 | 아키텍트 |
| [health_ui_implementation_guide.md](./health_ui_implementation_guide.md) | UI 구현 가이드 | 프론트엔드 |
| [health_test_scenarios.md](./health_test_scenarios.md) | 테스트 시나리오 | QA |

### Health 문서 읽는 순서

```
신규 개발자:
1. health_quick_reference.md (30분)
2. health_refactoring_summary.md (15분)
3. health_state_machine_diagrams.md (1시간)

UI 구현 시:
→ health_ui_implementation_guide.md

테스트 작성 시:
→ health_test_scenarios.md
```

---

## 📋 문서별 요약

### .claude/CLAUDE.md (메인 룰파일)

**용도**: AI Assistant가 따라야 할 모든 개발 규칙

**포함 내용**:
- 프로젝트 구조
- UI 규칙 (BasePage, StandardAppBar, Mixins)
- Clean Architecture 규칙
- Naming Conventions
- Git 워크플로우
- 개발 체크리스트
- 자주 하는 실수

### .claude/docs/UI_STRUCTURE.md

**용도**: UI 구조 및 패턴 가이드

**포함 내용**:
- BasePage & BasePageState
- TabbedMixin, RefreshableMixin, LoadableMixin
- StandardAppBar
- Common Widgets
- 페이지 타입별 템플릿

### .claude/docs/AI_QUICK_REFERENCE.md

**용도**: 빠른 코드 참조

**포함 내용**:
- Entity/Model/UseCase 템플릿
- BLoC Event/State/Bloc 템플릿
- Page 템플릿
- DI 등록 예제
- Common Patterns

### .claude/docs/ARCHITECTURE.md

**용도**: Clean Architecture 상세 가이드

**포함 내용**:
- Layer 구조
- Domain/Data/Presentation 상세
- DI 설정
- 베스트 프랙티스

### .claude/docs/CONTRIBUTING.md

**용도**: 전체 기여 프로세스

**포함 내용**:
- Development Checklist
- Feature Template
- Code Style Guide
- Commit Message Format
- Code Review Checklist

---

## 🔗 빠른 링크

### 개발 시작

- **새 페이지 만들기**: [UI_STRUCTURE.md](../.claude/docs/UI_STRUCTURE.md)
- **코드 템플릿**: [AI_QUICK_REFERENCE.md](../.claude/docs/AI_QUICK_REFERENCE.md)
- **참고 코드**: `lib/features/social/` (FriendsPage, LeaderboardPage)

### 설정

- **Apple 로그인**: [APPLE_SIGNIN_SETUP.md](./APPLE_SIGNIN_SETUP.md)
- **배포**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **인증서 관리**: [FASTLANE_MATCH_SETUP.md](./FASTLANE_MATCH_SETUP.md)

### Health 시스템

- **빠른 시작**: [health_quick_reference.md](./health_quick_reference.md)
- **전체 스펙**: [health_permission_refactoring.md](./health_permission_refactoring.md)

---

## 📝 문서 관리 가이드

### 문서 추가 시

1. 적절한 위치에 파일 생성
2. 이 README.md에 링크 추가
3. 관련 문서에서 참조 추가

### 문서 위치 규칙

| 문서 타입 | 위치 |
|----------|------|
| AI 개발 규칙/가이드 | `.claude/docs/` |
| 설정/배포 가이드 | `docs/` |
| 기능별 상세 스펙 | `docs/` |

### 버전 관리

- 문서 하단에 Last Updated 날짜 기록
- 주요 변경 시 버전 번호 업데이트

---

**Last Updated**: 2025-12-29
