| Keyword   | Purpose |
|----------|---------|
| `unit`   | Defines an eBPF program entry block (function-like) |
| `license`| Declares program license string for ELF metadata |
| `section`| Declares the eBPF attach section for the `unit` |
| `reg`    | Immutable binding (SSA-friendly; single assignment) |
| `state`  | Mutable local state (stack-backed in Stage-0) |
| `guard`  | Safety-gated conditional block (if condition true, run block) |
| `fall`   | Fallback block paired with `guard` (runs when condition is false) |
| `return` | Ends execution of the current `unit` and returns an integer result |