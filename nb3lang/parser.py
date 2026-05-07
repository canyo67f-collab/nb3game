"""
NB3Lang Parser - builds AST from tokens.
"""

from dataclasses import dataclass, field
from typing import List, Optional
from nb3lang.lexer import Token, TokenType


# ── AST Nodes ────────────────────────────────────────────────

@dataclass
class NumberLiteral:
    value: object

@dataclass
class FloatLiteral:
    value: float

@dataclass
class StringLiteral:
    value: str

@dataclass
class BoolLiteral:
    value: bool

@dataclass
class ListLiteral:
    elements: list

@dataclass
class Identifier:
    name: str

@dataclass
class BinaryOp:
    left: object
    op: str
    right: object

@dataclass
class UnaryOp:
    op: str
    operand: object

@dataclass
class Assign:
    name: str
    value: object

@dataclass
class AugAssign:
    name: str
    op: str
    value: object

@dataclass
class FunctionCall:
    name: str
    args: list

@dataclass
class MethodCall:
    obj: object
    method: str
    args: list

@dataclass
class IndexAccess:
    obj: object
    index: object

@dataclass
class IndexAssign:
    obj: object
    index: object
    value: object

@dataclass
class IfStatement:
    condition: object
    body: list
    elif_branches: list
    else_body: Optional[list]

@dataclass
class WhileStatement:
    condition: object
    body: list

@dataclass
class ForStatement:
    var_name: str
    iterable: object
    body: list

@dataclass
class FuncDef:
    name: str
    params: List[str]
    body: list

@dataclass
class ReturnStatement:
    value: object

@dataclass
class BreakStatement:
    pass

@dataclass
class ContinueStatement:
    pass

@dataclass
class Program:
    statements: list


# ── Parser ───────────────────────────────────────────────────

class ParseError(Exception):
    def __init__(self, message, token):
        self.token = token
        line = token.line if token else '?'
        col = token.col if token else '?'
        super().__init__(f"[Line {line}, Col {col}] {message}")


class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0

    def error(self, msg):
        raise ParseError(msg, self.current())

    def current(self) -> Token:
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        return Token(TokenType.EOF, '', 0, 0)

    def peek(self) -> Token:
        return self.current()

    def advance(self) -> Token:
        tok = self.current()
        self.pos += 1
        return tok

    def expect(self, tok_type: TokenType) -> Token:
        tok = self.current()
        if tok.type != tok_type:
            self.error(f"Expected {tok_type.name}, got {tok.type.name} ({tok.value!r})")
        return self.advance()

    def match(self, *types) -> bool:
        return self.current().type in types

    def skip_newlines(self):
        while self.current().type == TokenType.NEWLINE:
            self.advance()

    # ── Entry ─────────────────────────────────────────────

    def parse(self) -> Program:
        stmts = []
        self.skip_newlines()
        while self.current().type != TokenType.EOF:
            stmts.append(self.parse_statement())
            self.skip_newlines()
        return Program(stmts)

    # ── Statements ────────────────────────────────────────

    def parse_statement(self):
        tok = self.current()

        if tok.type == TokenType.IF:
            return self.parse_if()
        if tok.type == TokenType.WHILE:
            return self.parse_while()
        if tok.type == TokenType.FOR:
            return self.parse_for()
        if tok.type == TokenType.FUNC:
            return self.parse_func_def()
        if tok.type == TokenType.RETURN:
            return self.parse_return()
        if tok.type == TokenType.BREAK:
            self.advance()
            self._consume_newline()
            return BreakStatement()
        if tok.type == TokenType.CONTINUE:
            self.advance()
            self._consume_newline()
            return ContinueStatement()

        return self.parse_expr_statement()

    def parse_expr_statement(self):
        expr = self.parse_expression()

        # Check for assignment: name = value
        if isinstance(expr, Identifier) and self.match(TokenType.ASSIGN):
            self.advance()
            val = self.parse_expression()
            self._consume_newline()
            return Assign(expr.name, val)

        # Check for augmented assignment: name += value
        if isinstance(expr, Identifier) and self.match(
            TokenType.PLUS_ASSIGN, TokenType.MINUS_ASSIGN,
            TokenType.STAR_ASSIGN, TokenType.SLASH_ASSIGN
        ):
            op_tok = self.advance()
            op_map = {'+=': '+', '-=': '-', '*=': '*', '/=': '/'}
            val = self.parse_expression()
            self._consume_newline()
            return AugAssign(expr.name, op_map[op_tok.value], val)

        # Check for index assignment: list[i] = value
        if isinstance(expr, IndexAccess) and self.match(TokenType.ASSIGN):
            self.advance()
            val = self.parse_expression()
            self._consume_newline()
            return IndexAssign(expr.obj, expr.index, val)

        self._consume_newline()
        return expr

    def parse_if(self):
        self.expect(TokenType.IF)
        condition = self.parse_expression()
        self.expect(TokenType.COLON)
        body = self.parse_block()

        elif_branches = []
        while self.current().type == TokenType.ELIF:
            self.advance()
            elif_cond = self.parse_expression()
            self.expect(TokenType.COLON)
            elif_body = self.parse_block()
            elif_branches.append((elif_cond, elif_body))

        else_body = None
        if self.current().type == TokenType.ELSE:
            self.advance()
            self.expect(TokenType.COLON)
            else_body = self.parse_block()

        return IfStatement(condition, body, elif_branches, else_body)

    def parse_while(self):
        self.expect(TokenType.WHILE)
        condition = self.parse_expression()
        self.expect(TokenType.COLON)
        body = self.parse_block()
        return WhileStatement(condition, body)

    def parse_for(self):
        self.expect(TokenType.FOR)
        name_tok = self.expect(TokenType.IDENTIFIER)
        self.expect(TokenType.IN)
        iterable = self.parse_expression()
        self.expect(TokenType.COLON)
        body = self.parse_block()
        return ForStatement(name_tok.value, iterable, body)

    def parse_func_def(self):
        self.expect(TokenType.FUNC)
        name_tok = self.expect(TokenType.IDENTIFIER)
        self.expect(TokenType.LPAREN)
        params = []
        if not self.match(TokenType.RPAREN):
            params.append(self.expect(TokenType.IDENTIFIER).value)
            while self.match(TokenType.COMMA):
                self.advance()
                params.append(self.expect(TokenType.IDENTIFIER).value)
        self.expect(TokenType.RPAREN)
        self.expect(TokenType.COLON)
        body = self.parse_block()
        return FuncDef(name_tok.value, params, body)

    def parse_return(self):
        self.advance()
        val = None
        if not self.match(TokenType.NEWLINE, TokenType.EOF, TokenType.DEDENT):
            val = self.parse_expression()
        self._consume_newline()
        return ReturnStatement(val)

    def parse_block(self):
        self.skip_newlines()
        self.expect(TokenType.INDENT)
        stmts = []
        while not self.match(TokenType.DEDENT, TokenType.EOF):
            self.skip_newlines()
            if self.match(TokenType.DEDENT, TokenType.EOF):
                break
            stmts.append(self.parse_statement())
            self.skip_newlines()
        if self.match(TokenType.DEDENT):
            self.advance()
        return stmts

    # ── Expressions (precedence climbing) ─────────────────

    def parse_expression(self):
        return self.parse_or()

    def parse_or(self):
        left = self.parse_and()
        while self.match(TokenType.OR):
            self.advance()
            right = self.parse_and()
            left = BinaryOp(left, 'or', right)
        return left

    def parse_and(self):
        left = self.parse_not()
        while self.match(TokenType.AND):
            self.advance()
            right = self.parse_not()
            left = BinaryOp(left, 'and', right)
        return left

    def parse_not(self):
        if self.match(TokenType.NOT):
            self.advance()
            operand = self.parse_not()
            return UnaryOp('not', operand)
        return self.parse_comparison()

    def parse_comparison(self):
        left = self.parse_addition()
        while self.match(TokenType.EQ, TokenType.NEQ, TokenType.LT, TokenType.GT, TokenType.LTE, TokenType.GTE):
            op = self.advance().value
            right = self.parse_addition()
            left = BinaryOp(left, op, right)
        return left

    def parse_addition(self):
        left = self.parse_multiplication()
        while self.match(TokenType.PLUS, TokenType.MINUS):
            op = self.advance().value
            right = self.parse_multiplication()
            left = BinaryOp(left, op, right)
        return left

    def parse_multiplication(self):
        left = self.parse_unary()
        while self.match(TokenType.STAR, TokenType.SLASH, TokenType.PERCENT):
            op = self.advance().value
            right = self.parse_unary()
            left = BinaryOp(left, op, right)
        return left

    def parse_unary(self):
        if self.match(TokenType.MINUS):
            self.advance()
            operand = self.parse_unary()
            return UnaryOp('-', operand)
        return self.parse_postfix()

    def parse_postfix(self):
        expr = self.parse_primary()

        while True:
            if self.match(TokenType.LPAREN):
                # Function/method call
                self.advance()
                args = []
                if not self.match(TokenType.RPAREN):
                    args.append(self.parse_expression())
                    while self.match(TokenType.COMMA):
                        self.advance()
                        args.append(self.parse_expression())
                self.expect(TokenType.RPAREN)
                if isinstance(expr, Identifier):
                    expr = FunctionCall(expr.name, args)
                else:
                    expr = FunctionCall('__call__', [expr] + args)
            elif self.match(TokenType.LBRACKET):
                self.advance()
                index = self.parse_expression()
                self.expect(TokenType.RBRACKET)
                expr = IndexAccess(expr, index)
            elif self.match(TokenType.DOT):
                self.advance()
                method_name = self.expect(TokenType.IDENTIFIER).value
                if self.match(TokenType.LPAREN):
                    self.advance()
                    args = []
                    if not self.match(TokenType.RPAREN):
                        args.append(self.parse_expression())
                        while self.match(TokenType.COMMA):
                            self.advance()
                            args.append(self.parse_expression())
                    self.expect(TokenType.RPAREN)
                    expr = MethodCall(expr, method_name, args)
                else:
                    expr = MethodCall(expr, method_name, [])
            else:
                break

        return expr

    def parse_primary(self):
        tok = self.current()

        if tok.type == TokenType.NUMBER:
            self.advance()
            return NumberLiteral(tok.value)

        if tok.type == TokenType.FLOAT:
            self.advance()
            return FloatLiteral(tok.value)

        if tok.type == TokenType.STRING:
            self.advance()
            return StringLiteral(tok.value)

        if tok.type in (TokenType.TRUE, TokenType.FALSE):
            self.advance()
            return BoolLiteral(tok.value)

        if tok.type == TokenType.IDENTIFIER:
            self.advance()
            return Identifier(tok.value)

        if tok.type == TokenType.LPAREN:
            self.advance()
            expr = self.parse_expression()
            self.expect(TokenType.RPAREN)
            return expr

        if tok.type == TokenType.LBRACKET:
            return self.parse_list_literal()

        self.error(f"Unexpected token: {tok.type.name} ({tok.value!r})")

    def parse_list_literal(self):
        self.expect(TokenType.LBRACKET)
        elements = []
        if not self.match(TokenType.RBRACKET):
            elements.append(self.parse_expression())
            while self.match(TokenType.COMMA):
                self.advance()
                if self.match(TokenType.RBRACKET):
                    break
                elements.append(self.parse_expression())
        self.expect(TokenType.RBRACKET)
        return ListLiteral(elements)

    def _consume_newline(self):
        if self.match(TokenType.NEWLINE):
            self.advance()
