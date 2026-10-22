local root=assert(arg[1]);local function read(path)local f=assert(io.open(root..'/'..path));local b=f:read('*a');f:close();return b end
local function integer(v)assert(type(v)=='number'and v%1==0,'fractional pixel geometry: '..tostring(v))end
local function noop()end
local draws,frames=0,0
local scales={}
local g={push=noop,pop=noop,setShader=noop,setColor=noop,setLineStyle=noop}
function g.rectangle(_,x,y,w,h)integer(x);integer(y);integer(w);integer(h)end
function g.scale(x,y)integer(x);integer(y);assert(x>=1 and y>=1,'fractional sprite scale')end
function g.newQuad(x,y,w,h,iw,ih)integer(x);integer(y);integer(w);integer(h);return {quad=true}end
function g.newImage()
 return {setFilter=function(_,a,b)assert(a=='nearest'and b=='nearest')end,getWidth=function()return 16 end,getHeight=function()return 24 end}
end
function g.draw(image,a,b,c,d,e,f)
 local x,y,sx,sy
 if type(a)=='table'then x,y,sx,sy=b,c,e,f else x,y,sx,sy=a,b,d,e end
 integer(x);integer(y);integer(sx);integer(sy);assert(sx>=1 and sy>=1 and sx==sy,'sprite scale must be a whole uniform factor');draws=draws+1;scales[sx]=true
end
love={graphics=g,filesystem={newFileData=function(bytes)return bytes end}}
local R=dofile(root..'/arcade_logic.lua');local L=dofile(root..'/more_logic.lua')
local S=assert(load(read('solitaire_screen.lua')))()({read=function()return 'fixture'end},dofile(root..'/solitaire_logic.lua'))
local Extra=assert(load(read('more_screen.lua')))()(S,L)
local G=assert(load(read('games_screen.lua')))()(S,R,Extra)
local game={input={wasPressed=function()return false end}}
for _,size in ipairs({{160,144},{240,160}})do
 local host=G.new(game,size[1],size[2],noop);host:draw();frames=frames+1
 for i=1,5 do
  host:launch(i)
  if i==1 then host.child:act()
  elseif i==2 then local h=host.state.body[1];host.state.food={x=h.x+1,y=h.y};host:tick(.18)
  elseif i==3 then local s=host.state;s.piece={id=1,x=4,y=18,rot=0};s.board[18][2]=3;for x=1,10 do if x<4 or x>7 then s.board[20][x]=2 end end;host:drop(true)
  elseif i==4 then host.child.fx={time=0}
  elseif i==5 then host.child.fx={time=0,cells={{x=1,y=12},{x=2,y=12}}}end
  for _=1,13 do host:draw();frames=frames+1;host:tick(.04)end
 end
end
assert(draws>0 and scales[1]and scales[2],'native cards must exercise 1x and 2x')
local P=dofile(root..'/pixel_present.lua')
local fits=0
for _,size in ipairs({{160,144},{240,160}})do
 for _,window in ipairs({{1280,720,1280,720},{1024,768,1536,1152},{800,600,1600,1200},{1920,1080,1920,1080}})do
  local r=P.layout(size[1],size[2],unpack(window));integer(r.scale)
  assert(math.abs(r.sx*window[3]/window[1]-r.scale)<.00001,'physical horizontal scale')
  assert(math.abs(r.sy*window[4]/window[2]-r.scale)<.00001,'physical vertical scale')
  assert(math.abs(r.x*window[3]/window[1]-math.floor(r.x*window[3]/window[1]+.5))<.00001,'physical x origin')
  assert(r.scale*size[1]<=window[3]and r.scale*size[2]<=window[4],'letterbox fits')
  fits=fits+1
 end
end
print('Integer window/DPI layouts: '..fits)
print('Integer pixel render frames: '..frames..'; sprite draws: '..draws)
