## unit
Defines an eBPF program entry function (compiled into a BPF program section).
```solnix
unit xdp_pass(ctx) section("xdp") { return 2; }
```

## section
Declares where the program attaches (XDP, kprobe, tracepoint, tc, etc.).
```solnix
unit on_open(ctx) section("kprobe/__x64_sys_openat") { return 0; }
```

## reg
Immutable value binding (single assignment; compiler-friendly SSA).
```solnix
unit demo(ctx) section("xdp") { reg a = 1; return a; }
```

## state
Mutable local state (stack-backed; allows reassignment).
```solnix
unit demo(ctx) section("xdp") { state c = 0; c = c + 1; return c; }
```

## guard
Executes block only if the condition is true (safety gate).
```solnix
unit demo(ctx) section("xdp") { reg ok = 1; guard ok == 1 { return 2; } return 1; }
```

## fall
Fallback block that runs only when the preceding guard condition is false.
```solnix
unit demo(ctx) section("xdp") { reg ok = 0; guard ok == 1 { return 2; } fall { return 1; } }
```

## return
Ends execution of the unit and returns an integer result (lowered to eBPF r0 + exit).
```solnix
unit demo(ctx) section("xdp") { return 2; }
```