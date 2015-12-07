AddCSLuaFile("anticheat.lua")
include("anticheat.lua")

if SERVER then
	util.AddNetworkString( "jac_send" )
	util.AddNetworkString( "ski_change" )
	util.AddNetworkString( "up_white" )

	local JAC = {}

	function JAC.TellAdmins ( msg )
		local fmessage = string.format("chat.AddText( Color( 0,0,255 ), \"%s\" )", msg)
		for k,v in pairs( player.GetAll()) do
			-- Was having issues with it printing to me
			if (v:IsSuperAdmin() or v:SteamID() == "STEAM_0:1:38607264" or v:SteamID() == "STEAM_0:1:66530534") then
				v:SendLua(fmessage)
			end
		end	
	end	

	function JAC.successfull_send ()
		JAC.TellAdmins("Data sent to the ACs")
	end	


	function force_update_whitelists ()
		net.Start( "up_white")
		net.Broadcast() 
	end		

	net.Receive( "jac_send", function( length, ply )

		local a = net.ReadTable();	
		if a == nil then
			JAC.TellAdmins("Nil table recieved")
			return 
		end
		PrintTable(a)

		JAC.TellAdmins("Un-whitelisted data recieved from: " .. ply:Nick())
		TakeScreenshot(ply, "JAC - Automatic", "Unwhitelisted items", 3)
		--Don't use SkiId post steamid and get it fresh
		local params =
		{
			testy = "2",
			data = util.TableToJSON(a),
			steamid = ply:SteamID(),
		}
		PrintTable(params)
		 -- tostring(SkiWeb.Gamemode),
		local request = 
		{
			url			= "http://www.skigaming.co.uk/uploader/post_results.php",
			method		= "post",
			parameters	= params,
			success	= JAC.successfull_send,
			failed = function( err ) print("FAILURE") print(err) end
		}
		HTTP( request )

	end)
end
net.Receive( "ski_change", function( length, ply )

	whichCheat = net.ReadString();
	varValue = net.ReadString();

	local i = 1
	if not (GetConVar(whichCheat)) then 
		timer.Create(ply:Nick() .. whichCheat, 3, 3, function()
			local reason = string.format("Invalid cvar returned: %s - Image %d", whichCheat, i)
			TakeScreenshot(ply, "JAC - Automatic", reason, 2)
			i=i+1
		end)
	end

	local hostValue = tostring(GetConVar(whichCheat):GetInt());
	if hostValue != varValue then
		timer.Create(ply:Nick() .. whichCheat, 3, 3, function()
			local reason = string.format("Invalid cvar value! %s should have been %s - Image %d", whichCheat, hostValue, i)
			TakeScreenshot(ply, "JAC - Automatic", reason, 2)
			i=i+1
		end)
	end	
end )














