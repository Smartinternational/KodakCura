!ifndef VERSION
  !define VERSION '15.09.80'
!endif

; The name of the installer
Name "Kodak 3D Slicer ${VERSION}"

; The file to write
OutFile "Kodak_3D_Slicer_${VERSION}.exe"

; The default installation directory
InstallDir $PROGRAMFILES\Kodak_3D_Slicer

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Kodak_3D_Slicer_${VERSION}" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

; Set the LZMA compressor to reduce size.
SetCompressor /SOLID lzma
;--------------------------------

!include "MUI2.nsh"
!include "Library.nsh"

; !define MUI_ICON "dist/resources/cura.ico"
!define MUI_BGCOLOR FFFFFF

; Directory page defines
!define MUI_DIRECTORYPAGE_VERIFYONLEAVE

; Header
; Don't show the component description box
!define MUI_COMPONENTSPAGE_NODESC

;Do not leave (Un)Installer page automaticly
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

;Run Cura after installing
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Start Kodak 3D Slicer_ ${VERSION}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"

;Add an option to show release notes
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\plugins\ChangeLogPlugin\changelog.txt"

; Pages
;!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"

; Reserve Files
!insertmacro MUI_RESERVEFILE_LANGDLL
ReserveFile '${NSISDIR}\Plugins\InstallOptions.dll'

;--------------------------------

; The stuff to install
Section "Kodak 3D Slicer ${VERSION}"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File /r "dist\"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM "SOFTWARE\Kodak_3D_Slicer_${VERSION}" "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Kodak_3D_Slicer_${VERSION}" "DisplayName" "Kodak 3D Slicer ${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Kodak_3D_Slicer_${VERSION}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Kodak_3D_Slicer_${VERSION}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Kodak_3D_Slicer_${VERSION}" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

  ; Write start menu entries for all users
  SetShellVarContext all
  
  CreateDirectory "$SMPROGRAMS\Kodak 3D Slicer ${VERSION}"
  CreateShortCut "$SMPROGRAMS\Kodak 3D Slicer ${VERSION}\Uninstall Kodak 3D Slicer ${VERSION}.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\Kodak 3D Slicer ${VERSION}\Kodak 3D Slicer ${VERSION}.lnk" "$INSTDIR\Kodak3DSlicer.exe" '' "$INSTDIR\Kodak3DSlicer.exe" 0
  
SectionEnd

Function LaunchLink
  ; Write start menu entries for all users
  SetShellVarContext all
  Exec '"$WINDIR\explorer.exe" "$SMPROGRAMS\Kodak 3D Slicer ${VERSION}\Kodak 3D Slicer ${VERSION}.lnk"'
FunctionEnd

Section "Install Visual Studio 2010 Redistributable"
    SetOutPath "$INSTDIR"
    File "vcredist_2010_20110908_x86.exe"
    
    IfSilent +2
      ExecWait '"$INSTDIR\vcredist_2010_20110908_x86.exe" /q /norestart'

SectionEnd

Section "Open STL files with Kodak 3D Slicer"
   ${registerExtension} "$INSTDIR\Kodak3DSlicer.exe" ".stl" "STL_File"
SectionEnd

Section /o "Open OBJ files with Kodak 3D Slicer"
	WriteRegStr HKCR .obj "" "Kodak 3D Slicer OBJ model file"
	DeleteRegValue HKCR .obj "Content Type"
	WriteRegStr HKCR "Kodak 3D Slicer OBJ model file\DefaultIcon" "" "$INSTDIR\Kodak3DSlicer.exe,0"
	WriteRegStr HKCR "Kodak 3D Slicer OBJ model file\shell" "" "open"
	WriteRegStr HKCR "Kodak 3D Slicer OBJ model file\shell\open\command" "" '"$INSTDIR\Kodak3DSlicer.exe" "%1"'
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Kodak_3D_Slicer_${VERSION}"
  DeleteRegKey HKLM "SOFTWARE\Kodak_3D_Slicer_${VERSION}"

  ; Write start menu entries for all users
  SetShellVarContext all
  ; Remove directories used
  RMDir /r "$SMPROGRAMS\Kodak 3D Slicer ${VERSION}"
  RMDir /r "$INSTDIR"

SectionEnd
