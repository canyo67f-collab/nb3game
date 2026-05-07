#!/usr/bin/env python3
"""
NB3Lang - entry point.

Usage:
    python -m nb3lang <file.nb3>
    python -m nb3lang              (interactive REPL)
"""

import sys
import os

# Allow running as `python nb3lang/main.py` from the repo root
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from nb3lang.lexer import Lexer, LexerError
from nb3lang.parser import Parser, ParseError
from nb3lang.interpreter import Interpreter, NB3Error


def run_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        source = f.read()
    run_source(source)


def run_source(source):
    try:
        tokens = Lexer(source).tokenize()
        tree = Parser(tokens).parse()
        interp = Interpreter()
        interp.run(tree)
    except LexerError as e:
        print(f"Lexer error: {e}", file=sys.stderr)
        sys.exit(1)
    except ParseError as e:
        print(f"Parse error: {e}", file=sys.stderr)
        sys.exit(1)
    except NB3Error as e:
        print(f"Runtime error: {e}", file=sys.stderr)
        sys.exit(1)


def repl():
    print("NB3Lang REPL v0.1  (type 'exit' to quit)")
    print("─" * 40)
    interp = Interpreter()
    buffer = []
    indent_level = 0

    while True:
        try:
            prompt = "... " if indent_level > 0 else ">>> "
            line = input(prompt)
        except (EOFError, KeyboardInterrupt):
            print("\nBye!")
            break

        if line.strip() == 'exit':
            print("Bye!")
            break

        buffer.append(line)

        # Track indent level
        stripped = line.strip()
        if stripped.endswith(':'):
            indent_level += 1
            continue
        elif indent_level > 0:
            if stripped == '':
                indent_level = 0
            else:
                continue

        source = '\n'.join(buffer) + '\n'
        buffer = []
        indent_level = 0

        try:
            tokens = Lexer(source).tokenize()
            tree = Parser(tokens).parse()
            interp.run(tree)
        except LexerError as e:
            print(f"Lexer error: {e}")
        except ParseError as e:
            print(f"Parse error: {e}")
        except NB3Error as e:
            print(f"Error: {e}")


def main():
    if len(sys.argv) > 1:
        run_file(sys.argv[1])
    else:
        repl()


if __name__ == '__main__':
    main()
