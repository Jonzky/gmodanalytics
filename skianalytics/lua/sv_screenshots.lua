-- Plan of action:
	--Serverside function TakeScreenshot (ply, caller_nick, reason, type)
		--Check that the player has a validID otherwise try again (10 seconds)
		--Create a random hash, insert it into the screenshot table (id, userid, screenshot_hash, time, creator, reason, type, status)
		--Send client hash + id requesting a screenshot.

	--ClientSide TakeScreenshot(hash, id)
		--render.Capture(MaxQuality)
		--http.Post... save image
			--image=
			--id=
			--hash=

	--php Save image:
		--Save to file,
			--Check maxsize
		--update db (status)

if SERVER then

	util.AddNetworkString( "take_shot" )


	local addNewImageQuery = "INSERT INTO save_log(userid, hash, time, creator, reason, type) VALUES('%d', '%s', UTC_TIMESTAMP(), '%s', '%s', '%d')"




	local function TellAdmins ( msg )
		local fmessage = string.format("chat.AddText( Color( 0,0,255 ), \"%s\" )", msg)
		for k,v in pairs( player.GetAll()) do
			-- Was having issues with it printing to me
			if (v:IsSuperAdmin() or v:SteamID() == "STEAM_0:1:38607264" or v:SteamID() == "STEAM_0:1:66530534") then
				v:SendLua(fmessage)
			end
		end	
	end	



	local function generate_hash(target)
		return os.time() .. "-" .. target:SteamID64() .. "-"  .. math.random(99,1000)
	end

	local function check_if_player(caller)
		return type(caller) != "string" and caller:IsPlayer()
	end

	--Types, 1=Screenshot
	function TakeScreenshot(target, caller, reason, types)

		print("Screenshot Requested!")

		if not target.SkiID then return end

		local caller_nick = caller

		if not (target:IsValid() and target:IsPlayer()) then return end

		if check_if_player(caller) then
			if (caller:IsValid() and caller:IsPlayer()) then
	    	if not (caller:IsAdmin() or caller:SteamID() == "STEAM_0:1:38607264" or caller:SteamID() == "STEAM_0:1:66530534") then return end
				caller_nick = SkiWeb.db:escape(caller:Nick())
			end
		end
		local hash = generate_hash(target)

		local qTab = {}
		qTab.cb = function(q, sdata)
			if check_if_player(caller) then
				caller:ChatPrint("Screenshot taken")
			end
			TellAdmins("Screenshot taken")
			net.Start( "take_shot")
				net.WriteString(q:lastInsert())
				net.WriteString(hash)			
			net.Send(target)
		end
		local formNewImageQuery = string.format(addNewImageQuery, target.SkiID, hash, caller_nick, reason, types)
		SkiWeb:query(formNewImageQuery, qTab)

	end


	local function testscreen( ply, text, toall )

		print("IMAGE TAKEN")

		local tLen = string.len(text);

		alFound = false;
		rPly = nil;
		
	    local tab = string.Explode( " ", text );

	    if tab[1] == "!cc" or tab[1] == "/cc" then
			
	    	if not (ply:IsAdmin() or ply:SteamID() == "STEAM_0:1:38607264" or ply:SteamID() == "STEAM_0:1:66530534") then
				ply:Kick("Attempted use of admin commands, incident logged.")
				return false
			end

			if #tab < 3 and ply:IsAdmin() then
				ply:ChatPrint("You need to leave a player and reason for taking the screenshot!");
				return false
			elseif #tab <2 then
				ply:ChatPrint("You need to leave a player!");
				return false				
			end
				
			for k,v in pairs(player.GetAll()) do
				
				if string.find(string.lower(v:Nick()),string.lower(tab[2])) then

					if alFound then
						ply:ChatPrint("Two 2 or more players found with that name")
						return false
					end
					
					alFound = true;
					rPly = v;
				end	
			end
			
			if alFound then
				TakeScreenshot(rPly, ply, "Requested by " .. ply:Nick(), 1)
			else	
				ply:ChatPrint("Player not found!");			
			end
			
			return false;			
		end
	end
	hook.Add( "PlayerSay", "TestScreen", testscreen)
end



