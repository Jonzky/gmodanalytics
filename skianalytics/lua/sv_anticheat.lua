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

net.Receive( "JACSend", function( length, ply )

	local a = net.ReadTable();	
	if a == nil then
		JAC.TellAdmins("Nil table recieved")
		return 
	end

	--Don't use SkiId post steamid and get it fresh
	local params =
	{
		token = "",
		data = util.TableToJSON(a),
		steamid = ply:SteamID()
	}

	local request = 
	{
		url			= "",
		method		= "post",
		parameters	= params,
		success	= JAC.successfull_send,
		failed = function( err ) print(err) end
	}
	HTTP( request )

end)



