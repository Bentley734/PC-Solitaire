-- Ask the live menu-picture seams; never copy or bundle Pokemon art.
local Art={}
function Art.new(game)
 local self={game=game,pool={},valid={}}
 local gen=require('src.core.GameVersion').generation()
 if gen==3 then
  local P=require('src.core.game3.pokemon')
  if not P._names then P.install(P._cache)end
  for id,name in pairs(P._names or {})do
   local nat=P.national(id)
   if type(id)=='number'and id>0 and nat and nat>0 and type(name)=='string'and name~=''and not name:find('?',1,true)and name:upper()~='EGG'then
    self.pool[#self.pool+1]=id;self.valid[id]=name
   end
  end
  self.picture=function(_,id)local pic=P.frontPic(id,0,false,0);return pic and pic.image end
 else
  for id,def in pairs(game.data and game.data.pokemon or {})do
   if type(def)=='table'and def.spriteFront and type(def.name or id)=='string'and tostring(id):upper()~='EGG'and (def.name or ''):upper()~='EGG'then
    self.pool[#self.pool+1]=id;self.valid[id]=def.name or tostring(id)
   end
  end
  local Title=require('src.ui.TitleState')
  local owner={game=game,cycleIndex=1,cycleSpecies={},sprites={}}
  self.picture=function(_,id)
   owner.cycleSpecies[1]=id
   -- Resolve the method live, so changing sprite options also changes the pet.
   return Title.currentSprite(owner)
  end
 end
 table.sort(self.pool,function(a,b)return tostring(a)<tostring(b)end)
 function self:choose()if #self.pool>0 then return self.pool[math.random(#self.pool)]end end
 function self:name(id)return self.valid[id]or 'POKEMON'end
 function self:cry(id)
  if gen==3 then return require('src.core.game3.audio').playCry(id)end
  return require('src.core.Sound').playCry(game.data,id)
 end
 return self
end
return Art
