"""
NB3Lang Interpreter - executes AST nodes.
"""

import random
import math
import time

from nb3lang.parser import (
    Program, NumberLiteral, FloatLiteral, StringLiteral, BoolLiteral,
    ListLiteral, Identifier, BinaryOp, UnaryOp, Assign, AugAssign,
    FunctionCall, MethodCall, IndexAccess, IndexAssign,
    IfStatement, WhileStatement, ForStatement,
    FuncDef, ReturnStatement, BreakStatement, ContinueStatement,
)


class NB3Error(Exception):
    pass


class ReturnSignal(Exception):
    def __init__(self, value):
        self.value = value


class BreakSignal(Exception):
    pass


class ContinueSignal(Exception):
    pass


class Environment:
    def __init__(self, parent=None):
        self.vars = {}
        self.parent = parent

    def get(self, name):
        if name in self.vars:
            return self.vars[name]
        if self.parent:
            return self.parent.get(name)
        raise NB3Error(f"Variable '{name}' is not defined")

    def set(self, name, value):
        self.vars[name] = value

    def update(self, name, value):
        if name in self.vars:
            self.vars[name] = value
            return
        if self.parent:
            self.parent.update(name, value)
            return
        self.vars[name] = value


class NB3Function:
    def __init__(self, name, params, body, closure):
        self.name = name
        self.params = params
        self.body = body
        self.closure = closure


class Interpreter:
    def __init__(self, input_func=None, output_func=None):
        self.global_env = Environment()
        self.input_func = input_func or input
        self.output_func = output_func or print
        self._setup_builtins()

    def _setup_builtins(self):
        self.builtins = {
            'print': self._builtin_print,
            'input': self._builtin_input,
            'len': self._builtin_len,
            'str': self._builtin_str,
            'int': self._builtin_int,
            'float': self._builtin_float,
            'type': self._builtin_type,
            'range': self._builtin_range,
            'abs': self._builtin_abs,
            'min': self._builtin_min,
            'max': self._builtin_max,
            'round': self._builtin_round,
            'random': self._builtin_random,
            'randint': self._builtin_randint,
            'sqrt': self._builtin_sqrt,
            'sleep': self._builtin_sleep,
            'list': self._builtin_list,
            'append': self._builtin_append,
            'pop': self._builtin_pop,
            'sort': self._builtin_sort,
            'reverse': self._builtin_reverse,
            'join': self._builtin_join,
            'split': self._builtin_split,
            'replace': self._builtin_replace,
            'upper': self._builtin_upper,
            'lower': self._builtin_lower,
            'strip': self._builtin_strip,
            'contains': self._builtin_contains,
            'keys': self._builtin_keys,
            'values': self._builtin_values,
        }

    def run(self, program: Program):
        for stmt in program.statements:
            self.execute(stmt, self.global_env)

    def execute(self, node, env):
        if isinstance(node, Assign):
            val = self.evaluate(node.value, env)
            env.update(node.name, val)
            return val

        if isinstance(node, AugAssign):
            old = env.get(node.name)
            right = self.evaluate(node.value, env)
            result = self._apply_op(node.op, old, right)
            env.update(node.name, result)
            return result

        if isinstance(node, IndexAssign):
            obj = self.evaluate(node.obj, env)
            idx = self.evaluate(node.index, env)
            val = self.evaluate(node.value, env)
            if isinstance(obj, list):
                obj[int(idx)] = val
            elif isinstance(obj, dict):
                obj[idx] = val
            else:
                raise NB3Error(f"Cannot index-assign to {type(obj).__name__}")
            return val

        if isinstance(node, IfStatement):
            cond = self.evaluate(node.condition, env)
            if self._truthy(cond):
                for s in node.body:
                    self.execute(s, env)
            else:
                matched = False
                for elif_cond, elif_body in node.elif_branches:
                    if self._truthy(self.evaluate(elif_cond, env)):
                        for s in elif_body:
                            self.execute(s, env)
                        matched = True
                        break
                if not matched and node.else_body:
                    for s in node.else_body:
                        self.execute(s, env)
            return None

        if isinstance(node, WhileStatement):
            while self._truthy(self.evaluate(node.condition, env)):
                try:
                    for s in node.body:
                        self.execute(s, env)
                except BreakSignal:
                    break
                except ContinueSignal:
                    continue
            return None

        if isinstance(node, ForStatement):
            iterable = self.evaluate(node.iterable, env)
            if not hasattr(iterable, '__iter__'):
                raise NB3Error(f"Cannot iterate over {type(iterable).__name__}")
            for item in iterable:
                env.update(node.var_name, item)
                try:
                    for s in node.body:
                        self.execute(s, env)
                except BreakSignal:
                    break
                except ContinueSignal:
                    continue
            return None

        if isinstance(node, FuncDef):
            func = NB3Function(node.name, node.params, node.body, env)
            env.set(node.name, func)
            return None

        if isinstance(node, ReturnStatement):
            val = self.evaluate(node.value, env) if node.value else None
            raise ReturnSignal(val)

        if isinstance(node, BreakStatement):
            raise BreakSignal()

        if isinstance(node, ContinueStatement):
            raise ContinueSignal()

        # Expression statement
        return self.evaluate(node, env)

    def evaluate(self, node, env):
        if node is None:
            return None

        if isinstance(node, NumberLiteral):
            return node.value

        if isinstance(node, FloatLiteral):
            return node.value

        if isinstance(node, StringLiteral):
            return node.value

        if isinstance(node, BoolLiteral):
            return node.value

        if isinstance(node, ListLiteral):
            return [self.evaluate(el, env) for el in node.elements]

        if isinstance(node, Identifier):
            return env.get(node.name)

        if isinstance(node, BinaryOp):
            left = self.evaluate(node.left, env)
            # Short-circuit for and/or
            if node.op == 'and':
                return left if not self._truthy(left) else self.evaluate(node.right, env)
            if node.op == 'or':
                return left if self._truthy(left) else self.evaluate(node.right, env)
            right = self.evaluate(node.right, env)
            return self._apply_op(node.op, left, right)

        if isinstance(node, UnaryOp):
            operand = self.evaluate(node.operand, env)
            if node.op == '-':
                return -operand
            if node.op == 'not':
                return not self._truthy(operand)
            raise NB3Error(f"Unknown unary operator: {node.op}")

        if isinstance(node, FunctionCall):
            return self._call_function(node.name, node.args, env)

        if isinstance(node, MethodCall):
            obj = self.evaluate(node.obj, env)
            args = [self.evaluate(a, env) for a in node.args]
            return self._call_method(obj, node.method, args)

        if isinstance(node, IndexAccess):
            obj = self.evaluate(node.obj, env)
            idx = self.evaluate(node.index, env)
            if isinstance(obj, list):
                return obj[int(idx)]
            if isinstance(obj, str):
                return obj[int(idx)]
            if isinstance(obj, dict):
                return obj[idx]
            raise NB3Error(f"Cannot index into {type(obj).__name__}")

        if isinstance(node, Assign):
            val = self.evaluate(node.value, env)
            env.update(node.name, val)
            return val

        raise NB3Error(f"Unknown AST node: {type(node).__name__}")

    def _apply_op(self, op, left, right):
        if op == '+':
            # Auto-convert for string concatenation
            if isinstance(left, str) or isinstance(right, str):
                return self._to_str(left) + self._to_str(right)
            return left + right
        if op == '-':
            return left - right
        if op == '*':
            if isinstance(left, str) and isinstance(right, int):
                return left * right
            if isinstance(left, int) and isinstance(right, str):
                return right * left
            return left * right
        if op == '/':
            if right == 0:
                raise NB3Error("Division by zero")
            return left / right
        if op == '%':
            return left % right
        if op == '==':
            return left == right
        if op == '!=':
            return left != right
        if op == '<':
            return left < right
        if op == '>':
            return left > right
        if op == '<=':
            return left <= right
        if op == '>=':
            return left >= right
        raise NB3Error(f"Unknown operator: {op}")

    def _truthy(self, val):
        if val is None:
            return False
        if isinstance(val, bool):
            return val
        if isinstance(val, (int, float)):
            return val != 0
        if isinstance(val, str):
            return len(val) > 0
        if isinstance(val, list):
            return len(val) > 0
        return True

    def _to_str(self, val):
        if val is None:
            return "none"
        if isinstance(val, bool):
            return "true" if val else "false"
        if isinstance(val, float):
            if val == int(val):
                return str(int(val))
            return str(val)
        return str(val)

    def _call_function(self, name, arg_nodes, env):
        # Builtins
        if name in self.builtins:
            args = [self.evaluate(a, env) for a in arg_nodes]
            return self.builtins[name](args)

        # User-defined functions
        func = env.get(name)
        if isinstance(func, NB3Function):
            args = [self.evaluate(a, env) for a in arg_nodes]
            return self._invoke_user_func(func, args)

        raise NB3Error(f"'{name}' is not a function")

    def _invoke_user_func(self, func, args):
        if len(args) != len(func.params):
            raise NB3Error(
                f"Function '{func.name}' expects {len(func.params)} args, got {len(args)}"
            )
        local_env = Environment(parent=func.closure)
        for param, arg in zip(func.params, args):
            local_env.set(param, arg)
        try:
            for stmt in func.body:
                self.execute(stmt, local_env)
        except ReturnSignal as r:
            return r.value
        return None

    def _call_method(self, obj, method, args):
        if isinstance(obj, list):
            if method == 'append':
                obj.append(args[0] if args else None)
                return None
            if method == 'pop':
                idx = int(args[0]) if args else -1
                return obj.pop(idx)
            if method == 'sort':
                obj.sort()
                return None
            if method == 'reverse':
                obj.reverse()
                return None
            if method == 'len':
                return len(obj)
            if method == 'insert':
                obj.insert(int(args[0]), args[1])
                return None
            if method == 'remove':
                obj.remove(args[0])
                return None
            if method == 'contains':
                return args[0] in obj
            if method == 'index':
                return obj.index(args[0])

        if isinstance(obj, str):
            if method == 'len':
                return len(obj)
            if method == 'upper':
                return obj.upper()
            if method == 'lower':
                return obj.lower()
            if method == 'strip':
                return obj.strip()
            if method == 'split':
                sep = args[0] if args else None
                return obj.split(sep)
            if method == 'replace':
                return obj.replace(args[0], args[1])
            if method == 'startswith':
                return obj.startswith(args[0])
            if method == 'endswith':
                return obj.endswith(args[0])
            if method == 'contains':
                return args[0] in obj
            if method == 'find':
                return obj.find(args[0])
            if method == 'join':
                return obj.join([self._to_str(x) for x in args[0]])
            if method == 'repeat':
                return obj * int(args[0])

        if isinstance(obj, dict):
            if method == 'keys':
                return list(obj.keys())
            if method == 'values':
                return list(obj.values())
            if method == 'has':
                return args[0] in obj
            if method == 'remove':
                return obj.pop(args[0], None)

        raise NB3Error(f"Unknown method '{method}' on {type(obj).__name__}")

    # ── Built-in Functions ─────────────────────────────────

    def _builtin_print(self, args):
        parts = [self._to_str(a) for a in args]
        self.output_func(' '.join(parts))
        return None

    def _builtin_input(self, args):
        prompt = self._to_str(args[0]) if args else ''
        raw = self.input_func(prompt)
        # Auto-detect type: try int, then float, else string
        try:
            return int(raw)
        except (ValueError, TypeError):
            pass
        try:
            return float(raw)
        except (ValueError, TypeError):
            pass
        return raw

    def _builtin_len(self, args):
        return len(args[0])

    def _builtin_str(self, args):
        return self._to_str(args[0])

    def _builtin_int(self, args):
        return int(args[0])

    def _builtin_float(self, args):
        return float(args[0])

    def _builtin_type(self, args):
        val = args[0]
        if isinstance(val, bool):
            return 'bool'
        if isinstance(val, int):
            return 'int'
        if isinstance(val, float):
            return 'float'
        if isinstance(val, str):
            return 'string'
        if isinstance(val, list):
            return 'list'
        if isinstance(val, NB3Function):
            return 'function'
        if val is None:
            return 'none'
        return 'unknown'

    def _builtin_range(self, args):
        if len(args) == 1:
            return list(range(int(args[0])))
        if len(args) == 2:
            return list(range(int(args[0]), int(args[1])))
        if len(args) == 3:
            return list(range(int(args[0]), int(args[1]), int(args[2])))
        raise NB3Error("range() takes 1-3 arguments")

    def _builtin_abs(self, args):
        return abs(args[0])

    def _builtin_min(self, args):
        if len(args) == 1 and isinstance(args[0], list):
            return min(args[0])
        return min(args)

    def _builtin_max(self, args):
        if len(args) == 1 and isinstance(args[0], list):
            return max(args[0])
        return max(args)

    def _builtin_round(self, args):
        if len(args) == 2:
            return round(args[0], int(args[1]))
        return round(args[0])

    def _builtin_random(self, args):
        return random.random()

    def _builtin_randint(self, args):
        return random.randint(int(args[0]), int(args[1]))

    def _builtin_sqrt(self, args):
        return math.sqrt(args[0])

    def _builtin_sleep(self, args):
        time.sleep(args[0])
        return None

    def _builtin_list(self, args):
        if not args:
            return []
        if isinstance(args[0], str):
            return list(args[0])
        return list(args[0])

    def _builtin_append(self, args):
        args[0].append(args[1])
        return None

    def _builtin_pop(self, args):
        return args[0].pop(int(args[1]) if len(args) > 1 else -1)

    def _builtin_sort(self, args):
        args[0].sort()
        return None

    def _builtin_reverse(self, args):
        args[0].reverse()
        return None

    def _builtin_join(self, args):
        return args[0].join([self._to_str(x) for x in args[1]])

    def _builtin_split(self, args):
        sep = args[1] if len(args) > 1 else None
        return args[0].split(sep)

    def _builtin_replace(self, args):
        return args[0].replace(args[1], args[2])

    def _builtin_upper(self, args):
        return args[0].upper()

    def _builtin_lower(self, args):
        return args[0].lower()

    def _builtin_strip(self, args):
        return args[0].strip()

    def _builtin_contains(self, args):
        return args[1] in args[0]

    def _builtin_keys(self, args):
        return list(args[0].keys())

    def _builtin_values(self, args):
        return list(args[0].values())
