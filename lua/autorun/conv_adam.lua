--[[
==================================================================================================
                    THE LIBRARY
==================================================================================================
--]]


conv = {}


    -- Do something next tick/frame
function conv.callNextTick( func, ... )

    local argtbl = table.Pack(...)

    timer.Simple(0, function()
        func(unpack(argtbl))
    end)

end


    -- Do something after a certain amount of ticks/frames
function conv.callAfterTicks( ticknum, func, ... )

    conv.callNextTick( function( ... )

        if ticknum <= 0 then
            func(...)
        else
            conv.callAfterTicks( ticknum-1, func, ... )
        end
        

    end, ... )

end



    -- Create a simple derma frame
function conv.dermaFrame( title, width, height )
    local frame = vgui.Create("DFrame")
    frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
    frame:SetSize(width, height)
    frame:SetTitle(title)
    frame:MakePopup()
    return frame
end


    -- Checks if any player on the server can see this position right now
function conv.playersSeePos( pos )
    for _, ply in player.Iterator() do
        if ply:PosInView(pos) then
            return true
        end
    end
end


    -- Debug Overlay QOL
    -- https://wiki.facepunch.com/gmod/debugoverlay
    -- conv.overlay("Something", function()
    --     return {}
    -- end)
function conv.overlay( funcname, argsFunc )
    if !Developer:GetBool() then return end
    local args = argsFunc()
    debugoverlay[funcname](unpack(args))
end


    -- DEPRECATED
function conv.getSpawnMenuNPCs()
    return table.Copy(ents._SpawnMenuNPCs)
end


--[[
==================================================================================================
                    INCLUDE FILES
==================================================================================================
--]]


    -- Include the included files for conv, such as library extensions, and new commands
local function IncludeFiles()

    local files = file.Find("convenience/*", "LUA")

    -- Backwards compatability maybe...
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