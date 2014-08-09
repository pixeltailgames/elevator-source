GM.Name     = "Elevator: Source"
GM.Author   = "pixelTail Games"
DeriveGamemode( "base" )

//=====================================================

game.AddParticles("particles/elevator_particles.pcf")
game.AddParticles("particles/slappy_titfuck_goddamn.pcf")
game.AddParticles("particles/suna_fire.pcf")

local ParticleSystems = { "mono_fire", "rays", "confetti", "confetti_puff",
						  "tray_smoke", "noir_rain", "hearts", "cat1",
						  "cat02", "cat03", "cat04", "blood_spray",
						  "juice_red", "juice_green", "juice_blue",
						  "juice_orange",
						  "test_rain", "smoke_large_02b",
						  "fire_large_02_filler", "fire_large_02",
						  "fire_large_base", "fire_large_02_fillerb",
						  "smoke_medium_01", "fire_medium_base",
						  "fire_ploom_01", "fire_medium_01_filler",
						  "fire_medium_01", "fire_medium_01_fillerb",
						  "big_fire", "med_fire", "fire_large_02_warp",
						  "hair_fire" }
						  
for _, part in pairs( ParticleSystems ) do
	PrecacheParticleSystem( part )
end

//=====================================================

CHEAT_CONVAR = CreateConVar("sv_hedgehog", "0", { FCVAR_REPLICATED, FCVAR_CHEAT }, "Enable hedgehog mode.")
SLAPFORCE_CVAR = CreateConVar("elev_slapforce", 400, { FCVAR_REPLICATED, FCVAR_CHEAT, FCVAR_NOTIFY, FCVAR_NEVER_AS_STRING }, "The amount of force slapping causes on players")
COOLDOWN_CVAR = CreateConVar("elev_cooldown", 1, { FCVAR_REPLICATED, FCVAR_CHEAT, FCVAR_NOTIFY, FCVAR_NEVER_AS_STRING }, "1 = Cough/Slap cooldown; 0 = no cooldown")
ELEVATOR_WIDTH = 192

// ======================
// 		TEAMS
// ======================

TEAM_IDLE			= 1
TEAM_ELEVATOR		= 2
TEAM_END			= 3

team.SetUp( TEAM_IDLE, "In Lobby", Color( 255, 128, 0, 255 ) )
team.SetUp( TEAM_ELEVATOR, "In Elevator", Color( 255, 255, 128, 255 ) )
team.SetUp( TEAM_END, "Chilling Out", Color( 255, 128, 255, 255 ) )


// ======================
// 		MUSIC
// ======================

GM.Music = {
	{ Sound("elevator/music/elevator_1.mp3"), 147 },
	{ Sound("elevator/music/elevator_2.mp3"), 77 },
	{ Sound("elevator/music/elevator_3.mp3"), 34 },
	{ Sound("elevator/music/elevator_4.mp3"), 119 },
	{ Sound("elevator/music/elevator_5.mp3"), 130 },
	{ Sound("elevator/music/elevator_6.mp3"), 80 },
	{ Sound("elevator/music/elevator_7.mp3"), 162 },
	{ Sound("elevator/music/elevator_8.mp3"), 132 },
	{ Sound("elevator/music/elevator_9.mp3"), 201 },
	{ Sound("elevator/music/elevator_10.mp3"), 122 },
	{ Sound("elevator/music/elevator_11.mp3"), 369 },
	{ Sound("elevator/music/elevator_12.mp3"), 244 },
	{ Sound("elevator/music/elevator_13.mp3"), 187 },
	{ Sound("elevator/music/elevator_14.mp3"), 89 },
	{ Sound("elevator/music/elevator_15.mp3"), 131 },
	{ Sound("elevator/music/elevator_16.mp3"), 144 },
	{ Sound("elevator/music/elevator_17.mp3"), 88 },
	{ Sound("elevator/music/elevator_18.mp3"), 249 },
	{ Sound("elevator/music/elevator_19.mp3"), 161 },
	{ Sound("elevator/music/elevator_20.mp3"), 48 }
}

// ======================
// 		SOUNDS
// ======================

SOUND_BELL = 1
SOUND_START = 2
SOUND_STOP = 3
SOUNDS_CHEER = 4
SOUNDS_COUGH = 5
SOUNDS_DRINK = 6
SOUNDS_SLAP = 7

GM.Sounds = {
	[SOUND_BELL] = Sound( "elevator/effects/elevator_bell.wav" ),
	[SOUND_START] = Sound( "elevator/effects/elevator_start.wav" ),
	[SOUND_STOP] = Sound( "elevator/effects/elevator_stop.wav" ),
	[SOUNDS_CHEER] = { 
		Sound("odessa.nlo_cheer01"),
		Sound("odessa.nlo_cheer02"),
		Sound("odessa.nlo_cheer03")
	},
	[SOUNDS_COUGH] = {
		Sound("ambient/voices/cough1.wav"),
		Sound("ambient/voices/cough2.wav"),
		Sound("ambient/voices/cough3.wav"),
		Sound("ambient/voices/cough4.wav")
	},
	[SOUNDS_DRINK] = {
		Sound("elevator/effects/drink01.wav"),
		Sound("elevator/effects/drink02.wav"),
		Sound("elevator/effects/drink03.wav")
	},
	[SOUNDS_SLAP] = {
		Sound("elevator/effects/slap_hit01.wav"),
		Sound("elevator/effects/slap_hit02.wav"),
		Sound("elevator/effects/slap_hit03.wav"),
		Sound("elevator/effects/slap_hit04.wav"),
		Sound("elevator/effects/slap_hit05.wav"),
		Sound("elevator/effects/slap_hit06.wav"),
		Sound("elevator/effects/slap_hit07.wav"),
		Sound("elevator/effects/slap_hit08.wav"),
		Sound("elevator/effects/slap_hit09.wav")
	}
}

// ======================
// 		NPC NAMES
// ======================

GM.MaleNames = { "Roscoe", "Gordon", 
			  "Steve", "Hank", 
			  "James", "Darwin",
			  "John", "Sebastion",
			  "Scott", "Tidus",
			  "Ry", "Reginald Von Bloodslurp",
			  "Lizard Wizard", "Hjord",
			  "Baker", "Jacob",
			  "Barker", "Topher",
			  "Derek", "Ryan",
			  "Fernando", "Garry",
			  "Jerry", "Jaykin",
			  "Sam", "Jesus",
			  "BJ", "JB", "Andy",
			  "Thomas", "Renny",
			  "Spike", "Barley",
			  "The Dude",
			  "Andreas", "Horacio",
			  "Hamlet", "Isaac",
			  "Barney", "Lonk",
			  "God", "Wolf God"
}

GM.FemaleNames = { "Shaniqua",
				"Racheal", "Kate",
				"Tabitha", "Amber",
				"Ally", "Irene",
				"Brianna", "Samantha",
				"Alex", "Sarah",
				"Tammy", "Lynn", 
				"Lisa", "Anita Dick",
				"Claire", "Jill", "Sherry",
				"Aya", "Ada", "Regina",
				"Candy", "Sandy", 
				"Sugha", "Spice", "Everrrythin' Niiice",
				"Kitty", "Selina", "Blossom",
				"Talia", "Nadia", "Envy",
				"Heather", "Titney Spheres",
				"Maria", "Chastity",
				"Conquerer Mary", "Joan d' Arc",
				"Marie Curie", 
				"Amy", "Rose",
				"Couriette",
				"13/f/cali"
}

// ======================
// 		BLENDER
// ======================

// INGREDENT IDS
APPLE		= 1
STRAWBERRY	= 2
WATERMELON	= 3
BANANA		= 4
ORANGE		= 5
GLASS		= 6
PLASTIC		= 7
BONE		= 8

GM.ValidIngredients = { 
	[APPLE]			= Model("models/sunabouzu/fruit/apple.mdl"),
	[STRAWBERRY]	= Model("models/sunabouzu/fruit/strawberry.mdl"),
	[WATERMELON]	= Model("models/props_junk/watermelon01_chunk01b.mdl"),
	[BANANA]		= Model("models/props/cs_italy/bananna.mdl"),
	[ORANGE]		= Model("models/props/cs_italy/orange.mdl"),
	[GLASS]			= Model("models/props_junk/garbage_glassbottle001a.mdl"),
	[PLASTIC]		= Model("models/props_junk/garbage_plasticbottle002a.mdl"),
	[BONE]			= Model("models/gibs/hgibs.mdl"),
}

// ======================
// 		FUNCTIONS
// ======================

/**
 * Returns if a model is a female
 */
function GM:IsGirl( mdl )
	return string.find( tostring( mdl ), "female" )
end

/**
 * Returns a random NPC name ID (based on male/female list)
 */
function GM:GetRandomNPCNameID( mdl )

	if ( self:IsGirl( mdl ) ) then
		return math.random( 1, #self.FemaleNames )
	end
	
	return math.random( 1, #self.MaleNames )

end

/**
 * Returns NPC name with given ID
 */
function GM:GetNPCName( id, mdl )

	if ( self:IsGirl( mdl ) ) then
		return self.FemaleNames[ id ]
	end

	return self.MaleNames[ id ]

end

/**
 * Returns a random sound
 */
function GM:RandomSound( tbl )

	return tbl[ math.random( 1, #tbl ) ]

end

/**
 * Returns a random defined sound
 */
function GM:RandomDefinedSound( index )

	local snds = self.Sounds[index]
	if ( !snds ) then return end

	return self:RandomSound( snds )
	
end

/**
 * Returns if a player was holding an object
 */
function GM:WasHoldingObject( ply )

	return ply.LastPickup && ply.LastPickup + 0.2 > CurTime()
	
end

/**
 * Returns if a prop is a valid ingredient
 */
function GM:ValidIngredient( ent )

	if !IsValid( ent ) then return false end

	return table.HasValue( self.ValidIngredients, ent:GetModel() )

end

// ======================
// 		ANIMATIONS
// ======================

// fixes teleportation jerk, removed vaulting
function GM:CalcMainActivity( ply, velocity )

	ply.CalcIdeal = ACT_MP_STAND_IDLE
	ply.CalcSeqOverride = -1
	
	if self:HandlePlayerDriving( ply ) ||
		self:HandlePlayerNoClipping( ply, velocity ) ||
		self:HandlePlayerJumping( ply, velocity ) ||
		self:HandlePlayerDucking( ply, velocity ) ||
		self:HandlePlayerSwimming( ply, velocity ) then
		
	else
		local len2d = velocity:Length2D()
		
		if len2d > 210 then
			ply.CalcIdeal = ACT_MP_RUN
		elseif len2d > 0.5 then
			ply.CalcIdeal = ACT_MP_WALK
		end
	end
	
	// a bit of a hack because we're missing ACTs for a couple holdtypes
	local weapon = ply:GetActiveWeapon()
	
	if ply.CalcIdeal == ACT_MP_CROUCH_IDLE &&
		IsValid(weapon) &&
		( weapon:GetHoldType() == "knife" || weapon:GetHoldType() == "melee2" ) then
		
		ply.CalcSeqOverride = ply:LookupSequence("cidle_" .. weapon:GetHoldType())
	end
	

	return ply.CalcIdeal, ply.CalcSeqOverride

end

// ======================
// 		PLAYER META
// ======================

local PlayerMeta = FindMetaTable("Player")

/**
 * Returns the player's watch if it is valid
 */
function PlayerMeta:GetWatch()

	local watch = self:GetActiveWeapon()

	if ( IsValid( watch ) && watch:GetClass() == "watch" ) then
		return watch
	end

end

/**
 * Returns if a player has the watch equipped
 */
function PlayerMeta:HasWatchEquipped()
	
	if ( self:GetWatch() ) then return true end
	return false

end
