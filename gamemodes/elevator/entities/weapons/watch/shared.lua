if SERVER then
	AddCSLuaFile( "shared.lua" )
end

SWEP.Spawnable			= true
SWEP.AdminSpawnable	= true

SWEP.PrintName	= "Watch"
SWEP.Slot				= 0
SWEP.SlotPos			= 0

SWEP.ViewModel	= Model("models/weapons/v_watch.mdl")
SWEP.WorldModel	= ""
SWEP.HoldType		= "normal"

SWEP.Primary = {
    ClipSize     = -1,
    Delay = 1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.Secondary = {
    ClipSize     = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.Delay = {
	View = 1,
	Cough = function()
		if !COOLDOWN_CVAR:GetBool() then return 2 end
		return math.random(45,60)
	end,
	Slap = function()
		if !COOLDOWN_CVAR:GetBool() then return 2 end
		return math.random(120,540)
	end,
	Drink = 25/30 * 2
}

SWEP.Sounds = {
	Miss = Sound("Weapon_Knife.Slash"),
	HitWorld = Sound("Default.ImpactSoft")
}

SWEP.CheapAnims = {
	-- View watch
	Watch = {
		{ "ValveBiped.Bip01_Head1", Angle(0,-25,0) },
		{ "ValveBiped.Bip01_R_UpperArm", Angle(15,-40,-60) },
		{ "ValveBiped.Bip01_R_Forearm", Angle(0,-80,-45) }
	}
}

SWEP.Mins = Vector(-8, -8, -8)
SWEP.Maxs = Vector(8, 8, 8)

function SWEP:Initialize()
	self.iNextCough = nil

	self:SetWeaponHoldType(self.HoldType)

	self:DrawShadow(false)

	if SERVER then
		self.Weapon:SetNextSecondaryFire( CurTime() + self.Delay:Cough() )
	end
end

function SWEP:SetupDataTables()
    self:DTVar( "Bool", 0, "Viewing" )
    self:DTVar( "Bool", 1, "Spinning" )
end

local spin = {
	hour = math.Rand(0,1),
	min = math.Rand(0,1)
}
function SWEP:Think()
	-- Single player fix
	if !IsValid(self.Owner) then return end

	local vm = self.Owner:GetViewModel()
	if !IsValid(self.Owner) then return end

	if SERVER then

		-- Forced cough
		if self.iNextCough && CurTime() > self.iNextCough then
			self.iNextCough = nil
			self:Cough()
		end

		-- Disable cup bodygroup
		if !self:IsDrinking() && vm:GetBodygroup(0) == 1 then
			vm:SetBodygroup(0,0)
		end

		-- Reset animations
		if !self:IsInUse() && self:GetSequence() != 0 then -- not in idle animation
			self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
		end

	else

		-- Watch spinning effect
		if self:IsSpinning() then
			spin.hour = spin.hour + 0.003
			spin.min = spin.min + 0.008
			vm:SetPoseParameter("hhand_rot", spin.hour)
			vm:SetPoseParameter("mhand_rot", spin.min)
		else
			local time = os.date("*t") -- get current time in table format
			local mrot = time.min / 60
			local hrot = (time.hour / 12) + ((1/12) * mrot)
			vm:SetPoseParameter("hhand_rot", hrot)
			vm:SetPoseParameter("mhand_rot", mrot)
		end

	end

end

function SWEP:IsInUse()
	return self:IsViewingWatch(true) ||
		self:IsCoughing() ||
		self:IsSlapping() ||
		self:IsDrinking()
end

--[[-----------------------------------------
		Action Slots

		Christ, this swep ended up
		being a lot more than what
		we started with...
-------------------------------------------]]
SWEP.ActionSlots = {}

SLOT_COUGH 	= 1
SLOT_SLAP 		= 2
SLOT_DRINK 	= 3

function SWEP:SetNextAction(slot, time)
	if !self.ActionSlots[slot] then
		self.ActionSlots[slot] = {}
	end

	self.ActionSlots[slot].Last = CurTime()
	self.ActionSlots[slot].Next = time
end

function SWEP:GetNextAction(slot)
	if !self.ActionSlots[slot] then
		return -1
	else
		return self.ActionSlots[slot].Next
	end
end

function SWEP:GetLastAction(slot)
	if !self.ActionSlots[slot] then
		return -1
	else
		return self.ActionSlots[slot].Last
	end
end

--[[-----------------------------------------
		Watch Viewing
-------------------------------------------]]
function SWEP:IsViewingWatch(bCheckAnim)
	if bCheckAnim then -- checks if watch might be in the ending animation
		return self.dt.Viewing || ( self:GetNextPrimaryFire() > CurTime() )
	else
		return self.dt.Viewing
	end
end

function SWEP:SetViewing(bView)
	self.dt.Viewing = bView
end

--[[-----------------------------------------
		Watch Spinning
-------------------------------------------]]
function SWEP:IsSpinning()
	return self.dt.Spinning
end

function SWEP:SetSpinning(bSpin)
	self.dt.Spinning = bSpin
end

--[[-----------------------------------------
		Coughing
-------------------------------------------]]
function SWEP:IsCoughing()
	return self:GetLastAction(SLOT_COUGH) + 1 > CurTime()
end

function SWEP:Cough()
	if self:IsViewingWatch() then self:SetViewing(false) end

	self.Weapon:SendWeaponAnim(ACT_VM_RECOIL1)
	self.Owner:EmitSound( GAMEMODE:RandomDefinedSound( SOUNDS_COUGH ), 100, 100)

	self.Weapon:SetNextAction( SLOT_COUGH, CurTime() + self.Delay:Cough() )
end

--[[-----------------------------------------
		Drinking
-------------------------------------------]]
function SWEP:IsDrinking()
	return self:GetLastAction(SLOT_DRINK) + 2 > CurTime()
end

function SWEP:Drink()
	if !SERVER then return end
	if self:IsViewingWatch() then self:SetViewing(false) end

	local vm = self.Owner:GetViewModel()
	vm:SetBodygroup(0,1) -- enable cup bodygroup

	self.Weapon:SendWeaponAnim(ACT_VM_FIZZLE) -- fizzle dat soda

	timer.Simple( 2/3, function() -- drinking starts after 20 frames
		if !IsValid(self) then return end
		self.Owner:EmitSound( GAMEMODE:RandomDefinedSound( SOUNDS_DRINK ), 60, 100)
	end)

	self.Weapon:SetNextAction( SLOT_DRINK, CurTime() + self.Delay.Drink )
end

--[[-----------------------------------------
		Slapping
-------------------------------------------]]
function SWEP:IsSlapping()
	return self:GetLastAction(SLOT_SLAP) + 1 > CurTime()
end

function SWEP:Slap()
	if !SERVER then return end
	if self:IsViewingWatch() then self:SetViewing(false) end

	self.Weapon:SetNextAction( SLOT_SLAP, CurTime() + self.Delay:Slap() )

	local tr = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * 40),
		mins = self.Mins,
		maxs = self.Maxs,
		filter = self.Owner
	})

	local EmitSound = self.Sounds.Miss
	self.Owner:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE)

	if IsFirstTimePredicted() then
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
	end

	if tr.Hit then
		local ent = tr.Entity
		if IsValid(ent) && ( ent:IsPlayer() || ent:IsNPC() || ent:GetClass() == "prop_physics" ) then
			if ent:IsPlayer() || ent:IsNPC() then
				EmitSound = GAMEMODE:RandomDefinedSound( SOUNDS_SLAP )
			else
				EmitSound = self.Sounds.HitWorld
			end

			local pos = tr.StartPos
			local dmginfo = DamageInfo()
				dmginfo:SetDamage(0)
				dmginfo:SetDamagePosition(pos)
				dmginfo:SetDamageType(DMG_CLUB)
				dmginfo:SetInflictor(self.Owner)
				dmginfo:SetAttacker(self.Owner)

				local vec = (tr.HitPos - pos):GetNormal()
				if ent:IsPlayer() then -- SetVelocity is more practical for players
					ent:SetVelocity( vec * SLAPFORCE_CVAR:GetFloat() )
				else
					dmginfo:SetDamageForce( vec * 5000 )
				end

			ent:TakeDamageInfo(dmginfo)
		else
			EmitSound = self.Sounds.HitWorld
		end
	end

	self.Owner:EmitSound( EmitSound, 65, 100)
end

--[[-----------------------------------------
		Primary Fire - toggle watch
		Secondary Fire - cough
		Reload - slap
-------------------------------------------]]
function SWEP:PrimaryAttack()
	if !SERVER then return end
	if self:IsCoughing() || self:IsDrinking() || self:IsSlapping() then return end
	if IsValid( self.Owner.PickupItem ) then self.Owner.PickupItem = nil return end -- don't view watch while holding object

	if self:IsViewingWatch() then
		self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
		self:SetViewing(false)

		-- Reset cheap animations
		for _, bone in pairs(self.CheapAnims.Watch) do
			self.Owner:ManipulateBoneAngles(self.Owner:LookupBone(bone[1]) or 0, Angle(0,0,0))
		end
	else
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self:SetViewing(true)

		-- Rotate bones so it appears that the player is looking at their watch
		for _, bone in pairs(self.CheapAnims.Watch) do
			self.Owner:ManipulateBoneAngles(self.Owner:LookupBone(bone[1]) or 0, bone[2])
		end
	end

	self.Weapon:SetNextPrimaryFire( CurTime() + self.Delay.View )
end

function SWEP:SecondaryAttack()
	if !SERVER then return end
	if self:GetNextAction(SLOT_COUGH) > CurTime() then return end
	if self:IsSlapping() || self:IsDrinking() then return end
	if self:IsViewingWatch() then
		self:PrimaryAttack() -- stop viewing watch
		return
	end

	self:Cough()
end

function SWEP:Reload()
	if !SERVER then return end
	if self:GetNextAction(SLOT_SLAP) > CurTime() then return end
	if self:IsCoughing() || self:IsDrinking() then return end
	if self:IsViewingWatch() then
		self:PrimaryAttack() -- stop viewing watch
		return
	end

	self:Slap()
end


if CLIENT then

	local IsSinglePlayer = game.SinglePlayer

	function SWEP:DrawWorldModel() end -- silly view model thinks it's a world model too

	function SWEP:GetViewModelAttachment(attachment)
		local vm = self.Owner:GetViewModel()
		local attachID = vm:LookupAttachment(attachment)
		return vm:GetAttachment(attachID)
	end

	--[[-----------------------------------------
		CalcView override effect

		Uses attachment angles on view
		model for view angles
	-------------------------------------------]]
	local angdiff = nil
	local angfix = Angle(0,0,-90)

	function SWEP:CalcView( ply, origin, angles, fov )
		-- ViewModel.GetAttachment is currently broken in single player
		-- https://github.com/Facepunch/garrysmod-issues/issues/1255
		if IsSinglePlayer() then return end

		if !IsValid(self.Owner:GetVehicle()) then -- don't alter calcview when in vehicle
			local attach = self:GetViewModelAttachment("attach_camera")
			if !attach then return end

			local ang = attach.Ang

			angdiff = angles - (ang + angfix)

			-- SUPER HACK
			if (self:IsViewingWatch() || self:GetNextPrimaryFire() > CurTime()) && angdiff.r > 179.9 then -- view is flipped
				angdiff.p = -(89 - angles.p) -- find pitch difference to stop at 89 degrees
			end

			angles = angles - angdiff
		end

		return origin, angles, fov
	end

end

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:CanSecondaryAttack()
	return true
end

function SWEP:ShouldDropOnDie()
	return false
end
