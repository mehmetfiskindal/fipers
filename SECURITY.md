# Security Policy

## Overview

**FIPERS** is a security-critical project that provides encrypted, persistent local storage for Flutter applications using native code via FFI. Security is not an optional feature; it is a core design requirement.

This document explains:

* How to report security vulnerabilities
* What security guarantees FIPERS aims to provide
* What is explicitly out of scope
* How security issues are handled and fixed

---

## Supported Versions

Security fixes are applied only to the latest released version and the current development branch.

| Version            | Supported |
| ------------------ | --------- |
| Latest stable      | ✅         |
| Development (main) | ✅         |
| Older releases     | ❌         |

Users are strongly encouraged to stay up to date.

---

## Reporting a Vulnerability (Responsible Disclosure)

If you discover a potential security vulnerability, **do not open a public issue**.

Instead:

1. Contact the maintainers privately via the repository’s configured security contact (GitHub Security Advisories or maintainer email).
2. Provide a detailed report including:

   * Affected platform(s)
   * Description of the vulnerability
   * Steps to reproduce (if possible)
   * Potential impact
3. Allow maintainers reasonable time to investigate and respond before any public disclosure.

We aim to acknowledge reports within **72 hours**.

---

## Threat Model

FIPERS is designed to protect against:

* Offline attackers with access to application storage
* Accidental plaintext persistence
* Data tampering and corruption
* Incorrect key usage or nonce reuse

FIPERS does **not** protect against:

* Compromised devices or rooted/jailbroken environments
* Malicious code running in the same process
* Side-channel attacks outside reasonable threat assumptions
* Weak or reused user passphrases

---

## Cryptographic Guarantees

FIPERS enforces the following guarantees by design:

* Authenticated encryption (AES-256-GCM or equivalent)
* Unique nonce/IV per encryption operation
* Strong key derivation (PBKDF2-HMAC-SHA256 or Argon2id)
* No plaintext data written to disk
* No encryption keys stored on disk
* Explicit zeroing of sensitive memory where feasible

Cryptographic primitives are not home-grown. Well-established libraries (e.g., OpenSSL, libsodium) are used.

---

## Secure Development Rules

When modifying security-sensitive code:

* Do not introduce new cryptographic primitives without discussion
* Do not weaken defaults for convenience
* Do not bypass authentication or integrity checks
* Do not expose secrets across FFI boundaries
* Do not rely on undefined behavior

All security-relevant changes must be clearly documented in pull requests.

---

## Native Code Considerations

Given the use of native code:

* All FFI boundaries must have explicit ownership rules
* All allocations must have deterministic frees
* Input validation is mandatory
* Error paths must be handled explicitly

Memory safety bugs are considered security vulnerabilities.

---

## Dependency Security

* Cryptographic dependencies must be kept reasonably up to date
* Known vulnerable versions must not be used
* Platform-provided secure random generators are required

---

## Handling of Security Issues

When a vulnerability is confirmed:

1. The issue is reproduced and scoped
2. A fix is developed and reviewed
3. A patched release is published
4. A security advisory is issued if appropriate

Public disclosure happens only after a fix is available.

---

## Security Best Practices for Users

Users of FIPERS are strongly advised to:

* Use strong, unique passphrases
* Protect application-level secrets
* Keep dependencies up to date
* Understand platform-specific limitations

---

## Final Notes

Security is a continuous process. Design decisions favor **correctness and defense-in-depth** over performance shortcuts.

If something feels difficult or strict, it is likely intentional.

Thank you for helping keep FIPERS secure.
