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

# Create shared library (dylib for macOS)
add_library(fipers SHARED ${NATIVE_SOURCES})

# Find OpenSSL
find_package(OpenSSL REQUIRED)

# Link libraries
# For macOS, use shared libraries but set rpath
target_link_libraries(fipers PRIVATE OpenSSL::SSL OpenSSL::Crypto)

# Set install name to use @rpath for libfipers itself
set_target_properties(fipers PROPERTIES
  INSTALL_NAME "@rpath/libfipers.dylib"
)

# Set rpath for OpenSSL on macOS
# Use @rpath for both libfipers and OpenSSL dependencies
if(APPLE)
  set_target_properties(fipers PROPERTIES
    INSTALL_RPATH "@loader_path/../Frameworks"
    BUILD_WITH_INSTALL_RPATH TRUE
  )
  # Set install name to use @rpath
  set_target_properties(fipers PROPERTIES
    INSTALL_NAME_DIR "@rpath"
    BUILD_WITH_INSTALL_NAME_DIR TRUE
  )
endif()

# Set output directory
# For macOS, build to local build directory first, then copy to bundle during Flutter build
set_target_properties(fipers PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    MACOSX_RPATH ON
)
