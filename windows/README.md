## Build scripts for Windows

### Prerequisites

Install Qt for Windows with MinGW environment.
Sample download link for [Qt 5.7.0](http://download.qt.io/official_releases/qt/5.7/5.7.0/qt-opensource-windows-x86-mingw530-5.7.0.exe).

Be sure to select the option "MinGW" in the "Tools" section (this option is disabled by default).

### Files

- build-windows.ps1 : PowerShell script to build the installer.
- qtlinguist.nsi : NSIS (Nullsoft Scriptable Installation System) script.

### Building the Qt Linguist installer

Execute the script `build-windows.ps1` from PowerShell.

#### Syntax:
```
build-windows.ps1 [[-QtRoot] <String>] [[-Version] <String>] [-NoPause]
```

#### Parameters:
```
-QtRoot <String>
```
Root directory where Qt installations are dropped (default: search all Qt
directories at the root of all local drives). The typical installation
root is C:\Qt, so the default is OK in most cases.

```
-Version <String>
```
Version of Qt Linguist. The default is extracted from the Qt directory name.

```
-NoPause
```
Do not wait for the user to press <enter> at end of execution. By default,
execute a "pause" instruction at the end of execution, which is useful
when the script was run from Windows Explorer.
