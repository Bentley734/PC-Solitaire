local root=assert(arg[1]);local R=dofile(root..'/more_logic.lua');local n=0
local function ok(v,msg)assert(v,msg);n=n+1 end
local function cards(...)local out={};for _,rank in ipairs({...})do out[#out+1]={rank=rank,suit='hearts',up=true}end;return out end
ok(R.total(cards(1,1,9))==21,'multiple aces');ok(R.total(cards(1,1,10))==12,'soft ace becomes hard');ok(R.total(cards(11,12))==20,'face values')
local function bj(p,d,deck)return {player=cards(unpack(p)),dealer=cards(unpack(d)),deck=cards(unpack(deck or {})),score=0,bet=10,phase='player'}end
local s=bj({1,13},{10,9});R.settle(s);ok(s.score==15 and s.result=='BLACKJACK','natural payout');R.settle(s);ok(s.score==15,'settle idempotent')
s=bj({10,10},{10,10});R.stand(s);ok(s.score==0 and s.result=='PUSH','push')
s=bj({10,9},{10,6},{10});R.stand(s);ok(s.score==10,'dealer bust')
s=bj({10,6},{10,7},{10});R.hit(s);ok(s.score==-10 and s.result=='BUST','player bust')
s=bj({5,6},{10,8},{10});ok(R.double(s)and s.bet==20 and s.score==20,'double win')
s=bj({10,6},{10,8},{10});R.double(s);ok(s.score==-20,'double loss')
s=bj({2,3,4},{10,8});ok(not R.double(s)and s.bet==10,'double first two only')
s=bj({10,8},{1,6});R.stand(s);ok(#s.dealer==2 and s.score==10,'dealer stands soft17')
for seed=1,100 do
 math.randomseed(seed);s=R.blackjack();local seen={};local count=0
 for _,hand in ipairs({s.deck,s.player,s.dealer})do for _,c in ipairs(hand)do local id=c.suit..c.rank;ok(not seen[id],'52 unique cards');seen[id]=true;count=count+1 end end
 ok(count==52,'full deck')
 if s.phase=='player'then R.stand(s);ok(s.phase=='done','dealer resolves')end
end
local c=R.collapse(function()return 2 end);for y=1,12 do c.board[y]={}end
c.board[12]={[1]=1,[2]=1,[3]=1,[4]=2};c.board[10][1]=3
local group=R.removeGroup(c,1,12);ok(#group==3 and c.score==30,'group score');ok(c.board[12][1]==3 and c.board[12][4]==2,'gravity preserves columns')
ok(not R.removeGroup(c,4,12),'small group rejected');ok(#R.group(c,0,12)==0,'invalid group safe')
c.board[11][4]=2;c.board[11][5]=2;ok(#R.group(c,4,12)==3,'orthogonal floodfill')
local score=c.score;R.rise(c);ok(c.rows==1 and c.board[12][1]==2 and c.board[11][1]==3 and c.score==score,'rising row')
c.board[1][1]=1;R.rise(c);ok(c.over,'top out');ok(not R.removeGroup(c,4,12),'game over inert')
local function read(path)local f=assert(io.open(root..'/'..path));local b=f:read('*a');f:close();return b end
love={graphics={newImage=function()error('fallback')end},filesystem={newFileData=function()end}}
local S=assert(load(read('solitaire_screen.lua')))()({read=function()return nil end},dofile(root..'/solitaire_logic.lua'))
local Extra=assert(load(read('more_screen.lua')))()(S,R)
local G=assert(load(read('games_screen.lua')))()(S,dofile(root..'/arcade_logic.lua'),Extra)
local input={pressed={}};function input:wasPressed(k)return self.pressed[k]end
local closed=0;local host=G.new({input=input},160,144,function()closed=closed+1 end)
local function press(k)input.pressed={[k]=true};host:handle(input);input.pressed={}end
for index=4,5 do
 host.index=index;press('a');ok(host.child and host.child.kind==index-3,'extra game launch')
 local child=host.child
 if index==5 then
  local rows=child.state.rows;host:tick(8.1);ok(child.state.rows==rows+1,'collapse timer')

 end
 press('start');local clock=child.clock;host:tick(20);ok(child.clock==clock,'pause freezes extra games')
 press('down');press('down');press('a');ok(not host.child and not host.mode and host.index==index,'extra submenu return')
end
host.index=6;press('a');ok(closed==1,'back pc new index')
print('Additional game assertions: '..n)
