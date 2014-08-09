------------------------------------------------------------
-- MBilliards by Athos Arantes Pereira
-- Contact: athosarantes@hotmail.com
------------------------------------------------------------
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Initialize our vars
ENT.BilliardTableID = nil
ENT.BallType = nil
ENT.Model = Model( "models/billiards/ball.mdl" )

function ENT:Initialize()
	self:SetModel( self.Model )
	self:PhysicsInitSphere(0.94, "billiard_ball") -- We want perfect sphere collisions (54mm of diameter)
	self:SetCollisionBounds(Vector(-0.94, -0.94, -0.94), Vector(0.94, 0.94, 0.94))
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- Collides with everything but player
	local phys = self:GetPhysicsObject()
	phys:SetMass(1)
	phys:SetDamping(0, 1.2)
end

function ENT:PhysicsCollide(data, physobj)
	local ptable = self:GetBilliardTable()
	local Speed, HitEnt, hitpos = data.Speed, data.HitEntity, math.floor(data.HitPos[3])
	local poolPosZ = ptable:GetPos()[3]
	if(!ptable.WaitBallsToStop && hitpos >= poolPosZ + 33.9) then return physobj:SetVelocity(Vector(0,0,0)) end
	local NewVelocity = physobj:GetVelocity()
	local OldVelocity = data.OurOldVelocity:Length()
	local TheirOldVelocity = data.TheirOldVelocity:Length()
	NewVelocity = physobj:GetVelocity():GetNormal() * math.max(OldVelocity, Speed)
	if(HitEnt:GetClass() == "billiard_ball") then
		if(self.BallType == "CueBall" && !ptable.BehindHeadString && !ptable.Foul && !ptable.FirstHitBall &&
			ptable.GameType != BILLIARD_GAMETYPE_CARAMBOL) then
			if(!HitEnt.BallType) then ptable.FirstHitBall = HitEnt.uID
			else ptable.FirstHitBall = HitEnt.BallType end
		elseif(ptable.GameType == BILLIARD_GAMETYPE_CARAMBOL && self.BallType == "CueBall") then
			if(HitEnt.BallType == "Red") then ptable.CRHitRed = true
			else ptable.FirstHitBall = HitEnt.BallType end
		end
		if(hitpos >= poolPosZ + 33.9) then
			local uid = HitEnt.uID
			if(uid == 8 && ptable.GameType == BILLIARD_GAMETYPE_8BALL) then
				ptable.LastGameBallPos = HitEnt:GetPos()
			elseif(uid == 9 && ptable.GameType == BILLIARD_GAMETYPE_9BALL) then
				ptable.LastGameBallPos = HitEnt:GetPos()
			elseif(ptable.GameType == BILLIARD_GAMETYPE_ROTATION) then
				ptable.BallPositions[uid] = HitEnt:GetPos() -- Rotation works quite different
			end
		end
		-- Emit the ball-ball interaction sound
		-- All sounds were recorded from a free open source game: Foobillard Copyright Florian Berger
		if(data.DeltaTime > 0.07 && !ptable.Foul) then
			if(Speed <= 5) then
				self:EmitSound("billiards/hit_00.wav") 
			elseif(Speed > 5 && Speed <= 10) then
				self:EmitSound("billiards/hit_01.wav")
			elseif(Speed > 10 && Speed <= 20) then
				self:EmitSound("billiards/hit_02.wav")
			elseif(Speed > 20 && Speed <= 40) then
				self:EmitSound("billiards/hit_03.wav")
			elseif(Speed > 40 && Speed <= 60) then
				self:EmitSound("billiards/hit_04.wav")
			elseif(Speed > 60 && Speed <= 80) then
				self:EmitSound("billiards/hit_05.wav")
			elseif(Speed > 100) then
				self:EmitSound("billiards/hit_06.wav")
			end
		end
		if(OldVelocity <= 0.14 && TheirOldVelocity <= 0.14) then
			physobj:EnableMotion(false)
			return physobj:EnableMotion(true)
		end
		-- Speed loss calculation
		local loss
		if(OldVelocity > TheirOldVelocity) then
			loss = 1 - math.abs(data.HitNormal:DotProduct(data.OurOldVelocity:GetNormal()))
			if(loss <= 0.0030) then
				physobj:EnableMotion(false)
				return physobj:EnableMotion(true)
			end
			NewVelocity = NewVelocity * loss
		else
			loss = math.max(TheirOldVelocity, Speed)
			NewVelocity = NewVelocity:GetNormal() * loss
		end
	elseif(HitEnt:GetModel() == ptable:GetModel()) then
		if(hitpos >= poolPosZ + 33.9) then -- The ball hit the rail
			if(!self.HitRail) then
				ptable.BallsHitRail = ptable.BallsHitRail + 1
				self.HitRail = true
			end
			if(OldVelocity <= 0.14) then
				physobj:EnableMotion(false)
				return physobj:EnableMotion(true)
			end
			NewVelocity = NewVelocity * 0.85 -- Minus 15% of speed
			-- Emit the ball-rail interaction sound
			-- All sounds were recorded from a free open source game: Foobillard Copyright Florian Berger
			if(Speed <= 7) then
				self:EmitSound("billiards/tablehit_00.wav")
			elseif(Speed > 7 && Speed <= 15) then
				self:EmitSound("billiards/tablehit_01.wav")
			elseif(Speed > 15 && Speed <= 30) then
				self:EmitSound("billiards/tablehit_02.wav")
			elseif(Speed > 30 && Speed <= 50) then
				self:EmitSound("billiards/tablehit_03.wav")
			elseif(Speed > 50 && Speed <= 80) then
				self:EmitSound("billiards/tablehit_04.wav")
			elseif(Speed > 80) then
				self:EmitSound("billiards/tablehit_05.wav")
			end
		elseif(self:GetPos()[3] <= poolPosZ + 28) then -- The ball fell down in a hole
			return ptable:PocketBall(self)
		end
	else
		if(hitpos < poolPosZ + 20) then -- Ball jumped off table
			return ptable:PocketBall(self)
		end
	end
	return physobj:SetVelocity(Vector(NewVelocity[1], NewVelocity[2], 0))
end

function ENT:Think()
	self:NextThink(CurTime())
	local ptable = self:GetBilliardTable()
	-- In Carambol there's no need to check because we don't pocket any ball  =P
	if(ptable.GameType == BILLIARD_GAMETYPE_CARAMBOL) then return end
	-- This avoids the ball returning back when it was supposed to be pocketed... METHOD 1
	if(!ptable.WaitBallsToStop || ptable.ABMethod != 1) then return true end
	local physobj = self:GetPhysicsObject()
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos() + Vector(0, 0, -10)
	trace.filter = self
	trace = util.TraceLine(trace)
	if(trace.Hit && trace.Entity != nil && trace.Entity:GetClass() == "billiard_table") then
		local dist = 10 * trace.Fraction
		if(dist > 2.2) then
			physobj:SetVelocity(Vector(physobj:GetVelocity()[1] * 0.1, physobj:GetVelocity()[2] * 0.1, -80))
		end
	end
	return true
end