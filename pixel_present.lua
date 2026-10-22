-- The game's own window fit can be fractional. Present PC games at whole
-- physical-pixel multiples regardless of that setting, including on HiDPI.
local M={}
function M.layout(w,h,ww,wh,pw,ph)
 local dpiX,dpiY=pw/ww,ph/wh
 local scale=math.max(1,math.floor(math.min(pw/w,ph/h)))
 return {scale=scale,x=math.floor((pw-w*scale)/2)/dpiX,y=math.floor((ph-h*scale)/2)/dpiY,sx=scale/dpiX,sy=scale/dpiY}
end
function M.present(screen)
 local g=love.graphics
 local ww,wh=g.getDimensions();local pw,ph=g.getPixelDimensions()
 local r=M.layout(screen.w,screen.h,ww,wh,pw,ph)
 if not screen.pixelCanvas then
  screen.pixelCanvas=g.newCanvas(screen.w,screen.h,{dpiscale=1})
  screen.pixelCanvas:setFilter('nearest','nearest')
 end
 local previous=g.getCanvas()
 g.push('all');g.setCanvas(screen.pixelCanvas);g.origin();g.setShader();g.setScissor();g.setBlendMode('alpha');g.clear(0,0,0,1)
 screen:draw()
 g.setCanvas(previous);g.origin();g.setShader();g.setScissor();g.clear(0,0,0,1)
 g.setColor(1,1,1,1);g.setBlendMode('alpha','premultiplied')
 g.draw(screen.pixelCanvas,r.x,r.y,0,r.sx,r.sy);g.pop()
 return r
end
return M
