return function(Solitaire,R)
local Screen={};Screen.__index=Screen
local text=Solitaire.text
local colors={{.95,.3,.35},{.25,.7,1},{.95,.8,.2},{.3,.9,.5}}
local names={'BLACKJACK','COLLAPSE'}
function Screen.new(game,w,h,close,index)
 local s=setmetatable({game=game,w=w,h=h,close=close,kind=index,index=1,x=1,y=12,time=0,clock=0,status='',isOpaque=true,isMenu=true},Screen)
 s.renderer=Solitaire.new(game,w,h,function()end);s:restart();return s
end
function Screen:restart()
 self.pause=nil;self.fx=nil;self.time=0;self.index=1;self.selected=nil;self.hints=nil;self.status=''
 if self.kind==1 then self.state=R.blackjack(nil,self.state and self.state.score)
 else self.state=R.collapse();self.x=1;self.y=12 end
end
function Screen:tick(dt)
 if self.pause or self.closed then return end
 self.clock=self.clock+dt
 if self.fx then self.fx.time=self.fx.time+dt;if self.fx.time>.25 then self.fx=nil end end
 if self.kind==2 and not self.state.over and not self.fx then
  self.time=self.time+dt;local interval=math.max(3,8-math.floor(self.state.score/500)*.4)
  if self.time>=interval then self.time=self.time-interval;R.rise(self.state);self.y=math.max(1,self.y-1)end
 end
end
function Screen:handle(input)
 if self.closed then return end
 if self.pause then
  if input:wasPressed('b')or input:wasPressed('start')or input:wasPressed('select')then self.pause=nil
  elseif input:wasPressed('up')then self.menu=(self.menu-2)%3+1
  elseif input:wasPressed('down')then self.menu=self.menu%3+1
  elseif input:wasPressed('a')then
   if self.menu==1 then self.pause=nil elseif self.menu==2 then self:restart()else self.closed=true;self.close()end
  end;return
 end
 if input:wasPressed('b')then
  if self.selected then self.selected=nil else self.pause=true;self.menu=1 end;return
 end
 if input:wasPressed('start')or input:wasPressed('select')then self.pause=true;self.menu=1;return end
 local s=self.state
 if self.kind==1 then
  if s.phase=='done'then if input:wasPressed('a')then self:restart()end;return end
  if input:wasPressed('left')or input:wasPressed('up')then self.index=(self.index-2)%3+1
  elseif input:wasPressed('right')or input:wasPressed('down')then self.index=self.index%3+1
  elseif input:wasPressed('a')then
   if self.index==1 then R.hit(s)elseif self.index==2 then R.stand(s)elseif not R.double(s)then self.status='DOUBLE ON FIRST TWO ONLY'end
   self.fx={time=0}
  end
 elseif s.over then if input:wasPressed('a')then self:restart()end
 elseif self.kind==2 then
  if input:wasPressed('left')then self.x=(self.x-2)%10+1
  elseif input:wasPressed('right')then self.x=self.x%10+1
  elseif input:wasPressed('up')then self.y=math.max(1,self.y-1)
  elseif input:wasPressed('down')then
   if self.y==12 then R.rise(s);self.time=0;self.fx=nil;self.y=11
   else self.y=self.y+1 end
  elseif input:wasPressed('a')and not self.fx then
   local group=R.removeGroup(s,self.x,self.y)
   if group then self.fx={time=0,cells=group};self.status='CLEARED '..#group else self.status='MATCH 3 OR MORE'end
  end
 end
end
function Screen:update(dt)self:handle(self.game.input);self:tick(dt)end
function Screen:draw()
 local g=love.graphics;g.push('all');g.setShader();if g.setLineStyle then g.setLineStyle('rough')end;g.setColor(.035,.13,.13,1);g.rectangle('fill',0,0,self.w,self.h)
 local s=self.state;g.setColor(.9,1,.8,1);text(names[self.kind],4,4);text('SCORE '..s.score,self.w-64,4)
 if self.kind==1 then
  local cw,ch=self.w==160 and 16 or 32,self.w==160 and 24 or 48
  local function hand(cards,y,hide)
   local gap=math.min(cw+3,math.floor((self.w-12-cw)/math.max(1,#cards-1)))
   for i,c in ipairs(cards)do local face={rank=c.rank,suit=c.suit,up=not(hide and i==2)};self.renderer:card(face,6+(i-1)*gap,y,cw,ch)end
  end
  local dy=22;local py=self.w==160 and 68 or 80
  g.setColor(1,1,1,1);text('DEALER '..(s.phase=='done'and R.total(s.dealer)or '?'),6,14);hand(s.dealer,dy,s.phase~='done')
  g.setColor(1,1,1,1);text('YOU '..R.total(s.player),6,py-9);hand(s.player,py,false)
  g.setColor(1,1,.6,1)
  if s.phase=='done'then text(s.result,6,self.h-25);text('A NEXT HAND  B MENU',6,self.h-10)
  else
   for i,label in ipairs({'HIT','STAND','DOUBLE'})do text((i==self.index and '> 'or '  ')..label,4+(i-1)*math.floor(self.w/3),self.h-25)end
   g.setColor(.7,.9,.8,1);text(self.status~=''and self.status or 'A CHOOSE  B PAUSE',4,self.h-10)
  end
  if self.fx then g.setColor(1,1,.5,1-self.fx.time/.25);g.rectangle('line',4,py-2,self.w-8,ch+4)end
 elseif self.kind==2 then
  local cell=math.floor(math.min((self.w-12)/10,(self.h-37)/12));local ox=math.floor((self.w-cell*10)/2);local oy=16
  local group=R.group(s,self.x,self.y);local marked={};for _,p in ipairs(group)do marked[p.y*10+p.x]=true end
  for y=1,12 do for x=1,10 do local v=s.board[y][x];if v then
   g.setColor(unpack(colors[v]));g.rectangle('fill',ox+(x-1)*cell+1,oy+(y-1)*cell+1,cell-2,cell-2)
   if #group>=3 and marked[y*10+x]then g.setColor(1,1,1,1);g.rectangle('line',ox+(x-1)*cell,oy+(y-1)*cell,cell-1,cell-1)end
  end end end
  if self.fx then local t=self.fx.time/.25;for _,p in ipairs(self.fx.cells)do g.setColor(1,1,.6,1-t);local size=math.floor(cell*(1+t));g.rectangle('line',math.floor(ox+(p.x-.5)*cell-size/2),math.floor(oy+(p.y-.5)*cell-size/2),size,size)end end
  g.setColor(1,1,.3,1);g.rectangle('line',ox+(self.x-1)*cell-1,oy+(self.y-1)*cell-1,cell+1,cell+1)
  local interval=math.max(3,8-math.floor(s.score/500)*.4);g.setColor(.9,.5,.2,1);g.rectangle('fill',ox,oy+cell*12+2,math.floor(cell*10*self.time/interval),2)
  g.setColor(1,1,1,1);text(self.status~=''and self.status or 'A CLEAR GROUP  B PAUSE',4,self.h-10)
 end
 if s.over then
  g.setColor(.02,.1,.1,.95);g.rectangle('fill',4,math.floor(self.h/2)-13,self.w-8,29);g.setColor(1,1,.5,1)
  text(s.won and 'ALL PAIRS MATCHED'or 'GAME OVER',12,math.floor(self.h/2)-7);text('A RETRY  B MENU',12,math.floor(self.h/2)+4)
 end
 if self.pause then
  local x=math.floor((self.w-112)/2);local y=math.floor((self.h-60)/2)
  g.setColor(.02,.06,.1,1);g.rectangle('fill',x,y,112,60);g.setColor(1,1,.8,1);g.rectangle('line',x,y,112,60);text('PAUSED',x+8,y+6)
  for i,label in ipairs({'RESUME','NEW GAME','BACK TO GAMES'})do text((i==self.menu and '> 'or '  ')..label,x+7,y+10+i*12)end
 end
 g.pop()
end
return Screen
end
