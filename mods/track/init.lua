-- Parameters

local pathy = 8

-- Noises blended to create 'path'

local np_patha = {
	offset = 0.0,
	scale = 1,
	spread = {x = 384, y = 384, z = 384},
	seed = 11711,
	octaves = 4,
	persist = 0.6
}

local np_pathb = {
	offset = 0.0,
	scale = 1,
	spread = {x = 384, y = 384, z = 384},
	seed = 303,
	octaves = 1,
	persist = 0.5
}

-- Noises blended to create 'path2'

local np_pathc = {
	offset = 0.0,
	scale = 1,
	spread = {x = 512, y = 512, z = 512},
	seed = 7755,
	octaves = 4,
	persist = 0.6
}

local np_pathd = {
	offset = 0.0,
	scale = 1,
	spread = {x = 512, y = 512, z = 512},
	seed = 1001,
	octaves = 1,
	persist = 0.5
}

-- Blend between low and high octave noises

local np_blend = {
	offset = 0.0,
	scale = 6.0,
	spread = {x = 256, y = 256, z = 256},
	seed = 95059,
	octaves = 1,
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


-- Set mapgen flags to disable core mapgen decoration placement.
-- Tree decorations are placed using the Lua Voxel Manipulator after track generation
-- to avoid trees on track.

minetest.set_mapgen_setting("mg_flags", "caves,dungeons,light,nodecorations,biomes", true)


-- Constants

local c_roadblack = minetest.get_content_id("track:road_black")
local c_roadwhite = minetest.get_content_id("track:road_white")


-- Initialise noise object, noise table, voxelmanip table

local nobj_patha = nil
local nobj_pathb = nil
local nobj_pathc = nil
local nobj_pathd = nil
local nobj_blend = nil
local nvals_patha = {}
local nvals_pathb = {}
local nvals_pathc = {}
local nvals_pathd = {}
local nvals_blend = {}
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
	nobj_pathc = nobj_pathc or minetest.get_perlin_map(np_pathc, pmapdims)
	nobj_pathd = nobj_pathd or minetest.get_perlin_map(np_pathd, pmapdims)
	nobj_blend = nobj_blend or minetest.get_perlin_map(np_blend, pmapdims)
	nobj_patha:get2dMap_flat(pmapminp, nvals_patha)
	nobj_pathb:get2dMap_flat(pmapminp, nvals_pathb)
	nobj_pathc:get2dMap_flat(pmapminp, nvals_pathc)
	nobj_pathd:get2dMap_flat(pmapminp, nvals_pathd)
	nobj_blend:get2dMap_flat(pmapminp, nvals_blend)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	vm:get_data(data)

	-- Track brush centre generation area extends from x0/z0 - 4 to x1/z1 + 4
	for z = z0 - 4, z1 + 4 do
		-- Initial noise index at x0 - 4
		local ni = 1 + (z - (z0 - 5)) * pmapdim + 1
		-- Initial blend, n_path and n_path2 values for adjacent node at x0 - 5
		local xpreblend = (math.tanh(nvals_blend[(ni - 1)]) + 1) / 2
		local n_xprepath = (1 - xpreblend) * nvals_patha[(ni - 1)] +
			xpreblend * nvals_pathb[(ni - 1)]
		local n_xprepath2 = (1 - xpreblend) * nvals_pathc[(ni - 1)] +
			xpreblend * nvals_pathd[(ni - 1)]
		for x = x0 - 4, x1 + 4 do
			local blend = (math.tanh(nvals_blend[ni]) + 1) / 2
			local n_path = (1 - blend) * nvals_patha[ni] + blend * nvals_pathb[ni]
			local n_path2 = (1 - blend) * nvals_pathc[ni] + blend * nvals_pathd[ni]
			-- blend, n_path and n_path2 values for adjacent node at z - 1
			local zpreblend = (math.tanh(nvals_blend[(ni - pmapdim)]) + 1) / 2
			local n_zprepath = (1 - zpreblend) * nvals_patha[(ni - pmapdim)] +
				zpreblend * nvals_pathb[(ni - pmapdim)]
			local n_zprepath2 = (1 - zpreblend) * nvals_pathc[(ni - pmapdim)] +
				zpreblend * nvals_pathd[(ni - pmapdim)]
			-- Detect sign change of n_path and n_path2 in x, z directions
			if (n_path * n_xprepath < 0)
					or (n_path * n_zprepath < 0)
					or (n_path2 * n_xprepath2 < 0)
					or (n_path2 * n_zprepath2 < 0)
					-- Detect when n_path and n_path2 are simultaneously
					-- very small, to smooth corners of junctions
					or math.pow(math.abs(n_path), 0.1) *
					math.pow(math.abs(n_path2), 0.1) < 0.5 then
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
			-- Set adjacent node values to current values
			n_xprepath = n_path
			n_xprepath2 = n_path2
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
