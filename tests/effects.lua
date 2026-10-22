local root=assert(arg[1]);local function read(path)local f=assert(io.open(root..'/'..path));local b=f:read('*a');f:close();return b end
local R=dofile(root..'/arcade_logic.lua');local L=dofile(root..'/solitaire_logic.lua')
local n=0;local function ok(v,msg)assert(v,msg);n=n+1 end
love={graphics={newImage=function()error('fallback')end},filesystem={newFileData=function()end}}
local S=assert(load(read('solitaire_screen.lua')))()({read=function()return nil end},L)
local G=assert(load(read('games_screen.lua')))()(S,R)
local game={input={wasPressed=function()return false end}}
local s=S.new(game,160,144,function()end);local top=s.state.stock[#s.state.stock];s:act()
local e=s.effects[top];ok(e and e.x~=e.tx and e.flip and not e.fromUp and e.toUp,'stock slide and flip')
ok(#s.state.waste==1 and s.state.waste[1]==top,'rules commit once')
s:tick(.1);ok(s.effects[top],'in flight');s.pause=true;s:tick(1);ok(s.effects[top] and s.clock==.1,'pause freezes card animation')
s.pause=nil;s:tick(.15);ok(not next(s.effects),'animation finishes')
local hidden={suit='clubs',rank=4,up=false};local moved={suit='hearts',rank=3,up=true}
s.state.tableau={{hidden,moved},{{suit='clubs',rank=4,up=true}},{},{},{},{},{}};s.state.waste={};s.row=1;s.col=2;s.index=1;s.held={kind='tableau',pile=1,index=2};s:act()
ok(s.effects[moved] and s.effects[moved].x~=s.effects[moved].tx,'tableau slide')
ok(s.effects[hidden] and s.effects[hidden].flip,'exposed card flips')
ok(hidden.up and #s.state.tableau[2]==2,'move complete under animation')
local host=G.new(game,160,144,function()end);host:launch(1);host.child:act();host:tick(.1);ok(host.child.clock==.1,'host ticks card animations')
host:launch(2);local head=host.state.body[1];host.state.food={x=head.x+1,y=head.y};host:tick(.19)
ok(host.snakeFX and host.state.score==10 and #host.state.body==4,'eat produces growth effect')
host.pause=true;host:tick(2);ok(host.snakeFX.time==0,'snake effect pauses')
host.pause=nil;host.state.over=true;host:tick(.61);ok(not host.snakeFX,'snake effect expires after game over')
host:launch(3);local t=host.state;t.piece={id=1,x=4,y=18,rot=0}
for x=1,10 do if x<4 or x>7 then t.board[20][x]=2 end end
host:drop(true);ok(host.clearFX and t.lines==1,'clear animation event')
ok(host.clearFX.event.rows[1]==20 and host.clearFX.event.board[20][4]==1,'locked row snapshot')
ok(not t.board[20][1],'rules clear row once')
local y=t.piece.y;host:tick(.2);ok(host.clearFX and t.piece.y==y,'gravity suspended during clear')
local x=t.piece.x;host:handle({wasPressed=function(_,key)return key=='left'end});ok(t.piece.x==x,'movement suspended during clear')
host.pause=true;host:tick(2);ok(host.clearFX.time==.2,'clear pauses')
host.pause=nil;host:tick(.29);ok(not host.clearFX and t.piece.y==y,'clear completes without gravity jump')
host:tick(.8);ok(t.piece.y==y+1,'gravity resumes')
print('Animation assertions: '..n)
