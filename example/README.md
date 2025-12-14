# Fipers Example

This example application demonstrates how to use the Fipers encrypted persistent storage library in a Flutter application.

## Features Demonstrated

- ✅ **Storage Initialization**: Initialize Fipers with a storage path and passphrase
- ✅ **Store Encrypted Data**: Store data with encryption using the `put()` method
- ✅ **Retrieve Decrypted Data**: Retrieve and decrypt data using the `get()` method
- ✅ **Delete Data**: Delete stored data using the `delete()` method
- ✅ **Passphrase Management**: Reinitialize storage with a new passphrase
- ✅ **Error Handling**: Comprehensive error handling and user feedback
- ✅ **Platform Support**: Works on Android, iOS, macOS, Linux, Windows, and Web

## Usage

### Running the Example

1. Make sure you have Flutter installed and configured
2. Navigate to the example directory:
   ```bash
   cd example
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Basic Usage Example

```dart
import 'package:fipers/fipers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:convert';

// Initialize Fipers
final fipers = createFipers();
final directory = await getApplicationDocumentsDirectory();
await fipers.init(directory.path, 'my-secret-passphrase');

// Store encrypted data
final data = Uint8List.fromList(utf8.encode('Hello, Fipers!'));
await fipers.put('my-key', data);

// Retrieve and decrypt data
final retrieved = await fipers.get('my-key');
if (retrieved != null) {
  final value = utf8.decode(retrieved);
  print('Retrieved: $value');
}

// Delete data
await fipers.delete('my-key');

// Close storage
await fipers.close();
```

## Application Features

### Status Display
- Shows the current initialization status
- Displays the storage path being used
- Provides real-time feedback on operations

### Passphrase Configuration
- Set a custom passphrase for encryption
- Reinitialize storage with a new passphrase
- Passphrase is used for PBKDF2 key derivation (100,000 iterations)

### Data Operations
- **Store**: Encrypt and store data with a key
- **Retrieve**: Decrypt and retrieve data by key
- **Delete**: Remove stored data by key

### Key Management
- View all stored keys in a chip list
- Quick delete by tapping the delete icon on a key chip
- Automatic key list management

## Platform-Specific Notes

### Native Platforms (Android, iOS, macOS, Linux, Windows)
- Uses FFI to call native C functions (OpenSSL) for encryption
- File-based storage in application documents/support directory
- Maximum performance with native code execution

### Web Platform
- Uses WebCrypto API for encryption
- IndexedDB for persistent storage
- Optional WASM support for enhanced performance

## Security Features

- **AES-256-GCM Encryption**: Industry-standard encryption algorithm
- **PBKDF2 Key Derivation**: Secure passphrase-based key derivation with 100,000 iterations
- **Secure Storage**: Data is encrypted at rest
- **Platform-Aware**: Uses platform-specific secure storage mechanisms

## Error Handling

The example application includes comprehensive error handling:
- Initialization errors
- Storage operation errors
- Key not found scenarios
- Invalid input validation
- User-friendly error messages via SnackBar

## Dependencies

- `fipers`: The main Fipers library (path dependency to parent directory)
- `path_provider`: For getting platform-specific storage directories
- `flutter`: Flutter SDK

## Building

### For Native Platforms

The native libraries need to be built before running on native platforms. See the main README.md for build instructions.

### For Web

Web platform works out of the box with WebCrypto API. No additional build steps required.

## Troubleshooting

### Storage Not Initialized
- Make sure the storage path is accessible
- Check that the passphrase is not empty
- Verify platform-specific permissions

### Data Not Found
- Ensure the key exists before trying to retrieve
- Check that the storage was initialized with the same passphrase

### Build Errors
- Make sure native libraries are built (for native platforms)
- Run `flutter clean` and `flutter pub get` if dependencies are missing
