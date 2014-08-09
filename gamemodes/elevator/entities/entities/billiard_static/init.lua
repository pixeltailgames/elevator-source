------------------------------------------------------------
-- MBilliards by Athos Arantes Pereira
-- Contact: athosarantes@hotmail.com
------------------------------------------------------------
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	self:SetUseType(SIMPLE_USE)
end

function ENT:Use(ply, caller)

	if !ply:IsPlayer() then return end

	local ptable = ply:GetBilliardTable()
	if !ptable then return end

	ptable:Use(ply, caller, USE_ON, 1)

end

--[[ function ENT:PhysicsCollide(data, physobj)
	local ply = data.HitEntity
	if(!ply:IsPlayer()) then return end
	local ptable = self:GetBilliardTable()
	if(!ply.BilliardTableID || ply.BilliardTableID != self.BilliardTableID) then
		return
	end
	if(ply:GetPos()[3] < self:GetPos()[3] + 37.5) then return end
	if(ptable:GetOpponentPlayer(ply)) then
		ptable.Turn = ptable:GetOpponentPlayer(ply).bpID
		return ptable:EndBilliardGame()
	end
	ptable:ClearEnts()
	ptable:ClearPlayers()
	ptable:ResetVars()
end ]]