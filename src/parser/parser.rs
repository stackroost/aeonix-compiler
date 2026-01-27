#![allow(unused_assignments)]

use super::{Token, TokenKind};
use crate::lexer::Lexer;
use anyhow::Result;
use miette::{Diagnostic, SourceSpan};

#[allow(unused)]
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

#[derive(Debug, Clone, Copy)]
pub enum BinOp {
    Add,
}

#[derive(Debug, Clone)]
pub enum Expr {
    Number(i64),
    Var(String),
    Binary {
        left: Box<Expr>,
        op: BinOp,
        right: Box<Expr>,
    },
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

pub struct Parser<'src> {
    _src: &'src str,
    lexer: Lexer<'src>,
    current: Token,
}

impl<'src> Parser<'src> {
    pub fn new(src: &'src str) -> Result<Self, ParseError> {
        let mut lexer = Lexer::new(src);
        let current = lexer.next_token().map_err(|_e| {
            ParseError::new(super::SourceLoc::new(0, 0, 0), "Failed to lex first token")
        })?;

        Ok(Self {
            _src: src,
            lexer,
            current,
        })
    }

    pub fn advance(&mut self) -> Result<(), ParseError> {
        self.current = self
            .lexer
            .next_token()
            .map_err(|_e| ParseError::new(self.current.loc, "Lexer error"))?;
        Ok(())
    }

    pub fn check(&self, kind: TokenKind) -> bool {
        self.current.kind == kind
    }

    pub fn r#match(&mut self, kind: TokenKind) -> bool {
        if self.check(kind) {
            let _ = self.advance();
            true
        } else {
            false
        }
    }

    pub fn expect(&mut self, kind: TokenKind) -> Result<Token, ParseError> {
        if self.check(kind) {
            let tok = self.current.clone();
            self.advance()?;
            Ok(tok)
        } else {
            Err(ParseError::new(
                self.current.loc,
                format!("Expected {}, found {}", kind, self.current.kind),
            )
            .with_help(format!("Expected token: {}", kind)))
        }
    }

    pub fn error(&self, message: impl Into<String>) -> ParseError {
        ParseError::new(self.current.loc, message)
    }

    pub fn error_with_help(
        &self,
        message: impl Into<String>,
        help: impl Into<String>,
    ) -> ParseError {
        ParseError::new(self.current.loc, message).with_help(help)
    }

    pub fn current(&self) -> &Token {
        &self.current
    }

    pub fn current_loc(&self) -> crate::parser::SourceLoc {
        self.current.loc
    }

    pub fn current_kind(&self) -> TokenKind {
        self.current.kind
    }

    pub fn _current_lexeme(&self) -> &str {
        &self.current.lexeme
    }

    pub fn parse_expr(&mut self) -> Result<Expr, ParseError> {
        self.parse_additive()
    }

    fn parse_additive(&mut self) -> Result<Expr, ParseError> {
        let mut left = self.parse_primary()?;

        while self.current_kind() == TokenKind::Plus {
            self.advance()?; // eat '+'
            let right = self.parse_primary()?;
            left = Expr::Binary {
                left: Box::new(left),
                op: BinOp::Add,
                right: Box::new(right),
            };
        }

        Ok(left)
    }

    fn parse_primary(&mut self) -> Result<Expr, ParseError> {
        match self.current_kind() {
            TokenKind::Number => {
                let tok = self.current.clone();
                self.advance()?;
                Ok(Expr::Number(tok.int_value.unwrap()))
            }
            TokenKind::Identifier => {
                let tok = self.current.clone();
                self.advance()?;
                Ok(Expr::Var(tok.lexeme))
            }
            _ => Err(self.error("Expected expression")),
        }
    }
}
