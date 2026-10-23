local root=assert(arg[1]);local V=dofile(root..'/pet_viewport.lua');local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local function integer(v)ok(v%1==0,'whole pixel geometry')end
for _,w in ipairs({160,240})do
 local b=V.box(w)
 ok(b.y>21 and b.y+b.h<=94 and b.x+b.w<math.floor(w*.57),'box clears name, age and stats')
 for _,iw in ipairs({8,16,24,56,64,96,128,256,513})do
  for _,ih in ipairs({8,16,56,64,96,128,256,511})do for bob=-4,4 do
   local r=V.fit(iw,ih,b,bob)
   for _,k in ipairs({'x','y','w','h','scale','divisor'})do integer(r[k])end
   ok(r.x>b.x and r.y>b.y and r.x+r.w<b.x+b.w and r.y+r.h<b.y+b.h,'entire frame and motion fit')
   ok(r.scale>=1 and r.divisor>=1 and (r.scale==1 or r.divisor==1),'integer zoom or uniform integer reduction')
  end end
 end
end
local scissor,stack,meshes,draws=nil,{},0,0
local function noop()end
love={graphics={push=function()stack[#stack+1]={scissor}end,pop=function()scissor=table.remove(stack)[1]end,
 setScissor=function(x,y,w,h)scissor={x,y,w,h}end,setColor=noop,
 draw=function(object,x,y,_,sx,sy)integer(x);integer(y);integer(sx);ok(sx==sy and sx>=1,'uniform whole draw scale');ok(scissor~=nil,'pet clipped to viewport');draws=draws+1 end,
 newMesh=function(vertices,mode,usage)
  meshes=meshes+1;ok(mode=='triangles'and usage=='static','cached static mesh')
  for _,v in ipairs(vertices)do integer(v[1]);integer(v[2]);ok(v[3]>=0 and v[3]<=1 and v[4]>=0 and v[4]<=1,'valid source sample')end
  return {setTexture=function(self,image)self.image=image end}
 end}}
local function picture(w,h)return {getWidth=function()return w end,getHeight=function()return h end}end
local cache={};local b=V.box(160)
V.draw(picture(16,16),b,0,cache);ok(meshes==0,'small art draws with integer zoom')
V.draw(picture(64,64),b,1,cache);ok(meshes==0,'normal art stays 1x')
local a=picture(257,129);local r=V.draw(a,b,-1,cache)
ok(r.divisor==4 and meshes==1,'large complete frame reduced by integer stride')
V.draw(a,b,1,cache);V.draw(picture(257,129),b,0,cache)
ok(meshes==1 and draws==5,'animated images share geometry and remain live')
ok(scissor==nil,'scissor state restored for remaining UI')
print('Pet viewport assertions: '..checks)
