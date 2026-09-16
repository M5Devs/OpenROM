; OpenROM NSIS Installer Script
; https://github.com/M5Devs/OpenROM

!define APP_NAME    "OpenROM"
!define APP_EXE     "openrom_flutter.exe"
!define APP_ICON    "assets\icons\icon.ico"
!define REG_KEY     "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenROM"

; Version is passed via /DAPP_VERSION= from command line
!ifndef APP_VERSION
  !define APP_VERSION "0.0.0"
!endif

Name            "${APP_NAME} ${APP_VERSION}"
OutFile         "OpenROM-v${APP_VERSION}-Setup.exe"
InstallDir      "$PROGRAMFILES64\OpenROM"
InstallDirRegKey HKLM "Software\OpenROM" "InstallDir"
RequestExecutionLevel admin
SetCompressor   /SOLID lzma
BrandingText    "OpenROM v${APP_VERSION} — M5 Dev"

; Modern UI
!include "MUI2.nsh"
!define MUI_ICON "${APP_ICON}"
!define MUI_UNICON "${APP_ICON}"
!define MUI_WELCOMEPAGE_TITLE "Welcome to OpenROM ${APP_VERSION}"
!define MUI_WELCOMEPAGE_TEXT "Universal Retro Gaming Toolkit$\r$\n$\r$\nConvert, patch, compress and manage your ROM collection.$\r$\n$\r$\nClick Next to continue."
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch OpenROM"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ── Install ──────────────────────────────────────────────────────────────────
Section "OpenROM" SecMain
  SectionIn RO  ; Required section

  SetOutPath "$INSTDIR"
  File /r "dist\release\*.*"

  ; Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\OpenROM"
  CreateShortcut  "$SMPROGRAMS\OpenROM\OpenROM.lnk" \
                  "$INSTDIR\${APP_EXE}" "" \
                  "$INSTDIR\${APP_EXE}" 0

  CreateShortcut  "$SMPROGRAMS\OpenROM\Uninstall OpenROM.lnk" \
                  "$INSTDIR\Uninstall.exe"

  ; Desktop shortcut (optional — user can delete)
  CreateShortcut  "$DESKTOP\OpenROM.lnk" \
                  "$INSTDIR\${APP_EXE}" "" \
                  "$INSTDIR\${APP_EXE}" 0

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Registry — Add/Remove Programs entry
  WriteRegStr   HKLM "${REG_KEY}" "DisplayName"          "OpenROM"
  WriteRegStr   HKLM "${REG_KEY}" "DisplayVersion"       "${APP_VERSION}"
  WriteRegStr   HKLM "${REG_KEY}" "Publisher"            "M5 Dev"
  WriteRegStr   HKLM "${REG_KEY}" "UninstallString"      "$INSTDIR\Uninstall.exe"
  WriteRegStr   HKLM "${REG_KEY}" "InstallLocation"      "$INSTDIR"
  WriteRegStr   HKLM "${REG_KEY}" "URLInfoAbout"         "https://github.com/M5Devs/OpenROM"
  WriteRegStr   HKLM "${REG_KEY}" "URLUpdateInfo"        "https://github.com/M5Devs/OpenROM/releases"
  WriteRegDWORD HKLM "${REG_KEY}" "NoModify"             1
  WriteRegDWORD HKLM "${REG_KEY}" "NoRepair"             1
SectionEnd

; ── Uninstall ─────────────────────────────────────────────────────────────────
Section "Uninstall"
  ; Remove installed files
  RMDir /r "$INSTDIR"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\OpenROM\OpenROM.lnk"
  Delete "$SMPROGRAMS\OpenROM\Uninstall OpenROM.lnk"
  RMDir  "$SMPROGRAMS\OpenROM"
  Delete "$DESKTOP\OpenROM.lnk"

  ; Remove registry entries
  DeleteRegKey HKLM "${REG_KEY}"
  DeleteRegKey HKLM "Software\OpenROM"
SectionEnd
