--[[
==================================================================================================
                    MODULE BY filz0
==================================================================================================
--]]
local istable			= istable
local render			= render
local Material			= Material
local CreateMaterial	= CreateMaterial
local hook				= hook
local IsValid			= IsValid

module( "ent_overlay", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local ENTS, COLOR, MATERIAL, MATERIALDRAW		= 1, 2, 3, 4

local mat_overlay = Material( "models/props_combine/cit_beacon" )

function Add( ents, color, material, materialDraw )
	
	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( !istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables

	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ MATERIAL ] = material,
		[ MATERIALDRAW ] = materialDraw,
	}
	
	ListSize = ListSize + 1
	List[ ListSize ] = data
	
end

function RenderedEntity()
	
	return RenderEnt
end

local vmCrashFix = {

	antiOverflow = false,

	IsVMEnt = function(self, class, drawMode)
		local vm = class == "viewmodel"
		local hands = class == "gmod_hands"
		return ( vm && drawMode == 1 || hands && drawMode == 2 ) && !self.antiOverflow || !vm && !hands && drawMode == 0
	end
}

local function Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)

	if ( bDrawingSkybox || isDraw3DSkybox ) then return end -- Do not render overlays in depth pass or skybox

	for i = 1, ListSize do

		local data = List[ i ]

		if ( data ) then

			local ents = data[ ENTS ]
			local color = data[ COLOR ]
			local material = data[ MATERIAL ]
			local materialDraw = data[ MATERIALDRAW ]
			local mat = material || mat_overlay
			
			if materialDraw then materialDraw(mat) end

			for j = 1, #ents do

				local ent = ents[ j ]

				if ( IsValid( ent ) && ent:Alive() && vmCrashFix:IsVMEnt( ent:GetClass(), drawMode ) ) then

					RenderEnt = ent -- Store the currently rendered entity for later reference		
					render.UpdateRefractTexture()
			
					render.MaterialOverride( mat )					

					render.OverrideDepthEnable( true, false )
					render.SetColorModulation( color.r / 255, color.g / 255, color.b / 255 )
					render.SetBlend( color.a / 255 )	

						vmCrashFix.antiOverflow = true -- If missing, game crashes. Guess it doesn't like DrawModel() in post VM or Hands. :(
						ent:DrawModel()
					
					render.SetBlend( 1 )
					render.SetColorModulation( 1, 1, 1 )
					render.OverrideDepthEnable( false, false )
					render.MaterialOverride(0)
					vmCrashFix.antiOverflow = false

				end

			end

		end

	end

end

local function RenderEntOverlays(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	hook.Run( "SetupEntOverlays", Add )

	if ( ListSize == 0 ) then return end
	
	Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawTranslucentRenderables", "RenderEntOverlays", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	RenderEntOverlays(0, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
end )

hook.Add( "PostDrawViewModel", "RenderEntOverlays", function()

	RenderEntOverlays(1)	
end )

hook.Add( "PostDrawPlayerHands", "RenderEntOverlays", function()

	RenderEntOverlays(2)	
end )

-- Helper function to apply glowshell effect usint conv.callOnClient
function conv.addEntOverlay( hookName, ents, color, material )

	hook.Add( "SetupEntOverlays", hookName, function()

		overlay.Add( ents, color, material )

	end )

end

