print("CONV INIT!!!!")


-- Add client lua files
AddCSLuaFile("sh_conv.lua")
AddCSLuaFile("sh_misc.lua")
AddCSLuaFile("sh_ent.lua")
AddCSLuaFile("sh_hooks.lua")


-- Shared
include("sh_conv.lua")
include("sh_misc.lua")
include("sh_ent.lua")
include("sh_hooks.lua")


-- Server
if SERVER then
    include("sv_ents.lua")
end