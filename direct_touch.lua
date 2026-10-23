-- Hit testing shares each native screen's card/cell/menu geometry.
return function(Layout)
local M={layout=Layout}
local function press(screen,key)screen:handle({wasPressed=function(_,k)return k==key end})end
function M.tap(screen,x,y,long)
 local s=screen.child or screen;local mode=screen.mode
 if s.confirm then
  local r=Layout.modal(screen)
  if x>=r.x and x<r.x+r.w and y>=r.y+r.first and y<r.y+r.first+r.pitch*2 then press(screen,y<r.y+r.first+r.pitch and'a'or'b')end
  return true
 end
 if s.pause then
  local r=Layout.modal(screen);local index=math.floor((y-r.y-r.first)/r.pitch)+1
  if x>=r.x and x<r.x+r.w and index>=1 and index<=r.count then s.menu=index;press(screen,'a')end
  return true
 end
 if not mode then
  if y>=26 and y<186 then screen.index=math.floor((y-26)/20)+1;press(screen,'a')end
 elseif mode=='pokepet'then
  for index=1,4 do local r=Layout.care(index)
   if x>=r.x and x<r.x+r.w and y>=r.y and y<r.y+r.h then s.action=index;press(screen,'a');break end
  end
 elseif mode=='minesweeper'then
  local r=Layout.mines(s.w,s.h);local cell=r.cell
  if x>=r.x and x<r.x+cell*9 and y>=r.y and y<r.y+cell*9 then
   s.x=math.floor((x-r.x)/cell)+1;s.y=math.floor((y-r.y)/cell)+1;press(screen,long and'select'or'a')
  end
 elseif mode=='blackjack'then
  if s.state.phase=='done'then press(screen,'a')
  elseif y>=s.h-30 and y<s.h-12 then s.index=math.min(3,math.floor(x/(s.w/3))+1);press(screen,'a')end
 elseif mode=='collapse'then
  if s.state.over then press(screen,'a');return true end
  local cell=math.floor(math.min((s.w-12)/10,(s.h-37)/12));local ox=math.floor((s.w-cell*10)/2)
  if x>=ox and x<ox+cell*10 and y>=16 and y<16+cell*12 then s.x=math.floor((x-ox)/cell)+1;s.y=math.floor((y-16)/cell)+1;press(screen,'a')
  elseif y>=s.h-13 then s.y=12;press(screen,'down')end
 elseif mode=='solitaire'then
  local step=math.floor((s.w-4)/7);local col=math.floor((x-3)/step)+1
  if col<1 or col>7 then return true end
  if y>=11 and y<59 then
   if col~=3 then s.row=0;s.col=col;press(screen,'a')end
  elseif y>=64 and y<s.h-16 then
   local pile=s.state.tableau[col];local dy=math.min(8,math.max(1,math.floor((s.h-19-64-48)/math.max(1,#pile-1))))
   s.row=1;s.col=col;s.index=math.max(1,math.min(#pile,math.floor((y-64)/dy)+1))
   if pile[s.index]and not pile[s.index].up then return true end
   s:sync();press(screen,'a')
  elseif s.held then press(screen,'b')end
 end
 return true
end
return M
end
