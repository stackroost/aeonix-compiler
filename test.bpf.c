#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#ifndef XDP_ABORTED
#define XDP_ABORTED 0
#define XDP_DROP 1
#define XDP_PASS 2
#define XDP_TX 3
#define XDP_REDIRECT 4
#endif

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, __u32);
    __type(value, __u64);
} connection_counter SEC(".maps");

char LICENSE[] SEC("license") = "GPL";

SEC("xdp")
int filter_packets(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    if (data + 26 + 4 > data_end) return XDP_PASS;
    __u32 src_ip = *(__u32 *)(data + 26);

    __u32 key = src_ip;
    __u64 *count_ptr = bpf_map_lookup_elem(&connection_counter, &key);
    if (count_ptr) {
        __sync_fetch_and_add(count_ptr, 1);
    }

    return 1;
}

