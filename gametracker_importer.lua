-- Gametracker importer by Zerf (STEAM_0:0:46161927)
--[[ Example:
concommand.Add("gametracker_try", function(srvcon, cmd, args)
	GTImport.Run("66.150.188.121:27015", 8, 3, function(mastertbl)
		PrintTable(mastertbl)
		file.Write("gametracker_0-400.txt", util.TableToJSON(mastertbl))
	end)
end)
--]]
local function printerr(str)
	MsgC(Color(255, 0, 0), "[GAMETRACKER ERR]: " .. str .. "\n")
end

local GTImport = {}

function GTImport.Run(srvip, pagecount, startpage, callback)
	local ret = {}

	local lastpage = pagecount + startpage - 1
	for i = 1, pagecount do
		local curpage = startpage + i - 1
		local url = "http://www.gametracker.com/server_info/" .. srvip .. "/top_players/?searchipp=50&searchpge=" .. curpage

		http.Fetch(url, function(html)
			if !GTImport.ProcessHTML(html) then
				printerr("Server not found")
				return
			end

			for i, data in pairs(GTImport.ProcessHTML(html)) do
				ret[#ret + 1] = data
			end

			if curpage == lastpage then
				callback(ret)

				return
			end
		end, function(err)
			printerr("HTTP Fetch error: " .. err)
		end)
	end
end


function GTImport.Clean(data)
	local validlines = {}

	for i, line in pairs(string.Explode("\n", data)) do
		if string.find(line, "</td>") or string.find(line, "</tr>") or string.find(line, "<td>") or string.find(line, "<tr>") or string.find(line, "<table") or string.find(line, "a href") or string.find(line, "</a>") or string.find(line, "td class=\"c03\"") or string.find(line, "td class=\"c01\"") or string.find(line, "td class=\"c06\"") or #string.Trim(line) <= 0 then continue end
		line = string.Trim(line)
		validlines[#validlines + 1] = line
	end

	local ret = {
		names     = {},
		ranks     = {},
		scores    = {},
		score_min = {},
		playtimes = {}
	}

	local map = {
		[1] = ret.ranks,
		[2] = ret.names,
		[4] = ret.scores,
		[5] = ret.playtimes,
		[6] = ret.score_min,
	}

	local pos = 0
	for i = 8, #validlines - 8 do
		local line = validlines[i]

		pos = pos + 1

		if map[pos] then
			map[pos][ #map[pos] + 1 ] = line
		end

		if pos == 6 then pos = 0 end
	end

	local ret2 = {}
	for i = 1, #ret.names do
		ret2[#ret2 + 1] = {
			rank = ret.ranks[i],
			name = ret.names[i],
			score = ret.scores[i],
			playtime = ret.playtimes[i],
			score_min = ret.score_min[i]
		}
	end

	return ret2
end -- I tried using regex. I really did. ;(

function GTImport.ProcessHTML(rawhtml)
	local tblstart = string.find(rawhtml, "<table class=\"table_lst table_lst_spn\">")
	local tblend = string.find(rawhtml, "</table>")

	if (!tblstart) or (!tblend) then
		printerr("Couldn't find table of data in HTML!")

		return
	end

	local data = string.sub(rawhtml, tblstart, tblend)

	return GTImport.Clean(data)
end
