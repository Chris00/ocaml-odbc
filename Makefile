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

OBJOCAML  = ocaml_odbc.cmo
OBJOCAML_OPT  = ocaml_odbc.cmx

LIBOBJ    = ocamlodbc.cmo
LIBOBJ_OPT    = ocamlodbc.cmx
LIBOBJI   = ocamlodbc.cmi

OBJFILES = ocaml_odbc_c.o

all:
	for d in $(DATABASES_INSTALLED); do \
	  $(MAKE) clean; \
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
	$(MAKE) BASE=$(BASE) lib opt
	mkdir -p $(BASE)
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $(BASE)
	@echo Libs are in $@/

opt: lib_opt META

lib: $(LIB_CMI) $(LIB)
lib_opt: $(LIB_CMI) $(LIB_OPT)

$(LIB_C): $(OBJFILES)
	$(RM) $@
	$(AR) $@ $(OBJFILES)
	$(RANLIB) $@

$(LIB): $(OBJOCAML) $(LIBOBJ)
	$(OCAMLC) -a -linkall -custom -o $@ -cclib -locamlodbc \
		$(LINKFLAGS) $(OBJOCAML) $(LIBOBJ)
$(LIB_OPT): $(OBJOCAML_OPT) $(LIBOBJ_OPT) $(LIB_C)
	$(OCAMLOPT) -a -linkall -o $(LIB_OPT) -cclib -locamlodbc \
		$(LINKFLAGS) $(OBJOCAML_OPT) $(LIBOBJ_OPT)

META : DESTDIR=$(shell ocamlfind printconf destdir)
META :
	@echo 'name="ocamlodbc_$(LIB_DIR)"' > $@
	@echo 'version="'$(PACKAGE_VERSION)'"' >> $@
	@echo 'requires=""' >> $@
#	echo 'directory="+ocamlodbc/$(LIB_DIR)"' >> $@
	@echo 'archive(byte)="$(LIB)"' >> $@
	@echo 'archive(native)="$(LIB_OPT)"' >> $@
	@echo 'linkopts="-ccopt -L$(DESTDIR)/ocamlodbc_$(LIB_DIR)"' >> $@

#libocaml_odbc.cmo: $(OBJOCAML) $(LIBOBJ)
#	cp libocaml_odbc.cmo libocaml_odbc.cmo
#libocaml_odbc.cmx: $(OBJOCAML_OPT) $(LIBOBJ_OPT)
#	cp libocaml_odbc.cmx libocaml_odbc.cmx


clean:
	$(RM) *~ #*# *-
	$(RM) *.o *.cmi *.cmo *.cma *.cmx *.cmxa *.a *.so META

distclean: clean
	$(RM) Makefile.master config.*

# documentation :
#################
doc: dummy
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
.PHONY : install
install:
	@echo "Installation instructions:"
	@echo '  To install using findlib type: "make findlib_install"'
	@echo '  To install directly type : "make direct_install"'

direct_install: dummy
	if test -d $(INSTALL_BINDIR); then : ; \
	  else $(MKDIR) $(INSTALL_BINDIR); fi
	if test -d $(INSTALL_LIBDIR); then : ; \
	  else $(MKDIR) $(INSTALL_LIBDIR); fi
	for i in mysql postgres db2 unixodbc openingres oraclecfo ; \
	do (if test -d $$i ; then ($(MKDIR) $(INSTALL_LIBDIR)/$$i ; \
	  $(CP) $$i/* $(INSTALL_LIBDIR)/$$i/) fi) ; \
	done

findlib_install: META dummy
	for i in mysql postgres db2 unixodbc openingres oraclecfo ; do \
	  if [ -d $$i ]; then \
	    if (ocamlfind list | grep ocamlodbc_$$i >/dev/null); then \
	      ocamlfind remove ocamlodbc_$$i; \
	    fi; \
	    ocamlfind install ocamlodbc_$$i $$i/META \
	      `find $$i -not -name META -type f`; \
	  fi; \
	done

# common rules
.depend depend:: $(wildcard *.ml) $(wildcard *.mli)
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) $^ > .depend


.SUFFIXES: .c .o

ocaml_odbc_c.o :ocaml_odbc_c.c
	$(CC) -c $(CFLAGS) $<

dummy:

# web site :
############
WEBDEST=forge.ocamlcore.org:/home/groups/ocamlodbc/htdocs/
installweb:
	scp -r web/* $(LOGIN)@$(WEBDEST)

include .depend
