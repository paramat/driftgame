-- Schematic file format version 4

-- Standard table format, structure appears inverted in each z slice.
-- Z, Y and X are formatted in increasing order.

local mts_save = function(name, schematic)
	local s = minetest.serialize_schematic(schematic, "mts", {})
	local path = minetest.get_modpath("schematics") .. "/schematics"
	local filename = path .. "/" .. name .. ".mts"
	filename = filename:gsub("\"", "\\\""):gsub("\\", "\\\\")
	local file, err = io.open(filename, "wb")
	if err == nil then
		file:write(s)
		file:flush()
		file:close()
	end
	print("Wrote: " .. filename)
end

local _ = {name = "air", prob = 0}

-- Mapgen small pine tree

local L = {name = "trees:pine_needles", prob = 255}
local T = {name = "trees:pine_trunk", prob = 255, force_place = true}

mts_save("trees_pine_tree", {
	size = {x = 5, y = 12, z = 5},
	data = {
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, L, L, L, _,
		_, _, L, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,

		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		L, L, _, L, L,
		_, L, L, L, _,
		_, L, L, L, _,
		_, L, L, L, _,
		_, _, L, _, _,
		_, _, L, _, _,
		_, _, _, _, _,
		_, _, _, _, _,

		_, _, T, _, _,
		_, _, T, _, _,
		_, _, T, _, _,
		_, _, T, _, _,
		L, _, T, _, L,
		L, L, T, L, L,
		_, L, T, L, _,
		_, L, T, L, _,
		_, L, L, L, _,
		_, L, L, L, _,
		_, _, L, _, _,
		_, _, L, _, _,

		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		L, L, _, L, L,
		_, L, L, L, _,
		_, L, L, L, _,
		_, L, L, L, _,
		_, _, L, _, _,
		_, _, L, _, _,
		_, _, _, _, _,
		_, _, _, _, _,

		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, L, L, L, _,
		_, _, L, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
		_, _, _, _, _,
	},
	yslice_prob = {
		{ypos = 2, prob = 127},
		{ypos = 3, prob = 127},
		{ypos = 4, prob = 127},
	},
})
