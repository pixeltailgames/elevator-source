ENT.Base				= "base_brush"
ENT.Type				= "brush"

ENT.Players				= {}

ENT.Countdown			= false
ENT.NextCountdown		= 0 // holds the next countdown time
ENT.CurrentCountdown	= 0 // current second in countdown
ENT.MaxCountdown		= 3 // max seconds for the countdown

ENT.TrollTimer			= 0
ENT.DefaultTrollTime	= 12 // time before we force the elevator shut (if someone is waiting) this prevents players from leaving the doors and rentering (thus trolling)
ENT.Forced				= false

ENT.WallOn				= "lobby_wall_on"
ENT.WallOff				= "lobby_wall_off"
ENT.Closed				= false

function ENT:StartTouch( ply )

	if ( self.Closed ) then return end

	if ( !ply:IsPlayer() ) then return end
	
	if ( GAMEMODE.State == STATE_GAMEOVER ) then
		GAMEMODE:PlayerMessage( ply, "Elevator", "You will be taken to the top floor shortly." )
	end

	// Add player (if not already in list)
	if ( !table.HasValue( self.Players, ply ) ) then
		table.insert( self.Players, ply )
	end

	// Begin countdown (only if not being forced)
	if ( !self.Forced && !self.Countdown ) then
		self:BeginCountdown()
	end

	// Set troll time (force soon)
	if ( #self.Players > 1 && !self.TrollTime ) then
		self.TrollTime = CurTime() + self.DefaultTrollTime
	end

end

function ENT:EndTouch( ply )

	if ( !ply:IsPlayer() ) then return end
	
	local id = table.KeyFromValue( self.Players, ply )
	table.remove( self.Players, id )
	
	if ( #self.Players == 0 ) then
		self:Message( "start_idle" )
	end
	
	if ( GAMEMODE.State == STATE_GAMEOVER ) then
		GAMEMODE:PlayerMessage( ply, nil, nil )
	end

end

function ENT:Think()

	// check if there's players waiting
	if ( #self.Players < 1 || self.Closed ) then

		self:EndCountdown()
		self:ClearTimers()
		self.Forced = false
		return

	end

	// force shut after a peroid of time
	if ( self.TrollTime ) then

		if ( CurTime() > self.TrollTime ) then

			self:BeginCountdown()
			self.TrollTime = nil
			self.Forced = true
			return

		end

	end

	if self.Countdown && CurTime() > self.NextCountdown then
		self:DoCountdown()
	end

end

function ENT:BeginCountdown()

	self.Countdown = true
	self.NextCountdown = CurTime() + 1
	self.CurrentCountdown = self.MaxCountdown

end

function ENT:DoCountdown()

	self.NextCountdown = CurTime() + 1

	if self.CurrentCountdown == self.MaxCountdown then
		//self:Message( "Starting in " .. self.MaxCountdown .. "..." )
		self:Message( "start_" .. self.MaxCountdown )
	end
	
	if self.CurrentCountdown > 0 && self.CurrentCountdown < self.MaxCountdown then
		//self:Message( self.CurrentCountdown .. "..." )
		self:Message( "start_" .. self.CurrentCountdown )
	end
	
	if self.CurrentCountdown == 0 then
		//self:Message( "Elevator starting!" )
		self:Message( "start_4" )
		self:EndCountdown()
		self:BeginSending()
		return
	end

	self.CurrentCountdown = self.CurrentCountdown - 1

end

function ENT:EndCountdown()

	self.Countdown = false
	self.NextCountdown = 0
	self.CurrentCountdown = 0

end

function ENT:BeginSending()
	
	self:CloseDoors()
	timer.Simple( 4, function() self:Send() end )

end

function ENT:Send()

	if ( !self.Players ) then return end

	for _, ply in pairs( self.Players ) do

		GAMEMODE:SendPlayer( ply )

	end

	table.Empty( self.Players )
	self.Players = {}

	timer.Simple( 4, function() self:EndSending() end )

end

function ENT:EndSending()

	self:OpenDoors()
	self:Message( "start_idle" )

end

function ENT:Message( targetname )
	
	local ent = ents.FindByName(targetname)[1]
	if IsValid(ent) then
		ent:Fire( "Trigger", 0, 0 )
	else
		Msg("trigger_elevator: Error triggering " .. targetname .. "\n")
	end

end

function ENT:Remaining()
	return self.WaitTime - CurTime()
end

function ENT:ClearTimers()

	self.TrollTime = nil
	self.WaitTime = nil

end

function ENT:OpenDoors()
	self:Message( self.WallOff )
	self.Closed = false
end

function ENT:CloseDoors()
	self:Message( self.WallOn )
	self.Closed = true
end