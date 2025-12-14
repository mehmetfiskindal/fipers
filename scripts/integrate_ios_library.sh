#!/bin/bash
# Script to automatically integrate libfipers.a into Flutter iOS project
# This script modifies the Xcode project to include the static library

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
  echo "Error: This script must be run from a Flutter project root"
  exit 1
fi

# Check if iOS directory exists
if [ ! -d "ios" ]; then
  echo "Error: iOS directory not found. This script must be run from a Flutter project with iOS support"
  exit 1
fi

# Build the iOS library first
echo "Building iOS library..."
cd "$PROJECT_ROOT"
./scripts/build.sh ios Release

# Library path
LIBRARY_PATH="$PROJECT_ROOT/ios/build/libfipers.a"
LIBRARY_NAME="libfipers.a"

if [ ! -f "$LIBRARY_PATH" ]; then
  echo "Error: Library not found at $LIBRARY_PATH"
  exit 1
fi

# Copy library to iOS project
IOS_LIB_DIR="ios/Frameworks"
mkdir -p "$IOS_LIB_DIR"
cp "$LIBRARY_PATH" "$IOS_LIB_DIR/$LIBRARY_NAME"
echo "Copied library to $IOS_LIB_DIR/$LIBRARY_NAME"

# Get absolute path to library in iOS project
IOS_LIB_ABSPATH="$(cd "$IOS_LIB_DIR" && pwd)/$LIBRARY_NAME"

# Xcode project file
XCODE_PROJECT="ios/Runner.xcodeproj/project.pbxproj"

if [ ! -f "$XCODE_PROJECT" ]; then
  echo "Error: Xcode project not found at $XCODE_PROJECT"
  exit 1
fi

# Generate unique IDs for Xcode project entries
# Using a simple hash based on library name
LIBRARY_FILE_REF_ID=$(echo -n "$LIBRARY_NAME" | shasum | cut -c1-24 | tr '[:lower:]' '[:upper:]')
LIBRARY_BUILD_FILE_ID=$(echo -n "${LIBRARY_NAME}_BUILD" | shasum | cut -c1-24 | tr '[:lower:]' '[:upper:]')

# Check if library is already in the project
if grep -q "$LIBRARY_NAME" "$XCODE_PROJECT"; then
  echo "Library already integrated into Xcode project"
  exit 0
fi

# Create backup
cp "$XCODE_PROJECT" "${XCODE_PROJECT}.backup"
echo "Created backup: ${XCODE_PROJECT}.backup"

# Add library file reference (in PBXFileReference section)
# Find the last PBXFileReference entry and add after it
sed -i '' "/End PBXFileReference section/i\\
		${LIBRARY_FILE_REF_ID} /* ${LIBRARY_NAME} */ = {isa = PBXFileReference; lastKnownFileType = archive.ar; path = ${LIBRARY_NAME}; sourceTree = \"<group>\"; };\\
" "$XCODE_PROJECT"

# Add library to Frameworks group
# Find the Frameworks group and add library to it
sed -i '' "/71A9A1607E036E391BA6A301 \/\* Frameworks \*\/ = {/,/};/{
  /children = (/,/);/{
    /);/i\\
				${LIBRARY_FILE_REF_ID} /* ${LIBRARY_NAME} */,
  }
}" "$XCODE_PROJECT"

# Add library to PBXBuildFile section
sed -i '' "/End PBXBuildFile section/i\\
		${LIBRARY_BUILD_FILE_ID} /* ${LIBRARY_NAME} in Frameworks */ = {isa = PBXBuildFile; fileRef = ${LIBRARY_FILE_REF_ID} /* ${LIBRARY_NAME} */; };\\
" "$XCODE_PROJECT"

# Add library to Frameworks build phase
sed -i '' "/97C146EB1CF9000F007C117D \/\* Frameworks \*\/ = {/,/};/{
  /files = (/,/);/{
    /);/i\\
				${LIBRARY_BUILD_FILE_ID} /* ${LIBRARY_NAME} in Frameworks */,
  }
}" "$XCODE_PROJECT"

# Add library search path to build settings
# This is done by modifying the build configuration sections
# We'll add it to OTHER_LDFLAGS and LIBRARY_SEARCH_PATHS

# For Debug configuration
sed -i '' "/97C147031CF9000F007C117D \/\* Debug \*\/ = {/,/};/{
  /buildSettings = {/,/};/{
    /};/i\\
				LIBRARY_SEARCH_PATHS = (
					\"\$(inherited)\",
					\"\$(PROJECT_DIR)/Frameworks\",
				);
				OTHER_LDFLAGS = (
					\"\$(inherited)\",
					\"-l${LIBRARY_NAME%.a}\",
				);
  }
}" "$XCODE_PROJECT"

# For Release configuration  
sed -i '' "/249021D3217E4FDB00AE95B9 \/\* Profile \*\/ = {/,/};/{
  /buildSettings = {/,/};/{
    /};/i\\
				LIBRARY_SEARCH_PATHS = (
					\"\$(inherited)\",
					\"\$(PROJECT_DIR)/Frameworks\",
				);
				OTHER_LDFLAGS = (
					\"\$(inherited)\",
					\"-l${LIBRARY_NAME%.a}\",
				);
  }
}" "$XCODE_PROJECT"

# Find Release configuration (may have different ID)
# We'll search for Release configuration pattern
sed -i '' "/Release.*= {/,/};/{
  /buildSettings = {/,/};/{
    /};/i\\
				LIBRARY_SEARCH_PATHS = (
					\"\$(inherited)\",
					\"\$(PROJECT_DIR)/Frameworks\",
				);
				OTHER_LDFLAGS = (
					\"\$(inherited)\",
					\"-l${LIBRARY_NAME%.a}\",
				);
  }
}" "$XCODE_PROJECT"

echo ""
echo "✅ Successfully integrated $LIBRARY_NAME into Xcode project!"
echo ""
echo "The library has been:"
echo "  1. Copied to ios/Frameworks/$LIBRARY_NAME"
echo "  2. Added to Xcode project file references"
echo "  3. Added to Frameworks group"
echo "  4. Added to Link Binary With Libraries build phase"
echo "  5. Added library search paths and link flags to build settings"
echo ""
echo "You can now build your Flutter iOS app with:"
echo "  flutter build ios"
echo ""
echo "Note: If you encounter issues, restore from backup:"
echo "  cp ${XCODE_PROJECT}.backup $XCODE_PROJECT"
