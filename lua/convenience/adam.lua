CONV_LOAD_TIMES = (CONV_LOAD_TIMES && CONV_LOAD_TIMES + 1) or 1
print("CONV loaded "..CONV_LOAD_TIMES.." time(s)!")


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