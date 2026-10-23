-- A separate touch-only host: never pushes a native state or replaces game input.
return function(mod,Screen,Text,canOpen,Direct)
 local M={pointers={},held={}};local W,H=240,216
 local buttons={
  {key='up',label='UP',x=25,y=177,w=23,h=12},{key='down',label='DN',x=25,y=203,w=23,h=12},
  {key='left',label='LT',x=1,y=190,w=23,h=12},{key='right',label='RT',x=49,y=190,w=23,h=12},
  {key='a',label='A',x=80,y=181,w=38,h=30},{key='b',label='B',x=123,y=181,w=38,h=30},
  {key='start',label='MENU',x=169,y=179,w=67,h=15},{key='select',label='SELECT',x=169,y=198,w=67,h=15},
 }
 M.buttons=buttons
 local function inside(r,x,y)return r and x>=r.x and y>=r.y and x<r.x+(r.w or r.width)and y<r.y+(r.h or r.height)end
 function M.clearInput()M.pointers={};M.held={}end
 local function flush(screen)
  if not screen then return end
  if screen.child then flush(screen.child)end
  if screen.save then screen:save()end
 end
 function M.close()
  local screen=M.screen;M.screen=nil;M.rect=nil;M.layout=nil;M.external=false
  M.clearInput();flush(screen)
 end
 local function preferences()
  return M.game and M.game.options and M.game.options.modOptions and M.game.options.modOptions.kanto_gear or{}
 end
 local function externalWanted()
  local p=preferences();local mode=p.display_mode or(p.window_layout and p.window_layout~='off'and'combined'or'separate')
  -- Phone streaming is Gear-owned and not part of modules API 1. Use the
  -- in-window lower screen when no transferable native display is available.
  if mode~='separate'or p.display_target=='handheld'then return false end
  local b=M.bridge
  if b==M.failedBridge then return false end
  if not(b and b.detected and b.push and b.pollTouch)then return false end
  local ok,detected=pcall(b.detected);return ok and detected==true
 end
 function M.open()
  if not M.registered or M.screen or not M.game or canOpen and not canOpen()then return false end
  local input={}
  function input:isDown(key)return M.held[key]==true end
  function input:wasPressed()return false end
  -- All save/data providers still see the live game; only input is private.
  local game=setmetatable({input=input},{__index=M.game})
  M.clearInput();M.failedBridge=nil;M.screen=Screen.new(game,240,200,M.close)
  M.screen.touchMode=true
  local launch=M.screen.launch
  M.screen.launch=function(self,index)
   self.h=(index==2 or index==3)and 160 or 200
   launch(self,index);if self.child then self.child.touchMode=true end
  end
  M.screen.exitLabel='BACK TO GEAR';M.nextPresent=0;M.external=externalWanted()
  return true
 end
 function M.press(key)
  if M.screen then M.screen:handle({wasPressed=function(_,k)return k==key end,isDown=function(_,k)return M.held[k]==true end})end
 end
 local function rebuildHeld()
  M.held={};for _,p in pairs(M.pointers)do if p.key then M.held[p.key]=true end end
 end
 function M.touch(phase,id,x,y)
  if not M.screen then return false end
  local prior=M.pointers[id]
  if phase=='released'or phase=='cancelled'then
   M.pointers[id]=nil;rebuildHeld()
   if phase=='released'and prior and prior.tap and x and math.abs(x-prior.x)<8 and math.abs(y-prior.y)<8 then Direct.tap(M.screen,prior.x,prior.y-16,prior.age>=.45)end
   return prior~=nil or x and inside({x=0,y=0,w=W,h=H},x,y)or false
  end
  if phase=='moved'then
   if prior and prior.key and({up=true,down=true,left=true,right=true})[prior.key]then
    local key;for _,b in ipairs(buttons)do if inside(b,x,y)and({up=true,down=true,left=true,right=true})[b.key]then key=b.key end end
    if key~=prior.key then prior.key=key;rebuildHeld();if key then M.press(key)end end
   end
   return prior~=nil or inside({x=0,y=0,w=W,h=H},x,y)
  end
  if phase~='pressed'or not inside({x=0,y=0,w=W,h=H},x,y)then return false end
  if prior then return true end
  M.pointers[id]={}
  if y<15 and x>=174 then M.close();return true end
  if y<15 and x>=116 and M.screen.mode then M.press('start');return true end
  if M.screen.mode=='snake'or M.screen.mode=='tetris'then
   for _,b in ipairs(buttons)do if inside(b,x,y)then M.pointers[id].key=b.key;rebuildHeld();M.press(b.key);return true end end
  end
  if y>=16 then M.pointers[id]={tap=true,x=x,y=y,age=0}end
  return true
 end
 function M.fit(rect,pixelRatio)
  local scale=math.min(rect.w/W,rect.h/H);local dpi=pixelRatio or 1
  if scale*dpi>=1 then scale=math.floor(scale*dpi)/dpi end
  return{x=math.floor(rect.x+(rect.w-W*scale)/2),y=math.floor(rect.y+(rect.h-H*scale)/2),w=W*scale,h=H*scale}
 end
 function M.drawCanvas()
  if not M.screen or M.pending then return M.canvas end
  local G=love.graphics
  if not M.canvas then M.canvas=G.newCanvas(W,H,{dpiscale=1});M.canvas:setFilter('nearest','nearest')end
  local depth=G.getStackDepth and G.getStackDepth()
  G.push('all');local ok,err=pcall(function()
   G.setCanvas(M.canvas);G.origin();G.setShader();G.setScissor();if G.setStencilTest then G.setStencilTest()end
   G.setBlendMode('alpha');G.clear(.025,.07,.12,1);G.setColor(.65,1,.82,1)
   local function contents()
   Text('PC GAMES',6,3);if M.screen.mode then Text('MENU',126,3,2)end;Text('X CLOSE',178,3,2)
   local pad=M.screen.mode=='snake'or M.screen.mode=='tetris'
   M.screen.h=pad and 160 or 200
   G.push('all');G.translate(0,16);G.setScissor(0,16,240,M.screen.h)
   local child=M.screen.child or M.screen;local pause,confirm=child.pause,child.confirm
   child.pause,child.confirm=nil,nil
   local drawn,why=pcall(M.screen.draw,M.screen);child.pause,child.confirm=pause,confirm
   if not drawn then error(why,0)end
   if pause or confirm then
    local r=Direct.layout.modal(M.screen)
    G.setColor(.025,.09,.14,1);G.rectangle('fill',r.x,r.y,r.w,r.h)
    G.setColor(.7,1,.85,1);G.rectangle('line',r.x,r.y,r.w,r.h)
    Text(confirm and'REPLACE PET?'or'PAUSED',r.x+8,r.y+6)
    local labels=confirm and{'ADOPT NEW PET','KEEP THIS PET'}or M.screen.mode=='solitaire'and{'RESUME','NEW DEAL','TOGGLE DRAW MODE','BACK TO GAMES'}or{'RESUME',M.screen.mode=='pokepet'and'NEW PET'or'NEW GAME','BACK TO GAMES'}
    for i,label in ipairs(labels)do
     local y=r.y+r.first+(i-1)*r.pitch;G.setColor(.09,.2,.27,1);G.rectangle('fill',r.x+4,y,r.w-8,r.pitch-2)
     G.setColor(.9,1,.9,1);Text(label,r.x+12,y+5,2)
    end
   end
   G.pop()
   for _,b in ipairs(pad and buttons or{})do
    G.setColor(M.held[b.key]and .20 or .10,.28,.36,1);G.rectangle('fill',b.x,b.y,b.w,b.h)
    G.setColor(.8,1,.9,1);Text(b.label,b.x+math.floor((b.w-#b.label*8)/2),b.y+math.floor((b.h-10)/2),2)
   end
   end
   if Screen.withTextScale then Screen.withTextScale(1,contents)else contents()end
  end)
  if depth then while G.getStackDepth()>depth do G.pop()end else G.pop()end
  if not ok then M.close();error(err,0)end
  return M.canvas
 end
 local function shown()return M.screen~=nil end
 function M.register()
  if M.registered or not mod.find then return end
  local gear=mod.find('kanto_gear');local modules=gear and gear.exports and gear.exports.modules
  if not(modules and modules.api==1)then return end
  local accepted,why=modules.register({id='pc_games',label='PC GAMES',category='GAMES',accent='green',
   description={'SEVEN TOUCH-CONTROLLED GAMES.','POKEMON KEEPS RUNNING ABOVE.','INCLUDES POKEPET.'},
   icon=function(x,y,grey)local G=love.graphics;G.setColor(grey and .4 or .2,grey and .4 or .75,.4,1);G.rectangle('fill',x+2,y+4,20,15);G.setColor(.02,.1,.08,1);G.rectangle('fill',x+4,y+6,16,9);G.rectangle('fill',x+7,y+20,10,2)end,
   available=function(ctx)return ctx and ctx.generation>=1 and ctx.generation<=3 end,shown=shown,open=M.open})
  if not accepted then if mod.log then mod.log:warn('Kanto Gear registration: '..tostring(why))end;return end
  M.registered=true
  -- The native touch overlay runs before input.pointer and draws afterward.
  -- Fence only our lower panel; physical buttons and upper touches stay native.
  local ok,Touch=pcall(require,'src.core.TouchControls')
  if ok and Touch then
   Touch._pcGamesGearHost=M
   if not Touch._pcGamesGearTouch then
    local pressed,draw=Touch.touchpressed,Touch.draw;Touch._pcGamesGearTouch=true
    if pressed then Touch.touchpressed=function(self,id,x,y,...)
     local host=Touch._pcGamesGearHost
     if host.screen and not host.external and inside(host.layout,x,y)then return false end
     return pressed(self,id,x,y,...)
    end end
    if draw then Touch.draw=function(self,...)
     local host=Touch._pcGamesGearHost
     if not(host.screen and not host.external and host.layout)then return draw(self,...)end
     local G=love.graphics;G.push('all');G.setScissor(0,0,G.getWidth(),math.max(0,host.layout.y-2))
     local success,result=pcall(draw,self,...);G.pop();if not success then error(result,0)end;return result
    end end
   end
  end
  mod.hooks:wrap('input.step',function(next,game,dt)
   local result=next(game,dt)
   if M.screen and game==M.game then
    dt=math.max(0,math.min(.1,tonumber(dt)or 0))
    for _,p in pairs(M.pointers)do if p.tap then p.age=p.age+dt end end
    M.screen:tick(dt)
   end
   return result
  end,1100)
  mod.hooks:wrap('input.pointer',function(next,game,event)
   if not(M.screen and game==M.game and not M.external)or event.button and event.button~=1 then return next(game,event)end
   local r=M.rect;local id=tostring(event.source or'pointer')..':'..tostring(event.id or 1)
   if event.phase=='cancelled'then if M.touch('cancelled',id)then return true end
   elseif r and r.w>0 and r.h>0 and(inside(r,event.x,event.y)or M.pointers[id])then
    return M.touch(event.phase,id,(event.x-r.x)*W/r.w,(event.y-r.y)*H/r.h)
   end
   if event.x and event.y and inside(M.layout,event.x,event.y)then return true end
   return next(game,event)
  end,1100)
  mod.hooks:wrap('render.viewport',function(next,context)
   local base=next(context)
   if not M.screen then return base end
   local external=externalWanted();if external~=M.external then M.external=external;M.rect=nil;M.clearInput()end
   if M.external then M.layout=nil;return base end
   base=base or{x=0,y=0,width=context.width,height=context.height}
   local share=math.max(.30,math.min(.65,(tonumber(preferences().secondary_size)or 46)/100))
   local safe=math.max(0,math.min(50,tonumber(preferences().bottom_safe_area)or 0))
   local total=base.height*(1-safe/100);local bottom=math.floor(total*share);local top=math.max(1,total-bottom-2)
   M.layout={x=base.x or 0,y=(base.y or 0)+top+2,w=base.width,h=bottom}
   return{x=base.x or 0,y=base.y or 0,width=base.width,height=top,capture=true}
  end,1100)
  mod.hooks:wrap('render.window',function(next,game,context)
   local result=next(game,context)
   if not(M.screen and M.game==game and not M.external and M.layout)then return result end
   local canvas=M.drawCanvas();local G=love.graphics;local r=M.fit(M.layout,context.dpiX)
   G.push('all');G.setCanvas();G.origin();G.setShader();G.setScissor();G.setBlendMode('alpha','premultiplied')
   G.setColor(.025,.07,.12,1);G.rectangle('fill',M.layout.x,M.layout.y,M.layout.w,M.layout.h)
   G.setColor(1,1,1,1);G.draw(canvas,r.x,r.y,0,r.w/W,r.h/H);G.pop();M.rect=r;return result
  end,1100)
  mod.hooks:wrap('render.compose',function(next,renderer,context)
   M.bridge=context and context.secondScreen or M.bridge
   local result=next(renderer,context)
   if M.pending and M.canvas then local image=M.canvas:pollImageData();if image then M.pending=nil;M.readyImage=image end end
   if not(M.screen and M.external and M.bridge)then M.readyImage=nil;return result end
   local bridge=M.bridge
   for _=1,32 do
    local event=bridge.pollTouch();if not event then break end
    local action,x,y=tostring(event):match('^(%a+),([%d%.%-]+),([%d%.%-]+)$')
    if action then M.touch(({down='pressed',up='released',move='moved',cancel='cancelled'})[action],'secondary',tonumber(x),tonumber(y))end
    if not M.screen then break end
   end
   if not M.screen then return result end
   local now=love.timer.getTime()
   if now<(M.nextPresent or 0)then return result end
   if bridge.setEnabled then bridge.setEnabled(true)end
   local function submit(image)
    local ok,presented=pcall(bridge.push,image,W,H,0x06121f,'secondary')
    if not ok or presented~=true then M.failedBridge=bridge;M.external=false;M.clearInput()end
   end
   if M.readyImage then submit(M.readyImage);M.readyImage=nil end
   if not M.external then return result end
   if not M.pending then
    local canvas=M.drawCanvas()
    if canvas.requestImageData and canvas.pollImageData then
     local ok,requested=pcall(canvas.requestImageData,canvas)
     if ok and requested then M.pending=true else submit(canvas:newImageData())end
    else submit(canvas:newImageData())end
   end
   M.nextPresent=now+1/30;return result
  end,1100)
 end
 function M.bind(game)M.close();M.game=game;M.register()end
 M.register();return M
end
