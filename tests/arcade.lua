local root=assert(arg[1]);local R=dofile(root..'/arcade_logic.lua')
local n=0;local function ok(v,msg)assert(v,msg);n=n+1 end
local function rng(max)return max end
local s=R.snake(rng);ok(#s.body==3 and s.food,'snake initial')
ok(not R.turn(s,-1,0),'no reverse');ok(R.turn(s,0,-1),'queue turn');ok(not R.turn(s,-1,0),'one turn per tick')
R.snakeStep(s);ok(s.body[1].x==8 and s.body[1].y==6 and #s.body==3,'turn movement')
s.food={x=8,y=5};R.snakeStep(s);ok(s.score==10 and #s.body==4,'food growth')
for _,p in ipairs(s.body)do ok(p.x~=s.food.x or p.y~=s.food.y,'food unoccupied')end
s.body[1]={x=1,y=1};s.dx=-1;s.dy=0;R.snakeStep(s);ok(s.over,'wall collision')
s=R.snake(rng);s.body={{x=2,y=2},{x=2,y=3},{x=1,y=3},{x=1,y=2}};s.dx=-1;s.dy=0;s.food={x=10,y=10};R.snakeStep(s);ok(not s.over,'vacating tail legal')
s=R.snake(rng);s.body={{x=2,y=2},{x=1,y=2},{x=1,y=3},{x=2,y=3}};s.dx=-1;R.snakeStep(s);ok(s.over,'self collision')
s=R.snake(rng);s.body={};for y=1,16 do for x=1,20 do s.body[#s.body+1]={x=x,y=y}end end;R.food(s);ok(s.won and s.over and not s.food,'filled board win')
for seed=1,30 do
 math.randomseed(seed);local t=R.tetris();local seen={}
 for _=1,7 do ok(not seen[t.piece.id],'seven bag uniqueness');seen[t.piece.id]=true;R.spawn(t)end
end
local t=R.tetris(rng);t.piece={id=1,x=4,y=2,rot=0}
for _=1,4 do ok(R.shift(t,0,0,1),'rotation fits')end;ok(t.piece.rot==0,'four rotations')
while R.shift(t,-1,0)do end;ok(not R.shift(t,-1,0),'left wall');ok(R.shift(t,0,0,1),'wall rotation')
t=R.tetris(rng);t.piece={id=1,x=4,y=18,rot=0};for x=1,10 do if x<4 or x>7 then t.board[20][x]=2 end end
R.drop(t,true);ok(t.lines==1 and t.score>=100,'single clear');ok(not t.board[20][1],'clear removes row')
t=R.tetris(rng);for y=17,20 do for x=1,10 do if x~=5 then t.board[y][x]=2 end end end
t.piece={id=1,x=3,y=1,rot=1};R.drop(t,true);ok(t.lines==4 and t.score>=800,'four line clear')
t=R.tetris(rng);t.lines=9;t.piece={id=1,x=4,y=18,rot=0};for x=1,10 do if x<4 or x>7 then t.board[20][x]=2 end end;R.drop(t,true);ok(t.level==2,'level progression')
t=R.tetris(rng);for y=1,3 do for x=1,10 do t.board[y][x]=3 end end;R.spawn(t);ok(t.over,'spawn blocked')
t=R.tetris(rng);t.piece={id=2,x=4,y=-1,rot=0};R.lock(t);ok(t.over,'top out')
-- Host controls and simulation pause, independent of rendering.
local function read(path)local f=assert(io.open(root..'/'..path));local b=f:read('*a');f:close();return b end
love={graphics={newImage=function()error('fallback')end},filesystem={newFileData=function()end}}
local S=assert(load(read('solitaire_screen.lua')))()({read=function()return nil end},dofile(root..'/solitaire_logic.lua'))
local G=assert(load(read('games_screen.lua')))()(S,R)
local input={pressed={}};function input:wasPressed(k)return self.pressed[k]end
local closed=0;local host=G.new({input=input},160,144,function()closed=closed+1 end)
local function press(k)input.pressed={[k]=true};host:handle(input);input.pressed={}end
press('down');press('a');ok(host.mode=='snake','launch snake')
local x=host.state.body[1].x;host:tick(.2);ok(host.state.body[1].x==x+1,'snake timer')
press('b');x=host.state.body[1].x;host:tick(5);ok(host.state.body[1].x==x,'paused simulation')
press('down');press('down');press('a');ok(not host.mode,'snake submenu return')
press('down');press('a');ok(host.mode=='tetris','launch tetris')
x=host.state.piece.x;press('left');ok(host.state.piece.x==x-1,'tetris lateral input')
local y=host.state.piece.y;host:tick(.8);ok(host.state.piece.y==y+1,'gravity timer')
function input:isDown(k)return self.held==k end
input.held='right';x=host.state.piece.x;host:tick(.01);host:tick(.18);ok(host.state.piece.x==x+1,'held move repeat')
input.held='down';y=host.state.piece.y;host:tick(.01);host:tick(.05);ok(host.state.piece.y==y+1,'held soft drop')
input.held=nil;host:tick(.01)
press('up');ok(host.state.score>0,'hard drop score')
press('start');press('down');press('a');ok(host.state.score==0 and not host.pause,'new game')
press('select');press('down');press('down');press('a');ok(not host.mode,'tetris submenu return')
press('up');press('up');press('a');ok(host.child and host.mode=='solitaire','launch solitaire')
press('b');press('a');ok(not host.child and not host.mode,'solitaire submenu return')
press('b');ok(closed==1,'return pc');press('b');ok(closed==1,'closed inert')
print('Arcade and submenu assertions: '..n)
