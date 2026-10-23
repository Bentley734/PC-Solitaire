"""Integration with a local, unmodified Kanto Gear checkout.
Usage: python tests/run_kanto_gear.py ENGINE KANTO_GEAR_REPOSITORY
"""
from pathlib import Path
import sys
from lupa.luajit21 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().arg=lua.table_from([str(root),str(Path(sys.argv[1]).resolve()),str(Path(sys.argv[2]).resolve())])
lua.execute((root/'tests/kanto_gear.lua').read_text(encoding='utf-8'))
