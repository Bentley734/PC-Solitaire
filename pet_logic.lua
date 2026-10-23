-- Care advances only while visiting the pet. No offline neglect or death.
local P={}
local fields={'food','happy','energy','clean'}
local function number(v,default,max)
 if type(v)~='number'or v~=v or v==math.huge or v==-math.huge then return default end
 return math.max(0,math.min(max,v))
end
function P.new(species)return {version=1,species=species,food=80,happy=80,energy=80,clean=100,age=0,bond=0,sleeping=false}end
function P.restore(saved,valid)
 if type(saved)~='table'or saved.version~=1 or not valid(saved.species)then return nil end
 local s=P.new(saved.species)
 for _,k in ipairs(fields)do s[k]=number(saved[k],80,100)end
 s.age=number(saved.age,0,31536000);s.bond=math.floor(number(saved.bond,0,9999));s.sleeping=saved.sleeping==true
 return s
end
function P.tick(s,dt)
 dt=number(dt,0,60);s.age=s.age+dt
 s.food=math.max(0,s.food-dt*.10);s.clean=math.max(0,s.clean-dt*.075)
 s.energy=math.max(0,math.min(100,s.energy+dt*(s.sleeping and .65 or -.08)))
 s.happy=math.max(0,s.happy-dt*((s.food<20 or s.clean<20)and .20 or .035))
end
function P.care(s,action)
 if action==3 then s.sleeping=not s.sleeping;return s.sleeping and 'SWEET DREAMS'or 'GOOD MORNING'end
 if s.sleeping then return 'LET ME SLEEP'end
 if action==1 then
  if s.food>=95 then return 'ALREADY FULL'end
  s.food=math.min(100,s.food+25);s.clean=math.max(0,s.clean-4)
 elseif action==2 then
  if s.energy<15 then return 'TOO TIRED'end
  s.happy=math.min(100,s.happy+22);s.energy=math.max(0,s.energy-12);s.food=math.max(0,s.food-4)
 elseif action==4 then s.clean=100;s.happy=math.min(100,s.happy+5)
 else return nil end
 s.bond=math.min(9999,s.bond+1)
 return ({'YUMMY','THAT WAS FUN',false,'ALL CLEAN'})[action]
end
function P.snapshot(s)
 local out={version=1,species=s.species,age=s.age,bond=s.bond,sleeping=s.sleeping}
 for _,k in ipairs(fields)do out[k]=s[k]end
 return out
end
return P
