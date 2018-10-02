﻿# NSIS file to create a self-installing exe for Vim.
# It requires NSIS version 3.0 or later.
# Last Change:	2014 Nov 5

Unicode true

# WARNING: if you make changes to this script, look out for $0 to be valid,
# because uninstall deletes most files in $0.

# Location of gvim_ole.exe, vimw32.exe, GvimExt/*, etc.
!ifndef VIMSRC
  !define VIMSRC "..\src"
!endif

# Location of runtime files
!ifndef VIMRT
  !define VIMRT ".."
!endif

# Location of extra tools: diff.exe
!ifndef VIMTOOLS
  !define VIMTOOLS ..\..
!endif

# Location of gettext.
# It must contain two directories: gettext32 and gettext64.
# See README.txt for detail.
!ifndef GETTEXT
  !define GETTEXT ${VIMRT}
!endif

# Comment the next line if you don't have UPX.
# Get it at https://upx.github.io/
!define HAVE_UPX

# Comment the next line if you do not want to add Native Language Support
!define HAVE_NLS

# Uncomment the next line if you want to include VisVim extension:
#!define HAVE_VIS_VIM

# Comment the following line to create a multilanguage installer:
!define HAVE_MULTI_LANG

!include gvim_version.nsh	# for version number

# ----------- No configurable settings below this line -----------

!include "Library.nsh"		# For DLL install
!ifdef HAVE_VIS_VIM
  !include "UpgradeDLL.nsh"	# for VisVim.dll
!endif
!include "LogicLib.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "Sections.nsh"
!include "x64.nsh"

!define PRODUCT		"Vim ${VER_MAJOR}.${VER_MINOR}"
!define UNINST_REG_KEY	"Software\Microsoft\Windows\CurrentVersion\Uninstall"
!define UNINST_REG_KEY_VIM  "${UNINST_REG_KEY}\${PRODUCT}"

Name "${PRODUCT}"
OutFile gvim${VER_MAJOR}${VER_MINOR}.exe
CRCCheck force
SetCompressor /SOLID lzma
SetCompressorDictSize 64
ManifestDPIAware true
SetDatablockOptimize on
RequestExecutionLevel highest

!ifdef HAVE_UPX
  !packhdr temp.dat "upx --best --compress-icons=1 temp.dat"
!endif


##########################################################
# MUI2 settings

!define MUI_ICON   "icons\vim_16c.ico"
!define MUI_UNICON "icons\vim_uninst_16c.ico"

# Show all languages, despite user's codepage:
!define MUI_LANGDLL_ALLLANGUAGES

!define MUI_WELCOMEFINISHPAGE_BITMAP       "icons\welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP     "icons\uninstall.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP             "icons\header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP           "icons\un_header.bmp"

!define MUI_WELCOMEFINISHPAGE_BITMAP_STRETCH    "AspectFitHeight"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP_STRETCH  "AspectFitHeight"
!define MUI_HEADERIMAGE_BITMAP_STRETCH          "AspectFitHeight"
!define MUI_HEADERIMAGE_UNBITMAP_STRETCH        "AspectFitHeight"

!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_LICENSEPAGE_CHECKBOX
!define MUI_FINISHPAGE_RUN                 "$0\gvim.exe"
!define MUI_FINISHPAGE_RUN_TEXT            $(str_show_readme)
!define MUI_FINISHPAGE_RUN_PARAMETERS      "-R $\"$0\README.txt$\""

# This adds '\Vim' to the user choice automagically.  The actual value is
# obtained below with CheckOldVim.
InstallDir "$PROGRAMFILES\Vim"

# Types of installs we can perform:
InstType $(str_type_typical)
InstType $(str_type_minimal)
InstType $(str_type_full)

SilentInstall normal

# General custom functions for MUI2:
#!define MUI_CUSTOMFUNCTION_ABORT   VimOnUserAbort
#!define MUI_CUSTOMFUNCTION_UNABORT un.VimOnUserAbort

# Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${VIMRT}\doc\uganda.nsis.txt"
!insertmacro MUI_PAGE_COMPONENTS
Page custom SetCustom ValidateCustom
#!define MUI_PAGE_CUSTOMFUNCTION_LEAVE VimFinalCheck
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

# Uninstaller pages:
!insertmacro MUI_UNPAGE_CONFIRM
#!define MUI_PAGE_CUSTOMFUNCTION_LEAVE un.VimCheckRunning
!insertmacro MUI_UNPAGE_COMPONENTS
!insertmacro MUI_UNPAGE_INSTFILES
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_UNPAGE_FINISH

##########################################################
# Languages Files

!insertmacro MUI_RESERVEFILE_LANGDLL
!include "lang\english.nsi"

# Include support for other languages:
!ifdef HAVE_MULTI_LANG
    !include "lang\dutch.nsi"
    !include "lang\german.nsi"
    !include "lang\italian.nsi"
    !include "lang\japanese.nsi"
    !include "lang\simpchinese.nsi"
    !include "lang\tradchinese.nsi"
!endif


# Global variables
Var vim_dialog
Var vim_nsd_keymap_1
Var vim_nsd_keymap_2
Var vim_nsd_mouse_1
Var vim_nsd_mouse_2
Var vim_nsd_mouse_3
Var vim_keymap_stat
Var vim_mouse_stat


# Reserve files
ReserveFile ${VIMSRC}\installw32.exe

##########################################################
# Functions

# Get parent directory
# Share this function both on installer and uninstaller
!macro GetParent un
Function ${un}GetParent
  Exch $0 ; old $0 is on top of stack
  Push $1
  Push $2
  StrCpy $1 -1
  ${Do}
    StrCpy $2 $0 1 $1
    ${If} $2 == ""
    ${OrIf} $2 == "\"
      ${ExitDo}
    ${EndIf}
    IntOp $1 $1 - 1
  ${Loop}
  StrCpy $0 $0 $1
  Pop $2
  Pop $1
  Exch $0 ; put $0 on top of stack, restore $0 to original value
FunctionEnd
!macroend

!insertmacro GetParent ""
!insertmacro GetParent "un."

# Check if Vim is already installed.
# return: Installed directory. If not found, it will be empty.
Function CheckOldVim
  Push $0
  Push $R0
  Push $R1
  Push $R2

  ${If} ${RunningX64}
    SetRegView 64
  ${EndIf}

  ClearErrors
  StrCpy $0  ""   # Installed directory
  StrCpy $R0 0    # Sub-key index
  StrCpy $R1 ""   # Sub-key
  ${Do}
    # Eumerate the sub-key:
    EnumRegKey $R1 HKLM ${UNINST_REG_KEY} $R0

    # Stop if no more sub-key:
    ${If} ${Errors}
    ${OrIf} $R1 == ""
      ${ExitDo}
    ${EndIf}

    # Move to the next sub-key:
    IntOp $R0 $R0 + 1

    # Check if the key is Vim uninstall key or not:
    StrCpy $R2 $R1 4
    ${If} $R2 S!= "Vim "
      ${Continue}
    ${EndIf}

    # Verifies required sub-keys:
    ReadRegStr $R2 HKLM "${UNINST_REG_KEY}\$R1" "DisplayName"
    ${If} ${Errors}
    ${OrIf} $R2 == ""
      ${Continue}
    ${EndIf}

    ReadRegStr $R2 HKLM "${UNINST_REG_KEY}\$R1" "UninstallString"
    ${If} ${Errors}
    ${OrIf} $R2 == ""
      ${Continue}
    ${EndIf}

    # Found
    Push $R2
    call GetParent
    call GetParent
    Pop $0   # Vim directory
    ${ExitDo}

  ${Loop}

  ${If} ${RunningX64}
    SetRegView lastused
  ${EndIf}

  Pop $R2
  Pop $R1
  Pop $R0
  Exch $0  # put $0 on top of stack, restore $0 to original value
FunctionEnd

##########################################################
Section "$(str_section_old_ver)" id_section_old_ver
	SectionIn 1 2 3 RO

	# run the install program to check for already installed versions
	SetOutPath $TEMP
	File /oname=install.exe ${VIMSRC}\installw32.exe
	nsExec::Exec "$TEMP\install.exe -uninstall-check"
	Pop $3
	Delete $TEMP\install.exe
	Delete $TEMP\vimini.ini   # install.exe creates this, but we don't need it.

	# We may have been put to the background when uninstall did something.
	BringToFront
SectionEnd

##########################################################
Function .onInit
  # Check $VIM
  ReadEnvStr $INSTDIR "VIM"

  call CheckOldVim
  Pop $3
  ${If} $3 == ""
    # No old versions of Vim found. Unselect and hide the section.
    !insertmacro UnselectSection ${id_section_old_ver}
    SectionSetInstTypes ${id_section_old_ver} 0
    SectionSetText ${id_section_old_ver} ""
  ${Else}
    ${If} $INSTDIR == ""
      StrCpy $INSTDIR $3
    ${EndIf}
  ${EndIf}

  # If did not find a path: use the default dir.
  ${If} $INSTDIR == ""
    StrCpy $INSTDIR "$PROGRAMFILES\Vim"
  ${EndIf}

  # User variables:
  # $0 - holds the directory the executables are installed to
  # $1 - holds the parameters to be passed to install.exe.  Starts with OLE
  #      registration (since a non-OLE gvim will not complain, and we want to
  #      always register an OLE gvim).
  # $2 - holds the names to create batch files for
  StrCpy $0 "$INSTDIR\vim${VER_MAJOR}${VER_MINOR}"
  StrCpy $1 "-register-OLE"
  StrCpy $2 "gvim evim gview gvimdiff vimtutor"
FunctionEnd

Function .onInstSuccess
  WriteUninstaller vim${VER_MAJOR}${VER_MINOR}\uninstall-gui.exe
FunctionEnd

Function .onInstFailed
  MessageBox MB_OK|MB_ICONEXCLAMATION "Installation failed. Better luck next time."
FunctionEnd

##########################################################
Section "$(str_section_exe)" id_section_exe
	SectionIn 1 2 3 RO

	# we need also this here if the user changes the instdir
	StrCpy $0 "$INSTDIR\vim${VER_MAJOR}${VER_MINOR}"

	SetOutPath $0
	File /oname=gvim.exe ${VIMSRC}\gvim_ole.exe
	File /oname=install.exe ${VIMSRC}\installw32.exe
	File /oname=uninstal.exe ${VIMSRC}\uninstalw32.exe
	File ${VIMSRC}\vimrun.exe
	File /oname=tee.exe ${VIMSRC}\teew32.exe
	File /oname=xxd.exe ${VIMSRC}\xxdw32.exe
	File ${VIMRT}\vimtutor.bat
	File ${VIMRT}\README.txt
	File ..\uninstal.txt
	File ${VIMRT}\*.vim
	File ${VIMRT}\rgb.txt

	File ${VIMTOOLS}\diff.exe
	File ${VIMTOOLS}\winpty32.dll
	File ${VIMTOOLS}\winpty-agent.exe

	SetOutPath $0\colors
	File ${VIMRT}\colors\*.*

	SetOutPath $0\compiler
	File ${VIMRT}\compiler\*.*

	SetOutPath $0\doc
	File ${VIMRT}\doc\*.txt
	File ${VIMRT}\doc\tags

	SetOutPath $0\ftplugin
	File ${VIMRT}\ftplugin\*.*

	SetOutPath $0\indent
	File ${VIMRT}\indent\*.*

	SetOutPath $0\macros
	File ${VIMRT}\macros\*.*
	SetOutPath $0\macros\hanoi
	File ${VIMRT}\macros\hanoi\*.*
	SetOutPath $0\macros\life
	File ${VIMRT}\macros\life\*.*
	SetOutPath $0\macros\maze
	File ${VIMRT}\macros\maze\*.*
	SetOutPath $0\macros\urm
	File ${VIMRT}\macros\urm\*.*

	SetOutPath $0\pack\dist\opt\dvorak\dvorak
	File ${VIMRT}\pack\dist\opt\dvorak\dvorak\*.*
	SetOutPath $0\pack\dist\opt\dvorak\plugin
	File ${VIMRT}\pack\dist\opt\dvorak\plugin\*.*

	SetOutPath $0\pack\dist\opt\editexisting\plugin
	File ${VIMRT}\pack\dist\opt\editexisting\plugin\*.*

	SetOutPath $0\pack\dist\opt\justify\plugin
	File ${VIMRT}\pack\dist\opt\justify\plugin\*.*

	SetOutPath $0\pack\dist\opt\matchit\doc
	File ${VIMRT}\pack\dist\opt\matchit\doc\*.*
	SetOutPath $0\pack\dist\opt\matchit\plugin
	File ${VIMRT}\pack\dist\opt\matchit\plugin\*.*

	SetOutPath $0\pack\dist\opt\shellmenu\plugin
	File ${VIMRT}\pack\dist\opt\shellmenu\plugin\*.*

	SetOutPath $0\pack\dist\opt\swapmouse\plugin
	File ${VIMRT}\pack\dist\opt\swapmouse\plugin\*.*

	SetOutPath $0\pack\dist\opt\termdebug\plugin
	File ${VIMRT}\pack\dist\opt\termdebug\plugin\*.*

	SetOutPath $0\plugin
	File ${VIMRT}\plugin\*.*

	SetOutPath $0\autoload
	File ${VIMRT}\autoload\*.*

	SetOutPath $0\autoload\dist
	File ${VIMRT}\autoload\dist\*.*

	SetOutPath $0\autoload\xml
	File ${VIMRT}\autoload\xml\*.*

	SetOutPath $0\syntax
	File ${VIMRT}\syntax\*.*

	SetOutPath $0\spell
	File ${VIMRT}\spell\*.txt
	File ${VIMRT}\spell\*.vim
	File ${VIMRT}\spell\*.spl
	File ${VIMRT}\spell\*.sug

	SetOutPath $0\tools
	File ${VIMRT}\tools\*.*

	SetOutPath $0\tutor
	File ${VIMRT}\tutor\*.*
SectionEnd

##########################################################
Section "$(str_section_console)" id_section_console
	SectionIn 1 3

	SetOutPath $0
	File /oname=vim.exe ${VIMSRC}\vimw32.exe
	StrCpy $2 "$2 vim view vimdiff"
SectionEnd

##########################################################
Section "$(str_section_batch)" id_section_batch
	SectionIn 3

	StrCpy $1 "$1 -create-batfiles $2"
SectionEnd

##########################################################
SectionGroup $(str_group_icons) id_group_icons
	Section "$(str_section_desktop)" id_section_desktop
		SectionIn 1 3

		StrCpy $1 "$1 -install-icons"
	SectionEnd

	Section "$(str_section_start_menu)" id_section_startmenu
		SectionIn 1 3

		StrCpy $1 "$1 -add-start-menu"
	SectionEnd
SectionGroupEnd

##########################################################
Section "$(str_section_edit_with)" id_section_editwith
	SectionIn 1 3

	SetOutPath $0

	${If} ${RunningX64}
	  # Install 64-bit gvimext.dll into the GvimExt64 directory.
	  SetOutPath $0\GvimExt64
	  ClearErrors
	  !define LIBRARY_SHELL_EXTENSION
	  !define LIBRARY_X64
	  !insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "${VIMSRC}\GvimExt\gvimext64.dll" \
	      "$0\GvimExt64\gvimext.dll" "$0"
	  !undef LIBRARY_X64
	  !undef LIBRARY_SHELL_EXTENSION
	${EndIf}

	# Install 32-bit gvimext.dll into the GvimExt32 directory.
	SetOutPath $0\GvimExt32
	ClearErrors
	!define LIBRARY_SHELL_EXTENSION
	!insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	    "${VIMSRC}\GvimExt\gvimext.dll" \
	    "$0\GvimExt32\gvimext.dll" "$0"
	!undef LIBRARY_SHELL_EXTENSION

	# We don't have a separate entry for the "Open With..." menu, assume
	# the user wants either both or none.
	StrCpy $1 "$1 -install-popup -install-openwith"
SectionEnd

##########################################################
Section "$(str_section_vim_rc)" id_section_vimrc
	SectionIn 1 3

	StrCpy $1 "$1 -create-vimrc"

	${If} ${RunningX64}
	  SetRegView 64
	${EndIf}
	WriteRegStr HKLM "${UNINST_REG_KEY_VIM}" "keyremap" "$vim_keymap_stat"
	WriteRegStr HKLM "${UNINST_REG_KEY_VIM}" "mouse" "$vim_mouse_stat"
	${If} ${RunningX64}
	  SetRegView lastused
	${EndIf}

	${If} $vim_keymap_stat == "default"
	  StrCpy $1 "$1 -vimrc-remap no"
	${Else}
	  StrCpy $1 "$1 -vimrc-remap win"
	${EndIf}

	${If} $vim_mouse_stat == "default"
	  StrCpy $1 "$1 -vimrc-behave default"
	${ElseIf} $vim_mouse_stat == "windows"
	  StrCpy $1 "$1 -vimrc-behave mswin"
	${Else}
	  StrCpy $1 "$1 -vimrc-behave unix"
	${EndIf}

SectionEnd

##########################################################
SectionGroup $(str_group_plugin) id_group_plugin
	Section "$(str_section_plugin_home)" id_section_pluginhome
		SectionIn 1 3

		StrCpy $1 "$1 -create-directories home"
	SectionEnd

	Section "$(str_section_plugin_vim)" id_section_pluginvim
		SectionIn 3

		StrCpy $1 "$1 -create-directories vim"
	SectionEnd
SectionGroupEnd

##########################################################
!ifdef HAVE_VIS_VIM
Section "$(str_section_vis_vim)" id_section_visvim
	SectionIn 3

	SetOutPath $0
	!insertmacro UpgradeDLL "${VIMSRC}\VisVim\VisVim.dll" "$0\VisVim.dll" "$0"
	File ${VIMSRC}\VisVim\README_VisVim.txt
SectionEnd
!endif

##########################################################
!ifdef HAVE_NLS
Section "$(str_section_nls)" id_section_nls
	SectionIn 1 3

	SetOutPath $0\lang
	File /r ${VIMRT}\lang\*.*
	SetOutPath $0\keymap
	File ${VIMRT}\keymap\README.txt
	File ${VIMRT}\keymap\*.vim
	SetOutPath $0
	!insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	    "${GETTEXT}\gettext32\libintl-8.dll" \
	    "$0\libintl-8.dll" "$0"
	!insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	    "${GETTEXT}\gettext32\libiconv-2.dll" \
	    "$0\libiconv-2.dll" "$0"
  !if /FileExists "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll"
	# Install libgcc_s_sjlj-1.dll only if it is needed.
	!insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	    "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll" \
	    "$0\libgcc_s_sjlj-1.dll" "$0"
  !endif

	${If} ${SectionIsSelected} ${id_section_editwith}
	  ${If} ${RunningX64}
	    # Install DLLs for 64-bit gvimext.dll into the GvimExt64 directory.
	    SetOutPath $0\GvimExt64
	    ClearErrors
	    !define LIBRARY_X64
	    !insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
		"${GETTEXT}\gettext64\libintl-8.dll" \
		"$0\GvimExt64\libintl-8.dll" "$0\GvimExt64"
	    !insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
		"${GETTEXT}\gettext64\libiconv-2.dll" \
		"$0\GvimExt64\libiconv-2.dll" "$0\GvimExt64"
	    !undef LIBRARY_X64
	  ${EndIf}

	  # Install DLLs for 32-bit gvimext.dll into the GvimExt32 directory.
	  SetOutPath $0\GvimExt32
	  ClearErrors
	  !insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "${GETTEXT}\gettext32\libintl-8.dll" \
	      "$0\GvimExt32\libintl-8.dll" "$0\GvimExt32"
	  !insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "${GETTEXT}\gettext32\libiconv-2.dll" \
	      "$0\GvimExt32\libiconv-2.dll" "$0\GvimExt32"
  !if /FileExists "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll"
	  # Install libgcc_s_sjlj-1.dll only if it is needed.
	  !insertmacro InstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll" \
	      "$0\GvimExt32\libgcc_s_sjlj-1.dll" "$0\GvimExt32"
  !endif
	${EndIf}
SectionEnd
!endif

##########################################################
Section -call_install_exe
	SetOutPath $0
	nsExec::Exec "$0\install.exe $1"
	Pop $3
SectionEnd

##########################################################
Section -post

	# Get estimated install size
	SectionGetSize ${id_section_exe} $3
	${If} ${SectionIsSelected} ${id_section_console}
	  SectionGetSize ${id_section_console} $4
	  IntOp $3 $3 + $4
	${EndIf}
	${If} ${SectionIsSelected} ${id_section_editwith}
	  SectionGetSize ${id_section_editwith} $4
	  IntOp $3 $3 + $4
	${EndIf}
!ifdef HAVE_VIS_VIM
	${If} ${SectionIsSelected} ${id_section_visvim}
	  SectionGetSize ${id_section_visvim} $4
	  IntOp $3 $3 + $4
	${EndIf}
!endif
!ifdef HAVE_NLS
	${If} ${SectionIsSelected} ${id_section_nls}
	  SectionGetSize ${id_section_nls} $4
	  IntOp $3 $3 + $4
	${EndIf}
!endif

	# Register EstimatedSize.
	# Other information will be set by the install.exe (dosinst.c).
	${If} ${RunningX64}
	  SetRegView 64
	${EndIf}
	WriteRegDWORD HKLM "${UNINST_REG_KEY_VIM}" "EstimatedSize" $3
	${If} ${RunningX64}
	  SetRegView lastused
	${EndIf}

	BringToFront
SectionEnd

##########################################################
Function SetCustom
	# Display the _vimrc setting dialog using nsDialogs.

	# Check if a _vimrc should be created
	${IfNot} ${SectionIsSelected} ${id_section_vimrc}
	  Abort
	${EndIf}

	!insertmacro MUI_HEADER_TEXT \
	    $(str_vimrc_page_title) $(str_vimrc_page_subtitle)

	nsDialogs::Create 1018
	Pop $vim_dialog

	${If} $vim_dialog == error
	  Abort
	${EndIf}

	${If} ${RunningX64}
	  SetRegView 64
	${EndIf}

	GetFunctionAddress $3 ValidateCustom
	nsDialogs::OnBack $3

	# 1st group - Key remapping
	${NSD_CreateGroupBox} 0 0 100% 38% $(str_msg_keymap_title)
	Pop $3

	${NSD_CreateRadioButton} 5% 8% 90% 8% $(str_msg_keymap_default)
	Pop $vim_nsd_keymap_1
	${NSD_AddStyle} $vim_nsd_keymap_1 ${WS_GROUP}

	${NSD_CreateRadioButton} 5% 18% 90% 16% $(str_msg_keymap_windows)
	Pop $vim_nsd_keymap_2

	${If} $vim_keymap_stat == ""
	  ReadRegStr $3 HKLM "${UNINST_REG_KEY_VIM}" "keyremap"
	${Else}
	  StrCpy $3 $vim_keymap_stat
	${EndIf}
	${If} $3 == "windows"
	  ${NSD_SetState} $vim_nsd_keymap_2 ${BST_CHECKED}
	${Else} # default
	  ${NSD_SetState} $vim_nsd_keymap_1 ${BST_CHECKED}
	${EndIf}


	# 2nd group - Mouse behavior
	${NSD_CreateGroupBox} 0 42% 100% 58% $(str_msg_mouse_title)
	Pop $3

	${NSD_CreateRadioButton} 5% 48% 90% 16% $(str_msg_mouse_default)
	Pop $vim_nsd_mouse_1
	${NSD_AddStyle} $vim_nsd_mouse_1 ${WS_GROUP}

	${NSD_CreateRadioButton} 5% 65% 90% 16% $(str_msg_mouse_windows)
	Pop $vim_nsd_mouse_2

	${NSD_CreateRadioButton} 5% 81% 90% 16% $(str_msg_mouse_unix)
	Pop $vim_nsd_mouse_3

	${If} $vim_mouse_stat == ""
	  ReadRegStr $3 HKLM "${UNINST_REG_KEY_VIM}" "mouse"
	${Else}
	  StrCpy $3 $vim_mouse_stat
	${EndIf}
	${If} $3 == "xterm"
	  ${NSD_SetState} $vim_nsd_mouse_3 ${BST_CHECKED}
	${ElseIf} $3 == "windows"
	  ${NSD_SetState} $vim_nsd_mouse_2 ${BST_CHECKED}
	${Else} # defualt
	  ${NSD_SetState} $vim_nsd_mouse_1 ${BST_CHECKED}
	${EndIf}

	${If} ${RunningX64}
	  SetRegView lastused
	${EndIf}

	nsDialogs::Show
FunctionEnd

Function ValidateCustom
	${NSD_GetState} $vim_nsd_keymap_1 $3
	${If} $3 == ${BST_CHECKED}
	  StrCpy $vim_keymap_stat "default"
	${Else}
	  StrCpy $vim_keymap_stat "windows"
	${EndIf}

	${NSD_GetState} $vim_nsd_mouse_1 $3
	${If} $3 == ${BST_CHECKED}
	  StrCpy $vim_mouse_stat "default"
	${Else}
	  ${NSD_GetState} $vim_nsd_mouse_2 $3
	  ${If} $3 == ${BST_CHECKED}
	    StrCpy $vim_mouse_stat "windows"
	  ${Else}
	    StrCpy $vim_mouse_stat "xterm"
	  ${EndIf}
	${EndIf}
FunctionEnd

##########################################################
# Description for Installer Sections

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_old_ver}     $(str_desc_old_ver)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_exe}         $(str_desc_exe)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_console}     $(str_desc_console)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_batch}       $(str_desc_batch)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_group_icons}         $(str_desc_icons)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_desktop}     $(str_desc_desktop)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_startmenu}   $(str_desc_start_menu)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_editwith}    $(str_desc_edit_with)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_vimrc}       $(str_desc_vim_rc)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_group_plugin}        $(str_desc_plugin)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_pluginhome}  $(str_desc_plugin_home)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_pluginvim}   $(str_desc_plugin_vim)
!ifdef HAVE_VIS_VIM
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_visvim}      $(str_desc_vis_vim)
!endif
!ifdef HAVE_NLS
    !insertmacro MUI_DESCRIPTION_TEXT ${id_section_nls}         $(str_desc_nls)
!endif
!insertmacro MUI_FUNCTION_DESCRIPTION_END


##########################################################
Section "un.$(str_unsection_register)" id_unsection_register
	SectionIn RO

	# Apparently $INSTDIR is set to the directory where the uninstaller is
	# created.  Thus the "vim61" directory is included in it.
	StrCpy $0 "$INSTDIR"

!ifdef HAVE_VIS_VIM
	# If VisVim was installed, unregister the DLL.
	${If} ${FileExists} "$0\VisVim.dll"
	  ExecWait "regsvr32.exe /u /s $0\VisVim.dll"
	${EndIf}
!endif

	# delete the context menu entry and batch files
	nsExec::Exec "$0\uninstal.exe -nsis"
	Pop $3

	# We may have been put to the background when uninstall did something.
	BringToFront
SectionEnd

Section "un.$(str_unsection_exe)" id_unsection_exe

	StrCpy $0 "$INSTDIR"

	Delete /REBOOTOK $0\*.dll

	# Delete 64-bit GvimExt
	${If} ${RunningX64}
	  !define LIBRARY_X64
	  ${If} ${FileExists} "$0\GvimExt64\gvimext.dll"
	    !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
		"$0\GvimExt64\gvimext.dll"
	  ${EndIf}
	  ${If} ${FileExists} "$0\GvimExt64\libiconv-2.dll"
	    !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
		"$0\GvimExt64\libiconv-2.dll"
	  ${EndIf}
	  ${If} ${FileExists} "$0\GvimExt64\libintl-8.dll"
	    !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
		"$0\GvimExt64\libintl-8.dll"
	  ${EndIf}
	  ${If} ${FileExists} "$0\GvimExt64\libwinpthread-1.dll"
	    !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
		"$0\GvimExt64\libwinpthread-1.dll"
	  ${EndIf}
	  !undef LIBRARY_X64
	${EndIf}

	# Delete 32-bit GvimExt
	${If} ${FileExists} "$0\GvimExt32\gvimext.dll"
	  !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "$0\GvimExt32\gvimext.dll"
	${EndIf}
	${If} ${FileExists} "$0\GvimExt32\libiconv-2.dll"
	  !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "$0\GvimExt32\libiconv-2.dll"
	${EndIf}
	${If} ${FileExists} "$0\GvimExt32\libintl-8.dll"
	  !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "$0\GvimExt32\libintl-8.dll"
	${EndIf}
	${If} ${FileExists} "$0\GvimExt32\libgcc_s_sjlj-1.dll"
	  !insertmacro UninstallLib DLL NOTSHARED REBOOT_NOTPROTECTED \
	      "$0\GvimExt32\libgcc_s_sjlj-1.dll"
	${EndIf}

	ClearErrors
	# Remove everything but *.dll files.  Avoids that
	# a lot remains when gvimext.dll cannot be deleted.
	RMDir /r $0\autoload
	RMDir /r $0\colors
	RMDir /r $0\compiler
	RMDir /r $0\doc
	RMDir /r $0\ftplugin
	RMDir /r $0\indent
	RMDir /r $0\macros
	RMDir /r $0\plugin
	RMDir /r $0\spell
	RMDir /r $0\syntax
	RMDir /r $0\tools
	RMDir /r $0\tutor
!ifdef HAVE_VIS_VIM
	RMDir /r $0\VisVim
!endif
	RMDir /r $0\lang
	RMDir /r $0\keymap
	Delete $0\*.exe
	Delete $0\*.bat
	Delete $0\*.vim
	Delete $0\*.txt

	${If} ${Errors}
	  MessageBox MB_OK|MB_ICONEXCLAMATION \
	      "Some files in $0 have not been deleted!$\nYou must do it manually."
	${EndIf}

	# No error message if the "vim62" directory can't be removed, the
	# gvimext.dll may still be there.
	RMDir $0
SectionEnd

Section "un.$(str_unsection_vimfiles)" id_unsection_vimfiles
	# get the parent dir of the installation
	Push $INSTDIR
	Call un.GetParent
	Pop $1

	# if a plugin dir was created at installation ask the user to remove it
	# first look in the root of the installation then in HOME
	${IfNot} ${FileExists} $1\vimfiles
	  ReadEnvStr $1 "HOME"
	${EndIf}

	${If} $1 != ""
	${AndIf} ${FileExists} $1\vimfiles
	  RMDir /r $1\vimfiles
	${EndIf}
SectionEnd

Section "un.$(str_unsection_rootdir)" id_unsection_rootdir
	# get the parent dir of the installation
	Push $INSTDIR
	Call un.GetParent
	Pop $0

	RMDir /r $0
SectionEnd

##########################################################
# Description for Uninstaller Sections

!insertmacro MUI_UNFUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${id_unsection_register} $(str_desc_unregister)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_unsection_exe}      $(str_desc_rm_exe)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_unsection_vimfiles} $(str_desc_rm_vimfiles)
    !insertmacro MUI_DESCRIPTION_TEXT ${id_unsection_rootdir}  $(str_desc_rm_rootdir)
!insertmacro MUI_UNFUNCTION_DESCRIPTION_END
