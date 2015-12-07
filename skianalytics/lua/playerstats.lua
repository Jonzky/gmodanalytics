	
	if gmod.GetGamemode() != "terrortown" then return end

	local PlayerStats = {}
	function TestPrint()
		print(PlayerStats)
	end

    --[[
		Helper functions
    --]]

    local plymeta = FindMetaTable( "Player" )
    function plymeta:NotTraitor() return self:GetRole() != ROLE_TRAITOR end

    local function check_rdm(first, second)
    	return (victim:IsTraitor() && attacker:IsTraitor()) || 
    		(victim:NotTraitor() && attacker:NotTraitor());	
    end

    local function find_player_by_name(name)
		for k,v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(name) then
				return v
			end	
		end
		return null
    end

    function print_player_stats(plyname)
    	local ply = find_player_by_name(plyname)
    	if IsValid(ply) then
    		PrintTable({name = ply:Nick(), stats = plyname.updates})
    	end
    end

    local empty_player_stats = 
    {
		kills = 0,
		curstreak = 0,
		streak = 0,
		deaths = 0,
		suicides = 0,
		badkills = 0,
		score = 0,
		hits = 0,
		shots = 0,
		headshots = 0,
		hskills = 0,
		innocent = 0,
		detective = 0,
		traitor = 0,
		roundswon = 0,
		roundslost = 0
	}

	function debug_print ( msg )
		local fmessage = string.format("chat.AddText( Color( 0,0,255 ), \"%s\" )", msg)

		for k,v in pairs( player.GetAll()) do
			-- Was having issues with it printing to me
			if (v:IsAdmin() or v:SteamID() == "STEAM_0:1:38607264" or v:SteamID() == "STEAM_0:1:66530534") then
				v:SendLua(fmessage)
			end
		end	
	end

	local function load_weapon_ids()
		if file.Exists("skianalytics/weapons.txt", "DATA") then
			local content = file.Read("skianalytics/weapons.txt", "DATA")
			PlayerStats.weapons = util.JSONToTable(content)
		else
			if not file.Exists("skianalytics", "DATA") then
				file.CreateDir("skianalytics")
			end
		end
		PlayerStats.loadedweapons = true
	end

    --[[
		Add meta-method for entities to get ID - or return -1 if an issue
    --]]
	local function get_weapon_id(wclass)
		
		if not PlayerStats.loadedweapons then return -1 end

		if PlayerStats.weapons['class'] then
			return PlayerStats.weapons['class']
		end

		//Check  SQL if exists 

		//Insert if not exists

		//Set PlayerStats.weapons['class'] = to incrementID

		return -1
	end


	--[[
		
		GREATEST(players, VALUES(players)), - Streak


		player.stats.
		player.stats.updates = {}
		player.stats.updates.kills
		player.stats.updates.streak
		player.stats.updates.deaths
		player.stats.updates.suicides
		player.stats.updates.badkills
		player.stats.updates.score
		player.stats.updates.hits
		player.stats.updates.shots
		player.stats.updates.headshots
		player.stats.updates.hskills
		player.stats.updates.innocent
		player.stats.updates.detective
		player.stats.updates.traitor
		player.stats.updates.roundswon
		player.stats.updates.roundslost

		player.stats.weapon.classname.kills
		player.stats.weapon.classname.deaths
		//Tricky - player.stats.weapon.classname.time_used
		player.stats.weapon.classname.dinflicted
		player.stats.weapon.classname.dreceived
		player.stats.weapon.classname.hits.shots
		player.stats.weapon.classname.hits.hits
		player.stats.weapon.classname.hits.0
		player.stats.weapon.classname.hits.1
		player.stats.weapon.classname.hits.2
		player.stats.weapon.classname.hits.3
		player.stats.weapon.classname.hits.4+...

		//Seperate Module
	
		player.stats.playtime
		player.stats.playtime.alive
		player.stats.playtime.active
		player.stats.playtime.idle

		//Seperate Module
	
		player.stats.ghostdm.kills
		player.stats.ghostdm.deaths
		player.stats.ghostdm.streak
		player.stats.ghostdm.playtime


	--]]



	--[[
		Commands to show stats
	--]]
	function PlayerStats.Chat(ply, text, teamchat)
		debug_print(string.format("%s has said something the game!", ply:Nick()))	
	end

	--[[
		Setup a platers tables after joining + make sure they have their id
	--]]
	function PlayerStats.InitialSpawn(ply)
		debug_print(string.format("%s has spawned in the game!", ply:Nick()))
		ply.stats = ply.stats or {}
		ply.stats.updates = table.Copy(empty_player_stats)
	end

	--[[
		Keeps track of kills, deaths for players + weapons
	--]]
	function PlayerStats.Death(victim, inflictor, attacker)
		
		if victim:IsGhost || not victim:IsTerror() return end

		if victim == inflictor then
			victim.stats.updates.suicides += 1;
		end

		if check_rdm(victim, attacker) then
			attacker.badkills += 1
		elseif attacker:IsPlayer() && attacker:IsTerror() then
			
			victim.stats.updates.deaths += 1;
			if victim.stats.updates.curstreak > victim.stats.updates.streak then
				victim.stats.updates.streak = victim.stats.updates.curstreak;
			end

			attacker.stats.updates.kills +=1;
			attacker.stats.updates.curstreak +=1;

			if victim.stats.lastHitGroup && victim.stats.lastHitGroup == HITGROUP_HEAD then
				inflictor
			end

			--Do weapon stats
			--inflictor:GetClass()
		else
			victim.stats.updates.deaths += 1;
		end
		debug_print(string.format("%s has killed %s!", victim:Nick(), attacker:Nick()))	
	end

	--[[
		Save a players info
	--]]
	function PlayerStats.Disconnect(ply)
		debug_print(string.format("%s has left the game!", ply:Nick()))	
	end


	--[[
/		Keeps track of round stats (rounds played + roles)
	--]]
	function PlayerStats.RoundBegin()
		for k,v in pairs(player.GetAll()) do
			if v:IsTraitor() then
				v.stats.updates.traitor += 1;
				debug_print(string.format("%s is a traitor this round!", v:Nick()))
			elseif v:IsDetective() then
				v.stats.updates.detective += 1;
				debug_print(string.format("%s is a detective this round!", v:Nick()))
			else
				v.stats.updates.innocent += 1;
				debug_print(string.format("%s is innocent this round!", v:Nick()))
			end
		end
	end
3
	--[[
/		Keeps track of wins
	--]]
	function PlayerStats.RoundEnd(result)

		if result == WIN_TRAITOR then
			debug_print(string.format("Traitors have won!"))

			for k,v in pairs(player.stats.GetAll()) do

				if v:IsAlive() and v.stats.updates.curstreak > v.stats.updates.streak then
					v.stats.updates.streak = v.stats.updates.curstreak;
				end

				if v:IsTraitor() then
					v.stats.updates.roundswon += 1;
					debug_print(string.format("%s's team has won the round!", v:Nick()))
				elseif v:IsDetective() then
					v.stats.updates.roundslost += 1;
					debug_print(string.format("%s's team has lost the round and he was a detective!", v:Nick()))
				else
					v.stats.updates.roundslost += 1;
					debug_print(string.format("%s's team has lost the round!", v:Nick()))
				end
			end
		else
			debug_print(string.format("Innocents have won!"))
			for k,v in pairs(player.GetAll()) do

				if v:IsAlive() and v.stats.updates.curstreak > v.stats.updates.streak then
					v.stats.updates.streak = v.stats.updates.curstreak;
				end
				if v:IsTraitor() then
					v.stats.updates.roundslost += 1;
					debug_print(string.format("%s's team has lost the round!", v:Nick()))
				elseif v:IsDetective() then
					v.stats.updates.roundswon += 1;
					debug_print(string.format("%s's team has won the round and he was a detective!", v:Nick()))
				else
					v.stats.updates.roundswon += 1;
					debug_print(string.format("%s's team has won the round!", v:Nick()))			
				end
			end
		end
	end


	--[[
		Keeps track of hits
	--]]
	function PlayerStats.TracksHits(ply, hitgroup, info)
		
		local attacker = info:GetAttacker()
		local damage =  info:GetDamage()
		local inflictor = info:GetInflictor()

		local hitgroups =  {"Head", "Chest", "Stomach", "Left arm", "Right arm", "Left leg", "Right leg", "8", "9", "Hitbox gear?"}

		if IsValid(ply) && ply:IsPlayer() && ply:IsTerror() && !ply:IsGhost() then
			if IsValid(attacker) && attacker:IsPlayer() && attacker:IsTerror() && !attacker:IsGhost() then

				ply.stats.lastHitGroup = hitGroup

				attacker.stats.updates.hits += 1;

				if hitgroup == HITGROUP_HEAD then
					attacker.stats.updates.headshots += 1;
				elseif hitgroup == 0 then
					debug_print(string.format("%s has hit %s in the Generic with %s(%s) doing %s damage!", attacker:Nick(), ply:Nick(), inflictor:GetName(), inflictor:GetClass(), damage))					
				else
					debug_print(string.format("%s has hit %s in the %s with %s(%s) doing %s damage!", attacker:Nick(), ply:Nick(), hitgroups[hitgroup], inflictor:GetName(), inflictor:GetClass(), damage))
				end
			end
		end
	end


	--[[
		Keeps track of shots fired
	--]]
	function PlayerStats.FireBullets(ply, data)
		if IsValid(ply) && ply:IsPlayer() && ply:IsTerror() && !ply:IsGhost() then
			local weapon = ply:GetActiveWeapon()
			if IsValid(weapon) then

				ply.stats.updates.shots += 1;
				
				local class = weapon:GetClass()
				local name = weapon:GetName()
				debug_print(string.format("%s has fired %s (%s)!", ply:Nick(), name, class))
			end
		end
	end

	--[[
		Gets the weaponID for all weapons in game
	--]]
	function PlayerStats.ProccessWeapons()

		for k,v in pairs(player.stats.GetAll()) do


		end
	end


	hook.Add( "PlayerSay", "SkiAnalytics (playerstats) - Say", PlayerStats.Chat)
	hook.Add( "PlayerInitialSpawn", "SkiAnalytics (playerstats) - Initial spawn", PlayerStats.InitialSpawn )
	hook.Add( "PlayerDisconnected", "SkiAnalytics (playerstats) - Player disconnect", PlayerStats.Disconnect )
	hook.Add( "PlayerDeath", "SkiAnalytics (playerstats) - Player death", PlayerStats.Death )
	hook.Add( "TTTBeginRound", "SkiAnalytics (playerstats) - TTTBeginRound", PlayerStats.RoundBegin )
	hook.Add( "TTTEndRound", "SkiAnalytics (playerstats) - TTTEndRound", PlayerStats.RoundEnd )
	hook.Add( "ScalePlayerDamage", "SkiAnalytics (playerstats) - ScalePlayerDamage", PlayerStats.TracksHits )
	hook.Add( "EntityFireBullets", "SkiAnalytics (playerstats) - EntityFireBullets", PlayerStats.FireBullets )
	hook.Add( "TTTBeginRound", "SkiAnalytics (playerstats) - TTTBeginRound", PlayerStats.RoundBegin )