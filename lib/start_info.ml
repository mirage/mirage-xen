type page = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external cmdline: unit -> string = "caml_cmdline"

external console_start_page': unit -> page = "caml_console_start_page"
let console_start_page () = Cstruct.of_bigarray @@ console_start_page' ()

external console_event_channel: unit -> int = "caml_console_event_channel"

external xenstore_start_page': unit -> page = "caml_xenstore_start_page"
let xenstore_start_page () = Cstruct.of_bigarray @@ xenstore_start_page' ()

external xenstore_event_channel: unit -> int = "caml_xenstore_event_channel"
