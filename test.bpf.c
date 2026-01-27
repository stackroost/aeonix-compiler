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
int sample_tracepoint(void *ctx) {
    (void)ctx;
    __u64 v0 = 0;
    __u64 v1 = 0;
    __u64 v3 = 0;
    __u64 v2 = 0;
    __u64 v4 = 0;
    __u64 *v5 = 0;
    __u64 v6 = 0;
    __u64 v7 = 0;
    v0 = 10 + 0;
    v1 = 20 + 0;
    v3 = v0 + v1;
    v2 = v3 + 0;
    v4 = 0 + 0;
    v5 = bpf_map_lookup_elem(&results, &v4);
    if (v5) {
        *v5 = v2;
    }
    return 0;
}
