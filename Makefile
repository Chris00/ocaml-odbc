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
	make clean_all
	make BASE=MYSQL all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	@echo Libs are in $@/

postgres: dummy
	make clean_all
	make BASE=POSTGRES all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	@echo Libs are in $@/

db2: dummy
	make clean_all
	make BASE=DB2 all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	@echo Libs are in $@/

openingres: dummy
	make clean_all
	make BASE=OPENINGRES all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	@echo Libs are in $@/

unixodbc: dummy
	make clean_all
	make BASE=unixODBC all
	mkdir -p $@
	$(CP) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	@echo Libs are in $@/

# For all databases
###################
all: lib opt
opt: lib_opt

$(LIB_C): $(OBJFILES)
	$(RM) $@
	$(AR) $@ $(OBJFILES)
	$(RANLIB) $@

$(LIB): $(OBJOCAML) $(LIBOBJ)
	$(OCAMLC) -a -linkall -custom -o $@ -cclib -locamlodbc $(LINKFLAGS) $(OBJOCAML) $(LIBOBJ)
$(LIB_OPT): $(OBJOCAML_OPT) $(LIBOBJ_OPT) $(LIB_C)
	$(OCAMLOPT) -a -linkall -o $(LIB_OPT) -cclib -locamlodbc $(LINKFLAGS) $(OBJOCAML_OPT) $(LIBOBJ_OPT) 

#libocaml_odbc.cmo: $(OBJOCAML) $(LIBOBJ) 
#	cp libocaml_odbc.cmo libocaml_odbc.cmo
#libocaml_odbc.cmx: $(OBJOCAML_OPT) $(LIBOBJ_OPT) 
#	cp libocaml_odbc.cmx libocaml_odbc.cmx


lib: $(LIB_C) $(LIB_CMI) $(LIB)
lib_opt: $(LIB_C) $(LIB_CMI) $(LIB_OPT)

clean_all: clean
	$(RM) *.o *.cmi *.cmo *.cma *.cmx *.cmxa *.a

clean:
	$(RM) *~ #*# *-

# documentation :
#################
doc: dummy
	$(MKDIR) doc
	$(OCAMLDOC) $(OCAMLPP) $(COMPFLAGS) -d doc -html \
	-dump doc/ocamlodbc.odoc ocamlodbc.mli ocamlodbc.ml
	@echo Documentation is in doc/index.html

# installation :
################
install: dummy
	if test -d $(INSTALL_BINDIR); then : ; else $(MKDIR) $(INSTALL_BINDIR); fi
	if test -d $(INSTALL_LIBDIR); then : ; else $(MKDIR) $(INSTALL_LIBDIR); fi
	for i in mysql postgres db2 unixodbc openingres ; \
	do (if test -d $$i ; then ($(MKDIR) $(INSTALL_LIBDIR)/$$i ; $(CP) $$i/* $(INSTALL_LIBDIR)/$$i/) fi) ; done

# common rules
.depend depend::
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) *.ml *.mli > .depend


.SUFFIXES: .c .o

ocaml_odbc_c.o :ocaml_odbc_c.c 
	$(CC) -c $(C_COMPFLAGS) $<

dummy:

include .depend


