val cmdline : unit -> string
(** [cmdline ()] returns the command-line arguments passed to the unikernel at
    boot time. *)

val console_start_page: unit -> Cstruct.t
(** [console_start_page ()] is the console page automatically
    allocated by Xen. *)

val console_event_channel: unit -> int
(** [console_event_channel ()] is the int to pass to Eventchn.of_int for the
    console event channel. *)

val xenstore_start_page: unit -> Cstruct.t
(** [xenstore_start_page ()] is the xenstore page automatically
    allocated by Xen. *)

val xenstore_event_channel: unit -> int
(** xenstore_event_channel ()] is the int to pass to Eventchn.of_int for the
    xenstore event channel. *)
