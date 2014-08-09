ENT.Type 	= "point"
ENT.Base	= "base_point"

ENT.Gibs			= { Model( "models/gibs/HGIBS.mdl" ),
						Model( "models/gibs/HGIBS_rib.mdl" ),
						Model( "models/gibs/HGIBS_scapula.mdl" ),
						Model( "models/gibs/HGIBS_spine.mdl" ),
}

function ENT:AcceptInput( input, activator, ply )

	if input == "SleepOn" then
		GAMEMODE:SetSleepTime( true )

		local npc = GAMEMODE.GetRandomElevatorNPC()

		if ( IsValid( npc ) ) then
			// Spawn gibs
			for i = 1, #self.Gibs do
				local gib = ents.Create( "human_gib" )
					gib:SetPos( npc:GetPos() )
					gib:SetModel( self.Gibs[i] )
				gib:Spawn()

				//gib:SetRealName( ent.RealName )
			end

			// Remove NPC
			npc:Remove()
		end

	end

	if input == "SleepOff" then
		GAMEMODE:SetSleepTime( false )
	end
	
	if input == "SpaceOn" then
		-- distorted speakers effect
		for _, ply in pairs( team.GetPlayers( TEAM_ELEVATOR ) ) do
			ply:SetDSP( 31 )
		end
	end
	
	if input == "SpaceOff" then
		-- reset dsp
		for _, ply in pairs( team.GetPlayers( TEAM_ELEVATOR ) ) do
			ply:SetDSP( 0 )
		end
	end
	
end