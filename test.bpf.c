#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 8);
    __type(key, __u32);
    __type(value, __u64);
} results SEC(".maps");

char LICENSE[] SEC("license") = "GPL";

SEC("tracepoint/syscalls/sys_enter_execve")
int t4_null_deref(void *ctx) {
    (void)ctx;
    __u64 v0 = 0;
    __u64 *v1 = 0;
    __u64 v2 = 0;
    __u64 v3 = 0;
    v0 = 100 + 0;
    v1 = bpf_map_lookup_elem(&results, &v0);
    if (v1) {
        *v1 = 1;
    }
    return 0;
}
