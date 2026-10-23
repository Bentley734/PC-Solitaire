return function(Text,Mines,Pet,Art,mod)
local S={};S.__index=S
function S.new(game,w,h,close,kind)
 local self=setmetatable({game=game,w=w,h=h,close=close,kind=kind,x=5,y=5,action=1,clock=0,saveClock=0},S)
 if kind==1 then self.state=Mines.new()
 else
  local ok,art=pcall(Art.new,game)
  self.art=ok and art or {valid={},choose=function()end}
  local saved=mod.storage and mod.storage:read(game,'pokemon_pet')
  self.state=Pet.restore(saved,function(id)return self.art.valid[id]~=nil end)
  if not self.state then local id=self.art:choose();if id then self.state=Pet.new(id);self:save()end end
  if self.state then self:picture()end
 end
 return self
end
function S:save()
 if self.kind~=2 or not self.state then return end
 self.saved=mod.storage and mod.storage:write(self.game,'pokemon_pet',Pet.snapshot(self.state))or false
 self.saveClock=0
end
function S:picture()
 local ok,image=pcall(self.art.picture,self.art,self.state.species)
 self.image=ok and image or nil
 if self.image and self.image.setFilter then self.image:setFilter('nearest','nearest')end
end
function S:tick(dt)
 if self.pause then return end
 self.clock=self.clock+dt
 if self.fx then self.fx=self.fx-dt;if self.fx<=0 then self.fx=nil end end
 if not self.state then return end
 if self.kind==1 then
  if self.state.started and not self.state.over then self.state.time=self.state.time+dt end
 else
  Pet.tick(self.state,dt);self:picture();self.saveClock=self.saveClock+dt
  if self.saveClock>=15 then self:save()end
 end
end
function S:handle(input)
 local function pressed(k)return input:wasPressed(k)end
 if self.confirm then
  if pressed('b')then self.confirm=nil
  elseif pressed('a')then
   local id=self.art:choose();if id then self.state=Pet.new(id);self:save();self:picture()end
   self.confirm=nil;self.pause=nil
  end
  return
 end
 if self.pause then
  if pressed('b')or pressed('start')or pressed('select')then self.pause=nil
  elseif pressed('up')then self.menu=(self.menu-2)%3+1
  elseif pressed('down')then self.menu=self.menu%3+1
  elseif pressed('a')then
   if self.menu==1 then self.pause=nil
   elseif self.menu==2 then
    if self.kind==1 then self.state=Mines.new();self.pause=nil else self.confirm=true end
   else self:save();self.close()end
  end
  return
 end
 if pressed('b')or pressed('start')then self.pause=true;self.menu=1;self:save();return end
 if not self.state then return end
 if self.kind==1 then
  if pressed('left')then self.x=math.max(1,self.x-1)
  elseif pressed('right')then self.x=math.min(9,self.x+1)
  elseif pressed('up')then self.y=math.max(1,self.y-1)
  elseif pressed('down')then self.y=math.min(9,self.y+1)
  elseif pressed('select')then Mines.flag(self.state,self.x,self.y)
  elseif pressed('a')then
   if self.state.over then self.state=Mines.new()else Mines.reveal(self.state,self.x,self.y)end
  end
 else
  if pressed('left')or pressed('right')then self.action=self.action%2==1 and self.action+1 or self.action-1
  elseif pressed('up')or pressed('down')then self.action=(self.action+1)%4+1
  elseif pressed('select')then self.pause=true;self.menu=1;self:save()
  elseif pressed('a')and not self.fx then self.message=Pet.care(self.state,self.action);self.fx=1.2;self:save()end
 end
end
local function panel(g,text,w,h,labels,index,title)
 local x,y=math.floor((w-120)/2),math.floor((h-62)/2)
 g.setColor(.02,.06,.1,1);g.rectangle('fill',x,y,120,62);g.setColor(1,1,.8,1);g.rectangle('line',x,y,120,62)
 text(title,x+7,y+6)
 for i,label in ipairs(labels)do text((i==index and '> 'or '  ')..label,x+7,y+12+i*12)end
end
function S:draw()
 local g=love.graphics;g.push('all');g.setShader();if g.setLineStyle then g.setLineStyle('rough')end
 g.setColor(.025,.07,.12,1);g.rectangle('fill',0,0,self.w,self.h)
 g.setColor(.7,1,.8,1);Text(self.kind==1 and 'MINESWEEPER'or 'POKEPET',6,5)
 local s=self.state
 if self.kind==1 then
  local cell=math.floor(math.min((self.w-12)/9,(self.h-42)/9));local ox=math.floor((self.w-9*cell)/2);local oy=26
  g.setColor(1,1,1,1);Text('FLAGS '..s.flags..'/10',6,16);Text('TIME '..math.min(999,math.floor(s.time)),self.w-38,16)
  local colors={{.25,.6,1},{.25,1,.4},{1,.35,.3},{.75,.5,1},{1,.7,.2},{.2,1,1},{1,.5,.8},{1,1,1}}
  for y=1,9 do for x=1,9 do
   local c=s.cells[y][x];local px,py=ox+(x-1)*cell,oy+(y-1)*cell
   g.setColor(c.open and .10 or .32,c.open and .20 or .43,c.open and .26 or .55,1);g.rectangle('fill',px,py,cell-1,cell-1)
   if c.flag and not c.open then
    g.setColor(1,.75,.2,1);g.rectangle('fill',px+3,py+2,4,3);g.rectangle('fill',px+3,py+2,1,cell-4)
    if s.over and not c.mine then g.setColor(1,.2,.2,1);Text('X',px+4,py+3)end
   elseif c.mine and (c.open or s.over)then
    g.setColor(1,.25,.25,1);g.rectangle('fill',px+3,py+3,cell-6,cell-6);g.rectangle('fill',px+2,py+math.floor(cell/2),cell-4,1)
   elseif c.open and c.n>0 then g.setColor(unpack(colors[c.n]));Text(c.n,px+math.floor((cell-4)/2),py+math.floor((cell-6)/2))end
  end end
  g.setColor(1,.9,.25,1);g.rectangle('line',ox+(self.x-1)*cell-1,oy+(self.y-1)*cell-1,cell+1,cell+1)
  if s.over then g.setColor(1,.9,.4,1);Text(s.won and 'CLEARED  A NEW GAME'or 'BOOM  A NEW GAME',6,self.h-16)
  else g.setColor(.7,.85,.9,1);Text('A DIG  SELECT FLAG',6,self.h-16)end
  Text('B/START MENU',6,self.h-8)
 else
  if s then
   g.setColor(1,1,.8,1);Text(self.art:name(s.species):sub(1,32),6,16)
   local center=math.floor(self.w*.29);local base=92
   g.setColor(.12,.23,.3,1);g.rectangle('fill',center-35,base-5,70,3)
   if self.image then
    local iw,ih=self.image:getWidth(),self.image:getHeight()
    local bounce=not s.sleeping and self.fx and math.floor(math.sin(self.clock*16)*2)or 0
    g.setColor(1,1,1,1);g.draw(self.image,center-math.floor(iw/2),base-ih+bounce,0,1,1)
   else g.setColor(.7,.85,.9,1);Text('LOADING',center-14,54)end
   local x=math.floor(self.w*.57)
   for i,key in ipairs({'food','happy','energy','clean'})do
    local y=30+(i-1)*14;g.setColor(.8,.9,1,1);Text(key:upper()..' '..math.floor(s[key]),x,y)
    g.setColor(.16,.25,.3,1);g.rectangle('fill',x,y+7,self.w-x-8,3)
    g.setColor(s[key]<25 and 1 or .3,s[key]<25 and .4 or .9,.5,1);g.rectangle('fill',x,y+7,math.floor((self.w-x-8)*s[key]/100),3)
   end
   g.setColor(1,.8,.4,1)
   if s.sleeping then Text('Z Z Z',center+17,30)
   elseif self.fx then
    local y=math.floor(27-(1.2-self.fx)*6);Text(self.action==1 and 'YUM'or self.action==4 and 'CLEAN'or 'LOVE',center-7,y)
   end
   g.setColor(.8,.9,1,1);Text('AGE '..math.floor(s.age/60)..'M  BOND '..s.bond,6,96)
   Text(self.fx and self.message or s.sleeping and 'RESTING' or 'HOW ABOUT SOME CARE?',6,105)
   for i,label in ipairs({'FEED','PLAY',s.sleeping and 'WAKE'or 'REST','CLEAN'})do
    g.setColor(i==self.action and 1 or .65,i==self.action and .9 or .8,i==self.action and .3 or .85,1)
    Text((i==self.action and '> 'or '  ')..label,8+((i-1)%2)*math.floor(self.w/2),115+math.floor((i-1)/2)*10)
   end
   g.setColor(.7,.85,.9,1);Text(self.saved==false and 'SAVE FAILED - SESSION ONLY'or 'A CARE  B MENU',6,self.h-8)
  else g.setColor(1,1,1,1);Text('NO POKEMON ART AVAILABLE',6,45);Text('B MENU',6,60)end
 end
 if self.pause then panel(g,Text,self.w,self.h,{'RESUME',self.kind==1 and 'NEW GAME'or 'NEW PET','BACK TO GAMES'},self.menu,'PAUSED')end
 if self.confirm then panel(g,Text,self.w,self.h,{'A ADOPT NEW PET','B KEEP THIS PET'},0,'REPLACE CURRENT PET?')end
 g.pop()
end
return S
end
