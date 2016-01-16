
--[[

Copyright (C) 2016 - Auke Kok <sofar@foo-projects.org>

"lightning" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

local lightning = {}

lightning.interval_low = 17
lightning.interval_high = 503
lightning.range_h = 100
lightning.range_v = 50
lightning.size = 100

local rng = PcgRandom(32321123312123)

local ps = {}
local ttl = 1

local revertsky = function()
	if ttl == 0 then
		return
	end
	ttl = ttl - 1
	if ttl > 0 then
		return
	end

	for i = 1, table.getn(ps) do
		ps[i].p:set_sky(ps[i].sky.bgcolor, ps[i].sky.type, ps[i].sky.textures)
	end

	ps = {}
end

minetest.register_globalstep(revertsky)

lightning.strike = function()
	minetest.after(rng:next(lightning.interval_low, lightning.interval_high), lightning.strike)

	local playerlist = minetest.get_connected_players()
	local playercount = table.getn(playerlist)

	-- nobody on
	if playercount == 0 then
		return
	end

	local r = rng:next(1, playercount)
	local randomplayer = playerlist[r]
	local pos = randomplayer:getpos()

	-- avoid striking underground
	if pos.y < -20 then
		return
	end

	pos.x = math.floor(pos.x - (lightning.range_h / 2) + rng:next(1, lightning.range_h))
	pos.y = pos.y + (lightning.range_v / 2)
	pos.z = math.floor(pos.z - (lightning.range_h / 2) + rng:next(1, lightning.range_h))

	local b, pos2 = minetest.line_of_sight(pos, {x = pos.x, y = pos.y - lightning.range_v, z = pos.z}, 1)
	-- nothing but air found
	if b then
		return
	end

	local n = minetest.get_node({x = pos2.x, y = pos2.y - 1/2, z = pos2.z})
	if n.name == "air" or n.name == "ignore" then
		return
	end

	minetest.add_particlespawner({
		amount = 1,
		time = 0.2,
		-- make it hit the top of a block exactly with the bottom
		minpos = {x = pos2.x, y = pos2.y + (lightning.size / 2) + 1/2, z = pos2.z },
		maxpos = {x = pos2.x, y = pos2.y + (lightning.size / 2) + 1/2, z = pos2.z },
		minvel = {x = 0, y = 0, z = 0},
		maxvel = {x = 0, y = 0, z = 0},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 0.2,
		maxexptime = 0.2,
		minsize = lightning.size * 10,
		maxsize = lightning.size * 10,
		collisiondetection = true,
		vertical = true,
		-- to make it appear hitting the node that will get set on fire, make sure
		-- to make the texture lightning bolt hit exactly in the middle of the
		-- texture (e.g. 127/128 on a 256x wide texture)
		texture = "lightning_lightning_" .. rng:next(1,3) .. ".png",
	})

	minetest.sound_play({ pos = pos, name = "lightning_thunder", gain = 10, max_hear_distance = 500 })

	for i = 1, playercount do
		local sky = {}
		sky.bgcolor, sky.type, sky.textures = playerlist[i]:get_sky()
		table.insert(ps, { p = playerlist[i], sky = sky})
		playerlist[i]:set_sky(0xffffff, "plain", {})
	end
	-- trigger revert of skybox
	ttl = 5

	-- set the air node above it on fire
	pos2.y = pos2.y + 1/2
	if minetest.get_item_group(minetest.get_node({x = pos2.x, y = pos2.y - 1, z = pos2.z}).name, "liquid") < 1 then
		if minetest.get_node(pos2).name == "air" then
			-- only 1/4 of the time, something is changed
			if rng:next(1,4) > 1 then
				return
			end
			-- very rarely, cause a massive forest fire (100*4*250 = 1/100000 seconds)
			if rng:next(1,100) == 1 then
				minetest.set_node(pos2, {name = "fire:basic_flame"})
			else
				minetest.set_node(pos2, {name = "fire:permanent_flame"})
			end
		end
	end

	-- perform block modifications
	pos2.y = pos2.y - 1
	local n = minetest.get_node(pos2)
	if minetest.get_item_group(n.name, "tree") > 0 then
		minetest.set_node(pos2, { name = "default:coalblock"})
	elseif minetest.get_item_group(n.name, "sand") > 0 then
		minetest.set_node(pos2, { name = "default:glass"})
	elseif minetest.get_item_group(n.name, "soil") > 0 then
		minetest.set_node(pos2, { name = "default:gravel"})
	end
end

minetest.after(rng:next(lightning.interval_low, lightning.interval_high), lightning.strike)
