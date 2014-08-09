AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

// To-do
// - Recompile model under pt
// - Fix weird chair physics issue
// - Implement local bet with slots_spin command
// - Define multiplier combinations (In-Progress)
// - Send winnings
// - Jackpot System
//		- All money bet that doesn't win

/*---------------------------------------------------------
	Basics
---------------------------------------------------------*/
function ENT:Initialize()
	
	self.BetAmount = 10
	self.SlotsPlaying = nil
	self.SlotsSpinning = false
	self.LastSpin = CurTime()
	
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow( false )
	self:SetAngles( Angle( 0, 90, 0) )
	
	self:SetupChair()
	self:SetupLight()

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
	
end


function ENT:Think()

	// Player In Chair Check
	if !self.SlotsPlaying && self:IsInUse() then		// Game not in play, player in chair
		self:SendPlaying()
	elseif self.SlotsPlaying && !self:IsInUse() then	// Game in play, nobody in chair
		if IsValid(self.chair) then
			self.chair:Remove()
		end
		self.SlotsPlaying = nil
	end

	// Player Idling Check
	if ( self.LastSpin + (60*3) < CurTime() ) && self:IsInUse() then
		local ply = self:GetPlayer()
		ply:ExitVehicle()
		GAMEMODE:PlayerMessage( ply, "Slots", "You have been ejected due to idling!" )
		ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	end
	
	if ( self.Jackpot && self.Jackpot < CurTime() ) then
		self.Jackpot = nil
	end
	
	self:NextThink(CurTime()) // Don't change this, the animation requires it
	
	return true
end


/*---------------------------------------------------------
	Chair Related Functions
---------------------------------------------------------*/
local function HandleRollercoasterAnimation( vehicle, player )
	return player:SelectWeightedSequence( ACT_GMOD_SIT_ROLLERCOASTER )
end

function ENT:SetupChair()

	// Chair Model
	self.chairMdl = ents.Create("prop_physics_multiplayer")
	--self.chairMdl:SetModel("models/props/cs_militia/barstool01.mdl")
	self.chairMdl:SetModel(self.ChairModel)
	--self.chairMdl:SetParent(self)
	self.chairMdl:SetPos( self:GetPos() + Vector(0,35,-2) )
	self.chairMdl:SetAngles( Angle(0, math.random(-180,180), 0) )
	self.chairMdl:DrawShadow( false )
	
	self.chairMdl:PhysicsInit(SOLID_VPHYSICS)
	self.chairMdl:SetMoveType(MOVETYPE_NONE)
	self.chairMdl:SetSolid(SOLID_VPHYSICS)
	
	self.chairMdl:Spawn()
	self.chairMdl:Activate()
	
	local phys = self.chairMdl:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
	
	self.chairMdl:SetKeyValue( "minhealthdmg", "999999" )
	
end

function ENT:SetupVehicle()

	// Chair Vehicle
	self.chair = ents.Create("prop_vehicle_prisoner_pod")
	self.chair:SetModel("models/nova/airboat_seat.mdl")
	self.chair:SetKeyValue("vehiclescript","scripts/vehicles/prisoner_pod.txt")
	--self.chair:SetParent(self)
	self.chair:SetPos( self:GetPos() + Vector(0,35,30) )
	self.chair:SetAngles( Angle(0,180,0) )
	self.chair:SetNotSolid(true)
	self.chair:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	self.chair:SetNoDraw(true)
	self.chair:DrawShadow( false )

	self.chair.HandleAnimation = HandleRollercoasterAnimation
	self.chair.bSlots = true

	self.chair:Spawn()
	self.chair:Activate()
	
	local phys = self.chair:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
	
end

function ENT:SetupLight()

	self.light = ents.Create("slotmachine_light")

	self.light.Jackpot = false
	self.light:SetPos( self:GetPos() + Vector( 0, -5, 80 ) )

	self.light:Spawn()
	self.light:Activate()

end

function ENT:IsInUse()

	if IsValid(self.chair) && self.chair:GetDriver():IsPlayer() then
		return true
	else
		return false
	end
	
end

/*---------------------------------------------------------
	Initial Player Interaction
---------------------------------------------------------*/
function ENT:Use( ply )

	if !IsValid(ply) || !ply:IsPlayer() then
		return
	end
	
	if ( ply:GetBilliardTable() ) then
		GAMEMODE:PlayerMessage( ply, "Warning!", "You cannot play slots while you are in a billiards game.\nYou must quit your billiards game!" )
		return
	end
	
	if !self:IsInUse() then
		self:SetupVehicle()
	
		if !IsValid(self.chair) then return end -- just making sure...
	
		ply.SeatEnt = self.chair
		ply.EntryPoint = ply:GetPos()
		ply.EntryAngles = ply:EyeAngles()
		
		ply:EnterVehicle( self.chair )
		self:SendPlaying( ply )
	else
		return
	end
	
end

hook.Add( "PlayerLeaveVehicle", "ResetCollisionVehicle", function( ply )

	ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

end )

hook.Add( "CanPlayerEnterVehicle", "PreventEntry", function( ply, vehicle )

	if ( ply:GetBilliardTable() ) then
		GAMEMODE:PlayerMessage( ply, "Warning!", "You cannot play slots while you are in a billiards game.\nYou must quit your billiards game!" )
		return false
	end
	
	return true

end )

/*---------------------------------------------------------
	Console Commands
---------------------------------------------------------*/
concommand.Add( "slotm_spin", function( ply, cmd, args )
	local bet = tonumber(args[1]) or 10
	local ent = ply.SlotMachine
	if IsValid(ent) && !ent.SlotsSpinning && !ent.Jackpot then
		ent.LastSpin = CurTime()
		ent.BetAmount = bet
		ent:PullLever()
		ent:PickResults()
		
		GAMEMODE:PlayerMessage( ply, nil, nil )
	end
end )

/*---------------------------------------------------------
	Slot Machine Functions
---------------------------------------------------------*/
function ENT:GetPlayer()

	local ply = player.GetByID( self.SlotsPlaying )

	if IsValid(ply) && ply:IsPlayer() && self:IsInUse() then
		return ply
	end


end

function ENT:SendPlaying()
	
	if ( !IsValid( self ) || !IsValid(self.chair) ) then return end

	self.SlotsPlaying = self.chair:GetDriver():EntIndex()
	self.LastSpin = CurTime()
	
	local ply = self:GetPlayer()
	if !IsValid( ply ) then return end
	ply.SlotMachine = self
	
	local rf = RecipientFilter()
	rf:AddPlayer( ply )
	
	umsg.Start("slotsPlaying", rf)
		umsg.Short( self:EntIndex() )
	umsg.End()
	
end


function ENT:PullLever()
	
	local seq = self:LookupSequence("pull_handle")
    
	if seq == -1 then return end
    
	self:ResetSequence(seq)
	
end


function ENT:PickResults()

	self.SlotsSpinning = true
	
	local rf = RecipientFilter()
	//rf:AddPlayer( self:GetPlayer() )
	rf:AddAllPlayers()
	
	local random = { getRand(), getRand(), getRand() }
	
	umsg.Start("slotsResult", rf)
		umsg.Short( self:EntIndex() )
		umsg.Short( random[1] )
		umsg.Short( random[2] )
		umsg.Short( random[3] )
	umsg.End()
	
	self:EmitSound( Casino.SlotPullSound, 30, 100 )
	
	timer.Simple( Casino.SlotSpinTime[3], function()
		self:CalcWinnings( random )
	end )
	
	// Prevent spin button spam
	timer.Simple( Casino.SlotSpinTime[3] + 1, function()
		self.SlotsSpinning = false
	end )
end

// Ranked highest to lowest
ENT.ExactCombos = {
	//["6"] = { 2, 2, 2 }, //Jackpot?
	["5.5"] = { 1, 1, 1 },
	["5"] = { 3, 3, 3 },
	["4.5"] = { 4, 4, 4 },
	["4"] = { 5, 5, 5 },
	["3.5"] = { 6, 6, 6 },
}

ENT.AnyTwoCombos = {
	["2.5"] = 2,
}

function ENT:CalcWinnings( random )

	if !self:IsInUse() then
		return
	end
	
	local ply = self:GetPlayer()
	local winnings = 0
	
	// Jackpot
	if table.concat(random) == "222" then
		local winnings = math.Round( self:GetJackpot() + self.BetAmount )
		self:SendWinnings( ply, winnings, true )
		
		self:SetJackpot(0)
		
		return
	end
	
	// Exact Combos
	for x, combo in pairs( self.ExactCombos ) do
		if table.concat(random) == table.concat(combo) then
			local winnings = math.Round( self.BetAmount * tonumber(x) )
			self:SendWinnings( ply, winnings )
			return
		end
	end

	// Any Two Combos
	for x, combo in pairs( self.AnyTwoCombos ) do
		if random[3] == combo then
			local winnings = math.Round( self.BetAmount * tonumber(x) )
			self:SendWinnings( ply, winnings )
			return
		end
	end
	
	// Player lost
	self:SetJackpot( self:GetJackpot() + self.BetAmount )
	GAMEMODE:PlayerMessage( ply, "Slots", "Sorry, you didn't win anything." )
	
end

function ENT:SendWinnings( ply, amount, bJackpot )

	if bJackpot then
		PrintMessage( HUD_PRINTTALK, "[Slots] " .. ply:Name() .. " HAS WON THE JACKPOT! A total of " .. amount .. " garrybux!" )
		GAMEMODE:PlayerMessage( ply, "Slots JACKPOT", "YOU WON THE JACKPOT!\nYOU ARE THE GOD OF THE ELEVATOR!", 10 )
		self:EmitSound( Casino.SlotJackpotSound, 100, 100 )
		self.Jackpot = CurTime() + 25
	else
		self:EmitSound( Casino.SlotWinSound, 75, 100 )
		GAMEMODE:PlayerMessage( ply, "Slots Winner!", "You won " .. amount .. " garrybux!" )
	end

	if self.light then
		self.light:CreateLight( bJackpot )
	end
	
	GAMEMODE:Payout( ply, amount )
	
	//ParticleEffect( "coins", self:GetPos(), self:GetForward(), self )
	
end