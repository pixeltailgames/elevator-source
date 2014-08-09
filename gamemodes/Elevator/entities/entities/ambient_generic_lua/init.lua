AddCSLuaFile( "cl_init.lua" )

ENT.Type 	= "point"
ENT.Base	= "base_point"

ENT.Clients		= {}
ENT.Playing		= false
ENT.Disabled	= false
ENT.Sound		= nil
ENT.Volume		= 100
ENT.FadeOutTime = 5
ENT.TeamID		= -1
ENT.Radius		= 1250

ENT.Emit		= false
ENT.Fade		= true
ENT.Loop		= false

function ENT:KeyValue( key, value )

	if ( key == "StartDisabled" ) then self.Disabled = ( value == 1 ) end
	if ( key == "soundfile" ) then self.Sound = value end
	if ( key == "volume" ) then self.Volume = value end
	if ( key == "fadeout" ) then self.FadeOutTime = value end
	if ( key == "teamid" ) then self.TeamID = value end
	if ( key == "radius" ) then self.Radius = value end
	if ( key == "emit" ) then self.Emit = ( value == 1 ) end
	if ( key == "fade" ) then self.Fade = ( value == 1 ) end
	//if ( key == "loop" ) then self.Loop = ( value == 1 ) end

end

function ENT:Think()

	if ( self.Disabled ) then return end

	// Gather new clients
	for _, ply in ipairs( player.GetAll() ) do

		if ( !table.HasValue( self.Players, ply ) ) then

			if ( self:IsValidClient( ply ) ) then

				table.insert( self.Players, ply )
				self:StartClient( ply )

			end

		end

	end

	if ( !self.Players || #self.Players == 0 ) then return end

	// Remove old clients
	for _, ply in ipairs( self.Players ) do
	
		if ( !self:IsValidClient( ply ) ) then

			local id = table.KeyFromValue( self.Players, ply )
			table.remove( self.Players, id )

			self:EndClient( ply )

		end

	end

end

function ENT:IsValidClient( ply )

	if ( !IsValid( ply ) || !ply:IsPlayer() || !ply:Alive() ) then return false end

	// Check distance
	local dist = ply:GetPos():Distance( self:GetPos() )
	
	if ( dist <= self.Radius ) then

		// Check team
		if ( self.TeamID != -1 ) then
			return ply:Team() == self.TeamID
		end

		return true

	end

	return false

end

function ENT:StartClient( ply )

	if ( !self.Playing ) then return end

	umsg.Start( "ambient_generic_lua_play", ply )
		umsg.Char( self.EntIndex() )
		umsg.String( self.Sound )
		umsg.Char( self.Volume )
		umsg.Bool( self.Emit )
	umsg.End()

end

function ENT:EndClient( ply )

	if ( !self.Playing ) then return end

	umsg.Start( "ambient_generic_lua_stop", ply )
		umsg.Char( self.EntIndex() )
		umsg.Bool( self.Fade )
		if ( self.Fade ) then
			umsg.Char( self.FadeOutTime )
		end
	umsg.End()

end

function ENT:PlaySound()

	if ( self.Disabled ) then return end
	
	self.Playing = true

	for _, ply in ipairs( self.Players ) do
		umsg.Start( "ambient_generic_lua_play", ply )
			umsg.Char( self.EntIndex() )
			umsg.String( self.Sound )
			umsg.Char( self.Volume )
			umsg.Bool( self.Emit )
		umsg.End()
	end

end

function ENT:UpdateSound( volume )

	if ( self.Disabled ) then return end

	for _, ply in ipairs( self.Players ) do
		umsg.Start( "ambient_generic_lua_update", ply )
			umsg.Char( self.EntIndex() )
			umsg.Char( volume )
		umsg.End()
	end

end

function ENT:StopSound( fade )

	if ( self.Disabled ) then return end

	self.Playing = false

	for _, ply in ipairs( self.Players ) do
		umsg.Start( "ambient_generic_lua_stop", ply )
			umsg.Char( self.EntIndex() )
			umsg.Bool( fade )
			if ( fade ) then
				umsg.Char( self.FadeOutTime )
			end
		umsg.End()
	end

end

function ENT:Disable()

	self.Disabled = true
	self.Playing = false

	for _, ply in ipairs( self.Players ) do
		self:EndClient( ply )
	end

end

function ENT:Enable()

	self.Disabled = false
	
	for _, ply in ipairs( self.Players ) do
		self:StartClient( ply )
	end

end

function ENT:AcceptInput( input, activator, caller, data )

	if ( input == "Enable" ) then
		self:Disable()
	end
	
	if ( input == "Disable" ) then
		self:Enable()
	end

	if ( input == "PlaySound" ) then
		self:PlaySound()
	end
	
	if ( input == "StopSound" ) then
		self:StopSound( self.Fade )
	end
	
	if ( input == "Volume" ) then
		self:UpdateSound( data )
	end
	
	if ( input == "FadeOut" ) then
		self:StopSound( true )
	end
	
end