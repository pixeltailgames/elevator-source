if SERVER then
	AddCSLuaFile("shared.lua")
end

ENT.Type			= "anim"
ENT.Base			= "base_anim"

if CLIENT then return end

function ENT:Initialize()

	self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

	//self:SetMaterial( "models/flesh" )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	self:SetCollisionBounds( Vector( -128 -128, -128 ), Vector( 128, 128, 128 ) )

	local phys = self.Entity:GetPhysicsObject()
	if ( IsValid( phys ) ) then
		phys:Wake()
		phys:SetAngles( Angle( math.Rand(0,360), math.Rand(0,360), math.Rand(0,360) ) )
		phys:SetVelocity( VectorRand() * math.Rand( 10, 25 ) )
	end

end

--[[ function ENT:SetRealName( name )

	self.RealName = name

	// send to all clients
	umsg.Start( "Elevator_UpdateName" )
		umsg.Entity( self )
		umsg.String( name )
	umsg.End()
	
end ]]