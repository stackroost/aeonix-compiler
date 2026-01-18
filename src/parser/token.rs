// src/parser/token.rs
#![allow(unused)]

use std::fmt;

/// Source location with line, column, and byte offset
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct SourceLoc {
    pub line: usize,
    pub column: usize,
    pub offset: usize,
}

impl SourceLoc {
    #[inline]
    pub const fn new(line: usize, column: usize, offset: usize) -> Self {
        Self { line, column, offset }
    }

    /// Returns a zero location (useful for EOF)
    #[inline]
    pub const fn _zero() -> Self {
        Self::new(0, 0, 0)
    }
}

/// Token types representing Solnix language syntax
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum TokenKind {
    // Keywords
    KeywordUnit,
    KeywordSection,
    KeywordLicense,
    KeywordReturn,
    KeywordReg,
    KeywordImm,
    KeywordMap,
    KeywordType,
    KeywordKey,
    KeywordValue,
    KeywordMax,
    KeywordIf,
    KeywordGuard,
    KeywordHeap,

    // Map types
    MapTypeHash,
    MapTypeArray,
    MapTypeRingbuf,
    MapTypeLruHash,
    MapTypeProgArray,

    // Primitive types
    TypeU32,
    TypeU64,
    TypeI32,
    TypeI64,

    // Punctuation
    LBrace,
    RBrace,
    LParen,
    RParen,
    Equals,
    PlusEquals,
    Colon,
    Dot,
    Star,
    Semicolon,

    // Literals and identifiers
    Identifier,
    StringLiteral,
    Number,

    // End of file
    Eof,
}

impl TokenKind {
    /// Check if this token is a keyword
    #[inline]
    pub fn _is_keyword(&self) -> bool {
        matches!(self,
            Self::KeywordUnit
            | Self::KeywordSection
            | Self::KeywordLicense
            | Self::KeywordReturn
            | Self::KeywordReg
            | Self::KeywordImm
            | Self::KeywordMap
            | Self::KeywordType
            | Self::KeywordKey
            | Self::KeywordValue
            | Self::KeywordMax
            | Self::KeywordIf
            | Self::KeywordGuard
            | Self::KeywordHeap
        )
    }

    /// Check if this token is a map type
    #[inline]
    pub fn _is_map_type(&self) -> bool {
        matches!(self,
            Self::MapTypeHash
            | Self::MapTypeArray
            | Self::MapTypeRingbuf
            | Self::MapTypeLruHash
            | Self::MapTypeProgArray
        )
    }

    /// Check if this token is a primitive type
    #[inline]
    pub fn _is_primitive_type(&self) -> bool {
        matches!(self,
            Self::TypeU32
            | Self::TypeU64
            | Self::TypeI32
            | Self::TypeI64
        )
    }
}

impl fmt::Display for TokenKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            // Keywords
            Self::KeywordUnit => write!(f, "unit"),
            Self::KeywordSection => write!(f, "section"),
            Self::KeywordLicense => write!(f, "license"),
            Self::KeywordReturn => write!(f, "return"),
            Self::KeywordReg => write!(f, "reg"),
            Self::KeywordImm => write!(f, "imm"),
            Self::KeywordMap => write!(f, "map"),
            Self::KeywordType => write!(f, "type"),
            Self::KeywordKey => write!(f, "key"),
            Self::KeywordValue => write!(f, "value"),
            Self::KeywordMax => write!(f, "max"),
            Self::KeywordIf => write!(f, "if"),
            Self::KeywordGuard => write!(f, "guard"),
            Self::KeywordHeap => write!(f, "heap"),

            // Map types
            Self::MapTypeHash => write!(f, "hash"),
            Self::MapTypeArray => write!(f, "array"),
            Self::MapTypeRingbuf => write!(f, "ringbuf"),
            Self::MapTypeLruHash => write!(f, "lru_hash"),
            Self::MapTypeProgArray => write!(f, "prog_array"),

            // Primitive types
            Self::TypeU32 => write!(f, "u32"),
            Self::TypeU64 => write!(f, "u64"),
            Self::TypeI32 => write!(f, "i32"),
            Self::TypeI64 => write!(f, "i64"),

            // Punctuation
            Self::LBrace => write!(f, "{{"),
            Self::RBrace => write!(f, "}}"),
            Self::LParen => write!(f, "("),
            Self::RParen => write!(f, ")"),
            Self::Equals => write!(f, "="),
            Self::PlusEquals => write!(f, "+="),
            Self::Colon => write!(f, ":"),
            Self::Dot => write!(f, "."),
            Self::Star => write!(f, "*"),
            Self::Semicolon => write!(f, ";"),

            // Literals
            Self::Identifier => write!(f, "identifier"),
            Self::StringLiteral => write!(f, "string literal"),
            Self::Number => write!(f, "number"),

            Self::Eof => write!(f, "end of file"),
        }
    }
}

/// A lexical token with its kind, text, location, and optional value
#[derive(Debug, Clone)]
pub struct Token {
    pub kind: TokenKind,
    pub lexeme: String,  // Owned string for safety (avoids lifetime hell)
    pub loc: SourceLoc,

    /// Pre-parsed integer value for number tokens
    pub int_value: Option<i64>,
}

impl Token {
    /// Create a new token without an integer value
    pub fn new(kind: TokenKind, lexeme: impl Into<String>, loc: SourceLoc) -> Self {
        Self {
            kind,
            lexeme: lexeme.into(),
            loc,
            int_value: None,
        }
    }

    /// Create a numeric token with a pre-parsed value
    pub fn new_number(lexeme: impl Into<String>, loc: SourceLoc, value: i64) -> Self {
        Self {
            kind: TokenKind::Number,
            lexeme: lexeme.into(),
            loc,
            int_value: Some(value),
        }
    }

    /// Create an EOF token
    pub fn eof(offset: usize) -> Self {
        Self {
            kind: TokenKind::Eof,
            lexeme: String::new(),
            loc: SourceLoc::new(0, 0, offset),
            int_value: None,
        }
    }
}