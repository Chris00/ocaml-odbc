@echo ocamlODBC installation script for Windows
@echo Clement Capel Oct 2003
@echo -----------------------------------------

@echo Assumes VC++ installed
@echo variables set for "cl" and "link"
@echo -----------------------------------------

@echo  Compile the external functions and create the dll
cl /nologo /Ox /MD /DWIN32 -I "%OCAMLLIB%"\caml -c ocaml_odbc_c.c
move ocaml_odbc_c.obj ocaml_odbc_c.d.obj
link /nologo /dll /out:dllocamlodbc.dll /def:ocamlodbc.DEF  ocaml_odbc_c.d.obj "%OCAMLLIB%"\ocamlrun.lib  libodbc32.lib
copy dllocamlodbc.dll "%OCAMLLIB%"\stublibs

@echo  Make a native code library
ocamlopt -a -o ocamlodbc.cmxa ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -cclib -lodbc32
copy ocamlodbc.cmxa "%OCAMLLIB%"
copy ocamlodbc.cmi "%OCAMLLIB%"

@echo  Make a custom runtime library
ocamlc -a -o ocamlodbc.cma -custom ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -dllib -locamlodbc  -cclib -lodbc32
copy ocamlodbc.cma "%OCAMLLIB%"
copy ocamlodbc.cmi "%OCAMLLIB%"
