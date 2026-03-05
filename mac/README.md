## Build scripts for macOS

### Prerequisites

- Install Xcode from the Apple AppStore (free of charge).
- Install ["Qt for Open Source Use"](https://www.qt.io/development/download-qt-installer-oss) for macOS.

### Files

- `build-mac.sh` : Bash script to build the installer. Run it from a terminal.

### Using the installer

The generated file is a `.dmg` image, like most macOS installers.
Double-click on this file from the Finder.
The volume image is mounted and opened in the Finder.
Simply drag the *Qt Linguist* icon and drop it into the *Applications* icon to install Qt Linguist.

Qt Linguist can now be started from the *Launch Pad*.

### Specificities of the macOS installer

Because the Qt binaries are signed, we need some non-standard processing.
If we use `macdeployqt`, the binaries are modified and the signatures are invalidated.
We could completely remove the signature from all binaries but the resulting binaries
fail to execute ("killed: 9"). We could not find a reliable way to completely remove
signatures from a bundle.

Therefore, we do a manual deployment to preserve the original structure of Qt, so that
there is no need to modify the binaries.

Additionally, to reduce the size of the installer, we strip the universal binaries and
build two distinct installers, one for arm64 and one for x86_64.
