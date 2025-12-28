#!/bin/bash

# Fastlane Match 설정 스크립트
# 이 스크립트는 Fastlane Match를 처음 설정할 때 사용합니다.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fastlane Match 설정${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}이 스크립트는 macOS에서만 실행할 수 있습니다.${NC}"
    exit 1
fi

# Check if Fastlane is installed
if ! command -v fastlane &> /dev/null; then
    echo -e "${YELLOW}Fastlane이 설치되지 않았습니다. 설치를 진행합니다...${NC}"
    sudo gem install fastlane
    echo -e "${GREEN}✓ Fastlane 설치 완료${NC}"
else
    echo -e "${GREEN}✓ Fastlane이 이미 설치되어 있습니다.${NC}"
fi

echo ""
echo -e "${BLUE}1. 인증서 저장소 설정${NC}"
echo -e "${YELLOW}인증서를 저장할 비공개 GitHub 저장소를 생성하셨나요?${NC}"
echo -e "예: https://github.com/lppresident/coworkfit-certificates"
read -p "저장소 URL을 입력하세요: " MATCH_GIT_URL

if [ -z "$MATCH_GIT_URL" ]; then
    echo -e "${RED}저장소 URL이 필요합니다.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}2. GitHub Personal Access Token 설정${NC}"
echo -e "${YELLOW}GitHub Personal Access Token을 생성하셨나요?${NC}"
echo -e "생성 방법: https://github.com/settings/tokens"
read -sp "GitHub Token을 입력하세요: " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}GitHub Token이 필요합니다.${NC}"
    exit 1
fi

# GitHub username 추출
GITHUB_USERNAME=$(echo "$MATCH_GIT_URL" | sed -n 's|.*/github.com/\([^/]*\)/.*|\1|p')
echo -e "${GREEN}✓ GitHub Username: $GITHUB_USERNAME${NC}"

# Base64 인코딩
MATCH_GIT_BASIC_AUTH=$(echo -n "$GITHUB_USERNAME:$GITHUB_TOKEN" | base64)

echo ""
echo -e "${BLUE}3. Match 암호 설정${NC}"
echo -e "${YELLOW}인증서를 암호화할 비밀번호를 입력하세요 (최소 8자)${NC}"
read -sp "MATCH_PASSWORD: " MATCH_PASSWORD
echo ""
read -sp "MATCH_PASSWORD 확인: " MATCH_PASSWORD_CONFIRM
echo ""

if [ "$MATCH_PASSWORD" != "$MATCH_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}비밀번호가 일치하지 않습니다.${NC}"
    exit 1
fi

if [ ${#MATCH_PASSWORD} -lt 8 ]; then
    echo -e "${RED}비밀번호는 최소 8자 이상이어야 합니다.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}4. 환경 변수 설정${NC}"
export MATCH_GIT_URL="$MATCH_GIT_URL"
export MATCH_GIT_BASIC_AUTHORIZATION="$MATCH_GIT_BASIC_AUTH"
export MATCH_PASSWORD="$MATCH_PASSWORD"

echo -e "${GREEN}✓ 환경 변수 설정 완료${NC}"

echo ""
echo -e "${BLUE}5. Matchfile 업데이트${NC}"
cat > ios/fastlane/Matchfile << EOF
git_url("$MATCH_GIT_URL")

storage_mode("git")

type("adhoc") # Default type

app_identifier(["com.hansol.coworkfit"])

# Apple Team ID
team_id("DRPP364BVT")
EOF

echo -e "${GREEN}✓ Matchfile 생성 완료${NC}"

echo ""
echo -e "${BLUE}6. Match 인증서 생성${NC}"
echo -e "${YELLOW}Apple ID와 Team ID가 필요합니다.${NC}"
read -p "계속하시겠습니까? (y/n): " CONTINUE

if [ "$CONTINUE" != "y" ]; then
    echo -e "${YELLOW}나중에 다음 명령어로 인증서를 생성하세요:${NC}"
    echo -e "  cd ios"
    echo -e "  fastlane match adhoc"
    echo -e "  fastlane match appstore"
    exit 0
fi

cd ios

echo ""
echo -e "${BLUE}6-1. Ad-Hoc 인증서 생성 (Firebase 배포용)${NC}"
fastlane match adhoc

echo ""
echo -e "${BLUE}6-2. App Store 인증서 생성 (TestFlight 배포용)${NC}"
fastlane match appstore

cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  설정 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}다음 단계:${NC}"
echo ""
echo -e "1. ${YELLOW}GitHub Secrets 추가${NC}"
echo -e "   https://github.com/lppresident/co-workfit/settings/secrets/actions"
echo ""
echo -e "   ${GREEN}MATCH_PASSWORD:${NC}"
echo -e "   $MATCH_PASSWORD"
echo ""
echo -e "   ${GREEN}MATCH_GIT_BASIC_AUTHORIZATION:${NC}"
echo -e "   $MATCH_GIT_BASIC_AUTH"
echo ""
echo -e "   ${GREEN}MATCH_GIT_URL:${NC}"
echo -e "   $MATCH_GIT_URL"
echo ""
echo -e "2. ${YELLOW}GitHub Actions에서 iOS 배포 실행${NC}"
echo -e "   https://github.com/lppresident/co-workfit/actions"
echo ""
echo -e "${BLUE}자세한 내용은 docs/FASTLANE_MATCH_SETUP.md를 참고하세요.${NC}"
echo ""
