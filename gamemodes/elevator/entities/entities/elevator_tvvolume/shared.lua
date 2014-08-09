if SERVER then
	AddCSLuaFile("shared.lua")
end

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Model = Model( "models/sam/arrow.mdl" )

function ENT:Initialize()

	if CLIENT then return end

	self:SetModel( self.Model )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )

	// required or this won't work at all
	self:SetCollisionBounds( Vector( -5 -5, -5 ), Vector( 5, 5, 5 ) )
	self:SetSolid( SOLID_BBOX )

	self:SetUseType( SIMPLE_USE )

	local phys = self:GetPhysicsObject()
	if ( IsValid( phys ) ) then
		phys:EnableMotion( false )
	end

end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Use( ply )

	if CLIENT then return end

	if !IsValid( ply ) || !ply:IsPlayer() then return end
	
	local tv = self:GetOwner()

	if ( !IsValid( tv ) ) then return end

	if ( tv:GetClass() == "elevator_tv" ) then
		if ( self.Lower ) then
			tv:LowerVolume( ply )
		else
			tv:RaiseVolume( ply )
		end
	end

end

function ENT:SetProperty( lower )

	if CLIENT then return end

	if ( lower ) then self:SetAngles( Angle( 0, 180, 0 ) ) end
	self.Lower = lower

end