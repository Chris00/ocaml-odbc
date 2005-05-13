#################################################################################
#                OCamlODBC                                                         #
#                                                                               #
#    Copyright (C) 2004 Institut National de Recherche en Informatique et       #
#    en Automatique. All rights reserved.                                       #
#                                                                               #
#    This program is free software; you can redistribute it and/or modify       #
#    it under the terms of the GNU Lesser General Public License as published   #
#    by the Free Software Foundation; either version 2.1 of the License, or     #
#    any later version.                                                         #
#                                                                               #
#    This program is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#    GNU Lesser General Public License for more details.                        #
#                                                                               #
#    You should have received a copy of the GNU Lesser General Public License   #
#    along with this program; if not, write to the Free Software                #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#    02111-1307  USA                                                            #
#                                                                               #
#    Contact: Maxence.Guesdon@inria.fr                                          #
#################################################################################

include master.Makefile

OBJOCAML  = ocaml_odbc.cmo
OBJOCAML_OPT  = ocaml_odbc.cmx

LIBOBJ    = ocamlodbc.cmo
LIBOBJ_OPT    = ocamlodbc.cmx
LIBOBJI   = ocamlodbc.cmi

OBJFILES = ocaml_odbc_c.o

####
# For different target databases
################################
mysql: dummy
	make clean
	make BASE=MYSQL LIB_DIR=$@ all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $@/
	@echo Libs are in $@/

postgres: dummy
	make clean
	make BASE=POSTGRES LIB_DIR=$@ all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $@/
	@echo Libs are in $@/

db2: dummy
	make clean
	make BASE=DB2 LIB_DIR=$@ all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $@/
	@echo Libs are in $@/

openingres: dummy
	make clean
	make BASE=OPENINGRES LIB_DIR=$@ all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $@/
	@echo Libs are in $@/

unixodbc: dummy
	make clean
	make BASE=unixODBC LIB_DIR=$@ all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $@/
	@echo Libs are in $@/

oraclecfo: dummy
	make clean
	make BASE=ORACLECFO LIB_DIR=$@ all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $(DLL) META $@/
	@echo Libs are in $@/

# For all databases
###################
all: lib opt
opt: lib_opt META

$(LIB_C): $(OBJFILES)
	$(RM) $@
	$(AR) $@ $(OBJFILES)
	$(RANLIB) $@

$(LIB): $(OBJOCAML) $(LIBOBJ)
	$(OCAMLC) -a -linkall -custom -o $@ -cclib -locamlodbc $(LINKFLAGS) $(OBJOCAML) $(LIBOBJ)
$(LIB_OPT): $(OBJOCAML_OPT) $(LIBOBJ_OPT) $(LIB_C)
	$(OCAMLOPT) -a -linkall -o $(LIB_OPT) -cclib -locamlodbc $(LINKFLAGS) $(OBJOCAML_OPT) $(LIBOBJ_OPT)

META : DESTDIR=$(shell ocamlfind printconf destdir)
META :
	@echo 'name="ocamlodbc_$(LIB_DIR)"' > $@
	@echo 'version="'`grep "let version =" ocamlodbc.ml | cut -d'"' -f 2`'"' >> $@
	@echo 'requires=""' >> $@
#	echo 'directory="+ocamlodbc/$(LIB_DIR)"' >> $@
	@echo 'archive(byte)="$(LIB)"' >> $@
	@echo 'archive(native)="$(LIB_OPT)"' >> $@
	@echo 'linkopts="-ccopt -L$(DESTDIR)/ocamlodbc_$(LIB_DIR)"' >> $@

#libocaml_odbc.cmo: $(OBJOCAML) $(LIBOBJ)
#	cp libocaml_odbc.cmo libocaml_odbc.cmo
#libocaml_odbc.cmx: $(OBJOCAML_OPT) $(LIBOBJ_OPT)
#	cp libocaml_odbc.cmx libocaml_odbc.cmx


lib: $(LIB_CMI) $(LIB)
lib_opt: $(LIB_CMI) $(LIB_OPT)

clean:
	$(RM) *~ #*# *-
	$(RM) *.o *.cmi *.cmo *.cma *.cmx *.cmxa *.a *.so META

distclean: clean
	$(RM) master.Makefile config.*

# documentation :
#################
doc: dummy
	$(MKDIR) doc
	$(OCAMLDOC) $(OCAMLPP) $(COMPFLAGS) -d doc -html \
	-dump doc/ocamlodbc.odoc ocamlodbc.mli ocamlodbc.ml
	@echo Documentation is in doc/index.html

distribdoc:
	$(MKDIR) $@
	$(OCAMLDOC) $(OCAMLPP) $(COMPFLAGS) -d $@ -html \
	-css-style "../style.css" ocamlodbc.mli ocamlodbc.ml
	@echo Distrib documentation is in $@/

# headers :
###########
headers: dummy
	headache -h lgpl_header -c ~/.headache_config *.ml *.mli *.c \
	configure.in configure master.Makefile.in Makefile
	headache -h gpl_header -c ~/.headache_config \
	Biniki/*.ml \
	Exemples/*.ml

noheaders: dummy
	headache -r -c ~/.headache_config *.ml *.mli \
	configure.in configure master.Makefile.in \
	Exemples/*.ml \
	Biniki/*.ml


# installation :
################
.PHONY : install
install:
	@echo "Installation instructions:"
	@echo '  To install $(RESULT) using findlib type: "make findlib_install"'
	@echo '  To install $(RESULT) dirctly type : "make direct_install"'

direct_install: dummy
	if test -d $(INSTALL_BINDIR); then : ; else $(MKDIR) $(INSTALL_BINDIR); fi
	if test -d $(INSTALL_LIBDIR); then : ; else $(MKDIR) $(INSTALL_LIBDIR); fi
	for i in mysql postgres db2 unixodbc openingres oraclecfo ; \
	do (if test -d $$i ; then ($(MKDIR) $(INSTALL_LIBDIR)/$$i ; $(CP) $$i/* $(INSTALL_LIBDIR)/$$i/) fi) ; done

findlib_install: META dummy
	for i in mysql postgres db2 unixodbc openingres oraclecfo ; do \
	  if [ -d $$i ]; then \
	    if (ocamlfind list | grep ocamlodbc_$$i >/dev/null); then ocamlfind remove ocamlodbc_$$i; fi; \
	    ocamlfind install ocamlodbc_$$i $$i/META `find $$i -not -name META -type f`; \
	  fi; \
	done

# common rules
.depend depend::
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) *.ml *.mli > .depend


.SUFFIXES: .c .o

ocaml_odbc_c.o :ocaml_odbc_c.c
	$(CC) -c $(C_COMPFLAGS) $<

dummy:

include .depend
