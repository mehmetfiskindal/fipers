#!/bin/bash
# Build OpenSSL for Android
# This script builds OpenSSL for all Android ABIs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENSSL_VERSION="3.3.0"
OPENSSL_DIR="${PROJECT_ROOT}/third_party/openssl"
BUILD_DIR="${OPENSSL_DIR}/build"

# Android NDK path
if [ -z "$ANDROID_NDK" ]; then
    if [ -n "$ANDROID_HOME" ]; then
        # Try newer NDK location first (ndk/version)
        if [ -d "${ANDROID_HOME}/ndk" ]; then
            LATEST_NDK=$(ls -1 "${ANDROID_HOME}/ndk" 2>/dev/null | sort -V | tail -1)
            if [ -n "$LATEST_NDK" ] && [ -d "${ANDROID_HOME}/ndk/${LATEST_NDK}" ]; then
                ANDROID_NDK="${ANDROID_HOME}/ndk/${LATEST_NDK}"
            fi
        fi
        # Fallback to old location
        if [ ! -d "$ANDROID_NDK" ] && [ -d "${ANDROID_HOME}/ndk-bundle" ]; then
            ANDROID_NDK="${ANDROID_HOME}/ndk-bundle"
        fi
    fi
fi

if [ ! -d "$ANDROID_NDK" ]; then
    echo "❌ Error: Android NDK not found."
    echo "   Set ANDROID_NDK environment variable or ensure ANDROID_HOME is set."
    echo "   Current ANDROID_HOME: ${ANDROID_HOME:-not set}"
    echo "   Tried: ${ANDROID_HOME}/ndk/* and ${ANDROID_HOME}/ndk-bundle"
    exit 1
fi

echo "📦 Building OpenSSL ${OPENSSL_VERSION} for Android"
echo "   NDK: ${ANDROID_NDK}"
echo "   Output: ${OPENSSL_DIR}/libs"

# Create directories
mkdir -p "${OPENSSL_DIR}"
mkdir -p "${BUILD_DIR}"

# Download OpenSSL if not exists
OPENSSL_SOURCE="${OPENSSL_DIR}/openssl-${OPENSSL_VERSION}"
if [ ! -d "${OPENSSL_SOURCE}" ]; then
    echo "📥 Downloading OpenSSL ${OPENSSL_VERSION}..."
    cd "${OPENSSL_DIR}"
    curl -L "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -o "openssl-${OPENSSL_VERSION}.tar.gz"
    tar -xzf "openssl-${OPENSSL_VERSION}.tar.gz"
fi

# Build for each ABI
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

for ABI in "${ABIS[@]}"; do
    echo ""
    echo "🔨 Building for ${ABI}..."
    
    case $ABI in
        armeabi-v7a)
            ARCH="arm"
            API_LEVEL=21
            ;;
        arm64-v8a)
            ARCH="arm64"
            API_LEVEL=21
            ;;
        x86)
            ARCH="x86"
            API_LEVEL=21
            ;;
        x86_64)
            ARCH="x86_64"
            API_LEVEL=21
            ;;
    esac
    
    BUILD_ABI_DIR="${BUILD_DIR}/${ABI}"
    mkdir -p "${BUILD_ABI_DIR}"
    cd "${BUILD_ABI_DIR}"
    
    # Configure OpenSSL for Android
    # Set environment variables for Android NDK
    export ANDROID_NDK_HOME="${ANDROID_NDK}"
    export ANDROID_NDK="${ANDROID_NDK}"
    export PATH="${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/bin:${PATH}"
    
    # Build with -fPIC for shared library compatibility
    # Android shared libraries require Position Independent Code
    # Both CFLAGS and ASFLAGS need -fPIC for assembly code
    export CFLAGS="-fPIC"
    export ASFLAGS="-fPIC"
    
    "${OPENSSL_SOURCE}/Configure" \
        android-${ARCH} \
        -D__ANDROID_API__=${API_LEVEL} \
        --prefix="${OPENSSL_DIR}/libs/${ABI}" \
        --openssldir="${OPENSSL_DIR}/libs/${ABI}" \
        no-shared \
        no-asm \
        no-tests \
        -DANDROID_NDK_HOME="${ANDROID_NDK}" \
        -DANDROID_NDK="${ANDROID_NDK}"
    
    # Clean previous build to ensure -fPIC is applied
    make clean 2>/dev/null || true
    
    # Build
    make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    make install_sw
    
    echo "✅ Built OpenSSL for ${ABI}"
done

# Copy headers
echo ""
echo "📋 Copying headers..."
mkdir -p "${OPENSSL_DIR}/include"
cp -r "${OPENSSL_DIR}/libs/arm64-v8a/include/"* "${OPENSSL_DIR}/include/"

echo ""
echo "✅ OpenSSL build complete!"
echo "   Libraries: ${OPENSSL_DIR}/libs/{ABI}/"
echo "   Headers: ${OPENSSL_DIR}/include/"
