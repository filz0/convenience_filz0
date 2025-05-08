--[[
==================================================================================================
                    INTERNALS, NO TOUCHY
==================================================================================================
--]]

-- Fixing user data from translation --
local function convNormUserData( tab, typeOf )
	for i = 1, #tab do
		local data = tab[ i ]
		data = string.gsub( data, typeOf, "" )
		data = string.gsub( data, "[()]", "" )
		data = string.gsub( data, " ", "" )
		tab[ i ] = data
	end

	return tab
end

-- Function used by CallOnClient to translate sent data --
function conv.cocTranslate(data, funcN, ent, ...)   
	local args = string.find( data:lower(), "; " ) && string.Split( data, "; " ) || string.find( data:lower(), ";" ) && string.Split( data, ";" ) || { [1] = data }
	
	for i = 1, #args do

		local var = args[ i ]
		
		if var && string.find( var, "Entity_id" ) then		
			local entID = string.gsub( var, "Entity_id", "" )	
			entID = tonumber( entID )

			args[ i ] = Entity( entID ) 
			var = nil			
		end

		if var && string.find( var, "Color" ) && string.find( var, "[()]" ) then 
			local splts = string.find( var:lower(), ", " ) && string.Split( var, ", " )

			splts = convNormUserData( splts, "Color" )

			args[ i ] = splts[ 4 ] && Color( splts[ 1 ], splts[ 2 ], splts[ 3 ], splts[ 4 ] ) || Color( splts[ 1 ], splts[ 2 ], splts[ 3 ] )
			var = nil 							
		end

		if var && string.find( var, "Vector" ) && string.find( var, "[()]" ) then
			local splts = string.find( var:lower(), ", " ) && string.Split( var, ", " )

			splts = convNormUserData( splts, "Vector" )

			args[ i ] = Vector( splts[ 1 ], splts[ 2 ], splts[ 3 ] )
			var = nil
		end

		if var && string.find( var, "Angle" ) && string.find( var, "[()]" ) then
			local splts = string.find( var:lower(), ", " ) && string.Split( var, ", " )

			splts = convNormUserData( splts, "Angle" )

			args[ i ] = Angle( splts[ 1 ], splts[ 2 ], splts[ 3 ] )
			var = nil
		end

		if var then
			if string.find( var, "true" ) then
				args[ i ] = true 
				var = nil
			elseif string.find( var, "false" ) then
				args[ i ] = false 	
				var = nil
			elseif string.find( var, "nil" ) then
				args[ i ] = nil 
				var = nil
			end
		end

		if var && string.find( var, "%d" ) && !string.find( var, "%a" ) then 
			args[ i ] = tonumber( var ) 
			var = nil 
		end

		if var && string.find( var, "%a" ) then		

			args[ i ] = var 
			var = nil 
		end
		
		if i == #args then
			
			if IsValid(ent) || ent == game.GetWorld() then
			
			ent[ funcN ]( ent, unpack( args ) )
			
			elseif istable(ent) then
				
				ent[ funcN ]( unpack( args ) )
				
			else
				
				funcN( unpack( args ) )
				
			end
			
		end

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
    net.Start("ConvStrip")
    net.SendToServer()
end)


-- Give ammo to all weapons for a player, needs admin
concommand.Add("conv_giveammo", function(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end
    net.Start("ConvGiveAmmo")
    net.SendToServer()
end)

concommand.Add("conv_rmwep", function(ply, cmd, args)
    net.Start("ConvRmWep")
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

local scrWidth = 1920
local scrHeight = 1080

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
	return scrWidth / 2
end

-- Returns the central point of the vertical axis.
function conv.ScrHCenter()
	return scrHeight / 2
end

-- Used to create on screen messages/text similar to "game_text". entity https://developer.valvesoftware.com/wiki/Game_text
function conv.addScreenMSG(id, text, font, x, y, tColor, xAlign, yAlign, OWidth, OColor, del, fadeIn, fadeOut, dur)	
	if ( id && ( !text || text == "" ) ) then CONVScrnMSGTab[ id ] = nil return end

	CONVScrnMSGTab[ id ] = {
		['Text'] 		= text || "",
		['Font'] 		= font || "DermaDefault",
		['X'] 			= x || 0,
		['Y'] 			= y || 0,
		['Color'] 		= tColor || Color( 255, 255, 255, 255 ),
		['XAlign'] 		= xAlign || TEXT_ALIGN_CENTER,
		['YAlign'] 		= yAlign || TEXT_ALIGN_CENTER,
		['OWidth'] 		= OWidth || 0,
		['OColor'] 		= OColor || Color( 255, 255, 255, 255 ),
		['Delay'] 		= del || 0,
		['FadeIn'] 		= fadeIn || 0,
		['FadeOut'] 	= fadeOut || 0,
		['Duration'] 	= dur || 0,
		['StartTime'] 	= CurTime(),
	}
end