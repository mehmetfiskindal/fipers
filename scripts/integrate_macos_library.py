#!/usr/bin/env python3
"""
Script to automatically integrate libfipers.dylib into Flutter macOS project
This script copies the library to the Frameworks directory and ensures it's included in the app bundle
"""

import os
import sys
import shutil
from pathlib import Path

def integrate_library(project_root, library_path):
    """Integrate the dynamic library into the Flutter macOS project"""
    
    # Paths - project_root should be the Flutter project root (e.g., example/)
    macos_dir = Path(project_root) / "macos"
    library_name = "libfipers.dylib"
    frameworks_dir = macos_dir / "Frameworks"
    
    # Check paths
    if not macos_dir.exists():
        print("Error: macOS directory not found")
        return False
    
    if not Path(library_path).exists():
        print(f"Error: Library not found at {library_path}")
        return False
    
    # Copy library to macOS Frameworks directory
    frameworks_dir.mkdir(exist_ok=True)
    dest_library = frameworks_dir / library_name
    
    # Remove existing library if it exists
    if dest_library.exists():
        dest_library.unlink()
    
    shutil.copy2(library_path, dest_library)
    print(f"✅ Copied library to {dest_library}")
    
    # Copy OpenSSL libraries to Frameworks directory
    import subprocess
    openssl_libs = [
        ("/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib", "libssl.3.dylib"),
        ("/opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib", "libcrypto.3.dylib"),
    ]
    
    # Try alternative paths
    if not Path(openssl_libs[0][0]).exists():
        openssl_libs = [
            ("/usr/local/opt/openssl@3/lib/libssl.3.dylib", "libssl.3.dylib"),
            ("/usr/local/opt/openssl@3/lib/libcrypto.3.dylib", "libcrypto.3.dylib"),
        ]
    
    copied_openssl = []
    for src_path, dest_name in openssl_libs:
        src = Path(src_path)
        if src.exists():
            dest = frameworks_dir / dest_name
            if dest.exists():
                dest.unlink()
            shutil.copy2(src, dest)
            copied_openssl.append(dest)
            print(f"✅ Copied {dest_name} to {dest}")
        else:
            print(f"⚠️  OpenSSL library not found at {src_path}")
    
    # Check if library needs rpath fixing
    # We'll use install_name_tool but then re-sign the library
    try:
        result = subprocess.run(
            ["otool", "-L", str(dest_library)],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            needs_fix = False
            for line in result.stdout.split('\n'):
                if ('/opt/homebrew' in line or '/usr/local' in line) and ('libssl' in line or 'libcrypto' in line):
                    needs_fix = True
                    old_path = line.split()[0]
                    if 'libssl' in line:
                        subprocess.run(
                            ["install_name_tool", "-change",
                             old_path, "@rpath/libssl.3.dylib",
                             str(dest_library)],
                            check=False
                        )
                    elif 'libcrypto' in line:
                        subprocess.run(
                            ["install_name_tool", "-change",
                             old_path, "@rpath/libcrypto.3.dylib",
                             str(dest_library)],
                            check=False
                        )
            
            if needs_fix:
                # Re-sign the library after modifying rpath
                subprocess.run(
                    ["codesign", "--sign", "-", "--force", str(dest_library)],
                    check=False
                )
                print(f"✅ Fixed library rpath and re-signed")
            else:
                print(f"✅ Library rpath is correct")
    except Exception as e:
        print(f"⚠️  Could not fix library rpath: {e}")
    
    # Fix rpath in OpenSSL libraries themselves and re-sign
    for openssl_lib in copied_openssl:
        try:
            result = subprocess.run(
                ["otool", "-L", str(openssl_lib)],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                modified = False
                for line in result.stdout.split('\n'):
                    if not line.strip() or line.strip().startswith(openssl_lib.name):
                        continue
                    # Fix libcrypto reference in libssl
                    if 'libssl' in openssl_lib.name and ('/opt/homebrew' in line or '/usr/local' in line) and 'libcrypto' in line:
                        old_path = line.split()[0]
                        if old_path != '@rpath/libcrypto.3.dylib':
                            subprocess.run(
                                ["install_name_tool", "-change",
                                 old_path, "@rpath/libcrypto.3.dylib",
                                 str(openssl_lib)],
                                check=False
                            )
                            modified = True
                    # Fix self-reference in OpenSSL libraries
                    elif ('/opt/homebrew' in line or '/usr/local' in line) and openssl_lib.name.split('.')[0] in line:
                        old_path = line.split()[0]
                        new_name = openssl_lib.name
                        if old_path != f'@rpath/{new_name}':
                            subprocess.run(
                                ["install_name_tool", "-id",
                                 f"@rpath/{new_name}",
                                 str(openssl_lib)],
                                check=False
                            )
                            modified = True
                
                # Re-sign if modified
                if modified:
                    subprocess.run(
                        ["codesign", "--sign", "-", "--force", str(openssl_lib)],
                        check=False
                    )
        except Exception as e:
            print(f"⚠️  Could not fix rpath in {openssl_lib.name}: {e}")
    
    # Add to Xcode project
    xcode_project = macos_dir / "Runner.xcodeproj" / "project.pbxproj"
    if xcode_project.exists():
        import re
        import hashlib
        
        # Read Xcode project
        with open(xcode_project, 'r') as f:
            content = f.read()
        
        # Create backup
        backup_path = str(xcode_project) + ".backup"
        shutil.copy2(xcode_project, backup_path)
        print(f"✅ Created backup: {backup_path}")
        
        # Add OpenSSL libraries to Xcode project as well
        openssl_lib_names = ["libssl.3.dylib", "libcrypto.3.dylib"]
        for openssl_lib_name in openssl_lib_names:
            if openssl_lib_name not in content:
                openssl_file_ref_id = hashlib.sha1(f"{openssl_lib_name}_file_ref".encode()).hexdigest()[:24].upper()
                openssl_build_file_id = hashlib.sha1(f"{openssl_lib_name}_build_file".encode()).hexdigest()[:24].upper()
                
                # Add PBXFileReference
                file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
                file_ref_entry = f'\t\t{openssl_file_ref_id} /* {openssl_lib_name} */ = {{isa = PBXFileReference; lastKnownFileType = "compiled.mach-o.dylib"; path = ../Frameworks/{openssl_lib_name}; sourceTree = "<group>"; }};\n\t\t\\1'
                content = re.sub(file_ref_pattern, file_ref_entry, content)
                
                # Add to Frameworks group
                frameworks_group_pattern = r'(Frameworks.*= \{[^}]*children = \([^)]*)'
                if 'Frameworks' in content:
                    frameworks_entry = f'\\1\n\t\t\t\t{openssl_file_ref_id} /* {openssl_lib_name} */,\n'
                    content = re.sub(frameworks_group_pattern, frameworks_entry, content, flags=re.DOTALL)
                
                # Add PBXBuildFile
                build_file_pattern = r'(/\* End PBXBuildFile section \*/)'
                build_file_entry = f'\t\t{openssl_build_file_id} /* {openssl_lib_name} in Bundle Framework */ = {{isa = PBXBuildFile; fileRef = {openssl_file_ref_id} /* {openssl_lib_name} */; }};\n\t\t\\1'
                content = re.sub(build_file_pattern, build_file_entry, content)
                
                # Add to Bundle Framework build phase
                bundle_framework_pattern = r'(33CC110E2044A8840003C045 /\* Bundle Framework \*\/ = \{[^}]*files = \([^)]*)'
                bundle_framework_entry = f'\\1\n\t\t\t\t{openssl_build_file_id} /* {openssl_lib_name} in Bundle Framework */,\n'
                content = re.sub(bundle_framework_pattern, bundle_framework_entry, content)
        
        # Check if already integrated
        if library_name in content:
            print("⚠️  Library already in Xcode project, updating OpenSSL libraries...")
            # Write back updated content with OpenSSL libraries
            with open(xcode_project, 'w') as f:
                f.write(content)
            print("✅ Added OpenSSL libraries to Xcode project")
            
            # Add script to fix rpath after build
            # Find the ShellScript build phase and add rpath fix script
            shell_script_pattern = r'(3399D490228B24CF009A79C7 /\* ShellScript \*\/ = \{[^}]*shellScript = ")([^"]*)(";)'
            rpath_fix_script = '''\\n# Fix OpenSSL rpath in app bundle after copy
if [ -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libssl.3.dylib" ]; then
  install_name_tool -id "@rpath/libssl.3.dylib" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libssl.3.dylib" 2>/dev/null || true
  install_name_tool -change "/opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib" "@rpath/libcrypto.3.dylib" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libssl.3.dylib" 2>/dev/null || true
  install_name_tool -change "/opt/homebrew/Cellar/openssl@3" "@rpath/libcrypto.3.dylib" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libssl.3.dylib" 2>/dev/null || true
  install_name_tool -change "/usr/local/opt/openssl@3/lib/libcrypto.3.dylib" "@rpath/libcrypto.3.dylib" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libssl.3.dylib" 2>/dev/null || true
fi
if [ -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libcrypto.3.dylib" ]; then
  install_name_tool -id "@rpath/libcrypto.3.dylib" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Frameworks/libcrypto.3.dylib" 2>/dev/null || true
fi'''
            if 'Fix OpenSSL rpath' not in content:
                # Append to existing shell script
                def add_rpath_fix(match):
                    existing_script = match.group(2)
                    if 'Fix OpenSSL rpath' not in existing_script:
                        return f'{match.group(1)}{existing_script}{rpath_fix_script}{match.group(3)}'
                    return match.group(0)
                
                content = re.sub(
                    shell_script_pattern,
                    add_rpath_fix,
                    content,
                    flags=re.DOTALL
                )
                with open(xcode_project, 'w') as f:
                    f.write(content)
                print("✅ Added rpath fix script to build phase")
        else:
            # Generate IDs
            file_ref_id = hashlib.sha1(f"{library_name}_file_ref".encode()).hexdigest()[:24].upper()
            build_file_id = hashlib.sha1(f"{library_name}_build_file".encode()).hexdigest()[:24].upper()
            
            # Add PBXFileReference with correct path (relative to Runner directory)
            file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
            file_ref_entry = f'\t\t{file_ref_id} /* {library_name} */ = {{isa = PBXFileReference; lastKnownFileType = "compiled.mach-o.dylib"; path = ../Frameworks/{library_name}; sourceTree = "<group>"; }};\n\t\t\\1'
            content = re.sub(file_ref_pattern, file_ref_entry, content)
            
            # Add to Frameworks group (if exists) or create it
            frameworks_group_pattern = r'(Frameworks.*= \{[^}]*children = \([^)]*)'
            if 'Frameworks' in content:
                frameworks_entry = f'\\1\n\t\t\t\t{file_ref_id} /* {library_name} */,\n'
                content = re.sub(frameworks_group_pattern, frameworks_entry, content, flags=re.DOTALL)
            
            # Add PBXBuildFile
            build_file_pattern = r'(/\* End PBXBuildFile section \*/)'
            build_file_entry = f'\t\t{build_file_id} /* {library_name} in Bundle Framework */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {library_name} */; }};\n\t\t\\1'
            content = re.sub(build_file_pattern, build_file_entry, content)
            
            # Add to Bundle Framework build phase
            bundle_framework_pattern = r'(33CC110E2044A8840003C045 /\* Bundle Framework \*\/ = \{[^}]*files = \([^)]*)'
            bundle_framework_entry = f'\\1\n\t\t\t\t{build_file_id} /* {library_name} in Bundle Framework */,\n'
            content = re.sub(bundle_framework_pattern, bundle_framework_entry, content)
            
            # Write back
            with open(xcode_project, 'w') as f:
                f.write(content)
            
            print(f"✅ Added {library_name} to Xcode project")
        
    
    print(f"\n✅ Successfully integrated {library_name} into macOS project!")
    print(f"\nThe library has been:")
    print(f"  1. Copied to {dest_library}")
    print(f"  2. Fixed rpath for OpenSSL dependencies")
    print(f"  3. Added to Xcode project Bundle Framework build phase")
    print(f"\nYou can now build your Flutter macOS app with:")
    print(f"  flutter build macos")
    
    return True

def main():
    script_dir = Path(__file__).parent
    fipers_root = script_dir.parent
    
    # Check current directory - if we're in example, use it; otherwise check fipers_root
    current_dir = Path.cwd()
    project_root = None
    
    # Check if current directory is a Flutter project
    if (current_dir / "pubspec.yaml").exists() and (current_dir / "macos").exists():
        project_root = current_dir
    # Check if example directory exists and is a Flutter project
    elif (fipers_root / "example" / "pubspec.yaml").exists():
        project_root = fipers_root / "example"
    else:
        print("Error: This script must be run from a Flutter project root")
        print("Usage: Run from Flutter project root (e.g., fipers/example)")
        sys.exit(1)
    
    print(f"Using Flutter project: {project_root}")
    
    # Build the macOS library first
    print("Building macOS library...")
    build_script = script_dir / "build.sh"
    if build_script.exists():
        import subprocess
        result = subprocess.run(
            [str(build_script), "macos", "Release"],
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
    library_path = fipers_root / "macos" / "build" / "libfipers.dylib"
    
    if not library_path.exists():
        print(f"Error: Library not found at {library_path}")
        print("Please build the library first: ./scripts/build.sh macos Release")
        sys.exit(1)
    
    # Integrate library
    success = integrate_library(project_root, library_path)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
