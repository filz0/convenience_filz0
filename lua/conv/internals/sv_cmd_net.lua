// INTERNAL, DO NOT USE


util.AddNetworkString("ConvStrip")
util.AddNetworkString("ConvGiveAmmo")


net.Receive("ConvStrip", function(len, ply)
    ply:StripWeapons()
    ply:RemoveAllAmmo()
end)


net.Receive("ConvGiveAmmo", function(len, ply)
    for ammoid, ammoname in pairs(game.GetAmmoTypes()) do
        ply:GiveAmmo(game.GetCurrentAmmoMax(ammoid), ammoname)
    end
end)