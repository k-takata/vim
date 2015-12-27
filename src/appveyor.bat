@echo off
:: Batch file for building/testing Vim on AppVeyor

if /I "%1"=="" (
  set target=build
) else (
  set target=%1
)
goto %target%_%ARCH%
echo Unknown build target.
exit 1


:install_x86
:: ----------------------------------------------------------------------
@echo on
:: Work around for Python 2.7.11
reg copy HKLM\SOFTWARE\Python\PythonCore\2.7 HKLM\SOFTWARE\Python\PythonCore\2.7-32 /s /reg:32
:: Lua
curl -L "http://downloads.sourceforge.net/project/luabinaries/5.3.2/Windows%%20Libraries/Dynamic/lua-5.3.2_Win32_dllw4_lib.zip" -o lua.zip
7z x lua.zip -oC:\Lua
:: Perl
appveyor DownloadFile http://downloads.activestate.com/ActivePerl/releases/5.22.0.2200/ActivePerl-5.22.0.2200-MSWin32-x86-64int-299195.msi -F perl.msi
msiexec /i /quiet perl.msi TARGETDIR=C:\Perl522
:: Tcl
appveyor DownloadFile http://downloads.activestate.com/ActiveTcl/releases/8.6.4.1/ActiveTcl8.6.4.1.299124-win32-ix86-threaded.exe -F tcl.exe
start /wait tcl.exe --directory C:\Tcl

@echo off
goto :eof

:install_x64
:: ----------------------------------------------------------------------
@echo on
:: Work around for Python 2.7.11
reg copy HKLM\SOFTWARE\Python\PythonCore\2.7 HKLM\SOFTWARE\Python\PythonCore\2.7-32 /s /reg:64
:: Lua
curl -L "http://downloads.sourceforge.net/project/luabinaries/5.3.2/Windows%%20Libraries/Dynamic/lua-5.3.2_Win64_dllw4_lib.zip" -o lua.zip
7z x lua.zip -oC:\Lua
:: Perl
appveyor DownloadFile http://downloads.activestate.com/ActivePerl/releases/5.22.0.2200/ActivePerl-5.22.0.2200-MSWin32-x64-299195.msi -F perl.msi
msiexec /i /quiet perl.msi TARGETDIR=C:\Perl522
:: Tcl
appveyor DownloadFile http://downloads.activestate.com/ActiveTcl/releases/8.6.4.1/ActiveTcl8.6.4.1.299124-win32-x86_64-threaded.exe -F tcl.exe
start /wait tcl.exe --directory C:\Tcl

@echo off
goto :eof


:build_x86
:: ----------------------------------------------------------------------
@echo on
:: Remove progress bar from the build log
sed -e "s/\$(LINKARGS2)/\$(LINKARGS2) | sed -e 's#.*\\\\r.*##'/" Make_mvc.mak > Make_mvc2.mak
:: Build GUI version
nmake -f Make_mvc2.mak CPU=i386 ^
	GUI=yes OLE=no DIRECTX=yes ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PERL_VER=522 DYNAMIC_PERL=yes PERL=C:\Perl522 ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34 ^
	LUA_VER=53 DYNAMIC_LUA=yes LUA=C:\Lua ^
	TCL_VER=86 DYNAMIC_TCL=yes TCL=C:\Tcl ^
	WINVER=0x500
:: Build CUI version
nmake -f Make_mvc2.mak CPU=i386 ^
	GUI=no OLE=no DIRECTX=no ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PERL_VER=522 DYNAMIC_PERL=yes PERL=C:\Perl522 ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34 ^
	LUA_VER=53 DYNAMIC_LUA=yes LUA=C:\Lua ^
	TCL_VER=86 DYNAMIC_TCL=yes TCL=C:\Tcl ^
	WINVER=0x500
:: Build translations
pushd po
nmake -f Make_mvc.mak GETTEXT_PATH=C:\cygwin\bin VIMRUNTIME=..\..\runtime install-all
popd

@echo off
goto :eof


:build_x64
:: ----------------------------------------------------------------------
@echo on
:: Remove progress bar from the build log
sed -e "s/\$(LINKARGS2)/\$(LINKARGS2) | sed -e 's#.*\\\\r.*##'/" Make_mvc.mak > Make_mvc2.mak
:: Build GUI version
nmake -f Make_mvc2.mak CPU=AMD64 ^
	GUI=yes OLE=no DIRECTX=yes ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PERL_VER=522 DYNAMIC_PERL=yes PERL=C:\Perl522 ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27-x64 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34-x64 ^
	LUA_VER=53 DYNAMIC_LUA=yes LUA=C:\Lua ^
	TCL_VER=86 DYNAMIC_TCL=yes TCL=C:\Tcl ^
	WINVER=0x500
:: Build CUI version
nmake -f Make_mvc2.mak CPU=AMD64 ^
	GUI=no OLE=no DIRECTX=no ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PERL_VER=522 DYNAMIC_PERL=yes PERL=C:\Perl522 ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27-x64 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34-x64 ^
	LUA_VER=53 DYNAMIC_LUA=yes LUA=C:\Lua ^
	TCL_VER=86 DYNAMIC_TCL=yes TCL=C:\Tcl ^
	WINVER=0x500
:: Build translations
pushd po
nmake -f Make_mvc.mak GETTEXT_PATH=C:\cygwin\bin VIMRUNTIME=..\..\runtime install-all
popd

@echo off
goto :eof
