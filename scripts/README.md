# Fipers Build Scripts

This directory contains build and integration scripts for the fipers package.

## Build Scripts

### `build.sh`
Builds the native library for different platforms.

**Usage:**
```bash
./scripts/build.sh <platform> [build_type]
```

**Platforms:** `android`, `linux`, `windows`, `macos`, `ios`

**Build types:** `Debug`, `Release` (default: `Release`)

**Examples:**
```bash
./scripts/build.sh ios Release
./scripts/build.sh macos Release
./scripts/build.sh linux Release
```

### `integrate_ios_library.py`
Automatically integrates the iOS static library into a Flutter iOS project.

**Usage:**
```bash
# Run from your Flutter project root (e.g., fipers/example)
cd your_flutter_project
python3 path/to/fipers/scripts/integrate_ios_library.py
```

**What it does:**
1. Builds the iOS static library automatically
2. Copies it to `ios/Frameworks/libfipers.a`
3. Adds it to Xcode project file references
4. Adds it to Frameworks group
5. Adds it to Link Binary With Libraries build phase
6. Adds library search paths and link flags to build settings

**Requirements:**
- Python 3.6+
- Xcode project must exist at `ios/Runner.xcodeproj/project.pbxproj`

### `setup_ios_library.sh`
Builds the iOS library and provides instructions for manual integration.

**Usage:**
```bash
cd fipers
./scripts/setup_ios_library.sh
```

### `fipers_ios_build.sh`
Flutter iOS build hook (for future automatic integration during Flutter builds).

## Platform-Specific Notes

### iOS
- Requires OpenSSL (via CocoaPods or Homebrew for Simulator)
- Builds a static library (`.a` file)
- Must be integrated into Xcode project
- Supports both iOS Simulator (x86_64, arm64) and iOS devices (arm64)

### macOS
- Requires OpenSSL (via Homebrew)
- Builds a dynamic library (`.dylib` file)
- Automatically copied to app bundle during Flutter build

### Linux
- Requires OpenSSL development libraries (`libssl-dev`)
- Builds a shared library (`.so` file)
- Automatically copied to app bundle during Flutter build

### Windows
- Requires OpenSSL (via vcpkg or manual installation)
- Builds a dynamic library (`.dll` file)
- Automatically copied to app bundle during Flutter build

### Android
- OpenSSL included via NDK or CMake
- Builds a shared library (`.so` file)
- Automatically integrated via Android build system
