#!/bin/bash
# Flutter iOS build hook for fipers library
# This script is automatically called during Flutter iOS builds
# to ensure the native library is built and integrated

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIPERS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if we're in a Flutter project that uses fipers
# Look for fipers in pubspec.yaml
if [ -f "pubspec.yaml" ] && grep -q "fipers:" pubspec.yaml; then
  # We're in a Flutter project that uses fipers
  FLUTTER_PROJECT_ROOT="$(pwd)"
  
  # Check if library is already integrated
  if [ -f "ios/Frameworks/libfipers.a" ] && [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    # Check if library is in Xcode project
    if grep -q "libfipers.a" "ios/Runner.xcodeproj/project.pbxproj"; then
      # Already integrated, just ensure library is up to date
      if [ "$FIPERS_ROOT/ios/build/libfipers.a" -nt "ios/Frameworks/libfipers.a" ]; then
        echo "Updating libfipers.a..."
        cp "$FIPERS_ROOT/ios/build/libfipers.a" "ios/Frameworks/libfipers.a"
      fi
      exit 0
    fi
  fi
  
  # Integrate library if not already done
  echo "Integrating fipers iOS library..."
  python3 "$SCRIPT_DIR/integrate_ios_library.py"
fi
