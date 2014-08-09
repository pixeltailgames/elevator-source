------------------------------------------------------------
-- MBilliards by Athos Arantes Pereira
-- Contact: athosarantes@hotmail.com
------------------------------------------------------------
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Our main vars
ENT.Model = Model( "models/billiards/cue.mdl" )
ENT.BilliardTableID = nil
ENT.CanShoot = true
ENT.ZAng = 0
ENT.ShotSpeed = 0
ENT.Filter = {}

function ENT:Initialize()
	self:SetModel( self.Model )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- Collides with everything but player
end

function ENT:PhysicsCollide(data, physobj)
	local ptable = self:GetBilliardTable()
	-- If we hit the CueBall, hide the Cue and setup the billiard table to wait all balls stop.
	if(!ptable || data.HitEntity:GetClass() != "billiard_ball") then return end
	if(data.HitEntity.BallType == "CueBall" || ptable.Training) then
		if(ptable.FPerson) then
			self.ShotSpeed = math.Clamp(data.OurOldVelocity:Length(), 1, 400)
		end
		if(ptable.Foul) then
			ptable.Foul = false
		end
		ptable.BehindHeadString = false
		ptable:ToggleCollisions()
		ptable:ToggleBallsMotion(true)
		local vel = self:GetForward() * self.ShotSpeed * -1
		data.HitEntity:GetPhysicsObject():SetVelocity(Vector(vel[1], vel[2], 0))
		self.CanShoot = false
		self:SetColor( Color( 255, 255, 255, 0 ) )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:SetVelocity(Vector(0,0,0))
		self:SetPos(ptable:GetPos() + Vector(0, 0, 25))
		self:SetAngles(Angle(0, self:GetAngles().y, 0))
		physobj:EnableMotion(false)
		if(ptable.FPerson) then
			ptable:GetTurnPlayer():BilliardSpectate()
		else
			umsg.Start("billiard_mouseLock", ptable:GetTurnPlayer())
			umsg.End()
		end
		ptable.WaitBallsToStop = true
		ptable:SyncRoundTime(false)
		-- Emit the cue-ball interaction sound
		-- All sounds were recorded from a free open source game: Foobillard Copyright Florian Berger
		if(data.DeltaTime > 0.1) then
			if(data.Speed <= 5) then
				self:EmitSound("billiards/cuehit_00.wav")
			elseif(data.Speed > 5 && data.Speed <= 20) then
				self:EmitSound("billiards/cuehit_01.wav")
			elseif(data.Speed > 20 && data.Speed <= 60) then
				self:EmitSound("billiards/cuehit_02.wav")
			elseif(data.Speed > 60 && data.Speed <= 100) then
				self:EmitSound("billiards/cuehit_03.wav")
			elseif(data.Speed > 100 && data.Speed <= 140) then
				self:EmitSound("billiards/cuehit_04.wav")
			elseif(data.Speed > 140) then
				self:EmitSound("billiards/cuehit_05.wav")
			end
		end
		umsg.Start("billiard_sendSMsg", ptable:GetPlayersFilter())
		umsg.End()
	end
end

function ENT:Think()
	self:NextThink(CurTime())
	local ptable = self:GetBilliardTable()
	local ply = ptable:GetTurnPlayer()
	if(!self.CanShoot || !ply || !ptable:IsMyTurn(ply)) then return true end
	local Ang
	if(!ply.IsAiming) then
		Ang = self:GetRotation(ply:GetPos())
		self:SetAngles(Angle(self.ZAng, Ang + 90, 0))
	end
	if(!ptable.SmartCue) then
		self.ZAng = 0
		return true
	end
	-- SmartCue feature =P
	local ballpos = ptable:GetTableEnt():GetPos()
	local fwdir = self:GetForward() * 65 -- 65 because the cue is 65 units long
	local trace = {}
	trace.start = ballpos
	trace.endpos = ballpos + (fwdir)
	trace.filter = self.Filter
	trace = util.TraceLine(trace)
	if(trace.Hit && trace.Entity != nil) then
		local roc = 5 * trace.Fraction
		self.ZAng = math.Clamp(self.ZAng - (5 - roc), -90, 0)
	else
		Ang = self:GetAngles()
		if(Ang.p < 0) then
			trace = {}
			trace.start = ballpos
			trace.endpos = ballpos + Vector(fwdir[1], fwdir[2], 0)
			trace.filter = self.Filter
			trace = util.TraceLine(trace)
			if(!trace.Hit) then
				self.ZAng = 0
			end
		end
	end
	return true
end

function ENT:UpdateCue(ball)
	self.Filter = {}
	for k,v in pairs(ents.GetAll()) do -- I still have to change this piece of code
		if(v:GetClass() != "billiard_ball") then -- && v:GetClass() != "billiard_table") then
			table.insert(self.Filter, v)
		elseif(v:GetClass() == "billiard_ball" && v.BilliardTableID != self.BilliardTableID) then
			table.insert(self.Filter, v)
		elseif(v:GetClass() == "billiard_ball" && v.BilliardTableID == self.BilliardTableID && v.BallType == "CueBall") then
			table.insert(self.Filter, v)
		elseif(v:GetClass() == "billiard_table" && v.ID != self.BilliardTableID) then
			table.insert(self.Filter, v)
			constraint.NoCollide(self, v, 0, 0)
		end
	end
	if(self:GetBilliardTable().OpenBreakShot || self:GetBilliardTable().BehindHeadString) then
		local fwrd = self:GetBilliardTable():GetForward() * -1
		self:SetAngles(fwrd:Angle())
	end
	self.CanShoot = true
	self:SetColor(255, 255, 255, 255)
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	if(ball != nil && ball.BilliardTableID == self.BilliardTableID && ball:IsValid()) then
		self:SetPos(ball:GetPos())
	else
		self:SetPos(self:GetBilliardTable():GetTableEnt():GetPos())
	end
	self:GetPhysicsObject():EnableMotion(true)
end

function ENT:InitialSetup(poolid)
	self.BilliardTableID = poolid
	local ptable = self:GetBilliardTable()
	-- Nocollides with the table and the balls (except the CueBall)
	constraint.NoCollide(self, ptable, 0, 0)
	constraint.NoCollide(self, ptable:GetTableEnt("MGP"), 0, 0)
	constraint.NoCollide(self, ptable:GetTableEnt("HSL"), 0, 0)
	self:GetPhysicsObject():EnableGravity(false)
	if(!ptable.Training) then
		for k,v in pairs(ptable.Balls) do
			if(v.BallType != "CueBall") then
				constraint.NoCollide(self, v, 0, 0)
			end
		end
	end
	for i = 1, 6 do
		local pcol = ents.GetByIndex(ptable.EntsData[string.format("Pocket%02d_col", i)])
		if(!pcol) then continue end
		constraint.NoCollide(self, pcol, 0, 0)
	end
end

-- "Original function by Doomed_Space_Marine. Fixed by robhol." From the MTA Wiki. I only made a little edit ;P
function ENT:GetRotation(tpos)
	local pos = self:GetPos()
	local t = -math.deg(math.atan2(tpos[1] - pos[1], tpos[2] - pos[2]))
	if(t < 0) then
		t = t + 360
	end
	return t
end