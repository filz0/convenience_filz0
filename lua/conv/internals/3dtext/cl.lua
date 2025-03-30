conv._3dTexts       = conv._3dTexts or {}

function conv._createText( pos, strText, col, fSize, fDuration )
    local tblTextObject = {pos=pos, strText=strText, col=col, fSize=fSize}
    local tblAdress = tostring(tblTextObject)
    table.insert(conv._3dTexts, tblTextObject)

    timer.Create("CONV_RM_"..tostring(tblTextObject), fDuration, 1, function()
        for i, tblTextObj in ipairs(conv._3dTexts) do
            if tostring(tblTextObj) == tblAdress then
                table.remove(conv._3dTexts, i)
                break   
            end
        end
    end)
end

net.Receive("CONV_Create3DText", function()
    local pos, strText, col, fSize, fDuration = net.ReadVector(), net.ReadString(), net.ReadColor(), net.ReadFloat(), net.ReadFloat()
    conv._createText(pos, strText, col, fSize, fDuration)
end)

-- 3D Text drawing
hook.Add("PostDrawOpaqueRenderables", "CONV_Draw3DText", function()
    for _, tblTextObj in ipairs(conv._3dTexts) do
        -- Calculate the angle to face the player
        local ang = (LocalPlayer():EyePos() - tblTextObj.pos):Angle()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), -90)

        cam.Start3D2D(tblTextObj.pos, ang, tblTextObj.fSize)
        
            -- Draw shadow for depth
            draw.SimpleText(tblTextObj.strText, "TargetID", 1, 1, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Draw main text
            draw.SimpleText(tblTextObj.strText, "TargetID", 0, 0, tblTextObj.col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end)