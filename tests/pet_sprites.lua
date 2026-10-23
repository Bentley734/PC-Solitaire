local root,engine=assert(arg[1]),assert(arg[2]);package.path=engine..'/?.lua;'..package.path
local Art=dofile(root..'/pet_sprites.lua');local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local gen=1;package.loaded['src.core.GameVersion']={generation=function()return gen end}
local native,animated,g9={},{},{}
local title={currentSprite=function(self)
 ok(self.cycleSpecies[1]=='PIKACHU'and self.game.data.pokemon.PIKACHU,'GB portrait gets species and active data')
 return native
end}
package.loaded['src.ui.TitleState']=title
local cryCalls=0
package.loaded['src.core.Sound']={playCry=function(data,id)ok(data.pokemon.SPRIGATITO and id=='SPRIGATITO','GB cry uses active game data and extended species');cryCalls=cryCalls+1 end}
local game={data={pokemon={PIKACHU={name='PIKACHU',spriteFront='native.png'},SPRIGATITO={name='SPRIGATITO',spriteFront='mod.png'},EGG={name='EGG',spriteFront='egg.png'}}}}
for generation=1,2 do
 gen=generation;local art=Art.new(game)
 ok(#art.pool==2 and art.valid.SPRIGATITO and not art.valid.EGG,'GB pool includes enabled extended dex, excludes egg')
 ok(art:picture('PIKACHU')==native,'native GB art')
 -- 1025Dex installs its animated/static/G9 selection on this live method.
 title.currentSprite=function(self)ok(self.cycleSpecies[1]=='SPRIGATITO','extended species handed through');return animated end
 ok(art:picture('SPRIGATITO')==animated,'1025Dex style replacement observed after adoption')
 title.currentSprite=function()return g9 end;ok(art:picture('SPRIGATITO')==g9,'live style change')
 title.currentSprite=function()return native end
 art:cry('SPRIGATITO')
end
gen=3
local P={_names={[1]='BULBASAUR',[25]='PIKACHU',[1089]='SPRIGATITO',[412]='EGG',[999]='?????'},national=function(id)return id==412 and 0 or id end,
 frontPic=function(id,form,shiny)ok(id==1089 and form==0 and not shiny,'correct Gen3 sprite request');return {image=animated}end}
package.loaded['src.core.game3.pokemon']=P
local art=Art.new(game);ok(#art.pool==3 and art.valid[1089]and not art.valid[412]and not art.valid[999],'Gen3 pool uses live dex without 386 limit')
ok(art:picture(1089)==animated,'Gen3 active provider')
P.frontPic=function()return {image=g9}end;ok(art:picture(1089)==g9,'Gen3 animated/options provider remains live')
for _=1,40 do ok(art.valid[art:choose()]~=nil,'random selection is installed species')end
package.loaded['src.core.game3.audio']={playCry=function(id)ok(id==1089,'Gen3 cry uses internal species slot');cryCalls=cryCalls+1 end}
art:cry(1089)
package.loaded['src.core.game3.audio'].playCry=function()cryCalls=cryCalls+10 end
art:cry(1089);ok(cryCalls==13,'live cry provider changes respected')
print('Active Pokemon art assertions: '..checks)
