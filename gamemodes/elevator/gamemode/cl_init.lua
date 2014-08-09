include( "cl_legs.lua" )
include( "scoreboard/controls/cl_list.lua" )
include( "scoreboard/cl_playerlist.lua" )
include( "scoreboard/cl_init.lua" )
include( "shared.lua" )

include( "billiards/cl_billiards.lua" )
include( "postprocess/init.lua" )

//=====================================================

// Entities to draw a crosshair over
GM.CrosshairEnts = { "elevator_drink", "elevator_tvremote", "elevator_tvvolume" }

// Binds to disable
GM.DisableBinds = { "+menu", "+menu_context", "+speed" }

// HUD elements to hide
GM.HUDToHide = { "CHudAmmo", "CHudCrosshair", "CHudZoom",
				 "CHudHealth", "CHudBattery",
				 "CHudDamageIndicator", "CHudWeaponSelection"
}

// Vars for crosshair (based on gm_apartment code)
local CrosshairColor = Color( 0, 183, 235, 200 )
local CrosshairMat = Material( "effects/softglow" )

// Vars for vignette (taken from gm_apartment code)
local Vignette = true
local VignetteMat = Material( "sunabouzu/apartment_vignette" )

//=====================================================

// CVAR for distance opacity on players
local OPACITY_CVAR = CreateClientConVar( "elev_opacitydistance", 5, false, false )

surface.CreateFont( "HudCText", {
	font = "default",
	size = 35,
	weight = 700,
	antialias = true
})
surface.CreateFont( "HudCSubText", {
	font = "default",
	size = 18,
	weight = 700,
	antialias = true
})

/**
 * Draw the HUD elements
 */
function GM:HUDPaint()

	self:DrawCrosshair()
	self:DrawHUDMessages()
	self:HUDDrawTargetID()

end

/**
 * Draws a crosshair on entities that the player can use (based on gm_apartment code)
 */
function GM:DrawCrosshair()

	local pos = LocalPlayer():EyePos()
	local trace = util.TraceLine({
		["start"] = pos, 
		["endpos"] = pos + ( LocalPlayer():GetAimVector() * 128 ), 
		["filter"] = LocalPlayer()
	})

	local ent = trace.Entity
	if ( !IsValid( ent ) ) then return end

	if self:ValidIngredient( ent ) || table.HasValue( self.CrosshairEnts, ent:GetClass() ) then

		local w, h = ScrW() / 2, ScrH() / 2
		local alpha, size = ( 1 - trace.Fraction ) * 255, ScreenScale( 8 )
		local radius = size / 2				

		surface.SetDrawColor( CrosshairColor.r, CrosshairColor.g, CrosshairColor.b, alpha )
		surface.SetMaterial( CrosshairMat )
		surface.DrawTexturedRect( w - radius, h - radius, size, size )

	end	

end

// Vars for HUD messages
local ScreenTitle = nil
local ScreenText = nil
local ScreenMessageTime = 0

/**
 * Draws HUD messages.
 * Based on the billiards HUD messages by Athos Arantes Pereira (used with persmission)
 */
function GM:DrawHUDMessages()

	// Remove the message after its delay
	if ( CurTime() > ScreenMessageTime ) then
		ScreenTitle = nil
		ScreenText = nil
		return
	end

	// Don't draw anything if there's no text
	if ( !ScreenText ) then return end

	local w, h = ScrW() / 2, ScrH() / 2

	h = h + h / 2.5

	// Draw gradient boxes
	draw.GradientBox( w - 256, h, 128, 100, 0, Color( 0, 0, 0, 0 ), Color( 0, 0, 0, 230 ) )
	draw.GradientBox( w + 128, h, 128, 100, 0, Color( 0, 0, 0, 230 ), Color( 0, 0, 0, 0 ) )
	surface.SetDrawColor( 0, 0, 0, 230 )
	surface.DrawRect( w - 127, h, 256, 100 )

	// Draw title
	if ( ScreenTitle ) then
		draw.SimpleText( ScreenTitle, "HudCText", w, h + 20, Color( 255, 255, 255, 255 ), 1, 1 )
	end

	// Draw text
	draw.DrawText( ScreenText or "", "HudCSubText", w, h + 50, Color( 255, 255, 255, 255 ), 1 )

end

/**
 * Draws a vignette over the screen
 */
function GM:HUDPaintBackground()

	if Vignette then
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.SetMaterial( VignetteMat )
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
	end
	
end

local function CreateMusic( id )

	LocalPlayer().Music = CreateSound( LocalPlayer(), GAMEMODE.Music[ id ][1] )
	LocalPlayer().Music:PlayEx( 80, 100 )

end

/**
 * UMSG - Plays intermission music
 */
usermessage.Hook( "Elevator_StartMusic", function( um )

	local id = um:ReadChar()

	if LocalPlayer().Music && LocalPlayer().Music:IsPlaying() then

		LocalPlayer().Music:FadeOut( 1 )
		timer.Simple( 1, function() CreateMusic( id ) end )
		return

	end
	
	CreateMusic( id )

end )

/**
 * UMSG - Stops intermission music
 */
usermessage.Hook( "Elevator_StopMusic", function( um )

	if ( !LocalPlayer().Music ) then return end

	if LocalPlayer().Music:IsPlaying() then
		LocalPlayer().Music:FadeOut( 1 )
	end

end )

/**
 * UMSG - Plays client-side sound
 */
usermessage.Hook( "Elevator_Sound", function( um )

	surface.PlaySound( GAMEMODE.Sounds[ um:ReadChar() ] )

end )

/**
 * UMSG - Updates NPC name
 */
usermessage.Hook( "Elevator_UpdateNPCName", function( um )

	local npc = um:ReadEntity()

	if ( !IsValid( npc ) ) then return end

	local id = um:ReadChar()
	local mdl = npc:GetModel()

	npc.RealName = GAMEMODE:GetNPCName( id, mdl )

end )

/**
 * UMSG - Randomizes NPC names (for void floor)
 */
usermessage.Hook( "Elevator_RandomNames", function( um )

	LocalPlayer().RandomNames = um:ReadBool()

end )

/**
 * UMSG - Turns off legs/names (for void floor)
 */
usermessage.Hook( "Elevator_ToggleSleep", function( um )

	local legs = um:ReadBool()
	local names = um:ReadBool()
	
	LocalPlayer().ShouldDisableLegs = legs
	LocalPlayer().ShouldDisableNames = names

end )

/**
 * UMSG - Displays HUD message
 */
usermessage.Hook( "Elevator_ScreenMessage", function( um )

	local title = um:ReadString()
	local text = um:ReadString()
	local time = um:ReadChar()
	
	if ( title == "" ) then title = nil end
	if ( text == "" ) then text = nil end

	ScreenMessageTime = CurTime() + time
	ScreenTitle = title
	ScreenText = text

end )

/**
 * Displays HUD names
 */
function GM:HUDDrawTargetID()

	if ( LocalPlayer().ShouldDisableNames ) then return end

	local tr = util.GetPlayerTrace( LocalPlayer(), LocalPlayer():GetAimVector() )
	local trace = util.TraceLine( tr )
	if ( !trace.Hit ) then return end
	if ( !trace.HitNonWorld ) then return end

	local text = "ERROR"
	local font = "TargetID"
	local ent = trace.Entity

	// Display player names
	if ( ent:IsPlayer() ) then

		text = ent:Nick()

	// Display NPC names
	elseif ( ent:IsNPC() ) then

		// Randomize names
		if ( LocalPlayer().RandomNames ) then

			// Continously get a name
			local nameID = self:GetRandomNPCNameID( ent:GetModel() )
			text = self:GetNPCName( nameID, ent:GetModel() )

		else
		
			// Real name doesn't exist, give the client a random name
			if ( !ent.RealName ) then
				local nameID = self:GetRandomNPCNameID( ent:GetModel() )
				ent.RealName = self:GetNPCName( nameID, ent:GetModel() )
			end

			// Display the networked NPC name
			text = ent.RealName

		end

	else
		return // no other entity should have a name
	end

	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )
	
	local MouseX, MouseY = gui.MousePos()
	
	if ( MouseX == 0 && MouseY == 0 ) then
	
		MouseX = ScrW() / 2
		MouseY = ScrH() / 2
	
	end
	
	local x = MouseX
	local y = MouseY
	
	x = x - w / 2
	y = y + 30
	
	// Fade based on distance
	local dist = ( ent:GetPos() - LocalPlayer():GetPos() ):Length()
	local opacity = math.Clamp( ( dist / OPACITY_CVAR:GetFloat() ) - 0.2, 0, 1)
	
	// Don't fade for NPCs
	if ( ent:IsNPC() ) then opacity = 1 end

	// Draw the text
	draw.SimpleText( text, font, x+1, y+1, Color( 0,0,0,120 * opacity ) )
	draw.SimpleText( text, font, x+2, y+2, Color( 0,0,0,50 * opacity ) )
	draw.SimpleText( text, font, x, y, Color( 255, 255, 100, 255 * opacity ) )

end

/**
 * First-person death cam
 */
function GM:CalcView( ply, origin, angle, fov )

	// Don't override if they're alive
	if ply:Alive() then
		return self.BaseClass:CalcView( ply, origin, angle, fov )
	end

	// Get their ragdoll
	local rag = ply:GetRagdollEntity() 

	// Get the ragdoll's eyes and set that to the view
	if IsValid( rag ) then 
		local att = rag:GetAttachment( rag:LookupAttachment("eyes") ) 
 		return self.BaseClass:CalcView( ply, att.Pos, att.Ang, fov ) 
 	end

end

//=====================================================

/**
 * Disable certian binds
 */
function GM:PlayerBindPress( ply, bind, pressed )

	// Disable bind
	if table.HasValue( self.DisableBinds, bind ) then
		return true
	end
	
	// Don't let them zoom when they're viewing their watch
	local watch = ply:GetWatch()
	if IsValid( watch ) then
		if ( watch.IsViewingWatch && watch:IsViewingWatch() && bind == "+zoom" ) then
			return true
		end
	end
	
	// Disable crouch jumping
	if ( !ply:IsOnGround() && bind == "+duck" ) then
		return true
	end

end

/**
 * Disable HUD pickup icons
 */
function GM:HUDWeaponPickedUp() return false end
function GM:HUDItemPickedUp() return false end
function GM:HUDAmmoPickedUp() return false end

/**
 * Disable HUD elements from drawing
 */
function GM:HUDShouldDraw( elem )

	if ( table.HasValue( self.HUDToHide, elem ) ) then
		return false
	end
	
	return true

end

/**
 * Fade players when they get closer to each other (front seat issue)
 */
local undomodelblend = false
local matWhite = Material("models/debug/debugwhite")

function GM:PrePlayerDraw( ply )

	if ply:Team() != TEAM_ELEVATOR or 
		ply == LocalPlayer() then return end

	local radius = OPACITY_CVAR:GetFloat() or 30
	if radius > 0 then

		local eyepos = EyePos()
		local dist = ply:NearestPoint(eyepos):Distance(eyepos)

		if dist < radius then

			local blend = math.max((dist / radius) ^ 1.4, 0.04)
			render.SetBlend(blend)

			if blend < 0.4 then
				render.ModelMaterialOverride(matWhite)
				render.SetColorModulation(0.2, 0.2, 0.2)
			end

			undomodelblend = true

		end

	end

end

/**
 * Unfade player
 */
function GM:PostPlayerDraw( ply )

	if undomodelblend then

		render.SetBlend(1)
		render.ModelMaterialOverride()
		render.SetColorModulation(1, 1, 1)

		undomodelblend = false

	end

end

/**
 * Disable Bunny Hopping
 */
hook.Add( "CreateMove", "DisableBhop", function( input )
	if !LocalPlayer():Alive() or !LocalPlayer().NextJump then return end
	if LocalPlayer().NextJump < CurTime() then return end
	if input:KeyDown( IN_JUMP ) then
		input:SetButtons( input:GetButtons() - IN_JUMP )
	end
end )

hook.Add( "OnPlayerHitGround", "SetNextJump", function( ply, bInWater, bOnFloater, flFallSpeed )
	ply.NextJump = CurTime() + 0.08
end )