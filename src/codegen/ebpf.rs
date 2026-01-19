use std::ffi::CString;
use std::path::Path;
use std::ptr;

use llvm_sys::target_machine::{
    LLVMCodeGenOptLevel, LLVMRelocMode, LLVMCodeModel, LLVMCodeGenFileType,
};
use crate::llvm::*;

fn c(s: &str) -> CString {
    CString::new(s).unwrap()
}

pub fn emit_minimal(output: &Path) -> Result<(), String> {
    unsafe {
        LLVMInitializeBPFTarget();
        LLVMInitializeBPFTargetInfo();
        LLVMInitializeBPFTargetMC();
        LLVMInitializeBPFAsmPrinter();
        LLVMInitializeBPFAsmParser();
        LLVMInitializeBPFDisassembler();

        let ctx = LLVMContextCreate();
        let module = LLVMModuleCreateWithName(c("solnix").as_ptr());

        let i32t = LLVMInt32TypeInContext(ctx);
        let voidp = LLVMPointerType(LLVMInt8TypeInContext(ctx), 0);
        let mut args = [voidp];
        let fn_ty = LLVMFunctionType(i32t, args.as_mut_ptr(), 1, 0);
        let func = LLVMAddFunction(module, c("solnix_entry").as_ptr(), fn_ty);
        let bb = LLVMAppendBasicBlock(func, c("entry").as_ptr());
        let builder = LLVMCreateBuilder();
        LLVMPositionBuilderAtEnd(builder, bb);
        LLVMBuildRet(builder, LLVMConstInt(i32t, 0, 0));

        let triple = c("bpf");
        LLVMSetTarget(module, triple.as_ptr());

        let mut target = ptr::null_mut();
        let mut err = ptr::null_mut();
        LLVMGetTargetFromTriple(triple.as_ptr(), &mut target, &mut err);
        if target.is_null() {
            let msg = if !err.is_null() {
                std::ffi::CStr::from_ptr(err).to_string_lossy()
            } else {
                "Unknown LLVM error".into()
            };
            return Err(format!("Failed to get BPF target: {}", msg));
        }

        let tm = LLVMCreateTargetMachine(
            target,
            triple.as_ptr(),
            c("generic").as_ptr(),
            c("").as_ptr(),
            LLVMCodeGenOptLevel::LLVMCodeGenLevelNone as i32,
            LLVMRelocMode::LLVMRelocDefault as i32,
            LLVMCodeModel::LLVMCodeModelDefault as i32,
        );
        if tm.is_null() {
            return Err("Failed to create target machine".into());
        }

        if let Some(parent) = output.parent() {
            std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
        }

        let out = c(output.to_str().unwrap());
        if LLVMTargetMachineEmitToFile(
            tm,
            module,
            out.as_ptr() as *mut _,
            LLVMCodeGenFileType::LLVMObjectFile as i32,
            &mut err,
        ) != 0
        {
            let msg = if !err.is_null() {
                std::ffi::CStr::from_ptr(err).to_string_lossy().into_owned()
            } else {
                "Unknown LLVM emit error".into()
            };
            return Err(format!("Failed to emit BPF object: {}", msg));
        }
    }

    Ok(())
}