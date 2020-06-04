-- Parameters

local GRIP = 8 -- On road maximum linear and lateral acceleration, in nodes/s^2
local ORGRIP = 5 -- Off road maximum linear and lateral acceleration, in nodes/s^2
local SZTORQ = 22 -- Car speed where motor torque drops to zero, in nodes/s
local DRAG = 0.04 -- Air drag
local ROLRES = 0.6 -- Rolling resistence, in nodes/s^2
local ORROLRES = 1.8 -- Off road Rolling resistence, in nodes/s^2
local GRAV = 9.81 -- Acceleration of gravity, in nodes/s^2
local TINIT = 0.36 -- Initial turn speed on first control input, in radians/s
local TACC = 0.12 -- Turn acceleration on control input, in radians/s^2
local TMAX = 1.6 -- Maximum turn speed, in radians/s
local TDEC = 0.24 -- Turn deceleration on no control input, in radians/s^2

-- End of parameters


-- Constants

local sztorqh = SZTORQ / 2


-- Functions

local function get_sign(n)
	if n == 0 then
		return 0
	else
		return n / math.abs(n)
	end
end


local function get_vecmag(vec)
	return math.sqrt(vec.x ^ 2 + vec.z ^ 2)
end


local function get_theta(vec) -- returns 0 to PI * 2
	if vec.z == 0 then
		return 0
	end
	if vec.z < 0 then
		return math.atan(-vec.x / vec.z) + math.pi
	end
	if vec.x > 0 then
		return math.atan(-vec.x / vec.z) + math.pi * 2
	end
	return math.atan(-vec.x / vec.z)
end


local function get_veccomp(vecmag, theta, y)
	local x = -math.sin(theta) * vecmag
	local z =  math.cos(theta) * vecmag
	return {x = x, y = y, z = z}
end


local function wrap_yaw(yaw) -- wrap to 0 to PI * 2
	local fmod = math.fmod(yaw, math.pi * 2)
	if fmod < 0 then
		return fmod + math.pi * 2
	end
	return fmod
end


local function angbet(theta1, theta2) -- theta1 relative to theta2, -PI to PI
	local ang = theta1 - theta2
	if ang < -math.pi then
		return ang + math.pi * 2
	end
	if ang > math.pi then
		return ang - math.pi * 2
	end
	return ang
end


local function add_smoke_particle(pos, player_name)
	minetest.add_particle({
		pos = pos,
		velocity = {x = 0, y = 0, z = 0},
		acceleration = {x = 0, y = 0, z = 0},
		expirationtime = 0.25,
		size = 2.8,
		collisiondetection = false,
		collision_removal = false,
		vertical = false,
		texture = "driftcar_smoke.png",
		playername = player_name,
	})
end


-- Entity

local car = {
	initial_properties = {
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.53, -0.75, -0.53, 0.53, 0.75, 0.53},
		visual = "wielditem",
		visual_size = {x = 1.667, y = 1.667}, -- Scale-up of nodebox is these * 1.5
		textures = {"driftcar:blue_nodebox"},
		stepheight = 0.6,
	},

	-- Custom fields
	driver = nil,
	removed = false,
	rot = 0,
}

minetest.register_entity("driftcar:driftcar", car)


-- Entity functions

function car.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and name == self.driver then
		-- Detach
		self.driver = nil
		clicker:set_detach()
		player_api.player_attached[name] = false
		player_api.set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		minetest.after(0.1, function()
			clicker:setpos(pos)
		end)
	elseif not self.driver then
		-- Attach
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end
		self.driver = name
		clicker:set_attach(self.object, "",
			{x = 0, y = -3, z = 0}, {x = 0, y = 0, z = 0})
		player_api.player_attached[name] = true
		minetest.after(0.2, function()
			player_api.set_animation(clicker, "sit" , 30)
		end)
		clicker:set_look_horizontal(self.object:getyaw())
	end
end


function car.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
end


function car.on_punch(self, puncher)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end

	local name = puncher:get_player_name()
	if self.driver and name == self.driver then
		-- Detach
		self.driver = nil
		puncher:set_detach()
		player_api.player_attached[name] = false
	end
	if not self.driver then
		-- Move to inventory
		self.removed = true
		local inv = puncher:get_inventory()
		local leftover = inv:add_item("main", "driftcar:driftcar")
		if not leftover:is_empty() then
			minetest.add_item(self.object:getpos(), leftover)
		end
		minetest.after(0.1, function()
			self.object:remove()
		end)
	end
end


function car.on_detach_child(self, child)
	self.driver = nil
end


local sound_cyc = 0

function car.on_step(self, dtime)
	local vel = self.object:getvelocity()
	local velmag = get_vecmag(vel)
	-- Early return for near-stationary vehicle with no driver
	if not self.driver and velmag < 0.01 and vel.y == 0 then
		self.object:setpos(self.object:getpos())
		self.object:setvelocity({x = 0, y = 0, z = 0})
		self.object:setacceleration({x = 0, y = 0, z = 0})
		return
	end

	-- Angle of yaw relative to velocity, -PI to PI
	local yawrtvel = angbet(
		wrap_yaw(self.object:getyaw()),
		get_theta(vel)
	)
	-- Velocity component linear to car
	local linvel = math.cos(yawrtvel) * velmag
	local abslinvel = math.abs(linvel)
	--print(abslinvel)
	-- Touch ground bool
	local under_pos = self.object:getpos()
	under_pos.y = under_pos.y - 0.8
	local node_under = minetest.get_node(under_pos)
	local nodedef_under = minetest.registered_nodes[node_under.name]
	local touch = nodedef_under.walkable
	-- On road bool
	local onroad = true
	-- Modify grip according to 'crumbly' group
	local grip = GRIP
	if nodedef_under.groups.crumbly then
		grip = ORGRIP
		onroad = false
	end

	-- Torque acceleration applied linear to car
	local taccmag = 0

	-- Controls
	if self.driver and touch then
		local driver_objref = minetest.get_player_by_name(self.driver)
		if driver_objref then
			local ctrl = driver_objref:get_player_control()
			if ctrl.up or ctrl.down then
				-- Torque multiplier applied above SZTORQ / 2 to replicate reduction of
				-- motor torque with rotation speed.
				local torm = 1
				if abslinvel > sztorqh then
					torm = (SZTORQ - abslinvel) / sztorqh
				end

				if ctrl.up then
					taccmag = grip * torm
				elseif ctrl.down then
					taccmag = -grip * torm
				end
			end
 		end
	end

	-- Early return for near-stationary vehicle with driver
	if taccmag == 0 and velmag < 0.01 and vel.y == 0 then
		self.object:setpos(self.object:getpos())
		self.object:setvelocity({x = 0, y = 0, z = 0})
		self.object:setacceleration({x = 0, y = 0, z = 0})
		return
	end

	-- Allows fast reduction of turn when no turn control
	local noturnctrl = true

	if self.driver and touch then
		local driver_objref = minetest.get_player_by_name(self.driver)
		if driver_objref then
			local ctrl = driver_objref:get_player_control()
			if ctrl.left then
				if self.rot == 0 then
					self.rot = TINIT
				else
					self.rot = self.rot + TACC
				end
				noturnctrl = false
			elseif ctrl.right then
				if self.rot == 0 then
					self.rot = -TINIT
				else
					self.rot = self.rot - TACC
				end
				noturnctrl = false
			end
 		end
	end

	-- If no turn control adjust turn towards zero
	local sr = get_sign(self.rot)
	if noturnctrl and touch then
		self.rot = self.rot - TDEC * sr
		if sr ~= get_sign(self.rot) then
			self.rot = 0
		end
	end
	-- Limit turn
	if math.abs(self.rot) > TMAX then
		self.rot = TMAX * get_sign(self.rot)
	end

	-- Acceleration caused by 4 Forces

	-- 1. Drag is proportional to velocity, assuming laminar flow
	local dragacc = vector.multiply(vel, -DRAG)

	-- 2. Rolling resistence is constant
	local rraccmag = 0
	if touch then
		if linvel > 0 then
			if onroad then
				rraccmag = -ROLRES
			else
				rraccmag = -ORROLRES
			end
		elseif linvel < 0 then
			if onroad then
				rraccmag = ROLRES
			else
				rraccmag = ORROLRES
			end
		end
	end
	--local rracc = get_veccomp(rraccmag, self.object:getyaw(), 0)

	-- 3. Wheel torque acceleration
	--local tacc = get_veccomp(taccmag, self.object:getyaw(), 0)

	-- Combine taccmag and rraccmag since same direction
	local trracc = get_veccomp(taccmag + rraccmag, self.object:getyaw(), 0)

	-- 4. Tire lateral friction
	-- Velocity component lateral to car
	local tlfacc = {x = 0, y = 0, z = 0}
	if touch then
		local latvel = math.sin(yawrtvel) * velmag
		local tlfaccmag = math.min(math.max(latvel * 32, -grip), grip)
		tlfacc = get_veccomp(tlfaccmag, self.object:getyaw() + math.pi / 2, 0)

		-- Tire smoke
		if self.driver and onroad and math.random() < -0.05 + math.abs(latvel) / 30 then
			local opos = self.object:getpos()
			opos.y = opos.y - 0.5
			local yaw = self.object:getyaw()
			local yaw1 = yaw + math.pi * 0.187
			local yaw2 = yaw + math.pi * 0.813

			local srcomp1x = -1.127 * math.sin(yaw1)
			local srcomp1z = 1.127 * math.cos(yaw1)
			local srcomp2x = -1.127 * math.sin(yaw2)
			local srcomp2z = 1.127 * math.cos(yaw2)

			add_smoke_particle({
				x = opos.x + srcomp1x,
				y = opos.y,
				z = opos.z + srcomp1z
				}, self.driver)
			add_smoke_particle({
				x = opos.x - srcomp1x,
				y = opos.y,
				z = opos.z - srcomp1z
				}, self.driver)
			add_smoke_particle({
				x = opos.x + srcomp2x,
				y = opos.y,
				z = opos.z + srcomp2z
				}, self.driver)
			add_smoke_particle({
				x = opos.x - srcomp2x,
				y = opos.y,
				z = opos.z - srcomp2z
				}, self.driver)
		end
	end

	-- Add up accelerations
	local new_acc = {
		x = trracc.x + dragacc.x + tlfacc.x,
		y = trracc.y + dragacc.y + tlfacc.y - GRAV,
		z = trracc.z + dragacc.z + tlfacc.z,
	}

	-- Turn multiplier
	local turm = 1
	-- Reduce turn below 4nps
	if velmag < 4 then
		turm = velmag / 4
	end
	-- Limit dtime to avoid too much turn
	dtime = math.min(dtime, 0.2)

	-- Set position, velocity, acceleration and yaw
	self.object:setpos(self.object:getpos())
	self.object:setvelocity(self.object:getvelocity())
	self.object:setacceleration(new_acc)
	self.object:setyaw(wrap_yaw(self.object:getyaw() + self.rot * dtime * turm))
end


-- Craftitem

minetest.register_craftitem("driftcar:driftcar", {
	description = "Drift Car",
	inventory_image = "driftcar_new_front.png",
	wield_image = "driftcar_new_front.png",
	wield_scale = {x = 2, y = 2, z = 2},

	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]

		-- Run any on_rightclick function of pointed node instead
		if udef and udef.on_rightclick and
				not (placer and placer:is_player() and
				placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		if pointed_thing.type ~= "node" then
			return itemstack
		end

		pointed_thing.under.y = pointed_thing.under.y + 1.25
		local car = minetest.add_entity(pointed_thing.under,
			"driftcar:driftcar")
		if car then
			if placer then
				car:setyaw(placer:get_look_horizontal())
			end
			local player_name = placer and placer:get_player_name() or ""
			itemstack:take_item()
		end
		return itemstack
	end,
})


-- Give to new player

minetest.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	inv:add_item("main", "driftcar:driftcar")
end)


-- Nodeboxes

-- Smart Fortwo dim: L 2.695 W 1.663 H 1.555
-- Size in pixels L 21.56 W 13.304 H 12.44
-- Alter to L 20 W 12 H 12
-- 20 = full cube of unscaled nodebox, 1 pixel = 0.05
-- Required nodebox scale up 2.5, visual_size = 2.5 / 1.5 = 1.667

minetest.register_node("driftcar:blue_nodebox", {
	description = "Drift Car Blue Nodebox",
	tiles = { -- Top, base, right, left, front, back
		"driftcar_new_top.png",
		"driftcar_new_base.png",
		"driftcar_new_right.png",
		"driftcar_new_left.png",
		"driftcar_new_front.png",
		"driftcar_new_back.png",
	},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
		--   wmin,  hmin,  lmin,  wmax,  hmax,  lmax
			{-0.3,   0.05, -0.5,   0.3,   0.3,   0.4},  -- Upper
			{-0.3,  -0.25, -0.5,   0.3,   0.05,  0.5},  -- Lower
			{-0.3,  -0.3,  -0.5,  -0.2,  -0.05, -0.25}, -- Wheels
			{ 0.2,  -0.3,  -0.5,   0.3,  -0.05, -0.25},
			{-0.3,  -0.3,   0.25, -0.2,  -0.05,  0.5},
			{ 0.2,  -0.3,   0.25,  0.3,  -0.05,  0.5},
		},
	},
})
