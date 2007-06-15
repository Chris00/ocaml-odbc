@echo off
echo ocamlODBC installation script for Windows
echo Clement Capel Oct 2003
echo -----------------------------------------

echo Assumes VC++ installed
echo variables set for "cl" and "link"
echo -----------------------------------------

REM set LIBODBC=libodbc32.lib
REM For Windows Server 2003:
set LIBODBC=odbc32.lib

REM See http://msdn2.microsoft.com/en-us/library/d91k01sh(VS.80).aspx
REM for the structure of DEF files

@echo on
@echo --- Compile the external functions and create the dll ---
cl /nologo /Ox /MD /DWIN32 /DCAML_DLL -I "%OCAMLLIB%" -c ocaml_odbc_c.c

move ocaml_odbc_c.obj ocaml_odbc_c.d.obj >NUL
link /nologo /dll /out:dllocamlodbc.dll /def:ocamlodbc.DEF  ocaml_odbc_c.d.obj /LIBPATH:"%OCAMLLIB%" ocamlrun.lib %LIBODBC%
copy dllocamlodbc.dll "%OCAMLLIB%"\stublibs >NUL
@echo ---
@echo --- Make a custom runtime library ---
ocamlc -a -o ocamlodbc.cma -custom ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -dllib -locamlodbc  -cclib -lodbc32
copy ocamlodbc.cma "%OCAMLLIB%" >NUL
copy ocamlodbc.cmi "%OCAMLLIB%" >NUL
@echo ---
@echo --- Make a native code library ---
ocamlopt -a -o ocamlodbc.cmxa ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -cclib -lodbc32
copy ocamlodbc.cmxa "%OCAMLLIB%" >NUL
copy ocamlodbc.cmi "%OCAMLLIB%"  >NUL
