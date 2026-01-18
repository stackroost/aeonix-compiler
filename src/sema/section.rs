// src/sema/section.rs
use once_cell::sync::Lazy;
use regex::Regex;

/// Static list of valid eBPF section names
const STATIC_SECTIONS: &[&str] = &[
    // XDP
    "xdp", "xdp/ingress", "xdp/egress", "xdp/frags", "xdp/devmap", "xdp/cpumap", "xdp/offload",
    
    // TC (Traffic Control)
    "tc", "classifier", "action", "tcx/ingress", "tcx/egress", "tc/ingress", "tc/egress",
    
    // Tracepoints
    "tracepoint", "tp", "raw_tracepoint", "raw_tp", "tp_btf",
    
    // Cgroup
    "cgroup_skb", "cgroup_sock", "cgroup_skb/ingress", "cgroup_skb/egress", "sockops", "sk_msg",
    
    // Infrastructure
    "maps", "license", "version", "perf_event",
];

/// Section validator for eBPF program types
pub struct SectionValidator;

impl SectionValidator {
    /// Check if a section name is valid for eBPF
    pub fn is_valid(section: &str) -> bool {
        // Check static sections first
        if STATIC_SECTIONS.contains(&section) {
            return true;
        }

        // Tracepoint patterns
        if section.starts_with("tracepoint/") || section.starts_with("tp/") {
            let path = section.strip_prefix("tp/")
                .or_else(|| section.strip_prefix("tracepoint/"))
                .unwrap();
            
            let parts: Vec<&str> = path.split('/').collect();
            return parts.len() == 2 
                && Self::is_valid_identifier(parts[0]) 
                && Self::is_valid_identifier(parts[1]);
        }

        // Raw tracepoint
        if section.starts_with("raw_tracepoint/") || section.starts_with("raw_tp/") {
            let event = section.strip_prefix("raw_tp/")
                .or_else(|| section.strip_prefix("raw_tracepoint/"))
                .unwrap();
            return Self::is_valid_identifier(event);
        }

        // TP BTF
        if section.starts_with("tp_btf/") {
            return Self::is_valid_identifier(&section[7..]);
        }

        // Kprobes
        if section.starts_with("kprobe/") || section.starts_with("kretprobe/") {
            let func = section.strip_prefix("kprobe/")
                .or_else(|| section.strip_prefix("kretprobe/"))
                .unwrap();
            return Self::is_valid_identifier(func);
        }

        // Uprobes
        if section.starts_with("uprobe/") || section.starts_with("uretprobe/") {
            let sym = section.strip_prefix("uprobe/")
                .or_else(|| section.strip_prefix("uretprobe/"))
                .unwrap();
            return Self::is_valid_identifier(sym);
        }

        // TC extras
        if section.starts_with("tc/") || section.starts_with("classifier/") || section.starts_with("action/") {
            let extras = section.strip_prefix("tc/")
                .or_else(|| section.strip_prefix("classifier/"))
                .or_else(|| section.strip_prefix("action/"))
                .unwrap();
            
            if extras.is_empty() {
                return false;
            }
            if extras == "ingress" || extras == "egress" {
                return true;
            }
            // Allow alphanumeric + _ . - for custom TC sections
            return Self::is_valid_tc_extras(extras);
        }

        false
    }

    fn is_valid_tc_extras(extras: &str) -> bool {
        extras.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '.' || c == '-')
    }

    fn is_valid_identifier(name: &str) -> bool {
        if name.is_empty() {
            return false;
        }
        
        let mut chars = name.chars();
        let first = chars.next().unwrap();
        if !first.is_alphabetic() && first != '_' {
            return false;
        }

        chars.all(|c| c.is_alphanumeric() || c == '_' || c == '.')
    }

    /// Returns help text for valid section formats
    pub fn valid_formats() -> &'static str {
        r#"Valid eBPF section formats:
  Networking:
    - xdp, xdp/ingress, xdp/egress, xdp/frags...
    - tc, tcx/ingress, tcx/egress, classifier, action
  Tracepoints (Static):
    - tracepoint/<cat>/<event> (or tp/<cat>/<event>)
    - raw_tracepoint/<event>   (or raw_tp/<event>)
    - tp_btf/<event>           (Modern/Fast)
  Probes (Dynamic):
    - kprobe/<func>, kretprobe/<func>
    - uprobe/<sym>, uretprobe/<sym>
  Infrastructure:
    - maps, license, version
"#
    }
}