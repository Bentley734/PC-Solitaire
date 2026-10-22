-- Pure Lua rules for Snake and a seven-bag falling-block game.
local M={}
function M.snake(random)
 local s={body={{x=8,y=7},{x=7,y=7},{x=6,y=7}},dx=1,dy=0,score=0,random=random or math.random}
 M.food(s);return s
end
function M.food(s)
 local free={}
 for y=1,16 do for x=1,20 do
  local occupied=false;for _,p in ipairs(s.body)do if p.x==x and p.y==y then occupied=true;break end end
  if not occupied then free[#free+1]={x=x,y=y} end
 end end
 if #free==0 then s.won=true;s.over=true;s.food=nil else s.food=free[s.random(#free)] end
end
function M.turn(s,x,y)
 if s.over or s.queued or (x==-s.dx and y==-s.dy) then return false end
 s.queued={x=x,y=y};return true
end
function M.snakeStep(s)
 if s.over then return end
 if s.queued then s.dx=s.queued.x;s.dy=s.queued.y;s.queued=nil end
 local h={x=s.body[1].x+s.dx,y=s.body[1].y+s.dy}
 if h.x<1 or h.x>20 or h.y<1 or h.y>16 then s.over=true;return end
 local eat=s.food and h.x==s.food.x and h.y==s.food.y
 for i=1,#s.body-(eat and 0 or 1) do if s.body[i].x==h.x and s.body[i].y==h.y then s.over=true;return end end
 table.insert(s.body,1,h)
 if eat then s.score=s.score+10;M.food(s) else table.remove(s.body) end
end
local shapes={
 {{0,1},{1,1},{2,1},{3,1}},{{1,0},{2,0},{1,1},{2,1}},
 {{1,0},{0,1},{1,1},{2,1}},{{1,0},{2,0},{0,1},{1,1}},
 {{0,0},{1,0},{1,1},{2,1}},{{0,0},{0,1},{1,1},{2,1}},{{2,0},{0,1},{1,1},{2,1}},
}
function M.cells(piece)
 local out={}
 for _,p in ipairs(shapes[piece.id])do
  local x,y=p[1],p[2]
  if piece.id~=2 then for _=1,piece.rot do x,y=(piece.id==1 and 3 or 2)-y,x end end
  out[#out+1]={x=x+piece.x,y=y+piece.y}
 end
 return out
end
function M.fits(s,p)
 for _,c in ipairs(M.cells(p))do
  if c.x<1 or c.x>10 or c.y>20 or (c.y>=1 and s.board[c.y][c.x]) then return false end
 end
 return true
end
local function nextId(s)
 if #s.bag==0 then
  for i=1,7 do s.bag[i]=i end
  for i=7,2,-1 do local j=s.random(i);s.bag[i],s.bag[j]=s.bag[j],s.bag[i] end
 end
 return table.remove(s.bag)
end
function M.spawn(s)
 s.piece={id=s.next or nextId(s),x=4,y=0,rot=0};s.next=nextId(s)
 if not M.fits(s,s.piece) then s.over=true end
end
function M.tetris(random)
 local s={board={},bag={},random=random or math.random,score=0,lines=0,level=1}
 for y=1,20 do s.board[y]={} end
 M.spawn(s);return s
end
function M.shift(s,dx,dy,rotation)
 if s.over then return false end
 local p=s.piece;local candidate={id=p.id,x=p.x+dx,y=p.y+dy,rot=(p.rot+(rotation or 0))%4}
 local kicks=rotation and {0,-1,1,-2,2} or {0}
 for _,kick in ipairs(kicks)do candidate.x=p.x+dx+kick;if M.fits(s,candidate)then s.piece=candidate;return true end end
 return false
end
function M.lock(s)
 for _,c in ipairs(M.cells(s.piece))do
  if c.y<1 then s.over=true;return end
 end
 for _,c in ipairs(M.cells(s.piece))do s.board[c.y][c.x]=s.piece.id end
 local cleared=0;local y=20
 while y>=1 do
  local full=true;for x=1,10 do if not s.board[y][x]then full=false;break end end
  if full then table.remove(s.board,y);table.insert(s.board,1,{});cleared=cleared+1 else y=y-1 end
 end
 s.score=s.score+({[0]=0,100,300,500,800})[cleared]*s.level
 s.lines=s.lines+cleared;s.level=1+math.floor(s.lines/10);M.spawn(s)
end
function M.drop(s,hard)
 if s.over then return end
 if hard then
  while M.shift(s,0,1)do s.score=s.score+2 end
  M.lock(s)
 elseif not M.shift(s,0,1) then M.lock(s) end
end
return M
