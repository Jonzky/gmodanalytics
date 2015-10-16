
local inserPlayerQuery = "INSERT INTO players(steamid, nick, rank, reports_made, reports_against, firstseen, lastseen, status) VALUES ('%s', '%s', 'guest', '0', '0', UTC_TIMESTAMP(), UTC_TIMESTAMP(),'-1')"
local getPlayerIdQuery = "SELECT id, spawntime FROM players WHERE steamid = '%s'"
local updatePlayeQuery = "UPDATE players SET nick='%s',rank='%s',isadmin='%d',lastseen=UTC_TIMESTAMP(),status='1' WHERE steamid='%s'"
local updateSpawnQuery = "UPDATE players SET nick='%s',rank='%s',isadmin='%d',lastseen=UTC_TIMESTAMP(),spawntime=UTC_TIMESTAMP(),status='1' WHERE steamid='%s'"
local trackPlayerQuery = "INSERT INTO player_log(player_id, start_period, playtime) VALUES('%d', '%s', '%s') ON DUPLICATE KEY UPDATE playtime=playtime+'%d'"
local addNewServeQuery = "INSERT INTO servers(address, gamemode, lastupdate) VALUES('%s', '%d', UTC_TIMESTAMP())"
local getServerIdQuery = "SELECT id FROM servers WHERE address = '%s'"
local recordCrashQuery = "INSERT INTO crashlog(serverid, time, status) VALUES('%d', UTC_TIMESTAMP(), '1')"

local CRASH_CHECK_FILE = "crash_check.txt"

function setPlayerID(steamId, id, spawntime)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamId then
			v.SkiID = id
			v.SkiSpawn = spawntime
		end
	end
end


local function getUserId(steamid, nick)

	local escpName = SkiWeb.db:escape( nick )
	local qTab = {}
	qTab.cb = function(q, sdata)
	   if not SkiWeb:checkQuery(q) then			
			local qwe = {}
			qwe.cb = function(q,s)
				setPlayerID(steamid,q:lastInsert(), nil)
			end
			local formQuery = string.format(inserPlayerQuery, steamid, escpName)
			SkiWeb:query(formQuery, qwe)
		end		
		local row = sdata[1];
		if row == nil then return end
		setPlayerID(steamid,row['id'], row['spawntime']);
	end
	local formPlayerQuery = string.format(getPlayerIdQuery, steamid)
	SkiWeb:query(formPlayerQuery, qTab)
end

local function UpdatePlayerInfo(ply)

	if ply.SkiID == nil then
		getUserId(ply:SteamID(), ply:Nick())
		timer.Simple(10, function()
			return UpdatePlayerInfo(ply)
		end)
	end

	local escpName = SkiWeb.db:escape(ply:Nick())
	local escpRank = SkiWeb.db:escape(ply:GetUserGroup())
	local is_admin = 0
	if ply:IsAdmin() then
		is_admin = 1
	end

	local steamid = ply:SteamID()
	local formUpdatePlayer
	if ply.SkiSpawn == nil then
		formUpdatePlayer = string.format(updateSpawnQuery, escpName, escpRank, is_admin, steamid)
	else
		formUpdatePlayer = string.format(updatePlayeQuery, escpName, escpRank, is_admin, steamid)
	end
	
	local qTab = {}
	qTab.cb = function() print(string.format("[Ski Analytics] Updated: %s ", ply:Nick())) end
	SkiWeb:query(formUpdatePlayer, qTab)
end

local function HandlePlayerConnection(steamID64, ipAddress, svPassword, clPassword, name)
	local steamid = util.SteamIDFrom64(steamID64) 
	getUserId(steamid, name)
end
hook.Add( "CheckPassword", "CheckConnectingPeople", HandlePlayerConnection )

local function HandlePlayerSpawn(ply)
	UpdatePlayerInfo(ply)
	ply.SkiTime = os.time()
end
hook.Add( "PlayerInitialSpawn", "CheckSpawningsPeople", HandlePlayerSpawn )

local function UpdatePlayTime(ply)

	if ply.SkiID == nil then
		getUserId(ply:SteamID(), ply:Nick())
		timer.Simple(5, function()
			return UpdatePlayTime(ply)
		end)
	else

		local escpName = SkiWeb.db:escape(ply:Nick())
		local escpRank = SkiWeb.db:escape(ply:GetUserGroup())
		local playtime = os.time() - ply.SkiTime

		cur_week = os.date("%V-%Y")

		local qTab = {}
		qTab.cb = function(a,b)
			ply.SkiTime = os.time()
		end
		local formUpdateTimes = string.format(trackPlayerQuery, ply.SkiID, cur_week, playtime, playtime)
		SkiWeb:query(formUpdateTimes, qTab)
	end
end

local function checkTimes()
	for k,v in pairs(player.GetAll()) do
		UpdatePlayTime(v)
	end
end
timer.Create("CheckPlayersTime", 600, 0, checkTimes)

local function GetServerID()
	local qTab = {}
	qTab.cb = function(q, sdata)
	   if not SkiWeb:checkQuery(q) then			
			local qwe = {}
			qwe.cb = function(q,s)
				SkiWeb.ServerID = q:lastInsert()
			end

			local formInsertt = string.format(addNewServeQuery, SkiWeb.ServerAddress, SkiWeb.Gamemode)
			SkiWeb:query(formInsertt, qwe)
		end
		local row = sdata[1];
		if row == null then return GetServerID() end
		SkiWeb.ServerID = row['id']
	end
	local formGetId = string.format(getServerIdQuery, SkiWeb.ServerAddress)
	SkiWeb:query(formGetId, qTab)
end

//
// Crash checking/detecting - Write a bit into a file in Initliaze - modify it in Shutdown - If its not the shutdown
// value on intiliaze log a crash

local function RecordCrash()
	local formGetId = string.format(recordCrashQuery, SkiWeb.ServerID)
	SkiWeb:query(formGetId, {cb = false})
end

local function recordShutdown()
	file.Write(CRASH_CHECK_FILE, "1") 
end
hook.Add( "ShutDown", "SkiAnalytics - Shutdown hook", recordShutdown )

local function recordShutdown()
	if file.Exists(CRASH_CHECK_FILE,"DATA") then
		local crashCheck = file.Read(CRASH_CHECK_FILE,"DATA") 
		if crashCheck != "1" then
			RecordCrash()
		end
	end
	file.Write(CRASH_CHECK_FILE, "0")
end

local function intil()
	timer.Simple(2, GetServerID)
	timer.Simple(10, recordShutdown)
end
hook.Add( "Initialize", "SkiAnalytics - Initialize", intil )


