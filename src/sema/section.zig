const std = @import("std");

pub const SectionValidator = struct {
    pub fn isValid(section: []const u8) bool {
        const static_sections = [_][]const u8{            
            "xdp", "xdp/ingress", "xdp/frags", "xdp/devmap", 
            "xdp/cpumap", "xdp/offload", "xdp/egress",
            
            "tc", "classifier", "action", 
            "tcx/ingress", "tcx/egress", 
            "tc/ingress", "tc/egress",
            
            "tracepoint", "tp", "raw_tracepoint", "raw_tp", "tp_btf",
            
            "cgroup_skb", "cgroup_sock", "cgroup_skb/ingress", 
            "cgroup_skb/egress", "sockops", "sk_msg",

            "maps", "license", "version", "perf_event",
        };
        
        for (static_sections) |valid| {
            if (std.mem.eql(u8, section, valid)) return true;
        }        
        if (std.mem.startsWith(u8, section, "tracepoint/") or std.mem.startsWith(u8, section, "tp/")) {
            const path = if (std.mem.startsWith(u8, section, "tp/")) section[3..] else section[11..];
            if (std.mem.indexOfScalar(u8, path, '/')) |slash_pos| {
                const category = path[0..slash_pos];
                const event = path[slash_pos + 1 ..];
                return isValidIdentifier(category) and isValidIdentifier(event);
            }
            return false;
        }
        if (std.mem.startsWith(u8, section, "raw_tracepoint/") or std.mem.startsWith(u8, section, "raw_tp/")) {
            const event = if (std.mem.startsWith(u8, section, "raw_tp/")) section[7..] else section[15..];
            return isValidIdentifier(event);
        }
        if (std.mem.startsWith(u8, section, "tp_btf/")) {
            return isValidIdentifier(section[7..]);
        }
        if (std.mem.startsWith(u8, section, "kprobe/") or std.mem.startsWith(u8, section, "kretprobe/")) {
            const func = if (std.mem.startsWith(u8, section, "kprobe/")) section[7..] else section[10..];
            return isValidIdentifier(func);
        }
        if (std.mem.startsWith(u8, section, "uprobe/") or std.mem.startsWith(u8, section, "uretprobe/")) {
            const sym = if (std.mem.startsWith(u8, section, "uprobe/")) section[7..] else section[10..];
            return isValidIdentifier(sym);
        }
        if (std.mem.startsWith(u8, section, "tc/")) {
            return isValidTcExtras(section[3..]);
        }
        if (std.mem.startsWith(u8, section, "classifier/")) {
            return isValidTcExtras(section[11..]);
        }
        if (std.mem.startsWith(u8, section, "action/")) {
            return isValidTcExtras(section[7..]);
        }

        return false;
    }

    fn isValidTcExtras(extras: []const u8) bool {
        if (extras.len == 0) return false;
        if (std.mem.eql(u8, extras, "ingress") or std.mem.eql(u8, extras, "egress")) return true;
        for (extras) |ch| {
            const ok =
                (ch >= 'a' and ch <= 'z') or
                (ch >= 'A' and ch <= 'Z') or
                (ch >= '0' and ch <= '9') or
                ch == '_' or ch == '.' or ch == '-';
            if (!ok) return false;
        }
        return true;
    }

    fn isValidIdentifier(name: []const u8) bool {
        if (name.len == 0) return false;
        const first = name[0];
        if (!((first >= 'a' and first <= 'z') or (first >= 'A' and first <= 'Z') or first == '_')) return false;

        for (name[1..]) |ch| {
            if (!((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '_' or ch == '.')) {
                return false;
            }
        }
        return true;
    }

    pub fn getValidFormats() []const u8 {
        return 
        \\Valid eBPF section formats:
        \\  Networking:
        \\    - xdp, xdp/ingress, xdp/egress, xdp/frags...
        \\    - tc, tcx/ingress, tcx/egress, classifier, action
        \\  Tracepoints (Static):
        \\    - tracepoint/<cat>/<event> (or tp/<cat>/<event>)
        \\    - raw_tracepoint/<event>   (or raw_tp/<event>)
        \\    - tp_btf/<event>           (Modern/Fast)
        \\  Probes (Dynamic):
        \\    - kprobe/<func>, kretprobe/<func>
        \\    - uprobe/<sym>, uretprobe/<sym>
        \\  Infrastructure:
        \\    - maps, license, version
        ;
    }
};