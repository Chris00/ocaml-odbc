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
	make BASE=MYSQL all
	mkdir -p $@
	$(MV) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	make clean_all
	@echo Libs are in $@/

postgres: dummy
	make BASE=POSTGRES all
	mkdir -p $@
	$(MV) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	make clean_all
	@echo Libs are in $@/

db2: dummy
	make BASE=DB2 all
	mkdir -p $@
	$(MV) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	make clean_all
	@echo Libs are in $@/

openingres: dummy
	make BASE=OPENINGRES all
	mkdir -p $@
	$(MV) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	make clean_all
	@echo Libs are in $@/

unixodbc: dummy
	make BASE=unixODBC all
	mkdir -p $@
	$(MV) $(LIB_C) $(LIB_A) $(LIB_CMI) $(LIB) $(LIB_OPT) $@/
	make clean_all
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
	$(OCAMLC) -a -linkall -custom -o $@ -cclib -locamlodbc $(OBJOCAML) $(LIBOBJ)
$(LIB_OPT): $(OBJOCAML_OPT) $(LIBOBJ_OPT) $(LIB_C)
	$(OCAMLOPT) -a -linkall -o $(LIB_OPT) -cclib -locamlodbc $(OBJOCAML_OPT) $(LIBOBJ_OPT) 

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

# common rules
.depend depend::
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) *.ml *.mli > .depend


.SUFFIXES: .c .o

%.o :%.c 
	$(CC) -c $(C_COMPFLAGS) $<

dummy:

include .depend


