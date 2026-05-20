pico-8 cartridge // http://www.pico-8.com
version 0
__lua__

-- league of john
-- by william
-- project start date : 21/08/2018
-- made for the demake jam : 14/08 - 25/08

local game_objects ={}
local allies ={}
local enemies ={}
local building ={}
local part={}
local shkx, shky = 0, 0
local main_camera
local mouse
local mode='start'
local do_once = false
local left_click_once_timer=100
local right_click_once_timer=100
local p_champ = nil

function _init()
 poke(0x5f2d,1)
 sfx(11, 1)
end

function _update60()
 if mode == 'start' then
  update_start()
 elseif mode=='game' then
  update_game()
 elseif mode=='gameover' then
  update_gameover()
 elseif mode=='victory' then
  update_victory()
 end

--  if is_mouse_left_click_once() then      make_unit(mouse.x, mouse.y, 'enemy_unit1', 445/2, 25,
--      {class='melee', tag='ally', target=turret, damage=5, range=2+rnd(4),
--       timer=0, attack_speed=1.25}, {hit=4, death=8},{move={{sx=56, sy=0, sw=8, sh=8},{sx=64, sy=0, sw=8, sh=8}},
--      attack={{sx=72, sy=0, sw=8, sh=8}, {sx=80, sy=0, sw=8, sh=8}}, col1=8, col2=2, width=8, height=8})
-- end
-- make_unit(128, 128, 'enemy_unit1', 25, 16+rnd(2),
--   {class='melee', target_tag='ally', target=turret, damage=1, range=16+rnd(2),
--    timer=0, attack_speed=1}, {hit=4, death=8},{move={{sx=16, sy=0, sw=16, sh=16},{sx=32, sy=0, sw=16, sh=16}},
--   attack={{sx=46, sy=0, sw=16, sh=16}, {sx=64, sy=0, sw=16, sh=16}}, col1=12, col2=1})
end


function _draw()
 if mode == 'start' then
  draw_start()
 elseif mode=='game' then
  draw_game()
 elseif mode=='gameover' then
  draw_gameover()
 elseif mode=='victory' then
  draw_victory()
 end
 if mouse == nil then return end

 -- pset(0, 0, 11)
 -- print(stat(7), mouse.x, mouse.y+16, 8)
 -- print(spawner_ally.alivee+spawner_enemy.alivee, mouse.x, mouse.y-17, 8)
 -- print(main_camera.x-mouse.x, mouse.x, mouse.y+16, 8)
 -- if mouse.target == nil then return end
 -- print(#game_objects, mouse.x, mouse.y+32, 8)
end

function update_start()
 if btn(5) then  sfx(-1, 1) sfx(12) start_game() end
end

function draw_start()
 cls(3)
  -- outline_sspr(0, 32, 16, 16, 16, 64, 16, 16 )
  sspr(0, 32, 16, 16, 42, 28, 32, 32)

  spe_print("league of john", 35, 10, 12, 1)
  spe_print("by william", 5, 120, 9, 4, true)
 if time()*1%2 > 0.5 then spe_print('press ❎ to \n\n   start ', 35, 64, 11, 3) end

end

function draw_game()
 cls(3)

  -- draw_map()
  whiteframe_update()
  draw_part()
  draw_all_gameobject()

 draw_minimap()
 draw_mouse_cursor()
  -- print(distance(ally_nexus, enemy_nexus), mouse.x, mouse.y-17, 10)
end

function draw_map()
  -- for i=-1, 45 do
  for i=7, 28 do
  -- for i=(main_camera.y)/50, (main_camera.y)/50 +2 do
    map(9,5,-50+i*15,57-i*15, 10, 10)
    pal()
  end
  -- if main_camera.x >200 and main_camera.x < 450 and main_camera.y >-350 and main_camera.y < -100 then
  --  for i=200, 450 do
  --   for y=-250, -200 do
  --    local p = pget(i, y)
  --    if p==3 then pset(i,y, 1) 
  --    elseif p==4 then pset(i,y,12)
  --    elseif p==15 then pset(i,y,11)
  --    elseif p==13 then pset(i,y,3)
  --    end 
  --   end
  --  end
  -- end
end

-- ##update
function update_game()

 update_part()
 do_camera_shake()
 random_enemy_spawning(spawner_ally)
 random_enemy_spawning(spawner_enemy)
 update_all_gameobject()
 camera_follow()
 manage_player_champion()
 -- victory_gameover_check()
end
function draw_gameover()
 cls(3)

 if do_once == false then 
  do_once=true

 show_message('defeat', main_camera.x-20, main_camera.y-20-4*(cos(time())), 8, 2, 15, 2, 'gameover1', true, false, false , 7)
 -- show_message('press ❎ button \n\n  to restart', main_camera.x-29, main_camera.y + 10, 11, 3, 2, 2, 'gameover3', true, false, false , 7)
 
 end
 for obj in all(game_objects) do
  if(obj:is_active() == true) then
   obj:draw()
  end
 end
end

function draw_minimap()
 local x0, y0, x1, y1, posx, posy, posy1 = 31, 31, 62, 62, main_camera.x+31, main_camera.y+31, main_camera.y+62


 rectfill(posx, posy, main_camera.x+x1, posy1, 3)
 -- draw decors on minimap
 for i=1, 14 do
  rectfill(posx-2+i*2, posy1-2-i*2, posx+4+i*2, posy1+4-i*2, 15)
 end
 -- draw border 
 rect(posx-1, posy-1, main_camera.x+x1+1, posy1+1, 0)


 for obj in all(game_objects) do
  if obj:is_active() == true then
   local col = 8 
   if sub(obj:get_tag(), 0, 4) == 'ally' then col = 12 end
    if obj:is_active() and sub(obj:get_tag(), -5, #obj:get_tag()-1) == 'unit' then
    pset(posx+obj.x/25+x1/3.25-17, posy+obj.y/25+y1/3.25+7, col)
   elseif sub(obj:get_tag(), 6,13) == 'champion' then 
    circfill(posx+obj.x/25+x1/3.25-17, posy+obj.y/25+y1/3.25+7, 1,0)
    pset(posx+obj.x/25+x1/3.25-17, posy+obj.y/25+y1/3.25+7, 11)
   end

   
  end 
 end

 -- draw manualy ally turret
 rectfill(posx+4*2+2, posy1-4*2, posx-1+4*2+2, posy1-1-4*2, 1)
 rectfill(posx+6*2+2, posy1-6*2, posx-1+6*2+2, posy1-1-6*2, 1)
 -- draw manualy ally nexus
 rectfill(posx+2*2+2.5-1, posy1-2*2-1, posx-1+2*2+2.5+2, posy1-1-2*2+2, 1)
 circfill(posx+2*2+2.5, posy1-2*2, 1,12)

 -- draw manualy enemy turret
 rectfill(posx+4*5.25+2, posy1-4*5.25, posx-1+4*5.25+2, posy1-1-4*5.25, 2)
 rectfill(posx+6*2.85+2, posy1-6*2.85, posx-1+6*2.85+2, posy1-1-6*2.85, 2)

 -- draw manualy enemy nexus
 rectfill(posx+13*2+2-1, posy1-13*2-1, posx-1+13*2+2+2, posy1-1-13*2+2, 2)
 circfill(posx+13*2+2, posy1-13*2, 1,8)

 -- draw camera view point
 local cam_x, cam_y = main_camera.x+x0+main_camera.x/30+x1/36, main_camera.y+y0+main_camera.y/28-1+y1/3
 local posx, posy = cam_x, cam_y
 rect(posx, posy,posx+8, posy+8, 7)
end

function update_gameover()
 draw_mouse_cursor()

 if btnp(5) then run() end
 mode='gameover'
end

function start_game()
 init_all_gameobject()
 main_camera = search_gameobject('camera')
 mouse = search_gameobject('mouse')
 ally_nexus = search_gameobject('ally_nexus')
 enemy_nexus = search_gameobject('enemy_nexus')
 mode = 'game'
 spawner_ally = search_gameobject('spawner_ally')
 spawner_enemy = search_gameobject('spawner_enemy')
 p_champ = search_gameobject('ally_champion_garan')
end

-- #init
function init_all_gameobject()
 make_gameobject(46, 65, 'camera', {newposition = {x=0, y=0}, velocity=0, spx=0, spy=0,speed=0.1})
 make_gameobject(0, 32, 'mouse', {sprite=46,newposition = {x=0, y=0}})
 -- ally building
 make_nexus(16, 82, 'ally_nexus', 1000, {x0=8, y0=0, x1=16, y1=16, width=48, height=48, col1=12, col2=1})
 -- nexus towers
 make_turret(16, 32, 5500,'ally_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1},
  {tag='enemy',range=80, attack_speed=3, timer=0})
 make_turret(60, 64, 3800,'ally_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1},
  {tag='enemy',range=80, attack_speed=3, timer=0})

 make_turret(140, -60, 3800,'ally_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1},
  {tag='enemy',range=80, attack_speed=3, timer=0})
 -- make ally inhibitor
 make_turret(120, -30, 3800,'ally_inhibitor', {x0=8, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1},
  {tag='nobody',range=0, attack_speed=1000, timer=0})

 make_turret(240, -155, 3800,'ally_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1},
  {tag='enemy',range=80, attack_speed=3, timer=0})

-- enemy building
 make_nexus(635 , -550, 'enemy_nexus', 1000, {x0=8, y0=0, x1=16, y1=16, width=48, height=48, col1=8, col2=2})
 make_turret(635 , -500, 3800,'enemy_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=8, col2=2},
  {tag='ally',range=80, attack_speed=3, timer=0})
 make_turret(585 , -530, 3800,'enemy_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=8, col2=2},
  {tag='ally',range=80, attack_speed=3, timer=0})

 make_turret(525 , -430, 3800,'enemy_inhibitor', {x0=8, y0=0, x1=16, y1=16, width=32, height=32, col1=8, col2=2},
  {tag='nobody',range=0, attack_speed=1000, timer=0})


 make_turret(500 , -410, 3800,'enemy_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=8, col2=2},
  {tag='ally',range=80, attack_speed=3, timer=0})

 make_turret(400 , -310, 3800,'enemy_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=8, col2=2},
  {tag='ally',range=80, attack_speed=3, timer=0})


 make_gameobject(0, 0, 'spawner_ally', {
  timer=0,
  wave_timer=0,
  t_tag='enemy',
  time_between_spawn=1,
  time_between_wave=60 ,
  alivee=0,
  col1=12, col2=1, x=32, y=60,
  wave_c=0
  })

  make_gameobject(0, 0, 'spawner_enemy', {
  timer=0,
  wave_timer=0,
  t_tag='ally',
  time_between_wave=60 ,
  time_between_spawn=1,
  alivee=0,
  col1=8, col2=2, x=625, y=-540,
  wave_c=0
  })


   make_champion(40, 35, 'ally_champion_garan', 600, 45,
     {class='champion', tag='enemy', target=turret, damage=90, range=15,
      timer=0, attack_speed=1.25}, {hit=3, death=8, level_up=7},{idle={{sx=0, sy=32, sw=16, sh=16},{sx=16, sy=32, sw=16, sh=16}},
       move={{sx=32, sy=32, sw=16, sh=16},{sx=48, sy=32, sw=16, sh=16}},
     attack={{sx=64, sy=32, sw=16, sh=16}, {sx=80, sy=32, sw=16, sh=16}}, col1=12, col2=1, width=16, height=16})

 -- make_nexus(0 , 64, 'enemy_nexus', 1000, {x0=8, y0=0, x1=16, y1=16, width=64, height=64})
 -- make_turret(16, 32, 'enemy_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1}, {tag='ally',range=25, attack_speed=2, timer=0})
 -- make_turret(60, 64, 'enemy_turret', {x0=24, y0=0, x1=16, y1=16, width=32, height=32, col1=12, col2=1}, {tag='ally',range=25, attack_speed=2, timer=0})

end

function manage_player_champion()
   local shortest = 10000
   for obj in all(game_objects) do
    if obj:is_active() then
     local dist = distance(mouse, obj)
     if dist < shortest and (sub(obj:get_tag(), 0,4) == 'ally' or sub(obj:get_tag(), 0,5)  == 'enemy') then
       shortest = dist
       mouse.target = obj
     end
    end
   end
  if sub(mouse.target:get_tag(), 0,5) == 'enemy' and
   distance(mouse, mouse.target) < mouse.target.hit_box then
   mouse.sprite = 47
  else
   mouse.sprite=46
  end
  if is_mouse_right_click_once() and p_champ:is_alive() then 
   sfx(13)
   if mouse.target == nil then return end

   if sub(mouse.target:get_tag(), 0,5) == 'enemy' and distance(mouse, mouse.target) < mouse.target.hit_box then
    -- stop()
    p_champ.attack_info.target = mouse.target
    p_champ.move_point = p_champ.attack_info.target
   else 
    p_champ.move_point = {x=mouse.x, y=mouse.y}
    p_champ.attack_info.target = nil
    
    sprite_part({62}, mouse.x-4, mouse.y-4, 16)
    sprite_part({61}, mouse.x-4, mouse.y-4, 8)
   end
  end 
end
-- #champion
function make_champion(x, y, tag, health, move_speed, atk_info, sounds, sprite)
 local new_unit = make_gameobject(x, y, tag,{
  state='idle',
  sprite=sprite,
  max_health=health,
  current_health=health,
  sounds=sounds,
  money=500,
  level=1,
  max_exp=25,
  current_exp=0,
  move_speed=move_speed,
  move_point=nil,
  attack_info=atk_info,
  take_damage=function(self, damage)
   self.current_health-= damage
   if self.current_health < 0 then self.current_health = 0 end 
   -- shake_camera(1)
   return true
  end,
  is_alive=function(self)
   if self.current_health>self.max_health then self.current_health = self.max_health end
   if self.current_health <= 0 then
     self:kill()
     return false
   else
    return true
   end
  end,
  attack=function (self)
   local target = self:get_target()
   if self.attack_info.target == nil then return end
   if target:is_alive() == false then  self.move_point= nil self.attack_info.target = nil end

   -- self.state='attack'
   if self.attack_info.timer < time() and self:can_attack() and distance(self, self:get_target()) < self.attack_info.range then
    self.state='attack'
    self.attack_info.timer = time() + self.attack_info.attack_speed
    sfx(self.sounds.hit)

    if target.current_health-self.attack_info.damage <= 0 then
     local gold = flr(rnd(15)+15)
     self.money += gold
     show_message('+'..gold..' \x86', target.x, target.y, 10, 9, 5, 2, 'score', true, true)
    end
    shake_camera(1)
    target:take_damage(self.attack_info.damage)
   end
  end,
  get_target=function(self)
   return self.attack_info.target
  end,
  can_attack=function(self)
   if self:get_target() != nil and distance(self, self:get_target()) < 
   self.attack_info.range+self:get_target().hit_box
    then return true
   else return false end
  end,
  kill=function(self)
   sfx(self.sounds.death)
   self.move_point= nil self.attack_info.target = nil
   self.current_health = self.max_health
   main_camera.x, main_camera.y, self.x, self.y = 46, 65, 40, 35

  end,
  draw_button=function (self)
   local posx, posy = main_camera.x+shkx, main_camera.y+shky
    sspr(0, 64, 16, 16,posx-13, posy+34)
    sspr(32, 64, 16, 16,posx-29, posy+34)
    sspr(48, 64, 16, 16,posx+3, posy+34)
    -- spe_print('coming soon !',posx-30, posy+30, 8, 2)


   -- rectfill(posx, posy, posx+12, posy+12, 0)
  end,
  -- spells=function (self)
  --   -- if btnp(4) then
  --   -- end
  -- end,
  center=function(self, pos)
   if pos == 'x' then return self.x+self.sprite.width/2
   else return self.y+self.sprite.width/2 end
  end,
  draw_shadow=function(self)
    local is_flip_x, atk_offset = false, -4
    if self:get_target() != nil and self.x < self:get_target().x then is_flip_x = true
      atk_offset=4 end
    if self.state == 'move' then
     local n = flr(time()*self.move_speed/6 % #self.sprite.move)+1
     change_all_pal(2)
     outline_sspr(self.sprite.move[n].sx, self.sprite.move[n].sy, self.sprite.move[n].sw,
      self.sprite.move[n].sh, self.x+shkx, self.y+shky+self.sprite.height, self.sprite.width, self.sprite.height, is_flip_x, true, 2)
     pal()
    elseif self.state == 'attack' then
    local n = flr(time()*self.attack_info.attack_speed % #self.sprite.attack)+1
    if n == 2 then atk_offset = 0 end
    change_all_pal(2)
    outline_sspr(self.sprite.attack[n].sx, self.sprite.attack[n].sy, self.sprite.attack[n].sw,
     self.sprite.attack[n].sh, self.x+atk_offset+shkx, self.y+shky+self.sprite.height, self.sprite.width, self.sprite.height, is_flip_x, true, 2)
    pal()
    elseif self.state=='idle' then
    local n = flr(time()*self.move_speed/12 % #self.sprite.idle)+1
    change_all_pal(2)
    outline_sspr(self.sprite.idle[n].sx, self.sprite.idle[n].sy, self.sprite.idle[n].sw,
     self.sprite.idle[n].sh, self.x+shkx, self.y+shky+self.sprite.height, self.sprite.width, self.sprite.height, is_flip_x, true, 2)
    pal()

    end
  end,
  draw_sprite=function(self)
    local is_flip_x = false

    if self.state == 'idle' then
    local n = flr(time()*self.move_speed/12 % #self.sprite.idle)+1
    outline_sspr(self.sprite.idle[n].sx, self.sprite.idle[n].sy, self.sprite.idle[n].sw,
    self.sprite.idle[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)

    pal(12, self.sprite.col1)
    pal(1, self.sprite.col2)
    sspr(self.sprite.idle[n].sx, self.sprite.idle[n].sy, self.sprite.idle[n].sw,
     self.sprite.idle[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)
    pal()

    elseif self.state == 'move' then
     if self.move_point != nil and self.x > self.move_point.x then is_flip_x = true end

    local n = flr(time()*self.move_speed/12 % #self.sprite.move)+1
    outline_sspr(self.sprite.move[n].sx, self.sprite.move[n].sy, self.sprite.move[n].sw,
    self.sprite.move[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)

    pal(12, self.sprite.col1)
    pal(1, self.sprite.col2)
    sspr(self.sprite.move[n].sx, self.sprite.move[n].sy, self.sprite.move[n].sw,
     self.sprite.move[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)
    pal()
    elseif self.state=='attack' then
    if self:get_target() != nil and self.x > self:get_target().x then is_flip_x = true end

    local n = flr(time()*self.attack_info.attack_speed % #self.sprite.attack)+1
    outline_sspr(self.sprite.attack[n].sx, self.sprite.attack[n].sy, self.sprite.attack[n].sw,
    self.sprite.attack[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)

    pal(12, self.sprite.col1)
    pal(1, self.sprite.col2)
    sspr(self.sprite.attack[n].sx, self.sprite.attack[n].sy, self.sprite.attack[n].sw,
     self.sprite.attack[n].sh, self.x+shkx, self.y+shky, self.sprite.width,
      self.sprite.height, is_flip_x, false)
    pal() 

    end
  end,
  level_up=function (self)
   if btnp(0) or self.current_exp >= self.max_exp then self.level += 1 self.current_exp=0 self.max_exp*=1.5
    self.max_health *= 1.5 self.current_health *= 1.5 self.attack_info.damage += 10
    hit_part(self:center('x')-10,self:center(' y'),{10, 12, 1})
    hit_part(self:center('x')+10,self:center(' y'),{10, 12, 1})
    whiteframe = true
    shake_camera(11)
    sfx(self.sounds.level_up)

   end
  end,
  show_health=function(self)
   spe_rect(self.x+shkx,self.y+shky-7, self.x+shkx+16,self.y+shky-4, self.current_health/self.max_health, 5, 11, 0)

  end,
  show_level=function(self)
  -- function spe_rect(x0,y0,x1,y1, pc, back_col, font_col, bordercol)

   spe_rect(self.x+shkx-10,self.y+shky-10, self.x+shkx-3,self.y+shky-2, 1, 4, 4, 0)
   print(self.level, self.x+shkx-7,self.y+shky-7, 9)
   print(self.level, self.x+shkx-7,self.y+shky-8, 10)
   -- spe_print(self.level, self.x+shkx-8,self.y+shky-9, 10, 9)

  end,
  show_screen_ui=function (self)
   local posx, posy = main_camera.x+shkx, main_camera.y+shky
   self:draw_button()
   spe_rect(posx-28,posy+52, posx+18,
    posy+5+53, self.current_health/self.max_health, 5, 11, 0)
    spe_rect(posx-28,posy+60, posx+18,
    posy+1+60, self.current_exp/self.max_exp, 5, 12, 0)

    print(flr(self.current_health)..'/'..flr(self.max_health), posx-18, posy+53, 7)
    
    spe_print(self.money..' \x86', posx-57, posy+55, 10, 9)

  end,
  show_target=function(self)
   if self:get_target() != nil then outline_spr(31, self:get_target().x, self:get_target().y-12,false, false, 7) 
   spr(31, self:get_target().x, self:get_target().y-12) end
  end,
  passiv_heal=function(self) 
   self.current_health+= time()/1200%1
  end,
  show_ui=function(self)
   self:show_level()
   self:show_health()
   self:show_screen_ui()
   self:show_target()
  end,
  brain_work=function(self)
   if self:get_target() != nil and distance(self, self:get_target()) < self.attack_info.range then
    self.state='attack'
   elseif self.move_point != nil and distance(self, self.move_point) > 5 then 
    self.state = 'move'
    move_toward(self, self.move_point, self.move_speed)
    if distance(self,self.move_point) < 5 then self.move_point = nil end
   elseif self:get_target() == nil and self.move_point == nil then
    self.state ='idle'
   end
  end, 
  draw=function(self)
   self:draw_shadow()
   self:draw_sprite()
  end,
  update=function(self)
   self:attack()
   self:brain_work()
   self:level_up()
   self:is_alive()
   self:passiv_heal()
   -- self:spells()
  end
  })
  
  add(allies, new_unit) 
end

-- ##unit
function make_unit(x, y, tag, health, move_speed, atk_info, sounds, sprite)
 local new_unit = make_gameobject(x, y, tag,{
  sprite=sprite,
  max_health=health,
  current_health=health,
  sounds=sounds,
  move_speed=move_speed,
  attack_info=atk_info,
  take_damage=function(self, damage)
   self.current_health-= damage
   -- shake_camera(1)
   return true
  end,
  find_target=function(self)
   local shortest = 10000
   local tab = enemies
   if self.attack_info.tag == 'ally' then tab = allies end 
   for obj in all(tab) do
    if obj:is_active() and obj:is_alive() then
     local dist = distance(self, obj)
     if dist < shortest then
       shortest = dist
       self.attack_info.target = obj
       self.move_point = obj
     end
    end
   end
   for obj in all(building) do
    if obj:is_active() and sub(obj:get_tag(),1,#self.attack_info.tag)  == self.attack_info.tag then
     local dist = distance(self, obj)
     if dist < shortest then
       shortest = dist
       self.attack_info.target = obj
     end
    end
   end
  end,
  kill=function(self)
    self.current_health = 0
    if self.attack_info.tag == 'enemy' then del(allies, self) spawner_ally.alivee -= 1 else spawner_enemy.alivee -= 1 del(enemies, self) end 
    -- blood_part(self:center('x'), self:center('y')+16, 1, {8})
    -- if self.attack_info.tag == 'enemy' then side = -1 end

     -- blood_explosion(self:center('x'), self:center('y'), 50, side, {8})
-- blood_explosion(x, y, quantity, direction, colarr)
     if self.attack_info.tag == 'ally' and distance(self, p_champ) < 40 then
      local points = self.max_health/50
      -- show_message('+'..points..'$', self:get_target().x, self:get_target().y, 11, 3, 5, 2, 'score', true, true)
      p_champ.current_exp+= points
      -- sprite_part(sprite, speed, x, y, mage)
     end
     sfx(self.sounds.death +flr(rnd(2)))
     -- shake_camera(0.5)
    hit_part(self.x, self.y, {8})

     sprite_part({15}, self.x, self.y, 250)
     self.x, self.y = 130, 130
     self:disable()
  end,
  is_alive=function(self)
   if self.current_health <= 0 then
     return false
   else
    return true
   end
  end,
  get_target=function(self)
   return self.attack_info.target
  end,
  can_attack=function(self)
   if self:get_target() != nil and distance(self, self:get_target()) < self.attack_info.range+self:get_target().hit_box
    then return true
   else return false end
  end,
  move=function(self)
   if self:can_attack() == false then
    move_toward(self, self:get_target(), self.move_speed)
   end
  end,
  move_away_from_ally=function(self)
   local tab = enemies
   if self.attack_info.tag == 'enemy' then tab = allies end 
   for obj in all(tab) do
    if obj:is_active() then
     local dist = distance(self, obj)
     if dist < 10 then
        move_toward(self, obj, -(self.move_speed))
        -- move_toward(obj, self, -(self.move_speed/2))
     end
    end
   end
  end,
  attack=function(self)
   if self.attack_info.timer < time() and self:can_attack() then
     
    self.attack_info.timer = time() + self.attack_info.attack_speed
    if self.attack_info.class == 'melee' then
     sfx(self.sounds.hit)
     self:get_target():take_damage(self.attack_info.damage)
    elseif self.attack_info.class =='distance' then
     sfx(self.sounds.hit)

     local atk_offset = -10
     if self.x < self:get_target().x then atk_offset=10 end

     if  self.attack_info.effect != nil and self.attack_info.effect.state == true then 
      hit_part(self.x+atk_offset/2,self.y+12,{11, 3})
     end

     local bullet = make_bullet(self:center('x'), self:center('y'), self.attack_info.bullet_info.damage, self.attack_info.bullet_info.backoff, 
      self.attack_info.bullet_info.move_speed, self.attack_info.bullet_info.sprite, self.attack_info.target, self.attack_info.bullet_info.tag)
     if bullet != nil then
      bullet:set_target(self:get_target())
     end
    end
   end
  end,
  reset=function(self)
   self.current_health = self.max_health
   self:enable()
  end,
  show_health=function(self)
   local col1 = 11 col2 = 1 if self.attack_info.tag == 'ally' then col1= 8 col2 = 2 end
    -- rectfill(self.x+shkx,self.y+shky-2, self.x+shkx+8,self.y+shky-2,5)
    -- rectfill(self.x+shkx,self.y+shky-2, self.x+shkx + (self.x+shkx+8 - self.x+shkx)*self.current_health/self.max_health,
    --  self.y+shky-2,col)

   spe_rect(self.x+shkx,self.y+shky-2, self.x+shkx+8,self.y+shky-2, self.current_health/self.max_health, 5, col1, col2)
  end,
  show_target=function(self)
   if self:get_target() == nil then return end
   line(self:center('x'),self:center('y'),self:get_target().x,self:get_target().y,12)
  end,
  draw_shadow=function(self)
    local is_flip_x, atk_offset = false, -4
    if self:get_target() != nil and self.x < self:get_target().x then is_flip_x = true
      atk_offset=4 end
    if self:can_attack() == false then
     local n = flr(time()*self.move_speed/6 % #self.sprite.move)+1
     change_all_pal(2)
     outline_sspr(self.sprite.move[n].sx, self.sprite.move[n].sy, self.sprite.move[n].sw,
      self.sprite.move[n].sh, self.x+shkx, self.y+shky+self.sprite.height, self.sprite.width, self.sprite.height, is_flip_x, true, 2)
     pal()
    else
    local n = flr(time()/(self.attack_info.attack_speed/2) % #self.sprite.attack)+1
    if n == 2 then atk_offset = 0 end
    change_all_pal(2)
    outline_sspr(self.sprite.attack[n].sx, self.sprite.attack[n].sy, self.sprite.attack[n].sw,
     self.sprite.attack[n].sh, self.x+atk_offset+shkx, self.y+shky+self.sprite.height, self.sprite.width, self.sprite.height, is_flip_x, true, 2)
    pal()

    end
  end,
  draw_sprite=function(self)
    local is_flip_x, atk_offset = false, -4

    if self:get_target() != nil and self.x < self:get_target().x then is_flip_x = true
      atk_offset=4 end


   if self:can_attack() == false then

    local n = flr(time()*self.move_speed/6 % #self.sprite.move)+1

    outline_sspr(self.sprite.move[n].sx, self.sprite.move[n].sy, self.sprite.move[n].sw,
    self.sprite.move[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)

    pal(12, self.sprite.col1)
    pal(1, self.sprite.col2)
    sspr(self.sprite.move[n].sx, self.sprite.move[n].sy, self.sprite.move[n].sw,
     self.sprite.move[n].sh, self.x+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)
    pal()
   else
    local n = flr(time()/(self.attack_info.attack_speed/2) % #self.sprite.attack)+1
    if n == 2 then atk_offset = 0 end


    outline_sspr(self.sprite.attack[n].sx, self.sprite.attack[n].sy, self.sprite.attack[n].sw,
     self.sprite.attack[n].sh, self.x+atk_offset+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)
     pal(12, self.sprite.col1)
    pal(1, self.sprite.col2)
    sspr(self.sprite.attack[n].sx, self.sprite.attack[n].sy, self.sprite.attack[n].sw,
     self.sprite.attack[n].sh, self.x+atk_offset+shkx, self.y+shky, self.sprite.width, self.sprite.height, is_flip_x, false)
    pal()
   end

  end,
  show_ui=function(self)
   self:show_health()
  end,
  update=function(self)
   if self:is_alive() == false then self:kill() end
   if self:get_target()== nil or self:can_attack() == false or 
   self:get_target():is_alive() == false then  self:find_target() end
   
   self:move()
   self:attack()
   self:move_away_from_ally()
  end,
  draw=function(self)
   self:draw_sprite()
  end
  })
  
  if atk_info.tag == 'enemy' then add(allies, new_unit) spawner_ally.alivee += 1 else add(enemies, new_unit) spawner_enemy.alivee+=1 end
end

function sortbyy(a)
   for i=1,#a do
       local j = i
       while j > 1 and a[j-1].y > a[j].y do
           a[j],a[j-1] = a[j-1],a[j]
           j = j - 1
       end
   end
end

function victory_gameover_check()
mode='victory'
 if ally_nexus:is_alive() == false then mode='gameover'
 elseif enemy_nexus:is_alive()==false then mode='victory'

 end

end

function draw_mouse_cursor()

 local posx, posy= main_camera.x-mouse.x, main_camera.y-mouse.y
 mouse.x = stat(32) +main_camera.x-64
 mouse.y = stat(33) + main_camera.y-64

 spr(mouse.sprite, mouse.x, mouse.y)

 -- print(main_camera.x-mouse.x, mouse.x, mouse.y-5, 0)
end

function camera_follow()
 local _player, cam, shx, shy, camx, camy, posx, posy, camvelo = mouse, main_camera, 0,
  0, main_camera.x, main_camera.y, main_camera.x-mouse.x, main_camera.y-mouse.y, main_camera.velocity

 -- local cam = main_camera
 -- local shx, shy= 0, 0

 -- local posx= main_camera.x-mouse.x
 -- local posy= main_camera.y-mouse.y

 if posx < -50 or btn(1) then 
  main_camera.x += main_camera.velocity
  if camvelo < 4 then
   main_camera.velocity += main_camera.speed
  end
 elseif posx > 50 or btn(0) then
  main_camera.x -= main_camera.velocity
  if camvelo < 4 then
   main_camera.velocity += main_camera.speed
  end
 else
  if (posy > -50 ) and(posy < 50 ) then
   main_camera.velocity = 0.5
  end
 end
 
 if posy < -50 or btn(3) then 
  main_camera.y +=  main_camera.velocity
  if camvelo < 4 then
   main_camera.velocity += main_camera.speed
  end
 elseif posy > 50 or btn(2) then
  main_camera.y -= main_camera.velocity
  if camvelo < 4 then
   main_camera.velocity += main_camera.speed
  end
 else
  if (posx > -50 ) and (posx < 50 ) then
   main_camera.velocity = 0.5
  end
 end
 if camx > 600 then main_camera.x = 600 end
 if camx < 32 then main_camera.x = 32 end
 if camy > 64 then main_camera.y = 64 end
 if camy < -520 then main_camera.y = -520 end

 if btn(4) then
 --  local sp = 300
 --  if distance(main_camera, p_champ) < 20 then sp=55 end 
  move_toward(main_camera, p_champ, 350)
 end

 camera(cam.x-64 ,cam.y-64)
end

-- ##turret
function make_turret(x, y, health, tag, sprite, attack_info)
 local new_turret=  make_gameobject(x, y, tag, {
  sprite=sprite,
  attack_info=attack_info,
  max_health=health,
  current_health=health,
  hit_box=sprite.width/2.5,
  bullet_info={damage=100, sprite=45, move_speed=150, backoff=100, tag='bullet'},
  show_health=function(self)
   local x, y = -16, -16
   -- local in_col,out_col, rate = 11, 3, self.current_health/self.max_health
   -- if rate >= 0.75 then in_col = 11 out_col =3  elseif rate >= 0.5 then in_col = 10 out_col = 9 elseif rate>= 0.25 then in_col = 9 out_col = 4 else in_col = 8 out_col = 2 end
   -- spe_print(self.current_health,self.x+4, self.y-10, in_col, out_col)
   spe_rect(x+self.x+12+shkx,y+self.y-3+shky, x+self.x+28+shkx,y+self.y-2+shky, self.current_health/self.max_health, 8, 11, 0)

  end,
  take_damage=function(self, damage)
   self.current_health-= damage
   -- shake_camera(1)
   return true
  end,
  center=function(self, pos)
   if pos == 'x' then return self.x-self.sprite.width/3.5
   else return self.y-self.sprite.width/2 end
  end,
  find_target=function(self)
   local shortest = 10000
   if self:get_target() != nil and (distance(self, self:get_target()) > self.attack_info.range
   or self:get_target():is_alive() == false)
    then self.attack_info.target = nil end

   local champ = nil
   -- local c =0
   if self.attack_info.tag =='ally' and distance(self,p_champ) < self.attack_info.range 
   then champ = p_champ end

   for obj in all(game_objects) do
    if sub(obj:get_tag(),1,#self.attack_info.tag)  == self.attack_info.tag and obj:is_active() 
    and obj:is_alive() then
     local dist = distance(self, obj)
     -- if dist < self.attack_info.range then 
     --  c+=1
     -- end
     if dist < shortest then
      shortest = dist
      if shortest < self.attack_info.range then 
       if sub(obj:get_tag(), 0, #'ally_champion') != 'ally_champion' then
        self.attack_info.target = obj 
       end
      end
     end
    end
   end

   if self:get_target()==nil  then self.attack_info.target = champ end
  end,
  is_alive=function (self)
   if self.current_health <= 0 then
    self:disable()
    return false
   else
    return true
   end
  end,
  can_attack=function(self)
   if self:get_target() != nil and distance(self, self:get_target()) < self.attack_info.range and time() >= self.attack_info.timer then return true
   else return false end
  end,
  get_target=function(self)
   return self.attack_info.target
  end,
  attack=function(self)
   if self:can_attack()==false then return end

   if self.attack_info.timer < time() and self:get_target() != nil and
    distance(self, self:get_target()) < self.attack_info.range then
    -- shake_h(2)
    -- smoke_part_custom(self:center('x')+8, self:center(' y'), rnd(10)+5, rnd(100)+100, 0.,{7, 6, 5}) -- orange and brown circle.
    -- circ_part(self.x+16, self.y+25, rnd(3)+3, 5, {7})
    sfx(flr(rnd(2)+1))

    
    local bullet = make_bullet(self:center('x'), self:center('y'), self.bullet_info.damage, self.bullet_info.backoff, 
     self.bullet_info.move_speed, self.bullet_info.sprite, self.attack_info.target, self.bullet_info.tag)
    if bullet != nil then
     bullet:set_target(self:get_target())
    
    end
    self.attack_info.timer = time() + self.attack_info.attack_speed
   end
  end,
  show_ui=function(self)
   self:show_health()
   self:show_target()
  end,
  -- draw_shadow=function (self)
  --  local x, y= self:center('x'), self:center('y')
  --  change_all_pal(2)
  --  sspr(self.sprite.x0, self.sprite.y0+8, self.sprite.x1, self.sprite.y1/2+1, x+shkx, y+shky+self.sprite.height/2, self.sprite.width, self.sprite.height, false, false) 
  --  outline_sspr(self.sprite.x0, self.sprite.y0+8, self.sprite.x1, self.sprite.y1/2+1, x+shkx, y+shky+self.sprite.height/2, self.sprite.width, self.sprite.height, false, false,2) 
  --  pal()
  -- end,
  draw_sprite=function(self)
   local x, y= self:center('x'), self:center('y')

   -- outline_sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky, self.sprite.width, self.sprite.height)
   pal(12, self.sprite.col1)
   pal(1, self.sprite.col2)
   sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky, self.sprite.width, self.sprite.height)
   pal()
  end,
  show_range=function(self)
   circ(self.x+self.sprite.width/2, self.y+self.sprite.width/2,self.attack_info.range, 8)
  end,
  show_target=function(self)
   if self:get_target() == nil then return end

   spe_circ(self:get_target():center('x'), self:get_target():center('y'), 8, 0, 8)
   -- circ(self:get_target():center('x'), self:get_target():center('y'), 6, 8)
   -- spe_print(self:get_target().tag, self.x, self.y-16, 11, 3)
   line(self.x, self.y, self:get_target():center('x'),self:get_target():center('y'), 8)

  end,
  draw=function(self)
   self:draw_sprite()
   -- self:show_range()
   -- circ(self:center('x'), self:center('y'), self.hit_box, 9)
   -- if self:get_target() == nil then return end
   -- self:show_target()
  end,
  update=function(self)
   self:is_alive()
   self:find_target()
   self:attack()
  end

  })
 add(building, new_turret)
 return new_turret

end


-- ##random_enemy_spawning
function random_enemy_spawning(spawner)
 if(spawner == nil) then return end
 
 if spawner.wave_timer <= time() and spawner.alivee < 60 then
   -- spawn melee minions.
   if spawner.timer <= time() then
    spawner.timer = time() + spawner.time_between_spawn

    if spawner.wave_c < 1 then
     make_unit(spawner.x+rnd(5)-rnd(5), spawner.y+rnd(5)-rnd(5), sub(spawner:get_tag(),9, #spawner:get_tag())..'_unit1', 445/2, 30,
     {class='melee', tag=spawner.t_tag, target=turret, damage=12, range=2+rnd(4),
      timer=0, attack_speed=1.25}, {hit=4, death=5},{move={{sx=56, sy=0, sw=8, sh=8},{sx=64, sy=0, sw=8, sh=8}},
     attack={{sx=72, sy=0, sw=8, sh=8}, {sx=80, sy=0, sw=8, sh=8}}, col1=spawner.col1, col2=spawner.col2, width=8, height=8})

    elseif spawner.wave_c < 2 then
     make_unit(spawner.x+rnd(5)-rnd(5), spawner.y+rnd(5)-rnd(5), sub(spawner:get_tag(),9, #spawner:get_tag())..'_unit2', 280/2, 30,
     {class='distance', bullet_info={damage=25, sprite=44, move_speed=150, backoff=0, tag='bullet_mage'}, tag=spawner.t_tag, 
     target=turret, damage=25, range= 40+rnd(20),
      timer=0, attack_speed=2}, {hit=4, death=5},{move={{sx=88, sy=0, sw=8, sh=8},{sx=96, sy=0, sw=8, sh=8}},
     attack={{sx=104, sy=0, sw=8, sh=8}, {sx=112, sy=0, sw=8, sh=8}}, col1=spawner.col1, col2=spawner.col2, width=8, height=8})

    end

    spawner.wave_c += 1/2.5
   end
   if spawner.wave_c >= 2 then 
    spawner.wave_timer = spawner.time_between_wave  + time()
    spawner.wave_c = 0 
   end
 
 end
end


-- #bullet
function make_bullet(x, y, damage, backoff, move_speed, sprite, target, tag)
 return make_gameobject (x, y, tag, {
  damage=damage,
  move_speed=move_speed,
  sprite=sprite,
  target=target,
  direction={x=target.x, y=target.y},
  update=function(self)
   if self.target:is_active() == false then self:disable() end
   -- self.move_speed *= 0.98
   self:move_follow()
   if(distance(self, self.target) <= 10 and self.target:is_active() == true and self.target:is_alive()) then
    -- backoff the target
    -- move_toward(self.target, self, -backoff)

    self.target:take_damage(damage)

    self:explode()
    self:disable()
   elseif self.target:is_active() == false then
    self:disable()
   end
  end,
  explode=function(self)
    -- smoke_part_custom(self:center('x'),self:center(' y'), rnd(10)+5, rnd(100)+100, 0.5,{7, 6, 5, 5, 5}) -- orange and brown circle.
    hit_part(self:center('x'),self:center(' y'),{7, 6, 5})
    -- smoke_part_custom(self:center('x'),self:center('y'), rnd(15)+9, 20, 3,{2, 9, 15}) -- purple circle
     if self.target:get_tag()!='player' then sfx(0) end
  end,
  set_target=function(self, target)
   self.target = target
   self.direction={x=target.x, y=target.y}
  end,
  move_follow=function(self)
    move_toward(self, self.target, self.move_speed)
  end,

  move_straight=function(self)
   move_toward(self, {x=self.direction.x, y=self.direction.y}, self.move_speed)
   if(distance(self, self.target) >= 120) then self:explode() self:disable() end
  end,
  draw=function(self)
    if time()*6%2 >= 1 then
     pal(9, 2)
    end
    outline_spr(self.sprite, self:center('x')+shkx, self:center('y')+shky)
    spr(self.sprite, self:center('x')+shkx, self:center('y')+shky)
    pal()
  end,
  reset=function(self)
   self:enable()
   
  end
  })
end


-- make a nexus
-- #nexus
function make_nexus(x, y, tag, health, sprite)

 local new_nexus = make_gameobject(x, y, tag,{
  current_health=health,
  max_health=health,
  sprite=sprite,
  hit_box=sprite.width/2,
  show_health=function(self)
   local x, y = -32, -32
   spe_rect(x+self.x+shkx+15,y+self.y+shky+10,x+ self.x+shkx+48,y+self.y+shky+12, self.current_health/self.max_health, 5, 11, 0)
  end,
  center=function(self, pos)
   if pos == 'x' then return self.x-self.sprite.width/2
   else return self.y-self.sprite.width/2 end
  end,
  is_alive=function (self)
   if self.current_health <= 0 then
    self:disable()
    return false
   else
    return true
   end
  end,
  take_damage=function(self, damage)
   whiteframe=true
   self.current_health-= damage
   shake_camera(1)
   return true
  end,
  show_ui=function(self)
    self:show_health()
  end,
  -- draw_shadow=function(self)
  --  local x, y= self:center('x'), self:center('y')

  --  -- draw shadow
  --  change_all_pal(2)
  --  sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky+self.sprite.height/3, self.sprite.width, self.sprite.height, false, true) 
  --  outline_sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky+self.sprite.height/3, self.sprite.width, self.sprite.height, false, true,2) 

  --  pal()
  -- end,
  draw_sprite=function(self)
   local x, y= self:center('x'), self:center('y')


   -- outline_sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky, self.sprite.width, self.sprite.height) 
   pal(12, self.sprite.col1)
   pal(1, self.sprite.col2)
   sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky, self.sprite.width, self.sprite.height) 
   pal()
  end,
  draw=function(self)
   self:draw_sprite()

   -- sspr(self.sprite.x0, self.sprite.y0, self.sprite.x1, self.sprite.y1, x+shkx, y+shky, self.sprite.width, self.sprite.height) 

  end,
  update=function(self)
   self:is_alive()
  end
  })

 add(building, new_nexus) 
-- return new_nexus
end



-- ##make_gameobject
function make_gameobject(x, y, tag, properties)

 for obj in all(game_objects) do
  if obj:get_tag() == tag and obj:is_active() == false then
   obj:set_value(x, y, tag)
   obj:reset()
   return obj
  end
 end 

 local obj = {
  x=x,
  y=y,
  tag=tag,
  hit_box=10,
  active=true,
  enable=function(self)
   self.active=true
  end,
  draw_shadow=function(self)
  end,
  set_value=function(self, x, y, tag)
   self.x=x
   self.y=y
   self.tag=tag
  end,
  disable=function(self)
   self.active =false
  end,
  show_ui=function(self)
  end,
  get_tag=function(self)
   return self.tag
  end,
  is_active=function(self)
   return self.active
  end,
  reset=function(self)
   self:enable()
  end,
  center=function(self, value)
   if value == 'x' then return self.x+4
   else return self.y + 4
   end
  end,
  update=function()
  end,
  draw=function()
  end
 }
 if properties != nil then
    for k, v in pairs(properties) do
     obj[k] = v
    end
 end

 add(game_objects, obj)
 return obj
end


function update_all_gameobject()

-- draw all except nexus and tower
 for obj in all(game_objects) do
  if obj:is_active() then obj:update() end
 end
end

function is_in_camera_vision(obj)

 if obj.x < main_camera.x+70 and obj.x > main_camera.x-70 and obj.y < main_camera.y+70 and obj.y > main_camera.y-70 then return true
 else return false end
end
-- ##draw all
function draw_all_gameobject()
 -- qsort(enemies, ascending)
 -- sort_array(game_objects)

 sortbyy(enemies)
 sortbyy(allies)
 -- sortbyy(enemies)

 for obj in all(game_objects) do
   if obj:is_active() and is_in_camera_vision(obj)  then obj:draw_shadow() end
 end
 for obj in all(game_objects) do
   if obj:is_active() and is_in_camera_vision(obj) then obj:draw() end
 end


 --  for obj in all(enemies) do
 --  if obj:is_active() and is_in_camera_vision(obj) then obj:draw() end
 -- end
 -- for obj in all(allies) do
 --  if obj:is_active() and is_in_camera_vision(obj) then obj:draw() end
 -- end



 for obj in all(building) do
  if obj:is_active() and is_in_camera_vision(obj) then obj:draw() end
 end
 for obj in all(game_objects) do
  if obj:is_active() and is_in_camera_vision(obj) and (obj:get_tag()=='enemy_tower' or
   obj:get_tag() == 'ally_turret') then obj:draw()
  end
 end

 -- for obj in all(game_objects) do
 --  if obj:is_active() and (sub(obj:get_tag(), 1, 6)) == 'button' then
 --   obj:draw() 
 --  end
 -- end

 for obj in all(game_objects) do
  if obj:is_active() then
   obj:show_ui() 
  end
 end
end

-- draw a rect with a border color, a bg color and a fill color.
-- pc = pourcentage to fill
function spe_rect(x0,y0,x1,y1, pc, back_col, font_col, bordercol)
 local length = x1 - x0
 rectfill(x0-1,y0-1,x1+1,y1+1,bordercol)
 rectfill(x0,y0,x1,y1,back_col)
 if pc > 0.001 then
  rectfill(x0,y0, x0 + length*pc,y1,font_col)
 end
end

-- ##others
function whiteframe_update()
 if whiteframe == true then
  local posx, posy= main_camera.x-64, main_camera.y-64
  rectfill(posx,posy, posx+128, posy+128, 7)
  whiteframe = false
 end
end

function is_mouse_left_click_once()
 left_click_once_timer+=1
 if(stat(34) == 1) then left_click_once_timer =0 end
 if(left_click_once_timer <= 1 and left_click_once_timer > 0) then return true else return false end
end
function is_mouse_right_click_once()
 right_click_once_timer+=1
 if(stat(34) == 2) then right_click_once_timer =0 end
 if(right_click_once_timer <= 1 and right_click_once_timer > 0) then return true else return false end
end
-- ##part

function draw_part()

 for p in all(part) do
  if p.tpe==1 then
   circfill(p.x+shkx,p.y+shky,p.size, p.col)
   p.size -= 0.1
   -- go through  the colarr to draw each sprite
  elseif p.tpe==2  then
   spr(p.colarr[1], p.x, p.y)
  end
 end
end
function add_part(x, y ,tpe, size, mage, dx, dy, colarr)
 for obj in all(game_objects) do
  if(obj:is_active() == false and obj:get_tag() == tag) then
   obj:set_value(x,y,tag)
   obj:reset()
   return obj
  end
 end
 local p = {
  x=x,
  y=y,
  tpe=tpe,
  dx=dx,
  dy=dy,
  move_speed=0,
  size=size,
  age=0,
  mage=mage,
  col=1,
  colarr=colarr,
  active=true,
  layer=0

 }

 add(part, p)
 return p
end
function update_part()
 for p in all(part) do
  p.age+=1
  if p.mage != 0 and p.age >= p.mage or (p.size <= 0 and p.mage!=0) then
   del(part, p)
  end
  
  -- if p.colarr == nil then return end
  if #p.colarr == 1 then
   p.col=p.colarr[1]
  else
   local ci=p.age/p.mage
   ci=1+flr(ci*#p.colarr)
   p.col=p.colarr[ci]
  end
  p.x+=p.dx
  p.y+=p.dy
 end
end

-- draw sprite for a time, put the array sprite in the colarr
function sprite_part(sprite, x, y, mage)
   local p = add_part(x, y, 2, 1, mage, 0, 0, sprite)
end

function hit_part(x,y,colarr)
  for i=0, rnd(6)+4 do
  local p = add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 1, rnd(4)+3, rnd(5)+35, (rnd(10)-rnd(10))/30, (rnd(10)-rnd(10))/30, colarr)
 end
end
function change_all_pal(col)
 for i=0, 15 do
  pal(i, col)
 end
end

-- function blood_explosion(x, y, quantity, direction, colarr)
--   for i=0, quantity do
--   add_part(rnd(2)-rnd(2)+x, rnd(2)-rnd(2)+y, 13, flr(rnd(3)+1), 50, ((rnd(4)+1)*direction)/2, -rnd(1.5), colarr)
--   -- add_part(x, y ,tpe, size, mage, dx, dy, colarr)
--  end
-- end

function outline_spr(n, x, y, _flip_x, _flip_y, col)
 local out_col = 0
 if col != nil then out_col = col end
 local flip_x, flip_y = false, false
 if _flip_x != nil then flip_x = _flip_x end
 if _flip_y != nil then flip_y = _flip_y end

 for i=0, 15 do pal(i, out_col) end
 spr(n, x+1, y, 1, 1, flip_x, flip_y)
 spr(n, x-1, y, 1, 1, flip_x, flip_y)
 spr(n, x, y+1, 1, 1, flip_x, flip_y)
 spr(n, x, y-1, 1, 1, flip_x, flip_y)
 pal()
end
function outline_sspr(sx,sy,sw,sh,dx,dy, dw, dh, flip_x, flip_y, outline_col)
 local out_col = 0
 if outline_col != nil then out_col=outline_col end
 for i=0, 15 do pal(i, out_col) end
 sspr(sx,sy,sw,sh,dx+1,dy, dw, dh, flip_x, flip_y)
 sspr(sx,sy,sw,sh,dx-1,dy, dw, dh, flip_x, flip_y)
 sspr(sx,sy,sw,sh,dx,dy+1, dw, dh, flip_x, flip_y)
 sspr(sx,sy,sw,sh,dx,dy-1, dw, dh, flip_x, flip_y)
 pal()
end
-- the y axis has a default value, 
function distance(current, target)
 if current == nil or target == nil then return nil end
 local x0, y0, x1, y1 = current.x/100, current.y/100, target.x/100, target.y/100
 return sqrt((x1 - x0)^2+(y1 - y0)^2)*100
end

function move_toward(current, target, move_speed)
 if(move_speed == 0) then move_speed = 1 end
 
 local dist= distance(current, target)
 if dist < 1 then return end
 local direction_x, direction_y = (target.x - current.x) / 60 * move_speed, (target.y - current.y) / 60 * move_speed
 
 if dist < 1 then dist = 0.25 end
 current.x += direction_x / dist
 current.y += direction_y / dist
 return current.x, current.y
end

function search_gameobject(tag)
 for obj in all(game_objects) do
  if obj:get_tag() == tag then return obj end
 end
 return nil
end

-- ##spe_print
function spe_print(text, x, y, col_in, col_out, bordercol)
 local outlinecol = 0
 if bordercol != nil then outlinecol = bordercol end
 -- draw outline color.
 local posx, posy = x+shkx, y+shky
 print(text, posx-1, posy, outlinecol)
 print(text, posx+1, posy, outlinecol)
 print(text, posx+1, posy-1, outlinecol)
 print(text, posx-1, posy-1, outlinecol)
 print(text, posx, posy-1, outlinecol)
 print(text, posx+1, posy+1, outlinecol)
 print(text, posx-1, posy+1, outlinecol)
 print(text, posx+1, posy+2, outlinecol)
 print(text, posx-1, posy+2, outlinecol)
 print(text, posx, posy+2, outlinecol)
-- draw col_out.
 print(text, posx,posy+1, col_out)
 -- draw text.
 print(text, posx, posy, col_in)
end


function shake_camera(power)
 local shka=rnd(1)
 shkx+=power*cos(shka)
 shky+=power*sin(shka)
end
function shake_h(power)
 local shka=rnd(1)
 shkx+=power*cos(shka)
end
function shake_v(power)
 local shka=rnd(1)
 shky+=power*sin(shka)
end

function do_camera_shake()
if abs(shkx)<0.1 then
 shkx=0
else
 shkx*=-0.7-rnd(0.2)
end

if abs(shky)<0.1 then
  shky=0
 else
  shky*=-0.7-rnd(0.2)
 end
end

function spe_circ(x, y, in_col, out_col, radius)
   local in_col, out_col, posx, posy = in_col, out_col, x+shkx, y+shky

   circ(posx, posy,radius, 8)
   circ(posx, posy, radius,in_col)
   circ(posx+1, posy, radius,in_col)
   circ(posx-1, posy, radius,in_col)
   circ(posx, posy, radius-1,out_col)
   circ(posx, posy, radius+1,out_col)
end

-- ##show_message
function show_message(_text, _x, _y, _in_color, _out_color, _speed, _display_time, tag, moving, blink, ui_state, bordercol)
 local col1, col2 = 7, 6
 local msg = make_gameobject(_x, _y, tag, {
  text=_text, 
  in_color = _in_color,
  out_color = _out_color, 
  speed = _speed,
  moving_speed=3,
  blink=blink,
  display_time = time()+_display_time,
  reset=function(self)
   self:enable()
   self.timer = 0
   self.moving_speed=4
  end,
  set_properties=function(self, text, x, y, in_color, out_color, speed, display_time)
   self.text=text
   self.x=x
   self.y=y
   self.in_color=in_color
   self.out_color=out_color
   self.speed=speed
   self.display_time=time()+display_time
   self:reset()
  end,
  update=function(self)

   if moving then self.y -= self.moving_speed 
    if(self.moving_speed>=0.1) then self.moving_speed*=0.8 
    end
   end
   if(time()>= self.display_time) then 
    self:reset()
    self:disable()
   end
  end,
  blink_color=function(self)
   if(self.blink and time()*self.speed%4 >= 2) then return true else return false end
  end,
  draw=function(self)
   if ui_state then 
    if(self:blink_color()) then
    spe_print(self.text, self.x, self.y, col1, col2, true, bordercol)
    else
    spe_print(self.text, self.x, self.y, _in_color, _out_color, true, bordercol)
    end

   else
    if(self:blink_color()) then
    spe_print(self.text, self.x, self.y, col1, col2, bordercol)
    else
    spe_print(self.text, self.x, self.y, _in_color, _out_color, bordercol)
    end
   end
  end
  })
 if msg != nil then
  msg:set_properties(_text, _x, _y, _in_color, _out_color, _speed, _display_time)
  return msg
 end

 end

__gfx__
0000000000000000000000000000066666000000000000000000000077700cc000000000667777770007700c00000bb000000000770000bb000000bb00000000
00000000000006666660000000006611166000000000000000000000777ccc000000000067777770000777c000bbbbb00000000077000bbb00070bbb00ddd000
00700700000066d11d660000000661ddd166000000000000000000007cccc6667770000c77777cc0007c76661bbbbb0000000bb000bbbb0000bbbb070ddddd00
0007700000066d1111d6600000066ddddd66000000000000000000001c7c7666777cccc17777ccc707ccc6660c717c0100bbbbb00bbbbb000bbbbb00ddddddd0
000770000066d11cc11d660000016ddddd61000000000000000000004cccc6667cccc666777ccc771c7c76660cc1ccc00bbbbb0077717c000c717c00dd6d6dd0
00700700006d11cccc11d600000066ddd660000000000000000000000ccccc6c1c7c7666c777c77c0ccccc600cc1cccc1c717c0077c1cc000cc1cc0022222220
00000000006d1cccccc1d60000001166611000000000000000000000ccccccc04cccc666077777700cccccc0ccc1ccc00cc1cccc0cc1ccc00cc1ccc002222200
00000000006ddccccccdd60000006d111d600000000000000000000000000000cccccc6000077700cccccccc00000000ccc1ccc0ccc1ccccccc1cccc00222000
000000000066ddccccdd66000000d1c1c1d000000000000000000000333333333333333333333444444444444444444400000000000000000000000000000000
0000000000166ddccdd661000000d1ccc1d000000000000000000000333333333343433333444444444444444444444400000000000000000000000000008000
00000000001166dddd6611000000d1ccc1d000000000000000000000333333333334434333444444444444444444444400000000000000000000000000008000
0000000000211666666112000000d1ccc1d000000000000000000000333333333434432334444444444444444444444300000000000000000000000000008000
00000000002211111111220000006d1c1d600000000000000000000033333333333223333444444444444444444444430000000000000000000ddd0000008000
000000000002211111122000000016d1d610000000000000000000003333333334434433444444444444444444444433000000000000000000d7d7d000888880
00000000000022222222000000002111112000000000000000000000333333333443443344444444444444444444443300000000000000000022222000088800
00000000000002222220000000000222220000000000000000000000333333333223333344444444444444444443333300000000000000000002220000008000
000000000000000000000000000000000000000000000000000000004444444411111cccccc4444444444ccccccccccc00000000000000007770000077700000
00000000000000000000000000000000000000000000000000000000444444f411cccccccccccc4444cccccccccccccc00000000000990007497770079970000
000000000000000000000000000000000000000000000000000000004ff444d411cccccccccccc4444cccccccccccccc000cc000009999007499997074997000
000000000000000000000000000000000000000000000000000000004ff4f4441cccccccccccccc44cccccccccccccc400c77c00099aa9900799997007499770
000000000000000000000000000000000000000000000000000000004dd444441cccccccccccccc44cccccccccccccc400c77c00099aa9900749947000749887
000000000000000000000000000000000000000000000000000000004444ff44cccccccccccccccccccccccccccccc44000cc000009999000744499700078870
000000000000000000000000000000000000000000000000000000004f44ff44cccccccccccccccccccccccccccccc4400000000000990000077447000072787
000000000000000000000000000000000000000000000000000000004d44dd44ccccccccccccccccccccccccccc4444400000000000000000007770000007070
000000000000000000000000000000000000000000000000cccccccc1111111111111111cccccccccccccccccccccccc000bb000000bb0000000000000000000
000000000000000000000000000000000000000000000000ccbcbccc1111111111c1c111cccccccccccccccccccccccc0b0bb0b0000bb0000000000000000000
000000000000000000000000000000000000000000000000cccbbcbc11111111111cc1c1cccccccccccccccccccccccc00bbbb0000bbbb00000bb00000000000
000000000000000000000000000000000000000000000000cbcbbc3c111111111c1cc1214cccccccccccccccccccccc1bbb00bbbbbb00bbb00bbbb00000bb000
000000000000000000000000000000000000000000000000ccc33ccc11111111111221114cccccccccccccccccccccc1bbb00bbbbbb00bbb00bbbb00000bb000
000000000000000000000000000000000000000000000000cbbcbbcc111111111cc1cc1144cccccccccccccccccccc1100bbbb0000bbbb00000bb00000000000
000000000000000000000000000000000000000000000000cbbcbbcc111111111cc1cc1144cccccccccccccccccccc110b0bb0b0000bb0000000000000000000
000000000000000000000000000000000000000000000000c33ccccc111111111221111144444cccccccccccccc11111000bb000000bb0000000000000000000
0000000444400000000000000000000000000000000000000000000000000000000aa04400000000000000777777700000000077700000000000aaa000000000
0099900fff0000000000000444400000000000000000000000000004444000000000aa4440000000000777777777770000077770000000000aaaaaaaaa000000
0966691fff1999000099900fff000000000000044440000000000999ff000000000777a444440000007777777777777000777770aaaa70000aaaaaaaaaaa0000
99666911119966900966691fff19990000000999ff00000000009666919900000007779a9ff00000077777777777777007770770aaa77770aaaaaaaaaaaaa000
996691911919666999666911119966900000966691990000000996669166900000777766691900007777777777777777077077aaaaaa7777aaaa0aa770aaaa00
099691199119669999669191191966690009966691669000000996691966690000777966691500007777777777777777777777aaaaaa7777aaaaaaa7777aaa00
655a9191191969500996911991196699000996691966690000009969116699000077766691960000777777777777777777777aaaaaaaa777aaaaaa777777aa00
460a991111999560655a9191191969500000996911669900000655a919695000077709669116000077777766777777777777aaaaaaaaa777aaaaa77777777aa0
44a7701111506640460a991111999560000655a919695000000460a991956000077700999196000077777666977777777777aaaaaaaa07770aaaa77777777aa0
44a777711100044444a7701111506640000460a99195600000044a77116640007777000449100000777709669777777770777a0aaaaa77700aaaa7777aa00a00
0a7777777150004444a777711100044400044a771166400000044a777704440077700001111000007770009991777777777777aaaaa077700aaaaa77aaa00000
0a007777777500440a7777777100004400044a77770444000444a77777777400777000511115000077000519991777700777777aaaa7777700aa0aa7aaa00000
00055517777770000a007777777500440000a777777774000444a5577777777000000551111550007005551111577770077777777777777000aaaaaaaa777000
000555111777770000055517777770000000a4777777777004445550517777770000555511155000005555111555500000777777777777700000aaaaa7777000
0004401111077700000445111777770000004444517777770400000001144777000044400000440000444000004440000aaa777777077aa00007770000077700
004440000004440000444111111777000000400441100777000000000014444000044440000044440444400000444400000000000000aaaa0077770000077770
00000004444000005555555500000000000000000000000000000000000000000007707700000000000000777777700000000077700000000000000000000000
0099900fff0000005555555500000000000004444000000000000004444000000000777770000000000777777777770000077770000000000000000000000000
0966691fff0999005544444500000000000999ff000000000099901fff0000000007777777770000007777777777777000777770444470000000000000000000
9966691111996690554fff550000000000966691990000000966691fff0999000007777777700000077777777777777007770770fff777700000000000000000
996691911919666995ffff5900000000099666916690000099666991199966900077777777770000777777777777777707707700fff077770000000000000000
0996911991196699911fff1900000000099669196669000099669119911966690077777777770000777777777777777777777799111977770000000000000000
069991911919696091111119000000000099691166990000099a9191191966990077777777770000777777777777777777777669111907770000000000000000
666099111199966091111119000000000666a91969600000460a9911111969600777077777770000777777777777777777770991111107770000000000000000
460000111100664000000000000000000460a9919660000044a770111199966007770077777700007777777777777777777700a1111107770000000000000000
44000091190004440000000000000000044a77116640000044a77771190066407777000777700000777707777777777770777a01111177700000000000000000
44000619916000440000000000000000044a7777044400000a777777710004447770000777700000777000777777777777777711111077700000000000000000
0000661111660044000000000000000004a77777777400000a007777777500447770007777770000770007777777777007777775115777770000000000000000
0006661111666000000000000000000005a557777777700000055517777770000000077777777000700777777777777007777777777777700000000000000000
00066611110660000000000000000000055550517777770000055511177777000000777777777000007777777777700000777777777777700000000000000000
00044011110440000000000000000000044400011447770000044011110777000000777000007700007770000077700004447777770774400000000000000000
00444000000444000000000000000000444400001444400000444000000444000007777000007777077770000077770000000000000044440000000000000000
22999999999999222299999999999922229999999999992222999999999999229999999999999999000000000000000000000000000000000000000000000000
29999999999999922999999999999992299999999999999229999999999999929999999999999999000000000000000000000000000000000000000000000000
991661666777c7999911111111111199991115555555559999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
991aa66777cc7799991711c1c1117199991115555555579999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
991aaa77cc77769999711c777c111799991115555555779999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
991aaa7c77766699991cc77777cc1799991a115555577c9999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
99144a77766116999911c77777c11799991111555577c79999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
99444aa7616516999971cc777cc1779999111a15577c779999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
99441aa5616515999977cc777cc7779999111aa577c7719999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
994111151155159999777cc7cc777199991aaa177c77119999171a9999a11799991a1a9999a11a99000000000000000000000000000000000000000000000000
9911111515551599991777c7c777119999aaaaaaa771a19999111a9999a7119999111a9999aa1199000000000000000000000000000000000000000000000000
99111151155155999911111c11111199991aa1aaa7a1119999111a9999a1119999111a9999a11199000000000000000000000000000000000000000000000000
991115115511559999111111111111999933333333333399997171a99a17119999a1a1a99a1a1199000000000000000000000000000000000000000000000000
99155555511555999911111111111199993333333333339999111117711171999911111aa111a199000000000000000000000000000000000000000000000000
29999999999999922999999999999992299999999999999229999999999999929999999999999999000000000000000000000000000000000000000000000000
22999999999999222299999999999922229999999999992222999999999999229999999999999999000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1818181818181818181818181817181717181919171818171818191a27271a1b181818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818181818181818181818181818181718191a1a171819171819271a1a1a1b18181818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818181818181818181818171817171719271a1a18191a1919271a27271b1818181718181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181818181818181818181818181818191a1a1a1a19271a1a1a1a1a271b181818181718181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818181818181818181718171718191a1a271a1a1a1a1a1a271a1a1b18181818171818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18181818181818181818181818191a1a1a271a1a1a271a1a1a271b1818181817181717181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181818181818181818171718191a1a271a1a1a1a271a1a1a1a1b181818181718171718181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818181818181718171718191a1a1a1a1a271a1a1a1a271a1b18181818171717181718181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18181818181718171718191a1a271a1a1a1a271a1a271a1b1818181717181817171718181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181818181718181718191a1a1a271a1a1a1a1a271a1a1b181718181717181817181818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
371818171817171719271a1a1a271a1a271a271a1a1b18181817181718181817171818181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37371718171718191a1a1a1a1a1a1a1a271a1a1a1b1818181817181718181717181818180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
373718181718191a1a271a1a1a1a1a1a1a1a1a1b181817181817171717171718181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000017171719271a271a1a271a1a1a1a271a1b18181718171717171818181818181818373737373737370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001a271a1a1a271a1a1b1818171717171818181818181837373737373737373737373737373737373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000001a1a1a271a1b181718171817171817181818181837373737373737373737373737373737373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001a1a1a1b18171718181718181717181818181837373737373737373737373737373737373737373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000001a1b1817171817171818171818181837373737000000000000000000000000373737373737373737373737373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001717171818181817181818181837373737000000000000000000000000373737372a3a293737373737373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000171818171717171818183737371717171717171717171717171700003737372a3a3a3a2937373737373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001817171817181818181837373717383737372829000000000017000037372a3a3a3a3a3a29373737373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000018181717181818181837373717373738283a3a2900000000170000372a3a3a3a3a3a3a3a293737373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000001717181818181837373737173837283a3a363a29000000170000373a3a3a3a3a3a3a3a3a2937373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000017171818180000373737371737283a3a3a3a3a3a29000017000037393a3a3a3a3a3a3a3a3a29373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000181818180000373737371728363a3a3a3a3a3a3a29001700003737393a3a3a3a3a3a3a3a3a293737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000001818181800003737373717393a3a3a3a3a363a3a3a29170000373737393a3a3a3a3a3a3a3a3a2937000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000373737371700393a3a3a3a3a3a3a3a3617000037373737393a3a3a3a3a3a3a3a3a37000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003737373700170000393a3a363a3a3a3a3b1700003737373737393a3a3a3a3a3a3a2b37000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000373737370017000000393a3a3a363a3b37170000373737373737393a3a3a3a3a2b3737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000037373700001700000000393a3a3a3b383717000037373737373737393a3a3a2b373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003737373737170000000000393a3b3737381700003737373737373737393a2b37373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000003737373737171717171717171717171717170000373737373737373737373737373737000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2299999999999922229999999999992222999999999999222299999999999922999999999999999900000000000000000000000000000000000000000000000092999999999999299299999999999929929999999999992992999999999999299999999999999999000000000000000000000000000000000000000000000000
9961166676777c99991111111111119999115155555555999911a199991a11999911a199991a119900000000000000000000000000000000000000000000000099a16a7677cc77999971111c1c11179999115155555575999911a199991a11999911a199991a1199000000000000000000000000000000000000000000000000
99a1aa77cc7767999917c177c711719999115155555577999911a199991a11999911a199991a119900000000000000000000000000000000000000000000000099a1aac77767669999c17c7777cc719999a111555575c7999911a199991a11999911a199991a1199000000000000000000000000000000000000000000000000
9941a4776716619999117c77771c71999911115555777c999911a199991a11999911a199991a11990000000000000000000000000000000000000000000000009944a47a165661999917cc77c71c77999911a15175c777999911a199991a11999911a199991a1199000000000000000000000000000000000000000000000000
9944a15a165651999977cc77c77c77999911a15a777c17999911a199991a11999911a199991a119900000000000000000000000000000000000000000000000099141151115551999977c77ccc77179999a1aa71c77711999971a199991a719999a1a199991aa199000000000000000000000000000000000000000000000000
99111151515551999971777c7c77119999aaaaaa7a171a999911a199997a11999911a19999aa11990000000000000000000000000000000000000000000000009911111551155599991111c11111119999a11aaa7a1a11999911a199991a11999911a199991a1199000000000000000000000000000000000000000000000000
9911511155115599991111111111119999333333333333999917179aa9711199991a1a9aa9a111990000000000000000000000000000000000000000000000009951555515515599991111111111119999333333333333999911117117111799991111a11a111a99000000000000000000000000000000000000000000000000
9299999999999929929999999999992992999999999999299299999999999929999999999999999900000000000000000000000000000000000000000000000022999999999999222299999999999922229999999999992222999999999999229999999999999999000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100002631020010180100e0100f700077000370000700007000070000700007000070000700007000070000700007000070000700007000000000000000000000000000000000000000000000000000000000
000200002f61024610206101a6100f0100b0100901000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0101000023610236102d31021310173100c3100f310103101331015310173100e310113100c300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000034621286211c6211061110611000011561113611116210f6210c0010e6210c0010c6210c00116621146210000111621000010f6210d621000010c6210000100001000010000100001000010000100001
0002000016210132100c6100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010029610246101f6101c610176101561014610136101261012610126100f61011610126101101012010130101501017010180101a0101c01020010220102401026010280102c0102e010300103301035010
0001010013232162221621218232182221821218232182221821218232132220f2120f2320c2220a2120c2320c2220c2120c2120c2220c2120c2220f2120f2220f2120f2220f2120c2220a2120a2220521200202
00040000030100301005010050100701007010070100a0100a0100a0100c0100c0100f0100f010110101301016010180101b0101b0101d0101f010220102401027010290102e01030010370103a0103f0103f010
00020000186100f6103701035010310102e0102e0102b010290102701027010240102401022010220101f0101b0101b01018010160101601013010110100f0100f0100c0100a0100a01007010050100501001010
0007001f01050010500105001000010000105001050010500a0000b00001050010500105001050010501b0001b000010000100002000020500205002050020500205023000010000205002050020500205000000
001000010161001600016000160001600016000160001600016000160001600016000160001600016000160001600016000160001600016000160001600016000160001600016000160001600016000160001600
010c00200e01000000000000f013100101c0100f1130f1130e010000000f0130f013100101c01000000000000e01000000000000f013100101c0100f1130f1130e010000000f0130f013100101c0100000000000
0001000028010230101e0100501007010070100a0100000000000000000000000000000000000000000170101b010240102e010370103a0100000000000000000000000000000000000000000000000000000000
000100000121001200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000