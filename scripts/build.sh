#!/bin/bash
# Build script for Fipers native library
# Supports: Android, Linux, Windows, macOS

set -e

PLATFORM=$1
BUILD_TYPE=${2:-Release}

if [ -z "$PLATFORM" ]; then
  echo "Usage: $0 <platform> [build_type]"
  echo "Platforms: android, linux, windows, macos, ios"
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
    
  macos)
    echo "Building for macOS..."
    cd "$PROJECT_ROOT/macos"
    mkdir -p build
    cd build
    
    cmake .. \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE
    
    cmake --build . --config $BUILD_TYPE
    echo "macOS build complete!"
    echo "Library location: $PWD/libfipers.dylib"
    ;;
    
  ios)
    echo "Building for iOS..."
    cd "$PROJECT_ROOT/ios"
    mkdir -p build
    cd build
    
    # Get iOS SDK path
    IOS_SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null || xcrun --sdk iphoneos --show-sdk-path)
    
    # Try to find OpenSSL in homebrew
    HOMEBREW_PREFIX="/opt/homebrew"
    if [ ! -d "$HOMEBREW_PREFIX" ]; then
      HOMEBREW_PREFIX="/usr/local"
    fi
    
    OPENSSL_INCLUDE="${HOMEBREW_PREFIX}/opt/openssl@3/include"
    OPENSSL_SSL_LIB="${HOMEBREW_PREFIX}/opt/openssl@3/lib/libssl.a"
    OPENSSL_CRYPTO_LIB="${HOMEBREW_PREFIX}/opt/openssl@3/lib/libcrypto.a"
    
    # Fallback to openssl (without version)
    if [ ! -d "$OPENSSL_INCLUDE" ]; then
      OPENSSL_INCLUDE="${HOMEBREW_PREFIX}/opt/openssl/include"
      OPENSSL_SSL_LIB="${HOMEBREW_PREFIX}/opt/openssl/lib/libssl.a"
      OPENSSL_CRYPTO_LIB="${HOMEBREW_PREFIX}/opt/openssl/lib/libcrypto.a"
    fi
    
    # iOS requires specific toolchain
    cmake .. \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
      -DCMAKE_OSX_SYSROOT="$IOS_SDK_PATH" \
      -DOPENSSL_INCLUDE_DIR="$OPENSSL_INCLUDE" \
      -DOPENSSL_SSL_LIB="$OPENSSL_SSL_LIB" \
      -DOPENSSL_CRYPTO_LIB="$OPENSSL_CRYPTO_LIB"
    
    cmake --build . --config $BUILD_TYPE
    echo "iOS build complete!"
    echo "Library location: $PWD/libfipers.a"
    ;;
    
  *)
    echo "Unknown platform: $PLATFORM"
    exit 1
    ;;
esac

