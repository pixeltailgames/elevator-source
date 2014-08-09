ENT.Base				= "base_brush"
ENT.Type				= "brush"

function ENT:Touch( ent )

	if ( !IsValid( ent ) || ent:GetClass() != "prop_physics" ) then return end
	
	local phys = ent:GetPhysicsObject()
	
	if ( IsValid( phys ) ) then
	
		phys:Wake()
		phys:EnableGravity( false )
		phys:EnableDrag( false )

	end

end