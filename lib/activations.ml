(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)
open Lwt.Infix

external evtchn_get_nr_events : unit -> int = "mirage_xen_evtchn_get_nr_events"
[@@noalloc]

external evtchn_test_and_clear : int -> bool
  = "mirage_xen_evtchn_test_and_clear"
[@@noalloc]

let nr_events = evtchn_get_nr_events ()
let event_cb = Array.init nr_events (fun _ -> Lwt_dllist.create ())

(* The high-level interface creates one counter per event channel port.
   Every time the system receives a notification it increments the counter.
   Threads which have blocked elsewhere call 'after' which blocks until
   the stored counter is greater than the value they have already -- so
   if an event comes in between calls then it will not be lost.

   In the high-level interface it's almost impossible to miss an event.
   The only way you can miss is if you block while your port's counter
   wraps. Arguably if you have failed to notice 2bn (32-bit) wakeups then
   you have bigger problems. *)

type event = int

let program_start = min_int

type port = { mutable counter : event; c : unit Lwt_condition.t }

let ports =
  Array.init nr_events (fun _port ->
      { counter = program_start; c = Lwt_condition.create () })

let dump () =
  Printf.printf "Number of received event channel events:\n";
  for i = 0 to nr_events - 1 do
    if ports.(i).counter <> program_start then
      Printf.printf "port %d: %d\n%!" i (ports.(i).counter - program_start)
  done

let after evtchn counter =
  let port = Eventchn.to_int evtchn in
  let rec loop () =
    if ports.(port).counter <= counter && Eventchn.is_valid evtchn then
      Lwt_condition.wait ports.(port).c >>= fun () -> loop ()
    else Lwt.return_unit
  in
  loop () >>= fun () ->
  if Eventchn.is_valid evtchn then Lwt.return ports.(port).counter
  else Lwt.fail Generation.Invalid

(* Low-level interface *)

(* Block waiting for an event to occur on a particular port. Note
   if the event came in when we weren't looking then it is lost and
   we will block forever. *)
let wait evtchn =
  if Eventchn.is_valid evtchn then (
    let port = Eventchn.to_int evtchn in
    let th, u = Lwt.task () in
    let node = Lwt_dllist.add_l u event_cb.(port) in
    Lwt.on_cancel th (fun _ -> Lwt_dllist.remove node);
    th)
  else (
    Printf.printf "Activations.wait %d: Generation.Invalid\n%!"
      (Eventchn.to_int evtchn);
    Lwt.fail Generation.Invalid)

(* Go through the event mask and activate any events, potentially spawning
   new threads *)
let run _ =
  for port = 0 to nr_events - 1 do
    if evtchn_test_and_clear port then (
      Lwt_dllist.iter_node_l
        (fun node ->
          let u = Lwt_dllist.get node in
          Lwt_dllist.remove node;
          Lwt.wakeup_later u ())
        event_cb.(port);
      ports.(port).counter <- ports.(port).counter + 1;
      Lwt_condition.broadcast ports.(port).c ())
  done

(* Note, this should be run *after* Generation.resume *)
let resume () =
  for port = 0 to nr_events - 1 do
    Lwt_dllist.iter_node_l
      (fun node ->
        let u = Lwt_dllist.get node in
        Lwt_dllist.remove node;
        Lwt.wakeup_later_exn u Generation.Invalid)
      event_cb.(port);
    Lwt_condition.broadcast ports.(port).c ()
  done
