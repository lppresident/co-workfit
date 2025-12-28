# Fastlane Match 설정 가이드

이 문서는 Fastlane Match를 사용하여 iOS 인증서와 프로비저닝 프로파일을 관리하고, GitHub Actions에서 자동 배포를 설정하는 방법을 안내합니다.

## 📋 목차

1. [Fastlane Match란?](#fastlane-match란)
2. [사전 준비](#사전-준비)
3. [인증서 저장소 생성](#인증서-저장소-생성)
4. [Fastlane 설치 및 초기화](#fastlane-설치-및-초기화)
5. [Match 설정](#match-설정)
6. [인증서 생성](#인증서-생성)
7. [GitHub Secrets 설정](#github-secrets-설정)
8. [테스트](#테스트)
9. [트러블슈팅](#트러블슈팅)

---

## Fastlane Match란?

**Fastlane Match**는 iOS 개발 팀에서 인증서와 프로비저닝 프로파일을 안전하게 공유하고 관리하는 도구입니다.

### 장점
- ✅ 인증서 자동 생성 및 관리
- ✅ Git 저장소에 암호화하여 안전하게 저장
- ✅ 팀원 및 CI/CD 시스템에서 동일한 인증서 사용
- ✅ GitHub Actions 완전 자동화

### 작동 원리
```
1. Match가 인증서 생성
2. 암호화하여 Git 저장소에 저장
3. GitHub Actions에서 필요 시 다운로드 및 사용
```

---

## 사전 준비

### 필수 항목
- ✅ Apple Developer Program 가입 ($99/년)
- ✅ Mac 컴퓨터 (Fastlane 설정용)
- ✅ GitHub 계정
- ✅ Xcode 설치

### 필요한 정보
- Apple ID (이메일)
- Apple Team ID (10자리)
- Bundle ID: `com.hansol.coworkfit`

---

## 인증서 저장소 생성

Match는 인증서를 **비공개 Git 저장소**에 저장합니다.

### 1️⃣ GitHub에서 새 저장소 생성

1. https://github.com/new 접속
2. 저장소 설정:
   - **Repository name**: `coworkfit-certificates` (또는 원하는 이름)
   - **Description**: `iOS certificates for CoWorkFit`
   - **Visibility**: 🔒 **Private** (필수!)
3. **Create repository** 클릭

### 2️⃣ Personal Access Token 생성

Match가 저장소에 접근하려면 GitHub Token이 필요합니다.

1. https://github.com/settings/tokens 접속
2. **Generate new token** → **Generate new token (classic)** 클릭
3. 설정:
   - **Note**: `Fastlane Match - CoWorkfit`
   - **Expiration**: `No expiration` (또는 1년)
   - **Scopes**:
     - ✅ `repo` (모든 하위 항목 체크)
4. **Generate token** 클릭
5. **토큰 복사** (다시 볼 수 없으니 바로 저장!)

**형식 예시:**
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Fastlane 설치 및 초기화

### 1️⃣ Fastlane 설치

```bash
# Mac에서 실행
sudo gem install fastlane
```

### 2️⃣ iOS 폴더로 이동

```bash
cd /path/to/co-workfit/ios
```

### 3️⃣ Fastlane 초기화

```bash
fastlane init
```

**물어보는 것들:**

```
What would you like to use fastlane for?
→ 4. 🚀 Manual setup

Apple ID Username:
→ (당신의 Apple ID 이메일 입력)
```

---

## Match 설정

### 1️⃣ Match 초기화

```bash
cd ios
fastlane match init
```

**물어보는 것들:**

```
Where do you want to store your certificates?
1. git
2. google_cloud
3. s3
4. gitlab_secure_files

→ 1 (git 선택)

URL of the Git Repo:
→ https://github.com/lppresident/coworkfit-certificates.git
(위에서 생성한 저장소 URL)
```

### 2️⃣ Matchfile 확인

`ios/fastlane/Matchfile` 파일이 생성됩니다:

```ruby
git_url("https://github.com/lppresident/coworkfit-certificates.git")

storage_mode("git")

type("development") # The default type, can be: appstore, adhoc, enterprise or development
```

### 3️⃣ Matchfile 수정 (선택사항)

더 명확하게 설정하려면:

```ruby
git_url("https://github.com/lppresident/coworkfit-certificates.git")
storage_mode("git")

app_identifier("com.hansol.coworkfit")
username("your-apple-id@example.com") # Apple ID
team_id("DRPP364BVT") # Apple Team ID
```

---

## 인증서 생성

### 1️⃣ 환경 변수 설정

```bash
# GitHub Personal Access Token 설정
export MATCH_GIT_BASIC_AUTHORIZATION=$(echo -n "your-github-username:ghp_your_token" | base64)

# Match 암호 설정 (나중에 GitHub Secrets에도 사용)
export MATCH_PASSWORD="your-secure-password-here"
```

**암호 규칙:**
- 최소 8자 이상
- 안전한 암호 사용 (나중에 필요!)
- **절대 잊지 마세요!**

### 2️⃣ Development 인증서 생성

```bash
cd ios
fastlane match development
```

**물어보는 것들:**

```
Apple ID:
→ (자동으로 채워져 있음, Enter)

Team ID:
→ (목록에서 선택 또는 입력)

Passphrase for Git Repo:
→ (위에서 설정한 MATCH_PASSWORD 입력, 두 번)
```

### 3️⃣ Ad-Hoc 인증서 생성 (Firebase 배포용)

```bash
fastlane match adhoc
```

### 4️⃣ App Store 인증서 생성 (TestFlight용)

```bash
fastlane match appstore
```

### 5️⃣ 확인

인증서가 생성되었는지 확인:

```bash
# Git 저장소 확인
git clone https://github.com/lppresident/coworkfit-certificates.git /tmp/certs
ls -la /tmp/certs
# certs/, profiles/ 폴더가 있어야 함
```

---

## GitHub Secrets 설정

### 필요한 Secrets

다음 3개의 Secrets를 GitHub에 추가합니다:

#### 1️⃣ MATCH_PASSWORD

Match로 인증서를 암호화할 때 사용한 암호입니다.

```
위에서 설정한 암호
```

#### 2️⃣ MATCH_GIT_BASIC_AUTHORIZATION

GitHub Personal Access Token을 Base64로 인코딩한 값입니다.

```bash
# 생성 방법
echo -n "your-github-username:ghp_your_token" | base64
```

**예시:**
```bash
echo -n "lppresident:ghp_xxxxxxxxxxxx" | base64
# 출력: bHByZXNpZGVudDpnaHBfeHh4eHh4eHh4eHh4
```

#### 3️⃣ MATCH_GIT_URL

인증서 저장소 URL입니다.

```
https://github.com/lppresident/coworkfit-certificates.git
```

### GitHub Secrets 추가

1. https://github.com/lppresident/co-workfit/settings/secrets/actions 접속
2. **New repository secret** 클릭
3. 3개 Secret 추가:

**Secret 1:**
- Name: `MATCH_PASSWORD`
- Secret: (Match 암호)

**Secret 2:**
- Name: `MATCH_GIT_BASIC_AUTHORIZATION`
- Secret: (Base64 인코딩된 토큰)

**Secret 3:**
- Name: `MATCH_GIT_URL`
- Secret: `https://github.com/lppresident/coworkfit-certificates.git`

---

## 테스트

### 로컬에서 테스트

```bash
cd ios

# Match로 인증서 다운로드 테스트
fastlane match adhoc --readonly

# iOS 빌드 테스트
cd ..
flutter build ipa --release
```

성공하면 `build/ios/ipa/co_workfit.ipa` 파일이 생성됩니다!

---

## 트러블슈팅

### 문제 1: "Passphrase is incorrect"

**원인**: MATCH_PASSWORD가 틀렸습니다.

**해결:**
```bash
# 올바른 암호로 다시 설정
export MATCH_PASSWORD="correct-password"
fastlane match adhoc --readonly
```

### 문제 2: "Invalid credentials"

**원인**: GitHub Token이 만료되었거나 권한이 없습니다.

**해결:**
1. GitHub에서 Token 재생성
2. `MATCH_GIT_BASIC_AUTHORIZATION` 재설정

### 문제 3: "No certificates found"

**원인**: 인증서가 아직 생성되지 않았습니다.

**해결:**
```bash
cd ios
fastlane match adhoc  # readonly 빼고 실행
```

### 문제 4: "Team ID not found"

**원인**: Apple Team ID가 잘못되었습니다.

**해결:**
1. https://developer.apple.com/account 접속
2. Membership에서 Team ID 확인
3. Matchfile에서 `team_id` 수정

### 문제 5: GitHub Actions에서 실패

**원인**: Secrets가 올바르게 설정되지 않았습니다.

**해결:**
1. GitHub Secrets 확인
2. Secret 이름 대소문자 확인
3. Base64 인코딩 다시 확인

---

## 📚 참고 자료

- [Fastlane Match 공식 문서](https://docs.fastlane.tools/actions/match/)
- [Fastlane 설치 가이드](https://docs.fastlane.tools/getting-started/ios/setup/)
- [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

---

## ✅ 완료 체크리스트

- [ ] Fastlane 설치
- [ ] 인증서 저장소 생성 (Private)
- [ ] GitHub Personal Access Token 생성
- [ ] Match 초기화
- [ ] Development 인증서 생성
- [ ] Ad-Hoc 인증서 생성
- [ ] App Store 인증서 생성
- [ ] GitHub Secrets 3개 추가
  - [ ] MATCH_PASSWORD
  - [ ] MATCH_GIT_BASIC_AUTHORIZATION
  - [ ] MATCH_GIT_URL
- [ ] 로컬 빌드 테스트
- [ ] GitHub Actions 배포 테스트

---

**작성일**: 2025-12-26
**버전**: 1.0
**관련 이슈**: #35, #41
