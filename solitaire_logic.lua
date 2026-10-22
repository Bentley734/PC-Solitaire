-- Pure Lua Klondike rules. Sources are {kind='tableau'|'waste'|'foundation', pile=, index=}.
local M={}
local function color(c) return (c.suit=='hearts' or c.suit=='diamonds') and 1 or 0 end
function M.new(draw,random)
  local s={stock={},waste={},foundations={{},{},{},{}},tableau={{},{},{},{},{},{},{}},draw=draw==3 and 3 or 1,moves=0}
  for _,suit in ipairs({'hearts','diamonds','clubs','spades'}) do
    for rank=1,13 do s.stock[#s.stock+1]={suit=suit,rank=rank,up=false} end
  end
  random=random or math.random
  for i=52,2,-1 do local j=random(i);s.stock[i],s.stock[j]=s.stock[j],s.stock[i] end
  for i=1,7 do for j=1,i do local c=table.remove(s.stock);c.up=j==i;s.tableau[i][j]=c end end
  return s
end
function M.pile(s,ref)
  if not ref then return end
  if ref.kind=='waste' then return s.waste end
  if ref.kind=='tableau' then return s.tableau[ref.pile] end
  if ref.kind=='foundation' then return s.foundations[ref.pile] end
end
function M.source(s,ref)
  local p=M.pile(s,ref);if not p or #p==0 then return end
  local i=ref.index or #p
  if i<1 or i>#p or i%1~=0 or not p[i].up then return end
  if ref.kind~='tableau' and i~=#p then return end
  for j=i+1,#p do
    if not p[j].up or p[j-1].rank~=p[j].rank+1 or color(p[j-1])==color(p[j]) then return end
  end
  return p,i
end
function M.move(s,from,to)
  local src,i=M.source(s,from);local dst=M.pile(s,to)
  if not src or not dst or src==dst then return false end
  local c,top=src[i],dst[#dst]
  if to.kind=='foundation' then
    if i~=#src or (top and (top.suit~=c.suit or c.rank~=top.rank+1)) or (not top and c.rank~=1) then return false end
  elseif to.kind=='tableau' then
    if (top and (not top.up or top.rank~=c.rank+1 or color(top)==color(c))) or (not top and c.rank~=13) then return false end
  else return false end
  while #src>=i do dst[#dst+1]=table.remove(src,i) end
  if src[#src] then src[#src].up=true end
  s.moves=s.moves+1;return true
end
function M.drawStock(s)
  if #s.stock==0 then
    if #s.waste==0 then return false end
    while #s.waste>0 do local c=table.remove(s.waste);c.up=false;s.stock[#s.stock+1]=c end
  else
    for _=1,math.min(s.draw,#s.stock) do local c=table.remove(s.stock);c.up=true;s.waste[#s.waste+1]=c end
  end
  s.moves=s.moves+1;return true
end
function M.auto(s,ref)
  for i=1,4 do if M.move(s,ref,{kind='foundation',pile=i}) then return true end end
  return false
end
function M.won(s)
  for i=1,4 do if #s.foundations[i]~=13 then return false end end
  return true
end
return M
