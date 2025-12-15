---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

# Bug Report

Thank you for taking the time to report a bug in **FIPERS**. Well-written bug reports help us identify, reproduce, and fix issues efficiently—especially in a security- and FFI-critical project like this one.

Please fill out **all relevant sections** below. Incomplete reports may be delayed or closed if the issue cannot be reproduced.

---

## Summary

Provide a clear and concise description of the bug.

---

## Environment

Please complete the following information:

* **Platform(s):** Android / iOS / macOS / Linux / Windows / Web
* **OS version:**
* **Flutter version:** (`flutter --version`)
* **Dart version:**
* **FIPERS version / commit:**
* **Build mode:** Debug / Profile / Release

---

## Expected Behavior

Describe what you expected to happen.

---

## Actual Behavior

Describe what actually happened. Include error messages, crashes, or incorrect results.

---

## Reproduction Steps

Provide **minimal and deterministic** steps to reproduce the issue:

1. …
2. …
3. …

If the issue is intermittent, please describe the conditions under which it occurs.

---

## Code Sample (Required)

Provide a **minimal reproducible example**. Avoid large code dumps.

```dart
// Example
final storage = Fipers();
await storage.init(path, passphrase);
await storage.put('key', data);
```

---

## Logs / Output

Include relevant logs, stack traces, or native crash output.

```text
Paste logs here
```

---

## Security Impact

* [ ] This bug has **no security impact**
* [ ] This bug **may affect security** (confidentiality, integrity, availability)

If you selected the second option, **do not include sensitive details publicly**. Instead, follow the instructions in `SECURITY.md` for responsible disclosure.

---

## Platform-Specific Notes

If applicable, include additional details:

* **Android:** NDK version, ABI, device/emulator
* **iOS/macOS:** Xcode version, architecture
* **Linux:** Distribution, libc
* **Windows:** Compiler, architecture
* **Web:** Browser, fallback behavior

---

## Additional Context

Add any other context that might help diagnose the problem (workarounds, frequency, related issues).

---

## Checklist

Before submitting, please confirm:

* [ ] I have searched existing issues to avoid duplicates
* [ ] I am using a supported version
* [ ] I have provided a minimal reproduction
* [ ] I have read `SECURITY.md` if this issue may be security-related

---

Thank you for helping improve FIPERS.
