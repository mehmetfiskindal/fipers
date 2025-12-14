#!/bin/bash
# Script to setup iOS static library linking for Flutter projects
# This script adds the libfipers.a static library to the Xcode project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build the iOS library first
echo "Building iOS library..."
cd "$PROJECT_ROOT"
./scripts/build.sh ios Release

# Library path
LIBRARY_PATH="$PROJECT_ROOT/ios/build/libfipers.a"

if [ ! -f "$LIBRARY_PATH" ]; then
  echo "Error: Library not found at $LIBRARY_PATH"
  exit 1
fi

echo "iOS library built successfully at: $LIBRARY_PATH"
echo ""
echo "To use this library in your Flutter iOS app, you need to:"
echo "1. Add the library to your Xcode project"
echo "2. Link it in the 'Link Binary With Libraries' build phase"
echo "3. Add the library path to 'Library Search Paths' in build settings"
echo ""
echo "Or use this library path in your Xcode project:"
echo "$LIBRARY_PATH"
