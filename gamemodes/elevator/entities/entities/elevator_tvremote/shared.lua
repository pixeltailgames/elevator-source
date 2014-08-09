if SERVER then
	AddCSLuaFile("shared.lua")
end

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Model = Model( "models/sam/remote.mdl" )

function ENT:Initialize()

	if CLIENT then return end

	self:SetModel( self.Model )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
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
		tv:OpenControls( ply )
	end

end