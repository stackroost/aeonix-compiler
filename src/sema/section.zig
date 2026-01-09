const std = @import("std");

/// Validates eBPF section names according to kernel requirements
/// Invalid section names will cause programs to fail at load time
pub const SectionValidator = struct {
    /// Validates a section name and returns true if valid
    pub fn isValid(section: []const u8) bool {
        // Static section names (exact match)
        const static_sections = [_][]const u8{
            // XDP Programs
            "xdp",
            "xdp/ingress",
            // TC / Traffic Control
            "tc",
            "clsact",
            // Cgroup / Socket Programs
            "cgroup_skb",
            "cgroup_sock",
            "cgroup_skb/ingress",
            "cgroup_skb/egress",
            "sockops",
            "sk_msg",
            // BPF Type Format (BTF) / Special
            "maps",
            "license",
            "version",
            // Other / Misc
            "perf_event",
        };

        // Check static sections first
        for (static_sections) |valid| {
            if (std.mem.eql(u8, section, valid)) {
                return true;
            }
        }

        // Dynamic section patterns
        // kprobe/<function> or kretprobe/<function>
        if (std.mem.startsWith(u8, section, "kprobe/") or std.mem.startsWith(u8, section, "kretprobe/")) {
            if (section.len > 7) { // At least "kprobe/" or "kretprobe/"
                const after_slash = if (std.mem.startsWith(u8, section, "kprobe/"))
                    section[7..]
                else
                    section[10..];
                // Function name should be non-empty and valid identifier
                return isValidIdentifier(after_slash);
            }
            return false;
        }

        // uprobe/<symbol> or uretprobe/<symbol>
        if (std.mem.startsWith(u8, section, "uprobe/") or std.mem.startsWith(u8, section, "uretprobe/")) {
            if (section.len > 7) { // At least "uprobe/" or "uretprobe/"
                const after_slash = if (std.mem.startsWith(u8, section, "uprobe/"))
                    section[7..]
                else
                    section[10..];
                return isValidIdentifier(after_slash);
            }
            return false;
        }

        // tracepoint/<category>/<event>
        if (std.mem.startsWith(u8, section, "tracepoint/")) {
            if (section.len > 12) { // At least "tracepoint/"
                const after_prefix = section[12..];
                // Must have format: <category>/<event>
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

    /// Checks if a string is a valid identifier (for function/symbol names)
    fn isValidIdentifier(name: []const u8) bool {
        if (name.len == 0) return false;

        // First character must be letter or underscore
        const first = name[0];
        if (!((first >= 'a' and first <= 'z') or
            (first >= 'A' and first <= 'Z') or
            first == '_'))
        {
            return false;
        }

        // Rest can be letters, digits, underscores, or dots (for qualified names)
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

    /// Returns a human-readable description of valid section formats
    pub fn getValidFormats() []const u8 {
        return 
        \\Valid eBPF section formats:
        \\  Static sections:
        \\    - xdp, xdp/ingress
        \\    - tc, clsact
        \\    - cgroup_skb, cgroup_sock, cgroup_skb/ingress, cgroup_skb/egress
        \\    - sockops, sk_msg
        \\    - maps, license, version
        \\    - perf_event
        \\  Dynamic sections:
        \\    - kprobe/<function> (e.g., kprobe/sys_execve)
        \\    - kretprobe/<function> (e.g., kretprobe/do_sys_open)
        \\    - uprobe/<symbol> (e.g., uprobe/main)
        \\    - uretprobe/<symbol> (e.g., uretprobe/main)
        \\    - tracepoint/<category>/<event> (e.g., tracepoint/syscalls/sys_enter_open)
        ;
    }
};
