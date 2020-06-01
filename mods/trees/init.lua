-- Nodes

minetest.register_node("trees:pine_trunk", {
	description = "Pine Trunk",
	tiles = {
		"trees_pine_trunk_top.png",
		"trees_pine_trunk_top.png",
		"trees_pine_trunk_side.png",
	},
	groups = {choppy = 2},
})

minetest.register_node("trees:pine_needles", {
	description = "Pine Needles",
	tiles = {"trees_pine_needles.png"},
	walkable = false,
	groups = {dig_immediate = 2},
})


-- Decoration.
-- Placed by voxelmanip in 'track' mod, not by core mapgen, so use:
-- mg_flags = caves,dungeons,light,nodecorations,biomes

minetest.register_decoration({
	deco_type = "schematic",
	place_on = {"mapgen:grass"},
	sidelen = 16,
	noise_params = {
		offset = 0.0,
		scale = 0.04,
		spread = {x = 256, y = 256, z = 256},
		seed = 2,
		octaves = 3,
		persist = 0.7
	},
	y_min = -31000,
	y_max = 31000,
	schematic = minetest.get_modpath("trees").."/schematics/trees_pine_tree.mts",
	flags = "place_center_x, place_center_z",
})
