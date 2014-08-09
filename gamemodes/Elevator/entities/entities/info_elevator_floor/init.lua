ENT.Type 	= "point"
ENT.Base	= "base_point"

ENT.StartRelay = nil
ENT.EndRelay = nil

function ENT:KeyValue( key, value )

	if key == "relayStart" then
		self.StartRelay = value
	end
	
	if key == "relayEnd" then
		self.EndRelay = value
	end

end

function ENT:Start()

	if !self.StartRelay then return end

	local relay = ents.FindByName( self.StartRelay )[1]
	
	if ( IsValid( relay ) ) then
		relay:Fire( "Trigger", 0, 0 )
	end

end

function ENT:End()

	if !self.EndRelay then return end

	local relay = ents.FindByName( self.EndRelay )[1]
	
	if ( IsValid( relay ) ) then
		relay:Fire( "Trigger", 0, 0 )
	end

end

function ENT:KeyValue( key, value )

	if key == "relayStart" then
		self.StartRelay = value
	end

	if key == "relayEnd" then
		self.EndRelay = value
	end

end

function ENT:AcceptInput( input, activator, ply )

	if input == "end" then
		GAMEMODE:EndFloor()		
	end
	
end