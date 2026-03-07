;-----------------------------------------------------------------------------
; 
;  Copyright (c) 2016-2026, Thierry Lelegard
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
Caption "Qt Linguist Installer"

!verbose push
!verbose 0
!include "MUI2.nsh"
!include "Sections.nsh"
!include "TextFunc.nsh"
!include "FileFunc.nsh"
!include "WinMessages.nsh"
!include "x64.nsh"
!verbose pop

VIProductVersion ${ProductVersionInfo}
VIAddVersionKey ProductName "Qt Linguist"
VIAddVersionKey ProductVersion "${ProductVersion}"
VIAddVersionKey Comments "Qt Linguist"
VIAddVersionKey CompanyName "The Qt Company Ltd."
VIAddVersionKey LegalCopyright "Copyright (c) The Qt Company Ltd."
VIAddVersionKey FileVersion "${ProductVersionInfo}"
VIAddVersionKey FileDescription "Qt Linguist Installer"

; Name of binary installer file and default installation folder.
!ifdef Win64
    OutFile "${RootDir}\installers\QtLinguist-Win64-${ProductVersion}.exe"
    InstallDir "$PROGRAMFILES64\Qt Linguist"
!else ifdef Win32
    OutFile "${RootDir}\installers\QtLinguist-Win32-${ProductVersion}.exe"
    InstallDir "$PROGRAMFILES\Qt Linguist"
!else ifdef Arm64
    OutFile "${RootDir}\installers\QtLinguist-Arm64-${ProductVersion}.exe"
    InstallDir "$PROGRAMFILES64\Qt Linguist"
!else
    Error "Undefined target platform"
!endif

; Generate a Unicode installer (default is ANSI).
Unicode true

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

; Language selection dialog
!insertmacro MUI_RESERVEFILE_LANGDLL

; Remember the installer language for the current user in the registry.
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "${ProductKey}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

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
!insertmacro MUI_LANGUAGE "Afrikaans"
!insertmacro MUI_LANGUAGE "Albanian"
!insertmacro MUI_LANGUAGE "Arabic"
!insertmacro MUI_LANGUAGE "Basque"
!insertmacro MUI_LANGUAGE "Belarusian"
!insertmacro MUI_LANGUAGE "Bosnian"
!insertmacro MUI_LANGUAGE "Breton"
!insertmacro MUI_LANGUAGE "Bulgarian"
!insertmacro MUI_LANGUAGE "Catalan"
!insertmacro MUI_LANGUAGE "Croatian"
!insertmacro MUI_LANGUAGE "Czech"
!insertmacro MUI_LANGUAGE "Danish"
!insertmacro MUI_LANGUAGE "Dutch"
!insertmacro MUI_LANGUAGE "Esperanto"
!insertmacro MUI_LANGUAGE "Estonian"
!insertmacro MUI_LANGUAGE "Farsi"
!insertmacro MUI_LANGUAGE "Finnish"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "Galician"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Greek"
!insertmacro MUI_LANGUAGE "Hebrew"
!insertmacro MUI_LANGUAGE "Hungarian"
!insertmacro MUI_LANGUAGE "Icelandic"
!insertmacro MUI_LANGUAGE "Indonesian"
!insertmacro MUI_LANGUAGE "Irish"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "Kurdish"
!insertmacro MUI_LANGUAGE "Latvian"
!insertmacro MUI_LANGUAGE "Lithuanian"
!insertmacro MUI_LANGUAGE "Luxembourgish"
!insertmacro MUI_LANGUAGE "Macedonian"
!insertmacro MUI_LANGUAGE "Malay"
!insertmacro MUI_LANGUAGE "Mongolian"
!insertmacro MUI_LANGUAGE "Norwegian"
!insertmacro MUI_LANGUAGE "NorwegianNynorsk"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "Romanian"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "Serbian"
!insertmacro MUI_LANGUAGE "SerbianLatin"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Slovak"
!insertmacro MUI_LANGUAGE "Slovenian"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "SpanishInternational"
!insertmacro MUI_LANGUAGE "Swedish"
!insertmacro MUI_LANGUAGE "Thai"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "Ukrainian"
!insertmacro MUI_LANGUAGE "Uzbek"
!insertmacro MUI_LANGUAGE "Welsh"

;-----------------------------------------------------------------------------
; Initialization functions
;-----------------------------------------------------------------------------

; Installation initialization.
function .onInit

    ; Language selection.
    !insertmacro MUI_LANGDLL_DISPLAY

    ; In 64-bit installers, don't use registry redirection. Also prevent execution
    ; of 64-bit installers on 32-bit systems (the installer itself is 32-bit and
    ; can run on 32-bit systems but it contains 64-bit executables).
    ${If} ${RunningX64}
    ${OrIf} ${IsNativeARM64}
        SetRegView 64
    ${EndIf}

    !ifdef Win64
        ${IfNot} ${IsNativeAMD64}
            MessageBox MB_OK|MB_ICONSTOP \
                "This is a 64-bit Intel version of TSDuck.$\r$\n\
                Not suitable for this system."
            Quit
        ${EndIf}
    !else ifdef Arm64
        ${IfNot} ${IsNativeARM64}
            MessageBox MB_OK|MB_ICONSTOP \
                "This is an Arm64 version of TSDuck.$\r$\n\
                Not suitable for this system."
            Quit
        ${EndIf}
    !else
        ${If} ${IsNativeAMD64}
        ${OrIf} ${IsNativeARM64}
            MessageBox MB_OK|MB_ICONSTOP \
                "This is a 32-bit Intel version of TSDuck.$\r$\n\
                Not suitable for this system."
            Quit
        ${EndIf}
    !endif

functionEnd

; Uninstallation initialization.
function un.onInit

    ; Retrieve the installer language.
    !insertmacro MUI_UNGETLANGUAGE

    ; In 64-bit installers, don't use registry redirection.
    ${If} ${RunningX64}
    ${OrIf} ${IsNativeARM64}
        SetRegView 64
    ${EndIf}

functionEnd

;-----------------------------------------------------------------------------
; Installation section
;-----------------------------------------------------------------------------

Section "Install"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Cleanup previous install.
    RMDir /r "$INSTDIR\bin"
    RMDir /r "$INSTDIR\docs"
    RMDir /r "$INSTDIR\translations"
    RMDir /r "$INSTDIR\vcredist"

    ; Install product files.
    SetOutPath "$INSTDIR\bin"
    File /r "${BinDir}\*"
    SetOutPath "$INSTDIR\docs"
    File /r "${DocDir}\*"

    ; Create a shortcut in start menu.
    CreateShortCut "$SMPROGRAMS\Qt Linguist.lnk" "$INSTDIR\bin\linguist.exe"

    ; Store installation folder in registry.
    WriteRegStr HKLM "${ProductKey}" "InstallDir" $INSTDIR

    ; Install 'vcredist' (Visual C++ Redistributable) if available.
    !if "${VcredistExe}" != ""
        SetOutPath "$INSTDIR\vcredist"
        File "${VcredistExe}"
        ExecWait '"$INSTDIR\vcredist\${VcredistName}" /install /quiet /norestart'
    !endif

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\QtLinguistUninstall.exe"

    ; Declare uninstaller in "Add/Remove Software" control panel
    WriteRegStr HKLM "${UninstallKey}" "DisplayName" "Qt Linguist"
    WriteRegStr HKLM "${UninstallKey}" "Publisher" "The Qt Company Ltd."
    WriteRegStr HKLM "${UninstallKey}" "DisplayVersion" "${ProductVersion}"
    WriteRegStr HKLM "${UninstallKey}" "DisplayIcon" "$INSTDIR\QtLinguistUninstall.exe"
    WriteRegStr HKLM "${UninstallKey}" "UninstallString" "$INSTDIR\QtLinguistUninstall.exe"

    ; Get estimated size of installed files
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "${UninstallKey}" "EstimatedSize" "$0"

SectionEnd

;-----------------------------------------------------------------------------
; Uninstallation section
;-----------------------------------------------------------------------------

Section "Uninstall"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Get installation folder from registry
    ReadRegStr $0 HKLM "${ProductKey}" "InstallDir"

    ; Delete product files.
    RMDir /r "$0\bin"
    RMDir /r "$0\docs"
    RMDir /r "$0\translations"
    RMDir /r "$0\vcredist"
    Delete "$0\QtLinguistUninstall.exe"
    RMDir "$0"

    ; Delete start menu entries  
    Delete "$SMPROGRAMS\Qt Linguist.lnk"

    ; Delete registry entries
    DeleteRegKey HKCU "${ProductKey}"
    DeleteRegKey HKLM "${ProductKey}"
    DeleteRegKey HKLM "${UninstallKey}"

SectionEnd
