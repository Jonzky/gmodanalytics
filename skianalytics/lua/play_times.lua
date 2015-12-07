if not SERVER then return end

local getPlayerTimeQuery = "SELECT active FROM time_played WHERE userid='%d' AND serverid='%d' AND start_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)"
local updatePlayerTimeQuery = "UPDATE time_played SET last_seen=UTC_TIMESTAMP(),active=active+'%d',afk=afk+'%d' WHERE userid='%d' AND serverid='%d' AND start_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)"
local inserPlayerQuery = "INSERT INTO time_played(userid, start_date, last_seen, serverid, active, afk) VALUES('%d', UTC_TIMESTAMP(), UTC_TIMESTAMP(), '%s', '0', '0')"


local meta = FindMetaTable( "Player" )
if not meta then return end

function meta:CheckSpec()
	local gamemode = gmod.GetGamemode().Name
	if gamemode == "terrortown" then
		return self:IsSpec()
	elseif gamemode == "Hide and Seek" then
		return self:Team() == 3
	end
	return false
end

local function update_player_time (ply)

	if  (!ply.SkiID || !SkiWeb.ServerID || !ply.times.loaded) then 
		return 
	end

	local updatePlayerTime = {}
	updatePlayerTime.cb = function(q,s)
		if IsValid(ply) then
			ply.times.afk = 0;
			ply.times.active = 0;
		end
	end
	local formQuery = string.format(updatePlayerTimeQuery, ply.times.active, ply.times.afk, ply.SkiID, SkiWeb.ServerID)
	SkiWeb:query(formQuery, updatePlayerTime)
end

local function player_spawn( ply )
	ply.times = {}
	ply.times.afk = 0;
	ply.times.active = 0;

	if (!ply.SkiID || !SkiWeb.ServerID) then
		timer.Simple(10, function()
			player_spawn(ply)
		end)
		return
	end

	local getPlayerTime = {}
	getPlayerTime.cb = function(q, sdata)
	   if not SkiWeb:checkQuery(q) then			
			local insertNewPlayer = {}
			insertNewPlayer.cb = function(q,s)
				ply.times.loaded = true
			end
			local formQuery = string.format(inserPlayerQuery, ply.SkiID, SkiWeb.ServerID)
			SkiWeb:query(formQuery, insertNewPlayer)
		else
			ply.times.loaded = true
		end		
	end
	local formPlayerQuery = string.format(getPlayerTimeQuery, ply.SkiID, SkiWeb.ServerID)
	SkiWeb:query(formPlayerQuery, getPlayerTime)
end
hook.Add( "PlayerInitialSpawn", "[Ski Times] - PlayerInitialSpawn", player_spawn )


local function update_all_times()
	for _, ply in pairs( player.GetAll() ) do
		if ply and ply:IsConnected() and ply:IsValid() then
			update_player_time(ply)
		end
	end
end
timer.Create( "SkiTime", 300, 0, update_all_times )
hook.Add( "ShutDown", "[Ski Times] - Shutdown", update_all_times )
hook.Add( "PlayerDisconnected", "[Ski Times] - Disconnect", update_player_time )

local function updateAll()
	for _, ply in pairs( player.GetAll() ) do
		if ply and ply:IsConnected() and ply:IsValid() then
			if ply:CheckSpec() then --and ply:GetForceSpec() then
				ply.times.afk = ply.times.afk + 30			
			else
				ply.times.active = ply.times.active + 30		
			end
		end
	end
end
timer.Create( "[Ski Times] - Update all", 30, 0, updateAll )