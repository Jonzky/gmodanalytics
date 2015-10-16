require( "mysqloo" )

include("mapvotes.lua")
include("skianalytics.lua")

SkiWeb = {}
SkiWeb.ServerID = nil
//Game server address in the format IP:Port
SkiWeb.ServerAddress = ""
//Gamemode id, choose your own (e.g. TTT = 1)
SkiWeb.Gamemode = 1

SkiWeb.Host = ""
SkiWeb.Username = ""
SkiWeb.Password = ""
SkiWeb.Database_name = ""
SkiWeb.Database_port = 3306

//Dont touch
SkiWeb.connected = false;
SkiWeb.dbqueue = {}

function SkiWeb:connectToDatabase()
	
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







