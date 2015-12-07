require( "mysqloo" )

include("mapvotes.lua")
include("sv_screenshots.lua")
include("sv_serverinfo.lua")
include("play_times.lua")
include("skianalytics.lua")

SkiWeb = {}

SkiWeb.ServerID = nil
//TTT = 1
SkiWeb.Gamemode = 99

SkiWeb.Host = ""
SkiWeb.Username = ""
SkiWeb.Password = ""
SkiWeb.Database_name = ""
SkiWeb.Database_port = 3306
SkiWeb.connected = false;

SkiWeb.STATUS_READY    = mysqloo.DATABASE_CONNECTED;
SkiWeb.STATUS_WORKING  = mysqloo.DATABASE_CONNECTING;
SkiWeb.STATUS_OFFLINE  = mysqloo.DATABASE_NOT_CONNECTED;
SkiWeb.STATUS_ERROR    = mysqloo.DATABASE_INTERNAL_ERROR;
SkiWeb.dbqueue = {}


function game.ProcessIP( hostip )
    local ip = {}
    ip[ 1 ] = bit.rshift( bit.band( hostip, 0xFF000000 ), 24 )
    ip[ 2 ] = bit.rshift( bit.band( hostip, 0x00FF0000 ), 16 )
    ip[ 3 ] = bit.rshift( bit.band( hostip, 0x0000FF00 ), 8 )
    ip[ 4 ] = bit.band( hostip, 0x000000FF )
 
    return table.concat( ip, "." ) .. ":" .. GetConVarString( "hostport" )
end

function game.GetLocalIP()
    local hostip = GetConVarString( "hostip" ) -- GetConVarNumber is inaccurate
    hostip = tonumber( hostip )
    return game.ProcessIP( hostip )
end

hook.Add("")


function SkiWeb:connectToDatabase()
	
	SkiWeb.ServerAddress = game.GetLocalIP()

	print("[SkiWeb] Trying to connect to the database") 

	SkiWeb.db = mysqloo.connect(SkiWeb.Host, SkiWeb.Username, SkiWeb.Password, SkiWeb.Database_name, SkiWeb.Database_port)
	SkiWeb.db.onConnected = function() 	
		
		if SkiWeb.dbqueue then
			for k, v in pairs( SkiWeb.dbqueue ) do
				SkiWeb:query( v[ 1 ], v[ 2 ]  )
			end
			SkiWeb.dbqueue = {}
		end	
			
		print("[SkiWeb] Connected to database") 
		SkiWeb.connected = true;
	end
	SkiWeb.db.onConnectionFailed = function(self, err)
		SkiWeb.connected = false;
		print("[SkiWeb]Failed to connect to the database: ", err, ". Retrying in 30 seconds.");
		timer.Simple(30, function()
			SkiWeb.db:connect()
		end);
	end	
	SkiWeb.db:connect()
end
hook.Add( "Initialize", "SkiWeb DB - connect", function () SkiWeb:connectToDatabase() end ); 

function SkiWeb:checkQuery(query)
    local info = query:getData()
    if info[1] ~= nil then
		return true
    else
		return false
    end
end 

function SkiWeb:notifyerror(...)
    ErrorNoHalt("[", os.date(), "][SkiWeb] ", ...);
    ErrorNoHalt("\n");
    print();
end

function SkiWeb:notifymessage(...)
    local words = table.concat({"[",os.date(),"][SkiWeb] ",...},"").."\n";
    ServerLog(words);
    Msg(words);
end


function SkiWeb:query(sql, qTab)

	local callback = qTab.cb
    local query = SkiWeb.db:query(sql)

	if !query then
		ServerLog("[SkiWeb] Query is empty?\n")
		if ( SkiWeb.db:status() != mysqloo.DATABASE_CONNECTED ) then
			SkiWeb.db:connect()
			ErrorNoHalt("[SkiWeb] Empty query, retrying connection.\n")
			return
		else
			error("[SkiWeb] Empty query, we're already connected.\n")
		end
	end

	query.onSuccess = function(_, data)
		if callback then 
			callback(_, data)
		end
	end
	
	query.onError = function(_, err, sql)
		ServerLog("[SkiWeb][ERROR] "..sql.."\n")
		if ( (SkiWeb.db:status() != mysqloo.DATABASE_CONNECTED) && #SkiWeb.dbqueue != 0 ) then
			table.insert( SkiWeb.dbqueue, { sql, qTab } )
			SkiWeb.db:connect()
			return
		elseif SkiWeb.db:status() == mysqloo.DATABASE_CONNECTED then
			print("[SkiWeb] Error with the query!!!")
			print(err)
			print(sql)
		else
			SkiWeb.db:connect()
			SkiWeb.db:wait()
		end
	end	
	query:start()
end







