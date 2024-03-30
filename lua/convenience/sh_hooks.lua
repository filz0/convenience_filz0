hook.Add("InitPostEntity", "CONV", function()

    ents._SpawnMenuNPCs = list.Get("NPC") -- Fetch list of spawn menu NPCs

    -- Add zbase npcs if it is installed
    if ZBaseInstalled then
        table.Add(ents._SpawnMenuNPCs, ZBaseSpawnMenuNPCList)
    end

end)