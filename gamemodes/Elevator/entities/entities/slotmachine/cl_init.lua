include('shared.lua')
ENT.RenderGroup = RENDERGROUP_BOTH

Casino.SlotsLocalPlaying = nil
Casino.SlotsLocalBet = 10
Casino.SlotsMaxBet = 1000
Casino.SlotsSettingBet = false

Cursor2D = surface.GetTextureID( "cursor/cursor_default" )

surface.CreateFont( "ScoreboardText", {
	font = "Tahoma",
    size = 16,
    weight = 1000,
    antialias = true,
} )

// [DONE] Replace model buttons with 2D3D?
// [DONE] Setup clientside controls
// [DONE] Finish client/server interactions
// [DONE] Draw cursor dot on the controls
// Add combinations to the top scoreboard under "SASSASLOTS"
// Retexture everything

/*---------------------------------------------------------
	Basics
---------------------------------------------------------*/
function ENT:Initialize()

	self.SpinRotation = -180
	self.Spinners = { false, false, false }
	self.SelectedIcons = { getRand(), getRand(), getRand() }
	self:SendAnim( self:GetPitch(1), self:GetPitch(2), self:GetPitch(3) )
	
	//self.GameSound = CreateSound( self, Casino.SlotGameSound )
	//self.GameSound:Play()
	
end


function ENT:Draw()
	self:DrawModel()
end


function ENT:Think()

	if !LocalPlayer():InVehicle() then
		Casino.SlotsLocalPlaying = nil
	end

	self:Spin()
	
	self:NextThink(RealTime())

end

/*---------------------------------------------------------
	Slot Machine Related Functions
---------------------------------------------------------*/
function ENT:IsSpinning(spinner)
	return self.Spinners[spinner]
end


function ENT:GetPitch(spinner)
	return self.IconPitches[self.SelectedIcons[spinner]]
end


function ENT:SendAnim( spin1, spin2, spin3 )

	if spin1 then
		self:SetPoseParameter( "spinner1_pitch", spin1 )
	end
	
	if spin2 then
		self:SetPoseParameter( "spinner2_pitch", spin2 )
	end
	
	if spin3 then
		self:SetPoseParameter( "spinner3_pitch", spin3 )
	end

end


function ENT:Spin()
	
	// Hacky, but pose parameters don't go over a certain angle D:
	if self.SpinRotation >= 180 then self.SpinRotation = -179 end
	
	local speed = 20
	self.SpinRotation = self.SpinRotation + speed
	
	if self:IsSpinning(1) then
		self:SendAnim( self.SpinRotation )
	else
		self:SendAnim( self:GetPitch(1) )
	end
	
	if self:IsSpinning(2) then
		self:SendAnim( nil, self.SpinRotation )
	else
		self:SendAnim( nil, self:GetPitch(2) )
	end
	
	if self:IsSpinning(3) then
		self:SendAnim( nil, nil, self.SpinRotation )
	else
		self:SendAnim( nil, nil, self:GetPitch(3) )
	end
		
end


usermessage.Hook( "slotsPlaying", function ( um )

	local ent = ents.GetByIndex( um:ReadShort() )
	if IsValid( ent ) then 
		Casino.SlotsLocalPlaying = ent
		//RunConsoleCommand( "gmod_vehicle_viewmode", 0 ) // fix third person
	end
 
end )


usermessage.Hook( "slotsResult", function ( um )

	local self = ents.GetByIndex( um:ReadShort() )
	if !IsValid( self ) then return end

	local num1 = um:ReadShort()
	local num2 = um:ReadShort()
	local num3 = um:ReadShort()
	
	self.Spinners = { true, true, true }
	self.SelectedIcons = { num1, num2, num3 }
	//Msg("Results received\n")
	
	local SpinSnd = PlayEx
	
	local SpinSnd = CreateSound( self, Casino.SlotSpinSound )
	SpinSnd:PlayEx(0.3, 100)
	
	timer.Simple( Casino.SlotSpinTime[1], function()
		self.Spinners[1] = false
		self:EmitSound( Casino.SlotSelectSound, 100, 100 )
	end )
	
	timer.Simple( Casino.SlotSpinTime[2], function()
		self.Spinners[2] = false
		self:EmitSound( Casino.SlotSelectSound, 100, 100 )
	end )
	
	timer.Simple( Casino.SlotSpinTime[3], function()
		self.Spinners[3] = false
		self:EmitSound( Casino.SlotSelectSound, 100, 100 )
		SpinSnd:Stop()
	end )
 
end )

/*---------------------------------------------------------
	Console Commands
---------------------------------------------------------*/
concommand.Add( "slotm_setbet", function( ply, cmd, args )
	if !Casino.SlotsSettingBet then
		Casino.SlotsSettingBet = true
		Derma_StringRequest( "Slot Machine", "Set the amount of money you would like to bet. (10 - 1000)", Casino.SlotsLocalBet, 
						function( strTextOut )
							local amount = tonumber( strTextOut ) or Casino.SlotsLocalBet
							Casino.SlotsLocalBet = math.Clamp( math.Round(amount), 10, Casino.SlotsMaxBet )
							Casino.SlotsSettingBet = false
						end,
						function( strTextOut )
							Casino.SlotsSettingBet = false
						end,
						"Set Bet", "Cancel" )
	end
end )

/*---------------------------------------------------------
	3D2D Drawing
---------------------------------------------------------*/
function ENT:DrawTranslucent()

	self:DrawDisplay()

	if Casino.SlotsLocalPlaying != self then return end

	//self:DrawCombinations()
	self:DrawControls()

end


function ENT:DrawDisplay()

	local attachment = self:GetAttachment( self:LookupAttachment("display") )
	local pos, ang = attachment.Pos, attachment.Ang
	local scale = 0.1
	
	ang:RotateAroundAxis( ang:Up(), 90 )
	ang:RotateAroundAxis( ang:Forward(), 90 )

	cam.Start3D2D( pos, ang, scale )

		//draw.RoundedBox(8, -32, -16, 64, 32, Color( 200,200,255,75) )
		draw.SimpleText( "Jackpot: " .. self:GetJackpot(), "ScoreboardText", 10, 7, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		if Casino.SlotsLocalPlaying == self then
			draw.SimpleText( "Bet Amount: " .. Casino.SlotsLocalBet, "ScoreboardText", 10, 80, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )
		end
		
	cam.End3D2D()

end


function ENT:DrawCombinations()

	local attachment = self:GetAttachment( self:LookupAttachment("winnings") )
	local pos, ang = attachment.Pos, attachment.Ang

	ang:RotateAroundAxis( ang:Up(), 90 )
	ang:RotateAroundAxis( ang:Forward(), 90 )
	
	local Scale = 0.25

	cam.Start3D2D( pos, ang, Scale )	
	
		//draw.RoundedBox(8, -32, -16, 64, 32, Color( 200,200,255,75) )
		draw.SimpleText( "Winnings", "ScoreboardText", 45, 25, Color(255,255,255,255), 1, 1 )
		
	cam.End3D2D()

end

/*---------------------------------------------------------
	3D2D Buttons
---------------------------------------------------------*/
ENT.Controls = {

	[1] = {
		text = "BET",
		x = -40,
		col = Color(255,0,0,255),
		bcol = Color(128,0,0,255),
		selected = false,
		cmd = "slotm_setbet"
	},
	
	[2] = {
		text = "SPIN",
		x = 40,
		col = Color(0,0,255,255),
		bcol = Color(0,0,160,255),
		selected = false,
		cmd = "slotm_spin"
	},

}

surface.CreateFont( "Buttons", {
	font = "coolvetica",
	size = 22,
	weight = 200,
	antialias = true
})

local ButtonTexture = surface.GetTextureID( "models/gmod_tower/casino/button" )
function ENT:DrawControls()

	local attachment = self:GetAttachment( self:LookupAttachment("controls") )
	local pos, ang = attachment.Pos, attachment.Ang
	local scale = 0.1
	
	ang:RotateAroundAxis( ang:Up(), 90 )
	ang:RotateAroundAxis( ang:Forward(), 90 )
	
	local function IsMouseOver( x, y, w, h )
		mx, my = self:GetCursorPos( pos, ang, scale )
		
		if mx && my then
			return ( mx >= x && mx <= (x+w) ) && (my >= y && my <= (y+h))
		else
			return false
		end
	end

	cam.Start3D2D( pos, ang, scale )
		
		// Draw buttons
		for _, btn in ipairs( self.Controls ) do
			local x, col, text = btn.x, btn.col, btn.text
			local y, w, h = 2, 48, 30
		
			if IsMouseOver(x - (w/2), y - (h/2), w, h) then
				btn.selected = true
				btn.col = Color(col.r,col.g,col.b,120)
			else
				btn.selected = false
				btn.col = Color(col.r,col.g,col.b,40)
			end
		
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetTexture( ButtonTexture )
			surface.DrawTexturedRect( x - (w/2), y - (h/2), w, h )
		
			draw.RoundedBox( 0, x - (w/2), y - (h/2), w, h, btn.col ) // Color button texture
		
			draw.SimpleText(text, "Buttons", x, y + 1, btn.bcol, 1, 1)
		end
		
		// Draw small cursor
		local mx, my = self:GetCursorPos( pos, ang, scale )
		if IsMouseOver( -190/2, -35/2, 190, 35 ) then
			self:DrawCursor( mx, my )
			/*surface.SetDrawColor(255, 0, 0, 255)
			surface.DrawRect( mx - 2, my - 2, 4, 4 )*/
		end
		
	cam.End3D2D()

end

hook.Add( "KeyPress", "KeyPressedHook", function( ply, key )
	if Casino.SlotsLocalPlaying && key == IN_ATTACK then
		for _, btn in ipairs( Casino.SlotsLocalPlaying.Controls ) do
			if btn.selected then
				//Msg( "[" .. Casino.SlotsLocalPlaying:EntIndex() .. "] " .. LocalPlayer():Name() .. " has pressed the " .. btn.text .. " button.\n" )
				RunConsoleCommand( btn.cmd, Casino.SlotsLocalBet )
			end
		end
	end
end )

/*---------------------------------------------------------
	Mind Blowing 3D2D Cursor Math -- Thanks BlackOps!
---------------------------------------------------------*/
ENT.Width = 190 / 2
ENT.Height = 35 / 2

local function RayQuadIntersect(vOrigin, vDirection, vPlane, vX, vY)
	local vp = vDirection:Cross(vY)

	local d = vX:DotProduct(vp)

	if (d <= 0.0) then return end

	local vt = vOrigin - vPlane
	local u = vt:DotProduct(vp)
	if (u < 0.0 or u > d) then return end

	local v = vDirection:DotProduct(vt:Cross(vX))
	if (v < 0.0 or v > d) then return end

	return Vector(u / d, v / d, 0)
end

function ENT:MouseRayInteresct( pos, ang )
	local plane = pos + ( ang:Forward() * ( self.Width / 2 ) ) + ( ang:Right() * ( self.Height / -2 ) )

	local x = ( ang:Forward() * -( self.Width ) )
	local y = ( ang:Right() * ( self.Height ) )

	return RayQuadIntersect( EyePos(), LocalPlayer():GetAimVector(), plane, x, y )
end

function ENT:GetCursorPos( pos, ang, scale )

	local uv = self:MouseRayInteresct( pos, ang )
	
	if uv then
		local x,y = (( 0.5 - uv.x ) * self.Width), (( uv.y - 0.5 ) * self.Height)
		return (x / scale), (y / scale)
	end
end


function ENT:DrawCursor( cur_x, cur_y )

	local cursorSize = 32

	surface.SetTexture( Cursor2D )

	if input.IsMouseDown( MOUSE_LEFT ) then
		cursorSize = 28
		surface.SetDrawColor( 255, 150, 150, 255 )
	else
		surface.SetDrawColor( 255, 255, 255, 255 )
	end

	local offset = cursorSize / 2
	surface.DrawTexturedRect( cur_x - offset + 15, cur_y - offset + 15, cursorSize, cursorSize )

end