"""Exercise the actual Papyrus compiler's scaling bytecode, without a live game.
Usage: python tools/test_maid_body_scaling.py <MMEMaidBodyScaling.disassemble.pas>
"""
import math
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
block = re.search(r"\.function GetProgress static(.*?)\.endFunction", text, re.S)[1]
code = re.search(r"\.code(.*?)\.endCode", block, re.S)[1]
lines = [line.split(";")[0].strip() for line in code.splitlines() if line.split(";")[0].strip()]
labels = {line[:-1]: i for i, line in enumerate(lines) if line.endswith(":")}

def execute(level, maximum):
    registers = {"level": level, "maximum": maximum}
    def value(token):
        if token in registers:
            return registers[token]
        return float(token)
    pc = 0
    for _ in range(100):
        parts = lines[pc].split()
        pc += 1
        op, *args = parts
        if op.endswith(":"):
            continue
        if op == "Jump":
            pc = labels[args[0]]
        elif op == "JumpF":
            if not value(args[0]):
                pc = labels[args[1]]
        elif op == "Return":
            return value(args[0])
        elif op in ("Assign", "Cast"):
            registers[args[0]] = value(args[1])
        elif op == "FDivide":
            registers[args[0]] = value(args[1]) / value(args[2])
        elif op.startswith("Compare"):
            a, b = value(args[1]), value(args[2])
            registers[args[0]] = {"CompareLT": a < b, "CompareGT": a > b, "CompareLTE": a <= b, "CompareGTE": a >= b}[op]
        else:
            raise AssertionError(f"Unexpected compiled instruction: {op}")
    raise AssertionError("Bytecode did not return")

cases = [(-1, 20, 0), (0, 20, 0), (1, 20, .05), (10, 20, .5), (20, 20, 1), (200, 20, 1),
         (5, 0, .5), (5, 10, .5), (50, 100, .5), (50, 1000, .5)]
for level, cap, expected in cases:
    assert math.isclose(execute(level, cap), expected), (level, cap, expected)
for cap in range(10, 101):
    result = [execute(level, cap) for level in range(-1, 202)]
    assert result == sorted(result)
    assert min(result) == 0 and max(result) == 1
print("PASS: compiled progression: endpoints, fractions, invalid caps, clamping, monotonicity (18,483 cases)")

# The native API must receive typed empty arrays on cleanup, not invalid casts.
for function in re.findall(r"\.function .*?\.endFunction", text, re.S):
    arrays = re.findall(r"\.local (\S+) \w+\[\]", function)
    for name in arrays:
        assert not re.search(r"Cast " + re.escape(name) + r" None\b", function), name
assert "CallStatic NiOverride" not in text
assert re.search(r"CallStatic mmeextensionsnative ApplyMaidBodyMorphs .* candidate names values token", text, re.I)
print("PASS: compiled script has no direct NiOverride dependency or None-to-array casts; request token is passed")
