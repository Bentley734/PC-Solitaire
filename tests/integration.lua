-- Runs against the real 0.3.54 PC modules using headless graphics/audio.
local root=assert(arg[1]);local engine=assert(arg[2]);package.path=engine..'/?.lua;'..package.path
local function noop() end
love={graphics={getColor=function() return 1,1,1,1 end,setColor=noop,rectangle=noop,print=noop,printf=noop,draw=noop,newQuad=function()return {}end,newImage=function()error('fallback')end,getShader=noop,setShader=noop,newShader=function()error('headless')end,getDimensions=function()return 160,144 end,push=noop,pop=noop,translate=noop,scale=noop,circle=noop,clear=noop,setLineWidth=noop},math={random=math.random},filesystem={load=noop,getInfo=noop,read=noop,write=function()return true end,remove=function()return true end,newFileData=function(bytes)return bytes end},timer={getTime=function()return 0 end}}
local Runtime=require('src.mods.Runtime');local Version=require('src.core.GameVersion')
-- ROM-owned strings are a fixture; menu code, stacks and dispatch stay native.
local RomText=require('src.core.game3.rom_text')
RomText.plain=function(key)return key end
RomText.lazy=function(t)return t end
require('src.ui.game3.chrome').stdFrame=function()end
require('src.ui.game3.frlg_font').draw=function()end
require('src.ui.game3.frlg_font').drawGlyph=function()end
love.graphics.getPixelDimensions=function()return 1280,960 end
love.graphics.newCanvas=function()return {setFilter=function()end}end
love.graphics.getCanvas=noop;love.graphics.setCanvas=noop;love.graphics.origin=noop
love.graphics.setScissor=noop;love.graphics.setBlendMode=noop
local checks=0
local function ok(v,msg) assert(v,msg);checks=checks+1 end
local function read(path) local f=io.open(root..'/'..path,'rb');if not f then return end;local b=f:read('*a');f:close();return b end
local function newGame()
 local g={data={pokemon={PIKACHU={name='PIKACHU',spriteFront='fixture.png'}}},save={party={{species=1}},player={name='TEST'},engineFlags={}},input={pressed={}}}
 function g.input:wasPressed(k) return self.pressed[k] or false end
 g.stack={states={}};function g.stack:push(s) self.states[#self.states+1]=s end;function g.stack:pop() return table.remove(self.states) end;function g.stack:top() return self.states[#self.states] end
 g.draw=function(self)self.nativeDraws=(self.nativeDraws or 0)+1 end
 return g
end
local hooks,events={},{}
local pets={}
local mod={read=function(_,path)return read(path)end,hooks={wrap=function(_,name,fn)hooks[name]=fn end},events={on=function(_,name,fn)events[name]=fn end},exports={},
 storage={read=function(_,game)return pets[game]end,write=function(_,game,_,value)pets[game]=value;return true end}}
assert(load(read('main.lua')))()(mod)
-- Wire the public hook into the native constructors without a full loader boot.
local oldCall=Runtime.call
Runtime.call=function(name,next,...) if hooks[name] then return hooks[name](next,...) end;return oldCall(name,next,...) end
local function tour(g,handle,draw)
 local function press(key)g.input.pressed={[key]=true};handle(g.input);g.input.pressed={}end
 -- Each game must return to the same submenu before it can return to the PC.
 press('a');draw();press('b');press('a') -- Solitaire -> Games
 press('down');press('a');draw();press('b');press('down');press('down');press('a') -- Snake -> Games
 press('down');press('a');draw();press('b');press('down');press('down');press('a') -- Tetris -> Games
 for _=4,7 do
  press('down');press('a');draw();press('start');press('down');press('down');press('a')
 end
 ok(pets[g]and pets[g].species,'pet adopted and saved through every native PC path')
 press('b')
end
local function exit(g,s)
 local before=g.nativeDraws or 0;g:draw();ok((g.nativeDraws or 0)==before,'integer presenter owns active PC games')
 tour(g,function(input)s:handle(input)end,function()s:draw()end)
 g:draw();ok(g.nativeDraws==before+1,'native renderer restored after Games')
end
for _,id in ipairs({'red','blue','yellow','gold','silver','crystal','firered','leafgreen','ruby','sapphire','emerald'}) do
 Version.set(id);local g=newGame();events['game.ready']({game=g})
 if Version.generation()==1 then
  local rows=hooks['ui.pc.items'](function(_,r)return r end,g,{{label='PC'}})
  ok(#rows==2 and rows[2].keepOpen,'Gen1 hub injection')
  local parent={};g.stack:push(parent);rows[2].onSelect();local s=g.stack:top();ok(s~=parent and s.w==160,'Gen1 open');s:draw();exit(g,s);ok(g.stack:top()==parent,'Gen1 return')
  local P=require('src.ui.PlayerPC');local p=P.new(g,{direct=true});ok(p.items[#p.items-1].label=='GAMES','Gen1 bedroom')
 elseif Version.generation()==2 then
  local Hub=require('src.ui.gen2.CenterPcMenu');local p=Hub.new(g);local index
  for i,r in ipairs(p.entries)do if r.label=='GAMES' then index=i end end
  ok(index and index==#p.entries-1,'Gen2 hub');p.index=index;g.stack:push(p);p:choose();local s=g.stack:top();ok(s~=p and s.w==160,'Gen2 open');s:draw();exit(g,s);ok(g.stack:top()==p,'Gen2 return')
  g.save.engineFlags[11]=true;g.save.hallOfFame={count=1};p:buildEntries()
  ok(#p.entries==6,'Gen2 postgame rows')
  local Chrome=require('src.ui.gen2.Chrome')
  local oldBox,oldPrint,oldCursor=Chrome.box,Chrome.print,Chrome.cursor
  local solitaireY
  Chrome.box=noop;Chrome.cursor=noop
  Chrome.print=function(label,_,y)if label=='GAMES' then solitaireY=y end end
  p.message=nil;p.booted=true;p:drawPanel()
  ok(solitaireY and solitaireY<12,'Gen2 postgame row above dialogue')
  Chrome.box,Chrome.print,Chrome.cursor=oldBox,oldPrint,oldCursor
  for _,name in ipairs({'src.ui.gen2.PcMenu','src.ui.gen2.ItemPcMenu'}) do
   local c=require(name).new(g,{house=true});local found
   for i,r in ipairs(c.entries) do if r.label=='GAMES' then found=i end end
   ok(found,'Gen2 direct PC row');c.index=found;g.stack:push(c);c:choose();s=g.stack:top();ok(s~=c,'Gen2 direct open');exit(g,s);ok(g.stack:top()==c,'Gen2 direct return')
  end
 else
  local Pokemon=require('src.core.game3.pokemon')
  Pokemon._names={[25]='PIKACHU'};Pokemon._national={toNational={[25]=25}}
  local PC=require('src.ui.game3.pc_menu');local Stack=require('src.ui.game3.stack');Stack.clear()
  local session={name='TEST',version=id,party={}}
  PC.show({session=session,startMode='select'});local rows=PC._rootEntries();ok(rows[#rows-1].id=='pc_solitaire' and rows[#rows].id=='quit','Games directly before Log Off');ok(#PC._rootEntries()==#rows,'no duplicate')
  PC.cursor=#rows-1;g.input.pressed={a=true};PC.handleInput(g.input);local layer=Stack.top();ok(layer.id=='pc_solitaire','Gen3 open');layer.mod.draw();layer.mod.update(.1);g:draw();ok(not g.nativeDraws,'Gen3 integer presenter')
  tour(g,layer.mod.handleInput,layer.mod.draw);ok(Stack.top().id=='pc_menu' and PC.open and PC.cursor==#rows-1,'Gen3 return')
  g.input.pressed={down=true};PC.handleInput(g.input);g.input.pressed={a=true};PC.handleInput(g.input);g.input.pressed={}
  ok(not PC.open and PC._result==#rows-2,'Log Off preserves native script result')
  PC.show({session=session});PC.cursor=#PC._rootEntries();g.input.pressed={a=true};PC.handleInput(g.input);g.input.pressed={}
  ok(not PC.open,'non-script Log Off still closes')
  PC.show({session=session,startMode='player_pc',bedroom=true})
  ok(Stack.top().id=='pc_menu' and Stack.depth()==1,'Gen3 bedroom native menu only')
  ok(PC.mode=='player_pc','Gen3 original PC mode')
  local order
  if require('src.core.game3.profile').family(session)=='rse' then order=require('src.ui.game3.rse.player_pc').topOrder(PC)
  else order={};for i,e in ipairs(PC.TOP_ACTIONS)do order[i]=e.id end end
  local games
  for i,id in ipairs(order)do if id=='pc_games'then games=i end end
  ok(games and games==#order-1,'Games before native Turn Off')
  if require('src.core.game3.profile').family(session)=='rse' then
   local Rse=require('src.ui.game3.rse.player_pc')
   local drawMenu,drawStatus=Rse.drawMenu,Rse.drawStatus
   local labels,statusCalls
   Rse.drawMenu=function(rows)labels=rows end
   Rse.drawStatus=function()statusCalls=(statusCalls or 0)+1 end
   PC.draw()
   ok(labels and labels[games]=='GAMES' and #labels==#order,'native RSE menu includes Games')
   ok(statusCalls==1,'native status drawn once')
   Rse.drawMenu,Rse.drawStatus=drawMenu,drawStatus
  end
  PC.cursor=games;g.input.pressed={a=true};PC.handleInput(g.input);g.input.pressed={}
  ok(Stack.top().id=='pc_solitaire','Gen3 bedroom Games open')
  layer=Stack.top();tour(g,layer.mod.handleInput,layer.mod.draw)
  ok(Stack.top().id=='pc_menu' and PC.open and PC.mode=='player_pc' and PC.cursor==games,'Gen3 native bedroom return')
  -- Navigation uses the real PC handler, including the inserted row.
  g.input.pressed={down=true};PC.handleInput(g.input);g.input.pressed={}
  ok(PC.cursor==games+1,'native navigation to Turn Off')

 end
 print('PC adapters passed: '..id)
end
print('Native integration assertions: '..checks)
