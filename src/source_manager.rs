#![allow(unused)]

use std::collections::HashMap;
use std::ops::Range;
use miette::SourceSpan;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct FileId(pub u32);

#[derive(Debug, Clone)]
pub struct Span {
    pub file: FileId,
    pub range: Range<usize>,
}

#[derive(Debug, Clone)]
pub struct SourceFile {
    pub name: String,
    pub content: String,
}

#[derive(Debug, Default)]
pub struct SourceManager {
    files: HashMap<FileId, SourceFile>,
    next_id: u32,
}

impl SourceManager {
    pub fn new() -> Self {
        Self {
            files: HashMap::new(),
            next_id: 0,
        }
    }

    pub fn add_file(&mut self, name: String, content: String) -> FileId {
        let id = FileId(self.next_id);
        self.next_id += 1;
        self.files.insert(id, SourceFile { name, content });
        id
    }
}

impl Span {
    pub fn _to_source_span(&self) -> SourceSpan {
        (self.range.start..self.range.end).into()
    }
}
