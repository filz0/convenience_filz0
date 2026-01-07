include("shared.lua")

function ENT:Draw()
    local ang = (LocalPlayer():EyePos() - self:GetPos()):Angle()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), -90)

    cam.Start3D2D(self:GetPos(), ang, self:GetfSize())

        -- Draw shadow for depth
        draw.SimpleText(self:GetstrText(), "TargetID", 1, 1, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Draw main text
        draw.SimpleText(self:GetstrText(), "TargetID", 0, 0, self:GetvecColor():ToColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end