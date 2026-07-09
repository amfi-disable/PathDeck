# PathDeck Studio: macOS Distribution Guide

PathDeck is a premium, native macOS developer studio designed to visually manage, prioritize, and safely backup shell configurations (specifically targeting `~/.zshrc` and `~/.bash_profile`).

---

## Technical Specifications & Features

- **PATH Stack Studio**: Drag-and-drop to prioritize search pathways with visual status dot indicators (Green checkmark denotes folders that exist; orange/red warning signals dead/broken folders).
- **Alias Studio**: Edit shortcuts, search triggering keywords, and easily toggle shortcuts to comment them out of files without deleting them.
- **Environment Variables**: Audit credentials, lock sensitive variables behind Touch ID authentication, and auto-mask secrets as bullets (`••••••••`).
- **Safety Restores & Backups**: Every write command creates an automated timestamped backup of the config file in standard Library folders prior to commits. Recover snapshots securely with 1-click.
- **Ultra-Light Footprint**: Operates entirely in memory with zero external frameworks, targeting less than 20MB of resident memory.

---

## Grabbing the DMG from Releases
Developers and end-users can download the pre-packaged `PathDeck.dmg` file from our project's **GitHub Releases** page:
1. Navigate to the **Releases** section of the repository.
2. Under the latest tag (e.g. `V1.0.0`), download the compiled `PathDeck.dmg` asset.
3. Double-click the downloaded `PathDeck.dmg` to mount the disk image, and drag `PathDeck.app` into your local `Applications/` folder.

---

## Bypassing Apple Gatekeeper Warnings

Since PathDeck is compiled locally and distributed without Apple Developer notarization signatures, macOS Gatekeeper may present one of two warning blocks upon launch:
1. **"PathDeck.app cannot be opened because it is from an unidentified developer."**
2. **"PathDeck.app is damaged and cannot be opened. You should move it to the Trash."** (Typically happens to ad-hoc codesigned binaries moved across directory paths or quarantine flags).

### Method 1: The Right-Click Open Sequence
1. Locate `PathDeck.app` inside Finder (or your `Applications/` directory).
2. Control-click (or right-click) the application icon and select **Open** from the shortcut context menu.
3. In the security confirmation sheet pop-up, click **Open** again to authorize launch.
4. macOS will register a security override, permitting direct launches henceforth.

### Method 2: Stripping Extended Attributes (Recommended)
If macOS flags the application as "damaged" due to quarantine policies, strip the metadata attributes using the terminal:
1. Open the Terminal application.
2. Execute the following recursive attribute removal command:
   ```bash
   xattr -cr /Applications/PathDeck.app
   ```
   *(For example, if the app is run directly from the workspace build folder)*:
   ```bash
   xattr -cr ./PathDeck.app
   ```
3. Re-run or launch the application:
   ```bash
   open ./PathDeck.app
   ```

---

## Automated Compilation & Build Pipeline
To compile and package the final release assets locally:

1. Run the build script in the project root:
   ```bash
   ./scripts/build.sh
   ```
2. The script compiles the package in production release mode (`-c release`), scaffolds standard bundle directories, injects `info.plist` (declaring bundle `com.amfi-disable.PathDeck` version `V1.0.0`), signs it locally using ad-hoc `codesign`, and packages the bundle into a compressed DMG disk image using `hdiutil`.
3. Locate the compiled outputs in the project root:
   - Standalone app: `./PathDeck.app`
   - Compressed installer: `./PathDeck.dmg`
