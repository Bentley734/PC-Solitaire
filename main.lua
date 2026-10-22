return function(mod)
local function include(path)
  local bytes,err=mod:read(path);assert(bytes,err)
  return assert(load(bytes,'@pc_solitaire/'..path))()
end
local Logic=include('solitaire_logic.lua')
local Screen=include('solitaire_screen.lua')(mod,Logic)
local active,liveGame
local function open(game,gen3)
  if active then return end
  if gen3 then
    local Stack=require('src.ui.game3.stack')
    local screen=Screen.new(game,240,160,function() Stack.pop('pc_solitaire');active=nil end)
    active=screen
    -- Gen 3 dispatches module functions with dot syntax; Gen 1/2 use state methods.
    Stack.push('pc_solitaire',{isMenu=true,draw=function() screen:draw() end,
      handleInput=function(input) screen:handle(input) end,
      update=function(dt) screen.clock=screen.clock+dt end},{fullscreen=true,hideBelow=true})
  else
    local screen
    screen=Screen.new(game,160,144,function()
      if game.stack:top()==screen then game.stack:pop() end
      active=nil
    end)
    active=screen;game.stack:push(screen)
  end
end
local function row(game)
  return {label='SOLITAIRE',keepOpen=true,onSelect=function() open(game,false) end}
end
local function insert(rows,entry)
  for _,r in ipairs(rows) do if r.label=='SOLITAIRE' then return rows end end
  table.insert(rows,math.max(1,#rows),entry);return rows
end
mod.hooks:wrap('ui.pc.items',function(next,game,items)
  local rows=next(game,items)
  -- The engine appends the exit after this hook, so append here too.
  for _,r in ipairs(rows) do if r.label=='SOLITAIRE' then return rows end end
  rows[#rows+1]=row(game);return rows
end)
local patched={}
local function patch(module,key,wrap)
  local id=tostring(module)..key
  if patched[id] then return end
  patched[id]=true;module[key]=wrap(module[key])
end
mod.events:on('game.ready',function(ev)
  active=nil
  local game=ev.game
  liveGame=game
  local generation=require('src.core.GameVersion').generation()
  if generation==3 then
    local PC=require('src.ui.game3.pc_menu')
    patch(PC,'_rootEntries',function(original) return function(...)
      -- Copy cached rows: script result indexes for all builtins must stay unchanged.
      local rows={};for i,r in ipairs(original(...)) do rows[i]=r end
      rows[#rows+1]={id='pc_solitaire',label='SOLITAIRE'}
      return rows
    end end)
    patch(PC,'handleInput',function(original) return function(input)
      if PC.open and PC.mode=='root' then
        local r=PC._rootEntries()[PC.cursor]
        if r and r.id=='pc_solitaire' and input:wasPressed('a') then open(liveGame,true);return end
      end
      return original(input)
    end end)
    -- Bedroom PCs skip the hub and open directly in a family-specific player menu.
    patch(PC,'show',function(original) return function(opts)
      local result=original(opts)
      if opts and opts.startMode=='player_pc' then
        local Stack=require('src.ui.game3.stack')
        local priorMode,priorCursor=PC.mode,PC.cursor
        local choice=1
        Stack.push('pc_solitaire_bedroom',{
          isMenu=true,
          handleInput=function(input)
            if input:wasPressed('up') or input:wasPressed('down') then choice=3-choice
            elseif input:wasPressed('b') then Stack.pop('pc_solitaire_bedroom')
            elseif input:wasPressed('a') then
              if choice==1 then Stack.pop('pc_solitaire_bedroom');PC.mode=priorMode;PC.cursor=priorCursor
              else open(liveGame,true) end
            end
          end,
          draw=function()
            local Window=require('src.ui.game3.window')
            local box=Window.template(1,1,23,6)
            Window.fill(box);Window.stdFrame(box)
            Window.printPx('PLAYER PC',24,16);Window.printPx('SOLITAIRE',24,32)
            Window.cursorPx(12,choice==1 and 16 or 32)
          end,
        },{hideBelow=false})
      end
      return result
    end end)
  elseif generation==2 then
    local Hub=require('src.ui.gen2.CenterPcMenu')
    patch(Hub,'buildEntries',function(original) return function(self,...)
      original(self,...);insert(self.entries,row(self.game))
    end end)
    patch(Hub,'choose',function(original) return function(self,...)
      if self.entries[self.index] and self.entries[self.index].label=='SOLITAIRE' then open(self.game,false);return end
      return original(self,...)
    end end)
    patch(Hub,'drawPanel',function(original) return function(self,...)
      if not self.booted or #self.entries<=5 then return original(self,...) end
      -- Six postgame rows must fit above the dialogue box at tile 12.
      local proxy=setmetatable({entries={}},{__index=self})
      original(proxy,...)
      local Chrome=require('src.ui.gen2.Chrome')
      for i,entry in ipairs(self.entries) do
        local y=1+(i-1)*2
        if i==self.index then Chrome.cursor(1,y) end
        Chrome.print(entry.label,2,y)
      end
    end end)
    local Item=require('src.ui.gen2.ItemPcMenu')
    patch(Item,'choose',function(original) return function(self,...)
      local entry=self.entries[self.index]
      if entry and entry.label=='SOLITAIRE' then open(self.game,false);return end
      return original(self,...)
    end end)
  else
    local Player=require('src.ui.PlayerPC')
    patch(Player,'new',function(original) return function(g,...)
      local menu=original(g,...);insert(menu.items,row(g));menu.th=menu.th+2;return menu
    end end)
  end
end)
mod.exports.openSolitaire=function(game) open(game,game.data and game.data.generation==3) end
end
