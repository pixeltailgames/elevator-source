ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName	   	= "THE HAAAAANDDD"

ENT.Spawnable		= true
ENT.AdminSpawnable	= true

ENT.AutomaticFrameAdvance = true 
ENT.Model = Model( "models/sunabouzu/creep_hand.mdl" )

if SERVER then

	AddCSLuaFile( "shared.lua" )

	function ENT:Initialize()

		local GrabTime = 6.5 //Seconds from spawn from when a npc is grabbed
		
		self:SetModel( self.Model )
		self:SetAngles( Angle( 0, 180, 0 ) )
		
		self.TimeToGrab = CurTime() + GrabTime 
		self.IsGrabbing = false
		
		local sequence = self:LookupSequence( "creep_hand_grasp" )
		self:SetSequence( sequence )
		self:SetPlaybackRate( 1.0 )

	end

	function ENT:Think()
	
		if ( self.IsGrabbing || self.TimeToGrab > CurTime() ) then return end
		if !GAMEMODE.CurrentFloor then return end

		self.IsGrabbing = true
		//Msg("GRABBING THE VICTIM\n")

		local grabbedNPC = GAMEMODE:GetRandomElevatorNPC()

		local pos = GAMEMODE.CurrentFloor:GetPos() + Vector( 0, 0, ELEVATOR_WIDTH / 2 ) //Get the current elevator location
		
		if ( IsValid( grabbedNPC ) ) then
			umsg.Start("creep_hand_grab")
				umsg.Entity( grabbedNPC )
				umsg.Entity( self )
			umsg.End()
			timer.Simple( 0.1, function() grabbedNPC:Remove() end )
		
			if ( GAMEMODE:IsGirl( grabbedNPC:GetModel() ) ) then
				sound.Play( "elevator/effects/hand_grab.mp3", pos, 500, 160 )
			else
				sound.Play( "elevator/effects/hand_grab.mp3", pos, 500, 100 )
			end
		else
			sound.Play( "elevator/effects/hand_miss.mp3", pos, 500, 100 )
		end
		
		self:NextThink( CurTime() )
		return true
		
	end


else //CLIENT

	ENT.RenderGroup = RENDERGROUP_OPAQUE
	ENT.AutomaticFrameAdvance = true 

	function ENT:Draw()
		self:FrameAdvance( FrameTime() )
		self:DrawModel()
		
		if self.HasVictim && IsValid(self.Victim) then
			local ent = self.Victim
			local attID = self:LookupAttachment("victim_point")
			local posang = self:GetAttachment(attID) //get the table holding the position/angle of the attachment
			
			local normalized = posang.Ang:Right() //and the normalized right of it (to adjust the height)
			ent:SetPos( posang.Pos + normalized * 30 ) //Move the victim down a bit to fit more snugly in the clutches of the painful, merciless death claws
			ent:SetAngles( posang.Ang + Angle( 0, 0, 270 ) ) //and set his angle!
			

			ent:SetSequence( ACT_IDLE ) //Set the sequence of the victim (TODO: find some sort of panic animation)
			ent:FrameAdvance( FrameTime() ) //animate it
		end

	end

	function ENT:Initialize()
		local sequence = self:LookupSequence("creep_hand_grasp")
		self:SetSequence(sequence)
		self:SetPlaybackRate(1.0)
		
		self.HasVictim = false
		self.Victim = nil
	end
	
	function ENT:Think()  
		self:NextThink( CurTime() )
		return true
	end

	usermessage.Hook("creep_hand_grab", function( um )
		local ent = um:ReadEntity()
		local self = um:ReadEntity()
	
		if !IsValid( ent ) then return end
		local model = ent:GetModel()
		
		
		local deathEnt = ClientsideModel( model )
		
		self.Victim = deathEnt
		self.HasVictim = true
	end )
	
	function ENT:OnRemove()
		if IsValid( self.Victim ) then
			self.Victim:Remove()
			self.Victim = nil
			
			//Play a death sound or screech?
		end
	end

end
