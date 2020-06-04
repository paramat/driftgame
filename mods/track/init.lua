-- Parameters

local pathy = 8

local np_patha = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 256, z = 256},
	seed = 11711,
	octaves = 3,
	persist = 0.5
}

local np_pathb = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 256, z = 256},
	seed = 303,
	octaves = 3,
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

minetest.register_node("track:arrow_left", {
	description = "Arrow Block Left",
	tiles = {"track_red.png", "track_red.png",
		"track_red.png", "track_red.png",
		"track_red.png", "track_arrow_left.png"},
	paramtype = "light",
	light_source = 14,
	paramtype2 = "facedir",
	groups = {dig_immediate = 2},
})

minetest.register_node("track:arrow_right", {
	description = "Arrow Block Right",
	tiles = {"track_red.png", "track_red.png",
		"track_red.png", "track_red.png",
		"track_red.png", "track_arrow_left.png^[transformFX"},
	paramtype = "light",
	light_source = 14,
	paramtype2 = "facedir",
	groups = {dig_immediate = 2},
})


-- Give initial items

minetest.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	inv:add_item("main", "track:arrow_left 512")
	inv:add_item("main", "track:arrow_right 512")
end)


-- Constants

local c_roadblack = minetest.get_content_id("track:road_black")
local c_roadwhite = minetest.get_content_id("track:road_white")


-- Initialise noise object, noise table, voxelmanip table

local nobj_patha = nil
local nobj_pathb = nil
local nvals_patha = {}
local nvals_pathb = {}
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
	
	-- Noise map extends from x0/z0 - 5 to x1/z1 + 4, one node larger than the track brush
	-- centre generation area, to allow sign change of noise to be detected along minimum
	-- edges of track brush centre generation area.
	local mchudim  = x1 - x0 + 1
	local pmapdim  = mchudim + 9
	local pmapdims = {x = pmapdim, y = pmapdim, z = 1}
	local pmapminp = {x = x0 - 5, y = z0 - 5}

	nobj_patha = nobj_patha or minetest.get_perlin_map(np_patha, pmapdims)
	nobj_pathb = nobj_pathb or minetest.get_perlin_map(np_pathb, pmapdims)
	nobj_patha:get2dMap_flat(pmapminp, nvals_patha)
	nobj_pathb:get2dMap_flat(pmapminp, nvals_pathb)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	vm:get_data(data)

	-- Track brush centre generation area extends from x0/z0 - 4 to x1/z1 + 4
	for z = z0 - 4, z1 + 4 do
		-- Initial noise index at x0 - 4 for this z
		local ni = 1 + (z - (z0 - 5)) * pmapdim + 1
		local n_xprepatha = nvals_patha[(ni - 1)]
		local n_xprepathb = nvals_pathb[(ni - 1)]
		for x = x0 - 4, x1 + 4 do
			local n_patha = nvals_patha[ni]
			local n_pathb = nvals_pathb[ni]
			local n_zprepatha = nvals_patha[(ni - pmapdim)]
			local n_zprepathb = nvals_pathb[(ni - pmapdim)]
			-- Detect sign change of noise
			if (n_patha >= 0 and n_xprepatha < 0)
					or (n_patha < 0 and n_xprepatha >= 0)
					or (n_patha >= 0 and n_zprepatha < 0)
					or (n_patha < 0 and n_zprepatha >= 0)

					or (n_pathb >= 0 and n_xprepathb < 0)
					or (n_pathb < 0 and n_xprepathb >= 0)
					or (n_pathb >= 0 and n_zprepathb < 0)
					or (n_pathb < 0 and n_zprepathb >= 0)-- then
					-- Smooth corners of junctions
					or math.pow(math.abs(n_patha), 0.1) *
					math.pow(math.abs(n_pathb), 0.1) < 0.5 then
				-- Place track brush of radius 4
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

			ni = ni + 1
			n_xprepatha = n_patha
			n_xprepathb = n_pathb
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
