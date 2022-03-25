.PHONY: all clean
all: libmirage-xen_bindings.a

CC=ocamlfind -toolchain solo5 ocamlopt
CFLAGS=-cclib "-I ./include/"
OBJS=bmap.o clock_stubs.o evtchn.o gnttab.o main.o

libmirage-xen_bindings.a: $(OBJS)
	$(AR) r $@ $^

clean:
	$(RM) $(OBJS) libmirage-xen_bingings.a
