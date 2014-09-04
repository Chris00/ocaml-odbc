
include ../Makefile.master

SOURCES = biniki_messages.ml \
	biniki_misc.ml \
	biniki_context.ml \
	biniki_query_box.ml \
	biniki_window.ml \
	biniki.ml

all:
	@if test "$(OCAML_PKG_LABLGTK2)" = "no"; then \
	  echo "*** ERROR: Cannot compile Biniki, lablgtk2 not present."; \
	else \
	  for d in $(DATABASES_INSTALLED); do \
	    echo "module ODBC = Odbc_$$d" > odbc_driver.ml; \
	    $(MAKE) -B BASE=$$d program; \
	  done; \
	fi

program: exe opt
exe: biniki_$(BASE).byte
opt: biniki_$(BASE).native

fr:
	$(RM) biniki_messages.ml
	ln -s biniki_messages_fr.ml biniki_messages.ml

en:
	$(RM) biniki_messages.ml
	ln -s biniki_messages_en.ml biniki_messages.ml

# Overriden flags
COMPFLAGS=-nolabels -I ../$(SUBDIR)
LINKFLAGS=-ccopt -L../$(SUBDIR) -I ../$(SUBDIR)

LIBSGTK = -package $(OCAML_PKG_LABLGTK2) -linkpkg

biniki_%.byte: odbc_driver.ml $(SOURCES)
	$(OCAMLFIND) ocamlc -o $@ -custom $(LINKFLAGS) $(LIBSGTK) \
	  odbc.cma odbc_$(BASE).cma unix.cma str.cma $^

biniki_%.native: odbc_driver.ml $(SOURCES)
	$(OCAMLFIND) ocamlopt -o $@ $(LINKFLAGS) $(LIBSGTK) \
	  odbc.cmxa odbc_$(BASE).cmxa unix.cmxa str.cmxa $^

clean_all: clean
	$(RM) $(wildcard *.cmo *.cmx *.cmi *.o *.byte *.native)

clean:
	$(RM) *~ #*# *-

# common rules
.depend depend::
	$(RM) .depend
	$(OCAMLDEP) $(INCLUDES) *.ml *.mli > .depend

include .depend
