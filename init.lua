
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
lightning.range = 200
lightning.size = 100

local rng = PcgRandom(32321123312123)

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

	pos.x = math.floor(pos.x - (lightning.range / 2) + rng:next(1, lightning.range))
	pos.y = pos.y + (lightning.range / 2)
	pos.z = math.floor(pos.z - (lightning.range / 2) + rng:next(1, lightning.range))

	local b, pos2 = minetest.line_of_sight(pos, {x = pos.x, y = pos.y - lightning.range, z = pos.z}, 1)
	-- nothing but air found
	if b then
		return
	end

	minetest.add_particlespawner({
		amount = 1,
		time = 0.2,
		-- make it hit the top of a block exactly with the bottom
		minpos = { x = pos2.x, y = pos2.y + (lightning.size / 2) + 1/2, z = pos2.z },
		maxpos = { x = pos2.x, y = pos2.y + (lightning.size / 2) + 1/2, z = pos2.z },
		-- the particle will be centered above the pos2 position but we
		-- want it to hit the node on the ground
		-- down really fast at the ground
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

	-- set the air node above it on fire
	pos2.y = pos2.y + 1/2
	if minetest.get_node(pos2).name == "air" then
		minetest.set_node(pos2, {name = "fire:basic_flame"})
	end

	-- perform block modifications
	pos2.y = pos2.y - 1
	local n = minetest.get_node(pos2)
	if n.name == "default:tree" or n.name == "default:jungletree" or n.name == "default:pine_tree" or
	   n.name == "default:acacia_tree" or n.name == "default:acacia_tree" then
		minetest.set_node(pos2, { name = "default:coalblock"})
	elseif n.name == "default:sand" or n.name == "default:desert_sand" then
		minetest.set_node(pos2, { name = "default:glass"})
	elseif string.find(n.name, "default:dirt") then
		minetest.set_node(pos2, { name = "default:gravel"})
	elseif string.find(n.name, "default:soil") then
		minetest.set_node(pos2, { name = "default:gravel"})
	end
end

minetest.after(rng:next(lightning.interval_low, lightning.interval_high), lightning.strike)
