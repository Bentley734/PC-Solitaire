-- Pure rules. Mines are placed on the first reveal, outside its 3x3 area.
local M={}
local function neighbors(s,x,y,fn)
 for dy=-1,1 do for dx=-1,1 do
  local a,b=x+dx,y+dy
  if (dx~=0 or dy~=0)and a>=1 and a<=s.w and b>=1 and b<=s.h then fn(s.cells[b][a],a,b)end
 end end
end
function M.new(random)
 local s={w=9,h=9,mines=10,cells={},random=random or math.random,revealed=0,flags=0,started=false,time=0}
 for y=1,s.h do s.cells[y]={};for x=1,s.w do s.cells[y][x]={n=0}end end
 return s
end
local function seed(s,x,y)
 local pool={}
 for b=1,s.h do for a=1,s.w do
  if math.abs(a-x)>1 or math.abs(b-y)>1 then pool[#pool+1]=s.cells[b][a]end
 end end
 for i=1,s.mines do local j=s.random(i,#pool);pool[i],pool[j]=pool[j],pool[i];pool[i].mine=true end
 for b=1,s.h do for a=1,s.w do
  neighbors(s,a,b,function(c)if c.mine then s.cells[b][a].n=s.cells[b][a].n+1 end end)
 end end
 s.started=true
end
function M.flag(s,x,y)
 local c=s.cells[y]and s.cells[y][x]
 if s.over or not c or c.open then return false end
 if not c.flag and s.flags>=s.mines then return false end
 c.flag=not c.flag;s.flags=s.flags+(c.flag and 1 or -1);return true
end
function M.reveal(s,x,y)
 local c=s.cells[y]and s.cells[y][x]
 if s.over or not c or c.flag then return false end
 if not s.started then seed(s,x,y)end
 local queue={}
 local function visit(cell,a,b)
  if cell.open or cell.flag then return end
  cell.open=true
  if cell.mine then s.over=true;s.hit={x=a,y=b};return end
  s.revealed=s.revealed+1
  if cell.n==0 then queue[#queue+1]={a,b}end
 end
 if c.open then
  local flags=0;neighbors(s,x,y,function(v)if v.flag then flags=flags+1 end end)
  if c.n==0 or flags~=c.n then return false end
  neighbors(s,x,y,visit) -- Chording with incorrect flags can lose.
 else visit(c,x,y)end
 local i=1
 while queue[i]and not s.over do local p=queue[i];neighbors(s,p[1],p[2],visit);i=i+1 end
 if not s.over and s.revealed==s.w*s.h-s.mines then s.over=true;s.won=true end
 return true
end
return M
