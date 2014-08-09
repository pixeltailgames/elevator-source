if SERVER then
	AddCSLuaFile("shared.lua")
end

ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.Model			= Model( "models/sunabouzu/juice_cup.mdl" )

if CLIENT then return end

ENT.Used			= false
ENT.Drink			= nil
ENT.Player			= nil
ENT.DelayTime		= nil
ENT.EffectTime		= 0

ENT.EffectStart		= nil
ENT.EffectThink		= nil
ENT.EffectEnd		= nil

function ENT:Initialize()

	self:SetModel( self.Model )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetUseType( SIMPLE_USE )

end

function ENT:SetDrink( drink )

	self:SetColor( drink.Color )
	
	self.EffectStart = drink.Start or nil
	self.EffectThink = drink.Think or nil
	self.EffectEnd = drink.End or nil

	self.Drink = drink

end

function ENT:Use( ply )

	if ( self.Used || !ply:HasWatchEquipped() ) then return end
	
	// used drink
	self.Used = true

	// player drink anim
	ply:GetActiveWeapon():Drink()

	// store reference to player
	self.Player = ply
	
	if ( !self.Drink ) then return end

	self.DelayTime = CurTime() + 1.5
	self.EffectTime = CurTime() + ( self.Drink.Time or 0 )

	// remove from visibility
	self:SetNoDraw( true )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
	end

end

function ENT:Think()

	if ( !self.Player || !self.Drink ) then return end

	if ( self.DelayTime && self.DelayTime < CurTime() ) then
		self.DelayTime = nil

		if ( self.EffectStart ) then
			self.EffectStart( self.Player )
		end
		return
	end

	if ( self.EffectTime < CurTime() ) then
		if ( self.EffectEnd ) then
			self.EffectEnd( self.Player )
		end

		self:Remove()
		return
	end
	
	if ( self.EffectThink ) then
		self.EffectThink( self.Player )
	end

end