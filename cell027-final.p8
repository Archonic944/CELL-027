pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--cell-027 by archonic,
--virtuavirtue, troubledkarma56

-- main
--IMPORTANT FOR SAVING
--the value stored in dget(0) is level + 1.
function reset_game(start)
	dset(0,1)
	next_level(1,false,start)
	level=1
	cur_action = 1
end
frame = 0
		-- ☉ init ☉ --
	-- init
function _init()
	poke(0x5f5f,0x10)
	cartdata("cell-027")
	menuitem(1, "reset game", reset_game)
	_init_world() -- init world
	cur_state[1]() -- init state
	--reset_game(true)
		-- debug
	--cam_mode=true -- enables camera movement
end

	-- initialize global stats
function _init_world()
		-- stats
	poke(0x5f2d, 1)
	lvl_saved = dget(0)
	lvl_saved = (lvl_saved == 0) and 1 or lvl_saved
		-- world
	level,level_off,level_map_x,level_map_y,
	cur_state,events,
	cam,deaths
	=
	lvl_saved-1,128,16,16,
	states[1],{shake_screen},
	{x=0,y=0},0
end


		-- ⬆️ updating ⬆️ --
	-- update
function _update()
	cur_state[2]()
	if frame < 32000 then frame += 1 end
end


	-- draw
function _draw()
	cur_state[3]()
end
-->8
-- object system

		-- processes
	-- initialize objects
function _init_obj()
	objs={}
	
	for i=1,7do
		add(objs,{})
	end
end


		-- ⬆️ update ⬆️ --
	-- try update (performance)
function try_update(obj)
	if(obj.update)obj:update()
end

	-- update objects
function _update_objs()
	all_objs(try_update)
end


		-- ⬇️ draw ⬇️ --
	-- try draw (performance)
function try_draw(obj)
	if(obj.draw)obj:draw()
end

	-- draw objects
function _draw_objs()
	all_objs(try_draw)
end

	-- get sspr coordinates for sspr_draw
function set_sspr(o,sp)
	o.sx,o.sy,o.x_off,o.y_off
	=
	(sp%16)*8,sp\16*8,0,0
end

	-- draw object with sspr
function sspr_draw(o,x,y,w,h)
	w,h=w or 8,h or 8
	sspr(o.sx,o.sy,w,h,o.x-x*.5,o.y-y*.5,w+x,h+y)
end


		-- ⧗ table utilities ⧗ --
	-- iterate function over layer
function all_objs(func)
	foreach(objs,function(layer)
		foreach(layer,function(obj)
			func(obj)
		end)
	end)
end

	-- run function arrays
function for_each(arr)
	foreach(arr,function(ev)
		ev()
	end)
end


		-- utilities
	-- create new object
function new_obj(obj,layer,x,y)	
	local new_obj={}
	
	new_obj.init,new_obj.update,new_obj.draw,new_obj.death,new_obj.layer,new_obj.wh,new_obj.hh
	=
	obj[1],obj[2],obj[3],obj[4],layer,4,4
	
	if x and y then
		new_obj.x,new_obj.y,new_obj.w,new_obj.h
		=
		x,y,1,1
	end
	if(new_obj.init)new_obj:init()
	
	add(objs[layer],new_obj)
	return new_obj
end


	-- initialize properties
	-- necessary for particles
function prop_init(ob,w,h,col)
	ob.w,ob.h,ob.wh,ob.hh,ob.color
	=
	w,h,(w*8)*.5,(h*8)*.5,split(col)
end


	-- destroy object
function del_obj(obj)
	obj.deleted=true
	del_timer(obj.anim)
	del(objs[obj.layer],obj)
end


		-- ⬆️ utility ⬆️ --
	-- distance between two points
function dist(x1,y1,x2,y2)
 return abs(x1-x2)+abs(y1-y2)
end

	-- distance between player and object
function player_dist(o,amm)
	return player and dist(o.x+o.wh,o.y+o.hh,player.x+player.wh,player.y+player.hh)<amm
end

	-- lerp smoothly
function lerp(val_1,val_2,amm)
	amm=amm or 5
	return(val_1-val_2)/amm
end

function h_lerp(current, end_val, mult)
	local target_full = end_val - current
	local add = target_full/mult
	if(abs(add) < 0.01) return end_val
	return current + add
end

	-- convert position to map coord
function to_map(p)
	return(p/8)&-1
end

	-- get all possible flags from position
function get_flag(x,y,plus_off,min_off,flag)
	min_off,plus_off
	=
	min_off or 0,plus_off or 6
	
	return 
	check_flag(x,y,flag)
	or 
	check_flag(x+plus_off,y-min_off,flag)
	or
	check_flag(x-min_off,y+plus_off,flag)
	or
	check_flag(x+plus_off,y+plus_off,flag)
end

	-- check specific flag
function check_flag(x,y,flag)
	return fget(mget(to_map(x),to_map(y)),flag)
end

	-- set object velocity to position
function obj_to_pos(obj,x,y,spd)
	obj.rot=-look_at(obj.x,obj.y,x,y)
	move_to(obj,-obj.rot,spd)
end

	-- angle object towards position
function look_at(x1,x2,x,y)
	return atan2(x-x1,y-x2)
end

	-- set velocity to angle
function move_to(obj,ang,spd)
	obj.vel_x=cos(ang)*spd
	obj.vel_y=sin(ang)*spd
end


		-- ⬇️ drawing ⬇️ --
	-- draw with rotation
function pd_rotate(x,y,rot,mx,my,w,flipp,scale)
  local step = 1/16
  scale=scale or 1
  rot=rot\step * step
  local halfw, cx=scale*-w/2, mx + .5
  local cy,cs,ss=my-halfw/scale,cos(rot)/scale,sin(rot)/scale
  local sx, sy, hx, hy=cx+cs*halfw, cy+ss*halfw, w*(flipp and -4 or 4)*scale, w*4*scale
  for py=y-hy, y+hy do
  tline(x-hx, py, x+hx, py, sx -ss*halfw, sy + cs*halfw, cs/8, ss/8)
  halfw+=.125
  end
end


		-- 🐱 clearing 🐱 --
	-- clear objects except in table
function clear_except(excepts)
	if player then
		foreach(player.wires,function(w)
			del_wire(player,w)
		end)
	end

	all_objs(function(obj)
		local check=true
		
		foreach(excepts,function(ex)
			if(obj==ex)check=false
		end)
		
		if(check and not obj.top_level)del_obj(obj)
	end)
end
-->8
-- entities


		-- ✽ functions ✽ --
	-- init for entity objects
function entity_init(o,sprs)
	o.spr,o.sprites
	=
	0,split(sprs)
end

	-- init for character objects
function character_init(o,sprs,col,enemy,w,h)
	entity_init(o,sprs)
	
	o.vel_x,o.vel_y,o.spr,o.rot
	=
	0,0,o.sprites[1],0

	o.wh,o.hh
	=
	(o.w*8)*.5,(o.h*8)*.5
	
	prop_init(o,w or 1,h or 1,col)

	if(enemy)add(enemies,o)
end


		-- ⬇️ draw ⬇️ --
	-- draw for entity objects
function entity_draw(o)
	local w=o.w or 1
	if not o.rotate then
		spr(o.spr,o.x,o.y,w,o.h or 1,o.flip_x,o.flip_y)
	else
			-- janky attempt at rotating
			-- larger sprites
		local w_c,h_c
		=
		w>1and o.w*2or 0,w>1and o.w*6or 0
		pd_rotate(o.x+w_c,o.y+h_c,o.rot,o.rot_sp_x,o.rot_sp_y,o.w+(o.w-1),false,1)
	end
end


		-- ▒ behaviors ▒ --
	-- release wires
function del_wires(o)
	foreach(o.wires,function(wire)
		if(wire.landed or o.dead)wire:release()
	end)
end

	-- delete specific wire
function del_wire(o,wire)
	if(not wire)return
	del_obj(wire)
	del(o.wires,wire)
end


	-- takes pausing into account
function enemy_update(func)
	if(not player.dead and started)func()
end


		-- ⧗ table ⧗ --
	-- types of entities
entities={
		-- 😐 slimewalker 😐 --
	{
			-- init
		function(o)
			character_init(o,'7,8','8,4,2',true)
			set_rot_sprs(o,2,63)
			
				-- fly cooldown
			set_obj_flight(o)
		end,
			
			-- update
		function(o)
			enemy_update(function()
				if(o.flying)col_check(o,col_fly_stop)
				
				if player and not player.dead and o.can_fly and player_dist(o,100) then
					o.can_fly=false
					fly(o,player.x,player.y,4)
				end
			end)
		end,
			
			-- draw
		entity_draw
	},
	
		-- ⬆️ urchin ⬆️ --
	{
			-- init
		function(o)
			character_init(o,'10,11','8,4,2',true)

				-- animation
			anim(o)
			local r_vec=split'-1,1'
			
			o.vel_x,
			o.vel_y
			=
			rnd(r_vec),rnd(r_vec)
		end,
		
			-- update
		function(o)
			enemy_update(function()
				col_check(o,col_bounce,true)
			end)
		end,
		
			-- draw
		entity_draw
	},
	
		-- 🐱 crawler 🐱 --
	{
			-- init
		function(o)
			character_init(o,'12,13','8,4,2',true)
			
				-- animation/stats
			anim(o,7)
			o.spd,o.vel_x
			=
			2,2
		end,
			
			-- update
		function(o)
			enemy_update(function()
				col_check(o,col_climb,true)
			end)
		end,
		
			-- draw
		entity_draw
	},
		
		-- ∧ webber ∧ --
	{
		function(o)
			character_init(o,'14,15','2,4,8,7',true)
			set_rot_sprs(o,4,63)
			
			o.wires,o.anim
			=
			{},new_timer(rand_range(30,40)&-1,function()
				if player and not player.dead and o.can_fly and player_dist(o,100) then
					if #o.wires==3then
						o.wires[1]:release()
					end
					
					o.can_fly=false
					fire_wire(o,player.x+player.wh,player.y+player.hh,5)
				end
			end)
			
				-- fly cooldown
			set_obj_flight(o)
		end,
		
			-- update
		function(o)
			enemy_update(function()
				if(o.flying)col_check(o,col_fly_stop)
			end)
		end,
			
			-- draw
		entity_draw,
		
			-- death
		del_wires
	},
		-- bubble --
	{
		function(o)
			character_init(o,'29','8,4,2,7',true)
			set_sspr(o,29)
			
			o.off=rand_range(-50,50)
		end,
			-- update
		function(o)
			enemy_update(function()
				if player then
					obj_to_pos(o,player.x,player.y,1)
				
					o.x_off,o.y_off
					=
					sin(time()+o.off)*2,sin(time()+o.off*2)*2
				
					o.x+=o.x_off*.5
					o.y+=o.y_off*.5
					
					col_check(o,kill,true)
					kill_check(player,o,2)
				else
					kill(o)
				end
			end)
		end,
		
		function(o)
			sspr_draw(o,o.x_off+1,o.y_off+1)
		end
	},
		-- boss urchin --
	{
			-- init
		function(o)
			character_init(o,'94','8,4,2',true,2,2)
			o.vel_x,o.vel_y
			=
			1,1
			
			o.anim=new_timer(10,function()
				o.flip_x=not o.flip_x
			end)
		end,
			-- update
		function(o)
			enemy_update(function()
				if col_check(o,col_bounce,true)then
					if(player_dist(o,50))shake=.1
					play_sfx(22)
				end
			end)
		end,
			-- draw
		entity_draw,
			-- death
		function(o)
			for i=1,2do
				local urchin=new_obj(entities[2],1,o.x,o.y)
				urchin.inv,urchin.vel_x,urchin.vel_y
				=
				true,i==1 and -1 or 1,i==1 and -1 or 1
				new_timer(1,function()
					urchin.inv=false
				end,true)
			end
			if(player.wires[1]) player.wires[1]:release()
		end
	},
		-- bubble blower --
	{
			-- init
		function(o)
			character_init(o,'79','8,4,2',true)
			set_sspr(o,79)
			
			o.anim=new_timer(rand_range(40,50)&-1,function()
				enemy_update(function()
					if player and player_dist(o,100) then
						local bubble=new_obj(entities[5],2,o.x,o.y)
						large_part(bubble)
						
						o.x_off,o.y_off
						=
						25,25
					end
				end)
			end)
		end,
			-- update
		function(o)
			o.x_off*=.8
			o.y_off*=.8
			
			o.x_off&=-1
			o.y_off&=-1
		end,
			-- draw
		function(o)
			sspr_draw(o,o.x_off,o.y_off)
		end
	}
}


		-- ⬆️ utility ⬆️ --
	-- animate entity between 2 frames
function anim(o,dur)
	dur=dur or 10
	o.anim=new_timer(dur,function()
		o.spr=o.spr==o.sprites[2] and o.sprites[1] or o.sprites[2]
	end)
end

	-- set rotational sprites
function set_rot_sprs(o,x,y)
	o.rot_sp_x,o.rot_sp_y
	=
	x,y
end

	-- set object flight timer
function set_obj_flight(o)
		-- fly cooldown
	o.anim=new_timer(rand_range(40,45)&-1,function()
		o.can_fly=true
	end)
end


		-- 🐱 collision 🐱 --
	-- check collision on object
	-- unoptimal cause bitmasks
	-- didn't work
function col_check(o,func,bounce_col, stop_checks)
		-- x variables
	local x,y,w
	=
	o.x+o.vel_x,o.y,o.w*8
	
	w=w>0and w-2or w
	
	
	local col_x,death_check
	=
	bounce_col and get_flag(x,y,w) or check_flag(x,y),
	o.player and check_flag(x,y,1)
	
		-- x collision
	if not col_x then
		o.x+=o.vel_x
	else 
		func(o,1)
		if(death_check and not stop_checks)check_kill()
		return true
	end
	
	 -- y variables
	x,y
	=
	o.x,o.y+o.vel_y

	local col_y,death_check
	=
	bounce_col and get_flag(x,y,w) or check_flag(x,y),
	o.player and check_flag(x,y,1)
	
		-- y collision
	if not col_y then
		o.y+=o.vel_y
	else
		func(o,2)
		if(death_check and not stop_checks)check_kill()
		return true
	end
end


	-- stop collision when flying
function col_fly_stop(o,side)
		-- x
	if side==1 then
		o.flip_x,o.flip_y,o.spr,o.x
		=
		o.vel_x>0 and true or false,false,
		o.sprites[1],to_map(o.x)*8
	
		-- y
	else
		o.flip_y,o.flip_x,o.spr,o.y
		=
		o.vel_y<0 and true or false,false,
		o.sprites[2],to_map(o.y)*8
	end
	
	o.vel_x,o.vel_y,o.rotate,
	o.flying
	=
	0,0,false,false
	
	if o.player then
		shake=.1
		play_sfx(21)
	else
		play_sfx(22)
	end
	new_part(o,1,3)
end

	-- bounce when hitting a wall
function col_bounce(o,side)
	if side==1 then
		o.vel_x=-o.vel_x
	else
		o.vel_y=-o.vel_y
	end
	new_part(o,2,(4+o.w))
end

	-- change side to wall
function col_climb(o,side)
		-- x
	if side==1 then
		local vel_x=-sgn(o.vel_x)
		
		o.x,o.vel_x,o.vel_y
		=
		o.x,0,o.spd*vel_x
			
		-- y
	else
		local vel_y=sgn(o.vel_y)
		
		o.y,o.vel_y,o.vel_x
		=
		o.y,0,o.spd*vel_y
	
	end
	new_part(o,2,4)
end


	-- make entity fly towards position
function fly(o,targ_x,targ_y,spd,flypass)
	if(not flypass and (not o or o.dead or (not o.flying and not can_fly(o,targ_x,targ_y))))return

	new_part(o,1,3)
	if(not o.player)play_sfx(3)

	obj_to_pos(o,targ_x,targ_y,spd)
	o.flying,o.rotate
	=
	true,true

		-- particle trail
			-- i am deathly ashamed
	local trail_tick,trail_div=0

	if not o.anim then
		o.anim=new_timer(1,function()
			trail_tick+=1
			trail_div=(abs(o.vel_x)+abs(o.vel_y))&-1
			
			if o.flying and not o.dead then
				if trail_tick%(5/trail_div)&-1==0then
					rnd()
					new_part(o,2,2,2,0)
				end
			else
				del_timer(o.anim)
			end
		end)
	end
end

	-- if object can fly
function can_fly(o,targ_x,targ_y)
	if o.spr==o.sprites[1]then
		if((o.flip_x and o.x+5<targ_x)or(not o.flip_x and o.x-5>targ_x))return false
	else
		if((not o.flip_y and o.y+5<targ_y)or(o.flip_y and o.y-5>targ_y))return false
	end
	return true
end


		-- ▒ behavior ▒ --
	-- check if object can be killed
function kill_check(killer,killed,rad,func)
	if(not killer or not killed)return
	if not killed.dead and dist(killed.x+killed.wh,killed.y+killed.hh,killer.x+killer.wh,killer.y+killer.hh)<rad+(killer.w*killer.w) then
		if func then
			func()
		else
			kill(killed)
		end

		return true
	elseif killed.dead then
		killed.vel_x*=.8
		killed.vel_y*=.8
		killed.x+=killed.vel_x
		killed.y+=killed.vel_y
	end
end

	-- kill object
function kill(o)
		-- has no death frame
	if(o.inv or mouse.paused)return
	o.dead=true
	
		-- has no death sprite
	if(o.anim)del_timer(o.anim)
	if not o.sprites or not o.sprites[3] then
		del_obj(o)
	else
		o.rotate,o.spr
		=
		false,o.sprites[3]
	end
	if(o.death)o:death()
	
		-- if object is player
	if o.player then
		play_sfx(4)
		new_transition(1,function()
			reset_level(level)
		end)
		deaths+=1
	else
		del(enemies,o)
		play_sfx(5) -- generic death sfx
	
		if#enemies==0and not player.dead then
			if level==max_level then
				recovery_mode_cutscene()
			elseif not heart_boss or heart_boss.dead then
				next_level()
			end
		end
	end
	
	large_part(o,3,nil,o.player and 4 or 2)
	shake=.2
end


		-- # loading # --
	-- array of sprites to entity
spawns={}

	-- slimewalker
spawns[9],
	-- urchin
spawns[10],
	-- crawler
spawns[12],
	-- webber
spawns[78],
	-- bubble
spawns[29],
	-- boss urchin
spawns[95],
	-- bubble blower
spawns[79],
	-- check for player
spawns[5]
=
1,
2,
3,
4,
5,
6,
7,
true


spawn_cache={} -- resets spawns in room
	-- spawn objects in room
function spawn_objects()
		-- clear previous entities except player and mouse
	local excepts = {mouse, player_ghost}
	if(typewriter_timer) add(excepts, typewriter_timer)
	clear_except(excepts)
	spawn_cache[level]={}
	
	local x_off,y_off
	=
	lvl_x/8,lvl_y/8
	
		-- level offset
	for x=1+x_off,level_map_x+x_off do
		for y=1+y_off,level_map_y+y_off do
			local m=mget(x,y)
			local spawn=spawns[m]
			
			if spawn then
				add(spawn_cache[level],{x,y,m})
					-- player
				if m==5 then
					init_player(x*8,y*8)
					-- other
				else
					new_obj(entities[spawn],2,x*8,y*8)
				end
				mset(x,y,0)
			end
		end
	end
end
-->8
-- particles

	-- types of particles
particles={
		-- ★ gravity slime ★ --
	{
			-- init
		function(p)
			init_part(p,2,2.5)
		end,
			-- update
		function(p)
			p.vel_y+=0.1
			update_part(p)
		end,
			-- draw
		function(p)
			draw_part(p)
		end
	},
	
		-- ✽ floaty slime ✽ --
	{
			-- init
		function(p)
			init_part(p,2,2.5)
		end,
			-- update
		function(p)
			p.vel_y*=0.9
			update_part(p)			
		end,
			-- draw
		function(p)
			draw_part(p)
		end
	},
	
		-- slime flakes
	{
			-- init
		function(p)
			p.x,p.y,p.s,p.spd,p.off,p.c,p.top_level
			=
			rnd(128)+cam.x,
			rnd(128)+cam.y,
			0+flr(rnd(5)/4),
			0.25+rnd(5),
			rnd(1),
			rnd({3,11}),
			true
		end,
		nil,
			-- draw
		function(p)
			srand(rnd(5)) -- guh
			if(p.x>132+cam.x)p.x,p.y=-4+cam.x,rnd(128)+cam.y
			
			p.x+=p.spd
			p.y=(p.y+sin(p.off))%(132+cam.y)
			p.off+=min(0.05,p.spd/32)
			rectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
		end
	}
}


		-- ✽ functions ✽ --
	-- init particles
function init_part(obj,spd,size)
	obj.vel_x,obj.vel_y,obj.radius,obj.color,obj.org_level
	=
	rand_range(-spd,spd),rand_range(-spd,spd),rand_range(.5,size),11,level
end

	-- update particle
function update_part(obj)
		-- move particle to next level
	if obj.org_level~=level then
		obj.x+=cam.x
		obj.y+=cam.y
		obj.org_level=level
	end
	
	obj.x=obj.x+obj.vel_x
	obj.y=obj.y+obj.vel_y
	obj.radius*=0.95
	
	if(obj.radius<0.5)del_obj(obj)
end

	-- draw particle
function draw_part(obj)
	circfill(obj.x,obj.y,obj.radius,obj.color)
end


		--	⬆️ utility ⬆️ --
	-- create particles at object --

	-- particle object needs:
		-- x position - y position
		-- w width - h height
		-- color table
function new_part(obj,part,amm,layer,spd,min_size,max_size,top_level)
	layer=layer or 1
	
	for i=1,amm do
		local part=new_obj(particles[part],layer,
			rnd(obj.w*8)+obj.x,
			rnd(obj.h*8)+obj.y
		)
		
		part.color,part.top_level
		=
		rnd(obj.color),top_level
		if(min_size)part.radius=rand_range(min_size,max_size)
		if(spd)part.spd=rand_range(-spd,spd)
	end
end

	-- large particles
function large_part(obj,lay,top,spd)
	local size=obj.w+obj.h
	new_part(obj,2,10,lay or 3,spd or 2,.5+size,3+size,top)
end

	-- create large particle anywhere
function pos_large_part(col,x,y,lay,w,h,top)
	local p,w,h
	=
	{},w or 1,h or 1
 prop_init(p,
 	w,h,col
 )
 p.x,p.y
 =
 x+cam.x,y+cam.y
 
 large_part(p,lay,top)
end


		-- 😐 math 😐 --
	-- random between range
function rand_range(minf,maxf)
	return minf/2+rnd(maxf)
end
function real_rr(min, max)
	return rnd(max-min)+min
end
-->8
-- game states
max_level = 9
		-- ⧗ timers ⧗ --
	-- create new timer
	--on_del: function called on delete
function new_timer(amm,func,one_shot, repeats, on_del, draw, layer) --return true to end the cycle
	local timer={
		update=function(obj)
			if obj.amm==0then
			 if obj.repeats and obj.cycles>=obj.repeats then
			 	del_timer(obj)
				else
				 obj.amm=amm
				 obj.cycles+=1 --TODO could cause problems with int limit
				 if func(obj)or obj.one_shot then
					 del_timer(obj)
				 end
				end
			else
				obj.amm-=1
			end
		end,
		draw=draw
	}
	timer.amm,timer.cycles,timer.on_del,timer.repeats,timer.one_shot,timer.layer
	=
	amm,0,on_del,repeats,one_shot,(layer or 1)

	add(objs[layer or 1],timer)
	return timer
end

	-- delete timer
function del_timer(timer)
	if(not timer) return
	del(objs[timer.layer],timer)
	if (timer.on_del) timer.on_del()
end

	-- initialize game world
function _init_game()
		-- initial parts
	moves_counter,mouse,
	player_mode,lvl_y
	=
	bouncy_text("",10,12,10,9,true),new_obj(player_parts[1],7),
	2,0
 
 local old_draw=moves_counter.draw
	moves_counter.draw=function(obj)
		if(not hide_moves)old_draw(obj)
	end

		-- start first level
	events[2]=backgrounds[2]	
		-- snow particles
	for i=0,20 do
		new_obj(particles[3],3)
	end
	reset_level(level)
	--shockwave TODO
	make_player_ghost()
end


		-- ● game states ● --
	-- array of state functions
states={
		-- gameplay state
	{
			-- init
		function()
			_init_obj()
			_init_game()
			
			level_pal={11,3}
		end,
		
			-- update
		function()
			_update_objs()
		end,
				
			-- draw
		function()
				-- draw world
			cls()
			
			for_each(events) -- behind map
			
				-- draw map
			pal({[11]=level_pal[1],[3]=level_pal[2]})
		 map(lvl_x/8,lvl_y/8,lvl_x,lvl_y,level_map_x,level_map_y)
			palt(15,true)
			palt(0,false)
			
				-- draw objects
			_draw_objs()
			pal({[4]=136,[1]=129,[5]=133,[14]=140},1)
		end
	}
}
end_cutscene = false
boss_level = 10
	-- set level to original form then initialize
	-- use for changing levels
function reset_level(lvl)
		-- initialize everything
	init_level(lvl)
	if lvl == boss_level and not already_preboss then
		pre_boss_cutscene()
	end
end


		-- ☉ initialization ☉ --
	-- initialize a level as is
function init_level(lvl)
	if(end_cutscene) return
		-- set new entities
	level,lvl_x,lvl_y,enemies,level_ind,started
	=
	lvl,(lvl%8)*level_off,((lvl/8)&-1)*level_off,{},levels[lvl],false
	cam.x,cam.y
	=
	lvl_x,lvl_y
	
	del_timer(reset_timer)
	reset_timer=new_timer(100,function()
		started=true
	end,true)
	
		-- if level entry has script
	if level_ind then
		if(level_ind.bg)events[2]=backgrounds[level_ind.bg]
		moves,hide_moves
		=
		level_ind.moves or 10,level_ind.hide_moves
		
		local bgm=level_ind.bgm or 0
		if bgm and bgm~=cur_bgm then
			cur_bgm=bgm
			music(bgm,1000)
		end
		
		level_map_x,level_map_y,cam_mode
		=
		level_ind.map_x or 16,level_ind.map_y or 16,level_ind.cam_mode
	else
		moves,hide_moves,level_map_x,level_map_y,cam_mode
		=
		10,false,16,16,false
	end
	
		-- reset tiles
	foreach(spawn_cache[lvl],function(tile)
		mset(tile[1],tile[2],tile[3])
	end)
	spawn_objects()
	
		-- update camera
	camera(cam.x,cam.y)

		-- reset stats	
	if player then
		player.spr,player.flip_x,player.flip_y
		=
		player.sprites[1],false,false
	end
	shake=0
	set_moves(moves,true)
	
	if(level_ind and level_ind.func)level_ind.func()
end


		-- ⬅️ level table ➡️ --
	-- properties
levels={}

levels[0],
levels[1],
levels[2],
levels[3],
levels[4],
levels[5],
levels[6],
levels[7],
levels[8],
levels[9],
levels[10],
levels[11]
=
	-- title screen
{bg=1,bgm=-1,hide_moves=true,func=function()
		-- init title
	spr_popup(20,16)
	--function new_obj(obj,layer,x,y)	
	new_obj({
			-- init
		function(obj)
			obj.x,obj.y = 33,50
		end,
		
			-- update
		function(obj)
			
		end,
		
			-- draw
		function(obj)
			print("music by archonic", obj.x, obj.y, 6)
		end
	},1,x,y)
	--create_heart(50,50,true)
end},

	-- levels
{
	hide_moves=true,text="cell ONLINE - SELECT PROCEDURE#12#14|... cytotherapy.\n|PLEASE WAIT AFTER BEEP...#12#14|>5|cytotherapy READY. BE STILL#12#14|eliminate all red cells#8#2",
	bg=2,name="e n t r y",bgm=0
},
{text="ALERT - MINOR OVERHEATING#12#14|you're doing good, just...\n|don't exert yourself.\n|your hardware can't handle it.\n"},
{text="...\nwe're close to the artery.|ALERT - HAZARDOUS ENVIRONMENT#12#14|it's a little... worse... here.|be careful. keep going.", moves=9},
{
	moves=6, text="EXITING ENTRY...#12#14|you're doing good!|it'll be rough ahead, but-|...you can't hear me anyways.|*cough* just keep going.|ENTERING ARTERY...#12#14",
	name="a r t e r y"	
},
{moves=7, text="may i confide in you?|i'm fearful...|fearful this cure will fail.|the procedure isn't working.|keep going."},
{moves=7, text="is it possible?|could you succeed?|...|some hope remains, but...|it's getting worse..."},
{moves=6, text="you are nearing the…|*cough*|central organ.|don't stop now..."},
{moves=4, text="my arm...|it's... hurting?|cell, prepare for possible|*cough*|possible...|...|ugh...",bg=2, bgm=0},
{moves=6, text="oh my...|i'm quite parched...|could someone fetch me water?", bg=2, bgm=0},
{name="heart",bg=1,bgm=-1,hide_moves=true,func=function()
		-- init title
	--spr_popup(20,16)
	create_heart(32*8 + 64-16,  16*8 + 48,true)
end},
{map_x=32,map_y=16,cam_mode=true,hide_moves=true, bgm=22}

-->8
-- visuals/sfx

		-- ⧗ originals by munro ⧗ --
	-- passing cells
bg_col=1
bg_spd=1
backgrounds={
		-- passing cells
	function ()
		local r=t()
		
		srand()
		for j=0,60 do
			local y,k,x
			=
			rnd(120)+sin(r/3+rnd())*12,
			rnd(6)\1*12,(rnd(250)-r*rnd(100))%200-3
			circfill(x+cam.x,y+cam.y,rand_range(1,3),bg_col)
		end
	end,
	
		-- rotating cells
	function()
		cls()
		local f=sin(time()/10)/2-1.5
		
		for g=10,90,10do
			local n=time()/g*5
			line()
			color(bg_col)
			for i=0,g do
				local x,y=cos(i/g+n)-.3,sin(i/g+n)-.3
				local l=(i%2==0 and (g-5)*f*bg_spd or g*f*bg_spd)-32
				
				local global_x,global_y
				=
				x*l+cam.x,y*l+cam.y
				
				line(global_x,global_y)
				circfill(global_x,global_y,4)
			end
		end
	end
}


		-- ⧗ transitions ⧗ --
	-- transition objects
transitions={
		-- bubbly
	{
			-- init
		function(obj)
			obj.t,obj.c,obj.bsin,obj.bcol,obj.top_level
			=
			0,0,1,7,true
			dialogue_end_func = function() do_transition(obj) end
		end,
		
			-- update
		nil,
		
			-- draw
		function(obj)
			if obj.paused then
				cls(1)
				
				if obj.prompt and not obj.started then
						-- draw ❎ button prompt
					print("❎",115+cam.x,117+obj.bsin+cam.y,obj.bcol2)
					print("❎",115+cam.x,116+obj.bsin+cam.y,obj.bcol1)
					obj.bsin=sin(time())*2
					obj.bcol1,obj.bcol2
					=
					obj.bsin>0 and 6 or 7,obj.bsin>0 and 13 or 6
				end
				return -- delay
			end
			
			obj.t+=0.06
			local t=obj.t
			
		 obj.c=12+((t-2.55)/4)
		 		 
		 	-- if at middle - run function
		 if obj.c>11.97 then
		 	if not obj.transitioned then
			 	obj.paused
			 	=
			 	true
			 	del_obj(player)
			 	
			 	if(not obj.prompt)do_transition(obj)
			 	
			 	-- if at end, delete self
			 elseif obj.c>12.4then
			 	del_obj(obj)
			 end
		 end
		 
				-- render loop
		 for i=0,8 do -- column loop
		  for j=0,8 do -- row loop
		   local x,osc1,osc2
		   =
		   i*16+cam.x,
		   sin(t+i*0.1),
		   sin(t*.25+j*0.03)
	
		   local y=j*16+osc1*10+cam.y
		   circfill(x,y,osc2*15,1)
		  end
		 end
		end
	}
}

	-- do transition function
function do_transition(t)
	if(t.started)return
	t.started=true
	
	if(t.start_func)t.start_func()
	new_timer(t.delay,function()
		t.func()
		t.transitioned,t.paused
		=
		true,false
	end,true)
end


	-- start transition
function new_transition(trans,func,delay,prompt,start_func)
	local tran=new_obj(transitions[trans],4)
	tran.func,tran.top_level,tran.delay,tran.prompt,tran.start_func
	=
	func,true,delay or 0,prompt,start_func
	
	return tran
end


		-- ⬆️ text utilities ⬆️ --
	-- print text according to level
function print_b(text)
	print(text,cam.x,cam.y,7)
end

	-- few token text with outline
function outline(s,x,y,c,o)
	color(o)
	?'\-f'..s..'\^g\-h'..s..'\^g\|f'..s..'\^g\|h'..s,x+cam.x,y+cam.y
	?s,x+cam.x,y+cam.y,c
end

	-- center text around x
function text_center(x,s)
  return x-#s*2
end


		-- 🐱 camera utility 🐱 --
	-- shake screen
function shake_screen()
	if(shake==0)return
 local shake_x,shake_y
 =
 rand_range(-32,32),rand_range(-32,32)

 shake_x*=shake
 shake_y*=shake
 
 camera(cam.x+shake_x,cam.y+shake_y)
 
 shake=shake*0.8
 if shake<0.05 then 
 	shake=0
 	camera(cam.x,cam.y)
 end
end

	-- sfx priority
sfx_pri={}
sfx_pri[22],sfx_pri[3],sfx_pri[20],sfx_pri[21],sfx_pri[7],sfx_pri[6],sfx_pri[5],sfx_pri[4]
=
1,2,3,4,5,6,7,8


		-- ★ sfx ★ --
	-- play sfx
function play_sfx(fx)
	if(end_cutscene) return
	pri=sfx_pri[fx]or 1
	if(not sfx_pri[stat(46)] or stat(46)==-1 or pri>sfx_pri[stat(46)])sfx(fx,0)
end

-->8
-- player
	-- player behavior

	-- check if can move
function check_moves()
	if(moves==0)if((not moves_text or moves_text.deleted) and check_kill())moves_text=bouncy_text("out of moves!",text_center(64,"out of moves!"),64,10,9,true,true,5)
end

	-- check if can die
function check_kill()
	if#enemies>0 and not player.dead then
		kill(player)
		return true
	end
end

	-- fire a wire from the object
function fire_wire(par,targ_x,targ_y,spd,pull_st,cap)
	local pull_st,cap,follow_wire,flyable,kills
	=
		-- fly from wire
	pull_st or 0.02,cap or 7,
	function(o,amm)fly(par,o.x,o.y,amm or 1,true)end,
	can_fly(par,targ_x,targ_y),0
	if(not flyable and not par.player)return
		
	play_sfx(6)
	shake=0.1
	if(bounce)follow_wire(mouse)
	
		-- add tether
	local wire=add(par.wires,new_obj({
			-- init
		function(obj)
				-- initial momentum
			obj_to_pos(obj,targ_x,targ_y,spd)
			obj.st_x,obj.st_y,obj.color,obj.tick,obj.w,obj.h,
			obj.release
			=
			par.x,par.y,par.color,0,0,0,
			
				-- release wire function
			function(obj)
				local angle=look_at(obj.st_x,obj.st_y,obj.x,obj.y)
				obj.released,obj.landed,obj.vel_x,obj.vel_y
				=
				true,true,cos(angle)*spd,sin(angle)*spd
			end
		end,
		
			-- update
		function(obj)
			
				-- if object released
			if obj.released then
				obj.st_x+=obj.vel_x
				obj.st_y+=obj.vel_y
				
				if dist(obj.st_x,obj.st_y,obj.x,obj.y)<spd+3then
					large_part(obj,obj.layer)
					del_wire(par,obj)
				end

				-- if object active
			else
				local flying_or_dead=par.flying and not par.dead
				obj.st_x,obj.st_y
				=
				flying_or_dead and par.x or par.x+par.wh,
				flying_or_dead and par.y or par.y+par.hh
			
				obj.x+=obj.vel_x
				obj.y+=obj.vel_y
				
					-- if end of rope hit surface
				if bounce then
						-- pull player towards end
					if par.flying then
						par.vel_x-=(par.x-obj.x)*pull_st
						par.vel_y-=(par.y-obj.y)*pull_st
						
						local angle=look_at(par.x,par.y,obj.x,obj.y)
						par.rot=-angle
					
						par.vel_x,par.vel_y
						=
						mid(-cap,par.vel_x,cap),mid(-cap,par.vel_y,cap)
					end
				end
					-- if rope still flying
				if bounce or not obj.landed then
					obj.tick+=1
					if obj.tick>(bounce and 10 or 30)then
						obj:release()
					end
					
							-- check if hitting any enemies
					if par.player then
						foreach(enemies,function(en)
							if(not en.inv and kill_check(obj,en,12))kills+=1
						end)
					else
					
							-- check if hitting player if enemy
						kill_check(obj,player,9)
					end
				end
				
					-- check collision
				col_check(obj,function(_,side)
					if(obj.landed)return
					if flyable or par.flying then
						if(not bounce)follow_wire(obj,7)
					elseif par.player then
						check_moves()
					end
						
						-- combo
					if(par.player and kills>1)new_combo(kills,((obj.x+obj.st_x)*.5)-cam.x,((obj.y+obj.st_y)*.5)-cam.y)
					obj.vel_x,obj.vel_y,obj.landed,shake
					=
					0,0,true,0.1
					obj.x&=-1
					obj.y&=-1
					
					play_sfx(7)
					new_part(obj,1,3)
					if(bounce)obj:release()
				end,true)
			end
		end,
		
			-- draw line
		function(obj)
			line(
				obj.st_x,
				obj.st_y,
				obj.x,obj.y,obj.color[2]
			)
		end
	
	},1,par.x+par.wh,par.y+par.hh))

	new_timer(200,function()
		if(not player.flying)check_moves()
	end,true)
end


		-- ◆ player constants ◆ --
	-- player modes
player_modes={
		-- fly on click
	function()
		fly(player,mouse.x,mouse.y,5)
	end,
		-- grapple
	function()
		p_wire(player.flying and 8 or 7)
	end,
		-- phase 2
	function()
		p_wire(5,0.003)
	end
}

	-- switch player to phase 2
function player_phase_2()
	bounce,player_mode
	=
	true,3
end

	-- shoot a wire with some parameters
function p_wire(spd,pull,cap)
	if mouse.just_clicked then
		started=true
		rnd()
		pos_large_part('9,10',mouse.x-cam.x,mouse.y-cam.y,7,0,0,true)
	
		if(not hide_moves)set_moves()
		del_wires(player)
		fire_wire(player,mouse.x,mouse.y,spd,pull,cap)
		new_part(player,1,3)
	end
end

player_land_loc = nil
	-- player parts
player_parts={
		-- 😐 mouse cursor 😐 --
	{
			-- init
		function(obj)
			entity_init(obj,'1,2')
		end,
		
			-- update
		function(obj)
			obj.click=stat(34)
			
				-- follow camera
			obj.x,obj.y
			=
			stat(32)+cam.x,stat(33)+cam.y
			if(btnp(🅾️)) foreach(enemies, function(o) kill(o) end)

			
				-- debug
					-- todo - delete me
			
				-- mouse pressed
			if obj.click==1 then
				obj.spr=obj.sprites[2]
				
				obj.just_clicked=obj.old_click~=1
			else
				obj.spr=obj.sprites[1]
			end
			mouse.old_click=mouse.click
		end,
			-- draw
		entity_draw
	},
	
		-- ◆ player entity ◆
	{
			-- init
		function(obj)
			character_init(obj,'3,4,6','14,12')
			set_rot_sprs(obj,0,63)
			obj.wires
			=
			{}
		end,
			
			-- update
		function(obj)
				-- camera movement
			
			if cam_mode then
				cam.focus_x,cam.focus_y
				=
				player.x-64,player.y-64
				
				cam.x+=lerp(cam.focus_x,cam.y)
				cam.y+=lerp(cam.focus_y,cam.y)
				
					-- camera locking
					-- too lazy for pretty math
					-- do it yourself if bothered
				local x_len,y_len
				=
				(lvl_x+level_map_x*8)-128,
				(lvl_y+level_map_y*8)-128
				
				if(cam.x<lvl_x)cam.x=lvl_x
				if(cam.x>x_len)cam.x=x_len
				if(cam.y<lvl_y)cam.y=lvl_y
				if(cam.y>y_len)cam.y=y_len
				camera(cam.x,cam.y)
			end
			
				-- actual player code
			if(obj.dead)return
			if(obj.flying)col_check(obj,col_ply_stop)
			
			if not obj.flying or bounce then
				foreach(enemies,function(e)
					kill_check(e,obj,4+(e.w*2))
				end)
			end
			
				-- can move
			if moves>0 then
					-- left click
				if(mouse.paused)return
				if mouse.click==1then
					player_modes[player_mode]()
				end
			end
		end,
			
			-- draw
		entity_draw
	},
	{ --player ghost
		function(o)
			entity_init(o, 48)
			o.last_mx = -1
			o.last_my = -1
			player_ghost = o
			o.vel_x = 1
			o.vel_y = 1
		end,
	  --update
	  function(o)
		if (mouse.x ~= o.last_mx) or (mouse.y ~= o.last_my) and not (mouse.paused or player.wires[1]) then
			if mouse.x and player.x then
				o.x = player.x
				o.y = player.y
				local dir = atan2(mouse.x-player.x, mouse.y-player.y)
				o.vel_x,o.vel_y = cos(dir),sin(dir)
				for i=0,200 do
					if col_check(o, function() return end, false, true) then
						break
					end
				end
			end
		end
	  end,
	  function(o)
		if  not (mouse.paused or bounce or player.wires[1]) then
			line(player.x + 4, player.y + 4, o.x + 4, o.y + 4, 14)
			if (not (o.x == player.x and o.y == player.y)) spr(48, o.x, o.y)
		end
	  end
	}
}

--function new_obj(obj,layer,x,y)	
function make_player_ghost()
	new_obj(player_parts[3], 3, 0, 0)
end


	-- stop collision for player
function col_ply_stop(obj,side)
	if not bounce then
		col_fly_stop(obj,side)
	else
		local x,y
		=
		obj.x,obj.y
		
	 col_bounce(obj,side)
	 obj.vel_x*=.5
	 obj.vel_y*=.5
	 obj.rot=-look_at(x,y,x+obj.vel_x,y+obj.vel_y)
	end
	
	del_wires(obj)
	check_moves()
	shake+=.1
	play_sfx(20)
end


		-- ⬆️ utilities ⬆️ --
	-- initialize a player
	--function new_obj(obj,layer,x,y)
function init_player(x,y)
	player=new_obj(player_parts[2],3,x or 64,y or 64)
	player.player=true
	for i,ent in ipairs(entities) do --todo moving the ghost to the background doesnt work...
		if ent == player_ghost then
			del(entities, ent)
			add(entities, ent, i-1)
			break
		end
	end
end

	-- set moves and change ui
function set_moves(amm,part)
	moves=amm or moves-1
 moves_counter:change_text("moves - "..moves)
 
  -- particle effect
 if(not part)pos_large_part(moves_counter.color,moves_counter.x-8+moves_counter.len*4,moves_counter.y-2)
end
-->8
-- events
	-- ending, cutscenes, etc
	--player location during heart cutscene is about 2,26
	-- so the distance is about 594



already_preboss = false

		-- ░ ending ░ --

function pre_boss_cutscene()
	music(-1, 2000)
	mouse.paused = true
	local rec_dialogue = "cell... i know you will\nnever understand.|i know, despite your\nprotocols to cure me,|your digital cogs\ngrind up my words\nblindly as i speak.|but... my fate is inevitable\n|my time on this earth was...\nlimited...\nthe moment i laid on this bed.|life is a fragile thing.\ni'm luckier than i'll ever\nunderstand for a life lived.|i see you've made your way\nto the heart.|there is no turning back now.|free me, since the only\ncure is none.|cell...|eliminate all hostile entities."
	repeat_print(split(rec_dialogue, "|"), 1)
	already_preboss = true
	dialogue_end_func = function()
		mouse.paused = false
	end
end
--function typewriter_text(str, origin, clr, stopfunc, endfunc)
function boss_die_cutscene()
	end_cutscene = true
	music(-1)
	sfx(18)
	sfx(19)
	mouse.paused = true
	new_timer(0, function(self)
		if(self.cycles == 80) sfx(61)
	end, false, 260, function()
		typewriter_text("\npatient terminated\ndisease contained\n\ncell os version 0.5\na product of cre8\n\nengineered by:\nvirtuavirtue\narchonic\ntroubledkarma56\nshutting down.\^3.\^3.\^3", {cam.x, cam.y}, 12, function() end, function() stop() end) 
	end, function() cls(7) end, 5)
end
boss_maxhp = 4
	-- creates the heart boss
function create_heart(x,y,boss)
	sfx(60)
	local pulse,pulse_speed,off
	=
	2,1.5,4
	
	new_obj({
			-- init
		function(h)
			set_sspr(h,64)
			prop_init(h,3,4,'2,4,8')

			if boss then
				h.health,heart_boss,h.enemies,h.phase
				=
				boss_maxhp,h,{split'1,2,3',split'1,2,3,6,7'},0
			end
			h.hiding_y = h.y - 48
		end,
			-- update
		function(h)
			pulse+=sin(time()*pulse_speed)
		end,
			-- draw
		function(h)

			local off_sine=pulse+off
			off*=.95
			
			sspr_draw(h,off_sine,off_sine,24,32)

			if boss then
					-- not invincible
				if not h.inv then
						-- if hit
					kill_check(player,h,10,function()
						h.inv,shake,off
						=
						true,.2,20

						if cur_music~=16 then
							music(16,100)
							cur_music=16
						end
						h.health-=1
						h.phase=min(h.phase+1,2)
						large_part(h,3)
						sfx(5)

						if h.health==0 then
							boss_die_cutscene()
							return
						end

							-- start spawning enemies
						new_timer(40,function()
							h.hiding=true
							local i=0

								-- spawn loop
							del_timer(h.anim)
							h.anim=new_timer(40,function()
									-- return down
								if i==6*h.phase then
									del_timer(h.anim)
									h.hiding=false

									new_timer(40,function()
										large_part(h)

										h.hiding,h.inv,h.y
										=
										false,false,y

										large_part(h)

										h.anim=new_timer(30,function()
											local bubble=new_obj(entities[5],1,x+h.wh,y+h.hh)
											shake=.1
											large_part(bubble)
											sfx(7)
										end)
									end,true)
								end

								--local rand_spot={rand_range(cam.x + 30,cam.y+75),rand_range(cam.x+30,cam.y+75)}

								--while dist(rand_spot[1],rand_spot[2],player.x,player.y)<50 do
								--	rand_spot={rand_range(cam.y+30,cam.y+70),rand_range(cam.x+30,cam.y+70)}
								--end
								local spot = get_spawn_location()
								local ent=new_obj(entities[rnd(h.enemies[h.phase])],1,spot[1], spot[2])
								circfill(cam.x + 8, cam.y + 8, 10, 11)
								circfill(cam.x + 120, cam.y + 120, 10, 11)
								large_part(ent)
								sfx(7)
								i+=1
							end)
						end,true)
					end)

					-- hiding from player
				elseif h.hiding then
					h.y=h_lerp(h.y,h.hiding_y,3)
				end

				-- not boss
			else
				kill_check(player,h,10)
			end
		end,
		function()
			mouse.paused = true
			boss_die_cutscene()
		end
	},1,x,y)
end

function flag(x, y, flag)
	return fget(mget(x\8,y\8), flag)
end

--for heart biss enemies
function get_spawn_location()
	local x = real_rr(cam.x + 8, cam.x + 120)
	local y = real_rr(cam.y + 8, cam.y + 120)
	if(dist(x, y, player.x, player.y) < 35 or flag(x, y, 0)) return get_spawn_location()
	return {x,y}
end

function recovery_mode_dialogue()
	sfx(60, 1)
	local rec_dialogue = "your sensors... *cough*|are they detecting\nanything strange?|because my body feels...|feels sort of..."
	repeat_print(split(rec_dialogue, "|"), 1)
	dialogue_end_func = recovery_mode_shockwave
	mouse.paused = true
end

function recovery_mode_shockwave()
    sfx(-1,1)
	for i=48,50 do
		sfx(i)
	end
	local duration_1 = 130 --todo change this to 130
	local dur_2 = 36
	local radius_target = 600 --TODO adjust manually based on heart location relative to level location
	local shockwave_radius = 0
	new_timer(1, function()
			bg_spd -= 0.01
		end, false, duration_1, function()
			new_timer(30, function()
				shockwave_radius = 0
				sfx(56)
				new_timer(0, function()
					shake = 0.4
					bg_spd += 0.1
					shockwave_radius += radius_target/dur_2
				end, false, dur_2)
			end, false, 4, recovery_mode_bootup, function() --draw
				for i=0,5 do --todo change back to 5
					circle(cam.x + 128, cam.y + 128, shockwave_radius - i*7, 4, 10)
				end
			end, 5)
		end) --lerp
end

	-- recovery mode cutscene
function recovery_mode_cutscene()
	recovery_cutscene_active = true
	--slow down bg
	music(-1, 2000)
	new_timer(60, recovery_mode_dialogue, true) --todo undo this IMPORTANT
	--todo turn off particles
end
--function new_timer(amm,func,one_shot, repeats, on_del, draw)
function recovery_mode_bootup()
	shockwave_radius = -1 --TODO if the radius is not -1, could cause problems
	bg_col = 8
	sfx(17)
	local bios_ended = false
	local bios_end = function()
		new_timer(70, function()
			if not already_preboss then
			 next_level(boss_level, true)
			 sfx(44)
			 bios_ended = true
			end
		end, true)
	end
	new_timer(60, function() return true end, true, nil, function()
	 typewriter_text("cell os - rebooting\ninternal damage detected\nsome functions offline\n\ndiagnosing cause.\^3.\^3.\^3.\n\npulmonary emp emitted\nvirus lytic cycle triggered\n\n\fapatient termination required", {cam.x, cam.y + 7}, 4, function() return bios_ended end, bios_end)
	end, function() cls(8) end, 6)
end

type_spd = 2

function typewriter_text(str, origin, clr, stopfunc, endfunc)
	typewriter_timer = new_timer(type_spd, function(self)
		if(self.cycles <= #str) then
			if(str[self.cycles] ~= " ") sfx(10)
		else
			endfunc()
		end
		if(sub(str, self.cycles - 2, self.cycles-1) == "\^3") str = sub(str, 1, self.cycles - 3) .. sub(str, self.cycles, #str)
		if stopfunc() then
			endfunc()
			return true
		end
	end, false, nil, nil, function(self)
		cls(clr)
		print(sub(str, 1, self.cycles), origin[1], origin[2], 6)
	end, 6)
end


dialogue_actions = {
	function()
		sfx(51)
		cls(8)
		flip() --debug
	end
}
cur_action = 1
		-- ⧗ text utilities ⧗ --
	-- scrolling text
		-- todo - better sound effect
function new_scroll_text(text,x,y,c1,c2,prompt,func,holdparticles)
	holdparticles = holdparticles or text[1] == "cell... i know you will\nnever understand." --todo could cause issues
	if(text==nil)func()
	if text[1]==">"then
	  dialogue_actions[cur_action]()
	  cur_action+=1
	  new_timer(text[2]*10,func,true)
	else
	
	local full_lines=split(text,"\n")
	 
	 -- local variables instead of properties
	local tick,goal,prog,text_prog,make_part,right,left,prompt_pressed,part_controller
	=
	0,#text+1,0,"",
	
		-- create particles
	function(x)
		if(#full_lines>1)return
		rnd()
		if(not holdparticles) pos_large_part(c1..","..c2,x,y-1,6,0,0,true)
	end
		
		-- text left
	local function text_left(obj)
			-- delete text
		prog=1
		left=new_timer(0,function()
			tick+=1
			
					-- move text to right
			if prog+1~=goal and(not prompt or not btnp(❎))then
				if tick%2==0then
					local old_prog=text_prog
					text_prog,text_sub
					=
					sub(text,prog+1,goal),sub(text,prog,prog)
					
					obj.x+=4
					if(#split(old_prog,"\n")~=#split(text_prog,"\n"))obj.x=x

					if text_sub~=" "then
						play_sfx(10)
						if(not holdparticles) make_part(obj.x-(#text*2)+(prog*.5))
					end
					prog+=1
				end
				
				-- delete text
			else
				new_timer(0,function()
					del_timer(left)
					del_obj(obj)
					
					if func and not obj.called then
						func()
						obj.called=true
						
						if dialogue_end_func and prompts==0then --TODO could cause issues
							dialogue_end_func()
							dialogue_end_func=nil
						end
					end
				end,true)
			end
		end)
	end
	
	
			-- ⧗ text object ⧗ --
		-- create text
	return new_obj({
			-- init
		function(obj)
				-- global timer
			right,obj.top_level
			=
				-- move text to right
			new_timer(0,function()
				if prog~=goal then
					tick+=1
					if tick%2==0then
						local subs=sub(text,prog,prog)
						
						text_prog=text_prog..subs
						prog+=1
						if subs~=" "then
							play_sfx(9)
							if(not holdparticles) make_part(obj.center+(4*prog-1))
						end
					end
					
				else
					del_timer(right)
					
						-- wait 20 frames and delete
					if not prompt then
						new_timer(#text*4,function()
							text_left(obj) 
						end,true).top_level=true
					end
				end
			end),
			true
		end,
		
			-- check for button presses in prompt messages
		function(obj)
			obj.center=text_center(obj.x,text)
			
			if prompt and btnp(❎)and not prompt_pressed then
					-- if text isn't finished
				if prog~=goal then
					text_prog,prog
					=
					text,goal
					del_timer(right)
					return
					
					-- remove text to right
				else
					prompt_pressed,obj.finished
					=
					true,true
					text_left(obj)
				end
			end
		end,
		
			-- draw
		function(obj)
			local lines=split(text_prog,"\n")
			 -- draw each line
			for i,text_line in ipairs(lines) do
			 outline(text_line,text_center(i==1 and obj.x or x,full_lines[i]),obj.y+(7*(i-1)),c1,c2)
			end
		end
	},6,x,y-4)
	end
end


 -- bouncy text
function bouncy_text(text,x,y,c1,c2,top,scroll,lay)
 local chars,cur_i,vel_y,tim,lay,make_part
 =
 {},1,0,0,lay or 4,
 function(o,i)
 	rnd()
 	pos_large_part(o.color,o.x+(i*4),o.y+2,lay,0,0,top)
 end
 
 local obj=new_obj({
	  -- init
	 function(t)
	  chars,t.color,t.len,t.top_level
	  =
	  {},c1..','..c2,#text,top
	  
	   -- all characters
	  if not scroll then
		  chars=split(text,'')
		 else
		 	local i=0
		 	t.intro_timer=new_timer(1,function()
    	if i==#text+1 then
    		del_timer(t.intro_timer)
    		i=0
    		
    		local top_timer=new_timer(40,function()
	    		t.exit_timer=new_timer(1,function()
	    			if i==#text+1 or t.deleted then
	    				del_timer(t.exit_timer)
	    				del_obj(t)
	    			else
	    				make_part(t,i)
	    			end
	    			
	    			del(chars,text[i])
	    			i+=1
	    			x+=4
	    		end)
	    	end,true)
	    	top_timer.top_level=true
    	else
    		make_part(t,i)
    	end
    	add(chars,text[i])
    	i+=1
    end)
		 end
	 end,
	 nil,
	            
	     -- draw
	 function(t)
	  tim+=1
	  for i,c in ipairs(chars)do
	   outline(c,
	    x+(i-1)*4,
	    t.y+sin((tim+i)*.04)*2,
	    c1,c2
	   )
	  end
	 end
	},lay,x,y)
	
		-- change text
	obj.change_text=function(obj,new_text)
		text=new_text
		obj:init()
	end
	return obj
end


	-- add title popup
		-- todo - add more movement
function spr_popup(x,y)
	new_obj({
			-- init
		function(obj)
			obj.spr,obj.w,obj.h
			=
			67,11,4
		end,
		
			-- update
		function(obj)
			obj.y+=sin(time())*.6
		end,
		
			-- draw
		entity_draw
	},1,x,y)
end


	-- transition to next level
function next_level(lvl,no_transition,start)
	mouse.paused=true
	lvl=lvl or level+1
	
		-- level dialogue
	local lev,text,i=levels[lvl]
	
		-- try drawing level details
	if lev then
		text,i=split(lev.text,'|'),1
		
		if text then
			new_timer(40,function()
					-- prompts is amount of button presses
				prompts=#text
				
				repeat_print(text,i)	
			end,0)
		else
		 prompts=0
		end
	end
	
	local name_check=lev and lev.name
		
		-- create level transition
	if not no_transition then
		local lvl_trans=new_transition(1,function()
			
					-- change level
				change_level(lvl)
			end,name_check and 50 or text and 20 or 0,text,function()
				
					-- try level title
				if	name_check then
					new_scroll_text(lev.name,64,64,8,2)
				end
			end)
		
		if(start)lvl_trans.c=11.97
	else
		change_level(lvl)
	end
end

function change_level(lvl)
	level,mouse.paused
	=
	lvl,false
	if lvl == max_level + 1 then
		--bounce = true
		--player_phase_2 = true
		--recovery_mode_cutscene = false
	end
	if lvl <= max_level then dset(0, level + 1) end
	reset_level(level)
end

		-- ⧗ text utility ⧗ --
	-- repeat text for dialogue
function repeat_text(text,i)
	prompts-=1
	i+=1
	repeat_print(text,i)
end

	-- print text for dialogue
function repeat_print(text,i)
	if(i==1)prompts=#text
	local col=split(text[i],'#')
	if(col)new_scroll_text(col[1],64,64,col[2]or 10,col[3]or 9,true,function()repeat_text(text,i)end)
end

	-- create combo text
function new_combo(amm,x,y)
	local combo=bouncy_text(amm.." combo!",x,y,10,9,false,true,3)
	combo.update=function(o)
		o.y-=.3
	end
end

--utils

function circle(x,y,radius,border_weight, clr)
	radius = flr(radius)
	for i=0,border_weight do
		circ(x, y, radius + i, clr)
	end
end
__gfx__
00000000aaaaa9fff88888ff5ffffffffffffffffffffffff66ffffd2ffffffffffffffffffffffff8f8f8ffff8f8f8f8ffffff8ffffffff2f4f2ffff8ffff8f
00000000aaa9fffff888ffff55dddffffffffffffff5dddffd5566ff2f4f2fffffffffffff4f2fffff4888f88f4888fff88ff88fffffffff22422f48f4ffff4f
00700700aaaa9ffff8888fff5dc66cffffc66cffd55dc66cff55666f22422ffffff272fffff4422f4488884ff4888844f488884fff4884ff248842ffff2222ff
00077000a9aaa9fff8f888ffd66886fffd6886dfffd668866f66686f248842fff224242242248842f47884244488872fff8668fff888888f288772ff22477422
00077000a9faaa9ff8ff888fd66886fffd6886dfffd66886f6dd666f287227ffff28282fff4872272244472ff2744222ff4774fff486684f288772fff287782f
00700700a9faaaa9f8ff88885dc66cfffdc66cdfd55dc66cf6ddc6ff248842fff448784442248842f22222222222222ff422224ff247742f248842ff44888844
00000000fffa9a9fffff8f8f55dddffff5d66d5ffff5dddf5f66f56622422fffff24842ffff4422f2f2222ffff2222f2f22ff22ff222222f22422f48f248842f
00000000a9fffa9ff8ffff8f5fffffff555dd555ffffffff6fffffd62f4f2fff22222222ff4f2fffff2f2f2ff2f2f2ff2ffffff2ff2222ff2f4f2fff22222222
1233bb3fff3333fff3bb33211111111100011111111110001233bb3ff3bb3321ff3333fff3333fff3bbb33211233bb3f00000000ff4488ff0000000000000000
12333bb333bbbb33f3bb3221221122220111222222221110123bbbb33bbb3321f3bbbb333bbbb33f3bb332122123bb3f00000000f422228f0000000000000000
12333bb3bbbbbbbb3bb33211322223330122233333322210123bbbbbbbbb3321f3bbbbbbbbbbbbb33bb3322332233bb30000000042fff7280000000000000000
12233bb3bbb3333b3bb3321133333333112333bb333332111223bbbbbbb332213bb333bbbb33bbb33bb3333333333bb30000000042ffff280000000000000000
11233bb3333333333bb33221bb33333b1223bbbbbbb3322111233bbb333332113bb3333333333bb33bbb33bbb333bbb300000000824fff240000000000000000
11233bb3333222233bb33321bbbbbbbb123bbbbbbbbb332101222333333222103bbb332233333bb33bbbbbbbbbbbbb3f000000008244ff240000000000000000
1223bb3f222211223bb3332133bbbbb3123bbbb33bbb33210111222222221110f3bb332122233bb3f33bbb333bbbbb3f00000000f822224f0000000000000000
1233bb3f11111111f3bb3321ff33333f123bbb3ff3bb33210001111111111000f3bb33211233bb3ffff333fff33333ff00000000ff8844ff0000000000000000
ff444fff44ff444fffff444448844211f232222148844211112448841222232f11244884111111111111111111111111fff23ffffff22fffffff3bffff3bffff
328884448844888244448888488442214824421148844221122448841124428412244884211222211222211222222221fff3bffffff23fffffff3bffff3bffff
b32888888888882388888888f488442148844211488444211244884f1124488412444884322244222244222224444422fff3bffffff3bfffffff23bff333ffff
324448884488444288888444f488442148844221488844211244884f1224488412448884244444444444444244444444fff3bffffff3bffffffff23bb32fffff
24444444444444424444444448844221f4884421f4884421122448841244884f1244884f248884444488444288888444fff3bffffff3bfffffffff2332ffffff
32222442224422222444442248844211f4884421f4884421112448841244884f1244884f324888888888882388888888fff3bffffff3bfffffffffffffffffff
2211222212222112222222214824421148844221f488442111244284122448841244884f244488888888448244448888ffff3bffff3bffffffffffffffffffff
111111111111111111111111f232222148844211f48442211222232f112448841224884f44ff44444444ff44ffff4444ffff3bffff3bffffffffffffffffffff
ff8998ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff3bffff3bffff0000000000000000
f829928f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff3bffff3bffff0000000000000000
82f99f280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff3bff3bfffff0000000000000000
999ff9990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff23ff3bfffff0000000000000000
999ff9990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff2323ffffff0000000000000000
82f99f280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff23fffffff0000000000000000
f829928f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff0000000000000000
ff8998ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff0000000000000000
ffffffffffffff12ffff12ff111111111111111111111111111111111111111111111111111111fffffffffffff11111111fffffffffffffff4f2ff82f2444f4
fffffffff12ff1482ff1482f1222222222222222222222222222222222222222222222222222222fffffffffff1222222222ffffffffffff222442f4f247884f
ffffffff1482f1482ff1482f12222222222222222222222222222222222222222222222222222222fffffffff122222222222ffffffffffff248842f24888884
ffffffff1482f1482f14842f122444444444444444444444444224444444444444444442224444444fffffff12222224444444ffffffffff2488772f27866884
ffffffff14842148214842ff1224888888888888888888888882488888888888888888882488888888fffff1222222488888888fffffffff2488772f24877874
fffffffff148448844842fff122488888888888888888888882488888888888888888882488888888ffffff122222488888888fffffffffff248842f24844842
fffff22fff1488888882ffff12248888888888888888888882488888888888888888882488888888f2fffff22222488888888fffffffffff222442f4f242742f
ffff1842f148884444442fff1224888888888888888888882488888888888888888882488888888fff4fff41222488888888ffffffffffffff4f2ff82f2222f2
ffff14841248841222222fff1224888888888888888888824888888888888888888824888888882ffff888f1224888888882ffffffffffffffff4ffff4ffffff
fffff148248841244444422f122488888fff2fffff2ff122488888811111111fff1224888888ff2ffffffff1224888888ff4fffffffffffffffff4ffff4ff4ff
fffff1482488414888888442122488888fff4fffff2ff1224888888222222222ff1224888888ff4ffffffff1224888888ff8fffffffffffff44ff444444ff4ff
fff222482484244888444842122488888ff8ffffff4ff12248888882222222222f1224888888ff8ffffffff1224888888ff8fffffffffffffff4448888444fff
ff248888248424888412142112248888824fffffff8ff1224888888444444444441224888888fffffffffff122488888848ffffffffffffffff4488888844ff4
f1488888248424888124221f122488888ffffffffffff1224888888888888888888224888888ff8ffffffff1224888888ffffffffffffffff44448888884444f
f2488888248414888244882f122488888fffffffff8ff1224888888888888888888224888888fffffffffff1224888888fffffffffffffff4f446688888444ff
f248888824841448824422ff122488888ffffffffffff1224888888888888888888224888888fffffffffff1224888888fffffffffffffffff247788888442ff
f1448884248842488124482f122488888ffffffffffff1224888888888888888888224888888fffffffffff1224888888fffffffffffffffff244488886642ff
f124442248888448841222ff1224888881111111111ff1224888888888888888888224888888111111111ff122488888811111111111ffffff224444447722f2
ff1222248888888888421fff12248888822222222222f12248888881111111111f12248888882222222222f1224888888222222222222ffff22222444422222f
f12112488888888888842fff12248888822222222222212248888882222222222212248888882222222222212248888882222222222222ff2ff2222222222fff
f12224488888888888842ffff22488888444444444444422488888844444444444422488888844444444444422488888844444444444444ffff2222222222fff
122444888888888888842fffff24888888888888888888824888888888888888888824888888888888888888824888888888888888888888ff2ff222222ff22f
124444888888888888422ffffff248888888888888888888248888888888888888888248888888888888888888248888888888888888888fff2ff2ffff2fffff
124444888888888888422fffffff2488888888888888888882488888888888888888882488888888888888888882488888888888888888ffffffff2ffff2ffff
124444488888888888421ffffffff24888888888888888888824888888888888888888824888888888888888888824888888888888888fff0000000000000000
122444488888888888421ffffffffff48888888888888888888f48888888888888888888f48888888888888888888f48888888888888ffff0000000000000000
f1244444888888888421fffffffffffffff2fffff2ffff2ffffffff2fffffff4fffff2fffff2ffffffffff2ffffffffff2ffffffffffffff0000000000000000
f1224444488888888421fffffffffffffff4fffff4fffff48ffff84ffffffff8fffff4fffff4fffffffffff48ffffff84fffffffffffffff0000000000000000
ff12244444488884421fffffffffffffffff8fff8ffffffff8888fffffffffffffffff8fff8ffffffffffffff888888fffffffffffffffff0000000000000000
fff122244444444221fffffffffffffffffff888fffffffffffffffffffffff8fffffff888ffffffffffffffffffffffffffffffffffffff0000000000000000
ffff1122222222211fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
ffffff111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111710000000000000000000000000000000000000000000000000000000000000000
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
50009000e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
000000000000000000000000000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh00000000000000000000000000000000000
0000000000000000000000000hhh222222hh222222hh222222hh222222hh222222hh222222hh222222hh22222222hhh000000000000000000000000000000000
0000000000000000000000000h22233332222333322223333222233332222333322223333222233332222333333222h000000000000000000000000000000000
000000000000000000000000hh2333bb33333333333333333333333333333333333333333333333333333333333332hh00000000000000000000000000000000
000000000000000000000000h223bbbbbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbbb3322h00000000000000000000000000000000
000000000000000000000000h23bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb332h00000000000000000000000000000000
000000000000000000000000h23bbbb333bbbbb333bbbbb333bbbbb333bbbbb333bbbbb333bbbbb333bbbbb33bbb332h00000000000000000000000000000000
000000000000000000000000h23bbb30003333300033333000333330003333300033333hhh3333300033333003bb332h00000000000000000000000000000000
00000000000hhhhhhhhhhhhhh233bb30000230000002200000000000000000000000000hhh00000000003b003bbb332hhhhhhhhhhhhhh0000000000000000000
000000000hhh222222hh22222h23bb300003b000000230000000000000000000000000000000000000003b003bb332h322hh22222222hhh00000000000000000
000000000h2223333222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh000000000023bhhhhhhhh332222333333222h00000000000000000
00000000hh2333bb3333h22222222222222222222222222222222222222222222222222222200000000002h22222222233333333333332hh0000000000000000
00000000h223bbbbbb33h2222222222222222222222222222222222222222222222222222222000000000h22222222222b33333bbbb3322h0000000000000000
00000000h23bbbbbbbbbh22oooooooooooooooooooooooo22oooooooooooooooooo222ooooooo0000000h222222ooooooobbbbbbbbbb332h0000000000000000
00000000h23bbbb333bbh22o888888888888888888888882o88888888888888888882o8888888800000h222222o88888888bbbb33bbb332h0000000000000000
00000000h23bbb3hhh33h22o88888888888888888888882o88888888888888888882o88888888000000h22222o8888888833333003bb332h0000000000000000
00000000h233bb3hhh3bh22o8888888888888888888882o88888888888888888882o88888888020000022222o8888888800000003bbb332hhhhhhhhhhhhhh000
00000000h2333bb3hh3bh22o888888888888888888882o88888888888888888882o88888888000o000oh222o88888888000000003bb332h222hh22222222hhh0
00000000h2333bb3h3b0h22o88888888888888888882o88888888888888888882o88888888200008880h22o888888882000000003bb3322332222333333222h0
00000000h2233bb303b0h22o88888h002000022bbh22o888888hhhhhhhh000h22o88888800200000000h22o88888800o000000003bb3333333333333333332hh
00000000hh233bb32300h22o88888000o00000233h22o88888822222222200h22o88888800o00000000h22o888888008000000003bbb33bbbb33333bbbb3322h
00000000hh233bb33000h22o88888008000000o00h22o88888822222222220h22o888888008000000h0h22o888888008000000003bbbbbbbbbbbbbbbbbbb332h
00000000h223bb300000h22o888882o0000000800h22o888888oooooooooooh22o88888800000000hhhh22o888888o8000000000033bbb3333bbbbb33bbb332h
00000000h233bb300000h22o88888000000000000h22o88888888888888888822o888888008000000h0h22o888888000000000000003330hhh33333003bb332h
00000000h233bb300000h22o88888000000000800h22o88888888888888888822o88888800000000000h22o88888800000000000000230000002200003bb332h
00000000h2333bb30000h22o88888000000000000h22o88888888888888888822o88888800000000000h22o888888000000000000003b0000002300003bb322h
00000000h2333bb30000h22o88888h00000000000h22o88888888888888888822o88888800000000000h22o888888000000000000003b0000003b0003bb332hh
00000000h2233bb30000h22o88888hhhhhhhhhh00h22o88888888888888888822o888888hhhhhhhhh00h22o888888hhhhh33hhhh0003b0000003b0003bb332hh
00000000hh233bb30000h22o88888222222222220h22o888888hhhhhhhhhh0h22o88888822222222220h22o888888222223322222003b0000003b0003bb3322h
00000000hh233bb30000h22o88888222222222222h22o88888822222222222h22o88888822222222222h22o888888222222222222203b0000003b0003bb3332h
00000000h223bb30000hh22o88888ooooooooooooo22o888888oooooooooooo22o888888oooooooooooo22o888888oooooooooooooo03b0hhh3b00003bb3332h
00000000h233bb30000hhh2o88888888888888888882o88888888888888888882o88888888888888888882o8888888888888888888883bhhhh3b000003bb332h
00000000h233bb30000hhhh2o88888888888888888882o88888888888888888882o88888888888888888882o888888888888888888803bhhhh3b000003bb332h
00000000h2333bb30000hhh02o88888888888888888882o88888888888888888882o88888888888888888882o88888888888888888003bhhhh3b00hhh3bb323h
00000000h2333bb30000000002o88888888888888888882o88888888888888888882o88888888888888888882o88888888888888800003bhh3b00hhh3bb332hh
00000000h2233bb300000000000o88888888888888888880o88888888888888888b80o88888888888888888880o88888888888880000023003b00hhh3bb332hh
00000000hh233bb30000000000000002000002000020000000020000000o000002000002000000000020000000000200000000000000002323000hhh3bb3322h
00000000hh233bb3000000000000000o00000o00000o800008o00000000800000o00000o00000000000o80000008o0000000000000000002300000hh3bb3332h
00000000h223bb30000000000000000080008000000008888000000000000000008000800000000000000888888000000000000000000000000000003bb3332h
00000000h233bb30000000000h000000088800000000000000000000000800000008880000000000000000000000000000300000000000000000000003bb332h
00000000h233bb3000000000hhh00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332h
00000000h2333bb3000000000h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb322h
00000000h2333bb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332hh
00000000h2233bb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332hh
00000000hh233bb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb3322h
00000000hh233bb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb3332h
00000000h223bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb3332h
00000000h233bb30000000000000000000000000000000000000h000000000000000000000000000000000000000000000000000000000000000000003bb332h
00000000h233bb3003333000000000000000000000000000000hhh00000000000000000000000000000000000000000000000000000000000000000003bb332h
00000000h23bbbb33bbbb3300000000000000000000000000000h000000000000000000000000000000000000000000000000000hhh000000000000003bb322h
00000000h23bbbbbbbbbbbb3000000000000000000000000000000000000000000000hhh0000000000000000000000000000000hhhhh0000000000003bb332hh
00000000h223bbbbbb33bbb300000000000000000000000000000000000000000000hhhhh00000000000000000000000000000hhhhhhh000000000003bb332hh
00000000hh233bbb33333bb300000000000000000000000000000000000000000000hhhhh00000000000000000000000000000hhhhhhh000000000003bb3322h
000000000h23233333333bb300000000000000000000000000000000000000000000hhhhh00000000000000000000000000000hhhhhhh000000000003bb3332h
000000000hhh222222233bb300000000000000000000000000hhh0000000000000000hhh0000000000000000000000000000000hhhhh0000000000003bb3332h
00000000000hhhhhh233bb30000b000000000000000000000hhhhh00000000000000000000000000000000000000000000000000hhh000000000000003bb332h
0000000000000000h233bb30l000000000000000000000000hhhhh00000000000000000000000000000000000000000000000000000000000000000003bb332h
0000000000000000h2333bb3llddd00000000000000000000hhhhh00000000000000000000000000000000000000000000000000000000000000000003bb322h
0000000000000000h2333bb3ldc66c00000000000000000000hhh00000000000000000000000000000000000000000000000000000000000000000003bb332hh
0000000000000000h2233bb3d66886000h000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332hh
0000000000000000hh233bb3d668sssshhh00000000000000000000bb0000000000000000000000000000000000000000000000000000000000000003bb3322h
0000000000000000hh233bb3ldc66c00ssssss00000000000000000bb0000000000000000hhh000000000000000000000000000000000000000000003bb3332h
0000000000000000h223bb30llddd000000000ssssss0000000000000000000000000000hhhhh00000000000000000000000000000000000000000003bb3332h
0000000000000000h233bb30l0000000000000000000ssssss0000000000000000000000hhhhh000000000000000000000000000000000000000000003bb332h
00000000000hhhhhh233bb3000000000000000000000000000ssssss0000000000000000hhhhh000000000000000000000000000000000000033330003bb332h
000000000hhh22222h23bb3000000000000000000000000000000000sssssss0000000000hhh00000000000000000000000000000000000003bbbb333bbb332h
000000000h22233332233bb3h00000000000000000000000000000000000000ssssss000000000000000000000000000000000000000000003bbbbbbbbbb332h
00000000hh2333bb33333bb3hh0000000000000000000000000000000000000000000ssssss00000000000000000000000000000000000h03bb333bbbbb3322h
00000000h223bbbbb333bbb3h00000000000000000000000000000000000000000000000000ssssss0000000000000000000000000000h3h3bb33333333332hh
00000000h23bbbbbbbbbbb300000b0000000000000000000000000000000000000000000000000000sssssss0000000000000000000000h03bbb3322333222h0
00000000h23bbbb33bbbbb300000000000000000000000000000000000000000000000000000000000000000ssssss0000000000000000000899832h2222hhh0
00000000h23bbb30033333000000000000000000000000000000000000000000000000000000000000000000000000ssssss0000000000008299282hhhhhh000
00000000h233bb30000220000000000000000000000000000000000000000000000000000000000003808080000000000000ssssss0000082399328aaaaa9000
00000000h2333bb3000230000000000000000000000000000000000000000000000000000000000080o88800000000000000000000sssss999bb999aaa900000
00000000h2333bb30003b000000000000000000000000000000000000000000000000000000000000o8888oo00000000000000000000000999ss999aaaa90000
00000000h2233bb30003b00000000000000000000000000000000000000000000000000000000000oo8887230000000000000000000000082b99328a9aaa9000
00000000hh233bb30003b00000000000000000000000000000000000000000000000000000000000027oo2220000000000000000000000008299282a90aaa900
00000000hh233bb30003b00000000000000000000000000000000000000000000000000000000000222222200000000000000000000000003899832a90aaaa90
00000000h223bb30003b000000000000000000000000000000000000000000000000000000000000002222020000000000000000000000003bb3332h00a9a900
00000000h233bb30003b0000000000000000000000000000000000000000000000000000000000000202020000000000000000000000000003bb332a9000a900
00000000h233bb30003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332h00000000
00000000h2333bb3003b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb322h00000000
00000000h2333bb30333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332hh00000000
00000000h2233bb3b320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332hh00000000
00000000hh233bb33200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bb3322h00000000
00000000hh233bb30000000000000000000000000000000000000000000000000000000000000h00000000000000000000000000000000003bb3332h00000000
00000000h223bb30000000000000000000000000000000000000000000000000000000000000hhh0000000000000000000000000000000003bb3332h00000000
00000000h233bb300000000000000000000000000000000000000000000000000000000000000h000000000000000000000000000000000003bb332h00000000
00000000h233bb300033330003333000000000000000000000000000000000000000000000000h000000000000000000000000000000000003bb332h00000000
b0000000h23bbbb333bbbb333bbbb33000000000000000000000000000000000000000000000hhh000000000000000h0000000000000000003bb322h00000000
00000000h23bbbbbbbbbbbbbbbbbbbb3000000000000000000000000000000000000000000000h00000000000000000000000000000000003bb332hh00000000
00000000h223bbbbbbb3333bbb33bbb3000000000000000000000000000000000000000000000000000000000000000000000000000000003bb332hh00000000
00000000hh233bbb3333333333333bb300000000000000000000000h000000000000000000000000000000000000000000000000000000003bb3322h00000000
000000000h2223333332222333333bb30000000000000000000000hhhhh000000000000000000000000000000000000000000000000000003bb3332h00000000
000000000hhh22222222hh2222233bb300000000000000000000000hhhhh0000000000000000000000h000000000000000000000000000003bb3332h00000000
00000000000hhhhhhhhhhhhhh233bb300000000000000000000000hhhhhhh00000000000000000000000000000000000000000000000000003bb332h00000000
000000000000000003000000h233bb300000000000000000000000hhhhhhh00000000000000000000000000000333300003333h00033330003bb332h00000000
000000000000000000000000h2333bb30000000000000000000000hhhhhhh0000000000000000000000000hhh3bbbb3333bbbb3333bbbb333bbb332h00000000
000000000000000000000000h2333bb300000000000000000000000hhhhh0000000000000000000000000hhhh3bbbbbbbbbbbbbbbbbbbbbbbbbb332h00000000
000000000000000000000000h2233bb3000000000000000000000000hhh00000000000000000000000000hhh3bb333bbbbb3333bbbb3333bbbb3322h00000000
000000000000000000000330hh233bb300000000000000000000000000000000000000000000000000000hhh3bb333333333333333333333333332hh00000000
000000000000000000000330hh233bb3000000000000000000000000000000000000000000000000000000hh3bbb33223332222333322223333222h000000000
000000000000000000000000h223bb300000000000000000000000000000000000000000000000000000000003bb332h2222hh222222hh222222hhh000000000
000000000000000000000000h233bb30000000000000hhh0000000000000000000000000000000000000000003bb332hhhhhhhhhhhhhhhhhhhhhh00000000000
000000000000000000000000h233bb3000000000000hhhhh000000000000h00000000000000000000033330003bb332h00000000000000000000000000000000
000000000000000000000000h2333bb3b0000000000hhhhh00000000000hhh00000000000000000003bbbb333bbb332h00000000000000000000000000000000
000000000000000000000000h2333bb300000000000hhhhh000000000000h000000000000000000003bbbbbbbbbb332h00000000000000000000000000000000
000000000000000000000000h2233bb3000000000000hhh0000000000000000000000000000000003bb333bbbbb3322h00000000000000000000000000000000
000000000000000000000000hh233bb30000000000000000000000000000000000000000000000003bb33333333332hh00000000000000000000000000000000
000000000000000000000000hh233bb30000000000000000000000000000000000000000000000003bbb3322333222h000000000000000000000000000000000
000000000000000000000000h223bb3000000000000000000000000000000000000000000000000003bb332h2222hhh000000000000000000000000000000000
000000000000000000000000h233bb30000000000000000000000000000000h0000000000000000003bb332hhhhhh00000000000000000000000000000000000
000000000000000000000000h233bb3003333000000000000000000000000hhh000000000000000003bb332h0000000000000000000000000000000000000000
000000000000000000000000h23bbbb33bbbb3300000000000000000000000h0000000000000000003bb322h0000000000000000000000000000000000000000
000000000000000000000000h23bbbbbbbbbbbb300000000000000000000000000000000000000003bb332hh0000000000000000000000000000000000000000
000000000000000000000000h223bbbbbb33bbb300000000000000000000000000000000000000003bb332hh0000000000000000000000000000000000000000
000000000000000000000000hh233bbb33333bb300000000000000000000000000000000000000003bb3322h0000000000000000000000000000000000000000
0000000000000000000000000h22233333333bb300000000000000000000000000000000000000003bb3332h0000000000000000000000000000000000000000
0000000000000000000000000hhh222222233bb300000000000000000000000000000000000000003bb3332h0000000000000000000000000000000000000000
000000000000000000000000000hhhhhh233bb30000000000000000000000000000000000000000003bb332h0000000000000000000000000000000000000000
00000000000000000000000000000000h233bb30003333000033330000333300003333000033330003bb332h0000000000000000000000000000000000000000
00000000000000000000000000000000h23bbbb333bbbb3333bbbb3333bbbb3333bbbb3333bbbb333bbb332h00000000000000000000000b0000000000000000
00000000000000000000000000000000h23bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb332h0000000000000000000000000000000000000000
00000000000000000000000000000000h223bbbbbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3322h0000000000000000000000000000000000000000
00000000000000000000000000000000hh233bbb3333333333333333333333333333333333333333333332hh0000000000000000000000000000000000000000
000000000000000000000000000000000h2223333332222333322223333222233332222333322223333222h00000000000000000000000000000000000000000
000000000000000000000000000000000hhh22222222hh222222hh222222hh222222hh222222hh222222hhh00000000000000000000000000000000000000000
00000000000030000000000000000000000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhh0000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000001010101010101010101010101000000030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1c1c1c1413131313131313151c1c1c1c141313131313151c141313131313131514131313131313131313131313151c1c1c1c1c1c1413131313131315141313151413292b2b2a131514131313131313151c1c14131313131514132b2b2a1313151c1c14292a131514292b2a151c1c1c1c1c1c1c14131313292a1500001c1c1c1c
1c14131b2c2d000000002e1a13151c1c102d000000001a131b2f000000002e1210000000002e2f000a002c2d0c121c1c1c1c1c1c100000000000001210000012102d000000000a1a1b0000002e2f0c121c1c103d0000002410000000000000121c1c100000002410000000241c1c1c1c1c1c1c100c2e2f00001200001c1c1c1c
1c103d002e2f000000000000001a1315102f000000002e2f0000000000000012100c00000000000000002e2f00121c1c14292a131b0000000000001a1b0a0012102f000000000000000000000000001214131b000000002310000a000000001214131b00000025270000002314292a151c1c1c1611190000001a292b2b2a151c
1c1000000000000000000000002c2d12100c000000000000000000000000001216111900000000000000001811171c1c1000002c2d0000181900002c2d00002510000018111900000000181119000012270000000000001a1b00000000000024102c2d000000252800000012102e2f241413151c1c1000000a0000000000241c
1c1000000000000000000000003c3d121619000000000000001811190000181714131b000000000a0000001a1313151c1000002e2f000c121000003c3d000023100000121c10004f0000121c10000024260000000000002e2f0000005f000025282e2f000c0012260000001210000023272e121c1c161900000000000000121c
1c1000000000000000000000000000121c1000000000000000121c100000121c102c2d000000000000000000002e1a151000001811111117100000181900001210000012141b000000001a1510000025100000000000000000000000000000252600001811111716190000121000001228001a13151c1620211900000000121c
1c161900000000000000000000000012141b00000a000000001a131b00001a15103c3d00181900000000000000002c121000001a131313131b000012100c00121000001a1b2f000000002c1a1b000023100500000000000000001811190000251000001a292b2a131b00001a1b00001226002c2d1a151c1c1c2700004f00121c
1c1c10050000000000000000000000121000000000000000002e2f0000002c1210000000121005000018190000003c12100000002e2f2c2d0000001216111117100000000000000000002e2f00000012100000000a0000000000121c10000023100000000000002e2f0000000000001210003c3d00241c1c1c2600000000121c
1c141b000000000000000000000018171005000000181900000000000a002e12100000001a1b000000121000000000121005000000003c3d0000001a1313131510050000000000000000000000000012100000000000000000001a131b00001210050000000000000000000000000c241005000000251c1c1c1000000000241c
1c102d000000000000000a000000121c10000000001a1b000018111900000012100000002e2f0000001a1b000000001210000018190000181900000000002e121000001819000000000000181900002410000000181111190000002c2d000012100000000000000000000000000000251000000000231c1c1c1000000000251c
1c102f0000000000000000000000121c16190000002c2d0000121c10000018171619000000000000002c2d000000001210000012100000121000000c000000121000001216190000000018171000002527000000241c1c270000002e2f0000122700001820222111111120211900002527000000001a292a151619000000231c
1c16111900000000000000000000121c1c100000003c3d00001a131b0000121c1c161111111900000a3c3d000018111716111117270000121611111120211117270000121c1000000000121c1000002528000000231c1c26000000181120211726000012141313151413292a1b00002528000000000000001a131b000000121c
1c1c1c1000000000000000181111171c141b00000000000000002c2d00001a151c1c1c14131b000000000000001a13151c1c1c1c2600001a13131313151c1c1c2800001a131b000000001a131b000023280000001a13131b000000121c1c1c1c1000001a1b2c2d12102f00000000002526000000004f0000000000000000121c
1c1c1c1000000000000018171c1c1c1c100000000000000000002e2f00002e121c1c1c103d0000000000000000000c121c1c1c1c10000000002e2f00121c1c1c2600002c2d00000000002c2d00000012260000002c2d0000000a00241c1c1c1c10000000003c3d1210000a00000000231620211900000000000000000018171c
1c1c1c16190000000000121c1c1c1c1c1000000000000c1811190000000000121c1c1c100c00000000000a00000000121c1c1c1c1000000000000a00121c1c1c1000003c3d000018190c2e2f00000012100000003c3d0000000000231c1c1c1c1619000000000c1210000000001811171c1c1c10000000000000000000121c1c
1c1c1c1c161111111111171c1c1c1c1c16111111111111171c161111111111171c1c1c161111111111111111111111171c1c1c1c1611111111111111171c1c1c161111111111111716112022211111171620211111202222211111171c1c1c1c1c162022222221171620222221171c1c1c1c1c16111111202222222211171c1c
1c1c1413151c14292b2b2b2a151c1c1c14292a131313292a1313131514292a151c1c1c1413131313131313151c1c1c1c1313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313151413131313131313131313131313131514131313131313131313131313131315
1c141b2e121c100000000000241c1c1c1000002e2f0000003c3d2c12100000121c14131b2c2d000000002e1a13151c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c103d18171c161900000000231c1c1c100000000000000000003c12100000121c103d002e2f000000000000001a13150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c16111714131527000000001a131315270000181900000000000024100000121c1000000000000000000000002c2d120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c1c1c1c1000122600004f00002c2d12280000121005000000000025100000121c1000000000000000000000003c3d120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c1413151611171000000000003c3d12260000121000000000000023100000121c1000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c272e1a292b2a1b00000000004f0012100000121611111909000012100000121c1619000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c2600000000000000000000000000241000001a292a131b0000001a1b0000121c1c10050000000000000000000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c1000000000000000000000000000232700000000002c2d00000000000000121c141b000000000000000000000018170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121005000000000000000000000000001210050000000000000000000000000012
1c1005000000000000182022211900122600000000003c3d000000004f0000121c102d0000000000000000000000121c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c10000018190a000023141315161117100000181111111111111900001811171c102f0000000000000000000000121c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c2700001a1b000000231000121c1c1c1000001a131514292a131b00001a13151c16111900000000000000000000121c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c2600002c2d00000023161117141315100000000c1a1b00003c3d00002e2f121c1c1c1000000000000000181111171c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c1611193c3d0000001a151c141b0012100000000000000000000000000000121c1c1c1000000000000018171c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c1c1c100c000000003c121c103d001210000000001819000000000000000c121c1c1c16190000000000121c1c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121000000000000000000000000000001210000000000000000000000000000012
1c1c1c16112222221111171c16111117161111111117162021111111202221171c1c1c1c161111111111171c1c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000121611111111111111111111111111111716111111111111111111111111111117
__sfx__
010f00003f6123f61523600236001e600226002360017600286000000025600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10a00001817319100051000210000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
511000000d67500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0600000407307775097710477306001000010100301003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d05000022173170711f173130711717310071121730d071040750717302173007050570505700001000010100101001010010100101001010010100101001010010100101001010010100101001010010100101
140700001a17313073151730f073111730c0730d17308073061030000301005007050570505705001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
0d05000006071117710b77118771137711f7711a77114771000000000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
15050000130730b07118071050710c071080710000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0b00000000103001060010a0010f001140011700119001000210904104051170610f0611d0711607120071170711e071140711a0710f06114061090510b0410402100001000010000100001000010000100001
0c0500000a17500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
0d0400000c075001000e1000010000100001000e1000010000100001000e1000010000100001000e1000010000100001000e1000010000100001000e1000010000100001000e1000010000100001000e10000100
251400200006300063000630006300063000630006314073000630006300063000630006300063000630006300063000630006300063000630006300063140730006300063000630006300063000630006300063
0c0a00200b653000000000100001126410000000001080710b644000000000100001126440000005062000620b653000000000100001126410000000001080710b64400000000010000112644000000506200062
841400000206102062020620206202062020620507105072050720507205072050720406104062040620406204062040620406204062040620406204062040620406204062040620406202072010720007200072
841400000206102062020620206202062020620506105062050620506205062050620907109072090720907209072090720907209072090720907209072080610705106051050410404103031020310102100015
84140000020610206202062020620206202062050610506205062050620506205062010710107201072010720107201072010720107201072010720107201061020510305106041090410c05110051160611c073
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1310000018360183601836018360183601836018360000000c000100001300017000180001800018000180000c055100551305517055180551804518030180150000500000000000940009400094000000000000
01080000000003d65035650000002e65037650366502b650000003f6503e6503f6503f6503e6503f6503f6503f6503f6503e6503e6503e6503d6503c6503c65039650376503465033650306502b6502865024650
010800000000000000000000000000000000000000000000340543405134051340513405134051340513405134051340413404134041340413403134031340313402134021340213402134021340113401134011
0d0400000105307053150410c041180310b7211172104711010150600100001007050570505700001000010100101001010010100101001010010100101001010010100101001010010100101001010010100101
0d0700000507301071000730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d0a00000007300773000000000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010600000c6540c6410c6310c62500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a51400000e1551115515155181551a1551a1451a1351a1150e1551115515155181551a1551815515155111550e1551115515155181551a1551a1451a1351a1150e1551115515155181551a155181521d15118155
151400000c6150c6250c6150c6250c6150c6250c6150c6150c6150c6250c6150c6250c6150c6150c6250c6150c6350c6250c6250c6150c6350c6250c6450c655308550c955308550c9550c9530c9530c9530c953
d51400002650226502005020050200502005020050200502005020050200502005020050200502265022650226502295022d5022f5023050232502325023250226532295322d5323053232541305523555230562
3d1400000231202312023120231202312023120231202312053220532205322053220532205322053220532209332093320933209322093320932209332093220c3520c3520c3520c3520e3510e3520e3520e353
0d140000189520000000000000002484224813248130000024952000001895200000248322482324813000001895200000000000000024842248132481300000189520c655189520000018933189231897318973
d51400000e1551a155181551515515100181001a100181000e1551a15518155151550c1450c1550c1650c1750e1551a155181551515515100181001a100181000e1551a15518155151551c1521c1521f1521f153
851400000232102321023210232102321023210232302325053310533100321003210232102321023210232105331053310533205332053310530005334053050533105332053320533209341093420934209341
931400000b200002002f0232f0232f0132f0132f0132f0232d2002f20032023260231a023260233202332023300002f00030023300232402324023180231802300000000002f0232d023260232b0132901329023
8c14000015073110620e0521106215071110620e0521106015073110600e0501106015070110600e050110600c0531006013072100620c0521006011070100600c05310060130711006013072100620e05214070
8c14000015053110420e0321104215061110420e0321104015053110400e030110400c0300c0320e0420e04115053110420e0321104215061110420e0320c04015053110400e030110400c0300c0321805218051
811400000234002300023400234002340023000234002343053000530002345023000234002340023430230000340023000034000340003400230000340003430530005300003450230000340003400034302300
93140000260231a023260231a02326023260232602326023260232602332023320232602326000260232600024023240232402324023240232402324023240232b0232b0232b0232b0232c0232c0232c0232c023
d1140000264302643526430264352643226435264352640518432184351843218435184321843518432184351a4321a4351a4321a4351a4321a4351a4321a4351843500005184450000518452000051846500005
0d0a002018625186251861518615186151862518625186252484024845186001860018600186001860018600186251862518625186251861518615186251862524840248451860018600260231a0002602318600
0c140000139520000000000000002484224813248130000024952000001895200000248322482324813000001595200000000000000024842248132481300000189520c655189520000018625186351864518655
44140000267401a7421d7422174226730267302674226740287412874228742287402b7502b7502b7522b75224740247452473500000247452473024735247451875018750187521874218732187211873118750
d5140000264202642526420264252642226425264252640518422184251842218425184221842518422184251a4221a4251a4221a4251a4221a4251a4221a4251842500005184351875018442207521f4551f753
45140000267401a7421d7422174226730267302674226740287412874228742287402b7502b7502b7522b7522d7402d7452d7352d7502d7452473024730247452875028755287552874228735267212673526753
4514000029751297422974229732297322972229712297121d7011d7011d7011d7011d7011d7011d7011d70100701007010070100701007010070100701007010070100701007010070100701007010070100701
8d140000267522d7423075529700297002970024750247552b75028752247522470000700007000070000700267502d7523575200700000000000037750377003975039752397523975237751377513775237753
01090000306500c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000e9000c9000c9000e9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c9000c90000000
d51400000e1551115515155181551a1551a1451a1351a1150e1551115515155181551a1551815515155111550e1551115515155181551a1551a1451a1351a1150e1551115515155181551a155181521d15118155
8d14000035744327403474028700287002b700327451f700347402f74237742247002870026700347401a70032740327423274232744327422674132742327451a70000000000001a70000000000000000000000
0d1400001a7461d73621726267261a7261d73621736267461a7461d73621726247261a7261d73621736247461a7461d73621726247261a7261d7362173624746187461c7361f72618726187261c7361f7361c746
0f1400000d621096210862109621096210a6210a6210b6210f6210f6210d6210b6210b6210e62112621176211e62123621286212b6212b6212c6212d6212e621306213462136621386213a6213b6213d6213d621
011400000051000511005110051100511005210052100521005210052100521005310053100531005310053100531005310053100531005410054100541005410054100551005510055100551005710057100571
911400003400034000340003400034000340003400034000340003400034000340003401134011340113401134011340113401134011340213402134021340313403134031340313404134051340513406134071
010c00001805018050180501805024050240502405024050300503005030050300500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4e1400200c6110c6110c611186110c6110c6110c6110c6110c6110c611186110c611186110c6110c6110c61118611186111861118611186111861118611186111c6111c6111c6111c6111c6111c6111c6111c611
cd281000150751c005150751c0051c00515055150451c005200750000520045000052002500005200150000500005000050000500005000050000500005000050000500005000050000500005000050000500005
cd140000110651c00511065110451c00511065110451c00510000110651c00511055110351c005110351103510075000051006500005100550000510055000051004500005100000000010000000051002500005
cd280000150751c005150751c0051c00515055150351c0051407500005140450000514025000051401500005156251c605156251c6051c60515625156251c6051462500605146250060514615006051461500605
00040000006000c650216502165021650216502167021650216501f6501a6501765014650136501f65020650216500c6500e650126501565015600156001c60014600286002860032600286003b6503b6503b650
015000000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000c6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
613c00001512515125151251512515125151250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013c00001512515125151251512515125151251412514115141151411500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11140020001630c103001530000000000000000000000000001630c103001530000000000000000000000000001630c103001530000000100000000000000000001630c103001530010000000000000010000000
011400003004530035300253001500000000000000000000300453003530025300150000000000000000000030045000003004530000300450000030045000003003430031300313004130041300513005130051
613c0c001810518105181051810518105181051810518105141151412514135141451810518105181051810518105181051810514100141001410014100141001410014100141000000000000000000000000000
cf5000001052513535175451a5451c5351c5251c5251c5151052513535175451a5251c5151a525135150e51517530175211752117521175211751117511175110050000500005000050000500005000050000500
__music__
00 5819181b
01 631d1e1c
00 2f1d1e1c
00 2320221c
00 2320221c
00 211d1e1c
00 211d1e26
00 65242225
00 65282225
00 24252227
00 23282225
00 24252229
00 282a2225
00 2422252b
00 24222d25
02 222e2d25
00 410b654d
01 410b254d
00 410b650d
00 410b4c0e
00 410b250d
02 410b250f
01 40347444
00 40353444
00 40377834
00 40363534
00 3e363734
00 4036343a
00 4036343b
00 40343c40
00 40343c3f
02 403c3d34
00 30313c44

