
include ../master.Makefile

CMOFILES =  monitor.cmo
CMIFILES =  $(CMOFILES:.cmo=.cmi)
CMXFILES =  $(CMOFILES:.cmo=.cmx)
CMOFILES2 = test.cmo
CMIFILES2 =  $(CMOFILES2:.cmo=.cmi)
CMXFILES2 =  $(CMOFILES2:.cmo=.cmx)

PROG=monitor
PROG_OPT=monitor_opt
PROG2=ptest
PROG2_OPT=ptest_opt
PROG3=ptest_mt
PROG3_OPT=ptest_mt_opt

####
COMPFLAGS=-I ../$(SUBDIR) -ccopt -L../$(SUBDIR)
ALLLINKFLAGS=-ccopt -L../$(SUBDIR) -I ../$(SUBDIR) $(LINKFLAGS) 

all: $(PROG) $(PROG2) $(PROG3)
opt: $(PROG_OPT) $(PROG2_OPT) $(PROG3_OPT)


$(PROG): $(CMOFILES)
	$(OCAMLC) -custom -o $@ $(ALLLINKFLAGS) $(LIB) $(CMOFILES)  \
	-cclib -ldl -cclib -lunix 

$(PROG_OPT): $(CMXFILES)
	$(OCAMLOPT) -o $@ $(ALLLINKFLAGS) $(LIB_OPT) $(CMXFILES)  \
	-cclib -ldl -cclib -lunix 

$(PROG2): $(CMOFILES2)
	$(OCAMLC) -custom -o $@ $(COMPFLAGS) unix.cma $(LIB) $(CMOFILES2)  \
	-cclib -ldl -cclib -lunix $(LINKFLAGS)

$(PROG2_OPT): $(CMXFILES2)
	$(OCAMLOPT) -o $@ $(COMPFLAGS) unix.cmxa $(LIB_OPT) $(CMXFILES2)  \
	-cclib -ldl -cclib -lunix $(LINKFLAGS)

$(PROG3): test_mt.ml
	$(OCAMLC) $(COMPFLAGS) -thread -custom -o $@ unix.cma threads.cma $(LIB) $< \
	-cclib -ldl -cclib -lunix $(LINKFLAGS)

$(PROG3_OPT): test_mt.ml
	$(OCAMLOPT) $(COMPFLAGS) -thread -o $@ unix.cmxa threads.cmxa $(LIB_OPT) $<  \
	-cclib -ldl -cclib -lunix $(LINKFLAGS)

clean_all: clean
	$(RM) *.cmo *.cmx *.cmi *.o
	$(RM) $(PROG) $(PROG_OPT) $(PROG2) $(PROG2_OPT) $(PROG3) $(PROG3_OPT)

clean:
	$(RM) *~ #*# *-

# common rules

