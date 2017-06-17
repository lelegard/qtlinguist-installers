;-----------------------------------------------------------------------------
; 
;  Copyright (c) 2016, Thierry Lelegard
;  All rights reserved.
; 
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are met:
; 
;  1. Redistributions of source code must retain the above copyright notice,
;     this list of conditions and the following disclaimer. 
;  2. Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution. 
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
;  THE POSSIBILITY OF SUCH DAMAGE.
; 
;-----------------------------------------------------------------------------
; 
;  NSIS script to build the Qt Linguist binary installer for Windows.
;  Do not invoke NSIS directly, use build-windows.ps1 to build the installer.
;
;-----------------------------------------------------------------------------

Name "Qt Linguist"

!verbose push
!verbose 0
!include "MUI2.nsh"
!include "WinMessages.nsh"
!verbose pop

; Installer file name.
OutFile "${RootDir}\installers\QtLinguist-${ProductVersion}.exe"

; Registry entry for product info and uninstallation info.
!define ProductKey "Software\QtLinguist"
!define UninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\QtLinguist"

; Use XP manifest.
XPStyle on

; Request administrator privileges for Windows Vista and higher.
RequestExecutionLevel admin

; "Modern User Interface" (MUI) settings
!define MUI_ABORTWARNING
!define MUI_ICON "${RootDir}\images\linguist.ico"
!define MUI_UNICON "${RootDir}\images\linguist.ico"

; Default installation folder
InstallDir "$PROGRAMFILES\Qt Linguist"

; Get installation folder from registry if available from a previous installation.
InstallDirRegKey HKLM "${ProductKey}" "InstallDir"

; Installer pages
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

;-----------------------------------------------------------------------------
; Installation section
;-----------------------------------------------------------------------------

Section "Install"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Cleanup previous install.
    RMDir /r "$INSTDIR\bin"
    RMDir /r "$INSTDIR\vcredist"

    ; Install product files.
    SetOutPath "$INSTDIR\bin"
    File /r "${BinDir}\*"

    ; Create a shortcut in start menu.
    CreateShortCut "$SMPROGRAMS\Qt Linguist.lnk" "$INSTDIR\bin\linguist.exe"

    ; Store installation folder in registry.
    WriteRegStr HKLM "${ProductKey}" "InstallDir" $INSTDIR

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\QtLinguistUninstall.exe"

    ; Install 'vcredist' (Visual C++ Redistributable) if available.
    !if "${VcredistExe}" != ""
        SetOutPath "$INSTDIR\vcredist"
        File "${VcredistExe}"
        ExecWait '"$INSTDIR\vcredist\${VcredistName}" /install /quiet /norestart'
    !endif

    ; Declare uninstaller in "Add/Remove Software" control panel
    WriteRegStr HKLM "${UninstallKey}" "DisplayName" "Qt Linguist"
    WriteRegStr HKLM "${UninstallKey}" "DisplayVersion" "${ProductVersion}"
    WriteRegStr HKLM "${UninstallKey}" "DisplayIcon" "$INSTDIR\QtLinguistUninstall.exe"
    WriteRegStr HKLM "${UninstallKey}" "UninstallString" "$INSTDIR\QtLinguistUninstall.exe"

SectionEnd

;-----------------------------------------------------------------------------
; Uninstallation section
;-----------------------------------------------------------------------------

Section "Uninstall"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Delete product files.
    RMDir /r "$INSTDIR\bin"
    RMDir /r "$INSTDIR\vcredist"
    Delete "$INSTDIR\QtLinguistUninstall.exe"
    RMDir "$INSTDIR"

    ; Delete start menu entries  
    Delete "$SMPROGRAMS\Qt Linguist.lnk"

    ; Delete registry entries
    DeleteRegKey HKCU "${ProductKey}"
    DeleteRegKey HKLM "${ProductKey}"
    DeleteRegKey HKLM "${UninstallKey}"

SectionEnd
