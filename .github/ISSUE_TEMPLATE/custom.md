---
name: Custom issue template
about: Describe this issue template's purpose here.
title: ''
labels: ''
assignees: ''

---

Below are **custom GitHub Issue Templates (YAML)** tailored specifically for **FIPERS**. These are designed for a **security‑critical, FFI‑based, multi‑platform project** and intentionally enforce high‑quality reports.

Create the following files under:

```
.github/ISSUE_TEMPLATE/
```

---

## 1️⃣ bug_report.yml (Custom Bug Report)

```yaml
name: "Bug Report"
description: "Report a reproducible bug in FIPERS"
title: "[Bug]: "
labels: [bug]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for reporting a bug in **FIPERS**.
        This project uses native code and cryptography. Please be precise.

  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: Clear and concise description of the issue.
    validations:
      required: true

  - type: dropdown
    id: platform
    attributes:
      label: Platform(s)
      multiple: true
      options:
        - Android
        - iOS
        - macOS
        - Linux
        - Windows
        - Web
    validations:
      required: true

  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: Flutter, Dart, OS, FIPERS version
      placeholder: |
        Flutter:
        Dart:
        OS:
        FIPERS:
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual Behavior
    validations:
      required: true

  - type: textarea
    id: repro
    attributes:
      label: Reproduction Steps
      description: Minimal, deterministic steps
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Logs / Stack Traces
      render: text

  - type: checkboxes
    id: security
    attributes:
      label: Security Impact
      options:
        - label: This bug may impact security (confidentiality, integrity, availability)
        - label: This bug has no known security impact

  - type: markdown
    attributes:
      value: |
        ⚠️ If this issue affects security, **do not disclose sensitive details publicly**.
        Follow SECURITY.md for responsible disclosure.
```

---

## 2️⃣ feature_request.yml (Custom Feature Request)

```yaml
name: "Feature Request"
description: "Propose a new feature or enhancement"
title: "[Feature]: "
labels: [enhancement]
body:
  - type: markdown
    attributes:
      value: |
        Feature requests must consider **security, FFI boundaries, and cross‑platform impact**.

  - type: textarea
    id: summary
    attributes:
      label: Summary
    validations:
      required: true

  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem does this feature solve?
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: High‑level design and API impact
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered

  - type: dropdown
    id: platforms
    attributes:
      label: Affected Platforms
      multiple: true
      options:
        - Android
        - iOS
        - macOS
        - Linux
        - Windows
        - Web

  - type: textarea
    id: security
    attributes:
      label: Security Considerations
      description: Required. How does this affect encryption or key handling?
    validations:
      required: true

  - type: dropdown
    id: scope
    attributes:
      label: Scope
      options:
        - Small (localized change)
        - Medium (new API or component)
        - Large (architectural change)

  - type: checkboxes
    id: contribution
    attributes:
      label: Willingness to Contribute
      options:
        - label: I am willing to implement this
        - label: I can help with design/review
```

---

## 3️⃣ config.yml (Template Configuration – REQUIRED)

```yaml
blank_issues_enabled: false
contact_links:
  - name: Security Vulnerability
    url: https://github.com/OWNER/REPO/security/advisories
    about: "Report security issues privately. Do NOT open public issues."
```

⚠️ Replace `OWNER/REPO` with your actual repository path.

---

## ✅ Result

After adding these files:

* GitHub will **force structured issues**
* Security bugs are redirected correctly
* Low‑quality issues are dramatically reduced
* Your repo appears **professional and enterprise‑ready**

---

If you want next:

* `PULL_REQUEST_TEMPLATE.md`
* `ARCHITECTURE.md`
* `THREAT_MODEL.md`
* `ABI_STABILITY.md`

Say the word and we continue.
