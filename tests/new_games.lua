local root=assert(arg[1]);local M=dofile(root..'/mines_logic.lua');local P=dofile(root..'/pet_logic.lua');local n=0
local function ok(v,msg)assert(v,msg);n=n+1 end
for seed=1,100 do
 math.randomseed(seed);local s=M.new();local x,y=math.random(9),math.random(9)
 M.flag(s,x,y);ok(not M.reveal(s,x,y)and not s.started,'flagged first click inert');M.flag(s,x,y)
 M.reveal(s,x,y);ok(s.started and not s.over and s.cells[y][x].n==0,'safe first reveal')
 local mines=0
 for b=1,9 do for a=1,9 do
  local c=s.cells[b][a];if c.mine then mines=mines+1 end
  local count=0;for dy=-1,1 do for dx=-1,1 do
   local row=s.cells[b+dy];local other=row and row[a+dx]
   if other and (dx~=0 or dy~=0)and other.mine then count=count+1 end
  end end
  ok(c.n==count,'correct adjacent counts')
  if math.abs(a-x)<=1 and math.abs(b-y)<=1 then ok(not c.mine,'first neighborhood safe')end
 end end
 ok(mines==10,'exact mine count')
 for b=1,9 do for a=1,9 do if not s.cells[b][a].mine then M.reveal(s,a,b)end end end
 ok(s.won and s.revealed==71,'all safe cells win');ok(not M.flag(s,1,1)and not M.reveal(s,1,1),'won inert')
end
local s=M.new();s.started=true;s.cells[1][1].mine=true;M.reveal(s,1,1);ok(s.over and not s.won and s.hit.x==1,'mine loses')
s=M.new();for x=1,9 do M.flag(s,x,1)end;M.flag(s,1,2);ok(not M.flag(s,2,2)and s.flags==10,'flag limit');M.flag(s,1,1);ok(s.flags==9,'unflag')
-- Controlled 3x3 chord cases, with and without a correct flag.
local function chord()
 local t={w=3,h=3,mines=1,cells={},started=true,revealed=1,flags=1}
 for y=1,3 do t.cells[y]={};for x=1,3 do t.cells[y][x]={n=(x<=2 and y<=2)and 1 or 0}end end
 t.cells[1][1].mine=true;t.cells[2][2].open=true;return t
end
s=chord();s.cells[1][1].flag=true;M.reveal(s,2,2);ok(s.won,'correct chord opens neighbors')
s=chord();s.cells[1][2].flag=true;M.reveal(s,2,2);ok(s.over and not s.won,'incorrect chord loses')
local pet=P.new('PIKACHU');P.tick(pet,60);ok(pet.age==60 and pet.food<80 and pet.energy<80,'active care decay')
local a=P.new(1);local b=P.new(1);P.tick(a,60);for _=1,600 do P.tick(b,.1)end;ok(math.abs(a.food-b.food)<.00001,'frame independent needs')
pet.food=25;P.care(pet,1);ok(pet.food==50 and pet.bond==1,'feed improves food')
pet.happy=10;pet.energy=30;P.care(pet,2);ok(pet.happy==32 and pet.energy==18,'play costs energy')
pet.energy=1;local bond=pet.bond;ok(P.care(pet,2)=='TOO TIRED'and pet.bond==bond,'tired play blocked')
P.care(pet,3);local food=pet.food;ok(P.care(pet,1)=='LET ME SLEEP'and pet.food==food,'sleep blocks care')
P.tick(pet,60);ok(pet.energy>1,'sleep recovers energy');P.care(pet,3);pet.clean=5;P.care(pet,4);ok(pet.clean==100,'clean restores hygiene')
local snap=P.snapshot(pet);snap.food=0;ok(pet.food>0,'snapshot isolated')
snap.food=0/0;snap.age=-1;snap.bond=math.huge
local restored=P.restore(snap,function(id)return id=='PIKACHU'end);ok(restored.food==80 and restored.age==0 and restored.bond==0,'bad stats sanitized')
ok(not P.restore(snap,function()return false end),'removed species rejected');snap.version=2;ok(not P.restore(snap,function()return true end),'unsupported version rejected')
-- Child controls, pause and durable care state through the real screen factory.
local stored;local writes=0
local mod={storage={read=function()return stored end,write=function(_,_,_,value)stored=value;writes=writes+1;return true end}}
local cries=0
local Art={new=function()return {valid={PIKACHU='PIKACHU'},choose=function()return 'PIKACHU'end,picture=function()end,cry=function(_,id)ok(id=='PIKACHU','cry for adopted species');cries=cries+1 end}end}
local S=dofile(root..'/new_screen.lua')(function()end,M,P,Art,mod)
local input={};function input:wasPressed(k)return self.key==k end
local closed=0;local screen=S.new({},160,144,function()closed=closed+1 end,1)
local function press(key)input.key=key;screen:handle(input);input.key=nil end
screen:tick(2);ok(screen.state.time==0,'timer before first reveal');press('select');ok(screen.state.flags==1,'select flags');press('a');ok(not screen.state.started,'A respects flag');press('select');press('a');screen:tick(2);ok(screen.state.time==2,'timer after reveal')
press('b');screen:tick(20);ok(screen.state.time==2,'mines paused');press('down');press('a');ok(not screen.state.started and not screen.pause,'mines new game')
press('start');press('down');press('down');press('a');ok(closed==1,'mines return')
screen=S.new({},160,144,function()closed=closed+1 end,2);ok(stored.species=='PIKACHU','random species saved on adoption')
press('a');ok(stored.food==100 and stored.bond==1,'care saved immediately');screen:tick(2);press('right');press('a');ok(stored.bond==2,'navigate play')
screen:tick(16);ok(writes>=4 and stored.age>=18,'periodic progress save');ok(cries==2,'successful feed and play cry once each')
press('b');local age=screen.state.age;screen:tick(30);ok(screen.state.age==age,'pet paused')
press('down');press('a');ok(screen.confirm,'new pet requires confirmation');press('b');ok(not screen.confirm and screen.state.bond==2,'keep pet')
press('down');press('a');ok(closed==2,'pet return')
screen=S.new({},240,160,function()end,2);ok(screen.state.bond==2 and screen.state.age==stored.age,'reopen retains identity and care')
press('b');press('down');press('a');press('a');ok(screen.state.bond==0 and stored.bond==0 and not screen.pause,'confirmed new adoption')
local NoStorage=dofile(root..'/new_screen.lua')(function()end,M,P,Art,{})
ok(NoStorage.new({},160,144,function()end,2).saved==false,'save failure visible')
local before=cries
screen.state.food=100;screen.action=1;press('a');ok(cries==before,'full pet does not cry for rejected feeding')
screen:tick(2);screen.state.energy=0;screen.action=2;press('a');ok(cries==before,'tired pet does not cry for rejected play')
screen:tick(2);screen.state.sleeping=true;screen.action=1;press('a');ok(cries==before,'sleeping pet does not cry for rejected feeding')
screen:tick(2);screen.action=3;press('a');screen:tick(2);screen.action=4;press('a');ok(cries==before,'wake and clean stay quiet')
screen:tick(2);screen.action=1;screen.state.food=40;screen.art.cry=function()error('audio unavailable')end;press('a');ok(screen.state.food==65,'audio failure does not interrupt care')
print('Minesweeper and pet assertions: '..n)
