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
