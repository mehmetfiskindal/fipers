# Contributing to FIPERS

First of all, thank you for considering contributing to **FIPERS**. This project aims to provide a **secure, encrypted, cross-platform persistent storage solution for Flutter using FFI**. Contributions of any kind—code, documentation, testing, or design discussions—are welcome.

---

## 📌 Project Scope & Philosophy

FIPERS is designed with the following principles:

* **Security-first**: No plaintext persistence, strong cryptography by default
* **FFI-centric**: Native code is the source of truth for storage and crypto
* **Cross-platform correctness** over feature parity
* **Minimal public API**, extensible internal design
* **Production-grade quality** (no undefined behavior, no shortcuts)

When contributing, please keep these principles in mind.

---

## 🧱 Architecture Overview

High-level layers:

```
Dart Public API
   ↓
Dart Platform Interface
   ↓
FFI Bindings (ffigen)
   ↓
Native C Core (Storage + Crypto)
   ↓
Encrypted File System
```

Key rules:

* Dart **never** handles encryption keys or ciphertext logic
* Native code exposes **C ABI only** (no C++ symbols)
* Memory ownership across FFI boundaries must be explicit

---

## 🛠️ Development Setup

### Prerequisites

* Flutter (stable)
* Dart >= project minimum SDK
* C toolchain (platform-specific)
* CMake
* OpenSSL or libsodium (depending on platform)

### Bootstrap

```bash
flutter pub get
```

For native bindings:

```bash
dart run ffigen
```

---

## 🧪 Testing Guidelines

### Dart Tests

* All public APIs must be covered
* Platform-specific behavior must be guarded with conditional tests
* Web tests must assert `UnsupportedError` where applicable

```bash
flutter test
```

### Native Tests (Optional but Encouraged)

* Unit-test crypto primitives where feasible
* Validate encryption/decryption round-trips
* Check failure paths (wrong key, corrupted file, invalid tag)

---

## 🔐 Security & Cryptography Rules (STRICT)

When touching crypto or storage code:

* ❌ Do NOT invent cryptographic algorithms
* ❌ Do NOT reuse nonces
* ❌ Do NOT store keys on disk
* ❌ Do NOT expose secrets to Dart

Required properties:

* Authenticated encryption (AES-GCM or equivalent)
* Secure random generation
* Explicit zeroing of sensitive memory
* Constant-time operations where applicable

Security-relevant changes **must be explained clearly** in the PR description.

---

## 📁 Coding Standards

### Dart

* Follow `analysis_options.yaml` strictly
* No ignored lints without justification
* Prefer explicit types at FFI boundaries
* Avoid dynamic and reflection

### Native (C)

* C11 or later
* No undefined behavior
* Defensive checks on all inputs
* Clear error codes (no magic values)
* Free what you allocate

---

## 🧩 Platform-Specific Contributions

### Android

* NDK + CMake based
* No Java/Kotlin logic beyond loading the library

### iOS / macOS

* Xcode-compatible sources
* Avoid private Apple APIs

### Linux / Windows

* Shared library (.so / .dll)
* Stable exported symbols

### Web

* No FFI
* Stub or WebCrypto-based fallback only

---

## 📦 Versioning & Compatibility

* Follow **semantic versioning**
* Public Dart API changes require a major bump
* Native ABI changes must be documented

---

## 🔀 Pull Request Process

1. Fork the repository
2. Create a feature branch (`feature/<name>` or `fix/<name>`)
3. Ensure all tests pass
4. Update documentation if needed
5. Open a PR with:

   * Clear description
   * Motivation
   * Security impact (if any)

Draft PRs are welcome for early feedback.

---

## 🐛 Bug Reports

When filing a bug, please include:

* Platform(s)
* Flutter & Dart versions
* Expected vs actual behavior
* Reproduction steps (minimal example)

---

## 💡 Feature Requests

Feature proposals should explain:

* Use case
* Security implications
* Platform impact
* Backward compatibility

Large changes should start with an issue or discussion.

---

## 📜 License & CLA

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

## 🙏 Final Notes

This project intentionally favors **correctness and security over speed of development**. If something feels complex, that is usually by design.

Thank you for helping make FIPERS better.
