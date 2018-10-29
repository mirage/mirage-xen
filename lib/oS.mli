module Lifecycle : sig

val await_shutdown_request :
  ?can_poweroff:bool ->
  ?can_reboot:bool ->
  unit -> [`Poweroff | `Reboot] Lwt.t
(** [await_shutdown_request ()] is thread that resolves when the domain is
    asked to shut down.
    The optional [poweroff] (default:[true]) and [reboot] (default:[false])
    arguments can be used to indicate which features the caller wants to
    advertise (however, you can still get a request for a mode you didn't claim
    to support). *)

end

module Main : sig
val run : unit Lwt.t -> unit
val at_enter : (unit -> unit Lwt.t) -> unit
val at_enter_iter : (unit -> unit) -> unit
val at_exit_iter  : (unit -> unit) -> unit
end

module MM : sig
module Heap_pages : sig
  val total: unit -> int
  val used: unit -> int
end
end
module Time : sig

type +'a io = 'a Lwt.t

(** Timeout operations. *)

module Monotonic : sig
  (** Monotonic time is time since boot (dom0 or domU, depending on platform).
   * Unlike Clock.time, it does not go backwards when the system clock is
   * adjusted. *)

  type time_kind = [`Time | `Interval]
  type 'a t constraint 'a = [< time_kind]

  val time : unit -> [`Time] t
  (** Read the current monotonic time. *)

  val ( + ) : 'a t -> [`Interval] t -> 'a t
  val ( - ) : 'a t -> [`Interval] t -> 'a t
  val interval : [`Time] t -> [`Time] t -> [`Interval] t

  (** Conversions. Note: still seconds since boot. *)
  val of_nanoseconds : int64 -> _ t
end

val restart_threads: (unit -> [`Time] Monotonic.t) -> unit
(** [restart_threads time_fun] restarts threads that are sleeping and
    whose wakeup time is before [time_fun ()]. *)

val select_next : unit -> [`Time] Monotonic.t option
(** [select_next ()] is [Some t] where [t] is the earliest time
    when one sleeping thread will wake up, or [None] if there is no
    sleeping threads. *)

val sleep_ns : int64 -> unit Lwt.t
(** [sleep_ns d] Block the current thread for [n] nanoseconds. *)

exception Timeout
(** Exception raised by timeout operations *)

val with_timeout : int64 -> (unit -> 'a Lwt.t) -> 'a Lwt.t
(** [with_timeout d f] is a short-hand for:

    {[
    Lwt.pick [Lwt_unix.timeout d; f ()]
    ]}
*)
end

module Xs : sig
  include Xs_client_lwt.S
end

module Activations : sig
  (** Event channels handlers. *)

  type event
  (** identifies the an event notification received from xen *)

  val program_start: event
  (** represents an event which 'fired' when the program started *)

  val after: Eventchn.t -> event -> event Lwt.t
  (** [next channel event] blocks until the system receives an event
      newer than [event] on channel [channel]. If an event is received
      while we aren't looking then this will be remembered and the
      next call to [after] will immediately unblock. If the system
      is suspended and then resumed, all event channel bindings are invalidated
      and this function will fail with Generation.Invalid *)

  (** {2 Low level interface} *)

  val wait : Eventchn.t -> unit Lwt.t
  (** [wait evtchn] is a cancellable thread that will wake up when
      [evtchn] is notified. Cancel it if you are no longer interested in
      waiting on [evtchn]. Note that if the notification is sent before
      [wait] is called then the notification is lost. *)

  val run : Eventchn.handle -> unit
  (** [run ()] goes through the event mask and activate any events,
      potentially spawning new threads. This function is called by
      [Main.run]. Do not call it unless you know what you are doing. *)

  val resume : unit -> unit
  (** [resume] needs to be called after the unikernel is
      resumed. However, this function is automatically called by
      {!Sched.suspend}. Do NOT use it unless you know what you are
      doing. *)

  val dump : unit -> unit
  (** [dump ()] prints internal state to the console for debugging *)
end

module Device_state : sig
  type state =
      Unknown
    | Initialising
    | InitWait
    | Initialised
    | Connected
    | Closing
    | Closed
    | Reconfiguring
    | Reconfigured
  val of_string : string -> state
  val to_string : state -> string
  val prettyprint : state -> string
end

module Sched : sig
  (** Xen scheduler operations. *)

  (** Type of the argument of function [shutdown]. *)
  type reason =
    | Poweroff
    | Reboot
    | Suspend
    | Crash

  val add_resume_hook : (unit -> unit Lwt.t) -> unit
  (** [add_resume_hook f] adds [f] in the list of functions to be called
      on resume. *)

  val shutdown: reason -> unit
  (** [shutdown reason] informs Xen that the unikernel has shutdown. The
      [reason] argument indicates the type of shutdown (according to
      this type and the configuration of the unikernel, Xen might
      restart the unikernel or not). To suspend, do a [shutdown Suspend]
      is not enough, use the function below instead. *)

  val suspend: unit -> int Lwt.t
  (** [suspend ()] suspends the unikernel and returns [0] after
      the kernel has been resumed, in case of success, or
      immediately returns a non-zero value in case of error. *)
end

module Start_info : sig
  (** Get the start info page. *)

  type t = {
    magic: string; (** "xen-<version>-<platform>". *)
    nr_pages: int; (** Total pages allocated to this domain. *)
    shared_info: int; (** MACHINE address of shared info struct. *)
    flags: int; (** SIF_xxx flags. *)
    store_mfn: int; (** MACHINE page number of the shared page used for communication with the XenStore. *)
    store_evtchn: int; (** Event channel for communication with the XenStore. *)
    console_mfn: int; (** MACHINE page number of console page. *)
    console_evtchn: int; (** Event channel for console page. *)

    (** THE FOLLOWING ARE ONLY FILLED IN ON INITIAL BOOT (NOT RESUME). *)
    pt_base: int; (** VIRTUAL address of page directory. *)
    nr_pt_frames: int; (** Number of bootstrap p.t. frames. *)
    mfn_list: int; (** VIRTUAL address of page-frame list. *)
    mod_start: int; (** VIRTUAL address of pre-loaded module. *)
    mod_len: int; (** Size (bytes) of pre-loaded module. *)
    cmd_line: string; (** Command-line arguments passed to the unikernel. *)
    first_p2m_pfn: int; (** 1st pfn forming initial P->M table. *)
    nr_p2m_frames: int (** # of pfns forming initial P->M table. *)
  }

  val get: unit -> t
  (** [get ()] is the record containing the start info page. *)

  val console_start_page: unit -> Cstruct.t
  (** [console_start_page ()] is the console page automatically
      allocated by Xen. *)

  val xenstore_start_page: unit -> Cstruct.t
  (** [xenstore_start_page ()] is the xenstore page automatically
      allocated by Xen. *)
end

module Xen : sig
  (** Some more Xen-specific that is neither part of scheduling
      nor startup info, and not tied to xenstore either. *)

  val virt_to_mfn : nativeint -> nativeint
  (** Convert a Xen virtual addr ["va"] to [MFN]
    - This is a binding to Xen mini-os [virt_to_mfn()];
    - The inverse function in minios is [__mfn_to_virt].
    - example use: [OS.MM.virt_to_mfn (Io_page.get_addr your_io_page_t)]
    - see https://xenbits.xen.org/docs/xtf/mm_8h_source.html
      and https://wiki.xenproject.org/wiki/XenTerminology *)
end
