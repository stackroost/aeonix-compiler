#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#ifndef TC_ACT_OK
#define TC_ACT_OK 0
#define TC_ACT_SHOT 2
#define TC_ACT_UNSPEC -1
#endif
#ifndef XDP_ABORTED
#define XDP_ABORTED 0
#define XDP_DROP 1
#define XDP_PASS 2
#define XDP_TX 3
#define XDP_REDIRECT 4
#endif

#ifndef SK_PASS
#define SK_PASS 1
#define SK_DROP 0
#endif

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, __u32);
    __type(value, __u64);
} connection_counter SEC(".maps");

char LICENSE[] SEC("license") = "GPL";

SEC("sk_msg")
int pass_all_traffic(struct sk_msg_md *msg) {
    return SK_PASS;
}

