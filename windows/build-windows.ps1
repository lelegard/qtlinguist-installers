#-----------------------------------------------------------------------------
#
#  Copyright (c) 2016-2018, Thierry Lelegard
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#  THE POSSIBILITY OF SUCH DAMAGE.
#
#-----------------------------------------------------------------------------
#
#  Windows PowerShell script to build the package for Qt Linguist on Windows.
#
#-----------------------------------------------------------------------------

<#
 .SYNOPSIS

  Build the Qt Linguist standalone binary installer for Windows.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.

 .PARAMETER QtRoot

  Root directory where Qt installations are dropped (default: search all Qt
  directories at the root of all local drives). The typical installation
  root is C:\Qt, so the default is OK in most cases.

 .PARAMETER Version

  Version of Qt Linguist. The default is extracted from the Qt directory name.
#>

[CmdletBinding()]
param([string]$QtRoot = "", [string]$Version = "", [switch]$NoPause = $false)

Set-StrictMode -Version 3

# A function to exit this script.

function Exit-Script ([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Error $Message
        $Code = 1
    }
    if (-not $NoPause) {
        pause
    }
    exit $Code
}

# A function to search a file in a list of directories and exit if not found.
# $DirList can be a string or an array of strings.

function Search-File ([string]$File, $DirList)
{
    $path = ($DirList | ForEach-Object { Get-ChildItem $_ -Filter $File -ErrorAction SilentlyContinue } | Select-Object -First 1)
    if ($path -eq $null) {
        Exit-Script "$File not found in $DirList"
    }
    return $path.FullName
}

#-----------------------------------------------------------------------------

<#
 .SYNOPSIS

  Create a zip file from any files piped in.

 .PARAMETER Path

  The name of the zip archive to create.

 .PARAMETER Root

  Store directory names in the zip entries. Use the same hierarchy as input
  files but strip the root from their full name. If unspecified, create a
  flat archive of files without hierarchy.

 .PARAMETER Force

  If specified, delete the zip archive if it already exists.

 .EXAMPLE

  PS > dir *.ps1 | New-ZipFile scripts.zip
  Copies all PS1 files in the current directory to scripts.zip

 .EXAMPLE

  PS > "readme.txt" | New-ZipFile docs.zip
  Copies readme.txt to docs.zip

 .NOTES

  Initial version from Windows PowerShell Cookbook (O'Reilly)
  by Lee Holmes (http://www.leeholmes.com/guide)
  with additional options.

  This function requires Microsoft .NET Framework version 4.5 or higher.
  See http://www.microsoft.com/en-us/download/details.aspx?id=30653 or, for
  a full offline package, http://go.microsoft.com/fwlink/?LinkId=225702
  (dotnetfx45_full_x86_x64.exe).
#>
function New-ZipFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=1)][String] $Path,
        [Parameter(Mandatory=$false,Position=2)][String] $Root = $null,
        [Parameter(ValueFromPipeline=$true)] $Input,
        [Switch] $Force
    )

    Set-StrictMode -Version 3

    # Check if the file exists already.
    $ZipName = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (Test-Path $ZipName) {
        if ($Force) {
            Remove-Item $ZipName -Force
        }
        else {
            # Zip file exists and no -Force option, generate an error.
            throw "$ZipName already exists."
        }
    }

    # Build the root path, i.e. the path to strip from entries directory path.
    if ($Root) {
        $Root = (Get-Item $Root).FullName
    }

    # Add the DLL that helps with file compression.
    # This requires .NET 4.5 (FileNotFoundException on previous releases).
    Add-Type -Assembly System.IO.Compression.FileSystem

    try {
        # Open the Zip archive
        $archive = [System.IO.Compression.ZipFile]::Open($ZipName, "Create")

        # Go through each file in the input, adding it to the Zip file specified
        foreach ($file in $Input) {
            $item = $file | Get-Item
            # Skip the current file if it is the zip file itself
            if ($item.FullName -eq $ZipName) {
                continue
            }
            # Skip directories
            if ($item.PSIsContainer) {
                continue
            }
            # Compute entry name in archive.
            if ($Root -and $item.FullName -like "$Root\*") {
                $name = $item.FullName.Substring($Root.Length + 1)
            }
            else {
                $name = $item.Name
            }
            # Add the file to the archive.
            $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $item.FullName, $name)
        }
    }
    finally {
        # Close the file
        $archive.Dispose()
        $archive = $null
    }
}

#-----------------------------------------------------------------------------

# Get the project directories.

$RootDir = (Split-Path -Parent $PSScriptRoot)
$InstallerDir = (Join-Path $RootDir "installers")
$TempDir = (Join-Path $PSScriptRoot "tmp")

# Locate NSIS, the Nullsoft Scriptable Installation System.

$NsisExe = (Search-File "makensis.exe" (@($env:Path -split ';') + @("C:\Program Files\NSIS", "C:\Program Files (x86)\NSIS")))
$NsisScript = (Search-File "qtlinguist.nsi" $PSScriptRoot)

# Locate the latest Qt installation.
# We will locate linguist.exe and gcc.exe under Qt installation tree.
# We do not compile anything but gcc is required by windeployqt.
# We do not simply use a "Get-ChildItem -Recurse". This would be
# simple and neat, but awfully slow since a Qt installation tree
# contains thousands of files. In exploring the Qt installation, we
# skip a few subdirectories which are known to be useless because
# they contain deep directory trees with thousands of files.

$QtBinDir = ""
$LinguistExe = ""
$WinDeployExe = ""
$GccExe = ""
$QtSkipDirectories = @("doc", "docs", "examples", "imports", "include", "lib", "libexec", "licenses", "mkspecs", `
                       "opt", "plugins", "qml", "share", "src", "translations", "phrasebooks", "static")

# This function explores a tree of directories and updates $LinguistExe and $GccExe.
# Always sort subdirectories exploration in order to use the latest Qt installation
# (we assume that the latest is the last one in alphabetical order, eg. 4.8.6, 5.0.2, 5.1.0).

function Get-QtBinDir ($root)
{
    # If root directory exists...
    if (Test-Path $root -PathType Container) {

        # Check existence of executables in root directory.
        if (Test-Path (Join-Path $root linguist.exe)) {
            $script:LinguistExe = (Join-Path $root linguist.exe)
        }
        if (Test-Path (Join-Path $root gcc.exe)) {
            $script:GccExe = (Join-Path $root gcc.exe)
        }

        # Process each subdirectory in alphabetical order.
        foreach ($subdir in @(Get-ChildItem -Path $root -Directory | Sort-Object)) {
            # Recurse if subdirectory name not in skip list.
            if ($subdir -notin $QtSkipDirectories) {
                Get-QtBinDir (Join-Path $root $subdir)
            }
        }
    }
}

if ($QtRoot) {
    # Search only specified root.
    Get-QtBinDir $QtRoot
}
else {
    # Get all local drives, with Qt root directory
    (Get-PSDrive -PSProvider FileSystem | Where DisplayRoot -NotMatch "\\\\.*").Root |
        ForEach-Object { Join-Path $_ "Qt" } | Where { Test-Path $_ -PathType Container } |
        ForEach-Object { Get-QtBinDir $_ }
}

if (!$LinguistExe) {
    Exit-Script "Linguist.exe not found, retry with option -QtRoot"
}
if (!$GccExe) {
    Exit-Script "gcc.exe not found, retry with option -QtRoot"
}

Write-Output "Linguist path is $LinguistExe"
Write-Output "GCC path is $GccExe"

# Make sure that windeployqt is found in the same place as Linguist.

$QtBinDir = (Split-Path -Parent $LinguistExe)
$WinDeployExe = (Search-File "windeployqt.exe" $QtBinDir)

# The Qt translations directory is normally found at the same level as the bin directory.

$TranslationsDir = (Search-File "translations" (Split-Path -Parent $QtBinDir))
Write-Output "Translations path is $TranslationsDir"

# Define a clean and safe path: Qt, GCC and Windows only.

$env:Path = $QtBinDir + ";" + (Split-Path -Parent $GccExe) + ";" + (Join-Path $env:SystemRoot System32) + ";" + $env:SystemRoot

# If Qt version was not specified in command line, try to get it from the linguist path.

if (!$Version) {
    # Select the first element in path named "Qt<version>"
    $Version = ($QtBinDir -split '\\' | Where-Object {$_ -Match '^[Qq][Tt][0-9][0-9`.-]*$'} | Select-Object -First 1)
    if ($Version -ne $null) {
        # Found, remove the leading 'Qt'
        $Version = ($Version -replace '^..','')
    }
    else {
        # Not found, search the first element with only a version name.
        $Version = ($QtBinDir -split '\\' | Where-Object {$_ -Match '^[0-9][0-9`.-]*$'} | Select-Object -First 1)
    }
}
if (!$Version) {
    Exit-Script "Qt version not found in $QtBinDir, use option -Version"
}
Write-Output "Linguist version is $Version"

# Check if there is a 'vcredist' (Visual C++ Redistributable) in the Qt installation.
# Search a subdir named vcredist in the installation tree.

$VcredistName = ""
$VcredistExe = ""
$VcredistDir = ""
$path = $LinguistExe
while (!$VcredistDir -and $path -ne "") {
    $vc = (Join-Path $path vcredist)
    if (Test-Path -PathType Container $vc) {
        $VcredistDir = $vc
    }
    else {
        $path = (Split-Path -Parent $path)
    }
}
if ($VcredistDir) {
    # vcredist directory found, search executables here.
    $exe = @(Get-ChildItem $VcredistDir -Filter *.exe | Where-Object Name -NotLike *x64.exe)
    if ($exe.Count -eq 1) {
        $VcredistExe = $exe[0].FullName
        $VcredistName = (Split-Path -Leaf $VcredistExe)
        Write-Output "VC++ Redistributable is $VcredistExe"
    }
    elseif ($exe.Count -gt 1) {
        Write-Output "More that one .exe in $VcredistDir"
    }
    else {
        Write-Output "No VC++ Redistributable found"
    }
}

# Cleanup and create the temporary directory.

if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
[void] (New-Item -ItemType Directory -Force $TempDir)

# The rest of the script is in a try block to ensure the cleanup of the temporary directory.

try {
    $TempRootDir = (Join-Path $TempDir "QtLinguist")
    [void] (New-Item -ItemType Directory -Force $TempRootDir)
    $TempBinDir = (Join-Path $TempRootDir "bin")
    [void] (New-Item -ItemType Directory -Force $TempBinDir)
    $TempTransDir = (Join-Path $TempBinDir "translations")
    [void] (New-Item -ItemType Directory -Force $TempTransDir)

    # Copy Linguist in temporary directory.
    Copy-Item $LinguistExe $TempBinDir

    # "Deploy" dependent modules.
    & $WinDeployExe $TempBinDir --release --no-quick-import --no-system-d3d-compiler --no-webkit2 --no-angle --no-opengl-sw 

    # Copy additional executables.
    Copy-Item (Join-Path $QtBinDir lconvert.exe) $TempBinDir
    Copy-Item (Join-Path $QtBinDir lrelease.exe) $TempBinDir
    Copy-Item (Join-Path $QtBinDir lupdate.exe) $TempBinDir

    # Copy translation files.
    Copy-Item (Join-Path $TranslationsDir "linguist_*.qm") $TempTransDir
    Copy-Item (Join-Path $TranslationsDir "qt_*.qm") $TempTransDir
    Copy-Item (Join-Path $TranslationsDir "qtbase_*.qm") $TempTransDir
    Copy-Item (Join-Path $TranslationsDir "qtscript_*.qm") $TempTransDir
    Copy-Item (Join-Path $TranslationsDir "qtquick1_*.qm") $TempTransDir
    Copy-Item (Join-Path $TranslationsDir "qtmultimedia_*.qm") $TempTransDir
    Copy-Item (Join-Path $TranslationsDir "qtxmlpatterns_*.qm") $TempTransDir

    # Build the installer.
    & $NsisExe `
        "/DProductVersion=$Version" `
        "/DRootDir=$RootDir" `
        "/DBinDir=$TempBinDir" `
        "/DVcredistExe=$VcredistExe" `
        "/DVcredistName=$VcredistName" `
        "$($NsisScript)"

    # Copy VC++ redistributable libraries.
    $TempRedistDir = (Join-Path $TempRootDir "vcredist")
    [void] (New-Item -ItemType Directory -Force $TempRedistDir)
    Copy-Item $VcredistExe $TempRedistDir

    # Build standalone installer.
    $ZipInstaller = (Join-Path $InstallerDir "QtLinguist-Standalone-$Version.zip")
    Get-ChildItem -Recurse $TempRootDir | New-ZipFile $ZipInstaller -Force -Root $TempDir
}
finally {
    # Cleanup temporary directory.
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force
    }
}
Exit-Script
