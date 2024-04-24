(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_main
 * Copyright (C) 2009 Jérémie Dimino
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

external evtchn_block_domain : Time.t -> unit = "mirage_xen_evtchn_block_domain"
[@@noalloc]

external evtchn_demux_pending : unit -> bool = "mirage_xen_evtchn_demux_pending"
[@@noalloc]

let evtchn = Eventchn.init ()

(* Execute one iteration and register a callback function *)
let run t =
  let rec aux () =
    Lwt.wakeup_paused ();
    Time.restart_threads Time.time;
    match Lwt.poll t with
    | Some () -> ()
    | None ->
        if evtchn_demux_pending () then (
          (* Some event channels have triggered, wake up threads
           * and continue without blocking. *)
          (* Call enter hooks. *)
          Mirage_runtime.run_enter_iter_hooks ();
          Activations.run evtchn;
          (* Call leave hooks. *)
          Mirage_runtime.run_leave_iter_hooks ();
          aux ())
        else
          let timeout =
            if Lwt.paused_count () > 0 then 0L
            else
              match Time.select_next () with
              | None -> Int64.add (Time.time ()) (Duration.of_day 1)
              | Some tm -> tm
          in
          evtchn_block_domain timeout;
          aux ()
  in
  aux ()

let () =
  at_exit (fun () ->
      Lwt.abandon_wakeups ();
      run (Mirage_runtime.run_exit_hooks ()))
