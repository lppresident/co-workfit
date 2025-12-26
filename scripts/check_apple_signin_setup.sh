#!/bin/bash

# Co-WorkFit Apple Sign-In 설정 확인 스크립트
# 이 스크립트는 Apple Sign-In 설정이 올바르게 되어 있는지 확인합니다.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="✓"
CROSS="✗"
WARN="⚠"
INFO="ℹ"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Co-WorkFit Apple Sign-In 설정 확인${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}${WARN} 이 스크립트는 macOS에서만 실행할 수 있습니다.${NC}"
    echo -e "${YELLOW}${WARN} iOS 설정 확인은 macOS에서 진행해주세요.${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    local status=$1
    local message=$2

    if [ "$status" = "success" ]; then
        echo -e "${GREEN}${CHECK} ${message}${NC}"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}${CROSS} ${message}${NC}"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}${WARN} ${message}${NC}"
    else
        echo -e "${BLUE}${INFO} ${message}${NC}"
    fi
}

# Check Flutter
echo -e "${BLUE}1. Flutter 환경 확인${NC}"
if command_exists flutter; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_status "success" "Flutter 설치됨: $FLUTTER_VERSION"
else
    print_status "error" "Flutter가 설치되지 않았습니다."
    exit 1
fi
echo ""

# Check pubspec.yaml for sign_in_with_apple package
echo -e "${BLUE}2. sign_in_with_apple 패키지 확인${NC}"
if grep -q "sign_in_with_apple:" pubspec.yaml; then
    PACKAGE_VERSION=$(grep "sign_in_with_apple:" pubspec.yaml | awk '{print $2}')
    print_status "success" "sign_in_with_apple 패키지 설치됨: $PACKAGE_VERSION"
else
    print_status "error" "sign_in_with_apple 패키지가 pubspec.yaml에 없습니다."
    echo -e "${YELLOW}  다음 명령어로 추가하세요:${NC}"
    echo -e "  ${YELLOW}flutter pub add sign_in_with_apple${NC}"
    exit 1
fi
echo ""

# Check iOS Entitlements
echo -e "${BLUE}3. iOS Entitlements 확인${NC}"
ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"

if [ -f "$ENTITLEMENTS_FILE" ]; then
    print_status "success" "Entitlements 파일 존재: $ENTITLEMENTS_FILE"

    if grep -q "com.apple.developer.applesignin" "$ENTITLEMENTS_FILE"; then
        print_status "success" "Apple Sign-In entitlement 설정됨"
    else
        print_status "error" "Apple Sign-In entitlement가 설정되지 않았습니다."
        echo -e "${YELLOW}  $ENTITLEMENTS_FILE 파일에 다음 내용을 추가하세요:${NC}"
        echo -e "${YELLOW}  <key>com.apple.developer.applesignin</key>${NC}"
        echo -e "${YELLOW}  <array>${NC}"
        echo -e "${YELLOW}    <string>Default</string>${NC}"
        echo -e "${YELLOW}  </array>${NC}"
        exit 1
    fi
else
    print_status "error" "Entitlements 파일이 없습니다: $ENTITLEMENTS_FILE"
    exit 1
fi
echo ""

# Check UseCase file
echo -e "${BLUE}4. Apple Sign-In UseCase 확인${NC}"
USECASE_FILE="lib/features/auth/domain/usecases/sign_in_with_apple.dart"

if [ -f "$USECASE_FILE" ]; then
    print_status "success" "SignInWithApple UseCase 파일 존재"
else
    print_status "error" "SignInWithApple UseCase 파일이 없습니다: $USECASE_FILE"
    exit 1
fi
echo ""

# Check Xcode project (if Xcode is installed)
echo -e "${BLUE}5. Xcode 프로젝트 확인${NC}"
if command_exists xcodebuild; then
    print_status "success" "Xcode 설치됨"

    # Check Bundle ID
    BUNDLE_ID=$(grep -A1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | grep "= com" | head -n1 | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
    if [ -n "$BUNDLE_ID" ]; then
        print_status "info" "Bundle ID: $BUNDLE_ID"

        if [ "$BUNDLE_ID" = "com.hansol.coworkfit" ]; then
            print_status "success" "Bundle ID가 올바릅니다: com.hansol.coworkfit"
        else
            print_status "warning" "Bundle ID가 예상과 다릅니다. 확인 필요: $BUNDLE_ID"
        fi
    fi
else
    print_status "warning" "Xcode가 설치되지 않았습니다. iOS 빌드를 위해 Xcode를 설치해주세요."
fi
echo ""

# Check iOS deployment target
echo -e "${BLUE}6. iOS Deployment Target 확인${NC}"
IOS_TARGET=$(grep -A1 "IPHONEOS_DEPLOYMENT_TARGET" ios/Podfile | grep "platform" | sed 's/.*platform.*'\''ios'\'',.*'\''\(.*\)'\''.*/\1/')
if [ -z "$IOS_TARGET" ]; then
    IOS_TARGET=$(grep "platform :ios" ios/Podfile | sed "s/.*platform :ios, '\(.*\)'/\1/")
fi

if [ -n "$IOS_TARGET" ]; then
    print_status "info" "iOS Deployment Target: $IOS_TARGET"

    # Apple Sign-In requires iOS 13.0+
    if [ "${IOS_TARGET%%.*}" -ge 13 ]; then
        print_status "success" "iOS 13.0 이상 (Apple Sign-In 지원)"
    else
        print_status "error" "iOS 13.0 미만입니다. Apple Sign-In은 iOS 13.0 이상이 필요합니다."
        echo -e "${YELLOW}  ios/Podfile에서 플랫폼 버전을 13.0 이상으로 설정하세요.${NC}"
    fi
else
    print_status "warning" "iOS Deployment Target을 확인할 수 없습니다."
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  설정 확인 완료${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
print_status "success" "모든 코드 및 iOS 설정이 완료되었습니다!"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. ${BLUE}Apple Developer Program 가입${NC} ($99/년)"
echo -e "     https://developer.apple.com/programs/"
echo ""
echo -e "  2. ${BLUE}Apple Developer Portal 설정${NC}"
echo -e "     - App ID에 Sign in with Apple capability 활성화"
echo -e "     - Bundle ID: com.hansol.coworkfit"
echo ""
echo -e "  3. ${BLUE}Firebase Console 설정${NC}"
echo -e "     - Authentication > Sign-in method > Apple 활성화"
echo ""
echo -e "  4. ${BLUE}테스트${NC}"
echo -e "     - 실제 iOS 기기에서 테스트 (iOS 13.0 이상)"
echo -e "     - flutter run -d <ios-device-id>"
echo ""
echo -e "${GREEN}자세한 설정 방법은 docs/APPLE_SIGNIN_SETUP.md를 참고하세요.${NC}"
echo ""
