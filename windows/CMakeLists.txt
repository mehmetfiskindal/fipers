cmake_minimum_required(VERSION 3.18.1)
project(fipers)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Define export macro for Windows
add_definitions(-DFIPERS_EXPORTS)

# Source files
set(NATIVE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/storage.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/crypto.c
)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/include
)

# Create shared library (DLL on Windows)
add_library(fipers SHARED ${NATIVE_SOURCES})

# Find OpenSSL
find_package(OpenSSL REQUIRED)

# Link libraries
target_link_libraries(fipers PRIVATE OpenSSL::SSL OpenSSL::Crypto)

# Set output directory
# For Windows, the DLL will be built into the example app's build directory
set_target_properties(fipers PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../example/build/windows/x64/debug/runner"
)

