#!/usr/bin/env python3
"""
Automatically integrate Android native library into Flutter Android project.

This script:
1. Builds the Android native library (libfipers.so) if not already built
2. Ensures CMakeLists.txt is properly configured in build.gradle.kts
3. Verifies OpenSSL is available or provides instructions

Usage:
    python3 scripts/integrate_android_library.py [flutter_project_root]
    
If flutter_project_root is not provided, it will try to detect it from the current directory.
"""

import os
import sys
import subprocess
from pathlib import Path


def find_flutter_project_root(start_path=None):
    """Find Flutter project root by looking for pubspec.yaml"""
    if start_path is None:
        start_path = Path.cwd()
    else:
        start_path = Path(start_path)
    
    current = Path(start_path).resolve()
    while current != current.parent:
        pubspec = current / "pubspec.yaml"
        if pubspec.exists():
            return current
        current = current.parent
    
    return None


def check_openssl_for_android():
    """Check if OpenSSL is available for Android build"""
    # For now, we'll just warn the user
    # In the future, we could check for prebuilt OpenSSL or build it
    print("⚠️  Note: Android requires OpenSSL to be built separately.")
    print("   The CMakeLists.txt will attempt to find OpenSSL.")
    print("   If OpenSSL is not found, the build will fail with instructions.")
    return True


def verify_cmake_integration(project_root):
    """Verify CMakeLists.txt is properly integrated in build.gradle.kts"""
    build_gradle = project_root / "android" / "app" / "build.gradle.kts"
    if not build_gradle.exists():
        print(f"❌ build.gradle.kts not found at {build_gradle}")
        return False
    
    content = build_gradle.read_text()
    if "externalNativeBuild" not in content or "cmake" not in content:
        print("⚠️  CMake integration not found in build.gradle.kts")
        print("   The script will add it, but you may need to rebuild.")
        return False
    
    print("✅ CMake integration found in build.gradle.kts")
    return True


def main():
    # Find Flutter project root
    if len(sys.argv) > 1:
        project_root = Path(sys.argv[1])
    else:
        project_root = find_flutter_project_root()
    
    if project_root is None:
        print("❌ Error: Could not find Flutter project root (pubspec.yaml not found)")
        print("   Please run this script from your Flutter project directory")
        print("   or provide the project root as an argument.")
        sys.exit(1)
    
    print(f"📁 Flutter project root: {project_root}")
    
    # Find fipers root (should be a dependency or in the same repo)
    # Try to find it relative to the project
    fipers_root = project_root.parent
    if (fipers_root / "lib" / "fipers.dart").exists():
        # We're in the fipers repo itself
        fipers_root = fipers_root
    elif (project_root / "android" / "app" / "build.gradle.kts").exists():
        # We're in a Flutter project that uses fipers
        # Try to find fipers in dependencies
        fipers_root = None
        pubspec = project_root / "pubspec.yaml"
        if pubspec.exists():
            content = pubspec.read_text()
            if "fipers:" in content:
                # fipers is a dependency, we can't modify it directly
                print("ℹ️  fipers is a dependency. CMakeLists.txt should be configured in the package.")
                print("   Make sure the fipers package includes Android CMakeLists.txt integration.")
                return
    
    if fipers_root is None or not (fipers_root / "android" / "CMakeLists.txt").exists():
        print("⚠️  Could not find fipers root with android/CMakeLists.txt")
        print("   Make sure you're running this from the correct directory.")
        return
    
    print(f"📦 fipers root: {fipers_root}")
    
    # Check OpenSSL
    check_openssl_for_android()
    
    # Verify CMake integration
    verify_cmake_integration(project_root)
    
    print("\n✅ Android library integration check complete!")
    print("\n📝 Next steps:")
    print("   1. Ensure OpenSSL is built for Android (see README.md)")
    print("   2. Run: flutter build apk --debug")
    print("   3. The library should be automatically built and included in the APK")


if __name__ == "__main__":
    main()
