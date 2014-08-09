ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName	   	= "Blender"

ENT.Spawnable		= true
ENT.AdminSpawnable	= true
ENT.Model			= Model( "models/sunabouzu/fancy_blender.mdl" )

ENT.BlendDelay		= 4 // how long should we blend for?
ENT.BlendTime		= nil

ENT.SpitAnimDelay	= 1 // delay to for animation spit
ENT.SpitDelay		= 1.43 // delay actually spit out the drink

ENT.PackDelayTime	= .5 // delay between ingredients getting packed
ENT.PackDelay		= nil

ENT.Ingredients 	= {}
ENT.Drink			= nil // drink to be produced
ENT.IsBlending		= false

//Precache the particle system
PrecacheParticleSystem( "juice_red" )
PrecacheParticleSystem( "juice_blue" )
PrecacheParticleSystem( "juice_green" )
PrecacheParticleSystem( "juice_orange" )

if SERVER then
	
	AddCSLuaFile( "shared.lua" )

	local DrinkCombos = {
		{ 
			Name = "Morning Fruit Shake", 
			Ingredient1 = APPLE, 
			Ingredient2 = STRAWBERRY,
			Color = Color( 159, 209, 31 ),
		},
		{
			Name = "Mid-Afternoon Fruit Shake",
			Ingredient1 = WATERMELON,
			Ingredient2 = STRAWBERRY,
			Color = Color( 209, 73, 31 ),
			Time = 20,
			Start = function( ply )
				PostEvent( ply, "pcolored_on" )
			end,
			End = function( ply )
				PostEvent( ply, "pcolored_off" )
			end			
		},
		{ 
			Name = "Midnight Fruit Shake", 
			Ingredient1 = APPLE,
			Ingredient2 = WATERMELON,
			Color = Color( 124, 179, 16 ),
		},
		{ 
			Name = "Midnight Tang Fruit Shake", 
			Ingredient1 = ORANGE,
			Ingredient2 = WATERMELON,
			Color = Color( 209, 73, 31 ),
		},
		{ 
			Name = "Man's Orange Juice",
			Ingredient1 = GLASS,
			Ingredient2 = ORANGE,
			Color = Color( 122, 78, 20 ),
			Time = 3,
			Start = function( ply )
				PostEvent( ply, "pdamage" )
			end
		},
		{ 
			Name = "Deathwish", 
			Ingredient1 = PLASTIC,
			Ingredient2 = GLASS,
			Color = Color( 30, 30, 30 ),
			Time = 3,
			Start = function( ply )
				PostEvent( ply, "pdeath" )
			end,
			End = function( ply ) ply:Kill() end,
		},
		{ 
			Name = "Strawberry Banana Shake Boost", 
			Ingredient1 = STRAWBERRY,
			Ingredient2 = BANANA,
			Color = Color( 224, 188, 27 ),
			Time = 20,
			Start = function( ply )
				GAMEMODE:SetPlayerSpeed( ply, 175, 175 )
			end,
			End = function( ply )
				GAMEMODE:ResetSpeed( ply )
			end,
		},
		{
			Name = "One Too Many",
			Ingredient1 = GLASS,
			Ingredient2 = GLASS,
			Color = Color( 98, 56, 38 ),
			Time = 30,
			Start = function( ply )
				umsg.Start( "SetDrunk", ply )
					umsg.Char( 80 )
				umsg.End()
			end,
			End = function( ply )
				umsg.Start( "SetDrunk", ply )
					umsg.Char( 0 )
				umsg.End()
			end
		},
		{
			Name = "Slow Down",
			Ingredient1 = PLASTIC,
			Ingredient2 = WATERMELON,
			Color = Color( 155, 155, 155 ),
			Time = 20,
			Start = function( ply )
				PostEvent( ply, "ptime_on" )
				GAMEMODE:SetPlayerSpeed( ply, 50, 50 )
				ply:SetDSP( 31 )
			end,
			End = function( ply )
				PostEvent( ply, "ptime_off" )
				GAMEMODE:ResetSpeed( ply )
				ply:SetDSP( 0 )
			end			
		},
		{
			Name = "Bone Meal",
			Ingredient1 = PLASTIC,
			Ingredient2 = BONE,
			Color = Color( 255, 255, 255 ),
			Time = 20,
			Start = function( ply )
				PostEvent( ply, "pbone_on" )
			end,
			End = function( ply )
				PostEvent( ply, "pbone_off" )
			end			
		},
	}
	
	function ENT:Initialize()

		self:SetModel( self.Model )
		self:SetAngles( Angle( 0, 180, 0 ) )
		
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_NONE )
        self:SetSolid( SOLID_VPHYSICS )
		
		self:SetUseType( SIMPLE_USE ) // Or else it'll go WOBLBLBLBLBLBLBLBL
		
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:EnableMotion( false )
		end

	end

	function ENT:Use( ply )
        if !IsValid( ply ) || !ply:IsPlayer() then return end
		if ( self.IsBlending ) then return end

		if #self.Ingredients < 2 then
			//Play some sound saying HEY GET MORE INGRIDIENTS YOU DOLT
			//Msg("Not enough ingredients!\n")
			return
		end

		self:StartBlend()

	end
	
	function ENT:StartBlend()

		//Msg("STARTING BLENDER\n")

		self.IsBlending = true
		self.BlendTime = CurTime() + self.BlendDelay

		self.Drink = GetDrink( self.Ingredients[1], self.Ingredients[2] )
		
		self:EmitSound( "elevator/effects/drink_blend.wav", 80, 100 )

		umsg.Start( "SetBlender" )
			umsg.Entity( self )
			umsg.Bool( true )
		umsg.End()
	
	end
	
	function ENT:EndBlend()

		self.BlendTime = nil
		self:StartSpitDrink()
	
	end

	function ENT:Think()

		if !self.IsBlending then return end

		if ( self.BlendTime && self.BlendTime < CurTime() ) then
			self:EndBlend()
		end

	end
	
	function ENT:Touch( hitEnt )

		if self.PackDelay && self.PackDelay > CurTime() then return end //Slow down

		if !GAMEMODE:ValidIngredient( hitEnt ) || #self.Ingredients > 1 then return end

		local ingredient = table.KeyFromValue( GAMEMODE.ValidIngredients, hitEnt:GetModel() )
		if ( !ingredient || ingredient == -1 ) then return end
		
		//Msg( "Valid ingredient: "..tostring( hitEnt:GetModel() ).."\n" )
		self:AddIngredient( hitEnt, ingredient )
		
		umsg.Start( "BlenderInsert" )
			umsg.Entity( self )
			umsg.Char( self.Ingredients[1] or -1 )
			umsg.Char( self.Ingredients[2] or -1 )
		umsg.End()

		if ( #self.Ingredients > 1 ) then
			umsg.Start( "BlenderSprite" )
				umsg.Entity( self )
				umsg.Bool( true )
				umsg.Char( 64 )
				umsg.Char( 255 )
				umsg.Char( 64 )
			umsg.End()
		end

		self.PackDelay = CurTime() + 0.5

	end
	
	function ENT:AddIngredient( ent, id )
	
		table.insert( self.Ingredients, id )
		ent:Remove()

	end
	
	function GetDrink( ingredient1, ingredient2 )

		for _, drink in pairs( DrinkCombos ) do

			local ing1 = drink.Ingredient1
			local ing2 = drink.Ingredient2
			
			if ( ( ing1 == ingredient1 && ing2 == ingredient2 ) || ( ing1 == ingredient2 && ing2 == ingredient1 ) ) then
				return drink
			end
		end

		return nil

	end
	
	function ENT:StartSpitDrink()

		// Send animation
		timer.Simple( self.SpitAnimDelay, function()

			if ( !IsValid( self ) ) then return end

			if ( self.Drink ) then
				umsg.Start( "SpitBlender" )
					umsg.Entity( self )
				umsg.End()
			end

		end )

		// Actually spit out 
		timer.Simple( self.SpitDelay, function()
		
			if ( !IsValid( self ) ) then return end

			self:EndSpitDrink()
			self:ResetVars()

		end )

	end
	
	function ENT:EndSpitDrink()
	
		umsg.Start( "BlenderSprite" )
			umsg.Entity( self )
			umsg.Bool( true )
			umsg.Char( 255 )
			umsg.Char( 0 )
			umsg.Char( 0 )
		umsg.End()
		
		umsg.Start( "BlenderInsert" )
			umsg.Entity( self )
			umsg.Char( -1 )
			umsg.Char( -1 )
		umsg.End()

		if ( self.Drink ) then
			
			print( "Spitting out drink: " .. tostring( self.Drink.Name ) )
	
			self:EmitSound( "elevator/effects/drink_spit.wav", 80, 100 )
			
			local ent = ents.Create( "elevator_drink" )
				local attID = self:LookupAttachment( "juice.point" )
				local attPos = self:GetAttachment( attID )
				ent:SetPos( attPos.Pos )
			ent:Spawn()

			ent:SetDrink( self.Drink )

			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:ApplyForceCenter( Vector( math.random( -40, 40 ), math.random( -40, 40 ), 140 ) )
			end
			
		end

	end
	
	function ENT:ResetVars()

		self.BlendTime = nil

		table.Empty( self.Ingredients )
		self.Ingredients = {}

		self.Drink = nil
		self.IsBlending = false

		umsg.Start( "SetBlender" )
			umsg.Entity( self )
			umsg.Bool( false )
		umsg.End()

	end

else //CLIENT

	ENT.RenderGroup 	= RENDERGROUP_TRANSLUCENT
	ENT.AttachSpit		= "juice.point"
	ENT.AttachLight		= "light.point"
	ENT.AttachFruit		= "fruit.point"
	ENT.SpriteMat		= Material( "effects/softglow" )
	ENT.DrawSprite		= true
	ENT.Color			= Color( 255, 0, 0 )
	
	ENT.Particles		= {
							"juice_red",
							"juice_blue",
							"juice_green",
							"juice_orange",
	}
	
	ENT.Model1			= nil
	ENT.Model2			= nil

	function ENT:Draw()

		self:FrameAdvance( FrameTime() )
		self:DrawModel()
		
		if ( self:GetSequence() == self:LookupSequence( "spit" ) && self:GetCycle() > 25 ) then //Loop prevention to keep it from spitting
			self:SetSequence( self:LookupSequence( "idle" ) )
		end
		
		//Make the fruit shake with the blender	
		if IsValid( self.Model1 ) && IsValid( self.Model2 ) then
			local attID = self:LookupAttachment( self.AttachFruit )
			local attPos = self:GetAttachment( attID )
			
			self.Model1:SetPos( attPos.Pos )
			self.Model1:SetAngles( attPos.Ang - Angle( 0, 180, 90) ) //Offset from the blender angles
			
			local normal = attPos.Ang:Right()
			self.Model2:SetPos( attPos.Pos - (normal * 5 ) ) //Move the second prop upwards from the origin
			self.Model2:SetAngles( attPos.Ang - Angle( 0, 180, 90) )
		end

		if ( self.DrawSprite ) then
			render.SetMaterial( self.SpriteMat )
			
			local attID = self:LookupAttachment( self.AttachLight )
			local attPos = self:GetAttachment( attID )

			render.DrawSprite( attPos.Pos + ( self:GetForward() ), 5, 5, self.Color )
		end

	end

	function ENT:Initialize()

		local sequence = self:LookupSequence( "idle" )
		self:SetSequence( sequence )
		self:SetPlaybackRate( 1.0 )

	end
	
	usermessage.Hook( "SetBlender", function( um )
	
		local blender = um:ReadEntity()
		if ( !IsValid( blender ) ) then return end

		local bool = um:ReadBool()
		blender.IsBlending = bool
		
		if ( bool ) then

			local sequence = blender:LookupSequence( "jive" )
			blender:ResetSequence( sequence )

			blender.DrawSprite = true
			blender.Color = Color( 0, 255, 0 )

			local attID = blender:LookupAttachment( blender.AttachSpit )
			local attPos = blender:GetAttachment( attID )
			ParticleEffect( blender.Particles[ math.random( 1, #blender.Particles ) ], attPos.Pos, attPos.Ang + Angle( 0, 0, -90 ), blender )
			
		else
		
			local sequence = blender:LookupSequence("idle")
			blender:SetSequence( sequence )

			blender.DrawSprite = true
			blender.Color = Color( 255, 0, 0 )
			blender:StopParticles()

		end

	end )

	usermessage.Hook( "SpitBlender", function( um )

		local blender = um:ReadEntity()
		if ( !IsValid( blender ) ) then return end
		
		local sequence = blender:LookupSequence( "spit" )
		blender:ResetSequence( sequence )

		blender.DrawSprite = true
		blender.Color = Color( 255, 255, 0 )
		
		blender:StopParticles()

	end )
	
	usermessage.Hook( "BlenderSprite", function( um )

		local blender = um:ReadEntity()
		if ( !IsValid( blender ) ) then return end

		blender.DrawSprite = um:ReadBool()
		if ( !blender.DrawSprite ) then return end

		local r = um:ReadChar()
		local g = um:ReadChar()
		local b = um:ReadChar()
		
		blender.Color = Color( r, g, b )
	
	end )

	usermessage.Hook( "BlenderInsert", function( um )

		local blender = um:ReadEntity()
		if ( !IsValid( blender ) ) then return end

		local mdl1 = um:ReadChar() or -1
		local mdl2 = um:ReadChar() or -1
		
		local attID = blender:LookupAttachment( blender.AttachFruit )
		local attPos = blender:GetAttachment( attID )

		if ( mdl1 != -1 ) then		
			if ( IsValid( blender.Model1 ) ) then
				blender.Model1:Remove()
			end
			
			blender.Model1 = ClientsideModel( GAMEMODE.ValidIngredients[ mdl1 ] )
			blender.Model1:SetModelScale(0.75, 0)
			blender.Model1:SetPos( attPos.Pos )
		else
			if ( IsValid( blender.Model1 ) ) then
				blender.Model1:Remove()
			end
		end

		if ( mdl2 != -1 ) then		
			if ( IsValid( blender.Model2 ) ) then
				blender.Model2:Remove()
			end

			blender.Model2 = ClientsideModel( GAMEMODE.ValidIngredients[ mdl2 ] )
			blender.Model2:SetModelScale(0.75, 0)
			blender.Model2:SetPos( attPos.Pos + Vector( 0, 0, 5 ) )
		else		
			if ( IsValid( blender.Model2 ) ) then
				blender.Model2:Remove()
			end
		end
		
	end )
	
	function ENT:Think() end
	function ENT:OnRemove() end

	usermessage.Hook( "SetDrunk", function( um )
	
		LocalPlayer().BAL = um:ReadChar()
	
	end )

	// Blood alcohol level
	local BAL = 0

	hook.Add( "CalcView", "DrunkCalc", function( ply, origin, angle, fov )

		if !ply.BAL then return end

		if ply.BAL < BAL then
			BAL = math.Approach( BAL, ply.BAL, -0.2 )
		else
			BAL = math.Approach( BAL, ply.BAL, 0.1 )
		end

		if ply.BAL <= 0 then return end

		local multiplier = ( 20 / 100 ) * BAL;
		angle.pitch = angle.pitch + math.sin( CurTime() ) * multiplier;
		angle.roll = angle.roll + math.cos( CurTime() ) * multiplier;

	end )

	hook.Add( "RenderScreenspaceEffects", "DrunkEffect", function()

		local lp = LocalPlayer()
		if !IsValid( lp ) || BAL <= 0 then return end
		
		local alpha = ( ( 1 / 100 ) * BAL );
		if ( alpha > 0 ) then
		
			alpha = math.Clamp( 1 - alpha, 0.04, 0.99 );
			
			DrawMotionBlur( alpha, 0.9, 0.0 );
			
		end

		local sharp = ( ( 0.75 / 100 ) * BAL );
		if ( sharp > 0 ) then
			DrawSharpen( sharp, 0.5 );
		end
		
		local frac = math.min( BAL / 60, 1 );
		
		local rg = ( ( ( 0.2 / 100 ) * BAL ) + 0.1 ) * frac;

		local tab = {};
		tab[ "$pp_colour_addr" ] 		= rg;
		tab[ "$pp_colour_addg" ] 		= rg;
		tab[ "$pp_colour_addb" ] 		= 0;
		tab[ "$pp_colour_brightness" ] 	= -( ( 0.05 / 100 ) * BAL );
		tab[ "$pp_colour_contrast" ] 	= 1 - ( ( 0.5 / 100 ) * BAL );
		tab[ "$pp_colour_colour" ] 		= 1;
		tab[ "$pp_colour_mulr" ] 		= 0;
		tab[ "$pp_colour_mulg" ] 		= 0;
		tab[ "$pp_colour_mulb" ] 		= 0;
		
		DrawColorModify( tab );

	end )

	hook.Add( "CreateMove", "DrunkMove", function( ucmd )

		local ply = LocalPlayer()
		if !IsValid( ply ) || BAL <= 0 then return end

		local sidemove = math.sin( CurTime() ) * ( ( 150 / 100 ) * ply.BAL )
		ucmd:SetSideMove( ucmd:GetSideMove() + sidemove )

	end )

end