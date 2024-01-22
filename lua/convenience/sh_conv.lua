conv = {} -- "conv library"


    -- Do something next tick/frame
function conv.callNextTick( func, ... )

    local argtbl = table.Pack(...)

    timer.Simple(0, function()
        func(unpack(argtbl))
    end)

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