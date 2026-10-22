return function(Solitaire,Rules)
local Games={};Games.__index=Games
local colors={{0.1,0.9,0.95},{1,0.85,0.15},{0.7,0.35,1},{0.25,0.9,0.4},{1,0.3,0.35},{0.3,0.5,1},{1,0.6,0.2}}
local text=Solitaire.text
function Games.new(game,w,h,close)
 return setmetatable({game=game,w=w,h=h,close=close,index=1,isOpaque=true,isMenu=true,clock=0},Games)
end
function Games:launch(index)
 self.pause=nil;self.elapsed=0;self.clock=0;self.repeatKey=nil;self.repeatTime=0
 if index==1 then
  self.child=Solitaire.new(self.game,self.w,self.h,function()self.child=nil;self.mode=nil end)
  self.child.exitLabel='QUIT TO GAMES';self.mode='solitaire'
 elseif index==2 then self.mode='snake';self.state=Rules.snake()
 else self.mode='tetris';self.state=Rules.tetris() end
end
function Games:tick(dt)
 self.clock=self.clock+dt
 if self.child then self.child.clock=self.child.clock+dt;return end
 if not self.mode or self.pause or self.state.over then return end
 if self.mode=='tetris' then
  local input=self.game.input
  if input.isDown then
   local key=input:isDown('left') and 'left' or input:isDown('right') and 'right' or input:isDown('down') and 'down' or nil
   if key~=self.repeatKey then self.repeatKey=key;self.repeatTime=key=='down' and .045 or .17
   elseif key then
    self.repeatTime=self.repeatTime-dt
    if self.repeatTime<=0 then
     self.repeatTime=key=='down' and .045 or .065
     if key=='down' then if Rules.shift(self.state,0,1)then self.state.score=self.state.score+1;self.elapsed=0 end
     else Rules.shift(self.state,key=='left' and -1 or 1,0)end
    end
   end
  end
 end
 self.elapsed=self.elapsed+dt
 local speed=self.mode=='snake' and math.max(.065,.18-self.state.score*.0005) or math.max(.08,.75*(.82^(self.state.level-1)))
 local steps=0
 while self.elapsed>=speed and steps<5 and not self.state.over do
  self.elapsed=self.elapsed-speed;steps=steps+1
  if self.mode=='snake' then Rules.snakeStep(self.state) else Rules.drop(self.state,false) end
 end
end
function Games:handle(input)
 if self.closed then return end
 if self.child then self.child:handle(input);return end
 if not self.mode then
  if input:wasPressed('up')then self.index=(self.index-2)%4+1
  elseif input:wasPressed('down')then self.index=self.index%4+1
  elseif input:wasPressed('b')or (input:wasPressed('a')and self.index==4)then self.closed=true;self.close()
  elseif input:wasPressed('a')then self:launch(self.index)end
  return
 end
 if self.pause then
  if input:wasPressed('b')or input:wasPressed('start')or input:wasPressed('select')then self.pause=nil
  elseif input:wasPressed('up')then self.menu=(self.menu-2)%3+1
  elseif input:wasPressed('down')then self.menu=self.menu%3+1
  elseif input:wasPressed('a')then
   if self.menu==1 then self.pause=nil elseif self.menu==2 then self:launch(self.mode=='snake' and 2 or 3)else self.mode=nil;self.pause=nil end
  end
  return
 end
 if input:wasPressed('b')or input:wasPressed('start')or input:wasPressed('select')then self.pause=true;self.menu=1;return end
 if self.state.over then if input:wasPressed('a')then self:launch(self.mode=='snake' and 2 or 3)end;return end
 if self.mode=='snake' then
  if input:wasPressed('up')then Rules.turn(self.state,0,-1)
  elseif input:wasPressed('down')then Rules.turn(self.state,0,1)
  elseif input:wasPressed('left')then Rules.turn(self.state,-1,0)
  elseif input:wasPressed('right')then Rules.turn(self.state,1,0)end
 else
  if input:wasPressed('left')then Rules.shift(self.state,-1,0)
  elseif input:wasPressed('right')then Rules.shift(self.state,1,0)
  elseif input:wasPressed('down')then if Rules.shift(self.state,0,1)then self.state.score=self.state.score+1;self.elapsed=0 end
  elseif input:wasPressed('up')then Rules.drop(self.state,true);self.elapsed=0
  elseif input:wasPressed('a')then Rules.shift(self.state,0,0,1)end
 end
end
function Games:update(dt)self:handle(self.game.input);self:tick(dt)end
function Games:draw()
 if self.child then return self.child:draw()end
 local g=love.graphics;g.push('all');g.setShader();g.setColor(.025,.07,.12,1);g.rectangle('fill',0,0,self.w,self.h)
 g.setColor(.7,1,.8,1);text(self.mode and self.mode:upper() or 'PC GAMES',6,5)
 if not self.mode then
  text('CHOOSE A GAME',12,25)
  for i,label in ipairs({'SOLITAIRE','SNAKE','TETRIS','BACK TO PC'})do
   g.setColor(i==self.index and 1 or .65,i==self.index and .88 or .8,i==self.index and .3 or .85,1)
   text((i==self.index and '> 'or '  ')..label,16,40+(i-1)*17)
  end
  g.setColor(.7,.8,.85,1);text('A PLAY   B BACK',6,self.h-10);g.pop();return
 end
 local s=self.state
 if self.mode=='snake' then
  local cell=math.floor(math.min((self.w-10)/20,(self.h-34)/16));local ox=math.floor((self.w-cell*20)/2);local oy=20
  g.setColor(.18,.28,.35,1);g.rectangle('line',ox-1,oy-1,20*cell+2,16*cell+2)
  if s.food then g.setColor(1,.3,.3,1);g.rectangle('fill',ox+(s.food.x-1)*cell+1,oy+(s.food.y-1)*cell+1,cell-2,cell-2)end
  for i,p in ipairs(s.body)do g.setColor(i==1 and 1 or .3,1,.45,1);g.rectangle('fill',ox+(p.x-1)*cell,oy+(p.y-1)*cell,cell-1,cell-1)end
  g.setColor(1,1,1,1);text('SCORE '..s.score,65,5);text('D PAD MOVE  B PAUSE',4,self.h-8)
 else
  local cell=math.floor((self.h-24)/20);local ox=math.floor((self.w-cell*10-56)/2);local oy=15
  local function block(x,y,id,ghost)
   if y<1 then return end
   g.setColor(colors[id][1],colors[id][2],colors[id][3],1)
   g.rectangle(ghost and 'line'or 'fill',ox+(x-1)*cell+1,oy+(y-1)*cell+1,cell-2,cell-2)
  end
  g.setColor(.18,.28,.35,1);g.rectangle('line',ox-1,oy-1,cell*10+2,cell*20+2)
  for y=1,20 do for x=1,10 do if s.board[y][x]then block(x,y,s.board[y][x])end end end
  if not s.over then
   local p=s.piece;local ghost={id=p.id,x=p.x,y=p.y,rot=p.rot}
   repeat ghost.y=ghost.y+1 until not Rules.fits(s,ghost);ghost.y=ghost.y-1
   for _,c in ipairs(Rules.cells(ghost))do block(c.x,c.y,p.id,true)end
   for _,c in ipairs(Rules.cells(p))do block(c.x,c.y,p.id)end
  end
  local tx=ox+cell*10+7;g.setColor(1,1,1,1);text('SCORE',tx,19);text(s.score,tx,28);text('LINES '..s.lines,tx,42);text('LEVEL '..s.level,tx,54);text('NEXT',tx,70)
  for _,c in ipairs(Rules.cells({id=s.next,x=1,y=1,rot=0}))do g.setColor(unpack(colors[s.next]));g.rectangle('fill',tx+(c.x-1)*5,82+(c.y-1)*5,4,4)end
  g.setColor(1,1,1,1);text('A TURN',tx,104);text('UP DROP',tx,114);text('B PAUSE',tx,124)
 end
 if s.over then
  g.setColor(.02,.04,.08,.95);g.rectangle('fill',4,math.floor(self.h/2)-13,self.w-8,30)
  g.setColor(1,.85,.3,1);text(s.won and 'YOU WIN'or 'GAME OVER',math.floor(self.w/2)-18,math.floor(self.h/2)-7);text('A RETRY  B MENU',math.floor(self.w/2)-28,math.floor(self.h/2)+4)
 end
 if self.pause then
  local x=math.floor((self.w-112)/2);local y=math.floor((self.h-60)/2)
  g.setColor(.02,.06,.1,1);g.rectangle('fill',x,y,112,60);g.setColor(1,1,.8,1);g.rectangle('line',x,y,112,60);text('PAUSED',x+8,y+6)
  for i,label in ipairs({'RESUME','NEW GAME','BACK TO GAMES'})do text((i==self.menu and '> 'or '  ')..label,x+7,y+10+i*12)end
 end
 g.pop()
end
return Games
end
