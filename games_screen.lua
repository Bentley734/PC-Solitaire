return function(Solitaire,Rules,More,New)
local Games={};Games.__index=Games
local colors={{0.1,0.9,0.95},{1,0.85,0.15},{0.7,0.35,1},{0.25,0.9,0.4},{1,0.3,0.35},{0.3,0.5,1},{1,0.6,0.2}}
local text=Solitaire.text
Games.withTextScale=Solitaire.withTextScale
function Games.new(game,w,h,close)
 return setmetatable({game=game,w=w,h=h,close=close,index=1,isOpaque=true,isMenu=true,clock=0},Games)
end
function Games:launch(index)
 self.child=nil;self.pause=nil;self.snakeFX=nil;self.clearFX=nil;self.elapsed=0;self.clock=0;self.repeatKey=nil;self.repeatTime=0
 if index==1 then
  self.child=Solitaire.new(self.game,self.w,self.h,function()self.child=nil;self.mode=nil end)
  self.child.exitLabel='QUIT TO GAMES';self.mode='solitaire'
 elseif index==2 then self.mode='snake';self.state=Rules.snake()
 elseif index==3 then self.mode='tetris';self.state=Rules.tetris()
 elseif index<=5 then
  assert(More,'Extra game screens unavailable')
  self.child=More.new(self.game,self.w,self.h,function()self.child=nil;self.mode=nil end,index-3);self.mode=({'blackjack','collapse'})[index-3]
 else
  self.child=New.new(self.game,self.w,self.h,function()self.child=nil;self.mode=nil end,index-5)
  self.mode=index==6 and 'minesweeper'or 'pokepet'
 end
end
function Games:tick(dt)
 self.clock=self.clock+dt
 if self.child then self.child:tick(dt);return end
 if not self.mode or self.pause then return end
 if self.snakeFX then self.snakeFX.time=self.snakeFX.time+dt;if self.snakeFX.time>=.6 then self.snakeFX=nil end end
 if self.clearFX then
  self.clearFX.time=self.clearFX.time+dt
  if self.clearFX.time>=.48 then self.clearFX=nil;self.elapsed=0 end
  return
 end
 if self.state.over then return end
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
  if self.mode=='snake' then
   local score=self.state.score;local food=self.state.food
   Rules.snakeStep(self.state)
   if self.state.score>score then self.snakeFX={x=food.x,y=food.y,time=0}end
  else self:drop(false);if self.clearFX then break end end
 end
end
function Games:drop(hard)
 local serial=self.state.clearSerial
 Rules.drop(self.state,hard)
 if self.state.clearSerial~=serial then self.clearFX={event=self.state.clearEvent,time=0};self.elapsed=0;self.repeatKey=nil end
end
function Games:handle(input)
 if self.closed then return end
 if self.child then self.child:handle(input);return end
 if not self.mode then
  if input:wasPressed('up')then self.index=(self.index-2)%8+1
  elseif input:wasPressed('down')then self.index=self.index%8+1
  elseif input:wasPressed('b')or (input:wasPressed('a')and self.index==8)then self.closed=true;self.close()
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
 if self.clearFX then return end
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
  elseif input:wasPressed('up')then self:drop(true);self.elapsed=0
  elseif input:wasPressed('a')then Rules.shift(self.state,0,0,1)end
 end
end
function Games:update(dt)self:handle(self.game.input);self:tick(dt)end
function Games:draw()
 if self.child then return self.child:draw()end
 local g=love.graphics;g.push('all');g.setShader();if g.setLineStyle then g.setLineStyle('rough')end;g.setColor(.025,.07,.12,1);g.rectangle('fill',0,0,self.w,self.h)
 g.setColor(.7,1,.8,1);text(self.mode and self.mode:upper()or(self.touchMode and'CHOOSE A GAME'or'PC GAMES'),6,5)
 if not self.mode then
  if not self.touchMode then text('CHOOSE A GAME',12,19)end
  for i,label in ipairs({'SOLITAIRE','SNAKE','TETRIS','BLACKJACK','COLLAPSE','MINESWEEPER','POKEPET',self.exitLabel or 'BACK TO PC'})do
   g.setColor(i==self.index and 1 or .65,i==self.index and .88 or .8,i==self.index and .3 or .85,1)
   text((i==self.index and '> 'or '  ')..label,16,30+(i-1)*(self.touchMode and 20 or 12),self.touchMode and 2 or 1)
  end
  g.setColor(.7,.8,.85,1);text(self.touchMode and'TAP A GAME TO PLAY'or'A PLAY   B BACK',6,self.h-(self.touchMode and 12 or 10));g.pop();return
 end
 local s=self.state
 if self.mode=='snake' then
  local cell=math.floor(math.min((self.w-10)/20,(self.h-34)/16));local ox=math.floor((self.w-cell*20)/2);local oy=20
  g.setColor(.18,.28,.35,1);g.rectangle('line',ox-1,oy-1,20*cell+2,16*cell+2)
  if s.food then g.setColor(1,.3,.3,1);g.rectangle('fill',ox+(s.food.x-1)*cell+1,oy+(s.food.y-1)*cell+1,cell-2,cell-2)end
  for i,p in ipairs(s.body)do
   local ripple=self.snakeFX and math.max(0,1-math.abs(self.snakeFX.time*20-(i-1))*.8)or 0
   g.setColor(i==1 and 1 or .3+ripple*.7,1,.45+ripple*.45,1)
   local grow=ripple>.35 and 1 or 0
   g.rectangle('fill',ox+(p.x-1)*cell-grow,oy+(p.y-1)*cell-grow,cell-1+grow*2,cell-1+grow*2)
  end
  if self.snakeFX then
   local e=self.snakeFX;local t=e.time/.6;local px=ox+(e.x-.5)*cell;local py=oy+(e.y-.5)*cell
   g.setColor(1,.85,.2,1-t);local radius=cell*(.5+t*1.8)
   g.rectangle('line',math.floor(px-radius),math.floor(py-radius),math.floor(radius*2),math.floor(radius*2))
   for i=0,7 do local angle=i*math.pi/4;local r=cell*(1+t*3)
    g.rectangle('fill',math.floor(px+math.cos(angle)*r),math.floor(py+math.sin(angle)*r),2,2)
   end
   g.setColor(1,1,.6,1-t);text('10',math.floor(px-3),math.floor(py-cell-6-t*8))
  end
  g.setColor(1,1,1,1);text('SCORE '..s.score,65,5);text(self.touchMode and'PAD MOVE / MENU PAUSE'or'D PAD MOVE  B PAUSE',4,self.h-8)
 else
  local cell=math.floor((self.h-24)/20);local ox=math.floor((self.w-cell*10-56)/2);local oy=15
  local function block(x,y,id,ghost)
   if y<1 then return end
   g.setColor(colors[id][1],colors[id][2],colors[id][3],1)
   g.rectangle(ghost and 'line'or 'fill',math.floor(ox+(x-1)*cell+1),math.floor(oy+(y-1)*cell+1),cell-2,cell-2)
  end
  g.setColor(.18,.28,.35,1);g.rectangle('line',ox-1,oy-1,cell*10+2,cell*20+2)
  local clear=self.clearFX
  if clear then
   local e=clear.event;local marked={};for _,y in ipairs(e.rows)do marked[y]=true end
   if clear.time<.28 then
    for y=1,20 do for x=1,10 do
     local id=e.board[y][x]
     if id then
      if not marked[y]then block(x,y,id)
      else
       local t=clear.time/.28;g.setColor(1,1,.65,1)
       local width=math.max(1,math.floor((cell-1)*(1-t)))
       g.rectangle('fill',ox+(x-1)*cell+math.floor((cell-width)/2),oy+(y-1)*cell+1,width,cell-2)
      end
     end
    end end
   else
    local t=math.min(1,(clear.time-.28)/.2);t=1-(1-t)*(1-t)
    for y=1,20 do if not marked[y]then
     local fall=0;for _,row in ipairs(e.rows)do if row>y then fall=fall+1 end end
     for x=1,10 do if e.board[y][x]then block(x,y+fall*t,e.board[y][x])end end
    end end
   end
   g.setColor(1,1,.7,1);text(#e.rows..' LINES',ox+5,57);text(e.points..' POINTS',ox+5,66)
  else
   for y=1,20 do for x=1,10 do if s.board[y][x]then block(x,y,s.board[y][x])end end end
  end
  if not s.over and not clear then
   local p=s.piece;local ghost={id=p.id,x=p.x,y=p.y,rot=p.rot}
   repeat ghost.y=ghost.y+1 until not Rules.fits(s,ghost);ghost.y=ghost.y-1
   for _,c in ipairs(Rules.cells(ghost))do block(c.x,c.y,p.id,true)end
   for _,c in ipairs(Rules.cells(p))do block(c.x,c.y,p.id)end
  end
  local tx=ox+cell*10+7;g.setColor(1,1,1,1);text('SCORE',tx,19);text(s.score,tx,self.touchMode and 32 or 28);text('LINES '..s.lines,tx,self.touchMode and 48 or 42);text('LEVEL '..s.level,tx,self.touchMode and 62 or 54);text('NEXT',tx,self.touchMode and 80 or 70)
  for _,c in ipairs(Rules.cells({id=s.next,x=1,y=1,rot=0}))do g.setColor(unpack(colors[s.next]));g.rectangle('fill',tx+(c.x-1)*5,(self.touchMode and 96 or 82)+(c.y-1)*5,4,4)end
  g.setColor(1,1,1,1);text('A TURN',tx,self.touchMode and 126 or 104);text('UP DROP',tx,self.touchMode and 140 or 114);if not self.touchMode then text('B PAUSE',tx,124)end
 end
 if s.over and not self.clearFX then
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
