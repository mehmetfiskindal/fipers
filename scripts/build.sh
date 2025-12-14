#!/bin/bash
# Build script for Fipers native library
# Supports: Android, Linux, Windows

set -e

PLATFORM=$1
BUILD_TYPE=${2:-Release}

if [ -z "$PLATFORM" ]; then
  echo "Usage: $0 <platform> [build_type]"
  echo "Platforms: android, linux, windows"
  echo "Build types: Debug, Release (default: Release)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

case $PLATFORM in
  android)
    echo "Building for Android..."
    cd "$PROJECT_ROOT/android"
    mkdir -p build
    cd build
    
    # Android NDK path (adjust as needed)
    ANDROID_NDK=${ANDROID_NDK:-$ANDROID_HOME/ndk-bundle}
    if [ ! -d "$ANDROID_NDK" ]; then
      echo "Error: Android NDK not found. Set ANDROID_NDK or ANDROID_HOME"
      exit 1
    fi
    
    cmake .. \
      -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-21 \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE
    
    cmake --build . --config $BUILD_TYPE
    echo "Android build complete!"
    ;;
    
  linux)
    echo "Building for Linux..."
    cd "$PROJECT_ROOT/linux"
    mkdir -p build
    cd build
    
    cmake .. \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE
    
    cmake --build . --config $BUILD_TYPE
    echo "Linux build complete!"
    ;;
    
  windows)
    echo "Building for Windows..."
    cd "$PROJECT_ROOT/windows"
    mkdir -p build
    cd build
    
    cmake .. \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      -G "Visual Studio 17 2022" \
      -A x64
    
    cmake --build . --config $BUILD_TYPE
    echo "Windows build complete!"
    ;;
    
  *)
    echo "Unknown platform: $PLATFORM"
    exit 1
    ;;
esac

