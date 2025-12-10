# Co-WorkFit 프로젝트 컨텍스트 관리 규칙

이 규칙은 GitHub 워크플로우와 AI(Claude)와의 **토큰 효율적인 협업**을 위해 최적화되었습니다.

---

### 1. 🚀 프로젝트 개요 및 컨텍스트 복원

* **이름**: Co-WorkFit (Flutter 앱)
* **아키텍처**: Clean Architecture + BLoC
* **현재 Phase**: **Phase 4** (UI 구현 - *이 정보는 참고용입니다.*)
* **메인 Tracking Issue**: **#3**

> **💡 컨텍스트 복원 지침**
> 1. 새 세션 시작 시: **"GitHub Issue #3 보고 작업해줘"**라고 명령합니다.
> 2. AI는 **Issue #3 본문**을 확인하여 현재 진행 중인 최신 Phase를 파악하고 작업 Scope를 설정합니다.
> 3. 불필요한 전체 히스토리 탐색은 지양하여 토큰을 절약합니다.

---

### 2. 🎯 작업 진행 워크플로우

**1 Issue = 1 Branch = 1 PR** 원칙을 준수합니다.

#### 2.1. 📌 Issue 생성
- **제목**: `[Phase X] 기능명` (예: `[Phase 4] 리더보드 UI 구현`)
- **내용**: 작업 내용, 체크리스트, 관련 파일 경로 명시

#### 2.2. 🌿 Branch 명명
- **형식**: `feature/{기능명}-{issue번호}`
- **예시**: `feature/leaderboard-ui-15`

#### 2.3. 💬 Commit 규칙
- **포맷**: `type: 간단한 설명 (#issue번호)`
- **본문**: `Closes #issue번호` 포함 (PR 병합 시 자동 Close용)
- **Type**: `feat`, `fix`, `docs`, `refactor`, `style` 등

#### 2.4. 🔀 Pull Request (PR)
- **제목**: Issue 제목과 동일하게 작성
- **본문**: 반드시 `Closes #issue번호` 명시

---

### 3. 📁 기술 스택 및 코딩 규칙

#### 3.1. 핵심 구조 (토큰 절약용 요약)
- `lib/core/`: DI(GetIt), Config 관리
- `lib/features/`: 기능별 모듈 (workout, calibration, auth, social)
- `lib/features/{feature}/`: domain/data/presentation 3계층 준수

#### 3.2. 코딩 규칙
- **상태 관리**: BLoC (Event → Bloc → State) 사용
- **에러 처리**: `Either<Failure, T>` 사용 (Dartz 패키지)
- **데이터 흐름**: Datasource (try-catch) → Repository (Left 반환) → UseCase
- **AI 협업**: 코드 수정 전 반드시 대상 파일 읽기 수행

---

### ❗ 작업 시 주의사항
1. 추측 기반의 아키텍처 제안 금지 (기존 코드 확인 필수)
2. 1 Issue 당 1 PR 매핑 엄격 준수
3. 간결하고 명확한 Issue/PR 본문 유지

---

### 4. 🛠️ 개발 환경 및 테스트 규칙

#### 4.1. 작업 디렉토리
- **메인 저장소**: `/Users/user/Documents/HanSol/co-workfit`
- **중요**: worktree 기능을 사용하지 말고 메인 저장소에서 직접 작업할 것
- 브랜치 전환은 메인 저장소에서 `git checkout` 사용

#### 4.2. 테스트 및 디버깅
- **AI는 코드 구현만 담당**: 파일 작성, 수정, 커밋까지만 수행
- **사용자가 직접 수행**: 빌드, 테스트, 디버깅, 실행
- flutter analyze는 AI가 수행 가능하나, 실제 빌드(flutter build, flutter run)는 사용자가 직접 수행
