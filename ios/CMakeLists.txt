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

# For iOS, create a static library (preferred) or framework
# Static library is simpler for Flutter plugins
add_library(fipers STATIC ${NATIVE_SOURCES})

# Find OpenSSL
# On iOS, try to find OpenSSL in common locations
# For iOS Simulator, we can use homebrew OpenSSL
# For real devices, OpenSSL should be added via CocoaPods
find_package(OpenSSL QUIET)

if(NOT OpenSSL_FOUND)
  # Try to find OpenSSL in homebrew location (for iOS Simulator on macOS)
  # Check common homebrew locations
  set(HOMEBREW_PREFIX "/opt/homebrew")
  if(NOT EXISTS "${HOMEBREW_PREFIX}")
    set(HOMEBREW_PREFIX "/usr/local")
  endif()
  
  find_path(OPENSSL_INCLUDE_DIR
    NAMES openssl/evp.h
    PATHS
      "${HOMEBREW_PREFIX}/opt/openssl@3/include"
      "${HOMEBREW_PREFIX}/opt/openssl/include"
      "${HOMEBREW_PREFIX}/include"
      /usr/local/include
      /usr/include
  )
  
  find_library(OPENSSL_SSL_LIB
    NAMES ssl libssl
    PATHS
      "${HOMEBREW_PREFIX}/opt/openssl@3/lib"
      "${HOMEBREW_PREFIX}/opt/openssl/lib"
      "${HOMEBREW_PREFIX}/lib"
      /usr/local/lib
      /usr/lib
  )
  
  find_library(OPENSSL_CRYPTO_LIB
    NAMES crypto libcrypto
    PATHS
      "${HOMEBREW_PREFIX}/opt/openssl@3/lib"
      "${HOMEBREW_PREFIX}/opt/openssl/lib"
      "${HOMEBREW_PREFIX}/lib"
      /usr/local/lib
      /usr/lib
  )
  
  if(OPENSSL_INCLUDE_DIR AND OPENSSL_SSL_LIB AND OPENSSL_CRYPTO_LIB)
    target_include_directories(fipers PRIVATE ${OPENSSL_INCLUDE_DIR})
    target_link_libraries(fipers PRIVATE ${OPENSSL_SSL_LIB} ${OPENSSL_CRYPTO_LIB})
    message(STATUS "Found OpenSSL: ${OPENSSL_INCLUDE_DIR}")
    message(STATUS "OpenSSL SSL lib: ${OPENSSL_SSL_LIB}")
    message(STATUS "OpenSSL Crypto lib: ${OPENSSL_CRYPTO_LIB}")
  else()
    message(FATAL_ERROR "OpenSSL not found. For iOS, you need to add OpenSSL via CocoaPods or install via Homebrew. Include: ${OPENSSL_INCLUDE_DIR}, SSL: ${OPENSSL_SSL_LIB}, Crypto: ${OPENSSL_CRYPTO_LIB}")
  endif()
else()
  target_link_libraries(fipers PRIVATE OpenSSL::SSL OpenSSL::Crypto)
endif()

# Set output directory
set_target_properties(fipers PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
)
