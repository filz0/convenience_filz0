--[[
==================================================================================================
                    LOCALS / INTERNAS, NO TOUCHY
==================================================================================================
--]]

local scrWidth = 1920
local scrHeight = 1080

-- Function used by CallOnClient to translate sent data --
function CONV_INTERNAL_COCTranslate( ent, funcN, data )  

	data = conv.stringToTable( data )	
	
	if IsValid(ent) || ent == game.GetWorld() then
			
		ent[ funcN ]( ent, unpack( data ) )
	
	elseif istable(ent) then
		
		ent[ funcN ]( unpack( data ) )
		
	else
		
		funcN( unpack( data ) )
		
	end
	
end

--[[
==================================================================================================
                    COMMANDS
==================================================================================================
--]]


-- Strip the players weapons, and gives only essential tools
concommand.Add("conv_strip", function(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end
    net.Start("CONV_StripAndTools")
    net.SendToServer()
end)


-- Give ammo to all weapons for a player, needs admin
concommand.Add("conv_giveammo", function(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end
    net.Start("CONV_GiveAmmo")
    net.SendToServer()
end)

concommand.Add("conv_rmwep", function(ply, cmd, args)
    net.Start("CONV_RmWep")
    net.SendToServer()
end)

-- Show information about the player's weapons, useful when they have fast switch enabled
concommand.Add("conv_checkweapons", function(ply, cmd, args)
    local weps = ply:GetWeapons()

    notification.AddLegacy( "You currently have "..#weps.." weapons in your inventory", NOTIFY_HINT, 5 )

    local weapon_slotmap = {}
    for _, wep in ipairs(weps) do

        weapon_slotmap["SLOT "..wep:GetSlot()] = weapon_slotmap["SLOT "..wep:GetSlot()] or {}
        table.insert(weapon_slotmap["SLOT "..wep:GetSlot()], wep.PrintName && language.GetPhrase(wep.PrintName) or wep:GetClass())

    end

    PrintTable(weapon_slotmap)
end)
 
-- Show information about the player's frames, frame times, ping, etc. conv_telemetry <1/0> <x> <y>
concommand.Add( "conv_telemetry", function(ply, cmd, args)  
	local enable = tonumber(args[1]) > 0
	
	conv.addHUDElement("conv_telemetry", enable, function() 
		local ply = LocalPlayer()
		local w, h = 200, 100
		local x, y = args && args[2] || conv.ScrWCenter() - ( w / 2 ), args && args[3] || conv.ScrHCenter() - 300
		draw.RoundedBox( 8, x, y, w, h, color_hl2hud_box )

		local x1, y1 = x + 97, y + 15
		local text = "TELEMETRY"
		local textW, textH = draw.SimpleText( text, "HudDefault", x1, y1, color_hl2hud_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local x, y = x + 15, y + 10 + textH
		local text = "FRAMES/s:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = math.Round( ( 1 / FrameTime() ), 3 )
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
 
		local x, y = x, y + textH
		local text = "FRAME TIME:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = math.Round( FrameTime(), 5 )
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

		local x, y = x, y + textH
		local text = "PING:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = ply:Ping()
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		
		local x, y = x, y + textH
		local text = "PACKET LOSS:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = ply:PacketLoss() .. "%"
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end)
end) 

--[[
==================================================================================================
                    TOOL MENU
==================================================================================================
--]]

-- A convenient way to add toolmenu options
function conv.addToolMenu(tab, cat, name, func)
    conv.toolMenuFuncs = conv.toolMenuFuncs or {}
    conv.toolMenuFuncs[tab.."_"..cat.."_"..name] = {tab=tab, cat=cat, name=name, func=func}
end


--[[
==================================================================================================
					UI
==================================================================================================
--]]


-- Used to properly scale position and width of an UI elemet to different screen resolutions.
function conv.ScrWScale()
	return ScrW() / scrWidth
end

-- Used to properly scale position and height of an UI elemet to different screen resolutions.
function conv.ScrHScale()
	return ScrH() / scrHeight
end

-- Returns the central point of the horizontal axis.
function conv.ScrWCenter()
	return ScrW() / 2
end

-- Returns the central point of the vertical axis.
function conv.ScrHCenter()
	return ScrH() / 2
end
 
-- Used to create hud elements on the go
function conv.addHUDElement(id, enable, func)		
	if ( id && enable == nil && !isfunction(func) ) then CONVHUDElementsTab[ id ] = nil return end
	
	CONVHUDElementsTab[id] = { 
		['Enable']			= !enable && false || enable,
		['Function'] 		= func,
	}
end
 
-- Used to create on screen messages/text similar to "game_text". entity https://developer.valvesoftware.com/wiki/Game_text
function conv.addScreenMSG(id, text, font, x, y, tColor, xAlign, yAlign, OWidth, OColor, del, fadeIn, fadeOut, dur)		
	if ( id && ( !text ) ) then CONVScrnMSGTab[ id ] = nil return end
	
	text = text || ""
	font = font || "DermaDefault"
	x = x || 0
	y = y || 0
	tColor = tColor || Color( 255, 255, 255, 255 )
	xAlign = xAlign || TEXT_ALIGN_CENTER
	yAlign = yAlign || TEXT_ALIGN_CENTER
	OWidth = OWidth || 0
	OColor = OColor || Color( 0, 0, 0, 255 )
	del = del || 0
	fadeIn = fadeIn || 0
	fadeOut = fadeOut || 0
	dur = dur || 0

	local function pp(tbl, k, s, add, ret)
		return add && ( tbl[k] && tbl[k][s] && tbl[k][s] + add || add ) || ( tbl[k] && tbl[k][s] && tbl[k][s] || ret )
	end
	
	CONVScrnMSGTab[id] = { 
		['Text'] 		= text,
		['Font'] 		= font,
		['X'] 			= x,
		['Y'] 			= y,
		['Color'] 		= tColor,
		['XAlign'] 		= xAlign,
		['YAlign'] 		= yAlign,
		['OWidth'] 		= OWidth,
		['OColor'] 		= OColor,
		['Delay'] 		= del,
		['FadeIn'] 		= fadeIn,
		['FadeOut'] 	= fadeOut,
		['Duration'] 	= pp(CONVScrnMSGTab, id, 'Duration', dur),
		['StartTime'] 	= pp(CONVScrnMSGTab, id, 'StartTime', nil, CurTime() + del),
	}
end

-- Used to play UI sounds
function conv.emitUISound(snd, pitch, vol, channel, sfs, dsp, filter)		

	local ply = LocalPlayer()
	vol = vol || 1
	pitch = pitch || 100
	channel = channel || CHAN_AUTO
	sfs = sfs || 0
	dsp = dsp || 0


	ply.m_tCONVClientSounds = ply.m_tCONVClientSounds || {}


	local function stopSND(snd)

		for k, v in ipairs ( ply.m_tCONVClientSounds ) do
			if snd && v == snd then
				ply:StopSound( snd ) 	
				table.remove( ply.m_tCONVClientSounds, k ) 		
			else
				ply:StopSound( v ) 	
				table.remove( ply.m_tCONVClientSounds, k )			
			end			
		end

	end


	if snd then	

		ply:EmitSound( snd, 0, pitch, vol, channel, sfs, dsp, filter )
		table.insert( ply.m_tCONVClientSounds, snd )	

	elseif snd && pitch == true then

		stopSND(snd)		

	elseif !snd && ply.m_tCONVClientSounds && #ply.m_tCONVClientSounds > 0 then	

		stopSND()

	end			

end

-- Used to display text on an entity, useful for debugging or showing information
function conv.displayOnEntity( name, ent, tab, dur, x, y, xAlign, yAlign )   

	if !ent then return end

	local name = "CONV_DisplayOnEntity" .. name .. ent:EntIndex() || "CONV_DisplayOnEntity" .. ent:EntIndex()

	if !tab then ent:CONV_RemoveHook( "HUDPaint", name ) return end

	local ply = LocalPlayer()
	local font = "ChatFont"
	local x = x || 0
	local y = y || 0
	local dur = dur && dur < 0.1 && 0.1 || dur
	local xAlign = xAlign || TEXT_ALIGN_CENTER
	local yAlign = yAlign || TEXT_ALIGN_TOP

	ent:CONV_AddHook( "HUDPaint", function()

		local pos = ent:GetPos() + ent:OBBCenter() * 2       
		local sPos = pos:ToScreen()
		local i = 0
		
		for k, v in pairs(tab) do

			i = i + 1

			v = tostring(v)

			if !isnumber(k) then v = k .. " = " .. v end

			draw.SimpleText( v, font, sPos.x + x, sPos.y + ( i * 20 ) + y, color_white, xAlign, yAlign )
		end
	end, name )

	if dur then ent:CONV_TimerCreate( name, dur, 1, function() ent:CONV_RemoveHook( "HUDPaint", name ) end ) end
end


--[[
==================================================================================================
					FOG CONTROL
==================================================================================================
--]]

-- Setup world fog, set no values to reset
function conv.setupWorldFog(fogStart, fogEnd, fogMaxDensity, fogColor, fogMode, fogZ)

	if !fogStart && !fogEnd && !fogMaxDensity && !fogColor && !fogMode && !fogZ then 
		fogMode = 0 

		conv.callNextTick( function() 
			CONV_FOG_WORLD = nil
		end )
	end

	local s, e, z = render.GetFogDistances()
	local c = { render.GetFogColor() }

	CONV_FOG_WORLD = {}
	CONV_FOG_WORLD.FogStart			= fogStart || s
	CONV_FOG_WORLD.FogEnd 			= fogEnd || e
	CONV_FOG_WORLD.FogMaxDensity 	= fogMaxDensity || 0.5
	CONV_FOG_WORLD.FogColor 		= fogColor || c
	CONV_FOG_WORLD.FogMode			= fogMode || 1
	CONV_FOG_WORLD.FogZ				= fogZ || z

end

-- Setup skybox fog, set no values to reset
function conv.setupSkyboxFog(fogStart, fogEnd, fogMaxDensity, fogColor, fogMode, fogZ)

	if !fogStart && !fogEnd && !fogMaxDensity && !fogColor && !fogMode && !fogZ then 
		fogMode = 0 

		conv.callNextTick( function() 
			CONV_FOG_SKYBOX = nil
		end )
	end

	local s, e, z = render.GetFogDistances()
	local c = { render.GetFogColor() }

	CONV_FOG_SKYBOX = {}
	CONV_FOG_SKYBOX.FogStart		= fogStart || 0
	CONV_FOG_SKYBOX.FogEnd 			= fogEnd || 10000
	CONV_FOG_SKYBOX.FogMaxDensity 	= fogMaxDensity || 0.5
	CONV_FOG_SKYBOX.FogColor 		= fogColor || c
	CONV_FOG_SKYBOX.FogMode			= fogMode || 1
	CONV_FOG_SKYBOX.FogZ			= fogZ || z

end