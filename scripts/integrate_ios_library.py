#!/usr/bin/env python3
"""
Script to automatically integrate libfipers.a into Flutter iOS project
This script modifies the Xcode project to include the static library
"""

import os
import sys
import re
import hashlib
import shutil
from pathlib import Path

def generate_id(text):
    """Generate a unique 24-character hex ID for Xcode project entries"""
    return hashlib.sha1(text.encode()).hexdigest()[:24].upper()

def integrate_library(project_root, library_path):
    """Integrate the static library into the Flutter iOS project"""
    
    # Paths - project_root should be the Flutter project root (e.g., example/)
    ios_dir = Path(project_root) / "ios"
    library_name = "libfipers.a"
    frameworks_dir = ios_dir / "Frameworks"
    xcode_project = ios_dir / "Runner.xcodeproj" / "project.pbxproj"
    
    # Check paths
    if not ios_dir.exists():
        print("Error: iOS directory not found")
        return False
    
    if not xcode_project.exists():
        print(f"Error: Xcode project not found at {xcode_project}")
        return False
    
    if not Path(library_path).exists():
        print(f"Error: Library not found at {library_path}")
        return False
    
    # Copy library to iOS project
    frameworks_dir.mkdir(exist_ok=True)
    dest_library = frameworks_dir / library_name
    shutil.copy2(library_path, dest_library)
    print(f"✅ Copied library to {dest_library}")
    
    # Read Xcode project file
    with open(xcode_project, 'r') as f:
        content = f.read()
    
    # Create backup
    backup_path = str(xcode_project) + ".backup"
    shutil.copy2(xcode_project, backup_path)
    print(f"✅ Created backup: {backup_path}")
    
    # Check if already integrated
    if library_name in content:
        print("⚠️  Library already integrated, updating link flags to use -force_load...")
        # Update link flags to use -force_load instead of -lfipers
        # This ensures all symbols are included from the static library
        content = re.sub(
            r'OTHER_LDFLAGS = \([^)]*-lfipers[^)]*\)',
            r'OTHER_LDFLAGS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"-force_load",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks/libfipers.a",\n\t\t\t\t)',
            content,
            flags=re.DOTALL
        )
        # Also check if OTHER_LDFLAGS exists but doesn't have -force_load
        if '-force_load' not in content or 'libfipers.a' not in content:
            # Add force_load to all OTHER_LDFLAGS that don't have it
            def update_ldflags(match):
                ldflags = match.group(0)
                if '-force_load' not in ldflags and 'libfipers.a' not in ldflags:
                    # Insert before closing )
                    return ldflags[:-1] + '\n\t\t\t\t\t"-force_load",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks/libfipers.a",\n\t\t\t\t)'
                return ldflags
            content = re.sub(r'OTHER_LDFLAGS = \([^)]*\)', update_ldflags, content, flags=re.DOTALL)
        
        # Write back updated content
        with open(xcode_project, 'w') as f:
            f.write(content)
        
        print("✅ Updated link flags to use -force_load")
        return True
    
    # Generate IDs
    file_ref_id = generate_id(f"{library_name}_file_ref")
    build_file_id = generate_id(f"{library_name}_build_file")
    
    # Add PBXFileReference
    file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
    file_ref_entry = f'\t\t{file_ref_id} /* {library_name} */ = {{isa = PBXFileReference; lastKnownFileType = archive.ar; path = {library_name}; sourceTree = "<group>"; }};\n\t\t\\1'
    content = re.sub(file_ref_pattern, file_ref_entry, content)
    
    # Add to Frameworks group
    frameworks_group_pattern = r'(71A9A1607E036E391BA6A301 /\* Frameworks \*\/ = \{[^}]*children = \([^)]*)'
    frameworks_entry = f'\\1\n\t\t\t\t{file_ref_id} /* {library_name} */,\n'
    content = re.sub(frameworks_group_pattern, frameworks_entry, content)
    
    # Add PBXBuildFile
    build_file_pattern = r'(/\* End PBXBuildFile section \*/)'
    build_file_entry = f'\t\t{build_file_id} /* {library_name} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {library_name} */; }};\n\t\t\\1'
    content = re.sub(build_file_pattern, build_file_entry, content)
    
    # Add to Frameworks build phase
    frameworks_phase_pattern = r'(97C146EB1CF9000F007C117D /\* Frameworks \*\/ = \{[^}]*files = \([^)]*)'
    frameworks_phase_entry = f'\\1\n\t\t\t\t{build_file_id} /* {library_name} in Frameworks */,\n'
    content = re.sub(frameworks_phase_pattern, frameworks_phase_entry, content)
    
    # Add library search paths and link flags to build settings
    # This is more complex - we need to find each build configuration
    
    # Pattern for build settings block
    build_settings_pattern = r'(buildSettings = \{)([^}]*)(\};)'
    
    def add_library_settings(match):
        settings_block = match.group(2)
        # Check if already has our settings
        if 'Frameworks' in settings_block and 'libfipers' in settings_block:
            return match.group(0)
        
        # Add library search paths and link flags
        # For static libraries, we need to link the full path or use -l flag with library search path
        new_settings = settings_block
        if 'LIBRARY_SEARCH_PATHS' not in new_settings:
            new_settings += '\n\t\t\t\tLIBRARY_SEARCH_PATHS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks",\n\t\t\t\t);'
        if 'OTHER_LDFLAGS' not in new_settings:
            # Use -force_load to ensure all symbols from static library are included
            # This is important for static libraries that might not be fully linked otherwise
            new_settings += '\n\t\t\t\tOTHER_LDFLAGS = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"-force_load",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks/libfipers.a",\n\t\t\t\t);'
        elif '-force_load' not in new_settings and 'libfipers' not in new_settings:
            # Add force_load if OTHER_LDFLAGS exists but doesn't have our library
            # Insert before the closing );
            new_settings = re.sub(
                r'(OTHER_LDFLAGS = \([^)]*)',
                r'\1\n\t\t\t\t\t"-force_load",\n\t\t\t\t\t"$(PROJECT_DIR)/Frameworks/libfipers.a",',
                new_settings,
                flags=re.DOTALL
            )
        
        return match.group(1) + new_settings + match.group(3)
    
    # Apply to all build configurations (Debug, Release, Profile)
    content = re.sub(build_settings_pattern, add_library_settings, content, flags=re.DOTALL)
    
    # Write back
    with open(xcode_project, 'w') as f:
        f.write(content)
    
    print(f"✅ Successfully integrated {library_name} into Xcode project!")
    print(f"\nThe library has been:")
    print(f"  1. Copied to {dest_library}")
    print(f"  2. Added to Xcode project file references")
    print(f"  3. Added to Frameworks group")
    print(f"  4. Added to Link Binary With Libraries build phase")
    print(f"  5. Added library search paths and link flags to build settings")
    print(f"\nYou can now build your Flutter iOS app with:")
    print(f"  flutter build ios")
    
    return True

def main():
    script_dir = Path(__file__).parent
    fipers_root = script_dir.parent
    
    # Check current directory - if we're in example, use it; otherwise check fipers_root
    current_dir = Path.cwd()
    project_root = None
    
    # Check if current directory is a Flutter project
    if (current_dir / "pubspec.yaml").exists() and (current_dir / "ios").exists():
        project_root = current_dir
    # Check if example directory exists and is a Flutter project
    elif (fipers_root / "example" / "pubspec.yaml").exists():
        project_root = fipers_root / "example"
    else:
        print("Error: This script must be run from a Flutter project root")
        print("Usage: Run from Flutter project root (e.g., fipers/example)")
        sys.exit(1)
    
    print(f"Using Flutter project: {project_root}")
    
    # Determine fipers root (parent of scripts directory)
    fipers_root = script_dir.parent
    
    # Build the iOS library first
    print("Building iOS library...")
    build_script = script_dir / "build.sh"
    if build_script.exists():
        import subprocess
        result = subprocess.run(
            [str(build_script), "ios", "Release"],
            cwd=fipers_root,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"Error building library: {result.stderr}")
            sys.exit(1)
    else:
        print("Warning: build.sh not found, assuming library is already built")
    
    # Library path (always from fipers root)
    library_path = fipers_root / "ios" / "build" / "libfipers.a"
    
    if not library_path.exists():
        print(f"Error: Library not found at {library_path}")
        print("Please build the library first: ./scripts/build.sh ios Release")
        sys.exit(1)
    
    # Integrate library
    success = integrate_library(project_root, library_path)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
