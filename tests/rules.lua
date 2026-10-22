local L=dofile((arg and arg[1] or 'mods/pc_solitaire')..'/solitaire_logic.lua')
local count=0
local function ok(v,msg) assert(v,msg);count=count+1 end
local function card(s,r,up) return {suit=s,rank=r,up=up~=false} end
local function empty() return {stock={},waste={},foundations={{},{},{},{}},tableau={{},{},{},{},{},{},{}},draw=1,moves=0} end
for seed=1,100 do
 math.randomseed(seed);local s=L.new(seed%2==0 and 3 or 1);local seen={};local n=0
 local function visit(p) for _,c in ipairs(p) do local k=c.suit..c.rank;ok(not seen[k],'duplicate card');seen[k]=true;n=n+1 end end
 visit(s.stock);ok(#s.stock==24,'stock count')
 for i,p in ipairs(s.tableau) do visit(p);ok(#p==i and p[i].up,'deal');for j=1,i-1 do ok(not p[j].up,'hidden card') end end
 ok(n==52,'52 cards')
 local top=s.stock[#s.stock];L.drawStock(s);ok(#s.waste==s.draw,'draw mode')
 while #s.stock>0 do L.drawStock(s) end
 L.drawStock(s);ok(#s.stock==24 and #s.waste==0 and s.stock[#s.stock]==top,'recycle order')
end
local s=empty();s.tableau[1]={card('clubs',5,false),card('hearts',4),card('spades',3)};s.tableau[2]={card('clubs',5)}
ok(L.move(s,{kind='tableau',pile=1,index=2},{kind='tableau',pile=2}),'substack')
ok(#s.tableau[2]==3 and s.tableau[1][1].up,'flip exposed')
ok(not L.move(s,{kind='tableau',pile=2,index=2},{kind='foundation',pile=1}),'multi foundation forbidden')
s.waste={card('hearts',1)};ok(L.auto(s,{kind='waste'}),'ace foundation');s.waste={card('diamonds',2)}
ok(not L.move(s,{kind='waste'},{kind='foundation',pile=1}),'suit mismatch')
s.waste={card('hearts',2)};ok(L.auto(s,{kind='waste'}),'same suit ascending')
ok(not L.move(s,{kind='foundation',pile=1},{kind='tableau',pile=3}),'only king empty')
s.waste={card('clubs',13)};ok(L.move(s,{kind='waste'},{kind='tableau',pile=3}),'king empty')
s.tableau[4]={card('hearts',7),card('diamonds',6)};ok(not L.source(s,{kind='tableau',pile=4,index=1}),'invalid sequence')
s.tableau[4]={card('hearts',7,false)};ok(not L.source(s,{kind='tableau',pile=4,index=1}),'facedown source')
ok(not L.won(s),'not won');for i=1,4 do s.foundations[i]={};for r=1,13 do s.foundations[i][r]=card('hearts',r) end end;ok(L.won(s),'won')
print('Rules assertions: '..count)
