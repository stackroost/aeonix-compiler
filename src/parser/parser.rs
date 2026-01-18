// src/parser/parser.rs
#![allow(unused_assignments)]

use super::{Token, TokenKind};
use crate::lexer::Lexer;
use anyhow::Result;
use miette::{Diagnostic, SourceSpan};

/// Parser error with source location and context
#[derive(Debug, Diagnostic, thiserror::Error)]
#[error("Parse error: {message}")]
pub struct ParseError {
    #[label("here")]
    #[allow(unused)]
    pub span: SourceSpan,
    #[allow(unused)]
    pub message: String,
    #[allow(unused)]
    pub help: Option<String>,
}

impl ParseError {
    pub fn new(span: crate::parser::SourceLoc, message: impl Into<String>) -> Self {
        Self {
            span: (span.offset..span.offset + 1).into(),
            message: message.into(),
            help: None,
        }
    }

    pub fn with_help(mut self, help: impl Into<String>) -> Self {
        self.help = Some(help.into());
        self
    }
}

/// Main parser struct that owns the token stream
pub struct Parser<'src> {
    _src: &'src str,
    lexer: Lexer<'src>,
    current: Token,
}

impl<'src> Parser<'src> {
    /// Initialize parser with source code
    pub fn new(src: &'src str) -> Result<Self, ParseError> {
        let mut lexer = Lexer::new(src);
        let current = lexer.next_token()
            .map_err(|_e| ParseError::new(super::SourceLoc::new(0, 0, 0), "Failed to lex first token"))?;
        
        Ok(Self { _src: src, lexer, current })
    }

    /// Advance to next token
    pub fn advance(&mut self) -> Result<(), ParseError> {
        self.current = self.lexer.next_token()
            .map_err(|_e| ParseError::new(self.current.loc, "Lexer error"))?;
        Ok(())
    }

    /// Check if current token matches expected kind
    pub fn check(&self, kind: TokenKind) -> bool {
        self.current.kind == kind
    }

    /// Match and consume token if it matches
    pub fn r#match(&mut self, kind: TokenKind) -> bool {
        if self.check(kind) {
            let _ = self.advance(); // Ignore error for match
            true
        } else {
            false
        }
    }

    /// Expect a specific token kind, error if not found
    pub fn expect(&mut self, kind: TokenKind) -> Result<Token, ParseError> {
        if self.check(kind) {
            let tok = self.current.clone();
            self.advance()?;
            Ok(tok)
        } else {
            Err(ParseError::new(
                self.current.loc,
                format!("Expected {}, found {}", kind, self.current.kind)
            ).with_help(format!("Expected token: {}", kind)))
        }
    }

    /// Create a parse error at current location
    pub fn error(&self, message: impl Into<String>) -> ParseError {
        ParseError::new(self.current.loc, message)
    }

    /// Create a parse error with help text
    pub fn error_with_help(&self, message: impl Into<String>, help: impl Into<String>) -> ParseError {
        ParseError::new(self.current.loc, message)
            .with_help(help)
    }

    pub fn current(&self) -> &Token {
        &self.current
    }

    /// Get a copy of the current token's location
    pub fn current_loc(&self) -> crate::parser::SourceLoc {
        self.current.loc
    }

    /// Convenience: get the current token's kind
    pub fn current_kind(&self) -> TokenKind {
        self.current.kind
    }

    /// Convenience: get the current token's lexeme
    pub fn _current_lexeme(&self) -> &str {
        &self.current.lexeme
    }
}