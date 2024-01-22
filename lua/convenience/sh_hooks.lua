hook.Add("InitPostEntity", "CONV", function()

    ents._SpawnMenuNPCs = list.Get("NPC") -- Fetch list of spawn menu NPCs

end)