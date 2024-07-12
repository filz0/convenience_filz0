--[[
==================================================================================================
                    CONV AUTORUN
==================================================================================================
--]]

conv = conv or {}

AddCSLuaFile("conv/cl.lua")
AddCSLuaFile("conv/sh.lua")

if CLIENT then
	include("conv/cl.lua")
end

include("conv/sh.lua")

if SERVER then
	include("conv/sv.lua")
end

conv.includeDir("convenience")

MsgN("Zippy's library loaded!")

--[[
==================================================================================================
                    MESSAGE TEMPLATE
==================================================================================================
--]]


-- The message to show when CONV is not installed
-- if CLIENT then
--     function MissingConvMsg()
--         local frame = vgui.Create("DFrame")
--         frame:SetSize(300, 125)
--         frame:SetTitle("Missing Library!")
--         frame:Center()
--         frame:MakePopup()

--         local text = vgui.Create("DLabel", frame)
--         text:SetText("This server does not have the CONV library installed, some addons may function incorrectly. Click the link below to get it:")
--         text:Dock(TOP)
--         text:SetWrap(true)  -- Enable text wrapping for long messages
--         text:SetAutoStretchVertical(true)  -- Allow the text label to stretch vertically
--         text:SetFont("BudgetLabel")

--         local label = vgui.Create("DLabelURL", frame)
--         label:SetText("CONV Library")
--         label:SetURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3146473253")
--         label:Dock(BOTTOM)
--         label:SetContentAlignment(5)  -- 5 corresponds to center alignment
--     end
-- elseif SERVER && !file.Exists("autorun/conv.lua", "LUA") then
--     -- Conv lib not on on server, send message to clients
--     hook.Add("PlayerInitialSpawn", "convenienceerrormsg", function( ply )
--         local sendstr = 'MissingConvMsg()'
--         ply:SendLua(sendstr)
--     end)
-- end