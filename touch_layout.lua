local M={}
function M.modal(screen)
 local s=screen.child or screen;local count=s.confirm and 2 or screen.mode=='solitaire'and 4 or 3
 local h=28+count*22
 return{x=8,y=math.floor((s.h-h)/2),w=224,h=h,first=24,pitch=22,count=count}
end
function M.mines(w,h)
 local cell=math.floor(math.min((w-12)/9,(h-54)/9))
 return{cell=cell,x=math.floor((w-9*cell)/2),y=34}
end
function M.care(index)
 return{x=4+((index-1)%2)*120,y=136+math.floor((index-1)/2)*28,w=112,h=24}
end
return M
