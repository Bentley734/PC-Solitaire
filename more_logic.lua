-- Standalone rules for Blackjack and rising-block Collapse.
local M={}
function M.total(hand)
 local total,aces=0,0
 for _,c in ipairs(hand)do total=total+math.min(c.rank,10);if c.rank==1 then aces=aces+1 end end
 while aces>0 and total+10<=21 do total=total+10;aces=aces-1 end
 return total
end
local function take(s,hand)hand[#hand+1]=table.remove(s.deck)end
function M.blackjack(random,score)
 local s={deck={},player={},dealer={},score=score or 0,bet=10,phase='player',random=random or math.random}
 for _,suit in ipairs({'hearts','diamonds','clubs','spades'})do for rank=1,13 do s.deck[#s.deck+1]={rank=rank,suit=suit,up=true}end end
 for i=52,2,-1 do local j=s.random(i);s.deck[i],s.deck[j]=s.deck[j],s.deck[i]end
 take(s,s.player);take(s,s.dealer);take(s,s.player);take(s,s.dealer)
 if M.total(s.player)==21 or M.total(s.dealer)==21 then M.settle(s)end
 return s
end
function M.settle(s)
 if s.phase=='done'then return end
 local p,d=M.total(s.player),M.total(s.dealer)
 if p>21 then s.result='BUST';s.score=s.score-s.bet
 elseif d>21 or p>d then
  local natural=#s.player==2 and p==21
  s.result=natural and 'BLACKJACK'or 'YOU WIN';s.score=s.score+(natural and 15 or s.bet)
 elseif p==d then s.result='PUSH'
 else s.result='DEALER WINS';s.score=s.score-s.bet end
 s.phase='done'
end
function M.stand(s)
 if s.phase~='player'then return false end
 while M.total(s.dealer)<17 do take(s,s.dealer)end
 M.settle(s);return true
end
function M.hit(s)
 if s.phase~='player'then return false end
 take(s,s.player)
 if M.total(s.player)>21 then M.settle(s)elseif M.total(s.player)==21 then M.stand(s)end
 return true
end
function M.double(s)
 if s.phase~='player'or #s.player~=2 then return false end
 s.bet=20;take(s,s.player);if M.total(s.player)>21 then M.settle(s)else M.stand(s)end;return true
end
function M.collapse(random)
 local s={board={},score=0,rows=0,random=random or math.random}
 for y=1,12 do s.board[y]={};if y>=8 then for x=1,10 do s.board[y][x]=s.random(4)end end end
 for x=1,3 do s.board[12][x]=1 end
 return s
end
function M.group(s,x,y)
 local color=s.board[y]and s.board[y][x];if not color then return {}end
 local out,seen,queue={},{},{{x=x,y=y}};local at=1
 while at<=#queue do
  local p=queue[at];at=at+1;local key=p.y*10+p.x
  if p.x>=1 and p.x<=10 and p.y>=1 and p.y<=12 and not seen[key]and s.board[p.y][p.x]==color then
   seen[key]=true;out[#out+1]=p
   queue[#queue+1]={x=p.x-1,y=p.y};queue[#queue+1]={x=p.x+1,y=p.y};queue[#queue+1]={x=p.x,y=p.y-1};queue[#queue+1]={x=p.x,y=p.y+1}
  end
 end
 return out
end
function M.removeGroup(s,x,y)
 if s.over then return false end
 local group=M.group(s,x,y);if #group<3 then return false end
 for _,p in ipairs(group)do s.board[p.y][p.x]=nil end
 for x=1,10 do
  local values={};for y=12,1,-1 do if s.board[y][x]then values[#values+1]=s.board[y][x]end;s.board[y][x]=nil end
  for i,v in ipairs(values)do s.board[13-i][x]=v end
 end
 s.score=s.score+#group*(#group-1)*5;return group
end
function M.rise(s)
 if s.over then return end
 for x=1,10 do if s.board[1][x]then s.over=true;return end end
 table.remove(s.board,1);local row={};for x=1,10 do row[x]=s.random(4)end;s.board[12]=row;s.rows=s.rows+1
end
return M
