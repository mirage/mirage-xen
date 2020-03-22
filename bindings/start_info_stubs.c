/*
 * Copyright (c) 2012 Citrix Systems Inc
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
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

#include <xen/xen.h>
#include <mini-os/os.h>
#include <xen/hvm/params.h>
#include <mini-os/kernel.h>

CAMLprim value
caml_cmdline(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLreturn(caml_copy_string(cmdline));
}

CAMLprim value
caml_console_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  extern char console_ring_page[];
  CAMLreturn(caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT,
				1,
				console_ring_page,
				(long)PAGE_SIZE));
}

CAMLprim value
caml_console_event_channel(value v_unit)
{
  CAMLparam1(v_unit);
  uint64_t evtchn;
  if (hvm_get_parameter(HVM_PARAM_CONSOLE_EVTCHN, &evtchn))
    caml_failwith("couldn't get console event channel");
  CAMLreturn (Val_int(evtchn));
}

CAMLprim value
caml_xenstore_start_page(value v_unit)
{
  CAMLparam1(v_unit);
  uint64_t store;
  if (hvm_get_parameter(HVM_PARAM_STORE_PFN, &store))
    caml_failwith("couldn't get xenstore pfn");
  /* FIXME: map this store page somewhere */
  CAMLreturn(caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT,
				1,
				(void *)pfn_to_virt(store),
				(long)PAGE_SIZE));
}

CAMLprim value
caml_xenstore_event_channel(value v_unit)
{
  CAMLparam1(v_unit);
  uint64_t evtchn;
  if (hvm_get_parameter(HVM_PARAM_STORE_EVTCHN, &evtchn))
    caml_failwith("couldn't get xenstore event channel");
  CAMLreturn (Val_int(evtchn));
}
