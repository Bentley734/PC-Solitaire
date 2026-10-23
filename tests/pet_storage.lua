local root,engine=assert(arg[1]),assert(arg[2]);package.path=engine..'/?.lua;'..package.path
local P=dofile(root..'/pet_logic.lua');local files={}
local fs={getInfo=function(path)return files[path]and {type='file',size=#files[path]}end,
 read=function(path)return files[path]end,write=function(path,value)files[path]=value;return true end,
 createDirectory=function()return true end,remove=function(path)files[path]=nil;return true end}
love={filesystem=fs}
local storage=require('src.mods.Storage').new('pc_solitaire',fs)
local a={save={version='red',meta={playthroughId='pet_test_A'}}}
local b={save={version='red',meta={playthroughId='pet_test_B'}}}
local c={save={version='emerald',meta={playthroughId='pet_test_A'}}}
local s=P.new('SPRIGATITO');s.food=42;P.care(s,1);P.tick(s,20)
assert(storage:write(a,'pokemon_pet',P.snapshot(s)))
local loaded=assert(storage:read(a,'pokemon_pet'));assert(loaded.species=='SPRIGATITO'and loaded.bond==1 and loaded.food==s.food and loaded.age==20)
assert(not storage:read(b,'pokemon_pet')and not storage:read(c,'pokemon_pet'),'pet scoped to game and playthrough')
s=P.new(1089);s.sleeping=true;assert(storage:write(c,'pokemon_pet',P.snapshot(s)))
loaded=assert(storage:read(c,'pokemon_pet'));assert(loaded.species==1089 and loaded.sleeping,'numeric Gen3 species round trip')
assert(storage:read(a,'pokemon_pet').species=='SPRIGATITO','other pet unaffected')
print('Native mod storage round trips: PASS')
