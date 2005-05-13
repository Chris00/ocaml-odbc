# ocamlODBC installation script for Windows
# Clement Capel Oct 2003
# ----------------------------------------- 

# Assumes VC++ installed 
# variables set for "cl" and "link"
# ----------------------------------------- 

#  Compile the external functions and create the dll
#cl /nologo /Ox /MD /DWIN32 -I %OCAMLLIB%\caml -c ocaml_odbc_c.c
#move ocaml_odbc_c.obj ocaml_odbc_c.d.obj
#link /nologo /dll /out:dllocamlodbc.dll /def:ocamlodbc.DEF  ocaml_odbc_c.d.obj %OCAMLLIB%\ocamlrun.lib  libodbc32.lib
#copy dllocamlodbc.dll %OCAMLLIB%\stublibs

#insert -DDEBUG2 for gobs of debugging output
gcc -mno-cygwin -g -DDEBUG_LIGHT -DODBC2 -I /cygdrive/c/ocaml/lib/caml -I /usr/include/w32api -DWIN32 -c ocaml_odbc_c.c
gcc -mno-cygwin -g -shared -L /cygdrive/c/ocaml/lib -o dllocamlodbc.dll /cygdrive/c/ocaml/bin/ocamlrun.dll ocaml_odbc_c.o -lodbc32

#  Make a native code library
#ocamlopt -a -o ocamlodbc.cmxa ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -cclib -lodbc32
#copy ocamlodbc.cmxa %OCAMLLIB%
#copy ocamlodbc.cmi %OCAMLLIB%

#  Make a custom runtime library
#ocamlc -a -o ocamlodbc.cma -custom ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -dllib -locamlodbc  -cclib -lodbc32
#copy ocamlodbc.cma %OCAMLLIB%
#copy ocamlodbc.cmi %OCAMLLIB%

# Make a toplevel-dynlinked library
ocamlc -a -o ocamlodbc.cma ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml -dllib -locamlodbc
cp *.cmi *.mli *.cma $HOME/ocaml/lib
cp *.dll $HOME/ocaml/bin


