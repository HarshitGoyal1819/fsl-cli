; =============================================================================
; fsl-cli Windows Installer — NSIS script (PER-USER, NO ADMIN REQUIRED)
;
; Produces: fsl-cli-<version>-windows-x86_64-setup.exe
;
; Installs to %LOCALAPPDATA%\fsl-cli and modifies the USER PATH (HKCU).
; No administrator password is ever requested.
;
; Requirements: NSIS 3.x + EnvVarUpdate.nsh
; Build: makensis packaging\windows\installer.nsi
; =============================================================================

Unicode True

!define APP_NAME        "fsl-cli"
!define APP_VERSION     "0.1.0"
!define APP_PUBLISHER   "fsl-cli contributors"
!define APP_URL         "https://github.com/yourusername/fsl-cli"
!define EXE_NAME        "fsl-cli.exe"
; Per-user install location — no admin needed
!define INSTALL_DIR     "$LOCALAPPDATA\Programs\fsl-cli"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\fsl-cli"

OutFile "..\..\dist\fsl-cli-${APP_VERSION}-windows-x86_64-setup.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKCU "Software\fsl-cli" "InstallPath"

Name "${APP_NAME} ${APP_VERSION}"
Caption "fsl-cli Installer"
BrandingText "fsl-cli — local AI assistant"

!include "MUI2.nsh"
!include "WinMessages.nsh"

!define MUI_ABORTWARNING
; Icons are optional — only set them if the .ico file exists.
!if /FileExists "fsl-cli.ico"
    !define MUI_ICON   "fsl-cli.ico"
    !define MUI_UNICON "fsl-cli.ico"
!endif

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE  "..\..\packaging\macos\resources\license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ── PER-USER: no admin prompt (this is the key line) ─────────────────────────
RequestExecutionLevel user

; ── StrContains: returns "found" if <needle> is a substring of <haystack> ────
; Usage: Push <haystack>  Push <needle>  Call StrContains  Pop <result>
Function StrContains
    Exch $R1        ; R1 = needle
    Exch
    Exch $R2        ; R2 = haystack
    Push $R3        ; needle length
    Push $R4        ; index
    Push $R5        ; current slice
    StrCpy $R0 "notfound"
    StrLen $R3 $R1
    StrCpy $R4 0
    strc_loop:
        StrCpy $R5 $R2 $R3 $R4
        StrCmp $R5 "" strc_done
        StrCmp $R5 $R1 0 strc_next
            StrCpy $R0 "found"
            Goto strc_done
        strc_next:
        IntOp $R4 $R4 + 1
        Goto strc_loop
    strc_done:
        Pop $R5
        Pop $R4
        Pop $R3
        Pop $R2
        Pop $R1
        Push $R0
FunctionEnd

; ── Installer section ────────────────────────────────────────────────────────
Section "fsl-cli (required)" SecMain
    SectionIn RO

    SetOutPath "$INSTDIR"

    ; Copy the PyInstaller-built binary
    File "..\..\dist\fsl-cli.exe"

    ; Store install path (per-user registry)
    WriteRegStr HKCU "Software\fsl-cli" "InstallPath" "$INSTDIR"

    ; Add to the USER PATH (HKCU) — no admin required.
    ; Read current user PATH, append our dir if not already present.
    ReadRegStr $0 HKCU "Environment" "Path"
    Push "$0"
    Push "$INSTDIR"
    Call StrContains
    Pop $1
    StrCmp $1 "found" path_done 0
        StrCmp $0 "" 0 append_path
            WriteRegExpandStr HKCU "Environment" "Path" "$INSTDIR"
            Goto path_done
        append_path:
            WriteRegExpandStr HKCU "Environment" "Path" "$0;$INSTDIR"
    path_done:

    ; Uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; Add/Remove Programs entry (per-user)
    WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayName"     "${APP_NAME} ${APP_VERSION}"
    WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayVersion"   "${APP_VERSION}"
    WriteRegStr   HKCU "${UNINSTALL_KEY}" "Publisher"        "${APP_PUBLISHER}"
    WriteRegStr   HKCU "${UNINSTALL_KEY}" "URLInfoAbout"     "${APP_URL}"
    WriteRegStr   HKCU "${UNINSTALL_KEY}" "InstallLocation"  "$INSTDIR"
    WriteRegStr   HKCU "${UNINSTALL_KEY}" "UninstallString"  "$INSTDIR\uninstall.exe"
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify"         1
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair"         1

    ; Broadcast so open terminals pick up the new PATH
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=500

    ; Note: Ollama is installed on first run of fsl-cli (its own installer is
    ; per-user on Windows, so it also won't require admin).

SectionEnd

; ── Uninstaller ────────────────────────────────────────────────────────────
Section "Uninstall"
    ; Note: we leave the PATH entry (harmless — points to a removed dir).
    ; Fully scrubbing PATH safely requires more logic; the dir removal is enough.
    Delete "$INSTDIR\fsl-cli.exe"
    Delete "$INSTDIR\uninstall.exe"
    RMDir  "$INSTDIR"

    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    DeleteRegKey HKCU "Software\fsl-cli"
SectionEnd

; ── Finish page: open a new terminal running fsl-cli ────────────────────────
!define MUI_FINISHPAGE_RUN       "$WINDIR\system32\cmd.exe"
!define MUI_FINISHPAGE_RUN_TEXT  "Open Command Prompt and start fsl-cli"
!define MUI_FINISHPAGE_RUN_PARAMETERS "/k fsl-cli"
