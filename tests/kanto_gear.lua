local root,engine,gear=assert(arg[1]),assert(arg[2]),assert(arg[3]);package.path=engine..'/?.lua;'..package.path
local function read(p)local f=assert(io.open(root..'/'..p,'rb'));local b=f:read('*a');f:close();return b end
local function noop()end
local canvas={setFilter=noop,pollImageData=function()return{}end,newImageData=function()return{}end}
local G={push=noop,pop=noop,setCanvas=noop,origin=noop,setShader=noop,setScissor=noop,setBlendMode=noop,setColor=noop,clear=noop,rectangle=noop,translate=noop,draw=noop,setStencilTest=noop,newCanvas=function()return canvas end}
local clock=1
love={graphics=G,timer={getTime=function()return clock end}}
local nativeTouches=0
local Touch={touchpressed=function()nativeTouches=nativeTouches+1;return true end}
package.loaded['src.core.TouchControls']=Touch
local Pet=dofile(root..'/pet_logic.lua');local pets={};local inputCalls,ticks=0,0
local hooks={};local api={};local gearMod={log={info=noop,warn=function(_,message)error(message)end}}
local display={homeCatalog={packages={},surfaces={}},storeById={},storeCatalog={},home={}}
local session={active=true};local theme={i18n={extend=noop},hgss={v4AddAppIcon=noop}}
local registry=assert(loadfile(gear..'/mod/kanto_gear/runtime/modules.lua'))()(theme,display,gearMod,session)
local mod={find=function(id)return id=='kanto_gear'and{exports={modules=registry.exports}}end,
 hooks={wrap=function(_,k,fn)hooks[k]=fn end},log=gearMod.log}
-- Real game logic/handlers, lightweight art/text providers.
local Solitaire=assert(load(read('solitaire_screen.lua')))()({read=function()end},dofile(root..'/solitaire_logic.lua'))
local More=dofile(root..'/more_screen.lua')(Solitaire,dofile(root..'/more_logic.lua'))
local art={new=function()return{valid={PIKACHU=true},name=function()return'PIKACHU'end,choose=function()return'PIKACHU'end,picture=function()return nil end}end}
local storageMod={storage={read=function(_,game)return pets[game.save]end,write=function(_,game,_,value)pets[game.save]=value;return true end}}
local New=dofile(root..'/new_screen.lua')(noop,dofile(root..'/mines_logic.lua'),Pet,art,storageMod,dofile(root..'/pet_viewport.lua'),dofile(root..'/touch_layout.lua'))
local Screen=dofile(root..'/games_screen.lua')(Solitaire,dofile(root..'/arcade_logic.lua'),More,New)
local host=dofile(root..'/kanto_gear.lua')(mod,Screen,noop,function()return true end,dofile(root..'/direct_touch.lua')(dofile(root..'/touch_layout.lua')))
assert(#registry.order==1 and registry.order[1]=='pc_games','Only one PC Games tile is permitted')
local function game()
 local world={};return{save={},options={modOptions={kanto_gear={display_mode='combined'}}},input={isDown=function()return true end,wasPressed=function()return true end},stack={states={world},top=function()return world end}}
end
local count=0;local function check(v,message)count=count+1;assert(v,message)end
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal','ruby','sapphire','emerald','firered','leafgreen'})do
 local gen=(edition=='red'or edition=='blue'or edition=='yellow')and 1 or(edition=='gold'or edition=='silver'or edition=='crystal')and 2 or 3
 local g=game();local physical=g.input;local world=g.stack.states[1]
 host.bind(g);registry.applyAvailability{edition=edition,generation=gen};display.homeCatalog.packages.pc_games.installed=true
 check(registry.open('pc_games'),'Store open failed: '..edition);check(registry.anyShown(),'Gear does not stand down')
 check(g.input==physical and #g.stack.states==1 and g.stack.states[1]==world,'Native game input or stack changed')
 local upper=hooks['render.viewport'](function()return nil end,{width=960,height=720})
 check(upper.capture and upper.height<720 and host.layout.y>=upper.height,'Lower surface overlaps game')
 hooks['render.window'](function()inputCalls=inputCalls+1 end,g,{dpiX=1})
 local r=host.rect
 check(Touch:touchpressed(100,r.x+1,r.y+1)==false,'Native touch overlay intercepted lower app')
 check(Touch:touchpressed(100,0,0)==true,'Upper native touch control blocked')
 local function touch(phase,id,x,y)return hooks['input.pointer'](function()inputCalls=inputCalls+1;return'upper'end,g,{phase=phase,source='touch',id=id,x=r.x+x*r.w/240,y=r.y+y*r.h/216})end
 check(hooks['input.pointer'](function()return'upper'end,g,{phase='pressed',source='touch',id=80,x=0,y=0})=='upper','Upper touch swallowed')
 touch('pressed',1,40,16+30+6*20+3);touch('released',1,40,169)
 check(host.screen.mode=='pokepet','PokePet must open from Games list')
 local child=host.screen.child;local bond=child.state.bond
 touch('pressed',2,35,16+142);touch('released',2,35,158)
 check(child.state.bond==bond+1 and pets[g.save].bond==bond+1,'Touch care did not persist')
 hooks['input.step'](function(stepGame)check(stepGame.input==physical,'Physical input replaced');ticks=ticks+1;return'world tick'end,g,.05)
 check(child.state.age>0 and ticks>0,'World and minigame did not both advance')
 host.close();check(not registry.anyShown()and #g.stack.states==1,'Closing failed to restore Gear')
 check(pets[g.save].age==child.state.age,'Close did not save latest pet progress')
 registry.open('pc_games');host.screen:launch(3)
 hooks['render.viewport'](function()return nil end,{width=960,height=720})
 hooks['render.window'](function()end,g,{dpiX=1});r=host.rect
 touch('pressed',3,55,195);touch('pressed',4,96,190)
 check(host.held.right and host.held.a and physical==g.input,'Multitouch leaked physical input')
 touch('released',3,300,250);check(not host.held.right and host.held.a,'Outside release stuck or released other finger')
 touch('cancelled',4,0,0);check(not next(host.held),'Focus cancellation stuck')
 for n=1,7 do host.screen:launch(n);hooks['input.step'](function()return true end,g,.016)end
 local function tap(x,y)touch('pressed',90,x,y+16);touch('released',90,x,y+16)end
 host.screen:launch(1);local sol=host.screen.child
 local stock=#sol.state.stock;tap(5,20);check(#sol.state.stock<stock,'Stock tap did not draw')
 sol.state.waste={{suit='hearts',rank=1,up=true}};tap(39,20);tap(107,20)
 check(#sol.state.foundations[1]==1 and not sol.held,'Card taps did not move Ace to foundation')
 host.screen:launch(4);local black=host.screen.child
 black.state.phase='player';black.state.player={{rank=7},{rank=7}};black.state.dealer={{rank=10},{rank=7}}
 tap(110,black.h-23);check(black.state.phase=='done','Stand action did not respond to direct tap')
 host.screen:launch(5);local collapse=host.screen.child
 collapse.state.board[12]={1,1,1};tap(56,16+11*13+5)
 check(collapse.state.score>0,'Collapse group tap did not clear')
 host.screen:launch(6);local mines=host.screen.child
 touch('pressed',91,51,50)
 for _=1,5 do hooks['input.step'](function()end,g,.1)end
 touch('released',91,51,50)
 check(mines.state.cells[1][1].flag and not mines.state.cells[1][1].open,'Long press must flag without revealing')
 tap(68,34);check(mines.state.cells[1][2].open,'Cell tap did not reveal')
 touch('pressed',92,136,5);touch('released',92,136,5)
 check(mines.pause,'Header MENU did not open pause')
 tap(120,math.floor((mines.h-62)/2)+20);check(not mines.pause,'Pause entry did not respond to tap')
 host.bind(game());check(not host.screen and not next(host.held),'Game change retained active input')
end
-- Native second screen, physical-button isolation, detach fallback and close.
local external=game();external.options.modOptions.kanto_gear.display_mode='separate'
local queue={};local pushes=0;local connected=true
local bridge={detected=function()return connected end,pollTouch=function()return table.remove(queue,1)end,push=function()pushes=pushes+1;return true end,setEnabled=noop}
hooks['render.compose'](function()return'base'end,{}, {secondScreen=bridge})
host.bind(external);check(registry.open('pc_games')and host.external,'Native secondary display not selected')
check(hooks['render.viewport'](function()return nil end,{width=960,height=720})==nil,'Secondary mode shrank main display')
queue={'down,40,169','up,40,169'}
hooks['render.compose'](function()return'base'end,{}, {secondScreen=bridge})
check(host.screen.mode=='pokepet'and pushes==1,'Secondary frame/touch failed')
connected=false;hooks['render.viewport'](function()return nil end,{width=960,height=720})
check(not host.external and host.layout,'Disconnect did not fall back to lower window')
host.close();check(not registry.anyShown(),'Gear did not reclaim display')
connected=true;local requested=0;local ready=false
canvas.requestImageData=function()requested=requested+1;return true end
canvas.pollImageData=function()if ready then return{}end end
check(registry.open('pc_games'),'Reopen after detach failed')
local before=pushes
hooks['render.compose'](function()end,{}, {secondScreen=bridge})
check(requested==1 and pushes==before,'Async frame did not defer readback')
clock=clock+.04;hooks['render.compose'](function()end,{}, {secondScreen=bridge})
check(requested==1 and host.pending,'Pending readback was overwritten')
ready=true;clock=clock+.04;hooks['render.compose'](function()end,{}, {secondScreen=bridge})
check(pushes==before+1 and requested==2,'Completed async frame not submitted')
bridge.push=function()return false end
clock=clock+.04;hooks['render.compose'](function()end,{}, {secondScreen=bridge})
hooks['render.viewport'](function()return nil end,{width=960,height=720})
check(host.screen and not host.external and host.layout,'Failed presentation stranded app')
host.close()
print('Kanto Gear integration: '..count..' checks, eleven editions, real KG modules API, seven games, separate input and pet saves')
