from pathlib import Path
import sys,json
from lupa.luajit21 import LuaRuntime
root=Path(__file__).resolve().parents[1]
engine=Path(sys.argv[1]).resolve()
for test in ['rules.lua','controls.lua','arcade.lua','effects.lua','more.lua','new_games.lua','pet_sprites.lua','pet_storage.lua','pixels.lua','integration.lua']:
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().arg=lua.table_from([str(root),str(engine)])
    lua.execute((root/'tests'/test).read_text())
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute("package.path=... .. '/?.lua;' .. package.path",str(engine))
def table(v):
    if isinstance(v,dict): return lua.table_from({k:table(x) for k,x in v.items()})
    if isinstance(v,list): return lua.table_from([table(x) for x in v])
    return v
manifest=json.loads((root/'manifest.json').read_text())
lua.globals().manifest=table(manifest)
lua.execute("local M=require('src.mods.Manifest');M.validate(manifest);assert(manifest.github=='Bentley734/PC-Solitaire')")
print('Manifest validation: PASS')
