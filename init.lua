local random = math.random

birch = {}

function birch.can_grow(pos)
	local node_under = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not node_under then
		return false
	end
	local name_under = node_under.name
	local is_soil = minetest.get_item_group(name_under, "soil")
	if is_soil == 0 then
		return false
	end
	return true
end

local function add_trunk_and_leaves(data, a, pos, tree_cid, leaves_cid, height, size, iters)
	local x, y, z = pos.x, pos.y, pos.z
	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")

	-- Trunk
	for y_dist = 0, height - 1 do
		local vi = a:index(x, y + y_dist, z)
		local node_id = data[vi]
		if y_dist == 0 or node_id == c_air or node_id == c_ignore
		or node_id == leaves_cid then
			data[vi] = tree_cid
		end
	end

	-- Force leaves near the trunk
	for z_dist = -1, 1 do
	for y_dist = -size, 1 do
		local vi = a:index(x - 1, y + height + y_dist, z + z_dist)
		for x_dist = -1, 1 do
			if data[vi] == c_air or data[vi] == c_ignore then
				data[vi] = leaves_cid
			end
			vi = vi + 1
		end
	end
	end

	-- Randomly add leaves in 2x2x2 clusters.
	for i = 1, iters do
		local clust_x = x + random(-size, size - 1)
		local clust_y = y + height + random(-size, 0)
		local clust_z = z + random(-size, size - 1)

		for xi = 0, 1 do
		for yi = 0, 1 do
		for zi = 0, 1 do
			local vi = a:index(clust_x + xi, clust_y + yi, clust_z + zi)
			if data[vi] == c_air or data[vi] == c_ignore then
				data[vi] = leaves_cid
			end
		end
		end
		end
	end
end

function birch.grow_tree(pos)
	local x, y, z = pos.x, pos.y, pos.z
	local height = random(6, 8)
	local c_tree = minetest.get_content_id("birch:tree")
	local c_leaves = minetest.get_content_id("birch:leaves")

	local vm = minetest.get_voxel_manip()
	local minp, maxp = vm:read_from_map(
		{x = pos.x - 2, y = pos.y, z = pos.z - 2},
		{x = pos.x + 2, y = pos.y + height + 1, z = pos.z + 2}
	)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()

	add_trunk_and_leaves(data, a, pos, c_tree, c_leaves, height, 3, 30)

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end

minetest.register_abm({
	nodenames = {"birch:sapling"},
	interval = 10,
	chance = 50,
	action = function(pos, node)
		if not can_grow(pos) then
			return
		end

		minetest.log("action", "A birch sapling grows into a tree at "..minetest.pos_to_string(pos))
		birch.grow_tree(pos)
	end
})

-- Nodes
minetest.register_node("birch:tree", {
	description = "Birch Tree",
	tiles = {"birch_tree_top.png", "birch_tree_top.png", "birch_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree=1,choppy=2,oddly_breakable_by_hand=1,flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("birch:wood", {
	description = "Birchwood Planks",
	tiles = {"birch_wood.png"},
	groups = {choppy=2,oddly_breakable_by_hand=2,flammable=3,wood=1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("birch:sapling", {
	description = "Birch Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"birch_sapling.png"},
	inventory_image = "birch_sapling.png",
	wield_image = "birch_sapling.png",
	paramtype = "light",
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = {snappy=2,dig_immediate=3,flammable=2,attached_node=1,sapling=1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("birch:leaves", {
	description = "Birch Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	visual_scale = 1.3,
	tiles = {"birch_leaves.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1,
		items = {
			{
				-- player will get sapling with 1/20 chance
				items = {'birch:sapling'},
				rarity = 25,
			},
			{
				-- player will get leaves only if he get no saplings,
				-- this is because max_items is 1
				items = {'birch:leaves'},
			}
		}
	},
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = default.after_place_leaves,
})

-- Craft
minetest.register_craft({
	output = 'birch:wood 4',
	recipe = {
		{'birch:tree'},
	}
})

stairs.register_stair_and_slab("birchwood", "birch:wood",
	{snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	{"birch_wood.png"},
	"Birchwood Stair",
	"Birchwood Slab",
	default.node_sound_wood_defaults()
)

--MapGen

minetest.register_node("birch:direct_sapling", {
	description = "Birch Direct Sapling (You cheater, You!)",
	drawtype = "plantlike",
	tiles = {"birch_sapling.png"},
	inventory_image = "birch_sapling.png",
	wield_image = "birch_sapling.png",
	paramtype = "light",
	walkable = false,
	is_ground_content = true,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = {sapling=1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_abm({
	nodenames = {"birch:direct_sapling"},
	interval = 0.1,
	chance = 1,
	action = function(pos, node)
		if not birch.can_grow(pos) then
			return
		end

		birch.grow_tree(pos)
	end
})
