###############################################################################
#              OCamlODBC                                                      #
#                                                                             #
#  Copyright (C) 2004-2011 Institut National de Recherche en Informatique     #
#  et en Automatique. All rights reserved.                                    #
#                                                                             #
#  This program is free software; you can redistribute it and/or modify       #
#  it under the terms of the GNU Lesser General Public License as published   #
#  by the Free Software Foundation; either version 2.1 of the License, or     #
#  any later version.                                                         #
#                                                                             #
#  This program is distributed in the hope that it will be useful,            #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#  GNU Lesser General Public License for more details.                        #
#                                                                             #
#  You should have received a copy of the GNU Lesser General Public License   #
#  along with this program; if not, write to the Free Software                #
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#  02111-1307  USA                                                            #
#                                                                             #
#  Contact: Maxence.Guesdon@inria.fr                                          #
###############################################################################

include Makefile.master

all:
	for d in $(DATABASES_INSTALLED); do \
	  $(MAKE) BASE=$$d library; \
	done

# For all databases -- distinguished by $(BASE)
###############################################
library:
	@if [ -z "$(BASE)" ]; then \
	  echo "*** ERROR: The variable BASE must be set."; exit 1; \
	else \
	  echo "======== Compiling '$(BASE)' ========"; \
	fi
	$(MAKE) BASE=$(BASE) ocamlmklib


odbc_$(BASE)_c.c: ocaml_odbc_c.c
	sed -e 's/ocamlodbc_/ocamlodbc_$(BASE)_/' $< > $@

odbc_$(BASE)_c.o: odbc_$(BASE)_c.c
	$(CC) -c $(CFLAGS) $(OPTODBC) $(ODBCINCLUDE) $<

odbc_$(BASE)_lowlevel.ml: ocamlodbc_lowlevel.ml
	sed -e 's/ocamlodbc_/ocamlodbc_$(BASE)_/' $< > $@
odbc_$(BASE).ml: ocamlodbc.ml
	sed -e 's/Ocamlodbc_lowlevel/Odbc_$(BASE)_lowlevel/' $< > $@
odbc_$(BASE).mli: ocamlodbc.mli
	$(CP) $< $@

ocamlmklib: odbc_$(BASE)_c.o odbc_$(BASE)_lowlevel.ml \
  odbc_$(BASE).mli odbc_$(BASE).ml
	$(OCAMLMKLIB) -o odbc_$(BASE) -oc odbc_$(BASE)_stubs \
	  $(addprefix -I, $(ODBCINCLUDE)) $(ODBCLIB) $(LIBS) $^

clean:
	$(RM) *~ #*# *-
	$(RM) $(wildcard *.o *.cmi *.cmo *.cma *.cmx *.cmxa *.a *.so)

distclean: clean
	$(RM) Makefile.master $(wildcard config.* odbc_*.ml odbc_*.mli odbc_*.c)

# documentation :
#################
doc:
	$(MKDIR) doc
	$(OCAMLDOC) $(OCAMLPP) -d doc -html \
	-dump doc/ocamlodbc.odoc ocamlodbc.mli ocamlodbc.ml
	@echo Documentation is in doc/index.html

distribdoc:
	$(MKDIR) $@
	$(OCAMLDOC) $(OCAMLPP) -d $@ -html \
	-css-style "../style.css" ocamlodbc.mli ocamlodbc.ml
	@echo Distrib documentation is in $@/


# installation :
################
.PHONY : install direct_install findlib_install
install:
	@echo "Installation instructions:"
	@echo '  To install using findlib type: "make findlib_install"'
	@echo '  To install directly type : "make direct_install"'

direct_install:
	if test -d $(INSTALL_BINDIR); then : ; \
	  else $(MKDIR) $(INSTALL_BINDIR); fi
	if test -d $(INSTALL_LIBDIR); then : ; \
	  else $(MKDIR) $(INSTALL_LIBDIR); fi
	for i in mysql postgres db2 unixodbc openingres oraclecfo ; \
	do (if test -d $$i ; then ($(MKDIR) $(INSTALL_LIBDIR)/$$i ; \
	  $(CP) $$i/* $(INSTALL_LIBDIR)/$$i/) fi) ; \
	done

findlib_install:
	ocamlfind install META \
	  $(wildcard odbc_*.cmi odbc_*.cma odbc_*.cmxa odbc_*.cmx *_stubs.a)


# common rules
.depend depend:: $(wildcard *.ml) $(wildcard *.mli)
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) $^ > .depend


.SUFFIXES: .c .o


# web site :
############
WEBDEST=forge.ocamlcore.org:/home/groups/ocamlodbc/htdocs/
installweb:
	scp -r web/* $(LOGIN)@$(WEBDEST)

include .depend
