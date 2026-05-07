"""
NB3Lang Lexer - tokenizer for the NB3 programming language.
"""

from enum import Enum, auto
from dataclasses import dataclass
from typing import List


class TokenType(Enum):
    # Literals
    NUMBER = auto()
    FLOAT = auto()
    STRING = auto()
    IDENTIFIER = auto()

    # Keywords
    IF = auto()
    ELIF = auto()
    ELSE = auto()
    WHILE = auto()
    FOR = auto()
    IN = auto()
    FUNC = auto()
    RETURN = auto()
    TRUE = auto()
    FALSE = auto()
    AND = auto()
    OR = auto()
    NOT = auto()
    BREAK = auto()
    CONTINUE = auto()

    # Operators
    PLUS = auto()
    MINUS = auto()
    STAR = auto()
    SLASH = auto()
    PERCENT = auto()
    ASSIGN = auto()
    EQ = auto()
    NEQ = auto()
    LT = auto()
    GT = auto()
    LTE = auto()
    GTE = auto()
    PLUS_ASSIGN = auto()
    MINUS_ASSIGN = auto()
    STAR_ASSIGN = auto()
    SLASH_ASSIGN = auto()

    # Delimiters
    LPAREN = auto()
    RPAREN = auto()
    LBRACKET = auto()
    RBRACKET = auto()
    COMMA = auto()
    COLON = auto()
    DOT = auto()

    # Special
    NEWLINE = auto()
    INDENT = auto()
    DEDENT = auto()
    EOF = auto()


KEYWORDS = {
    'if': TokenType.IF,
    'elif': TokenType.ELIF,
    'else': TokenType.ELSE,
    'while': TokenType.WHILE,
    'for': TokenType.FOR,
    'in': TokenType.IN,
    'func': TokenType.FUNC,
    'return': TokenType.RETURN,
    'true': TokenType.TRUE,
    'false': TokenType.FALSE,
    'and': TokenType.AND,
    'or': TokenType.OR,
    'not': TokenType.NOT,
    'break': TokenType.BREAK,
    'continue': TokenType.CONTINUE,
}


@dataclass
class Token:
    type: TokenType
    value: object
    line: int
    col: int

    def __repr__(self):
        return f"Token({self.type.name}, {self.value!r}, L{self.line}:{self.col})"


class LexerError(Exception):
    def __init__(self, message, line, col):
        self.line = line
        self.col = col
        super().__init__(f"[Line {line}, Col {col}] {message}")


class Lexer:
    def __init__(self, source: str):
        self.source = source
        self.pos = 0
        self.line = 1
        self.col = 1
        self.tokens: List[Token] = []
        self.indent_stack = [0]

    def error(self, msg):
        raise LexerError(msg, self.line, self.col)

    def peek(self):
        if self.pos >= len(self.source):
            return '\0'
        return self.source[self.pos]

    def advance(self):
        ch = self.source[self.pos]
        self.pos += 1
        if ch == '\n':
            self.line += 1
            self.col = 1
        else:
            self.col += 1
        return ch

    def skip_comment(self):
        while self.pos < len(self.source) and self.source[self.pos] != '\n':
            self.pos += 1
            self.col += 1

    def read_string(self, quote):
        start_line = self.line
        start_col = self.col
        result = []
        while self.pos < len(self.source):
            ch = self.source[self.pos]
            if ch == '\\':
                self.pos += 1
                self.col += 1
                if self.pos >= len(self.source):
                    self.error("Unexpected end of string")
                esc = self.source[self.pos]
                escape_map = {'n': '\n', 't': '\t', '\\': '\\', "'": "'", '"': '"'}
                result.append(escape_map.get(esc, esc))
                self.pos += 1
                self.col += 1
            elif ch == quote:
                self.pos += 1
                self.col += 1
                return ''.join(result)
            elif ch == '\n':
                self.error("Unterminated string")
            else:
                result.append(ch)
                self.pos += 1
                self.col += 1
        self.error("Unterminated string")

    def read_number(self):
        start = self.pos
        is_float = False
        while self.pos < len(self.source) and (self.source[self.pos].isdigit() or self.source[self.pos] == '.'):
            if self.source[self.pos] == '.':
                if is_float:
                    break
                is_float = True
            self.pos += 1
            self.col += 1
        text = self.source[start:self.pos]
        if is_float:
            return TokenType.FLOAT, float(text)
        return TokenType.NUMBER, int(text)

    def read_identifier(self):
        start = self.pos
        while self.pos < len(self.source) and (self.source[self.pos].isalnum() or self.source[self.pos] == '_'):
            self.pos += 1
            self.col += 1
        return self.source[start:self.pos]

    def tokenize(self) -> List[Token]:
        while self.pos < len(self.source):
            # Handle beginning of line - indentation
            if self.col == 1:
                self._handle_indentation()

            ch = self.peek()

            if ch == '\0':
                break

            # Skip blank lines
            if ch == '\n':
                self.tokens.append(Token(TokenType.NEWLINE, '\\n', self.line, self.col))
                self.advance()
                continue

            # Skip spaces/tabs in the middle of a line
            if ch in (' ', '\t'):
                self.advance()
                continue

            # Comments
            if ch == '#':
                self.skip_comment()
                continue

            # Strings
            if ch in ('"', "'"):
                start_line, start_col = self.line, self.col
                self.advance()
                val = self.read_string(ch)
                self.tokens.append(Token(TokenType.STRING, val, start_line, start_col))
                continue

            # Numbers
            if ch.isdigit():
                start_line, start_col = self.line, self.col
                tok_type, val = self.read_number()
                self.tokens.append(Token(tok_type, val, start_line, start_col))
                continue

            # Identifiers and keywords
            if ch.isalpha() or ch == '_':
                start_line, start_col = self.line, self.col
                name = self.read_identifier()
                tok_type = KEYWORDS.get(name, TokenType.IDENTIFIER)
                if tok_type == TokenType.TRUE:
                    self.tokens.append(Token(tok_type, True, start_line, start_col))
                elif tok_type == TokenType.FALSE:
                    self.tokens.append(Token(tok_type, False, start_line, start_col))
                else:
                    self.tokens.append(Token(tok_type, name, start_line, start_col))
                continue

            # Two-char operators
            start_line, start_col = self.line, self.col
            if ch == '=' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.EQ, '==', start_line, start_col))
                continue
            if ch == '!' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.NEQ, '!=', start_line, start_col))
                continue
            if ch == '<' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.LTE, '<=', start_line, start_col))
                continue
            if ch == '>' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.GTE, '>=', start_line, start_col))
                continue
            if ch == '+' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.PLUS_ASSIGN, '+=', start_line, start_col))
                continue
            if ch == '-' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.MINUS_ASSIGN, '-=', start_line, start_col))
                continue
            if ch == '*' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.STAR_ASSIGN, '*=', start_line, start_col))
                continue
            if ch == '/' and self._peek_next() == '=':
                self.advance(); self.advance()
                self.tokens.append(Token(TokenType.SLASH_ASSIGN, '/=', start_line, start_col))
                continue

            # Single-char operators and delimiters
            single = {
                '+': TokenType.PLUS, '-': TokenType.MINUS,
                '*': TokenType.STAR, '/': TokenType.SLASH,
                '%': TokenType.PERCENT, '=': TokenType.ASSIGN,
                '<': TokenType.LT, '>': TokenType.GT,
                '(': TokenType.LPAREN, ')': TokenType.RPAREN,
                '[': TokenType.LBRACKET, ']': TokenType.RBRACKET,
                ',': TokenType.COMMA, ':': TokenType.COLON,
                '.': TokenType.DOT,
            }
            if ch in single:
                self.advance()
                self.tokens.append(Token(single[ch], ch, start_line, start_col))
                continue

            self.error(f"Unexpected character: {ch!r}")

        # Close remaining indents
        while len(self.indent_stack) > 1:
            self.indent_stack.pop()
            self.tokens.append(Token(TokenType.DEDENT, '', self.line, self.col))

        self.tokens.append(Token(TokenType.EOF, '', self.line, self.col))
        return self.tokens

    def _peek_next(self):
        if self.pos + 1 >= len(self.source):
            return '\0'
        return self.source[self.pos + 1]

    def _handle_indentation(self):
        indent = 0
        while self.pos < len(self.source) and self.source[self.pos] in (' ', '\t'):
            if self.source[self.pos] == '\t':
                indent += 4
            else:
                indent += 1
            self.pos += 1
            self.col += 1

        # Skip blank/comment-only lines
        if self.pos < len(self.source) and self.source[self.pos] in ('\n', '#', '\0'):
            return

        current = self.indent_stack[-1]
        if indent > current:
            self.indent_stack.append(indent)
            self.tokens.append(Token(TokenType.INDENT, indent, self.line, self.col))
        elif indent < current:
            while self.indent_stack[-1] > indent:
                self.indent_stack.pop()
                self.tokens.append(Token(TokenType.DEDENT, '', self.line, self.col))
            if self.indent_stack[-1] != indent:
                self.error(f"Indentation error")
