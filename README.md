# Co-WorkFit 💪

**동료와 함께하는 운동 성취 공유 앱**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

---

## ✨ 주요 기능

### 🏃 운동 데이터 통합
- Apple HealthKit / Google Health Connect 연동
- Garmin Connect 지원
- 수동 운동 기록 입력

### 🏆 통나무런 (Log Run)
- 그룹 챌린지 생성 및 참여
- 초대 코드로 친구와 함께
- 실시간 기여도 추적

### 👥 소셜 기능
- 친구 추가 및 관리
- 주간/월간 리더보드
- 운동 기록 공유

### ⚖️ 공정한 비교
- 플랫폼별 보정 계수 적용
- 운동 타입별 난이도 반영
- 표준화된 Workload 점수

---

## 🛠️ 기술 스택

| 분류 | 기술 |
|------|------|
| **Framework** | Flutter 3.10+ |
| **Architecture** | Clean Architecture + BLoC |
| **State** | flutter_bloc |
| **DI** | GetIt |
| **Backend** | Firebase (Auth, Firestore) |
| **Health Data** | health package |

---

## 🚀 시작하기

### 요구사항

- Flutter SDK 3.10+
- Firebase 프로젝트

### 설치

```bash
# 클론
git clone https://github.com/lppresident/co-workfit.git
cd co-workfit

# 의존성 설치
flutter pub get

# Firebase 설정
flutterfire configure

# 실행
flutter run
```

### Android 개발 환경

```bash
# Java/Android SDK 설정 (새 터미널마다)
source scripts/setup-env.sh
```

---

## 📁 프로젝트 구조

```
lib/
├── core/           # 공통 기능 (DI, Utils, Widgets)
├── features/       # 기능별 모듈
│   ├── auth/       # 인증
│   ├── log_run/    # 통나무런
│   ├── profile/    # 프로필
│   ├── social/     # 소셜
│   └── workout/    # 운동
└── main.dart
```

---

## 📚 문서

### AI 개발자 (Claude Code)

| 문서 | 설명 |
|------|------|
| [CLAUDE.md](.claude/CLAUDE.md) | **개발 규칙 (필독)** |
| [TEMPLATES.md](.claude/docs/TEMPLATES.md) | 코드 템플릿 |

### 설정 가이드

| 문서 | 설명 |
|------|------|
| [APPLE_SIGNIN_SETUP.md](docs/APPLE_SIGNIN_SETUP.md) | Apple 로그인 설정 |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | 배포 가이드 |
| [FASTLANE_MATCH_SETUP.md](docs/FASTLANE_MATCH_SETUP.md) | 인증서 관리 |

---

## 🔄 개발 워크플로우

```
1. Issue 생성  →  [Phase X] 기능명
2. Branch 생성 →  feature/{기능명}-{issue번호}
3. 개발        →  CLAUDE.md 규칙 준수
4. PR 생성    →  flutter analyze 통과
5. Merge      →  develop → main
```

---

## 📱 스크린샷

> Coming soon

---

## 📝 라이선스

Private Project - All rights reserved

---

**Co-WorkFit** - 함께 운동하고, 함께 성장하세요! 🏋️
