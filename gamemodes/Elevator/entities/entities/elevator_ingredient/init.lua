ENT.Type 	= "point"
ENT.Base	= "base_point"
ENT.Ent		= nil	

function ENT:Initialize()

	timer.Simple( .1, function()

		self:CreateProp()

	end )

end

function ENT:Think()

	if ( !IsValid( self.Ent ) ) then

		self:CreateProp()

	end

end

function ENT:CreateProp()
	if !GAMEMODE.ValidIngredients then return end

	local ent = ents.Create( "prop_physics" )
		ent:SetModel( GAMEMODE.ValidIngredients[ math.random( 1, #GAMEMODE.ValidIngredients ) ] )
		ent:SetPos( self:GetPos() )
	ent:Spawn()
	ent:Activate()
	
	self.Ent = ent

end