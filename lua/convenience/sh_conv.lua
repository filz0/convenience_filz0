conv = {} -- "conv library"
local Developer = GetConVar("developer")



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


    -- Checks if any player can see this position right now
function conv.playersSeePos( pos )
    for _, ply in player.Iterator() do
        if ply:PosInView(pos) then
            return true
        end
    end
end


    -- Debug Overlay QOL
    -- https://wiki.facepunch.com/gmod/debugoverlay
    -- conv.Overlay("Something", function()
    --     return {}
    -- end)
function conv.Overlay( funcname, argsFunc )
    if !Developer:GetBool() then return end
    local args = argsFunc()
    debugoverlay[funcname](unpack(args))
end



-- function conv.option( data )
--     local option = {}
--     option.cvar = data.cvar
--     option.type = data.dermaType
-- end


--     -- Create a tool menu where:
--     -- Options should be a sequential table with options created by conv.option()
-- function conv.createToolMenu( tab, category, name, options )
-- end