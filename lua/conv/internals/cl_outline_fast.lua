--[[
==================================================================================================
                    MODULE BY relaxtakenotes
==================================================================================================
--]]
local istable = istable
local render = render
local Material = Material
local CreateMaterial = CreateMaterial
local hook = hook
local IsValid = IsValid

module( "conv_outline_fast", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local FastOutlineSettingsZ	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "1"
}

local FastOutlineSettings	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "0"
}

local WFOutlineZ		= CreateMaterial( "conv_outline_fast_z", "UnlitGeneric", FastOutlineSettingsZ )
local WFOutline			= CreateMaterial( "conv_outline_fast", "UnlitGeneric", FastOutlineSettings )

local ENTS, COLOR, IGNOREZ, CHILDREN	= 1, 2, 3, 4

function Add( ents, color, ignorez, include_children )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ IGNOREZ ] = ignorez,
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

	if (bDrawingSkybox or isDraw3DSkybox) then return end -- Do not render overlays in depth pass or skybox
	if (IsInWorld()) then return end
	if (IsValidScene()) then return end

	local reference = 0

	-- Clear out the stencil
	render.ClearStencil()

	-- Enable stencils
	render.SetStencilEnable(true)

	-- Reset everything to known good
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(0)
	render.SetStencilCompareFunction(STENCIL_GREATER)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	-- Render the models onto the stencil
	render.SetBlend(1)

	for i = 1, ListSize do

		-- Determine our reference value based on the list index
        reference = 0xFF - (i - 1)

		local data = List[ i ]
		local ents = data[ ENTS ]
		local color = data[ COLOR ]
		local ignorez = data[ IGNOREZ ]
		local children = data[ CHILDREN ]

		render.SetStencilPassOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )

		-- Determine our reference value based on the list index
		render.SetStencilReferenceValue(reference)	
		render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
		
		-- Render using a cheap material
		render.MaterialOverride(materialDebugWhite)
		-- We dont need lighting
		render.SuppressEngineLighting(true)
		-- We dont need color
		render.OverrideColorWriteEnable(true, false)
		-- We dont need depth
		render.OverrideDepthEnable(true, false)

		RenderModels(ents, drawMode, children)

		render.OverrideColorWriteEnable(false)
		render.SuppressEngineLighting(false)
		render.MaterialOverride(nil)
		render.OverrideDepthEnable(false)

		render.SetStencilFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_GREATER )
		render.SetColorModulation( color.r / 255, color.g / 255, color.b / 255 )
		render.MaterialOverride( ignorez and WFOutlineZ or WFOutline )

		RenderModels(ents, drawMode, children)

		render.MaterialOverride( nil )
		
	end

	RenderEnt = NULL

	render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_KEEP)

	render.SetStencilEnable( false )

end

local function CONVRenderOutlinesFast(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)

	hook.Run( "CONVSetupOutlinesFast", Add )

	if ( ListSize == 0 ) then return end
	
	Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawTranslucentRenderables", "CONVRenderOutlinesFast", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
	CONVRenderOutlinesFast(0, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
end )

hook.Add( "PreDrawViewModels", "CONVRenderOutlinesFast", function()
	CONVRenderOutlinesFast(1)	
end )

hook.Add( "PostDrawPlayerHands", "CONVRenderOutlinesFast", function()
	CONVRenderOutlinesFast(2)	
end )

-- Helper function to apply outline fast effect using conv.callOnClient
function conv.addOutlineFast( hookName, ents, color, ignorez, include_children )

	if not ents and not color and not ignorez and not include_children then hook.Remove( "CONVSetupOutlinesFast", hookName ) return end

	hook.Add( "CONVSetupOutlinesFast", hookName, function()

		conv_outline_fast.Add( ents, color, ignorez, include_children )

	end )

end