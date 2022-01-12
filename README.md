# mirage-xen -- Xen core platform libraries for MirageOS

This package provides the MirageOS `OS` library for
Xen targets, which handles the main loop and timers.  It also provides
the low level C startup code and C stubs required by the OCaml code.

[![Build Status](https://travis-ci.org/mirage/mirage-xen.svg)](https://travis-ci.org/mirage/mirage-xen)

## Development

```
$ git clone https://github.com/mirage/mirage-xen
$ cd mirage-xen
$ opam monorepo lock
$ opam monorepo pull
$ opam install ocaml-freestanding dune
$ dune build
```
