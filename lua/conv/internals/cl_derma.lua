--[[
==================================================================================================
                    LOCALS, NO TOUCH
==================================================================================================
--]]

concommand.Add( "conv_menu_test", function(ply, cmd, args)  
    local menu = conv.dermaMenu( 500, 500, 1, true, "Epic Cool Menu For Settings And Other Stuffs", font, Color( 255, 0, 0, 255 ), Color( 0, 255, 0, 255 ), Color( 0, 0, 255, 255 ), tickFunc, crossFunc, "this is a help text ment for helping and shit" )
    
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

--[[
==================================================================================================
                    CONV MENU FUNCTIONS
==================================================================================================
--]]

-- Creates a derma menu with a lot of cool features
function conv.dermaMenu( w, h, animDelta, blur, tittle, font, tColor, bgColor, hColor, tickFunc, crossFunc, categories )
    bgColor = bgColor || color_white
    hColor = hColor || Color( color_gmod.r, color_gmod.g, color_gmod.b, 255 )
    font = font || "DermaDefaultBold"
	
    local panel = vgui.Create( "DFrame" )
    panel:ParentToHUD()
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
    
    local hThiccUp = 24

    panel.Paint = function( self, w, h )
        
        if blur then Derma_DrawBackgroundBlur( self, 0 ) end

        draw.RoundedBoxEx( 10, 0, 0, w, h, bgColor, true, true, true, true )
        draw.RoundedBoxEx( 8, 0, 0, w, hThiccUp, hColor, true, true, false, false )	

		conv.dermaTextScroll( self, w, 20, 5, isfunction(tittle) && tittle() || tittle, font, tColor, sColor )

    end

-----------------------------------------------------------ANIMATIONS

    panel.OldThink = panel.Think
    animDelta = animDelta || 0
    local aStart, aDur = CurTime(), animDelta

    panel.Think = function(self)

        panel.OldThink(self)

        local aProg = ( CurTime() - aStart ) / aDur
	    local a = Lerp( aProg, 25, h )
        --panel.ScrollP:SetTall( a - hThiccUp * 1.7 )
        self:SetTall( a )
        animDone = self:GetTall() == h
    end
-----------------------------------------------------------BUTTONS

    tickFunc = tickFunc || function( self ) panel:Close() end
    crossFunc = crossFunc || function( self ) panel:Close() end
    
    local buttonW, buttonH = 20 * conv.ScrWScale(), 20

    panel.ButtonA = conv.dermaButton( panel, buttonW, buttonH, 0, 0, "✔", font, tColor, hColor, tickFunc )
    panel.ButtonB = conv.dermaButton( panel, buttonW, buttonH, w - buttonW, 0, "✘", font, tColor, hColor, crossFunc )  

    return panel
end

function conv.dermaTextScroll( self, w, h, buffere, text, font, tColor, sColor )
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

function conv.dermaScrollBar(panel, sBarColor, sBarGripColor)
    local panel = vgui.Create( "DScrollPanel", panel )
    panel:Dock( FILL )

    local sbar = panel:GetVBar()

    sbar:SetHideButtons( true )
    function sbar:Paint(w, h)
        draw.RoundedBox( 0, 0, 0, w, h, sBarColor )
    end
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox( 8, 0, 0, w, h, sBarGripColor )
    end

    return panel
end

function conv.dermaPropertySheet(panel, font, tColor, sColor)
    local panel = vgui.Create( "DPropertySheet", panel )
    panel:Dock( FILL )

    panel.Paint = function(self, w, h)
    end

    function panel:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )

        if ( !IsValid( panel ) ) then
            ErrorNoHalt( "DPropertySheet:AddSheet tried to add invalid panel!" )
            debug.Trace()
            return
        end

        font = font || "DermaDefaultBold"
        local Sheet = {}

        Sheet.Name = label

        Sheet.Tab = vgui.Create( "DTab", self )
        Sheet.Tab:SetTooltip( Tooltip )
        Sheet.Tab:Setup( label, self, panel, material )

        local colW = Color( tColor.r * 2, tColor.g * 2, tColor.b * 2, 55 )
        Sheet.Tab.Paint = function(self, w, h)     
            
            conv.dermaTextScroll( self, w, h, 5, label, font, tColor || color_white, sColor || color_black )
            if self:IsActive() then conv.dermaTextScroll( self, w, h, 5, label, font, colW, colW ) end
 
        end

        Sheet.Tab.GetTabHeight = function(self)

            return 40

        end

        Sheet.Tab:SetTextColor( Color( 0, 0, 0, 0 ) )
        Sheet.Panel = panel
        Sheet.Panel.NoStretchX = NoStretchX
        Sheet.Panel.NoStretchY = NoStretchY
        Sheet.Panel:SetPos( self:GetPadding(), 20 + self:GetPadding() )
        Sheet.Panel:SetVisible( false )

        panel:SetParent( self )

        table.insert( self.Items, Sheet )

        if ( !self:GetActiveTab() ) then
            self:SetActiveTab( Sheet.Tab )
            Sheet.Panel:SetVisible( true )
        end

        self.tabScroller:AddPanel( Sheet.Tab )

        return Sheet

    end

    return panel
end

function conv.dermaButton(self, w, h, x, y, text, font, tColor, bColor, funcClick)    
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
      
        --draw.RoundedBoxEx( r, 0, 0, w, h, col, cornTab[1], cornTab[2], cornTab[3], cornTab[4] )   
        
        conv.dermaTextScroll( self, w, h, 5, text, font, tColor )

        if hover then conv.dermaTextScroll( self, w, h, 5, text, font, colHover, colHover ) end  

    end
	
    return panel
end