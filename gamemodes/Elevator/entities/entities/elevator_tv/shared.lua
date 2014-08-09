if SERVER then
	AddCSLuaFile("shared.lua")
end

ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.Type 				= "anim"
ENT.Base 				= "base_anim"
ENT.Model 				= Model( "models/gmod_tower/suitetv.mdl" )
ENT.Width 				= 1024
ENT.Height 				= 768
ENT.Scale 				= 0.053
ENT.BasePosition 		= Vector( 0, -27, 35 )

local UMSG_OFF			= 0
local UMSG_ON			= 1
local UMSG_CONTROL		= 2

if SERVER then

	ENT.TurnOffDist 	= 300

	function ENT:Initialize()

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow( false )
		self:SetModel( self.Model )
		
		self:SetAngles( Angle( 0, 180, 0 ) )
		self:SetUseType( SIMPLE_USE )

		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:EnableMotion( false )
		end

		timer.Simple( .1, function()

			if ( !IsValid( self ) ) then return end

			// Create remote
			local ent = ents.Create( "elevator_tvremote" )
				ent:SetPos( self:GetPos() + ( self:GetForward() * 12 ) )
				ent:DrawShadow( false )
			ent:Spawn()
			ent:Activate()
			ent:SetOwner( self )

			// Create lower volume arrow
			local ent = ents.Create( "elevator_tvvolume" )
				ent:SetPos( self:GetPos() + ( self:GetForward() * 12 ) + Vector( 0, 10, 0 ) )
				ent:DrawShadow( false )
			ent:Spawn()
			ent:Activate()
			ent:SetProperty( true )
			ent:SetOwner( self )

			// Create raise volume arrow
			local ent = ents.Create( "elevator_tvvolume" )
				ent:SetPos( self:GetPos() + ( self:GetForward() * 12 ) + Vector( 0, -10, 0 ) )
				ent:DrawShadow( false )
			ent:Spawn()
			ent:Activate()
			ent:SetProperty( false )
			ent:SetOwner( self )

		end )

	end
	
	function ENT:Think()

		for _, ply in pairs( player.GetAll() ) do
		
			if ( self:IsWatching( ply ) ) then
				local dist = ply:GetPos():Distance( self:GetPos() )
				if ( dist > self.TurnOffDist ) then
					self:TurnOffTV( ply )				
				end
			end
		
		end
		
	end
	
	function ENT:Use( ply )
	
		if ( !IsValid( ply ) ) then return end

		if ( !self:IsWatching( ply ) ) then
			self:TurnOnTV( ply )
		else
			self:TurnOffTV( ply )
		end

	end
	
	function ENT:AddPlayer( ply )
	
		if ( !IsValid( ply ) ) then return end
	
		ply.ActiveTV = self
	
	end
	
	function ENT:RemovePlayer( ply )
	
		if ( !IsValid( ply ) ) then return end

		ply.ActiveTV = nil

	end
	
	function ENT:IsWatching( ply )
		return IsValid( ply.ActiveTV ) && ply.ActiveTV == self
	end
	
	function ENT:TurnOnTV( ply )
	
		if ( !IsValid( ply ) ) then return end

		self:AddPlayer( ply )

		umsg.Start( "elevator_tvstatus", ply )
			umsg.Entity( self )
			umsg.Char( UMSG_ON )
		umsg.End()

		//if ( self:IsWatching( ply ) ) then
			self:UpdatePlayer( ply )
		//end

	end

	function ENT:TurnOffTV( ply )
	
		if ( !IsValid( ply ) ) then return end

		self:RemovePlayer( ply )

		umsg.Start( "elevator_tvstatus", ply )
			umsg.Entity( self )
			umsg.Char( UMSG_OFF )
		umsg.End()

	end
	
	function ENT:TVIsPlaying()
		return tobool( self.VideoID )
	end
	
	function ENT:TVTime()
		return math.Round( CurTime() - ( self.VideoStartTime or 0 ) )
	end
	
	function ENT:SetTV( ply, vid, dur )
	
		if ( !IsValid( ply ) ) then return end

		self.VideoID = vid
		self.VideoStartTime = CurTime()
		
		self:UpdateAllPlayers( ply )

	end
	
	function ENT:UpdateAllPlayers( starter )
	
		for _, ply in pairs( player.GetAll() ) do

			// Don't update the starter - they're already up to date
			if ( IsValid( starter ) && ply == starter ) then
				continue
			end

			if ( self:IsWatching( ply ) ) then
				self:UpdatePlayer( ply )
				GAMEMODE:PlayerMessage( ply, "TV", starter:Nick() .. " started a new video.", 3 )
			end

		end

		// Don't forget the starter
		if ( IsValid( starter ) ) then
			self:AddPlayer( starter )
		end
	
	end
	
	function ENT:UpdatePlayer( ply )
	
		if ( !IsValid( ply ) ) then return end

		umsg.Start( "elevator_updatetv", ply )
			umsg.Entity( self )
			umsg.String( self.VideoID or "" )
			umsg.Short( self:TVTime() or 0 )
		umsg.End()

	end
	
	function ENT:OpenControls( ply )
	
		if ( !IsValid( ply ) ) then return end

		umsg.Start( "elevator_tvstatus", ply )
			umsg.Entity( self )
			umsg.Char( UMSG_CONTROL )
		umsg.End()

	end
	
	function ENT:LowerVolume( ply )
	
		if ( !IsValid( ply ) ) then return end

		umsg.Start( "elevator_tvvolume", ply )
			umsg.Bool( true ) // true to lower, false to raise
		umsg.End()
	
	end
	
	function ENT:RaiseVolume( ply )
	
		if ( !IsValid( ply ) ) then return end

		umsg.Start( "elevator_tvvolume", ply )
			umsg.Bool( false ) // true to lower, false to raise
		umsg.End()
	
	end
	
	concommand.Add( "elev_settv", function( ply, cmd, args )
		
		if #args < 2 then
			return
		end
		
		local vid = args[1]

		Msg( vid )

		local tvindex = tonumber( args[2] )
		if !tvindex then return end
		
		local tv = Entity( tvindex )
		if !IsValid( tv ) then return end

		tv:SetTV( ply, vid )

	end )
	
else // Client

	ENT.URL	= "http://www.pixeltailgames.com/elevator/tv/"

	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:DrawTranslucent()

		local status, err = pcall( self.DrawPanel, self)
			
		if not status then
			print( err )
		end
		
	end

	function ENT:TurnOff()

		if ( !self:IsOn() ) then return end
	
		if ValidPanel( self.Browser ) then
			self.Browser:Remove()
			self.Browser = nil
		end

		LocalPlayer().ActiveTV = nil
		self:EmitSound( "elevator/effects/tv_off.wav" )

	end

	function ENT:TurnOn()

		if ( self:IsOn() ) then return end
	
		if !ValidPanel( self.Browser ) then
			self.Browser = vgui.Create( "EntityHTML" )
			self.Browser:SetSize( self.Width, self.Height )
			self.Browser:SetVisible( false )
			self.Browser:SetPaintedManually( true )
			self.Browser:SetEntity( self )

			self:UpdateTV()
		end
		
		LocalPlayer().ActiveTV = self
		self:EmitSound( "elevator/effects/tv_on.wav" )

	end
	
	function ENT:IsOn()
		return ValidPanel( self.Browser )
	end

	function ENT:UpdateTV( vid, time )

		if !ValidPanel( self.Browser ) then return end
		
		if ( vid && time ) then
			self.Browser:OpenURL( self.URL .. "index.php?type=w&t=" .. time .. "&id=" .. vid )
		else
			self.Browser:OpenURL( self.URL .. "index.php?type=n" )
		end

	end

	function ENT:DisplayControls()

		if !self:IsOn() then
			self:TurnOn()
		end
		
		if !ValidPanel( self.Browser ) then return end
		
		if !ValidPanel( self.HTMLFrame ) then
			local w, h = self.Browser:GetWide() + 10, self.Browser:GetTall() + 35

			self.HTMLFrame = vgui.Create( "DFrame" )
			self.HTMLFrame:SetSize( w, h )
			self.HTMLFrame:SetTitle( "Elevator TV" )
			self.HTMLFrame:SetPos( ( ScrW() / 2 ) - ( w / 2 ), ( ScrH() / 2 ) - ( h / 2 ) )
			self.HTMLFrame:SetDraggable( false )
			self.HTMLFrame:ShowCloseButton( true )
			self.HTMLFrame:SetDeleteOnClose( false ) //Do not remove when the window is closed, just hide it
		end
		
		self.Browser:SetPaintedManually( false )
		self.Browser:SetParent( self.HTMLFrame )
		self.Browser:SetPos( 5, 25 )
		self.Browser:SetVisible( true )
		self.Browser:OpenURL( self.URL )
		
		self.HTMLFrame:SetVisible( true )
		self.HTMLFrame:MakePopup()
		
		local browser = self.Browser
		local tv	  = self
		self.HTMLFrame.Close = function( self )
			DFrame.Close( self )
			
			if ( ValidPanel( browser ) ) then
				browser:SetPaintedManually( true )
				browser:SetParent( nil )
				browser:SetVisible( false )
				tv:UpdateTV( tv.VideoID, math.Round( CurTime() - ( tv.VideoStartTime or 0 ) ) )
				//tv:TurnOff()
			end
		end

	end

	function ENT:GetPosBrowser()
		return self:GetPos() + (self:GetForward() * 1) + (self:GetUp() * -5.5)
	end

	function ENT:DrawBrowser()

		if !ValidPanel( self.Browser ) then return end
		
		self.Browser:UpdateHTMLTexture()

		local w, h = self.Browser:GetSize()

		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( self.Browser:GetHTMLMaterial() )
		surface.DrawTexturedRect( 0, 0, w, h )

	end

	function ENT:DrawPanel()

		local pos, ang = self:GetPosBrowser(), self:GetAngles()
		local up, right = self:GetUp(), self:GetRight()

		pos = pos + (up * self.Height * self.Scale) + (right * (self.Width/2) * self.Scale)

		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		cam.Start3D2D(pos,ang,self.Scale)
			self:DrawBrowser()
		cam.End3D2D()
		
		/*render.SetMaterial( Mat )
		local Vec1 = self.BasePosition
		local Vec2 = Vec1 + Vector(0,self.Width,0) * self.Scale
		local Vec3 = Vec1 + Vector(0,0,-self.Height) * self.Scale
		local Vec4 = Vec1 + Vector(0,self.Width,-self.Height) * self.Scale
		
		local Pos1, Pos2, Pos3, Pos4 = 
			self:LocalToWorld( Vec1 ),
			self:LocalToWorld( Vec2 ),
			self:LocalToWorld( Vec4 ),
			self:LocalToWorld( Vec3 )

		render.DrawQuad( Pos1, Pos2, Pos3, Pos4 )*/
		
		//render.SetMaterial( Laser )
		//render.DrawBeam( Pos1, Pos2, 5, 0, 0, Color( 255, 255, 255, 255 ) ) 
		//render.DrawBeam( Pos2, Pos3, 5, 0, 0, Color( 255, 255, 255, 255 ) ) 
		//render.DrawBeam( Pos3, Pos4, 5, 0, 0, Color( 255, 255, 255, 255 ) )
		//render.DrawBeam( Pos4, Pos1, 5, 0, 0, Color( 255, 255, 255, 255 ) ) 
		
	end

	function ENT:OnRemove()

		if ValidPanel( self.Browser ) then
			self.Browser:Remove()
		end
			
		if ValidPanel( self.HTMLFrame ) then
			self.HTMLFrame:Remove()
		end

	end

	function ENT:Think()
		
		//The client went away from the TV, turn it off
		//Nobody wants to hear nyan cat while being scared by the inner most thoughts of Foohy
		if self.On && LocalPlayer():GetPos():Distance( self:GetPos() ) > 300 then
			self:TurnOff()
		end

	end
	
	usermessage.Hook( "elevator_tvstatus", function( um )
		
		local ent = um:ReadEntity()
		
		if !IsValid( ent ) then return end

		local message = um:ReadChar()
		
		if message == UMSG_OFF then
			ent:TurnOff()
		elseif message == UMSG_ON then
			ent:TurnOn()
		elseif message == UMSG_CONTROL then
			ent:DisplayControls()
		end
		
	end )
	
	usermessage.Hook( "elevator_updatetv", function( um )
		
		local ent = um:ReadEntity()

		if !IsValid( ent ) then return end
		
		local vid = um:ReadString()
		local time = um:ReadShort()

		Msg( vid )
		
		if ( vid == "" ) then vid = nil end
		
		ent:UpdateTV( vid, time )
		
	end )
	
	usermessage.Hook( "elevator_tvvolume", function( um )
	
		local tv = LocalPlayer().ActiveTV
		if ( !IsValid( tv ) ) then return end

		if ( !LocalPlayer().TVVolume ) then
			LocalPlayer().TVVolume = 30
		end
		
		local bool = um:ReadBool()
		local volume = LocalPlayer().TVVolume
		if ( bool ) then // lower
			volume = volume - 5
		else // raise
			volume = volume + 5
		end

		volume = math.Clamp( volume, 0, 100 )
		LocalPlayer().TVVolume = volume

		// Update TV volume
		local html = tv.Browser
		if ValidPanel( html ) then
			html:RunJavascript( "setVolume(" .. volume .. ")" )
		end
		
	end )	

	concommand.Add( "elev_tvvolume", function( ply, cmd, args )

		// Get TV
		local tv = ply.ActiveTV
		if ( !IsValid( tv ) ) then return end

		// Get volume
		local volume = tonumber( args[1] )
		if ( !volume ) then return end
		volume = math.Clamp( volume, 0, 100 )
		
		// Store volume
		LocalPlayer().TVVolume = volume

		// Update TV volume
		local html = tv.Browser
		if ValidPanel( html ) then
			html:RunJavascript( "setVolume(" .. volume .. ")" )
		end

	end )
	
end

//=====================================================

if CLIENT then

	local PANEL = {}

	function PANEL:Init()
		self:SetPaintedManually( true )
		self:AddFunction( "gmt", "VideoID", function( id ) self:SelectedVideo( id ) end )
	end

	function PANEL:SetEntity( ent )
		self.Entity = ent
	end

	function PANEL:SelectedVideo( id )

		if IsValid( self.Entity ) && id != self.Entity.VideoID then

			// Update clients
			RunConsoleCommand( "elev_settv", id, self.Entity:EntIndex() )

			// Store vid
			self.Entity.VideoID = id

			// Update starter's TV
			self.Entity:UpdateTV( id, 0 )

		end

		// Close starter's TV
		if ( ValidPanel( self.Entity.HTMLFrame ) ) then
			self.Entity.HTMLFrame:Close()
		end

	end

	vgui.Register( "EntityHTML", PANEL, "DHTML" )

end // Client