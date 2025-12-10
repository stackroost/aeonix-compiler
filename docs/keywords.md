# Aeonix Keywords

| Keyword | Purpose |
|---------|---------|
| unit    | Define executable unit |
| emitln  | Print line to console |
| reg     | Immutable binding (SSA-friendly) |
| state   | Mutable kernel state |
| guard   | Defines a safety gate |
| fall    | Defines fallback execution path |
| loop    | Defines a controlled execution cycle |
| halt    | Terminates the current loop immediately |
| skip    | Abandons the current loop iteration |
| next    | Abandons the current execution path inside a loop and jumps directly to the next scheduling cycle |
| exit    | Terminates execution of the current unit immediately |
| dispatch| Routes execution to a specific path based on a selector value |
| spawn   | Creates a new execution context (process or task), separate from the current unit |
| link    | Attach another compilation unit / module at link time |
| expose  | Expose a symbol to the linker boundary so other units can bind to it |