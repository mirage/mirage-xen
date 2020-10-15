module Heap_pages = struct
  external total: unit -> int = "mirage_xen_heap_get_pages_total" [@@noalloc]
  external used: unit -> int = "mirage_xen_heap_get_pages_used" [@@noalloc]
end
