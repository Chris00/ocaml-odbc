REM How I got OCamlODBC working under Win32
REM by John Small ( jsmall@laser.net )

REM Get the OCamlODBC from
REM http://www.maxence-g.net/tools_en.html
REM http://www.maxence-g.net/ocamlodbc_2_2.tgz

REM After unzipping ocamlodbc_2_2.tgz with WinZip

cd \ocaml\OcamlODBC\src

REM  Assumes VC++ installed  (My vision is 6.0) and environment
REM  variables set for "cl"

REM  Copy and rename the odbc32.lib
copy "\Program Files\Microsoft Visual Studio\Vc98\lib\Odbc32.lib" libodbc32.lib

REM  Compile the external functions
cl /c /DWIN32 /MT /I\ocaml\lib\caml ocaml_odbc_c.c

REM  Make a native code library
ocamlopt -a -o ocamlodbc.cmxa ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -cclib -lodbc32
copy ocamlodbc.cmxa \ocaml\lib
copy ocamlodbc.lib \ocaml\lib
copy ocamlodbc.cmi \ocaml\lib
copy libodbc32.lib \ocaml\lib

REM  Make a custom runtime library
ocamlc -a -o ocamlodbc.cma -custom ocaml_odbc.ml ocamlodbc.mli ocamlodbc.ml ocaml_odbc_c.obj -cclib -lodbc32
copy ocamlodbc.cma \ocaml\lib
copy ocamlodbc.cmi \ocaml\lib
copy libodbc32.lib \ocaml\lib

REM  This runtime library is buggy and get the following error:
REM  myprog.cmo and ocamlodbc.cma make inconsistent assumptions
REM  over interface ocamlodbc.

REM  But if I compile as shown below it's fine:
REM  ocamlc -o myprog ocaml_odbc.ml ocamlodbc.mli libocaml.ml myprog.ml ocaml_odbc_c.obj -cclib -lodbc32
REM  I'm guessing the bug is in how the ocamlodbc.cma file holds the interface declaration.