ENT.Type   				= "anim"
ENT.Base                = "base_anim"
ENT.PrintName           = "Slot Machine Light"
ENT.RenderGroup         = RENDERGROUP_BOTH
ENT.Model				= Model( "models/props/de_nuke/emergency_lighta.mdl" )

if SERVER then

	AddCSLuaFile( "shared.lua" )

	ENT.Light 			= nil
	ENT.LightMat 		= "effects/flashlight001"

	function ENT:Initialize()

		self:SetModel( self.Model )
		self:DrawShadow( false )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
		self:SetMoveType( MOVETYPE_NONE )

		self.IsLit = false
	end

	function ENT:Think()

		if self.IsLit then

			if self.LightTime && self.LightTime < CurTime() then
				self:RemoveLight()
				return
			end

			self.Light:SetLocalAngles( Angle( 0, 1, 0 ) )

		end

	end

	function ENT:CreateLight( jackpot )

		self.IsLit = true
		self.LightTime = CurTime() + 1

		if jackpot then
			self.LightTime = CurTime() + 25
		end

		self.Light = ents.Create( "env_projectedtexture" )
			self.Light:SetParent( self )
			self.Light:SetLocalPos( Vector( 0, 0, 0 ) )
			self.Light:SetLocalAngles( Angle( 80, 80, 80 ) )
			
			self.Light:SetKeyValue( "enableshadows", 1 )
			self.Light:SetKeyValue( "farz", 1024 )
			self.Light:SetKeyValue( "nearz", 60 )
			self.Light:SetKeyValue( "lightfov", 80 )
			self.Light:SetKeyValue( "lightcolor", "255 0 0" )
		self.Light:Spawn()
		self.Light:Input( "SpotlightTexture", NULL, NULL, self.LightMat )

		umsg.Start( "SlotLight" )
			umsg.Entity( self )
			umsg.Bool( true )
		umsg.End()

	end

	function ENT:RemoveLight()

		self.IsLit = false

		if self.Light && IsValid( self.Light ) then
			
			self.Light:Remove()
			self.Light = nil

		end

		umsg.Start( "SlotLight" )
			umsg.Entity( self )
			umsg.Bool( false )
		umsg.End()

	end
	
	function ENT:OnRemove()
		self:RemoveLight()
	end

else // CLIENT

	local matLight          = Material( "sprites/light_ignorez" )
	local matBeam           = Material( "effects/lamp_beam" )

	function ENT:Initialize()
	
		self.IsLit = false
		self.Lamp = nil
		self.PixVis = util.GetPixelVisibleHandle()
		
		self.Spin = 0
		self.GlowTime = 0
		self.Distance = 40

	end

	function ENT:Draw()

		if self.IsLit then
			self.Spin = self.Spin + ( FrameTime() * 250 )
			self:SetLocalAngles( Angle( 0, self.Spin, 0 ) )
		end

		self:SetModelScale( .5, 0 )
	
		self:DrawModel()

	end
	
	function ENT:Think()

		if !self.IsLit then return end
	
		local dlight = DynamicLight( self:EntIndex() )
		if dlight then
			dlight.Pos = self:GetPos() + Vector( 0, 0, 5 )
			dlight.r = 255
			dlight.g = 0
			dlight.b = 0
			dlight.Brightness = .8
			dlight.Size = 256
			dlight.Decay =  80 * 5
			dlight.DieTime = CurTime() + .2
		end

	end

	function ENT:DrawTranslucent()

		if !self.IsLit then return end
		
		//Lamp "glow"
		local LightNrm = self:GetAngles():Up()
		local ViewNormal = self:GetPos() - EyePos()
		local Distance = ViewNormal:Length()
		ViewNormal:GetNormal()

		local ViewDot = ViewNormal:Dot( LightNrm )
		local Col = Color( 255, 0, 0, 25 )
		local LightPos = self:GetPos() + Vector( 0, 0, 5 ) + LightNrm * -6

		if ( ViewDot >= 0 ) then
		   
			render.SetMaterial( matLight )
			local Visibile  = util.PixelVisible( LightPos, 16, self.PixVis )       
				   
			if (!Visibile) then return end
				   
			local Size = math.Clamp( Distance * Visibile * ViewDot * 2, 32, 64 )
					
			Distance = math.Clamp( Distance, 32, 800 )
			local Alpha = math.Clamp( (1000 - Distance) * Visibile * ViewDot, 0, 100 )
				   
			render.DrawSprite( LightPos, Size, Size, Col, Visibile * ViewDot )
			render.DrawSprite( LightPos, Size*0.4, Size*0.4, Color(255, 255, 255, Alpha), Visibile * ViewDot )	
		  
		end

	end

	usermessage.Hook( "SlotLight", function( um )

		local ent = um:ReadEntity()
		ent.IsLit = um:ReadBool()

	end )

end