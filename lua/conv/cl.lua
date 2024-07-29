--[[
==================================================================================================
                    COMMANDS
==================================================================================================
--]]


-- Strip the players weapons and ammo on server from client
concommand.Add("conv_strip", function(ply, cmd, args)
    net.Start("ConvStrip")
    net.SendToServer()
end)


-- Give ammo to all weapons for a player on server from client
concommand.Add("conv_giveammo", function(ply, cmd, args)
    net.Start("ConvGiveAmmo")
    net.SendToServer()
end)

--[[
==================================================================================================
                    TOOL MENU
==================================================================================================
--]]

-- A convenient way to add toolmenu options
function conv.addToolMenu(tab, cat, name, func)
    conv.toolMenuFuncs = conv.toolMenuFuncs or {}
    conv.toolMenuFuncs[tab.."_"..cat.."_"..name] = {tab=tab, cat=cat, name=name, func=func}
end