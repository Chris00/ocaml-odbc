
include ../master.Makefile

CMOFILES = biniki_messages.cmo\
	biniki_misc.cmo\
	biniki_context.cmo\
	biniki_query_box.cmo\
	biniki_window.cmo\
	biniki.cmo
CMIFILES =  $(CMOFILES:.cmo=.cmi)
CMXFILES =  $(CMOFILES:.cmo=.cmx)

# Overriden flags

COMPFLAGS=-I ../$(SUBDIR) $(INCLUDEGTK)
LINKFLAGS=-ccopt -L../$(SUBDIR) -I ../$(SUBDIR) $(LINKGTK) 

####
BINIKI=biniki
BINIKI_OPT=biniki.opt

# targets for each database
mysql:
	make BASE=MYSQL all
postgres:
	make BASE=POSTGRES all
openingres:
	make BASE=OPENINGRES all
db2:
	make BASE=DB2 all
unixodbc:
	make BASE=unixODBC all

all: exe opt
exe: $(BINIKI)
opt: $(BINIKI_OPT)


fr:
	$(RM) biniki_messages.ml
	ln -s biniki_messages_fr.ml biniki_messages.ml

en:
	$(RM) biniki_messages.ml
	ln -s biniki_messages_en.ml biniki_messages.ml

$(BINIKI): $(CMOFILES) $(CMIFILES) 
	$(OCAMLC) -custom -o $@ $(LINKFLAGS) $(LIB) unix.cma str.cma $(LIBSGTK) $(CMOFILES)

$(BINIKI_OPT): $(CMXFILES) $(CMIFILES)
	$(OCAMLOPT) -o $@ $(LINKFLAGS) $(LIB_OPT) unix.cmxa str.cmxa $(LIBSGTK_OPT) $(CMXFILES)  

clean_all: clean
	$(RM) $(CMOFILES) $(CMXFILES) $(CMIFILES) *.o
	$(RM) $(BINIKI) $(BINIKI_OPT)

clean:
	$(RM) *~ #*# *-

# common rules
.depend depend::
	rm -f .depend
	$(OCAMLDEP) $(INCLUDES) *.ml *.mli > .depend

include .depend