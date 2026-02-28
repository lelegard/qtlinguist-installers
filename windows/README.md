## Build scripts for Windows

### Prerequisites

Install ["Qt for Open Source Use"](https://www.qt.io/development/download-qt-installer-oss) for Windows with MinGW environment.

On Intel systems (x86 and x64), do not forget to select the Qt components for the latest version of MinGW.
In the list of components, select Qt -> Qt-with-latest-version -> MinGW-with-latest-version.
If you want to develop with Qt on Windows, also select Build Tools -> MinGW-with-latest-version.

### Files

- build-windows.ps1 : PowerShell script to build the installer.
- qtlinguist.nsi : NSIS (Nullsoft Scriptable Installation System) script.

### Building the Qt Linguist installers

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

### Using the installers

The script generates two installers, a classical one and a standalone / portable one.

The classical installer is the `.exe` file. Execute it to install Qt Linguist.

The standalone / portable installer is the `.zip` file. It is meant to be used
be users without administration privileges on the Windows system. Simply unzip
the file anywhere. To run Qt Linguist, execute `QtLinguist\bin\linguist.exe`.
