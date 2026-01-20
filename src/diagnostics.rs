#![allow(unused)]

use miette::{Diagnostic, SourceSpan};
use std::ops::Range;
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct FileId(pub u32);

#[derive(Debug, Clone)]
pub struct Span {
    pub file: FileId,
    pub range: Range<usize>,
}

pub struct SourceManager {
    files: std::collections::HashMap<FileId, SourceFile>,
    next_id: u32,
}

pub struct SourceFile {
    pub name: String,
    pub content: String,
}

impl SourceManager {
    pub fn new() -> Self {
        Self {
            files: std::collections::HashMap::new(),
            next_id: 0,
        }
    }

    pub fn add_file(&mut self, name: String, content: String) -> FileId {
        let id = FileId(self.next_id);
        self.next_id += 1;
        self.files.insert(id, SourceFile { name, content });
        id
    }

    pub fn get(&self, id: FileId) -> Option<&SourceFile> {
        self.files.get(&id)
    }
}

impl Span {
    pub fn to_source_span(&self) -> SourceSpan {
        (self.range.start..self.range.end).into()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorCategory {
    Parse,
    Semantic,
    Codegen,
    Io,
}

#[derive(Error, Debug, Diagnostic)]
#[error("Compilation error in {file}: {message}")]
#[allow(unused)]
pub struct CompileDiagnostic {
    #[source_code]
    pub file: String,

    #[label("{label_message}")]
    pub span: SourceSpan,

    pub message: String,
    pub label_message: String,
    pub category: ErrorCategory,
    pub code: String,
}

impl CompileDiagnostic {
    pub fn new(
        file: String,
        span: Span,
        message: String,
        label_message: String,
        category: ErrorCategory,
        code: impl Into<String>,
    ) -> Self {
        Self {
            file,
            span: span.to_source_span(),
            message,
            label_message,
            category,
            code: code.into(),
        }
    }
}