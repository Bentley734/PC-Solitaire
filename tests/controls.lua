local root=assert(arg[1])
local function read(path)local f=assert(io.open(root..'/'..path,'rb'));local b=f:read('*a');f:close();return b end
local L=assert(load(read('solitaire_logic.lua')))()
love={graphics={newImage=function()error('use fallback')end},filesystem={newFileData=function()end}}
local S=assert(load(read('solitaire_screen.lua')))()({read=function()return nil end},L)
local n=0;local function ok(v,msg)assert(v,msg);n=n+1 end
local g={input={pressed={}}};function g.input:wasPressed(k)return self.pressed[k]end
local closed=0;local s=S.new(g,160,144,function()closed=closed+1 end)
local function press(k,dt)g.input.pressed={[k]=true};s:update(dt or .05);g.input.pressed={}end
press('a');ok(#s.state.waste==1,'abstract stock action')
press('right');press('a');ok(s.held and s.held.kind=='waste','pick waste')
press('b');ok(not s.held and not s.pause,'cancel')
s.state.waste={{suit='hearts',rank=1,up=true}};press('a');press('a');ok(#s.state.foundations[1]==1 and not s.held,'double tap foundation')
press('start');ok(s.pause and s.menu==1,'pause');press('down');press('down');press('a');ok(s.state.draw==3,'toggle')
press('b');ok(not s.pause,'resume');press('select');ok(s.pause,'select pause');press('down');press('a');ok(#s.state.stock==24 and s.state.draw==3,'new deal retains mode')
press('down');ok(s.row==1,'enter tableau');press('right');press('right');ok(s.col==3 and s.index==3,'first faceup clamp')
-- Build a face-up run and check per-card navigation.
s.state.tableau[3]={{suit='hearts',rank=7,up=false},{suit='clubs',rank=6,up=true},{suit='hearts',rank=5,up=true}}
s.index=2;press('down');ok(s.index==3,'down run');press('down');ok(s.index==3,'bottom clamp');press('up');ok(s.index==2,'up run');press('up');ok(s.row==0,'up top row')
press('b');ok(s.pause and s.menu==4,'exit prompt');press('b');ok(not s.pause and closed==0,'cancel exit');press('b');press('a');ok(closed==1,'confirm exit');press('a');ok(closed==1,'closed screen inert')
print('Control assertions: '..n)
