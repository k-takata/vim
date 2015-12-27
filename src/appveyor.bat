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
@echo off
goto :eof

:install_x64
:: ----------------------------------------------------------------------
@echo on
:: Work around for Python 2.7.11
reg copy HKLM\SOFTWARE\Python\PythonCore\2.7 HKLM\SOFTWARE\Python\PythonCore\2.7-32 /s /reg:64
@echo off
goto :eof


:build_x86
:: ----------------------------------------------------------------------
@echo on
:: Remove progress bar from the build log
sed -e "s/\$(LINKARGS2)/\$(LINKARGS2) | sed -e 's#.*\\\\r.*##'/" Make_mvc.mak > Make_mvc2.mak
:: Build GUI version
nmake -f Make_mvc2.mak CPU=i386 ^
	GUI=yes OLE=yes DIRECTX=yes ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34 ^
	WINVER=0x500
:: Build CUI version
nmake -f Make_mvc2.mak CPU=i386 ^
	GUI=no OLE=no DIRECTX=no ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34 ^
	WINVER=0x500

@echo off
goto :eof


:build_x64
:: ----------------------------------------------------------------------
@echo on
:: Remove progress bar from the build log
sed -e "s/\$(LINKARGS2)/\$(LINKARGS2) | sed -e 's#.*\\\\r.*##'/" Make_mvc.mak > Make_mvc2.mak
:: Build GUI version
nmake -f Make_mvc2.mak CPU=AMD64 ^
	GUI=yes OLE=yes DIRECTX=yes ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27-x64 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34-x64 ^
	WINVER=0x500
:: Build CUI version
nmake -f Make_mvc2.mak CPU=AMD64 ^
	GUI=no OLE=no DIRECTX=no ^
	FEATURES=HUGE IME=yes MBYTE=yes ICONV=yes DEBUG=no ^
	PYTHON_VER=27 DYNAMIC_PYTHON=yes PYTHON=C:\Python27-x64 ^
	PYTHON3_VER=34 DYNAMIC_PYTHON3=yes PYTHON3=C:\Python34-x64 ^
	WINVER=0x500

@echo off
goto :eof
