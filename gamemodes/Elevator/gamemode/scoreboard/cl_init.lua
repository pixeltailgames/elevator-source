surface.CreateFont( "LabelFont", { font = "Open Sans Condensed Light", size = 22, weight = 200 } )

SCOREBOARD = {}
SCOREBOARD.CurrentHeight = 256

function SCOREBOARD:Init()

	self:SetZPos( 2 )
	self:SetSize( 512, 256 )

	self.PlayerList = vgui.Create( "ScoreboardPlayerList", self )

end

function SCOREBOARD:Paint( w, h )

	//Render the background
	surface.SetDrawColor( 26, 30, 38, 220 )
	surface.DrawRect( 0, 0, self.PlayerList:GetWide() + 1, self:GetTall() )

end

function SCOREBOARD:Think() end

function SCOREBOARD:PerformLayout()

	self.PlayerList:SetWide( 512 )
	
	local curTall = math.Clamp( self.PlayerList:GetTall(), 256, ScrH() * .8 )
	self.CurrentHeight = math.Approach( self.CurrentHeight, curTall, FrameTime() * 400 )

	self:SetTall( self.CurrentHeight )
	self:Center()

end

vgui.Register( "Scoreboard", SCOREBOARD )


if ValidPanel( Gui ) then 
	Gui:Remove()
	Gui = nil
end

function GM:ScoreboardShow()

	if !ValidPanel( Gui ) then
		Gui = vgui.Create( "Scoreboard" )
	end

	Gui:InvalidateLayout()
	Gui:SetVisible( true )

end

function GM:ScoreboardHide()

	if ValidPanel( Gui ) then
	    Gui:SetVisible( false )
	    GAMEMODE:HideMouse()
	    CloseDermaMenus()
	end

end

GM.MouseEnabled = false

function GM:ShowMouse()
	if self.MouseEnabled then return end
	gui.EnableScreenClicker( true )
	RestoreCursorPosition()
	self.MouseEnabled = true
end

function GM:HideMouse()
	if !self.MouseEnabled then return end
	RememberCursorPosition()
	gui.EnableScreenClicker( false )
	self.MouseEnabled = false
end

function GM:MenuShow()

	if !IsValid(LocalPlayer()) then return end

	-- GAMEMODE:ShowMouse()

end
concommand.Add("+menu", GM.MenuShow ) 
concommand.Add("+menu_context", GM.MenuShow )

function GM:MenuHide()

	-- GAMEMODE:HideMouse()

end
concommand.Add("-menu", GM.MenuHide ) 
concommand.Add("-menu_context", GM.MenuHide )

-- Scroll playerlist
hook.Add( "PlayerBindPress", "PlayerListScroll", function( ply, bind, pressed )

	if !ValidPanel(Gui) then return end

	if bind == "invnext" then
		Gui.PlayerList.PlayerList.VBar:AddScroll(2)
	elseif bind == "invprev" then
		Gui.PlayerList.PlayerList.VBar:AddScroll(-2)
	end

end )