-- Fit complete provider frames without fractional stretching. Oversized frames
-- use a uniform whole-number sampling stride, then draw at 1x; small frames
-- can enlarge by whole multiples. Keep the same grid for every animation pose.
local V={}
function V.box(w)
 return {x=6,y=24,w=math.floor(w*.57)-14,h=70}
end
function V.fit(iw,ih,box,bob)
 local w,h=box.w-4,box.h-6
 local scale=math.floor(math.min(w/iw,h/ih));local divisor=1
 if scale<1 then divisor=math.ceil(math.max(iw/w,ih/h));scale=1 end
 local sw,sh=math.ceil(iw/divisor),math.ceil(ih/divisor)
 local dw,dh=sw*scale,sh*scale
 return {x=box.x+2+math.floor((w-dw)/2),y=box.y+box.h-3-dh+math.max(-1,math.min(1,math.floor(bob or 0))),
  w=dw,h=dh,sw=sw,sh=sh,scale=scale,divisor=divisor}
end
function V.draw(image,box,bob,cache)
 local g=love.graphics;local iw,ih=image:getWidth(),image:getHeight()
 local r=V.fit(iw,ih,box,bob)
 g.push('all');g.setScissor(box.x+1,box.y+1,box.w-2,box.h-2);g.setColor(1,1,1,1)
 if r.divisor==1 then g.draw(image,r.x,r.y,0,r.scale,r.scale)
 else
  -- A mesh samples one source texel per output pixel. UVs are constant over
  -- each pixel square, avoiding uneven fractional resizing or GPU readback.
  -- The mesh is reused when an animated provider replaces an Image's pixels.
  local key=iw..':'..ih..':'..r.divisor
  local mesh=cache[key]
  if not mesh then
   local vertices={}
   local function vertex(x,y,u,v)vertices[#vertices+1]={x,y,u,v,1,1,1,1}end
   for y=0,r.sh-1 do for x=0,r.sw-1 do
    local u=(math.min(iw-1,x*r.divisor+math.floor(r.divisor/2))+.5)/iw
    local v=(math.min(ih-1,y*r.divisor+math.floor(r.divisor/2))+.5)/ih
    vertex(x,y,u,v);vertex(x+1,y,u,v);vertex(x+1,y+1,u,v)
    vertex(x,y,u,v);vertex(x+1,y+1,u,v);vertex(x,y+1,u,v)
   end end
   mesh=g.newMesh(vertices,'triangles','static');cache[key]=mesh
  end
  mesh:setTexture(image);g.draw(mesh,r.x,r.y,0,1,1)
 end
 g.pop();return r
end
return V
