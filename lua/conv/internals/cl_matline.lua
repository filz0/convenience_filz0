--[[
==================================================================================================
                    MODULE BY relaxtakenotes
==================================================================================================
--]]
local istable			= istable
local render			= render
local Material			= Material
local CreateMaterial	= CreateMaterial
local hook				= hook
local IsValid			= IsValid
local map_maxsize		= 32768

module( "matline", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local MatlineSettingsIZ	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "1"
}

local MatlineSettings	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "0"
}

local MatlineIZ			= CreateMaterial( "MatlineIZ", "UnlitGeneric", MatlineSettingsIZ )
local Matline			= CreateMaterial( "Matline", "UnlitGeneric", MatlineSettings )

local ENTS, COLOR, IGNOREZ		= 1, 2, 3

function Add( ents, color, ignorez )
	
	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( !istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ IGNOREZ ] = ignorez,
	}
	
	ListSize = ListSize + 1
	List[ ListSize ] = data
	
end

function RenderedEntity()
	
	return RenderEnt
end

local function Render()
	cam.Start3D()

		for i = 1, ListSize do

			local data = List[ i ]
			local ents = data[ ENTS ]
			local color = data[ COLOR ]
			local ignorez = data[ IGNOREZ ]

			for j = 1, #ents do

				local ent = ents[ j ]
							
				if ( IsValid( ent ) && ent:Alive() ) then
					
					render.SetStencilEnable( true )
					render.ClearStencil()
					render.SetStencilTestMask( 255 )
					render.SetStencilWriteMask( 255 )
					render.SetStencilPassOperation( STENCILOPERATION_KEEP )
					render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
					render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
					render.SetStencilReferenceValue( 9 )
					render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
					
					ent:DrawModel( bit.bor( STUDIO_RENDER, STUDIO_NOSHADOWS ) )

					render.SetStencilFailOperation( STENCILOPERATION_KEEP )
					render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_GREATER )

					render.SetColorModulation( color.r / 255, color.g / 255, color.b / 255 )

					render.MaterialOverride( ignorez && MatlineIZ || Matline )
					ent:DrawModel( bit.bor( STUDIO_RENDER, STUDIO_NOSHADOWS ) )

					render.MaterialOverride( nil )

					render.SetStencilEnable( false )
				end

			end

		end
		
	cam.End3D()
end

local function RenderMatlines()
	
	hook.Run( "SetupMatlines", Add )

	if ( ListSize == 0 ) then return end
	
	Render()
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawEffects", "RenderMatlines", function()

	RenderMatlines()	
end )
