#!/bin/bash
# Setup script for Android development environment
# Source this file before running Android-related commands: source scripts/setup-env.sh

echo "Setting up Android development environment..."

# Java setup
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation
if [ -x "$JAVA_HOME/bin/java" ]; then
    echo "✅ Java found: $($JAVA_HOME/bin/java --version | head -n 1)"
else
    echo "❌ Java not found at $JAVA_HOME"
    echo "Please install Java: brew install openjdk@17"
    return 1
fi

# Android SDK (optional - uncomment if needed)
# if [ -d "$HOME/Library/Android/sdk" ]; then
#     export ANDROID_HOME=$HOME/Library/Android/sdk
#     export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
#     echo "✅ Android SDK found"
# fi

echo "✅ Environment setup complete!"
echo ""
echo "You can now run Android development commands:"
echo "  - keytool (for SHA-1 fingerprints)"
echo "  - ./gradlew (for Gradle tasks)"
