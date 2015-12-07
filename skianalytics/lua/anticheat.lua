if SERVER then return end

local memoryused = collectgarbage( "count" )


require("timer")
require ( "hook" )				-- Gamemode hooks


print("123321: " .. memoryused )

local _G = _G
local ___h = _G[ "hook" ][ "Add" ];
local dgi = _G["\100\101\98\117\103"]["\103\101\116\105\110\102\111"]; 
local _r = _G["\114\101\113\117\105\114\101"];
local oldCCCV = _G["\67\114\101\97\116\101\67\108\105\101\110\116\67\111\110\86\97\114"];
local oldCCV = _G["\67\114\101\97\116\101\67\111\110\86\97\114"];
local _iN = _G[ "\105\110\99\108\117\100\101" ]; 
local JAC = {}
local fuckYou = _G["render"]["Capture"]
local render = render
local file = file


local JAC = {}

JAC.preload_log 	= {};
JAC.incident_log	= {};	
JAC.whitelist_items = {};
JAC.loaded 			= false;
JAC.to_send 		= {};

local function testy_poo(code, body, head)
	JAC.whitelist_items = util.JSONToTable(body)
	JAC.loaded = true
end

function JAC.update_whitelist()
	local request = 
	{
		url			= "http://skigaming.co.uk/uploader/get_whitelist.php",
		method		= "get",
		success	= testy_poo,
		parameters = {ggame = gmod.GetGamemode().Name},
		failed = function( err ) print("FAILURE") timer.Simple(5, JAC.update_whitelist) end
	}
	HTTP( request )
end
hook.Add( "PostGamemodeLoaded", "load_meh_whitelist", JAC.update_whitelist )

function log_inccident(type, name, value, path, func)
	if not JAC.incident_log[type] then
		JAC.incident_log[type] = {}
	end
	table.insert(JAC.incident_log[type], {name = name, value = value, path = path, func = func})
	table.insert(JAC.to_send, {dtype = type, name = name, value = value, path = path, func = func})
end

function proccess_preload()

	if not JAC.loaded then
		return
	end
	for type,values in pairs(JAC.preload_log) do
		if JAC.preload_log[type] == nil then print("NILILIILI") continue end
		for k,v in pairs(JAC.preload_log[type]) do
			if JAC.whitelist_items[type] and table.HasValue(JAC.whitelist_items[type], v.value) then
				continue
			else
				log_inccident(type, v.name, v.value, v.path, v.func)
			end
		end
		JAC.preload_log[type] = {}
	end
	JAC.preload_log = nil
end


function proccess_item(type, name, value, path, func)

	if not JAC.loaded then

		if not JAC.preload_log[type] then
			JAC.preload_log[type] = {}
		end

		for k,v in pairs(JAC.preload_log[type]) do
			if v.value == value then
				return
			end
		end
		table.insert(JAC.preload_log[type], {name = name, value = value, path = path, func = func})
	else
	
		if not JAC.whitelist_items then
			JAC.whitelist_items = {}
		end

		if not JAC.whitelist_items[type] then
			JAC.whitelist_items[type] = {}
		end

		if table.HasValue(JAC.whitelist_items[type], value) then
			return
		end

		if not JAC.incident_log[type] then
			JAC.incident_log[type] = {}
		end		

		--Check here - might be inefficient, but if they reach this point they're most likely hacking so I couldn't give a shit.
		for k,v in pairs(JAC.incident_log[type]) do
			if v.value == value then
				return
			end
		end

		table.insert(JAC.incident_log[type], {name = name, value = value, path = path, func = func})
		table.insert(JAC.to_send, {dtype = type, name = name, value = value, path = path, func = func})
	end
end

function JAC.check_lists()
	local v = LocalPlayer()
	if JAC.preload_log then
		proccess_preload()
	end

	if #JAC.to_send > 0 then

		local v = LocalPlayer()
		if v and v.SteamID then
			if (v:SteamID() == "STEAM_0:0:23126654" or  v:SteamID() == "STEAM_0:1:38607264" or v:SteamID() == "STEAM_0:1:66530534") then
				PrintTable(JAC.to_send)
			end
		end

		net.Start("jac_send")
			net.WriteTable(JAC.to_send)
		net.SendToServer()
		table.Empty(JAC.to_send)
	end
end
timer.Create("CheckStuffze", 1, 0, JAC.check_lists)

/*/

Detection stuff

/*/

function CreateConVar( _a, _b, _c )

	local path = dgi and dgi( 2 ) and dgi( 2 )["short_src"] or "n/a";
	local fname = debug.getinfo(1, "n").name or "n/a";		
	local val = util.CRC(_a) .. "," .. util.CRC(path)
	proccess_item("createconvar", _a, val, path, fname)

	return oldCCV(_a, _b, _c)
end


function CreateClientConVar( _a, _b, _c, _d )
			
	local path = dgi and dgi( 2 ) and dgi( 2 )["short_src"] or "n/a";
	local fname = debug.getinfo(1, "n").name or "n/a";		
	local val = util.CRC(_a) .. "," .. util.CRC(path)
	proccess_item("createconvar", _a, val, path, fname)
		
	return oldCCCV( _a, _b, _c, _d);
end

function require( name ) 
	local path = dgi and dgi( 2 ) and dgi( 2 )["short_src"] or "n/a";
	local fname = debug.getinfo(1, "n").name or "n/a";
	local val = util.CRC(name) .. "," .. util.CRC(path)
	proccess_item("require", name, val, path, fname)
	return _r( name );		
end

function hook.Add( id, name, func )

	local path = dgi and dgi( 2 ) and dgi( 2 )["short_src"] or "n/a";
	local fname = debug.getinfo(1, "n").name or "n/a";		

	--Value = v.name .. "," v.path

	if type(name) != "string" then 
		name = "Entity" 
	end
	if type(id) != "string" then 
		id = "Entity" 
	end

	local val = util.CRC(name) .. "," .. util.CRC(id) .. "," .. util.CRC(path)
	if string and string.Replace then
		name = string.Replace(tostring(name), ":", "-")
		id = string.Replace(tostring(id), ":", "-")		
	end
	name = id .. ":" .. name
	proccess_item("hook", name, val, path, fname)

	return ___h( id, name, func );
end

function PostULXHook( id, name, func, path, fname )

	if type(name) != "string" then 
		name = "Entity" 
	end
	if type(id) != "string" then 
		id = "Entity" 
	end

	local val = util.CRC(name) .. "," .. util.CRC(id) .. "," .. util.CRC(path)
	if string and string.Replace then
		name = string.Replace(tostring(name), ":", "-")
		id = string.Replace(tostring(id), ":", "-")		
	end
	name = id .. ":" .. name
	proccess_item("hook", name, val, path, fname)
end

function include( name )
	local path = dgi and dgi( 2 ) and dgi( 2 )["short_src"] or "n/a";
	local fname = debug.getinfo(1, "n").name or "n/a";		

	--Value = v.name .. "," v.path
	local val = util.CRC(name) .. "," .. util.CRC(path)
	proccess_item("include", name, val, path, fname)
	return _iN( name );	
end

local function submitImage( params )

	local request = 
	{
		url			= "http://skigaming.co.uk/uploader/web_uploader.php",
		method		= "post",
		parameters	= params,
		success	= function() end,
		failed = function( err ) end
	}
	HTTP( request )
end

net.Receive( "up_white", function( length )
	JAC.update_whitelist()
end)


net.Receive( "take_shot", function( length )

	a = net.ReadString();
	b = net.ReadString();

	local img = fuckYou( 
	{
		['format'] = 'jpeg',
		['quality'] = 100,
		['h'] = ScrH(),
		['w'] = ScrW(),
		['x'] = 0,
		['y'] = 0
	})			
	submitImage({	
		hash = b, 
		id = a, 
		data = util.Base64Encode(img)
	}) 
end)

local blockedVars = { 
		sv_allowcslua = 0,
		host_timescale = 1,
		mat_wirefram = 0,
		sv_cheats = 0
}

function JAC.cvar_change(convar_name, value_old, value_new)

	if not blockedVars[convar_name] then return end

	if blockedVars[convar_name] != value_new then
		net.Start("ski_change");
			net.WriteString( convar_name );
			net.WriteString( value_new );
		net.SendToServer();
	end	
end
hook.Add("Initialize", "JACInit", function()
	cvars.AddChangeCallback( "sv_allowcslua", JAC.cvar_change) 
	cvars.AddChangeCallback( "sv_cheats", JAC.cvar_change) 
	cvars.AddChangeCallback( "host_timescale", JAC.cvar_change) 
	cvars.AddChangeCallback( "mat_wirefram", JAC.cvar_change) 
end)

