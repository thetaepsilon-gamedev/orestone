


-- colour tinting helpers
local hex = function(v) return string.format("%02x", v) end
local whiten = function(base, ratio)
	local darkness = 255 - base
	return math.floor(255 - (darkness * ratio))
end

-- map a function over a table's keys -
-- used to apply texture modifiers to a base node's tiles.
local filter = function(f, tbl)
	local r = {}
	for k, v in pairs(tbl) do
		r[k] = f(v)
	end
	return r
end
-- rgb table wrapper, somewhat like vector.new
local rgb = function(r, g, b) return {r=r,g=g,b=b} end
-- does similar, but applies some whitening to base colour values.
local rgbw = function(rd, gd, bd, w)
	local r = whiten(rd, w)
	local g = whiten(gd, w)
	local b = whiten(bd, w)
	return rgb(r, g, b)
end



-- our database of known ores.
-- my previous attempts to automatically extract colours from textures
-- have fell flat on their face, so here we just hard-code tinting colours,
-- as well as other information (such as which ore lump they refine to).
-- organisation of table is as follows:
--[[
{
	-- just organisational convenience
	["modname"] = {
		-- if modname:oreblock doesn't exist, skip this
		["some_ore"] = {
			colour = rgb(...),
			name = "some material",	-- used to form block description
			purity = 0.2,	-- volume of ore to containing material
			-- refinery methods (can be empty)
			methods = {
				somemethod = {
					-- various method speciic data goes here
					-- however this key is required:
					output = "modname:somelump 9"
				}
			}

			-- other keys may be added later
		}
	}
}
]]
-- methods helper for pure magnetic separation ores
local magnetic = function(output)
	return {
		magnetic = {
			output = output,
		}
	}
end
-- methods when none implemented yet
local none = function() return {} end

local stone_db = {	-- ores appearing in default:stone
	default = {
		stone_with_iron = {
			colour = rgb(137, 102, 82),
			name = "iron",
			purity = 0.2,
			methods = magnetic("default:iron_lump")
		},
		stone_with_diamond = {
			--colour = rgb(123, 244, 242),
			colour = rgbw(110, 220, 255, 0.5),
			name = "diamond",
			purity = 0.2,
			methods = none,
		},
		stone_with_copper = {
			-- 171 127 76
			colour = rgb(200, 128, 61),
			name = "copper",
			purity = 0.4,
			methods = none
		},
	}
}



-- create tinting modifier based on base colour.
-- rgb_tint :: RGB -> String
local rgb_tint = function(c)
	local colour = hex(c.r)..hex(c.g)..hex(c.b)
	return "^[multiply:#"..colour
end

-- escape a block name so that it can be used as part of another block name.
local escape = function(n) return string.gsub(n, ":", "_") end



local mn = "orestone"
local desc_traces = " with traces of "
local register_db_node = function(hostname, registered_nodes, entry, regf)
	-- texture modifier for host def's tiles.
	local texm = rgb_tint(entry.colour)
	local maptex = function(tex) return "("..tex..")"..texm end
	local name = entry.name

	-- look up properties of hosting node.
	local hostdef = registered_nodes[hostname]

	-- various properties are borrowed from hostdef, such as sounds.
	-- e.g. for stone it'll sound mostly like stone, dig like it, etc.
	local orestone_def = {
		groups = hostdef.groups,
		sounds = hostdef.sounds,
		tiles = filter(maptex, hostdef.tiles),
		description = hostdef.description..desc_traces..name
	}
	local n = mn..":ore_"..escape(hostname).."_"..name
	regf(n, orestone_def)

	-- TODO: no method handling yet...
end

local register_nodes_in_db = function(hostname, db, basedefs, regf)
	for modname, nodes in pairs(db) do
		for modnode, entry in pairs(nodes) do
			local nodename = modname..":"..modnode
			local cond = basedefs[nodename]
			if cond then
				register_db_node(hostname, basedefs, entry, regf)
			end
		end
	end
end

local nodes = minetest.registered_nodes
register_nodes_in_db("default:stone", stone_db, nodes, minetest.register_node)


