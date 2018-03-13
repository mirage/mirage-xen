#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
#require "ocb-stubblr.topkg"
open Topkg
open Ocb_stubblr_topkg

let opams = [
  Pkg.opam_file "opam" ~lint_deps_excluding:(Some ["mirage-xen-ocaml"; "io-page-xen"; "mirage-xen-minios"])
]

let nowhere ?force ?built ?cond ?exts ?dst _ = Pkg.nothing

let () =
  Pkg.describe ~build:(Pkg.build ~cmd()) ~opams "mirage-xen" @@ fun c ->
  Ok [
    Pkg.mllib "lib/oS.mllib" ;
    Pkg.clib ~dllfield:nowhere "lib/libmirage-xen_bindings.clib";
    (* Should be lib/pkgconfig/ but workaround ocaml/opam#2153 *)
    Pkg.share_root ~dst:"pkgconfig/" "lib/bindings/mirage-xen.pc"
  ]
