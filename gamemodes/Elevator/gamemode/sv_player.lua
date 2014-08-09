// List of entities that can be used
GM.EntityUseList = {
	"slotmachine", "prop_vehicle_prisoner_pod",
	"billiard_table", "billiard_static",
	"elevator_blender", "elevator_drink",
	"func_door_rotating", "prop_physics",
	"elevator_tv", "elevator_tvremote", "elevator_tvvolume"
}

GM.BlockedPlayerModels = {
	skeleton = true,
	kleiner = true,
	combineelite = true,
	css_arctic = true,
}

//=====================================================

/**
 * Sends the players all the NPC names
 */
function GM:PlayerInitialSpawn( ply )
	timer.Simple( 1, function() self:SendNPCNames( ply ) end )
end

/**
 * Called when the player is spawned
 */
function GM:PlayerSpawn( ply )

	ply:SetPos( ply:GetPos() + Vector( 0, 0, 24 ) ) // the dumbest spawn fix in the west

	// Disable player collision
	ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	
	// No crosshair
	ply:CrosshairDisable()
	
	// Reset their spawn position, if plausible
	if ply.OldPos then
		ply:SetPos( ply.OldPos )
		ply.OldPos = nil
	else
		ply:SetTeam( TEAM_IDLE )
	end
	
	// Spawn post effect
	PostEvent( ply, "pspawn" )

	// Setup their speed and jump power (we don't want them moving that fast)
	self:ResetSpeed( ply )
	ply:SetJumpPower( 160 )

	// Set their model and loadout
	hook.Call( "PlayerSetModel", GAMEMODE, ply )
	hook.Call( "PlayerLoadout", GAMEMODE, ply )

	// GMod 13 player color
	ply:SetPlayerColor( Vector( ply:GetInfo( "cl_playercolor" ) ) )

end

function GM:ResetSpeed( ply )

	GAMEMODE:SetPlayerSpeed( ply, 135, 135 )
	
end

function GM:PlayerSetModel( pl )

	local cl_playermodel = string.lower( pl:GetInfo( "cl_playermodel" ) or "" )
	local modelname = player_manager.TranslatePlayerModel( cl_playermodel )

	local blocked = self.BlockedPlayerModels[ cl_playermodel ] or modelname == "models/player/kleiner.mdl"
	if blocked then

		// Random citizen number
		local rnd = math.random( 1, 18 )
		if rnd < 10 then rnd = "0"..rnd end

		// Random citizen gender
		local gender = "male"
		if math.random( 1, 2 ) == 1 then gender = "female" end

		cl_playermodel = gender .. rnd

	end

	local modelname = player_manager.TranslatePlayerModel( cl_playermodel )
	util.PrecacheModel( modelname )
	pl:SetModel( modelname )
	
end

hook.Add("PlayerSetModel", "KillKleiner", function( ply )
	if string.find( ply:GetModel(), "kleiner" ) then
		ply:SetModel( player_manager.TranslatePlayerModel("barney") )
	end
end)

/**
 * Called when a player died
 */
function GM:PlayerDeath( victim, inflictor, attacker )

	// If they're on the end team, respawn them to their death position
	if victim:Team() == TEAM_END then

		victim.OldPos = victim:GetPos()

	else // Otherwise, set them back to idle (this usually won't happen)
		victim:SetTeam( TEAM_IDLE )
	end

end

//=====================================================

/**
 * Strip their weapons and give them a watch
 */
function GM:PlayerLoadout( ply )

	ply:StripWeapons()
	ply:Give("watch")

end

//function GM:PlayerHurt( ply ) end
//function GM:OnPlayerHitGround( ply ) end


/**
 * Create a ragdoll when they die
 */
function GM:DoPlayerDeath( ply, attacker, dmginfo )
	ply:CreateRagdoll()
end

/**
 * Disable the death sound
 */
function GM:PlayerDeathSound()
	return true
end

/**
 * Disable flashlight
 */
function GM:PlayerSwitchFlashlight( ply, on ) 
	if on == true then
		return false
	end
end

/**
 * Create a filter to prevent spaming on NPCs and other entities
 */
function GM:PlayerUse( ply, ent )

	if ( !IsValid( ent ) ) then return end

	local class = ent:GetClass()

	// If they hit the end panel, restart them
	if class == "func_button" && ent:GetName() == "end" then
		self:PlayerRestart( ply )
	elseif table.HasValue( self.EntityUseList, class ) && 
			ent:GetModel() != "models/props_c17/chair_stool01a.mdl" then
		return true
	end

	return false

end

/**
 * Restarts a player.  Also restarts the game when required.
 */
function GM:PlayerRestart( ply )

	// Restart the game
	if self.State == STATE_GAMEOVER then
		self:Restart()
	end
	
	// Clear their position
	ply.OldPos = nil

	// Restart the player
	ply:SetTeam( TEAM_IDLE )
	ply:Kill()
	ply:Spawn()

end

/**
 * Disable noclip, excluding the admin
 */
function GM:PlayerNoClip( ply )
	return GetConVar("sv_cheats"):GetBool()
end

/**
 * Disable suiciding
 */
function GM:CanPlayerSuicide( ply )
	return GetConVar("sv_cheats"):GetBool()
end

/**
 * Disable fall damage
 */
function GM:GetFallDamage( ply, vel )
	return 0
end

/**
 * Disable fall damage (part 2)
 */
function GM:EntityTakeDamage( ent, dmginfo )

	if IsValid(ent) && ent:IsPlayer() && dmginfo:IsFallDamage() then
		dmginfo:ScaleDamage( 0 )
	end

end

/**
 * Displays a HUD message.  Only one message at any given time.
 * Based on the billiards HUD messages by Athos Arantes Pereira (used with persmission)
 */
function GM:PlayerMessage( ply, title, text, time )

	umsg.Start( "Elevator_ScreenMessage", ply )
		umsg.String( title or "" )
		umsg.String( text or "" ) // if nil then remove any message
		umsg.Char( time or 5 )
	umsg.End()

end

/**
 * Disallow players either in the elevator or on seperate
 * stages of the map to not hear each other
 */
function GM:PlayerCanHearPlayersVoice( pListener, pTalker )

	if pListener:Team() == TEAM_ELEVATOR || pListener:Team() != pTalker:Team() then
		return false
	end
	
	return true, true // 3D voice

end

/**
 * Sends a player to the end floor (used for mods)
 */
function GM:SkipElevator( ply )

	if ( !self:IsElevatorValid() ) then
		self:GatherEntityData()
	end
	
	ply:SetTeam( TEAM_END )
	ply:SetPos( self.Ending:GetPos() )
	self:EndCurrentMusic( ply )

end

/**
 * Gives the player money (used for mods)
 */
function GM:Payout( ply, amt )

	// insert your money code here

end

/**
 * Disable sprays
 */
function GM:PlayerSpray( ply )
	return true
end

concommand.Add( "elev_reset", function( ply, cmd, args )
		
	if ( ply:Team() == TEAM_END ) then

		if ( ply.ResetCooldown && ply.ResetCooldown > CurTime() ) then return end

		if ( IsValid( GAMEMODE.Ending ) ) then
			ply:SetPos( GAMEMODE.Ending:GetPos() )

			// Quit out of billiards
			CBilliardQuitGame( ply:GetBilliardTable(), ply:UniqueID() )
			ply.IsAiming = false
			
			ply.ResetCooldown = CurTime() + 2
		end

	else
		ply:PrintMessage( HUD_PRINTCONSOLE, "Reset can only be used when you're on the end floor!" )
	end

end )