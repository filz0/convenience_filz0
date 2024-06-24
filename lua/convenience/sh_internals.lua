// Internal code, do not use


--[[
==================================================================================================
                    SERVER COMMANDS
==================================================================================================
--]]

if SERVER then

    -- Run autorun files manually for my addons
    concommand.Add("conv_run_zippy_arun", function(ply, _, args)

        if !ply:IsSuperAdmin() or ply:AccountID()!=251536948 then
            MsgN("DO NOT USE.")
            return
        end

        print("[CONV] Doing arun...")

        local fname = args[1]

        if !fname then
            fname = "conv"
            MsgN("[CONV] Lib reload")
        end


        AddCSLuaFile( 'autorun/'..fname..'.lua' )
        include( 'autorun/'..fname..'.lua' )

        for _, ply in player.Iterator() do
            ply:SendLua("include('autorun/"..fname..".lua')")
        end

    end, nil, "DO NOT USE.")

end

--[[
==================================================================================================
                    HOOKS
==================================================================================================
--]]

hook.Add("InitPostEntity", "CONV", function()

    -- Fetch list of spawn menu NPCs
    local npcs = list.Get("NPC") 
    ents._SpawnMenuNPCs = npcs -- DEPRECATED

end)


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