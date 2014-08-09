ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName		= "Slot Machine"
ENT.Author			= "Sam"
ENT.Contact			= ""
ENT.Purpose			= "GMT"
ENT.Instructions	= ""
ENT.Spawnable		= true
ENT.AdminSpawnable	= true
ENT.AutomaticFrameAdvance = true

ENT.Model		= Model( "models/gmod_tower/casino/slotmachine.mdl")
ENT.ChairModel		= Model( "models/props_c17/chair_stool01a.mdl")
ENT.IconPitches = {
	[1] = -180,	// Bell 
	[2] = -120,	// Community Logo
	[3] = -60,	// Lemon
	[4] = 0,	// Strawberry
	[5] = 60,	// Watermelon
	[6] = 120	// Cherry
}

// Need to move these elsewhere?
Casino = {}
Casino.SlotSpinTime = { 0.8, 1.6, 2.4 }
//Casino.SlotGameSound = Sound( /* NEED A SOUND HERE */ )
Casino.SlotSelectSound = Sound( "buttons/lightswitch2.wav" )
Casino.SlotPullSound = Sound( "pt/casino/slots/slotpull.wav" )
Casino.SlotWinSound = Sound( "pt/casino/slots/winner.wav" )
Casino.SlotSpinSound = Sound( "pt/casino/slots/spin_loop1.wav" )
Casino.SlotJackpotSound = Sound( "pt/casino/slots/you_win_forever.mp3" )

function getRand()
	return math.random(1,6)
end

/*---------------------------------------------------------
	Jackpot
---------------------------------------------------------*/
function ENT:SetJackpot( amount )
	SetGlobalInt( "jackpot", amount )
end


function ENT:GetJackpot()
	return GetGlobalInt( "jackpot", 0 )
end