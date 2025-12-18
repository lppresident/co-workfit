#!/bin/bash

# CoWorkfit APK 배포 스크립트
# 사용법: ./scripts/deploy_apk.sh [version_bump_type] [release_notes]
# version_bump_type: major, minor, patch, build (기본값: build)
# release_notes: 릴리스 노트 (기본값: "New test release")

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 에러 메시지 출력
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# 함수: 성공 메시지 출력
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 함수: 정보 메시지 출력
info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# 함수: 버전 번호 증가
bump_version() {
    local version_file="pubspec.yaml"
    local bump_type="${1:-build}"

    # 현재 버전 읽기
    local current_version=$(grep "^version:" "$version_file" | sed 's/version: //')
    local version_name=$(echo "$current_version" | cut -d'+' -f1)
    local build_number=$(echo "$current_version" | cut -d'+' -f2)

    info "현재 버전: $current_version"

    # 버전 번호 분리
    local major=$(echo "$version_name" | cut -d'.' -f1)
    local minor=$(echo "$version_name" | cut -d'.' -f2)
    local patch=$(echo "$version_name" | cut -d'.' -f3)

    # 버전 증가
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            build_number=1
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            build_number=1
            ;;
        patch)
            patch=$((patch + 1))
            build_number=1
            ;;
        build)
            build_number=$((build_number + 1))
            ;;
        *)
            error "잘못된 버전 타입: $bump_type (major, minor, patch, build 중 하나를 사용하세요)"
            ;;
    esac

    local new_version="$major.$minor.$patch+$build_number"

    # pubspec.yaml 업데이트
    sed -i.bak "s/^version: .*/version: $new_version/" "$version_file"
    rm -f "${version_file}.bak"

    success "버전 업데이트: $current_version → $new_version"
    echo "$new_version"
}

# 함수: APK 빌드
build_apk() {
    info "Flutter 프로젝트 클린업..."
    flutter clean

    info "의존성 설치..."
    flutter pub get

    info "APK 빌드 중..."
    flutter build apk --release

    success "APK 빌드 완료"

    # 빌드된 APK 경로
    echo "build/app/outputs/flutter-apk/app-release.apk"
}

# 함수: APK 정보 출력
show_apk_info() {
    local apk_path="$1"
    local version="$2"

    if [ ! -f "$apk_path" ]; then
        error "APK 파일을 찾을 수 없습니다: $apk_path"
    fi

    local file_size=$(du -h "$apk_path" | cut -f1)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "배포 준비 완료!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "버전: $version"
    echo "파일: $apk_path"
    echo "크기: $file_size"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 함수: Firebase App Distribution에 배포
deploy_to_firebase() {
    local apk_path="$1"
    local version="$2"
    local release_notes="${3:-New test release}"

    info "Firebase App Distribution에 배포 중..."

    # Firebase CLI 확인
    if ! command -v firebase &> /dev/null; then
        error "Firebase CLI가 설치되어 있지 않습니다. 'npm install -g firebase-tools'로 설치하세요."
    fi

    # Firebase 앱 ID 확인
    if [ -z "$FIREBASE_APP_ID" ]; then
        error "FIREBASE_APP_ID 환경 변수가 설정되어 있지 않습니다."
    fi

    # 테스터 그룹 (기본값: testers)
    local tester_groups="${FIREBASE_TESTER_GROUPS:-testers}"

    firebase appdistribution:distribute "$apk_path" \
        --app "$FIREBASE_APP_ID" \
        --groups "$tester_groups" \
        --release-notes "$release_notes - Version: $version"

    success "Firebase App Distribution에 배포 완료"
}

# 함수: GitHub Release 생성
create_github_release() {
    local apk_path="$1"
    local version="$2"
    local release_notes="${3:-New test release}"

    info "GitHub Release 생성 중..."

    # gh CLI 확인
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI가 설치되어 있지 않습니다. https://cli.github.com/ 에서 설치하세요."
    fi

    # 태그 생성
    local tag="v$version"

    # Release 생성
    gh release create "$tag" "$apk_path" \
        --title "CoWorkfit v$version" \
        --notes "$release_notes" \
        --prerelease

    success "GitHub Release 생성 완료: $tag"
}

# 메인 로직
main() {
    local version_bump="${1:-build}"
    local release_notes="${2:-New test release}"
    local deploy_method="${DEPLOY_METHOD:-local}"

    info "CoWorkfit APK 배포 스크립트 시작"
    echo ""

    # 1. 버전 증가
    local new_version=$(bump_version "$version_bump")

    # 2. APK 빌드
    local apk_path=$(build_apk)

    # 3. APK 정보 출력
    show_apk_info "$apk_path" "$new_version"

    # 4. 배포
    case "$deploy_method" in
        firebase)
            deploy_to_firebase "$apk_path" "$new_version" "$release_notes"
            ;;
        github)
            create_github_release "$apk_path" "$new_version" "$release_notes"
            ;;
        both)
            deploy_to_firebase "$apk_path" "$new_version" "$release_notes"
            create_github_release "$apk_path" "$new_version" "$release_notes"
            ;;
        local)
            info "로컬 빌드만 수행. APK를 수동으로 배포하세요."
            ;;
        *)
            error "잘못된 배포 방법: $deploy_method (local, firebase, github, both 중 하나를 사용하세요)"
            ;;
    esac

    echo ""
    success "모든 작업이 완료되었습니다!"

    # Git 변경사항 커밋 여부 확인
    if git diff --quiet pubspec.yaml; then
        info "버전 변경사항이 없습니다."
    else
        echo ""
        info "버전이 업데이트되었습니다. Git에 커밋하시겠습니까?"
        echo "다음 명령어를 실행하세요:"
        echo "  git add pubspec.yaml"
        echo "  git commit -m \"chore: Bump version to $new_version\""
        echo "  git push"
    fi
}

# 스크립트 실행
main "$@"
