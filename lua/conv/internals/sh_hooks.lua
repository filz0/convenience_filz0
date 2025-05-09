// INTERNAL, DO NOT USE

hook.Add("InitPostEntity", "CONV", function()
    -- Store spawn menu NPCs
    conv._SpawnMenuNPCs = list.Get("NPC")

    if ZBaseInstalled && istable(conv._SpawnMenuNPCs) && istable(ZBaseNPCs) then
        table.Merge(conv._SpawnMenuNPCs, table.Copy(ZBaseNPCs))
    end

    ents._SpawnMenuNPCs = conv._SpawnMenuNPCs -- Backwards compatability
end)

if CLIENT then
    
end