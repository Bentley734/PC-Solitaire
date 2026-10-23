return function(mod)
local function include(path)
  local bytes,err=mod:read(path);assert(bytes,err)
  return assert(load(bytes,'@pc_solitaire/'..path))()
end
local Logic=include('solitaire_logic.lua')
local Solitaire=include('solitaire_screen.lua')(mod,Logic)
local More=include('more_screen.lua')(Solitaire,include('more_logic.lua'))
local New=include('new_screen.lua')(Solitaire.text,include('mines_logic.lua'),include('pet_logic.lua'),include('pet_sprites.lua'),mod)
local Screen=include('games_screen.lua')(Solitaire,include('arcade_logic.lua'),More,New)
local Pixels=include('pixel_present.lua')
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
      update=function(dt) screen:tick(dt) end},{fullscreen=true,hideBelow=true})
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
  return {label='GAMES',keepOpen=true,onSelect=function() open(game,false) end}
end
local function insert(rows,entry)
  for _,r in ipairs(rows) do if r.label=='GAMES' then return rows end end
  table.insert(rows,math.max(1,#rows),entry);return rows
end
mod.hooks:wrap('ui.pc.items',function(next,game,items)
  local rows=next(game,items)
  -- The engine appends the exit after this hook, so append here too.
  for _,r in ipairs(rows) do if r.label=='GAMES' then return rows end end
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
  if type(game.draw)=='function' then
    patch(game,'draw',function(original) return function(self,...)
      local owned=active and active.game==self
      if owned and generation==3 then
        local top=require('src.ui.game3.stack').top()
        owned=top and top.id=='pc_solitaire'
      elseif owned then owned=self.stack:top()==active end
      if owned then return Pixels.present(active)end
      return original(self,...)
    end end)
  end
  if generation==3 then
    local PC=require('src.ui.game3.pc_menu')
    patch(PC,'_rootEntries',function(original) return function(...)
      -- Copy cached rows and place Games immediately before Log Off.
      local rows={};for i,r in ipairs(original(...)) do rows[i]=r end
      local at=#rows+1
      for i,r in ipairs(rows)do if r.id=='quit'then at=i;break end end
      table.insert(rows,at,{id='pc_solitaire',label='GAMES'})
      return rows
    end end)
    patch(PC,'handleInput',function(original) return function(input)
      if PC.open and PC.mode=='root' then
        local r=PC._rootEntries()[PC.cursor]
        if r and r.id=='pc_solitaire' and input:wasPressed('a') then open(liveGame,true);return end
        if r and r.id=='quit' and PC._select and input:wasPressed('a') then
          -- Script menus expect the original zero-based Log Off result.
          PC._silentClose=true
          return PC.close(PC.cursor-2)
        end
      end
      if PC.open and PC.mode=='player_pc' then
        local Profile=require('src.core.game3.profile')
        local id
        if Profile.family(PC._session)=='rse' then id=require('src.ui.game3.rse.player_pc').topOrder(PC)[PC.cursor]
        else local entry=PC.TOP_ACTIONS[PC.cursor];id=entry and entry.id end
        if id=='pc_games' and input:wasPressed('a') then open(liveGame,true);return end
      end
      return original(input)
    end end)
    -- Add Games directly to the native player-PC rows, including bedroom PCs.
    insert(PC.TOP_ACTIONS,{id='pc_games',label='GAMES'})
    local Rse=require('src.ui.game3.rse.player_pc')
    patch(Rse,'topOrder',function(original) return function(pc)
      local rows={};for i,id in ipairs(original(pc)) do rows[i]=id end
      for _,id in ipairs(rows)do if id=='pc_games' then return rows end end
      table.insert(rows,#rows,'pc_games');return rows
    end end)
    patch(Rse,'draw',function(original) return function(pc)
      if pc.mode~='player_pc' then return original(pc) end
      local keys={item_storage='gText_ItemStorage',mailbox='gText_Mailbox',decoration='gText_Decoration',turn_off='gText_TurnOff'}
      local RomText=require('src.core.game3.rom_text')
      local labels={}
      for i,id in ipairs(Rse.topOrder(pc))do labels[i]=id=='pc_games' and 'GAMES' or RomText.plain(keys[id]) end
      Rse.drawMenu(labels,pc.cursor,#labels*2);Rse.drawStatus(pc)
    end end)
  elseif generation==2 then
    local Hub=require('src.ui.gen2.CenterPcMenu')
    patch(Hub,'buildEntries',function(original) return function(self,...)
      original(self,...);insert(self.entries,row(self.game))
    end end)
    patch(Hub,'choose',function(original) return function(self,...)
      if self.entries[self.index] and self.entries[self.index].label=='GAMES' then open(self.game,false);return end
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
      if entry and entry.label=='GAMES' then open(self.game,false);return end
      return original(self,...)
    end end)
  else
    local Player=require('src.ui.PlayerPC')
    patch(Player,'new',function(original) return function(g,...)
      local menu=original(g,...);insert(menu.items,row(g));menu.th=menu.th+2;return menu
    end end)
  end
end)
mod.exports.openGames=function(game) open(game,require('src.core.GameVersion').generation()==3) end
mod.exports.openSolitaire=mod.exports.openGames
end
