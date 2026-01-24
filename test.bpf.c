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
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 8);
    __type(key, __u32);
    __type(value, __u64);
} results SEC(".maps");

char LICENSE[] SEC("license") = "GPL";

SEC("tracepoint/syscalls/sys_enter_execve")
int tp_execve_vars(void *ctx) {
    (void)ctx;
    __u64 v0 = 0;
    __u64 v1 = 0;
    __u64 v3 = 0;
    __u64 v2 = 0;
    __u64 v5 = 0;
    __u64 v4 = 0;
    __u64 v7 = 0;
    __u64 v6 = 0;
    __u64 v9 = 0;
    __u64 v8 = 0;
    __u64 v11 = 0;
    __u64 v10 = 0;
    __u64 v12 = 0;
    __u64 *v13 = 0;
    __u64 v14 = 0;
    __u64 v15 = 0;
    __u64 v16 = 0;
    __u64 *v17 = 0;
    __u64 v18 = 0;
    __u64 v19 = 0;
    __u64 v20 = 0;
    __u64 *v21 = 0;
    __u64 v22 = 0;
    __u64 v23 = 0;
    __u64 v24 = 0;
    __u64 *v25 = 0;
    __u64 v26 = 0;
    __u64 v27 = 0;
    __u64 v28 = 0;
    __u64 *v29 = 0;
    __u64 v30 = 0;
    __u64 v31 = 0;
    v0 = 10 + 0;
    v1 = 20 + 0;
    v3 = v0 + v1;
    v2 = v3 + 0;
    v5 = v1 - v0;
    v4 = v5 + 0;
    v7 = v0 * v1;
    v6 = v7 + 0;
    v9 = v1 / v0;
    v8 = v9 + 0;
    v11 = v1 % v0;
    v10 = v11 + 0;
    v12 = 0 + 0;
    v13 = bpf_map_lookup_elem(&results, &v12);
    if (v13) {
        *v13 = v2;
    }
    v16 = 1 + 0;
    v17 = bpf_map_lookup_elem(&results, &v16);
    if (v17) {
        *v17 = v4;
    }
    v20 = 2 + 0;
    v21 = bpf_map_lookup_elem(&results, &v20);
    if (v21) {
        *v21 = v6;
    }
    v24 = 3 + 0;
    v25 = bpf_map_lookup_elem(&results, &v24);
    if (v25) {
        *v25 = v8;
    }
    v28 = 4 + 0;
    v29 = bpf_map_lookup_elem(&results, &v28);
    if (v29) {
        *v29 = v10;
    }
    return 0;
}
