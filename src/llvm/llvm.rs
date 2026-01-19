#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]
#![allow(dead_code)]

extern "C" {
    pub fn LLVMInitializeBPFTarget();
    pub fn LLVMInitializeBPFTargetInfo();
    pub fn LLVMInitializeBPFTargetMC();
    pub fn LLVMInitializeBPFAsmPrinter();
    pub fn LLVMInitializeBPFAsmParser();
    pub fn LLVMInitializeBPFDisassembler();
    pub fn LLVMContextCreate() -> *mut std::ffi::c_void;
    pub fn LLVMModuleCreateWithName(name: *const i8) -> *mut std::ffi::c_void;
    pub fn LLVMInt32TypeInContext(ctx: *mut std::ffi::c_void) -> *mut std::ffi::c_void;
    pub fn LLVMInt8TypeInContext(ctx: *mut std::ffi::c_void) -> *mut std::ffi::c_void;
    pub fn LLVMPointerType(t: *mut std::ffi::c_void, addr: u32) -> *mut std::ffi::c_void;
    pub fn LLVMFunctionType(
        ret: *mut std::ffi::c_void,
        args: *mut *mut std::ffi::c_void,
        count: u32,
        var: i32,
    ) -> *mut std::ffi::c_void;
    pub fn LLVMAddFunction(
        m: *mut std::ffi::c_void,
        name: *const i8,
        ty: *mut std::ffi::c_void,
    ) -> *mut std::ffi::c_void;
    pub fn LLVMAppendBasicBlock(
        f: *mut std::ffi::c_void,
        name: *const i8,
    ) -> *mut std::ffi::c_void;
    pub fn LLVMCreateBuilder() -> *mut std::ffi::c_void;
    pub fn LLVMPositionBuilderAtEnd(b: *mut std::ffi::c_void, bb: *mut std::ffi::c_void);
    pub fn LLVMBuildRet(b: *mut std::ffi::c_void, v: *mut std::ffi::c_void);
    pub fn LLVMConstInt(t: *mut std::ffi::c_void, v: u64, sign: i32) -> *mut std::ffi::c_void;
    pub fn LLVMSetTarget(m: *mut std::ffi::c_void, triple: *const i8);
    pub fn LLVMGetTargetFromTriple(
        triple: *const i8,
        target: *mut *mut std::ffi::c_void,
        err: *mut *mut i8,
    );
    pub fn LLVMCreateTargetMachine(
        target: *mut std::ffi::c_void,
        triple: *const i8,
        cpu: *const i8,
        features: *const i8,
        opt: i32,
        reloc: i32,
        model: i32,
    ) -> *mut std::ffi::c_void;
    pub fn LLVMTargetMachineEmitToFile(
        tm: *mut std::ffi::c_void,
        m: *mut std::ffi::c_void,
        filename: *mut i8,
        filetype: i32,
        err: *mut *mut i8,
    ) -> i32;
}
