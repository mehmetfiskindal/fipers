cmake_minimum_required(VERSION 3.18.1)
project(fipers)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Source files
set(NATIVE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/storage.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/crypto.c
)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/include
)

# Create shared library
add_library(fipers SHARED ${NATIVE_SOURCES})

# Find OpenSSL for Android
# Android NDK doesn't include OpenSSL by default, so we need to build it separately
# The build script scripts/build_openssl_android.sh can build OpenSSL for all ABIs

# Try to find OpenSSL in the project directory first (if prebuilt)
set(OPENSSL_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openssl")
set(OPENSSL_INCLUDE_DIR "${OPENSSL_ROOT_DIR}/include")
# OpenSSL installs libraries in libs/${ABI}/lib/ directory
set(OPENSSL_SSL_LIB "${OPENSSL_ROOT_DIR}/libs/${ANDROID_ABI}/lib/libssl.a")
set(OPENSSL_CRYPTO_LIB "${OPENSSL_ROOT_DIR}/libs/${ANDROID_ABI}/lib/libcrypto.a")

if(EXISTS "${OPENSSL_INCLUDE_DIR}/openssl/evp.h" AND EXISTS "${OPENSSL_SSL_LIB}" AND EXISTS "${OPENSSL_CRYPTO_LIB}")
    target_include_directories(fipers PRIVATE ${OPENSSL_INCLUDE_DIR})
    target_link_libraries(fipers PRIVATE ${OPENSSL_SSL_LIB} ${OPENSSL_CRYPTO_LIB})
    message(STATUS "✅ Using prebuilt OpenSSL from: ${OPENSSL_ROOT_DIR}")
    message(STATUS "   Include: ${OPENSSL_INCLUDE_DIR}")
    message(STATUS "   SSL lib: ${OPENSSL_SSL_LIB}")
    message(STATUS "   Crypto lib: ${OPENSSL_CRYPTO_LIB}")
else()
    # Try standard find_package as fallback
    find_package(OpenSSL QUIET)
    if(OpenSSL_FOUND)
        target_link_libraries(fipers PRIVATE OpenSSL::SSL OpenSSL::Crypto)
        message(STATUS "✅ Found OpenSSL via find_package")
    else()
        message(FATAL_ERROR 
            "\n"
            "❌ OpenSSL not found for Android (ABI: ${ANDROID_ABI})\n"
            "\n"
            "To build OpenSSL for Android, run:\n"
            "  cd fipers\n"
            "  ./scripts/build_openssl_android.sh\n"
            "\n"
            "This will build OpenSSL and place it in:\n"
            "  ${OPENSSL_ROOT_DIR}/libs/${ANDROID_ABI}/\n"
            "\n"
            "Expected files:\n"
            "  - ${OPENSSL_INCLUDE_DIR}/openssl/evp.h\n"
            "  - ${OPENSSL_SSL_LIB}\n"
            "  - ${OPENSSL_CRYPTO_LIB}\n"
            "\n"
            "See README.md for more information.\n"
        )
    endif()
endif()

# Set output directory
# For Android, CMake will automatically place the library in the correct location
# The library will be built into the app's lib directory for each ABI
set_target_properties(fipers PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
)

