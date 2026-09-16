; OpenROM Enhanced NSIS Installer
; https://github.com/M5Devs/OpenROM

Unicode True

!define APP_NAME    "OpenROM"
!define APP_EXE     "openrom_flutter.exe"
!define APP_CORE    "openrom-core.exe"
!define APP_ICON    "assets\icons\icon.ico"
!define REG_KEY     "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenROM"
!define REG_APP     "Software\OpenROM"

!ifndef APP_VERSION
  !define APP_VERSION "0.0.0"
!endif

Name            "${APP_NAME} ${APP_VERSION}"
OutFile         "OpenROM-v${APP_VERSION}-Setup.exe"
InstallDir      "$PROGRAMFILES64\OpenROM"
InstallDirRegKey HKLM "${REG_APP}" "InstallDir"
RequestExecutionLevel admin
SetCompressor   /SOLID lzma
BrandingText    "OpenROM v${APP_VERSION} — M5 Dev | GPL v3"

; ── Modern UI ─────────────────────────────────────────────────────────────────
!include "MUI2.nsh"
!include "Sections.nsh"

!define MUI_ICON                        "${APP_ICON}"
!define MUI_LICENSEPAGE_CHECKBOX
!define MUI_LICENSEPAGE_CHECKBOX_TEXT   "I have read and accept the security & privacy policy"
!define MUI_UNICON                      "${APP_ICON}"
!define MUI_WELCOMEFINISHPAGE_BITMAP    "assets\icons\installer-sidebar.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP          "assets\icons\installer-header.bmp"
!define MUI_HEADERIMAGE_RIGHT

!define MUI_WELCOMEPAGE_TITLE           "Welcome to OpenROM ${APP_VERSION}"
!define MUI_WELCOMEPAGE_TEXT            "Universal Retro Gaming Toolkit$\r$\n$\r$\nConvert, patch, compress and manage your ROM collection.$\r$\n$\r$\nClick Next to continue."

!define MUI_COMPONENTSPAGE_TEXT_TOP     "Select the components you want to install."
!define MUI_FINISHPAGE_RUN              "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT         "Launch OpenROM"
!define MUI_FINISHPAGE_LINK             "Visit GitHub"
!define MUI_FINISHPAGE_LINK_LOCATION    "https://github.com/M5Devs/OpenROM"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "SECURITY.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ── Version upgrade detection ─────────────────────────────────────────────────
Function .onInit
  ReadRegStr $0 HKLM "${REG_KEY}" "DisplayVersion"
  ${If} $0 != ""
    MessageBox MB_YESNO|MB_ICONQUESTION \
      "OpenROM $0 is already installed.$\r$\nDo you want to upgrade to ${APP_VERSION}?" \
      IDYES upgrade
    Abort
    upgrade:
    ; Remove old installation silently before installing new
    ExecWait '"$INSTDIR\Uninstall.exe" /S'
  ${EndIf}
FunctionEnd

; ── Sections ──────────────────────────────────────────────────────────────────

; Required — Core app files
Section "OpenROM GUI" SecGUI
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r "dist\release\*.*"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Registry — Add/Remove Programs
  WriteRegStr   HKLM "${REG_KEY}" "DisplayName"     "OpenROM"
  WriteRegStr   HKLM "${REG_KEY}" "DisplayVersion"  "${APP_VERSION}"
  WriteRegStr   HKLM "${REG_KEY}" "Publisher"       "M5 Dev"
  WriteRegStr   HKLM "${REG_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr   HKLM "${REG_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr   HKLM "${REG_KEY}" "URLInfoAbout"    "https://github.com/M5Devs/OpenROM"
  WriteRegStr   HKLM "${REG_KEY}" "URLUpdateInfo"   "https://github.com/M5Devs/OpenROM/releases"
  WriteRegStr   HKLM "${REG_KEY}" "DisplayIcon"     "$INSTDIR\${APP_EXE}"
  WriteRegDWORD HKLM "${REG_KEY}" "NoModify"        1
  WriteRegDWORD HKLM "${REG_KEY}" "NoRepair"        1
  WriteRegStr   HKLM "${REG_APP}" "InstallDir"      "$INSTDIR"
SectionEnd

; Start Menu + Desktop shortcuts
Section "Desktop & Start Menu Shortcuts" SecShortcuts
  CreateDirectory "$SMPROGRAMS\OpenROM"
  CreateShortcut  "$SMPROGRAMS\OpenROM\OpenROM.lnk" \
                  "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortcut  "$SMPROGRAMS\OpenROM\Uninstall OpenROM.lnk" \
                  "$INSTDIR\Uninstall.exe"
  CreateShortcut  "$DESKTOP\OpenROM.lnk" \
                  "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
SectionEnd

; Add openrom-core to system PATH
Section "Add openrom-core to PATH" SecPATH
  ; Append install dir to system PATH
  EnVar::AddValue "PATH" "$INSTDIR"
  Pop $0
  ${If} $0 = 0
    DetailPrint "openrom-core added to system PATH"
  ${Else}
    DetailPrint "Warning: Could not add to PATH (EnVar error $0)"
  ${EndIf}
SectionEnd

; File associations
Section "File Associations" SecFileAssoc
  ; .cue → OpenROM
  WriteRegStr HKCR ".cue"             "" "OpenROM.CUEFile"
  WriteRegStr HKCR "OpenROM.CUEFile"  "" "CUE Sheet"
  WriteRegStr HKCR "OpenROM.CUEFile\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
  WriteRegStr HKCR "OpenROM.CUEFile\shell\open\command" "" \
    '"$INSTDIR\${APP_EXE}" "%1"'

  ; .gdi → OpenROM
  WriteRegStr HKCR ".gdi"             "" "OpenROM.GDIFile"
  WriteRegStr HKCR "OpenROM.GDIFile"  "" "GDI Disc Image"
  WriteRegStr HKCR "OpenROM.GDIFile\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
  WriteRegStr HKCR "OpenROM.GDIFile\shell\open\command" "" \
    '"$INSTDIR\${APP_EXE}" "%1"'

  ; .chd → OpenROM
  WriteRegStr HKCR ".chd"             "" "OpenROM.CHDFile"
  WriteRegStr HKCR "OpenROM.CHDFile"  "" "CHD Disc Image"
  WriteRegStr HKCR "OpenROM.CHDFile\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
  WriteRegStr HKCR "OpenROM.CHDFile\shell\open\command" "" \
    '"$INSTDIR\${APP_EXE}" "%1"'

  ; .cso → OpenROM
  WriteRegStr HKCR ".cso"             "" "OpenROM.CSOFile"
  WriteRegStr HKCR "OpenROM.CSOFile"  "" "Compressed ISO"
  WriteRegStr HKCR "OpenROM.CSOFile\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
  WriteRegStr HKCR "OpenROM.CSOFile\shell\open\command" "" \
    '"$INSTDIR\${APP_EXE}" "%1"'

  ; Refresh shell icons
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
    (0x08000000, 0, 0, 0)'
SectionEnd

; Section descriptions (shown on components page)
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecGUI}       "OpenROM desktop application and all bundled tools. Required."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcuts} "Create shortcuts on the Desktop and in the Start Menu."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecPATH}      "Add openrom-core to system PATH so you can run it from any terminal or script."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecFileAssoc} "Associate .chd, .cue, .gdi, and .cso files with OpenROM."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ── Uninstall ─────────────────────────────────────────────────────────────────
Section "Uninstall"
  ; Remove files
  RMDir /r "$INSTDIR"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\OpenROM\OpenROM.lnk"
  Delete "$SMPROGRAMS\OpenROM\Uninstall OpenROM.lnk"
  RMDir  "$SMPROGRAMS\OpenROM"
  Delete "$DESKTOP\OpenROM.lnk"

  ; Remove from PATH
  EnVar::DeleteValue "PATH" "$INSTDIR"

  ; Remove file associations
  DeleteRegKey HKCR ".cue"
  DeleteRegKey HKCR ".gdi"
  DeleteRegKey HKCR ".chd"
  DeleteRegKey HKCR ".cso"
  DeleteRegKey HKCR "OpenROM.CUEFile"
  DeleteRegKey HKCR "OpenROM.GDIFile"
  DeleteRegKey HKCR "OpenROM.CHDFile"
  DeleteRegKey HKCR "OpenROM.CSOFile"

  ; Refresh shell
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
    (0x08000000, 0, 0, 0)'

  ; Remove registry
  DeleteRegKey HKLM "${REG_KEY}"
  DeleteRegKey HKLM "${REG_APP}"
SectionEnd
