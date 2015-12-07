local GetMapIdsQuery = "SELECT id FROM maps WHERE name = '%s'"
local addNewMapQuery = "INSERT INTO maps(name, firstseen) VALUES('%s', UTC_TIMESTAMP())"
local mapTracksQuery = "INSERT INTO map_votes(mapid, date_period, server, total_votes, total_plays) VALUES('%d', '%s', '%d', '%d', 0) ON DUPLICATE KEY UPDATE total_votes=total_votes+'%d'"
local mapPlayedQuery = "INSERT INTO map_votes(mapid, date_period, server, total_votes, total_plays) VALUES('%d', '%s', '%d', 0, 1) ON DUPLICATE KEY UPDATE total_plays=total_plays+1"


local function update_map_id(mapid, ammount)
    local cur_week = os.date("%V-%Y")
    local formGetId = string.format(mapTracksQuery, mapid, cur_week, SkiWeb.ServerID, ammount, ammount)
    SkiWeb:query(formGetId, {cb = false})
end

local function update_map_votes(mapname, ammount)

    print(string.format("Updating map: %s with votes: %d", mapname, ammount))
    local escpName = SkiWeb.db:escape( mapname )
    local qTab = {}
    qTab.cb = function(q, sdata)
       if not SkiWeb:checkQuery(q) then         
            local qwe = {}
            qwe.cb = function(q,s)
                update_map_id(q:lastInsert(), ammount)
            end
            local formQuery = string.format(addNewMapQuery, mapname)
            SkiWeb:query(formQuery, qwe)
        end     
        local row = sdata[1];
        if row == nil then return end
        update_map_id(row['id'], ammount);
    end
    local formMapQuery = string.format(GetMapIdsQuery, mapname)
    SkiWeb:query(formMapQuery, qTab)
end

local function update_map_played()

    if SkiWeb.db == nil || SkiWeb.ServerID == nil then
        timer.Simple(5, function()
            update_map_played()
        end)
        return
    end

    local mapname = game.GetMap()
    local escpName = SkiWeb.db:escape( mapname )
    local cur_week = os.date("%V-%Y")
    local qTab = {}
    qTab.cb = function(q, sdata)
       if not SkiWeb:checkQuery(q) then         

            local qwe = {}
            qwe.cb = function(q,s)
                mapid = q:lastInsert()
                local formGetId = string.format(mapPlayedQuery, mapid, cur_week, SkiWeb.ServerID)
                SkiWeb:query(formGetId, {cb = false})
            end
            local formQuery = string.format(addNewMapQuery, mapname)            
            SkiWeb:query(formQuery, qwe)
        end 

        local row = sdata[1];
        if row == nil then return end

        local formGetId = string.format(mapPlayedQuery, row['id'], cur_week, SkiWeb.ServerID)
        SkiWeb:query(formGetId, {cb = false})

    end
    local formMapQuery = string.format(GetMapIdsQuery, mapname)
    SkiWeb:query(formMapQuery, qTab)
end
hook.Add("PostGamemodeLoaded", "SkiAnalytics - Increment map played counter", update_map_played)
 
function MuhVote(length, current, limit, prefix)
    current = current or MapVote.Config.AllowCurrentMap or false
    length = length or MapVote.Config.TimeLimit or 28
    limit = limit or MapVote.Config.MapLimit or 24

    local is_expression = false

    if not prefix then
        local info = file.Read(GAMEMODE.Folder.."/"..GAMEMODE.FolderName..".txt", "GAME")

        if(info) then
            local info = util.KeyValuesToTable(info)
            prefix = info.maps
        else
            error("MapVote Prefix can not be loaded from gamemode")
        end

        is_expression = true
    else
        if prefix and type(prefix) ~= "table" then
            prefix = {prefix}
        end
    end
    
    local maps = file.Find("maps/*.bsp", "GAME")
    
    local vote_maps = {}
    
    local amt = 0

    for k, map in RandomPairs(maps) do
        local mapstr = map:sub(1, -5):lower()
        if(not current and game.GetMap():lower()..".bsp" == map) then continue end

        if is_expression then
            if(string.find(map, prefix)) then -- This might work (from gamemode.txt)
                vote_maps[#vote_maps + 1] = map:sub(1, -5)
                amt = amt + 1
            end
        else
            for k, v in pairs(prefix) do
                if string.find(map, "^"..v) then
                    vote_maps[#vote_maps + 1] = map:sub(1, -5)
                    amt = amt + 1
                    break
                end
            end
        end
        
        if(limit and amt >= limit) then break end
    end
    
    net.Start("RAM_MapVoteStart")
        net.WriteUInt(#vote_maps, 32)
        
        for i = 1, #vote_maps do
            net.WriteString(vote_maps[i])
        end
        
        net.WriteUInt(length, 32)
    net.Broadcast()
    
    MapVote.Allow = true
    MapVote.CurrentMaps = vote_maps
    MapVote.Votes = {}
    
    timer.Create("RAM_MapVote", length, 1, function()
        MapVote.Allow = false
        local map_results = {}
        
        for k, v in pairs(MapVote.Votes) do
            if(not map_results[v]) then
                map_results[v] = 0
            end
            
            for k2, v2 in pairs(player.GetAll()) do
                if(v2:SteamID() == k) then
                    if(MapVote.HasExtraVotePower(v2)) then
                        map_results[v] = map_results[v] + 2
                    else
                        map_results[v] = map_results[v] + 1
                    end
                end
            end
            
        end
        
        local winner = table.GetWinningKey(map_results) or 1
        
        net.Start("RAM_MapVoteUpdate")
            net.WriteUInt(MapVote.UPDATE_WIN, 3)
            
            net.WriteUInt(winner, 32)
        net.Broadcast()
        


        local map = MapVote.CurrentMaps[winner]

        for k, v in pairs(map_results) do
            if v==0 then continue end
            update_map_votes(MapVote.CurrentMaps[k], v)
        end
        
        timer.Simple(6, function()
            hook.Run("MapVoteChange", map)
            RunConsoleCommand("changelevel", map)
        end)
    end)
end
hook.Add("PostGamemodeLoaded", "SkiAnalytics - Map.Vote fix", function()
    timer.Create("SkiAnalytics - My map vote", 30, 0, function() 
        if MapVote then
            MapVote.Start = MuhVote
        end
    end)
end)