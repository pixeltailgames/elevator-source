// dummy ent that creates a stand billiards table
ENT.Type 	= "point"
ENT.Base	= "base_point"

function ENT:Initialize()

	timer.Simple( .1, function()

		self:CreateBilliards()
		self:Remove()

	end )

end

function ENT:CreateBilliards()

	local ent = ents.Create( "billiard_table" )
	ent:SetSize( 10 )
	ent:SetPos( self:GetPos() )
	ent:SetAngles( Angle( 0, 90, 0 ) )
	ent:Spawn()

	ent:SetConfig( BILLIARD_GAMETYPE_8BALL, 30, false, false, 2, true, false )

	ent:Activate()
	ent:SetSkin( math.random( 0, 2 ) )

	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
	end

end