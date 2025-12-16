import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:fipers/fipers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// path_provider is only used on native platforms
// On web, we use a simple string path identifier instead
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory, getApplicationSupportDirectory;
import 'dart:io' if (dart.library.html) 'dart:html' as io;

void main() {
  runApp(const FipersExampleApp());
}

class FipersExampleApp extends StatelessWidget {
  const FipersExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fipers Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FipersExamplePage(),
    );
  }
}

class FipersExamplePage extends StatefulWidget {
  const FipersExamplePage({super.key});

  @override
  State<FipersExamplePage> createState() => _FipersExamplePageState();
}

class _FipersExamplePageState extends State<FipersExamplePage> {
  Fipers? _fipers;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasInitialized = false; // Flag to prevent multiple initializations
  String _statusMessage = 'Not initialized';
  String _storagePath = '';
  String _passphrase = 'my-secret-passphrase';

  // Form controllers
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();

  // Stored keys list
  final List<String> _storedKeys = [];

  @override
  void initState() {
    super.initState();
    _passphraseController.text = _passphrase;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized && !_isLoading) {
      _hasInitialized = true;
      _initializeStorage();
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _passphraseController.dispose();
    _fipers?.close();
    super.dispose();
  }

  Future<void> _initializeStorage() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing storage...';
    });

    try {
      // Get platform-specific storage directory
      // On web, we don't need path_provider - Fipers uses path as identifier only
      if (kIsWeb) {
        // Web platform - path is just an identifier for IndexedDB, not a file path
        _storagePath = '/fipers_storage';
      } else {
        final directory = await _getStorageDirectory();
        _storagePath = directory.path;
      }

      // Create Fipers instance
      _fipers = createFipers();

      // Initialize with path and passphrase
      await _fipers!.init(_storagePath, _passphrase);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _statusMessage = 'Storage initialized successfully';
      });

      // Log successful initialization
      developer.log(
        'Storage initialized successfully at: $_storagePath',
        name: 'FipersExample',
      );

      // Load existing keys
      await _loadStoredKeys();
    } catch (e, stackTrace) {
      // Log error with stack trace
      developer.log(
        'Failed to initialize storage',
        name: 'FipersExample',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isInitialized = false;
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to initialize storage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<io.Directory> _getStorageDirectory() async {
    // Use Flutter's platform detection instead of dart:io Platform
    // Note: This function is only called on native platforms (not web)
    // Web platform uses a simple string path identifier instead
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      // For mobile platforms, use application documents directory
      return await getApplicationDocumentsDirectory();
    } else {
      // For desktop platforms, use application support directory
      return await getApplicationSupportDirectory();
    }
  }

  Future<void> _loadStoredKeys() async {
    // Note: Fipers doesn't have a listKeys method, so we'll maintain
    // our own list of keys. In a real app, you might want to store
    // a metadata file with all keys.
    setState(_storedKeys.clear);
  }

  Future<void> _putData() async {
    if (!_isInitialized || _fipers == null) {
      _showError('Storage not initialized');
      return;
    }

    final key = _keyController.text.trim();
    final value = _valueController.text.trim();

    if (key.isEmpty) {
      _showError('Key cannot be empty');
      return;
    }

    if (value.isEmpty) {
      _showError('Value cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Storing data...';
    });

    try {
      // Convert string to Uint8List
      final data = Uint8List.fromList(utf8.encode(value));

      // Store encrypted data
      await _fipers!.put(key, data);

      // Add to stored keys list if not already present
      if (!_storedKeys.contains(key)) {
        setState(() {
          _storedKeys.add(key);
        });
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Data stored successfully';
      });

      // Log successful storage
      developer.log(
        'Data stored successfully for key: $key',
        name: 'FipersExample',
      );

      // Clear input fields
      _valueController.clear();

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Data stored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Log error with stack trace
      developer.log(
        'Failed to store data',
        name: 'FipersExample',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      _showError('Failed to store data: $e');
    }
  }

  Future<void> _getData() async {
    if (!_isInitialized || _fipers == null) {
      _showError('Storage not initialized');
      return;
    }

    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _showError('Key cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Retrieving data...';
    });

    try {
      // Retrieve and decrypt data
      final data = await _fipers!.get(key);

      if (data == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Key not found';
        });

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Key not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Convert Uint8List to string
      final value = utf8.decode(data);

      setState(() {
        _isLoading = false;
        _statusMessage = 'Data retrieved successfully';
        _valueController.text = value;
      });

      // Log successful retrieval
      developer.log(
        'Data retrieved successfully for key: $key',
        name: 'FipersExample',
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Data retrieved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Log error with stack trace
      developer.log(
        'Failed to retrieve data',
        name: 'FipersExample',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      _showError('Failed to retrieve data: $e');
    }
  }

  Future<void> _deleteData() async {
    if (!_isInitialized || _fipers == null) {
      _showError('Storage not initialized');
      return;
    }

    final key = _keyController.text.trim();

    if (key.isEmpty) {
      _showError('Key cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting data...';
    });

    try {
      // Delete data
      await _fipers!.delete(key);

      // Remove from stored keys list
      setState(() {
        _storedKeys.remove(key);
        _isLoading = false;
        _statusMessage = 'Data deleted successfully';
      });

      // Log successful deletion
      developer.log(
        'Data deleted successfully for key: $key',
        name: 'FipersExample',
      );

      // Clear input fields
      _keyController.clear();
      _valueController.clear();

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Data deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Log error with stack trace
      developer.log(
        'Failed to delete data',
        name: 'FipersExample',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      _showError('Failed to delete data: $e');
    }
  }

  Future<void> _reinitializeWithNewPassphrase() async {
    final newPassphrase = _passphraseController.text.trim();

    if (newPassphrase.isEmpty) {
      _showError('Passphrase cannot be empty');
      return;
    }

    // Close existing instance
    await _fipers?.close();

    setState(() {
      _passphrase = newPassphrase;
      _isInitialized = false;
      _storedKeys.clear();
      _keyController.clear();
      _valueController.clear();
    });

    // Reinitialize with new passphrase
    await _initializeStorage();
  }

  void _showError(String message) {
    // Log error message
    developer.log(
      message,
      name: 'FipersExample',
      level: 1000, // Error level
    );

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fipers Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_storagePath.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Storage Path: $_storagePath',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Passphrase Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passphrase Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passphraseController,
                      decoration: const InputDecoration(
                        labelText: 'Passphrase',
                        hintText: 'Enter passphrase for encryption',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : _reinitializeWithNewPassphrase,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Reinitialize with New Passphrase'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data Operations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Operations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        hintText: 'Enter key name',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading && _isInitialized,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        hintText: 'Enter value to store',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: !_isLoading && _isInitialized,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || !_isInitialized
                                ? null
                                : _putData,
                            icon: const Icon(Icons.save),
                            label: const Text('Store'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || !_isInitialized
                                ? null
                                : _getData,
                            icon: const Icon(Icons.search),
                            label: const Text('Retrieve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || !_isInitialized
                                ? null
                                : _deleteData,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stored Keys
            if (_storedKeys.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stored Keys (${_storedKeys.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _storedKeys.map((key) {
                          return Chip(
                            label: Text(key),
                            onDeleted: () {
                              _keyController.text = key;
                              _deleteData();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
