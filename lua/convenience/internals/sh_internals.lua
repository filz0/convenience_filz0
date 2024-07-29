// Internal code, do not use


--[[
==================================================================================================
                    HOOKS
==================================================================================================
--]]

hook.Add("InitPostEntity", "CONV", function()

    conv._SpawnMenuNPCs = list.Get("NPC")

    if ZBaseInstalled then
        table.Merge(conv._SpawnMenuNPCs, table.Copy(ZBaseNPCs))
    end

    -- Backwards compatability
    ents._SpawnMenuNPCs = conv._SpawnMenuNPCs

end)


if CLIENT then

    hook.Add("PopulateToolMenu", "CONV", function()

        -- Populate tool menu
        if istable(conv.toolMenuFuncs) then
            for k, v in pairs(conv.toolMenuFuncs) do
                spawnmenu.AddToolMenuOption(v.tab, v.cat, v.name, v.name, "", "", v.func)
            end
        end

    end)

end


--[[
==================================================================================================
                    NET CODE
==================================================================================================
--]]

if SERVER then

    -- Add network strings
    util.AddNetworkString("ConvStrip")
    util.AddNetworkString("ConvGiveAmmo")

    -- Strip the players weapons and ammo on server from client
    net.Receive("ConvStrip", function(len, ply)
        ply:StripWeapons()
        ply:RemoveAllAmmo()
    end)

    -- Give ammo to all weapons for a player on server from client
    net.Receive("ConvGiveAmmo", function(len, ply)
        for ammoid, ammoname in pairs(game.GetAmmoTypes()) do
            ply:GiveAmmo(game.GetCurrentAmmoMax(ammoid), ammoname)
        end
    end)

end