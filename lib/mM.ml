module Heap = struct
  external total_bytes: unit -> int64 =
      "mirage_xen_get_heap_total_bytes" [@@noalloc]

  external allocated_bytes: unit -> int64 =
      "mirage_xen_get_heap_allocated_bytes" [@@noalloc]
end
