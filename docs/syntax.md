# Aeonix Syntax Documentation

## 1. Program Structure

An Aeonix program consists of units.

A unit is an executable function and also serves as a program entry point.

### Entry Point

```aeonix
unit main() {
}
```

### Rules

- `unit main()` is the default entry point
- A program may contain multiple unit blocks
- Execution always starts from main

## 2. Keyword: unit

### Purpose

Defines a function-like execution block.

### Syntax

```aeonix
unit <name>(<parameters>) {
    <statements>
}
```

### Example

```aeonix
unit greet() {
    emitln "hello kernel"
}
```

### Design Notes

- `unit` replaces traditional `fn`, `function`, or `def`
- Treated as a compile-time symbol
- No return value in v0
- Parameters are reserved for future versions

## 3. Keyword: emitln

### Purpose

Outputs a line to the standard console.

### Syntax

```aeonix
emitln <expression>
```

### Example

```aeonix
emitln "hello kernel"
emitln 123
```

### Behavior

- Appends a newline after output
- Accepts literals and expressions
- Internally maps to a direct syscall (write)

## 4. Keyword: reg

### Purpose

Defines an immutable binding, conceptually equivalent to a CPU or eBPF register.

### Characteristics

- Immutable after assignment
- SSA-friendly (single assignment)
- Optimized by the compiler
- Maps naturally to IR registers and eBPF r0–r9

### Syntax

```aeonix
reg <name> = <expression>
```

### Example

```aeonix
reg pid = syscall.pid
reg msg = "hello kernel"

emitln pid
emitln msg
```

**Note:** Reassignment is not allowed:

```aeonix
reg x = 1
x = 2    // compile-time error
```

## 5. Keyword: state

### Purpose

Defines mutable kernel state, representing memory-backed values.

### Characteristics

- Mutable after assignment
- Stored in stack, map, or heap (backend dependent)
- Explicit opt-in mutability
- Designed to be eBPF verifier-friendly

### Syntax

```aeonix
state <name> = <expression>
```

### Example

```aeonix
state counter = 0

counter = counter + 1
emitln counter
```

## 6. Keyword: guard

### Purpose

Defines a safety gate. Execution is allowed to proceed only if the condition is valid. A guard is not a logic statement—it is a validation boundary. If the guard fails, execution does not enter the block. Think: "Permit execution only if this state is safe."

### Syntax

```aeonix
guard <condition> {
    <statements>
}
```

### Example

```aeonix
unit main() {
    reg fd = syscall.open("/etc/passwd")

    guard fd > 0 {
        emitln "file opened"
    }
}
```

### Semantics

- `<condition>` must evaluate to boolean
- If condition is true → block executes
- If condition is false → block is skipped
- No implicit fallback or else in v0

## 7. Keyword: fall

### Purpose

Defines the fallback execution path when a preceding guard does not pass. This models branch fall-through in CPU pipelines and kernel control flow.

### Mental Model (System-Level)

- `guard` → validation gate
- `fall` → failure / alternate execution path
- No "logic language", only execution paths
- Think: "If the guard is not taken, execution falls here."

### Syntax

```aeonix
guard <condition> {
    <statements>
} fall {
    <statements>
}
```

### Example

```aeonix
unit main() {
    reg fd = syscall.open("/etc/passwd")

    guard fd > 0 {
        emitln "file opened"
    } fall {
        emitln "open failed"
    }
}
```

### Semantics

- `fall` must directly follow a `guard`
- Executed only if the guard condition is false
- Exactly one `fall` per `guard`
- No chaining in v0

## 8. Keyword: loop

### Purpose

Defines a controlled execution cycle. It represents repeated execution without exposing high-level iteration semantics. This mirrors CPU execution cycles, kernel polling loops, and eBPF verifier-safe bounded loops.

### Mental Model (System-Level)

- `loop` is not "iterate over data"
- It is repeat execution while a condition holds
- Condition checked at the entry point, like a branch-back jump
- Think: "Execute this block while execution is permitted."

### Syntax

```aeonix
loop <condition> {
    <statements>
}
```

### Example

```aeonix
unit main() {
    state i = 0

    loop i < 3 {
        emitln i
        i = i + 1
    }
}
```

### Semantics

- `<condition>` must evaluate to boolean
- Condition evaluated before each iteration
- Loop exits when condition becomes false
- No implicit infinite loops in v0

## 9. Keyword: halt

### Purpose

Terminates the current loop immediately. It represents a hard stop in execution flow, similar to loop break in compilers, early exit in kernel paths, and abort of repetitive execution.

### Mental Model (System-Level)

- `halt` stops the execution cycle
- Control exits the nearest enclosing loop
- No condition, no arguments
- Think: "Stop this execution path now."

### Syntax

```aeonix
halt
```

### Example

```aeonix
unit main() {
    state i = 0

    loop i < 5 {
        guard i == 3 {
            halt
        }
        emitln i
        i = i + 1
    }
}
```

### Semantics

- Valid only inside a loop
- Exits the nearest loop block
- Execution continues after the loop
- Compile-time error if used outside a loop

## 10. Keyword: skip

### Purpose

Abandons the current loop iteration and continues with the next execution cycle. It represents a forward jump to the loop condition, matching low-level control flow.

### Mental Model (System-Level)

- `skip` does not end the loop
- It immediately jumps to the next iteration
- No conditions, no expressions
- Think: "Ignore the rest of this cycle and advance execution."

### Syntax

```aeonix
skip
```

### Example

```aeonix
unit main() {
    state i = 0

    loop i < 5 {
        i = i + 1
        guard i == 3 {
            skip
        }
        emitln i
    }
}
```

### Semantics

- Valid only inside a loop
- Skips remaining statements in the current iteration
- Control resumes at the loop condition
- Compile-time error if used outside a loop
## 11. Keyword: next

### Purpose

Abandons the current execution path inside a loop and jumps directly to the next scheduling cycle.

This mirrors:

Kernel schedulers (next task)

Netfilter pipelines (goto next)

BPF program tail-jump mentality

### Mental Model (System-Level)

next = advance execution

Does not stop the loop

Does not evaluate remaining statements

Think:

"Move to the next execution slot."

### Syntax

next

### Example

unit main() {
    state i = 0

    loop i < 5 {
        i = i + 1

        guard i == 3 {
            next
        }

        emitln i
    }
}

### Semantics

Valid only inside loop

Jumps to the loop condition

No arguments allowed

Compile-time error outside loop
## 12. Keyword: exit

### Purpose

exit terminates execution of the current unit immediately.

This maps directly to:

Linux exit / exit_group

Process termination

End of execution path

### Mental Model (System-Level)

exit is not a language feature

It is an execution boundary

Once called, no further instructions run

Think:

"End this execution context now."

### Syntax

exit

### Example

unit main() {
    emitln "starting"

    guard syscall.pid == 0 {
        emitln "kernel context"
        exit
    }

    emitln "user context"
}

### Semantics

Terminates the current unit

No return values in v0

Control does not continue past exit

Valid anywhere inside a unit
## 13. Keyword: dispatch

### Purpose

dispatch routes execution to a specific path based on a selector value.

This models:

Kernel demultiplexing

Syscall routing

eBPF tail-call style branching

### Mental Model (System-Level)

dispatch is not high-level pattern matching

It is a branch table

One input → one execution path

Think:

"Route execution to the correct handler."

### Syntax

dispatch <expression> {
    <label> => { <statements> }
}

### Example

unit main() {
    reg op = syscall.number

    dispatch op {
        open  => { emitln "open syscall" }
        read  => { emitln "read syscall" }
        write => { emitln "write syscall" }
    }
}

### Semantics

<expression> evaluated once

Exactly one matching branch executes

No implicit fallthrough

No default branch in v0
## 14. Keyword: spawn

### Purpose

spawn creates a new execution context (process or task), separate from the current unit.

This directly reflects:

Linux process creation

Kernel task spawning

Userspace helpers started from system tools

### Mental Model (System-Level)

spawn is not a function call

It is a kernel action

Execution continues independently

Think:

"Create a new task and let it run."

### Syntax

spawn <expression>

### Example

unit main() {
    emitln "parent"

    spawn "/bin/ls"

    emitln "parent continues"
}

### Semantics

Launches a new process or task

Does not block the current unit

No return value in v0

Failure handling will be added later
## 15. Keyword: link

### Purpose

Attach another compilation unit / module at link time.

This models:

object files

kernel symbol linking

static resolution

### Mental Model (System-Level)

Think:

"Link in external modules for static resolution."

### Syntax

link <module>

### Example

link fs

unit main() {
    reg fd = fs.open("/etc/passwd")
    emitln fd
}

### Semantics

Attaches module at link time

Enables access to module's symbols

Static resolution

No runtime loading in v0
## 16. Keyword: expose

### Purpose

Expose a symbol to the linker boundary so other units can bind to it.

This models:

symbol visibility

kernel exported symbols

shared object interfaces

### Mental Model (System-Level)

Think:

"Make this unit visible to other modules."

### Syntax

expose unit <name>() {
    <statements>
}

### Example

expose unit add() {
    emitln "add called"
}

Used from another file:

link math

math.add()

### Semantics

Makes the unit accessible from linked modules

Symbol exported at link time

Enables inter-module calls

No runtime dynamic linking in v0