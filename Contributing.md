# Contributing to PathDeck

Thank you for your interest in contributing to PathDeck! We welcome community contributions to help improve this visual macOS developer studio.

---

## How to Contribute

### 1. Reporting Bugs
- Please search existing issues to see if the bug has already been reported.
- If not, create a new bug report using our standard bug template.

### 2. Suggesting Enhancements
- Open a feature request detailing your proposed enhancement and rationale.

### 3. Code Contributions
- Fork the repository and create your feature branches off the `main` branch.
- Maintain our strict **all-lowercase file naming standard** for all files inside the repository (except for the final output `.app` and `.dmg`).
- Write accompanying unit tests under `tests/pathdecktests/` for any parser or backup manager updates.
- Keep the operational memory footprint under 20MB.
- Submit a Pull Request.

---

## Code Style & Rules

- **Strict File Naming**: Every file and folder inside the repository must be in lowercase.
- **Pure Swift**: No third-party packages or dependencies.
- **Safety First**: Never modify configuration files without executing an automated backup snapshot first.
