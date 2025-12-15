# Co-WorkFit 컨텍스트 관리 규칙

> **⚠️ 중요**: 이 파일은 Git 워크플로우 규칙만 포함합니다.
>
> **모든 개발 규칙은 프로젝트 루트의 `.claud` 파일에 통합되었습니다.**
>
> Claude Code는 자동으로 `.claud` 파일을 읽어들이므로 별도로 참조할 필요가 없습니다.

---

### 1. 🚀 프로젝트 개요

* **이름**: Co-WorkFit (Flutter 앱)
* **아키텍처**: Clean Architecture + BLoC
* **현재 상태**: Phase 4 완료, Phase 5 준비 중
* **개발 규칙**: 프로젝트 루트의 `.claud` 파일 참조 (Claude Code 자동 로드)

> **💡 새 세션 시작 시**
> - Claude Code 사용 시: 별도 설정 불필요 (`.claud` 자동 로드)
> - 최신 작업 확인: `gh issue list --state open --limit 5` 실행
> - 진행 중인 작업: Issue와 PR 확인

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
