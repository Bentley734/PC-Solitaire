local root=assert(os.getenv('PC_GAMES_SOURCE')):gsub('\\','/')
local gear=assert(os.getenv('PC_GAMES_GEAR')):gsub('\\','/')
local engine=assert(os.getenv('PC_GAMES_ENGINE')):gsub('\\','/')
local output=assert(os.getenv('PC_GAMES_OUTPUT')):gsub('\\','/')
local function read(p)local f=assert(io.open(p,'rb'));local b=f:read('*a');f:close();return b end
local function write(p,b)local f=assert(io.open(output..'/'..p,'wb'));f:write(b);f:close()end
function love.load()
 local ok,err=xpcall(function()
  package.path=engine..'/?.lua;'..package.path
  local G=love.graphics;local Runtime=require('src.mods.Runtime');local Hooks=require('src.mods.Hooks').new();Runtime.hooks=Hooks
  local function noop()end
  local gearMod={hooks={wrap=function(_,name,fn,priority)return Hooks:wrap(name,fn,priority,'kanto_gear')end},events={on=noop},log={info=noop,warn=function(_,s)error(s)end}}
  local theme={i18n={extend=noop},hgss={v4AddAppIcon=noop}}
  local display={homeCatalog={packages={},surfaces={}},storeById={},storeCatalog={},home={},displayBridge={},motion={},perf={start=function()return 0 end}}
  local session={active=true}
  local registry=assert(loadfile(gear..'/mod/kanto_gear/runtime/modules.lua'))()(theme,display,gearMod,session)
  local mod={read=function(_,p)return read(root..'/'..p)end,exports={},find=function()return{exports={modules=registry.exports}}end,log=gearMod.log,
   hooks={wrap=function(_,name,fn,priority)return Hooks:wrap(name,fn,priority,'pc_solitaire')end}}
  local L=dofile(root..'/solitaire_logic.lua');local Solitaire=dofile(root..'/solitaire_screen.lua')(mod,L)
  local More=dofile(root..'/more_screen.lua')(Solitaire,dofile(root..'/more_logic.lua'))
  local image=love.image.newImageData(16,20)
  image:mapPixel(function(x,y)if x>2 and x<14 and y>2 and y<18 then return .9,.75,.15,1 end;return 0,0,0,0 end)
  image=G.newImage(image)
  local Art={new=function()return{valid={PIKACHU=true},choose=function()return'PIKACHU'end,name=function()return'PIKACHU'end,picture=function()return image end}end}
  local saved
  mod.storage={read=function()return saved end,write=function(_,_,_,v)saved=v;return true end}
  local New=dofile(root..'/new_screen.lua')(Solitaire.text,dofile(root..'/mines_logic.lua'),dofile(root..'/pet_logic.lua'),Art,mod,dofile(root..'/pet_viewport.lua'),dofile(root..'/touch_layout.lua'))
  local Screen=dofile(root..'/games_screen.lua')(Solitaire,dofile(root..'/arcade_logic.lua'),More,New)
  local host=dofile(root..'/kanto_gear.lua')(mod,Screen,Solitaire.text,function()return true end,dofile(root..'/direct_touch.lua')(dofile(root..'/touch_layout.lua')))
  -- Install the unmodified KG hook implementation, including its ownership
  -- checks and priorities, rather than imitating the delegation in this test.
  local hookSource=read(gear..'/mod/kanto_gear/runtime/hooks.lua')
  local names=assert(hookSource:match('return function%s*%((.-)%)'))
  local dependencies={mod=gearMod,session=session,displayRuntime=display,THEME=theme,resetSwapState=noop,hgssRuntime={},render={G=G}}
  local args,n={},0
  for name in names:gmatch('[%a_][%w_]*')do n=n+1;args[n]=dependencies[name]end
  assert(loadstring(hookSource))()(unpack(args,1,n))
  local game={save={},options={modOptions={kanto_gear={display_mode='combined'}}},input={wasPressed=function()return false end},stack={states={}}}
  host.bind(game);registry.applyAvailability{edition='red',generation=1};display.homeCatalog.packages.pc_games.installed=true
  assert(registry.open('pc_games'));assert(#registry.order==1,'Unexpected second app tile')
  local View=require('src.render.GameViewport');local target
  local setCanvas=G.setCanvas;G.setCanvas=function(c,...)return setCanvas(c or target,...)end
  local checks,updates=0,0
  local nativeRectangle=G.rectangle;local pads=0
  G.rectangle=function(kind,x,y,w,h,...)if x==80 and y==181 and w==38 and h==30 then pads=pads+1 end;return nativeRectangle(kind,x,y,w,h,...)end
  for _,size in ipairs({{960,720},{480,960},{1280,360}})do
   setCanvas();love.window.setMode(size[1],size[2]);target=G.newCanvas(size[1],size[2]);G.setCanvas(target)
   for choice=0,7 do
    host.screen.child=nil;host.screen.mode=nil
    if choice>0 then host.screen:launch(choice)end
    for frame=1,3 do
     Runtime.call('input.step',function()updates=updates+1 end,game,1/60)
     local rect=View.begin(1);assert(rect.height<size[2],'Native viewport not divided')
     View.setTarget();G.origin();G.setScissor();G.clear(.12,.28,.4,1);G.setColor(1,1,1,1);G.rectangle('fill',frame*4,12,8,8)
     pads=0
     View.finish(game)
     assert(pads==((choice==2 or choice==3)and 1 or 0),'Control pad visible outside Snake/Tetris')
     setCanvas();local data=target:newImageData();G.setCanvas(target);local r,g,b=data:getPixel(10,math.floor(rect.height/2));assert(math.abs(r-.12)<.01 and math.abs(g-.28)<.01 and math.abs(b-.4)<.01,'Lower screen overwrote main gameplay')
     local r,g,b=data:getPixel(frame*4+1,13);assert(r>.99 and g>.99 and b>.99,'Main gameplay stopped rendering')
     assert(host.rect and host.rect.y>=rect.height,'Lower drawing/hit area crossed main screen')
     checks=checks+3
     if frame==3 then write(size[1]..'x'..size[2]..'-'..choice..'.png',data:encode('png'):getString())end
    end
   end
  end
  assert(updates==72 and #game.stack.states==0,'Game updates or native stack changed')
  host.close();assert(not registry.anyShown()and saved,'Close did not hand back display/save pet')
  write('result.txt','PASS '..checks..' GPU assertions, 72 live gameplay frames, seven games and library at three window shapes; actual KG hooks and native GameViewport\n')
 end,debug.traceback)
 if not ok then write('result.txt','FAIL '..tostring(err))end
 love.event.quit(ok and 0 or 1)
end
