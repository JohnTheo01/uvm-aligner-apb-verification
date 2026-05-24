# Usage: python3 sv_include_guard.py <filepath>
# Adds a `ifndef/`define/`endif guard at the top/bottom of a .sv file.
# The guard name is derived from the filename (e.g. cfs_algn_if.sv → CFS_ALGN_IF_SV).
# No-op if a guard already exists.

import os
import sys

filepath = sys.argv[1]
name = os.path.basename(filepath).replace(".", "_").upper()

guard_open  = f"`ifndef {name}\n\n    `define {name}\n\n"
guard_close = f"\n`endif\n"

content = open(filepath).read()

if "`ifndef" not in content:
    open(filepath, "w").write(guard_open + content + guard_close)
