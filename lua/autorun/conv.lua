--[[
==================================================================================================
                    THE LIBRARY
==================================================================================================
--]]


conv = {}


--[[
==================================================================================================
                    INCLUDE FILES
==================================================================================================
--]]


local function IncludeFiles()

    local files = file.Find("convenience/*", "LUA")

    -- Might serve as backwards compatability...
    AddCSLuaFile("convenience/adam.lua")
    include("convenience/adam.lua")


    for _, filename in ipairs(files) do
        filepathname = "convenience/"..filename
        if string.StartsWith(filename, "cl_") then

            AddCSLuaFile(filepathname)

            if CLIENT then
                include(filepathname)
            end

        elseif string.StartsWith(filename, "sh_") then

            AddCSLuaFile(filepathname)
            include(filepathname)

        elseif string.StartsWith(filename, "sv_") && SERVER then

            include(filepathname)

        end
    end
end


IncludeFiles()


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
-- elseif SERVER && !file.Exists("autorun/conv_adam.lua", "LUA") then
--     -- Conv lib not on on server, send message to clients
--     hook.Add("PlayerInitialSpawn", "convenienceerrormsg", function( ply )
--         local sendstr = 'MissingConvMsg()'
--         ply:SendLua(sendstr)
--     end)
-- end