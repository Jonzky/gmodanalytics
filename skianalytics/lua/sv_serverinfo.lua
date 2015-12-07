local getServerIdQuery = "SELECT s.id, g.name FROM servers s LEFT JOIN gamemodes g ON s.gamemode=g.id WHERE token = '%s'"
local insertServerQuery = "INSERT INTO servers(token, address, gamemode, lastupdate) VALUES('%s', '%s', '%d', UTC_TIMESTAMP())"

local getGamemodeIdQuery = "SELECT id FROM gamemodes WHERE name='%s'"
local inserGamemodeQuery = "INSERT INTO gamemodes(name) VALUES('%s')"

CreateConVar("ski_servertoken", "devserver", FCVAR_NONE, "Sets the Ski ServerID - create a unqiue value for each server")
CreateConVar("ski_serverip", "123:27015", FCVAR_NONE, "Sets the IP for Ski Analytics - Format IP:PORT")


local function get_server_id(gamemodeid)

	local token = SkiWeb.db:escape(GetConVar("ski_servertoken"):GetString())
	local serverIP = SkiWeb.db:escape(GetConVar("ski_serverip"):GetString())

	if serverId == -1 then
		print("************** No Ski server-id set **************")
		print("***** Please make sure one is set to proceed *****")
		return
	end

	local qTab = {}
	qTab.cb = function(q, sdata)
	   if not SkiWeb:checkQuery(q) then			
			local qwe = {}
			qwe.cb = function(q,s)
				print("[Ski] Server added to the database!")
				SkiWeb.ServerID = q:lastInsert()
			end
			local formQuery = string.format(insertServerQuery, token, serverIP, gamemodeid)
			SkiWeb:query(formQuery, qwe)
		end		
		local row = sdata[1];
		if row == nil then return end
		SkiWeb.ServerID = row['id']
		print("[Ski] Server ID is: " .. SkiWeb.ServerID)	
	end
	local formServerQuery = string.format(getServerIdQuery, token)
	SkiWeb:query(formServerQuery, qTab)
end

local function check_gamemode()
	local escpMode = SkiWeb.db:escape( gmod.GetGamemode().Name )
	local qTab = {}
	qTab.cb = function(q, sdata)
	   if not SkiWeb:checkQuery(q) then			
			local qwe = {}
			qwe.cb = function(q,s)
				SkiWeb.Gamemode = q:lastInsert()
				get_server_id(SkiWeb.Gamemode)
				SkiWeb.Gamemode = 
				print("[Ski] Gamemode added to the database!")
				return
			end
			local formQuery = string.format(inserGamemodeQuery, escpMode)
			SkiWeb:query(formQuery, qwe)
		end		
		local row = sdata[1];
		if row == nil then return end
		SkiWeb.Gamemode = row['id']
		get_server_id(row['id'])
	end
	local formGamemodeQuery = string.format(getGamemodeIdQuery, escpMode)
	SkiWeb:query(formGamemodeQuery, qTab)
end
hook.Add("Initialize", "[Ski] Server Initialize", function() timer.Simple(1, function() check_gamemode() end) end)
//hook.Add("Initialize", "[Ski] Server Initialize", check_gamemode)
