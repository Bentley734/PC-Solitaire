return function(mod,Logic)
local Screen={};Screen.__index=Screen
local glyphs={A='010101111101101',B='110101110101110',C='011100100100011',D='110101101101110',E='111100110100111',F='111100110100100',G='011100101101011',H='101101111101101',I='111010010010111',J='001001001101010',K='101101110101101',L='100100100100111',M='101111111101101',N='101111111111101',O='010101101101010',P='110101110100100',Q='010101101111011',R='110101110101101',S='011100010001110',T='111010010010010',U='101101101101111',V='101101101101010',W='101101111111101',X='101101010101101',Y='101101010010010',Z='111001010100111',['0']='111101101101111',['1']='010110010010111',['2']='110001010100111',['3']='110001010001110',['4']='101101111001001',['5']='111100110001110',['6']='011100111101111',['7']='111001010010010',['8']='111101111101111',['9']='111101111001110',['/']='001001010100100',['-']='000000111000000',[':']='000010000010000',['?']='110001010000010',['>']='100010001010100'}
local function text(s,x,y)
  for c in tostring(s):upper():gmatch('.') do
    local bits=glyphs[c]
    if bits then for j=1,15 do if bits:sub(j,j)=='1' then love.graphics.rectangle('fill',x+(j-1)%3,y+math.floor((j-1)/3),1,1) end end end
    x=x+4
  end
end
function Screen.new(game,w,h,close)
  local self=setmetatable({game=game,w=w,h=h,close=close,state=Logic.new(),row=0,col=1,index=1,images={},clock=0,status='A PICK  B MENU',isOpaque=true,isMenu=true},Screen)
  for _,suit in ipairs({'hearts','diamonds','clubs','spades'}) do for rank=1,13 do self:load(suit..'_'..rank) end end
  self:load('back');return self
end
function Screen:load(name)
  local bytes=mod:read('assets/cards/'..name..'.png')
  if not bytes then return end
  local ok,img=pcall(function()
    return love.graphics.newImage(love.filesystem.newFileData(bytes,name..'.png'))
  end)
  if ok then img:setFilter('nearest','nearest');self.images[name]=img end
end
function Screen:ref()
  if self.row==1 then return {kind='tableau',pile=self.col,index=self.index} end
  if self.col==2 then return {kind='waste'} end
  if self.col>=4 then return {kind='foundation',pile=self.col-3} end
end
function Screen:sync()
  if self.row==1 then
    local p=self.state.tableau[self.col];local first=#p+1
    for i,c in ipairs(p) do if c.up then first=i;break end end
    self.index=math.max(math.min(first,#p),math.min(#p,self.index))
    self.index=math.max(1,self.index)
  end
end
function Screen:act()
  if self.row==0 and self.col==1 then
    if self.held then self.status='B CANCEL FIRST';return end
    Logic.drawStock(self.state);self.last=nil;return
  end
  local ref=self:ref();if not ref then return end
  local key=ref.kind..':'..tostring(ref.pile)..':'..tostring(ref.index)
  if self.last==key and self.clock-self.lastTime<=0.35 then
    self.held=nil
    local p=Logic.pile(self.state,ref)
    if p and (not ref.index or ref.index==#p) and Logic.auto(self.state,ref) then self.status='FOUNDATION' else self.status='NO FOUNDATION MOVE' end
    self.last=nil;self:sync();return
  end
  if self.held then
    if Logic.move(self.state,self.held,ref) then self.held=nil;self.status='MOVED';self:sync()
    else self.status='INVALID MOVE' end
    self.last=nil
  elseif Logic.source(self.state,ref) then
    self.held=ref;self.last=key;self.lastTime=self.clock;self.status='A PLACE  B CANCEL'
  end
end
function Screen:handle(input)
  if self.closed then return end
  if self.pause then
    if input:wasPressed('b') or input:wasPressed('start') or input:wasPressed('select') then self.pause=nil
    elseif input:wasPressed('up') then self.menu=(self.menu-2)%4+1
    elseif input:wasPressed('down') then self.menu=self.menu%4+1
    elseif input:wasPressed('a') then
      if self.menu==1 then self.pause=nil
      elseif self.menu==2 then self.state=Logic.new(self.state.draw);self.held=nil;self.last=nil;self.row=0;self.col=1;self.pause=nil
      elseif self.menu==3 then self.state.draw=self.state.draw==1 and 3 or 1
      else self.closed=true;self.close() end
    end
    return
  end
  if input:wasPressed('start') or input:wasPressed('select') then self.pause=true;self.menu=1;return end
  if input:wasPressed('b') then
    if self.held then self.held=nil;self.last=nil;self.status='CANCELLED' else self.pause=true;self.menu=4 end
    return
  end
  local moved=false
  if input:wasPressed('left') then self.col=(self.col-2)%7+1;moved=true
  elseif input:wasPressed('right') then self.col=self.col%7+1;moved=true
  elseif input:wasPressed('down') then
    if self.row==0 then self.row=1;self.index=1 else self.index=self.index+1 end;moved=true
  elseif input:wasPressed('up') then
    if self.row==1 then
      local p=self.state.tableau[self.col]
      if self.index>1 and p[self.index-1] and p[self.index-1].up then self.index=self.index-1 else self.row=0 end
    end;moved=true
  elseif input:wasPressed('a') then self:act() end
  if moved then self.last=nil;self:sync() end
end
function Screen:update(dt)
  self.clock=self.clock+dt
  self:handle(self.game.input)
end
function Screen:card(c,x,y,w,h)
  local g=love.graphics
  local img=c and self.images[c.up and (c.suit..'_'..c.rank) or 'back']
  g.setColor(1,1,1,1)
  if img then g.draw(img,x,y,0,w/img:getWidth(),h/img:getHeight());return end
  g.setColor(c and 0.96 or 0.1,c and 0.96 or 0.35,c and 0.87 or 0.24,1);g.rectangle('fill',x,y,w,h)
  g.setColor(0.1,0.2,0.15,1);g.rectangle('line',x+0.5,y+0.5,w-1,h-1)
  if c then
    if c.up then
      local red=c.suit=='hearts' or c.suit=='diamonds'
      g.setColor(red and 0.8 or 0.05,0.03,0.04,1)
      text(({[1]='A',[11]='J',[12]='Q',[13]='K'})[c.rank] or c.rank,x+2,y+2)
      text(c.suit:sub(1,1),x+2,y+9)
    else
      g.setColor(0.15,0.25,0.65,1)
      for yy=y+2,y+h-3,3 do for xx=x+2,x+w-3,3 do g.rectangle('fill',xx,yy,2,2) end end
    end
  end
end
function Screen:draw()
  local g=love.graphics;g.push('all');g.setShader();g.setColor(0.035,0.28,0.17,1);g.rectangle('fill',0,0,self.w,self.h)
  local step=math.floor((self.w-4)/7);local cw=self.w==160 and 16 or 24;local ch=self.w==160 and 24 or 36
  local function x(c) return 3+(c-1)*step end
  g.setColor(1,1,0.8,1);text('SOLITAIRE  DRAW '..self.state.draw,3,2)
  local topY,base=11,self.w==160 and 40 or 52
  self:card(self.state.stock[#self.state.stock],x(1),topY,cw,ch)
  self:card(self.state.waste[#self.state.waste],x(2),topY,cw,ch)
  for i=1,4 do local p=self.state.foundations[i];self:card(p[#p],x(i+3),topY,cw,ch) end
  local focusY=topY
  for col,p in ipairs(self.state.tableau) do
    local dy=math.min(8,math.max(1,math.floor((self.h-19-base-ch)/math.max(1,#p-1))))
    if #p==0 then self:card(nil,x(col),base,cw,ch) end
    for i,c in ipairs(p) do self:card(c,x(col),base+(i-1)*dy,cw,ch) end
    if self.row==1 and self.col==col then focusY=base+(math.min(self.index,math.max(1,#p))-1)*dy end
    if self.held and self.held.kind=='tableau' and self.held.pile==col then
      g.setColor(0.4,0.8,1,1);g.rectangle('line',x(col)-1,base+(self.held.index-1)*dy-1,cw+2,ch+2)
    end
  end
  g.setColor(1,0.88,0.1,1);g.rectangle('line',x(self.col)-1,focusY-1,cw+2,ch+2)
  local ref=self:ref();local p=Logic.pile(self.state,ref);local c=p and p[ref.index or #p]
  local detail=c and c.up and (({[1]='A',[11]='J',[12]='Q',[13]='K'})[c.rank] or c.rank)..' '..c.suit:upper() or (self.row==0 and self.col==1 and ('STOCK '..#self.state.stock) or 'EMPTY')
  g.setColor(0.02,0.15,0.09,1);g.rectangle('fill',0,self.h-16,self.w,16)
  g.setColor(1,1,1,1);text(detail..(self.held and '  HOLD' or ''),3,self.h-15);text(Logic.won(self.state) and 'YOU WIN - START NEW DEAL' or self.status,3,self.h-7)
  if self.pause then
    local px=math.floor((self.w-126)/2);local py=math.floor((self.h-67)/2)
    g.setColor(0.03,0.12,0.09,1);g.rectangle('fill',px,py,126,67);g.setColor(1,1,0.8,1);g.rectangle('line',px,py,126,67)
    text('PAUSED',px+8,py+5)
    for i,label in ipairs({'RESUME','NEW DEAL','DRAW '..self.state.draw..' / TOGGLE',self.exitLabel or 'QUIT TO PC'}) do text((i==self.menu and '> ' or '  ')..label,px+7,py+8+i*11) end
  end
  g.pop()
end
Screen.text=text
return Screen
end
