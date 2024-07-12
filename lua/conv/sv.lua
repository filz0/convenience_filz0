--[[
==================================================================================================
                    COMMANDS
==================================================================================================
--]]


-- Runs files in the 'autorun' folder, if no file name is given, it will instead run conv's autorun file.
concommand.Add("conv_arun", function(ply, _, args)

    if !ply:IsSuperAdmin() then
        return
    end

    print("[CONV] Doing arun...")

    local fname = args[1]

    if !fname then
        fname = "conv"
        MsgN("[CONV] Doing lib reload")
    end

    AddCSLuaFile( 'autorun/'..fname..'.lua' )
    include( 'autorun/'..fname..'.lua' )

    for _, ply in player.Iterator() do
        ply:SendLua("include('autorun/"..fname..".lua')")
    end

end)