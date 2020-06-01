-- Parameters

local pathy = 8

local np_patha = {
	offset = 0,
	scale = 1,
	spread = {x = 1024, y = 1024, z = 1024},
	seed = 11711,
	octaves = 5,
	persist = 0.5
}


-- Nodes

minetest.register_node("track:road_black", {
	description = "Road Black",
	tiles = {"track_road_black.png"},
	is_ground_content = false,
	groups = {cracky = 3},
})

minetest.register_node("track:road_white", {
	description = "Road White",
	tiles = {"track_road_white.png"},
	paramtype = "light",
	light_source = 12,
	is_ground_content = false,
	groups = {cracky = 3},
})


-- Constants

local c_roadblack = minetest.get_content_id("track:road_black")
local c_roadwhite = minetest.get_content_id("track:road_white")


-- Initialise noise object, noise table, voxelmanip table

local nobj_patha = nil
local nvals_patha = {}
local data = {}


-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > pathy or maxp.y < pathy then
		return
	end

	--local t1 = os.clock()

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	local sidelen  = x1 - x0 + 1
	local emerlen  = sidelen + 32
	local overlen  = sidelen + 9
	local pmapdims = {x = overlen, y = overlen, z = 1}
	local pmapminp = {x = x0 - 5, y = z0 - 5}

	nobj_patha = nobj_patha or minetest.get_perlin_map(np_patha, pmapdims)
	nobj_patha:get2dMap_flat(pmapminp, nvals_patha)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	vm:get_data(data)

	local ni = 1
	for z = z0 - 5, z1 + 4 do
		local n_xprepatha = false
		-- x0 - 5, z0 - 5 is to setup initial values of 'xprepath_', 'zprepath_'
		for x = x0 - 5, x1 + 4 do
			local n_patha = nvals_patha[ni]
			local n_zprepatha = nvals_patha[(ni - overlen)]

			if x >= x0 - 4 and z >= z0 - 4 then
				if (n_patha >= 0 and n_xprepatha < 0) -- detect sign change of noise
						or (n_patha < 0 and n_xprepatha >= 0)
						or (n_patha >= 0 and n_zprepatha < 0)
						or (n_patha < 0 and n_zprepatha >= 0) then
					-- place path node brush
					for k = -4, 4 do
						local vi = area:index(x - 4, pathy, z + k)
						for i = -4, 4 do
							local radsq = (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2
							if radsq <= 15 then
								data[vi] = c_roadblack
							elseif radsq <= 20 then
								local nodid = data[vi]
								if nodid ~= c_roadblack then
									data[vi] = c_roadwhite
								end
							end
							vi = vi + 1
						end
					end
				end
			end

			n_xprepatha = n_patha
			ni = ni + 1
		end
	end
	
	vm:set_data(data)
	minetest.generate_decorations(vm)
	vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:write_to_map(data)

	--local chugent = math.ceil((os.clock() - t1) * 1000)
	--print ("[track] "..chugent.." ms")
end)
