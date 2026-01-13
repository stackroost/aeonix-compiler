const std = @import("std");

pub const SectionValidator = struct {
    pub fn isValid(section: []const u8) bool {
        const static_sections = [_][]const u8{
            "xdp",
            "xdp/ingress",
            "xdp/frags",
            "xdp/devmap",
            "xdp/cpumap",
            "xdp/offload",
            "xdp/egress",

            "tc",
            "classifier",
            "action",
            "tcx/ingress",
            "tcx/egress",
            "tc/ingress",
            "tc/egress",
            
            "cgroup_skb",
            "cgroup_sock",
            "cgroup_skb/ingress",
            "cgroup_skb/egress",
            "sockops",
            "sk_msg",

            "maps",
            "license",
            "version",

            // Misc
            "perf_event",
        };

        for (static_sections) |valid| {
            if (std.mem.eql(u8, section, valid)) return true;
        }

        if (std.mem.startsWith(u8, section, "tc/")) {
            const extras = section["tc/".len..];
            return extras.len > 0 and isValidTcExtras(extras);
        }
        if (std.mem.startsWith(u8, section, "classifier/")) {
            const extras = section["classifier/".len..];
            return extras.len > 0 and isValidTcExtras(extras);
        }
        if (std.mem.startsWith(u8, section, "action/")) {
            const extras = section["action/".len..];
            return extras.len > 0 and isValidTcExtras(extras);
        }
        if (std.mem.startsWith(u8, section, "kprobe/") or std.mem.startsWith(u8, section, "kretprobe/")) {
            if (section.len > 7) {
                const after_slash = if (std.mem.startsWith(u8, section, "kprobe/"))
                    section[7..]
                else
                    section[10..];
                return isValidIdentifier(after_slash);
            }
            return false;
        }
        if (std.mem.startsWith(u8, section, "uprobe/") or std.mem.startsWith(u8, section, "uretprobe/")) {
            if (section.len > 7) {
                const after_slash = if (std.mem.startsWith(u8, section, "uprobe/"))
                    section[7..]
                else
                    section[10..];
                return isValidIdentifier(after_slash);
            }
            return false;
        }
        if (std.mem.startsWith(u8, section, "tracepoint/")) {
            if (section.len > 12) {
                const after_prefix = section[12..];
                if (std.mem.indexOfScalar(u8, after_prefix, '/')) |slash_pos| {
                    if (slash_pos > 0 and slash_pos < after_prefix.len - 1) {
                        const category = after_prefix[0..slash_pos];
                        const event = after_prefix[slash_pos + 1 ..];
                        return isValidIdentifier(category) and isValidIdentifier(event);
                    }
                }
            }
            return false;
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
        if (!((first >= 'a' and first <= 'z') or
            (first >= 'A' and first <= 'Z') or
            first == '_'))
        {
            return false;
        }

        for (name[1..]) |ch| {
            if (!((ch >= 'a' and ch <= 'z') or
                (ch >= 'A' and ch <= 'Z') or
                (ch >= '0' and ch <= '9') or
                ch == '_' or
                ch == '.'))
            {
                return false;
            }
        }

        return true;
    }

    pub fn getValidFormats() []const u8 {
        return 
        \\Valid eBPF section formats (selected):
        \\  TC:
        \\    - tc, classifier, action
        \\    - tc/<extras>, classifier/<extras>, action/<extras>
        \\    - tcx/ingress, tcx/egress (recommended)
        \\    - tc/ingress, tc/egress
        \\  Other:
        \\    - xdp, xdp/ingress
        \\    - cgroup_skb(/ingress|/egress), cgroup_sock, sockops, sk_msg
        \\    - maps, license, version, perf_event
        \\    - kprobe/<fn>, kretprobe/<fn>, uprobe/<sym>, uretprobe/<sym>
        \\    - tracepoint/<category>/<event>
        ;
    }
};
