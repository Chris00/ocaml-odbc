@echo off
REM ocamlODBC installation script for Windows
REM Clement Capel, Oct 2003
REM Troestler Christophe, June 2007 (thanks to Dmitry Bely for suggestions)

set INSTALLDIR=%OCAMLLIB%\ocamlodbc
set STUBDIR=%OCAMLLIB%\stublibs
set ODBC3=
REM Uncomment if your system supports ODBC 3.0 or greater.
REM set ODBC3=/DODBC3
set DEBUG=
REM set DEBUG=/DDEBUG2

echo ----------------------------------------------------------------------
REM Please read the README.win32 file in the ocaml distribution,
REM get the appropriate software for MSVC and compile in a shell with the
REM appropriate PATH set.  The latter is typically done by executing .bat :
REM
REM CALL "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
REM CALL "c:\Program Files\Microsoft Platform SDK"\SetEnv.Cmd /SRV32
echo Assumes VC++ installed:
echo i.e. "cl", "link", and "lib" are available
echo ----------------------------------------------------------------------

REM set LIBODBC=libodbc32.lib
REM For Windows Server 2003:
set LIBODBC=odbc32.lib
REM set CUSTOM=-custom ocaml_odbc_c.obj  -cclib -lodbc32
REM set CUSTOM=

REM See http://msdn2.microsoft.com/en-us/library/d91k01sh(VS.80).aspx
REM for the structure of DEF files

prompt $G$S
@echo on
@echo --- Compile the external functions and create the dll ---
cl /nologo /Ox /MT /DWIN32 %ODBC3% /I "%OCAMLLIB%" /c ocaml_odbc_c.c /Foocaml_odbc_c.s.obj
lib /nologo /out:libocamlodbc.lib ocaml_odbc_c.s.obj

cl /nologo /Ox /MD %DEBUG% /DWIN32 %ODBC3% /DCAML_DLL /I "%OCAMLLIB%" /c ocaml_odbc_c.c /Foocaml_odbc_c.d.obj
link /nologo /dll /out:dllocamlodbc.dll /def:ocamlodbc.DEF  ocaml_odbc_c.d.obj /LIBPATH:"%OCAMLLIB%" ocamlrun.lib %LIBODBC%

@echo --- Make a byte code library ---
ocamlc -a -o ocamlodbc.cma %CUSTOM% ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml -cclib -locamlodbc -cclib %LIBODBC%

@echo --- Make a native code library ---
ocamlopt -a -o ocamlodbc.cmxa ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml -cclib -locamlodbc -cclib %LIBODBC%

@echo --- Install ---
mkdir "%INSTALLDIR%"
copy libocamlodbc.lib "%INSTALLDIR%" >NUL
copy dllocamlodbc.dll "%STUBDIR%"  >NUL

copy ocamlodbc.mli  "%INSTALLDIR%" >NUL
copy ocamlodbc.cmi  "%INSTALLDIR%" >NUL
copy ocamlodbc.cma  "%INSTALLDIR%" >NUL
copy ocamlodbc.cmxa "%INSTALLDIR%" >NUL
copy ocamlodbc.lib  "%INSTALLDIR%" >NUL

@prompt $P$G$S
