--[[
==================================================================================================
                    MODULE BY filz0
==================================================================================================
--]]
local istable			= istable
local render			= render
local hook				= hook
local IsValid			= IsValid

module( "conv_silhouette", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL
local materialDebugWhite 	= Material("models/debug/debugwhite")

local ENTS, COLOR, CHILDREN	= 1, 2, 3


function Add( ents, color, include_children )
	
	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables


	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ CHILDREN ] = include_children,
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

		local data = List[i]
		local ents = data[ENTS]
		local color = data[COLOR]
		local children = data[CHILDREN]		
		
		-- Determine our reference value based on the list index
		render.SetStencilReferenceValue(reference)
		-- Always draw everything
		render.SetStencilCompareFunction(STENCIL_GREATER)
		-- If something would draw to the screen but is behind something, set the pixels it draws to 1
		render.SetStencilZFailOperation(STENCIL_REPLACE)

		vmCrashFix.antiOverflow = true -- If missing, game crashes. Guess it doesn't like DrawModel() in post VM or Hands. :(
		
		-- Render using a cheap material
		render.MaterialOverride(materialDebugWhite)
		-- We dont need lighting
		render.SuppressEngineLighting(true)
		-- We dont need color
		render.OverrideColorWriteEnable(true, false)
		-- We dont need depth
		render.OverrideDepthEnable(true, false)

		-- Draw our entities. They will draw as normal
		RenderModels(ents, drawMode, children)
		
		render.OverrideColorWriteEnable(false)
		render.SuppressEngineLighting(false)
		render.MaterialOverride(nil)
		render.OverrideDepthEnable(false)

		-- Now, only draw things that have their pixels set to 1. This is the hidden parts of the stencil tests.
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		-- Flush the screen. This will draw teal over all hidden sections of the stencil tests
		render.ClearBuffersObeyStencil(color.r, color.g, color.b, color.a, false)
		-- Let everything render normally again

		-- This fixes ZFail triggering on the entity itself. Or something.
		RenderModels(ents, drawMode, children)

		vmCrashFix.antiOverflow = false

	end

	RenderEnt = NULL

	render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_KEEP)

	render.SetStencilEnable(false)

end

local function CONVRenderSilhouettes(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	hook.Run( "CONVSetupSilhouettes", Add )

	if ( ListSize == 0 ) then return end
	
	Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawTranslucentRenderables", "CONVRenderSilhouettes", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
	CONVRenderSilhouettes(0, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
end )

hook.Add( "PreDrawViewModels", "CONVRenderSilhouettes", function()
	CONVRenderSilhouettes(1)	
end )

hook.Add( "PostDrawPlayerHands", "CONVRenderSilhouettes", function()
	CONVRenderSilhouettes(2)	
end )

-- Helper function to apply silhouette effect usint conv.callOnClient
function conv.addSilhouette( hookName, ents, color, include_children )

	if not ents and not color and not include_children then hook.Remove( "CONVSetupSilhouettes", hookName ) return end

	hook.Add( "CONVSetupSilhouettes", hookName, function()

		conv_silhouette.Add( ents, color, include_children )

	end )

end


--[[
local istable			= istable
local render			= render
local hook				= hook
local IsValid			= IsValid

module( "conv_silhouette", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local ENTS, COLOR, CHILDREN	= 1, 2, 3


function Add( ents, color, include_children )
	
	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables


	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ CHILDREN ] = include_children,
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
	 
local function RenderModels(ents, drawMode, children)
    for i = 1, #ents do
        local ent = ents[i]

        if IsValid(ent) and ent:Alive() and vmCrashFix:IsVMEnt( ent:GetClass(), drawMode ) then
            RenderEnt = ent
			
            ent:DrawModel( bit.bor( STUDIO_RENDER, STUDIO_NOSHADOWS ) )

            if children then
                local childrenmodels = ent:GetChildren()
                if childrenmodels and #childrenmodels > 0 then RenderModels(childrenmodels, drawMode, children) end
            end

        end
    end
end

local function Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)

	if ( bDrawingSkybox or isDraw3DSkybox ) then return end -- Do not render overlays in depth pass or skybox

	for i = 1, ListSize do

		local data = List[ i ]
		local ents = data[ ENTS ]
		local color = data[ COLOR ]
		local children = data[ CHILDREN ]

		-- Reset everything to known good
		render.SetStencilWriteMask( 0xFF )
		render.SetStencilTestMask( 0xFF )
		render.SetStencilReferenceValue( 0 )
		render.SetStencilCompareFunction( STENCIL_ALWAYS )
		render.SetStencilPassOperation( STENCIL_KEEP )
		render.SetStencilFailOperation( STENCIL_KEEP )
		render.SetStencilZFailOperation( STENCIL_KEEP )
		render.ClearStencil()

		-- Enable stencils
		render.SetStencilEnable( true )
		-- Set the reference value to 1. This is what the compare function tests against
		render.SetStencilReferenceValue( 1 )
		-- Always draw everything
		render.SetStencilCompareFunction( STENCIL_ALWAYS )
		-- If something would draw to the screen but is behind something, set the pixels it draws to 1
		render.SetStencilZFailOperation( STENCIL_REPLACE )
			
		vmCrashFix.antiOverflow = true -- If missing, game crashes. Guess it doesn't like DrawModel() in post VM or Hands. :(

		-- Draw our entities. They will draw as normal
		RenderModels(ents, drawMode, children)

		-- Now, only draw things that have their pixels set to 1. This is the hidden parts of the stencil tests.
		render.SetStencilCompareFunction( STENCIL_EQUAL )
		-- Flush the screen. This will draw teal over all hidden sections of the stencil tests
		render.ClearBuffersObeyStencil( color.r, color.g, color.b, color.a, false )

		-- Let everything render normally again
		render.SetStencilEnable( false )

		-- This fixes ZFail triggering on the entity itself. Or something.
		RenderModels(ents, drawMode, children)
		

		vmCrashFix.antiOverflow = false

	end

end

local function CONVRenderSilhouettes(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	hook.Run( "CONVSetupSilhouette", Add )

	if ( ListSize == 0 ) then return end
	
	Render(drawMode, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawTranslucentRenderables", "CONVRenderSilhouettes", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	CONVRenderSilhouettes(0, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
end )

hook.Add( "PostDrawViewModel", "CONVRenderSilhouettes", function()

	CONVRenderSilhouettes(1)	
end )

hook.Add( "PostDrawPlayerHands", "CONVRenderSilhouettes", function()

	CONVRenderSilhouettes(2)	
end )

-- Helper function to apply silhouette effect usint conv.callOnClient
function conv.addSilhouette( hookName, ents, color, include_children )

	if not ents and not color and not include_children then hook.Remove( "CONVSetupSilhouettes", hookName ) return end

	hook.Add( "CONVSetupSilhouettes", hookName, function()

		conv_silhouette.Add( ents, color, include_children )

	end )

end

]]--