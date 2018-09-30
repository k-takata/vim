# NSIS file to create a self-installing exe for Vim.
# It requires NSIS version 2.0 or later.
# Last Change:	2014 Nov 5

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

# comment the next line if you do not want to add Native Language Support
!define HAVE_NLS

!include gvim_version.nsh	# for version number

# ----------- No configurable settings below this line -----------

!include UpgradeDLL.nsh		# for VisVim.dll
!include LogicLib.nsh
!include x64.nsh

!define PRODUCT		"Vim ${VER_MAJOR}.${VER_MINOR}"
!define UNINST_REG_KEY	"Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}"

Name "${PRODUCT}"
OutFile gvim${VER_MAJOR}${VER_MINOR}.exe
CRCCheck force
SetCompressor /SOLID lzma
SetDatablockOptimize on
RequestExecutionLevel highest
XPStyle on

ComponentText "This will install Vim ${VER_MAJOR}.${VER_MINOR} on your computer."
DirText "Choose a directory to install Vim (should contain 'vim')"
Icon icons\vim_16c.ico
# NSIS2 uses a different strategy with six different images in a strip...
#EnabledBitmap icons\enabled.bmp
#DisabledBitmap icons\disabled.bmp
UninstallText "This will uninstall Vim ${VER_MAJOR}.${VER_MINOR} from your system."
UninstallIcon icons\vim_uninst_16c.ico

# On NSIS 2 using the BGGradient causes trouble on Windows 98, in combination
# with the BringToFront.
# BGGradient 004000 008200 FFFFFF
LicenseText "You should read the following before installing:"
LicenseData ${VIMRT}\doc\uganda.nsis.txt

!ifdef HAVE_UPX
  !packhdr temp.dat "upx --best --compress-icons=1 temp.dat"
!endif

# This adds '\vim' to the user choice automagically.  The actual value is
# obtained below with ReadINIStr.
InstallDir "$PROGRAMFILES\Vim"

# Types of installs we can perform:
InstType Typical
InstType Minimal
InstType Full

SilentInstall normal

# These are the pages we use
Page license
Page components
Page custom SetCustom ValidateCustom ": _vimrc setting"
Page directory "" "" CheckInstallDir
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

# Reserve files
# Needed for showing the _vimrc setting page faster.
ReserveFile /plugin InstallOptions.dll
ReserveFile vimrc.ini

##########################################################
# Functions

Function .onInit
  MessageBox MB_YESNO|MB_ICONQUESTION \
	"This will install Vim ${VER_MAJOR}.${VER_MINOR} on your computer.$\n Continue?" \
	/SD IDYES \
	IDYES NoAbort
	    Abort ; causes installer to quit.
	NoAbort:

  # run the install program to check for already installed versions
  SetOutPath $TEMP
  File /oname=install.exe ${VIMSRC}\installw32.exe
  ExecWait "$TEMP\install.exe -uninstall-check"
  Delete $TEMP\install.exe

  # We may have been put to the background when uninstall did something.
  BringToFront

  # Install will have created a file for us that contains the directory where
  # we should install.  This is $VIM if it's set.  This appears to be the only
  # way to get the value of $VIM here!?
  ReadINIStr $INSTDIR $TEMP\vimini.ini vimini dir
  Delete $TEMP\vimini.ini

  # If ReadINIStr failed or did not find a path: use the default dir.
  ${If} $INSTDIR == ""
    StrCpy $INSTDIR "$PROGRAMFILES\Vim"
  ${EndIf}

  # Should check for the value of $VIM and use it.  Unfortunately I don't know
  # how to obtain the value of $VIM
  # IfFileExists "$VIM" 0 No_Vim
  #   StrCpy $INSTDIR "$VIM"
  # No_Vim:

  # User variables:
  # $0 - holds the directory the executables are installed to
  # $1 - holds the parameters to be passed to install.exe.  Starts with OLE
  #      registration (since a non-OLE gvim will not complain, and we want to
  #      always register an OLE gvim).
  # $2 - holds the names to create batch files for
  StrCpy $0 "$INSTDIR\vim${VER_MAJOR}${VER_MINOR}"
  StrCpy $1 "-register-OLE"
  StrCpy $2 "gvim evim gview gvimdiff vimtutor"

  # Extract InstallOptions files
  # $PLUGINSDIR will automatically be removed when the installer closes
  InitPluginsDir
  File /oname=$PLUGINSDIR\vimrc.ini "vimrc.ini"
FunctionEnd

Function .onUserAbort
  MessageBox MB_YESNO|MB_ICONQUESTION "Abort install?" IDYES NoCancelAbort
    Abort ; causes installer to not quit.
  NoCancelAbort:
FunctionEnd

# We only accept the directory if it ends in "vim".  Using .onVerifyInstDir has
# the disadvantage that the browse dialog is difficult to use.
Function CheckInstallDir
FunctionEnd

Function .onInstSuccess
  WriteUninstaller vim${VER_MAJOR}${VER_MINOR}\uninstall-gui.exe
  MessageBox MB_YESNO|MB_ICONQUESTION \
	"The installation process has been successful. Happy Vimming! \
	$\n$\n Do you want to see the README file now?" IDNO NoReadme
      Exec '$0\gvim.exe -R "$0\README.txt"'
  NoReadme:
FunctionEnd

Function .onInstFailed
  MessageBox MB_OK|MB_ICONEXCLAMATION "Installation failed. Better luck next time."
FunctionEnd

Function un.onUnInstSuccess
  MessageBox MB_OK|MB_ICONINFORMATION \
  "Vim ${VER_MAJOR}.${VER_MINOR} has been (partly) removed from your system"
FunctionEnd

Function un.GetParent
  Exch $0 ; old $0 is on top of stack
  Push $1
  Push $2
  StrCpy $1 -1
  loop:
    StrCpy $2 $0 1 $1
    StrCmp $2 "" exit
    StrCmp $2 "\" exit
    IntOp $1 $1 - 1
  Goto loop
  exit:
    StrCpy $0 $0 $1
    Pop $2
    Pop $1
    Exch $0 ; put $0 on top of stack, restore $0 to original value
FunctionEnd

##########################################################
Section "Vim executables and runtime files" sec_main_id
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
Section "Vim console program (vim.exe)" sec_cons_id
	SectionIn 1 3

	SetOutPath $0
	File /oname=vim.exe ${VIMSRC}\vimw32.exe
	StrCpy $2 "$2 vim view vimdiff"
SectionEnd

##########################################################
Section "Create .bat files for command line use"
	SectionIn 3

	StrCpy $1 "$1 -create-batfiles $2"
SectionEnd

##########################################################
Section "Create icons on the Desktop"
	SectionIn 1 3

	StrCpy $1 "$1 -install-icons"
SectionEnd

##########################################################
Section "Add Vim to the Start Menu"
	SectionIn 1 3

	StrCpy $1 "$1 -add-start-menu"
SectionEnd

##########################################################
Section "Add an Edit-with-Vim context menu entry" sec_gvimext_id
	SectionIn 1 3

	# Be aware of this sequence of events:
	# - user uninstalls Vim, gvimext.dll can't be removed (it's in use) and
	#   is scheduled to be removed at next reboot.
	# - user installs Vim in same directory, gvimext.dll still exists.
	# If we now skip installing gvimext.dll, it will disappear at the next
	# reboot.  Thus when copying gvimext.dll fails always schedule it to be
	# installed at the next reboot.  Can't use UpgradeDLL!
	# We don't ask the user to reboot, the old dll will keep on working.
	SetOutPath $0
	ClearErrors
	SetOverwrite try

	${If} ${RunningX64}
	  # Install 64-bit gvimext.dll into the GvimExt64 directory.
	  SetOutPath $0\GvimExt64
	  ClearErrors
	  File /oname=gvimext.dll ${VIMSRC}\GvimExt\gvimext64.dll

	  ${If} ${Errors}
	    # Can't copy gvimext.dll, create it under another name and rename it
	    # on next reboot.
	    GetTempFileName $3 $0\GvimExt64
	    File /oname=$3 ${VIMSRC}\GvimExt\gvimext64.dll
	    Rename /REBOOTOK $3 $0\GvimExt64\gvimext.dll
	  ${EndIf}
	${EndIf}

	# Install 32-bit gvimext.dll into the GvimExt32 directory.
	SetOutPath $0\GvimExt32
	ClearErrors
	File /oname=gvimext.dll ${VIMSRC}\GvimExt\gvimext.dll

	${If} ${Errors}
	  # Can't copy gvimext.dll, create it under another name and rename it
	  # on next reboot.
	  GetTempFileName $3 $0\GvimExt32
	  File /oname=$3 ${VIMSRC}\GvimExt\gvimext.dll
	  Rename /REBOOTOK $3 $0\GvimExt32\gvimext.dll
	${EndIf}
	SetOverwrite lastused

	# We don't have a separate entry for the "Open With..." menu, assume
	# the user wants either both or none.
	StrCpy $1 "$1 -install-popup -install-openwith"
SectionEnd

##########################################################
Section "Create a _vimrc if it doesn't exist" sec_vimrc_id
	SectionIn 1 3

	StrCpy $1 "$1 -create-vimrc"
SectionEnd

##########################################################
Section "Create plugin directories in HOME or VIM"
	SectionIn 1 3

	StrCpy $1 "$1 -create-directories home"
SectionEnd

##########################################################
Section "Create plugin directories in VIM"
	SectionIn 3

	StrCpy $1 "$1 -create-directories vim"
SectionEnd

##########################################################
Section "VisVim Extension for MS Visual Studio" sec_visvim_id
	SectionIn 3

	SetOutPath $0
	!insertmacro UpgradeDLL "${VIMSRC}\VisVim\VisVim.dll" "$0\VisVim.dll" "$0"
	File ${VIMSRC}\VisVim\README_VisVim.txt
SectionEnd

##########################################################
!ifdef HAVE_NLS
Section "Native Language Support" sec_nls_id
	SectionIn 1 3

	SetOutPath $0\lang
	File /r ${VIMRT}\lang\*.*
	SetOutPath $0\keymap
	File ${VIMRT}\keymap\README.txt
	File ${VIMRT}\keymap\*.vim
	SetOutPath $0
	File ${GETTEXT}\gettext32\libintl-8.dll
	File ${GETTEXT}\gettext32\libiconv-2.dll
	#File /nonfatal ${VIMRT}\libwinpthread-1.dll
  !if /FileExists "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll"
	# Install libgcc_s_sjlj-1.dll only if it is needed.
	File ${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll
  !endif

	${If} ${SectionIsSelected} ${sec_gvimext_id}
	  SetOverwrite try

	  ${If} ${RunningX64}
	    # Install DLLs for 64-bit gvimext.dll into the GvimExt64 directory.
	    SetOutPath $0\GvimExt64
	    ClearErrors
	    File ${GETTEXT}\gettext64\libintl-8.dll
	    File ${GETTEXT}\gettext64\libiconv-2.dll

	    ${If} ${Errors}
	      # Can't copy the DLLs, create it under another name and rename it
	      # on next reboot.
	      GetTempFileName $3 $0\GvimExt64
	      File /oname=$3 ${GETTEXT}\gettext64\libintl-8.dll
	      Rename /REBOOTOK $3 $0\GvimExt64\libintl-8.dll
	      GetTempFileName $3 $0\GvimExt64
	      File /oname=$3 ${GETTEXT}\gettext64\libiconv-2.dll
	      Rename /REBOOTOK $3 $0\GvimExt64\libiconv-2.dll
	    ${EndIf}
	  ${EndIf}

	  # Install DLLs for 32-bit gvimext.dll into the GvimExt32 directory.
	  SetOutPath $0\GvimExt32
	  ClearErrors
	  File ${GETTEXT}\gettext32\libintl-8.dll
	  File ${GETTEXT}\gettext32\libiconv-2.dll
  !if /FileExists "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll"
	  # Install libgcc_s_sjlj-1.dll only if it is needed.
	  File ${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll
  !endif

	  ${If} ${Errors}
	    # Can't copy the DLLs, create it under another name and rename it
	    # on next reboot.
	    GetTempFileName $3 $0\GvimExt32
	    File /oname=$3 ${GETTEXT}\gettext32\libintl-8.dll
	    Rename /REBOOTOK $3 $0\GvimExt32\libintl-8.dll
	    GetTempFileName $3 $0\GvimExt32
	    File /oname=$3 ${GETTEXT}\gettext32\libiconv-2.dll
	    Rename /REBOOTOK $3 $0\GvimExt32\libiconv-2.dll
  !if /FileExists "${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll"
	    # Install libgcc_s_sjlj-1.dll only if it is needed.
	    GetTempFileName $3 $0\GvimExt32
	    File /oname=$3 ${GETTEXT}\gettext32\libgcc_s_sjlj-1.dll
	    Rename /REBOOTOK $3 $0\GvimExt32\libgcc_s_sjlj-1.dll
  !endif
	  ${EndIf}

	  SetOverwrite lastused
	${EndIf}
SectionEnd
!endif

##########################################################
Section -call_install_exe
	SetOutPath $0
	ExecWait "$0\install.exe $1"
SectionEnd

##########################################################
Section -post

	# Get estimated install size
	SectionGetSize ${sec_main_id} $3
	${If} ${SectionIsSelected} ${sec_cons_id}
	  SectionGetSize ${sec_cons_id} $4
	  IntOp $3 $3 + $4
	${EndIf}
	${If} ${SectionIsSelected} ${sec_gvimext_id}
	  SectionGetSize ${sec_gvimext_id} $4
	  IntOp $3 $3 + $4
	${EndIf}
	${If} ${SectionIsSelected} ${sec_visvim_id}
	  SectionGetSize ${sec_visvim_id} $4
	  IntOp $3 $3 + $4
	${EndIf}
	${If} ${SectionIsSelected} ${sec_nls_id}
	  SectionGetSize ${sec_nls_id} $4
	  IntOp $3 $3 + $4
	${EndIf}

	# Register EstimatedSize.
	# Other information will be set by the install.exe.
	${If} ${RunningX64}
	  SetRegView 64
	${EndIf}
	WriteRegDWORD HKLM "${UNINST_REG_KEY}" "EstimatedSize" $3
	${If} ${RunningX64}
	  SetRegView lastused
	${EndIf}

	BringToFront
SectionEnd

##########################################################
Function SetCustom
	# Display the InstallOptions dialog

	# Check if a _vimrc should be created
	${IfNot} ${SectionIsSelected} ${sec_vimrc_id}
	  Abort
	${EndIf}

	InstallOptions::dialog "$PLUGINSDIR\vimrc.ini"
	Pop $3
FunctionEnd

Function ValidateCustom
	ReadINIStr $3 "$PLUGINSDIR\vimrc.ini" "Field 2" "State"
	${If} $3 == "1"
	  StrCpy $1 "$1 -vimrc-remap no"
	${Else}
	  StrCpy $1 "$1 -vimrc-remap win"
	${EndIf}

	ReadINIStr $3 "$PLUGINSDIR\vimrc.ini" "Field 5" "State"
	${If} $3 == "1"
	  StrCpy $1 "$1 -vimrc-behave unix"
	${Else}
	  ReadINIStr $3 "$PLUGINSDIR\vimrc.ini" "Field 6" "State"
	  ${If} $3 == "1"
	    StrCpy $1 "$1 -vimrc-behave mswin"
	  ${Else}
	    StrCpy $1 "$1 -vimrc-behave default"
	  ${EndIf}
	${EndIf}
FunctionEnd

##########################################################
Section Uninstall
	# Apparently $INSTDIR is set to the directory where the uninstaller is
	# created.  Thus the "vim61" directory is included in it.
	StrCpy $0 "$INSTDIR"

	# If VisVim was installed, unregister the DLL.
	${If} ${FileExists} "$0\VisVim.dll"
	  ExecWait "regsvr32.exe /u /s $0\VisVim.dll"
	${EndIf}

	# delete the context menu entry and batch files
	ExecWait "$0\uninstal.exe -nsis"

	# We may have been put to the background when uninstall did something.
	BringToFront

	# ask the user if the Vim version dir must be removed
	MessageBox MB_YESNO|MB_ICONQUESTION \
	  "Would you like to delete $0?$\n \
	   $\nIt contains the Vim executables and runtime files." IDNO NoRemoveExes

	Delete /REBOOTOK $0\*.dll
	Delete /REBOOTOK $0\GvimExt32\*.dll
	${If} ${RunningX64}
	  Delete /REBOOTOK $0\GvimExt64\*.dll
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
	RMDir /r $0\VisVim
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

	NoRemoveExes:
	# get the parent dir of the installation
	Push $INSTDIR
	Call un.GetParent
	Pop $0
	StrCpy $1 $0

	# if a plugin dir was created at installation ask the user to remove it
	# first look in the root of the installation then in HOME
	${IfNot} ${FileExists} $1\vimfiles
	  ReadEnvStr $1 "HOME"
	${EndIf}

	${If} $1 != ""
	${AndIf} ${FileExists} $1\vimfiles
	  MessageBox MB_YESNO|MB_ICONQUESTION \
	    "Remove all files in your $1\vimfiles directory?$\n \
	    $\nCAREFUL: If you have created something there that you want to keep, click No" IDNO Fin
	  RMDir /r $1\vimfiles
	${EndIf}

	# ask the user if the Vim root dir must be removed
	MessageBox MB_YESNO|MB_ICONQUESTION \
	  "Would you like to remove $0?$\n \
	   $\nIt contains your Vim configuration files!" IDNO NoDelete
	   RMDir /r $0 ; skipped if no
	NoDelete:

	Fin:
	Call un.onUnInstSuccess

SectionEnd
