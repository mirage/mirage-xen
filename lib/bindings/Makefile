.PHONY: all clean
all: libmirage-xen_bindings.a

CC=ocamlfind -toolchain solo5 ocamlopt
CFLAGS=-ccopt "-I ./include/ -O2 -std=c99 -Wall -D__XEN_INTERFACE_VERSION__=__XEN_LATEST_INTERFACE_VERSION__"
OBJS=bmap.o clock_stubs.o evtchn.o gnttab.o main.o

libmirage-xen_bindings.a: $(OBJS)
	$(AR) r $@ $^

clean:
	$(RM) $(OBJS) libmirage-xen_bingings.a
