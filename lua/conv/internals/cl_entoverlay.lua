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

module( "conv_overlay", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local ENTS, COLOR, MATERIAL, MATERIALDRAW, CHILDREN		= 1, 2, 3, 4, 5

local mat_overlay = Material( "models/props_combine/cit_beacon" )

function Add( ents, color, material, materialDraw, include_children )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables

	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ MATERIAL ] = material,
		[ MATERIALDRAW ] = materialDraw,
		[ CHILDREN ] = include_children
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
		return ( vm and drawMode == 1 or hands and drawMode == 2 ) and not self.antiOverflow or not vm and not hands and drawMode == 0
	end
}

local function IsOnScreen(ent)

	local pos = ent:GetPos()
	local screenPos = pos:ToScreen()
	
	return screenPos.visible
end

local tr = { collisiongroup = COLLISION_GROUP_WORLD, output = {} }
local function IsInWorld()

	local pos = EyePos()
	
	tr.start = pos
	tr.endpos = pos

	return util.TraceLine( tr ).HitWorld
end

local function IsValidScene()
	local scene = render.GetRenderTarget()

    return scene ~= nil
end

local function RenderModels(ents, drawMode, children)

	for i = 1, #ents do

		local ent = ents[i]

		if IsValid(ent) then

			if not ent:Alive() then return end
			if not IsOnScreen(ent) then return end
			if not vmCrashFix:IsVMEnt(ent:GetClass(), drawMode) then return end
			
			RenderEnt = ent

			ent:DrawModel()

			if children then
				local childrenmodels = ent:GetChildren()
				if childrenmodels and #childrenmodels > 0 then RenderModels(childrenmodels, drawMode, children) end
			end

		end

	end
	
end

local function Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)

	if ( bDrawingSkybox or isDraw3DSkybox ) then return end -- Do not render overlays in depth pass or skybox
	if (IsInWorld()) then return end
	if (IsValidScene()) then return end

	-- Clear out the stencil
	render.ClearStencil()

	-- Reset everything to known good
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(0)
	render.SetStencilCompareFunction(STENCIL_GREATER)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	for i = 1, ListSize do

		local data = List[ i ]
		local ents = data[ ENTS ]
		local color = data[ COLOR ]
		local material = data[ MATERIAL ]
		local materialDraw = data[ MATERIALDRAW ]
		local children = data[ CHILDREN ]

		local mat = material or mat_overlay
		
		if materialDraw then materialDraw(mat) end

		render.UpdateRefractTexture()		
		render.MaterialOverride( mat )					
		render.OverrideDepthEnable( true, false )
		render.SetColorModulation( color.r / 255, color.g / 255, color.b / 255 )
		render.SetBlend( color.a / 255 )	

		vmCrashFix.antiOverflow = true -- If missing, game crashes. Guess it doesn't like DrawModel() in post VM or Hands. :(
		
		RenderModels(ents, drawMode, children)

		render.SetBlend( 1 )
		render.SetColorModulation( 1, 1, 1 )
		render.OverrideDepthEnable( false, false )
		render.MaterialOverride(nil)

		vmCrashFix.antiOverflow = false

	end

	RenderEnt = NULL

	render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_KEEP)

end

local function CONVRenderOverlays(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)

	hook.Run( "CONVSetupOverlays", Add )

	if ( ListSize == 0 ) then return end
	
	Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawTranslucentRenderables", "CONVRenderOverlays", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
	CONVRenderOverlays(0, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
end )

hook.Add( "PreDrawViewModels", "CONVRenderOverlays", function()
	CONVRenderOverlays(1)	
end )

hook.Add( "PostDrawPlayerHands", "CONVRenderOverlays", function()
	CONVRenderOverlays(2)	
end )

-- Helper function to apply glowshell effect usint conv.callOnClient
function conv.addOverlay( hookName, ents, color, material, include_children )

	if not ents and not color and not material and not include_children then hook.Remove( "CONVSetupOverlays", hookName ) return end

	hook.Add( "CONVSetupOverlays", hookName, function()

		conv_overlay.Add( ents, color, material, include_children )

	end )

end

