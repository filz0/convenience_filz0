--[[
==================================================================================================
                    LOCALS, NO TOUCH
==================================================================================================
--]]

concommand.Add( "conv_menu_test", function(ply, cmd, args)  
    local menu = conv.createMenu( 500, 500, 1, true, "Epic Cool Menu For Settings And Other Stuffs", font, Color( 255, 0, 0, 255 ), Color( 0, 255, 0, 255 ), Color( 0, 0, 255, 255 ), tickFunc, crossFunc, "this is a help text ment for helping and shit" )
    
    for i=0, 100 do
        local DButton = menu:Add( "DButton" )
        DButton:SetText( "Button #" .. i )
        DButton:Dock( TOP )
        DButton:DockMargin( 0, 0, 0, 5 )

        local Wang = menu:Add( "DNumberWang" )
        Wang:Dock( TOP )
        Wang:SetSize(45, 26)
        Wang:SetMin(0)
        Wang:SetMax(100)
    end
end )

local color_gmod = Color( 17, 148, 240, 255 )
local color_shadow = Color( 0, 0, 0, 200 )
local color_no = Color( 0, 0, 0, 0 )

local function Derma_TextScroll( self, w, h, buffere, text, font, tColor, sColor )
    surface.SetFont( font )

    local tW, tH = surface.GetTextSize( text )
    local px, py = self:LocalToScreen( buffere, 0 )
    local pw, ph = self:LocalToScreen( w - buffere, h + tH )
    
    render.SetScissorRect( px, py, pw, ph, true )

    local x, y = w / 2 - tW / 2, h / 2 - tH / 2

    if ( tW > ( w - buffere * 2 ) ) then
        local mx, my = self:ScreenToLocal( input.GetCursorPos() )
        local diff = tW - w + buffere * 2

        x = buffere + math.Remap( math.Clamp( mx, 0, w ), 0, w, 0, -diff )
    end

    draw.SimpleText( text, font, x + 1, y + 1, sColor || color_shadow )
    draw.SimpleText( text, font, x, y, tColor || color_white )

    render.SetScissorRect( 0, 0, 0, 0, false )
end

local function menuButton( self, w, h, x, y, r, cornTab, text, font, tColor, bColor, funcClick )    
    tColor = tColor || color_white
    bColor = bColor || color_gmod
    r = r || 8
    local animDone

    local panel = vgui.Create( "DButton", self )
	panel:SetPos( x || 0, y || 0 )	
	panel:SetSize( w, h ) 
	panel:SetText( "" )
    local clickReset = CurTime()

    local col = bColor
    local hover = false

    panel.OnCursorEntered = function(self)
        hover = true
    end

    panel.OnCursorExited = function(self)
        hover = false
    end

    panel.DoClick = function(self)
        clickReset = CurTime() + 0.2
        if isfunction(funcClick) then funcClick(self) end
    end

    local colW, colB = Color( tColor.r * 2, tColor.g * 2, tColor.b * 2, 55 ), Color( 0, 0, 0, 155 )

    panel.Paint = function(self, w, h) 
        
        local colHover = clickReset > CurTime() && colB || colW
      
        draw.RoundedBoxEx( r, 0, 0, w, h, col, cornTab[1], cornTab[2], cornTab[3], cornTab[4] )   
        
        Derma_TextScroll( self, w, h, 2, text, font, tColor )

        if hover then Derma_TextScroll( self, w, h, 2, text, font, colHover, colHover ) end  

    end
	
    return panel
end

--[[
==================================================================================================
                    CONV MENU FUNCTIONS
==================================================================================================
--]]

-- Creates a derma menu with a lot of cool features
function conv.createMenu( w, h, animDelta, blur, tittle, font, tColor, bgColor, hColor, tickFunc, crossFunc, helpText )
    bgColor = bgColor || color_white
    hColor = hColor || Color( color_gmod.r, color_gmod.g, color_gmod.b, 255 )
    font = font || "DermaDefaultBold"
	
    local panel = vgui.Create( "DFrame" )
    panel:SetTitle( "" )
    w, h = w || ( 500 * conv.ScrWScale() ), h || ( 500 * conv.ScrHScale() )
    panel:SetSize( w, h )
    panel:Center()
    panel:SetVisible( true )
    panel:SetDraggable( true )
    panel:ShowCloseButton( false )
    panel:NoClipping( true )
    panel:SetSizable( false )
    panel:SetMinWidth( panel:GetWide() )
    panel:SetMinHeight( panel:GetTall() )
    panel:MakePopup()

-----------------------------------------------------------PAINT
    local buttonW, buttonH = math.ceil( w / 3 ), 18
    local hThiccUp = 24

    panel.Paint = function( self, w, h )
        
        if blur then Derma_DrawBackgroundBlur( self, 0 ) end

        draw.RoundedBoxEx( 10, 0, 0, w, h, bgColor, true, true, true, true )
        draw.RoundedBoxEx( 8, 0, 0, w, hThiccUp, hColor, true, true, false, false )	

		Derma_TextScroll( self, w, 20, 5, tittle, font, tColor, sColor )

        local x, y, w, h = animDone && w / 4 || 0, animDone && self:GetTall() - 10 || self:GetTall() - buttonH, animDone && w / 2 || w, animDone && 10 || buttonH
        draw.RoundedBoxEx( 0, x, y, w, h, hColor, true, true, true, true )
        	
    end
-----------------------------------------------------------SCROLL

    panel.ScrollP = vgui.Create( "DScrollPanel", panel )
    panel.ScrollP:SetSize( w, h )
    panel.ScrollP:SetPos( 0, hThiccUp )

    local sbar = panel.ScrollP:GetVBar()
    sbar:SetHideButtons( true )
    function sbar:Paint(w, h)
        draw.RoundedBox( 0, 0, 0, w, panel:GetTall(), hColor )
    end
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox( 8, 0, 0, w, h, bgColor )
    end

    panel.AddItem = function(self, pnl)
        panel.ScrollP:AddItem( pnl )
    end
    panel.Add = function(self, pnl)
        return panel.ScrollP:Add( pnl )
    end
-----------------------------------------------------------ANIMATIONS

    panel.OldThink = panel.Think
    animDelta = animDelta || 0
    local aStart, aDur = CurTime(), animDelta

    panel.Think = function(self)

        panel.OldThink(self)

        local aProg = ( CurTime() - aStart ) / aDur
	    local a = Lerp( aProg, 25, h )
        panel.ScrollP:SetTall( a - hThiccUp * 1.7 )
        self:SetTall( a )
        animDone = self:GetTall() == h
    end
-----------------------------------------------------------BUTTONS

    tickFunc = tickFunc || function( self ) panel:Close() end
    crossFunc = crossFunc || function( self ) panel:Close() end
    
    panel.ButtonA = menuButton( panel, buttonW, buttonH, 0, h - buttonH, 8, { false, true, true, false }, "✔", font, tColor, hColor, tickFunc )
    panel.ButtonB = menuButton( panel, buttonW, buttonH, w - buttonW, h - buttonH, 8, { true, false, false, true }, "✘", font, tColor, hColor, crossFunc )
    
    if helpText then
        panel.ButtonH = menuButton( panel, ( buttonW / 2 ), buttonH, w / 2 - ( buttonW / 2 ) / 2, h - buttonH, 8, { true, true, false, false }, "？", font, tColor, hColor )
        panel.ButtonH:SetTooltip( helpText )
    end

    return panel
end