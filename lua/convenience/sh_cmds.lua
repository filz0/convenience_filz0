// Commands created with concommand.Add

--[[
==================================================================================================
                    SERVER COMMANDS
==================================================================================================
--]]

if SERVER then
    
end

--[[
==================================================================================================
                    CLIENT COMMANDS
==================================================================================================
--]]

if CLIENT then
    concommand.Add("conv_strip", function(ply, cmd, args)
        net.Start("ConvStrip")
        net.SendToServer()
    end)

    concommand.Add("conv_giveammo", function(ply, cmd, args)
        net.Start("ConvGiveAmmo")
        net.SendToServer()
    end)
end
