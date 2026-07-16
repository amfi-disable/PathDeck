# PathDeck Studio (V1.0.0)

PathDeck is a premium, native macOS developer studio designed to visually manage, prioritize, audit, and safely back up shell environment configurations (specifically targeting `~/.zshrc` and `~/.bash_profile`).

Every developer on a Mac deals with shell profiles, but managing them remains trapped in terminal editors. PathDeck transforms this experience by reading these hidden configuration files and mapping them directly to a safe, modern SwiftUI interface.

---

## Key Features

- **PATH Stack Studio**: Drag-and-drop to prioritize search pathways with visual status dot indicators (Green checkmark denotes folders that exist on disk; orange warning signals dead/broken folders). Offloads disk validation tasks to background threads to prevent UI lag.
- **Alias Studio**: Register custom command shortcuts. Deactivate aliases cleanly by commenting them out in `~/.zshrc` without deleting them.
- **Environment Variables**: Lock sensitive local environment variables behind Touch ID biometrics. Revealing secrets requires verification on a per-row basis. Auto-masks secrets in-memory as bullets (`••••••••`).
- **Safety Restores & Backups**: Every write command creates an automated timestamped backup of the config file in standard Library Application Support directories prior to commits. Recover snapshots securely with 1-click.
- **Ultra-Light Footprint**: Operates entirely in memory with zero external frameworks, keeping operational states strictly under 10MB.

---

## Installation & DMG Releases

Pre-packaged DMG installers are available in our project's **GitHub Releases** page:
1. Navigate to the **Releases** section of this repository.
2. Under the latest tag matching exactly `V1.0.0`, download the compiled `PathDeck.dmg` asset.
3. Double-click the downloaded `PathDeck.dmg` file to mount the disk image, and drag `PathDeck.app` into your local `/Applications/` folder.

### Bypassing Apple Gatekeeper Warnings
Since PathDeck is compiled locally and distributed without Apple Developer notarization signatures, macOS Gatekeeper may present a security warning block upon launch:
- **Right-Click Open Sequence**: Control-click (or right-click) the application icon in Finder, select **Open** from the context menu, and click **Open** again to authorize launch.
- **Terminal Bypass**: Alternatively, strip quarantine metadata attributes recursively using the terminal:
  ```bash
  xattr -cr /Applications/PathDeck.app
  ```

---

## Local Compilation & Build Instructions

PathDeck is built using pure Swift 5.10+ targeting macOS 14+. To compile and package the final release assets locally:

1. Clone this repository:
   ```bash
   git clone https://github.com/amfi-disable/PathDeck.git
   cd PathDeck
   ```
2. Build and package the application bundle using our release script:
   ```bash
   ./scripts/build.sh
   ```
3. Locate the generated release assets in the project root folder:
   - Standalone App: `./PathDeck.app`
   - Compressed Installer: `./PathDeck.dmg`

---

## Development & Test Commands

### Run Unit Tests
To run our test suites containing edge-case tokenizer parser and backup restoration validations:
```bash
swift test
```

### Clean Tree
Our `.gitignore` blocks build caches and output binaries from leaking into the remote tree. Ensure all compiled artifacts are kept locally:
- `.build/`
- `PathDeck.app/`
- `PathDeck.dmg`

---

## Open-Source Contributions

Contributions are welcome! Please follow these guidelines:
- Fork the repository and create your feature branches off `main`.
- Write accompanying unit tests under `tests/pathdecktests/` for parser engine modifications.
- Ensure that the application memory footprint remains under 20MB.
- Submit a Pull Request describing your changes.

---

## License

This project is licensed under the MIT License - see the [license](license) file for details.
