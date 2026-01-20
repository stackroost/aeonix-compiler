
#![allow(unused_assignments)]

use miette::{Diagnostic, SourceSpan};
use crate::parser::TokenKind;


#[derive(Debug, Diagnostic, thiserror::Error)]
pub enum LexError {
    #[error("Unterminated comment")]
    #[diagnostic(help("Comments start with /* and end with */"))]
    UnterminatedComment { #[allow(unused)] span: SourceSpan },

    #[error("Invalid character")]
    InvalidCharacter { #[allow(unused)] span: SourceSpan },

    #[error("Unterminated string literal")]
    UnterminatedString { #[allow(unused)] span: SourceSpan },

    #[error("Invalid escape sequence: \\{seq}")]
    InvalidEscapeSequence { seq: String, #[allow(unused)] span: SourceSpan },

    #[error("Expected string literal")]
    ExpectedStringLiteral { #[allow(unused)] span: SourceSpan },
}

pub struct Lexer<'src> {
    src: &'src str,
    bytes: &'src [u8],
    index: usize,
    line: usize,
    column: usize,
}

impl<'src> Lexer<'src> {
    pub fn new(src: &'src str) -> Self {
        Self {
            src,
            bytes: src.as_bytes(),
            index: 0,
            line: 1,
            column: 1,
        }
    }

    fn current_loc(&self) -> crate::parser::SourceLoc {
        crate::parser::SourceLoc::new(self.line, self.column, self.index)
    }

    fn peek(&self) -> char {
        if self.index >= self.bytes.len() {
            '\0'
        } else {
            self.bytes[self.index] as char
        }
    }

    fn peek_next(&self) -> char {
        if self.index + 1 >= self.bytes.len() {
            '\0'
        } else {
            self.bytes[self.index + 1] as char
        }
    }

    fn advance(&mut self) {
        if self.index < self.bytes.len() {
            if self.bytes[self.index] == b'\n' {
                self.line += 1;
                self.column = 1;
            } else {
                self.column += 1;
            }
            self.index += 1;
        }
    }

    fn skip_whitespace(&mut self) {
        while self.index < self.bytes.len() {
            let ch = self.peek();
            if ch.is_whitespace() {
                self.advance();
            } else {
                break;
            }
        }
    }

    fn skip_comment(&mut self) -> Result<(), LexError> {
        if self.peek() == '/' {
            self.advance();
            if self.peek() == '/' {
                self.advance();
                while self.index < self.bytes.len() && self.peek() != '\n' {
                    self.advance();
                }
                if self.index < self.bytes.len() {
                    self.advance();
                }
            } else if self.peek() == '*' {
                self.advance();
                let start_loc = self.current_loc();
                while self.index < self.bytes.len() {
                    if self.peek() == '*' && self.peek_next() == '/' {
                        self.advance();
                        self.advance();
                        return Ok(());
                    }
                    self.advance();
                }
                return Err(LexError::UnterminatedComment {
                    span: (start_loc.offset..self.index).into(),
                });
            } else {
                self.index -= 1;
                self.column -= 1;
            }
        }
        Ok(())
    }

    fn read_identifier(&mut self) -> crate::parser::Token {
        let start = self.index;
        let loc = self.current_loc();

        while self.index < self.bytes.len() {
            let ch = self.peek();
            if ch.is_alphanumeric() || ch == '_' {
                self.advance();
            } else {
                break;
            }
        }

        let lexeme = &self.src[start..self.index];
        
        let kind = match lexeme {
            "unit" => crate::parser::TokenKind::KeywordUnit,
            "section" => crate::parser::TokenKind::KeywordSection,
            "license" => crate::parser::TokenKind::KeywordLicense,
            "return" => crate::parser::TokenKind::KeywordReturn,
            "reg" => crate::parser::TokenKind::KeywordReg,
            "imm" => crate::parser::TokenKind::KeywordImm,
            "map" => crate::parser::TokenKind::KeywordMap,
            "type" => crate::parser::TokenKind::KeywordType,
            "key" => crate::parser::TokenKind::KeywordKey,
            "value" => crate::parser::TokenKind::KeywordValue,
            "max" => crate::parser::TokenKind::KeywordMax,
            "if" => crate::parser::TokenKind::KeywordIf,
            "guard" => crate::parser::TokenKind::KeywordGuard,
            "heap" => crate::parser::TokenKind::KeywordHeap,
            "u32" => crate::parser::TokenKind::TypeU32,
            "u64" => crate::parser::TokenKind::TypeU64,
            "i32" => crate::parser::TokenKind::TypeI32,
            "i64" => crate::parser::TokenKind::TypeI64,
            _ => crate::parser::TokenKind::Identifier,
        };

        crate::parser::Token::new(kind, lexeme.to_string(), loc)
    }

    fn read_number(&mut self) -> Result<crate::parser::Token, LexError> {
        let start = self.index;
        let loc = self.current_loc();
        let mut value: i64 = 0;
        let mut negative = false;

        if self.peek() == '-' {
            negative = true;
            self.advance();
        }

        if self.index + 1 < self.bytes.len() 
            && self.peek() == '0' 
            && self.peek_next() == 'x' 
        {
            self.advance();
            self.advance();
            let mut has_digits = false;

            while self.index < self.bytes.len() {
                let ch = self.peek();
                match ch {
                    '0'..='9' => {
                        value = value * 16 + (ch as i64 - '0' as i64);
                        has_digits = true;
                        self.advance();
                    }
                    'a'..='f' => {
                        value = value * 16 + (ch as i64 - 'a' as i64 + 10);
                        has_digits = true;
                        self.advance();
                    }
                    'A'..='F' => {
                        value = value * 16 + (ch as i64 - 'A' as i64 + 10);
                        has_digits = true;
                        self.advance();
                    }
                    _ => break,
                }
            }

            if !has_digits {
                return Err(LexError::InvalidCharacter {
                    span: (self.index..self.index + 1).into(),
                });
            }
        } else {
            while self.index < self.bytes.len() {
                let ch = self.peek();
                if let Some(digit) = ch.to_digit(10) {
                    value = value * 10 + digit as i64;
                    self.advance();
                } else {
                    break;
                }
            }
        }

        if negative {
            value = -value;
        }

        let lexeme = &self.src[start..self.index];
        Ok(crate::parser::Token::new_number(lexeme.to_string(), loc, value))
    }

    fn read_string(&mut self) -> Result<crate::parser::Token, LexError> {
        let start = self.index;
        let loc = self.current_loc();

        if self.peek() != '"' {
            return Err(LexError::ExpectedStringLiteral {
                span: (self.index..self.index + 1).into(),
            });
        }

        self.advance();
        let content_start = self.index;

        while self.index < self.bytes.len() {
            let ch = self.peek();
            match ch {
                '"' => {
                    self.advance();
                    let content = &self.src[content_start..self.index - 1];
                    return Ok(crate::parser::Token::new(
                        crate::parser::TokenKind::StringLiteral,
                        format!("\"{}\"", content),
                        loc,
                    ));
                }
                '\\' => {
                    self.advance();
                    if self.index >= self.bytes.len() {
                        return Err(LexError::UnterminatedString {
                            span: (start..self.index).into(),
                        });
                    }
                    let esc = self.peek();
                    match esc {
                        '"' | '\\' | 'n' => self.advance(),
                        _ => {
                            return Err(LexError::InvalidEscapeSequence {
                                seq: esc.to_string(),
                                span: (self.index - 1..self.index).into(),
                            });
                        }
                    }
                }
                '\n' => {
                    return Err(LexError::UnterminatedString {
                        span: (start..self.index).into(),
                    });
                }
                _ => self.advance(),
            }
        }

        Err(LexError::UnterminatedString {
            span: (start..self.index).into(),
        })
    }

    pub fn next_token(&mut self) -> Result<crate::parser::Token, LexError> {
        loop {
            self.skip_whitespace();
            
            if self.index >= self.bytes.len() {
                return Ok(crate::parser::Token::eof(self.index));
            }

            let before = self.index;
            if let Err(e) = self.skip_comment() {
                return Err(e);
            }
            
            if self.index == before {
                break;
            }
        }

        let loc = self.current_loc();
        let ch = self.peek();

        if ch.is_alphabetic() || ch == '_' {
            return Ok(self.read_identifier());
        }

        if ch.is_ascii_digit() || ch == '-' {
            return self.read_number();
        }

        if ch == '"' {
            return self.read_string();
        }

        match ch {
            '{' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::LBrace, "{", loc))
            }
            '}' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::RBrace, "}", loc))
            }
            '(' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::LParen, "(", loc))
            }
            ')' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::RParen, ")", loc))
            }
            ':' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::Colon, ":", loc))
            }
            '.' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::Dot, ".", loc))
            }
            '*' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::Star, "*", loc))
            }
            ';' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::Semicolon, ";", loc))
            }
            '=' => {
                self.advance();
                Ok(crate::parser::Token::new(TokenKind::Equals, "=", loc))
            }
            '+' => {
                self.advance();
                if self.peek() == '=' {
                    self.advance();
                    Ok(crate::parser::Token::new(TokenKind::PlusEquals, "+=", loc))
                } else {
                    Err(LexError::InvalidCharacter {
                        span: (loc.offset..loc.offset + 1).into(),
                    })
                }
            }
            _ => Err(LexError::InvalidCharacter {
                span: (loc.offset..loc.offset + 1).into(),
            }),
        }
    }
}