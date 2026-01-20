#![no_std]
#![no_main]

use core::ptr;
use core::ffi::c_void;

extern "C" {
    fn bpf_map_lookup_elem(map: *const core::ffi::c_void, key: *const core::ffi::c_void) -> *mut core::ffi::c_void;
}

#[repr(C)]
pub struct BpfMap {
    pub map_type: u32,
    pub key_size: u32,
    pub value_size: u32,
    pub max_entries: u32,
}

#[link_section = ".maps"]
#[no_mangle]
pub static connection_counter: BpfMap = BpfMap { map_type: 1, key_size: 4, value_size: 8, max_entries: 1024 };

#[link_section = "license"]
#[no_mangle]
static LICENSE: &[u8] = b"GPL";

#[repr(C)]
pub struct xdp_md {
    pub data: u32,
    pub data_end: u32,
}

#[link_section = "xdp"]
#[no_mangle]
pub fn filter_packets(ctx: *mut xdp_md) -> i32 {
    unsafe {
        let data = (*ctx).data;
        let data_end = (*ctx).data_end;
        if data + 30 > data_end { return 0; }
        let src_ip = ptr::read((data + 26) as *const u32);
        let key = src_ip;
        let count_ptr = bpf_map_lookup_elem(&connection_counter as *const _ as *const c_void, &key as *const _ as *const u8) as *mut u64;
        if !count_ptr.is_null() {
            *count_ptr += 1;
        }
        1
    }
}
