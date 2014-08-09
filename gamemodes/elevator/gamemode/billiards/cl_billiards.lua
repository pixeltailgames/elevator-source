------------------------------------------------------------
-- MBilliards by Athos Arantes Pereira
-- Contact: athosarantes@hotmail.com
------------------------------------------------------------
language.Add("billiard_table", "Billiard Table")
language.Add("billiard_cue", "Billiard Cue")
language.Add("billiard_ball", " Billiard Ball")

b_MouseSensitivity = CreateClientConVar("billiard_cl_mouse_sensitivity", "2", true, true)
b_InvCueMouseX = CreateClientConVar("billiard_cl_cue_invmouse_h", "0", true, true)
b_InvCueMouseY = CreateClientConVar("billiard_cl_cue_invmouse_v", "0", true, true)
b_InvMouseX = CreateClientConVar("billiard_cl_invmouse_h", "0", true, false)
b_InvMouseY = CreateClientConVar("billiard_cl_invmouse_v", "0", true, false)

BILLIARD_GAMETYPE_8BALL = 0
BILLIARD_GAMETYPE_9BALL = 1
BILLIARD_GAMETYPE_SNOOKER = 2
BILLIARD_GAMETYPE_ROTATION = 3
BILLIARD_GAMETYPE_CARAMBOL = 4

RequestedPlayers = {}
PocketedBalls_tmp = {}
PocketedBalls = {}

b_GameType = 0
b_SpecEnt = nil
b_SpecBaseEnt = nil
b_BilliardTime = nil
b_LastAngles = nil
b_FPerson = false
b_RunTime = true
b_CScore = nil
b_OScore = nil
b_ShotForce = 150
b_Zoom = 30

constObjective = ""
opponentName = nil
b_FoulReason = nil
b_Objective = ""
b_scrTitle = nil
b_scrText = nil
b_BarInfo = nil

b_keyf7_pressed = nil

b_requests_panel = nil
b_client_panel = nil

billiard_mainGUI_tex = surface.GetTextureID("vgui/panel/billiard_gui")
billiard_mainSGUI_tex = surface.GetTextureID("vgui/panel/billiard_sgui")
billiard_mainCRGUI_tex = surface.GetTextureID("vgui/panel/billiard_crgui")
billiard_subGUI_tex = surface.GetTextureID("vgui/panel/billiard_subgui")
billiard_needle_tex = surface.GetTextureID("vgui/panel/needle")
billiard_meter_tex = surface.GetTextureID("vgui/panel/meter")
billiard_ball_tex = {}
for i = 1, 15 do
	billiard_ball_tex[i] = surface.GetTextureID(string.format("vgui/panel/ball%02d", i))
end

surface.CreateFont( "HUDPoolText", {
	font = "default",
	size = 16,
	weight = 700,
	antialias = true
})

--[[ concommand.Add("incbzoom", function(ply, cmd, args)
	if(b_FPerson) then b_Zoom = math.Clamp(b_Zoom + 1, 15, 40)
	else b_ShotForce = math.Clamp(b_ShotForce + 5, 1, 400) end
end)

concommand.Add("decbzoom", function(ply, cmd, args)
	if(b_FPerson) then b_Zoom = math.Clamp(b_Zoom - 1, 15, 40)
	else b_ShotForce = math.Clamp(b_ShotForce - 5, 1, 400) end
end) ]]

hook.Add("Think", "CBilliardThink", function()

	if(!b_FPerson && LocalPlayer():KeyDown(IN_ATTACK) && !LocalPlayer():KeyDown(IN_SPEED)) then
		RunConsoleCommand("billiard_strike", b_ShotForce)
	end
	if(input.IsKeyDown(KEY_F7) && !b_keyf7_pressed) then
		b_keyf7_pressed = true
		guiBilliardClientConfig()
	end
	
	// FUCKING AWFUL ALPHA FIX SO FAGGOTS DONT GET IN THE WAY OF THE GOD DAMN FUCKING CAMERA THOSE TWATS xD
	if ( LocalPlayer().IsPlayingBilliards ) then

		if ( !LocalPlayer().BilliardsAlphaApplied ) then

			for _, ply in pairs( player.GetAll() ) do
				ply:SetColor( 255, 255, 255, 50 )
			end
			LocalPlayer().BilliardsAlphaApplied = true
		end
		
		--[[ if ( LocalPlayer():KeyDown( IN_JUMP ) ) then
			RunConsoleCommand( "billiard_strike_normal" )
		end ]]
		
	else

		if ( LocalPlayer().BilliardsAlphaApplied ) then
			for _, ply in pairs( player.GetAll() ) do
				ply:SetColor( 255, 255, 255, 255 )
			end
			LocalPlayer().BilliardsAlphaApplied = false
		end

	end
end)


hook.Add("PlayerBindPress", "BilliardsAdjustPower", function( ply, bind, pressed )

	if ( bind == "invnext" ) then
		b_ShotForce = math.Clamp( b_ShotForce - 5, 10, 400 )
	elseif ( bind == "invprev" ) then
		b_ShotForce = math.Clamp( b_ShotForce + 5, 10, 400 )
	end

end )

function hook.Exist(name)
	for i,t in pairs(hook.GetTable()) do
		for k,v in pairs(t) do
			if(string.lower(k) == string.lower(name)) then return true end
		end
	end
	return false
end

function hook.RemoveAll(name)
	local count = 0
	for i,t in pairs(hook.GetTable()) do
		for k,v in pairs(t) do
			if(k != name) then continue end
			hook.Remove(i, k)
			count = count + 1
		end
	end
	return count
end

-- I didn't want to use textures to do this effect, so I made this nice gradient function =P
-- Thanks to all people at FacePunch forums that helped me to optimize it!
local g_grds, g_wgrd, g_sz
function draw.GradientBox(x, y, w, h, al, ...)
	g_grds = {...}
	al = math.Clamp(math.floor(al), 0, 1)
	local n
	if(al == 1) then
		n = w
		w, h = h, n
	end
	g_wgrd = w / (#g_grds - 1)
	for i = 1, w do
		for c = 1, #g_grds do
			n = c
			if(i <= g_wgrd * c) then break end
		end
		g_sz = i - (g_wgrd * (n - 1))
		surface.SetDrawColor(
			Lerp(g_sz/g_wgrd, g_grds[n].r, g_grds[n + 1].r),
			Lerp(g_sz/g_wgrd, g_grds[n].g, g_grds[n + 1].g),
			Lerp(g_sz/g_wgrd, g_grds[n].b, g_grds[n + 1].b),
			Lerp(g_sz/g_wgrd, g_grds[n].a, g_grds[n + 1].a))
		if(al == 1) then surface.DrawRect(x, y + i, h, 1)
		else surface.DrawRect(x + i, y, 1, h) end
	end
end

function GetTimeLeft()
	if(!b_RunTime) then return "--:--" end
	local sec = b_BilliardTime - CurTime()
	if(!sec || sec <= 0) then return "00:00" end
	return string.format("%02d:%02d", math.floor(sec / 60), math.fmod(sec, 60))
end

function BilliardSpectate(ply, pos, angles, fov)
	local m_ent = ents.GetByIndex(b_SpecEnt)
	local base = ents.GetByIndex(b_SpecBaseEnt)
	if(m_ent && m_ent:IsValid()) then
		local view = {}
		local dist = 30 + b_Zoom
		if(m_ent:GetClass() == "billiard_cue") then
			local fwrd = m_ent:GetForward() * -1
			view.origin = base:GetPos() + Vector(0, 0, 5) + (fwrd * dist * -1)
			view.angles = fwrd:Angle() + Angle(0, -0.07, 0) -- We need an angle offset
		else
			local fwrd = LocalPlayer():GetAimVector()
			view.origin = m_ent:GetPos() + (fwrd * dist * -1)
			view.angles = angles
		end
		view.fov = 30
		return view
	end
end

function BilliardInputMouseApply(cmd, x, y, angles)
	if(!b_FPerson && LocalPlayer():KeyDown(IN_SPEED)) then return true
	elseif(b_FPerson && LocalPlayer():KeyDown(IN_ATTACK2)) then return true end
	local s = math.Clamp(b_MouseSensitivity:GetFloat(), 0.5, 10) / 100
	x, y = x * -s, y * s
	if(b_InvMouseX:GetBool()) then x = -x end
	if(b_InvMouseY:GetBool()) then y = -y end
	cmd:SetViewAngles(angles + Angle(y, x, 0))
	return true
end

local b_w, b_h, b_px, b_py, b_obj, b_c, b_nm, b_onm
function BilliardHUDPaint()
	b_nm = 128
	surface.SetDrawColor(255, 255, 255, 255)
	-- The main GUI Image
	surface.SetTexture(billiard_mainGUI_tex)
	if(b_GameType == BILLIARD_GAMETYPE_SNOOKER || b_GameType == BILLIARD_GAMETYPE_ROTATION) then
		surface.SetTexture(billiard_mainSGUI_tex)
	elseif(b_GameType == BILLIARD_GAMETYPE_CARAMBOL) then
		surface.SetTexture(billiard_mainCRGUI_tex)
		b_nm = 64
	end
	surface.DrawTexturedRect(ScrW() / 2 - 512, 0, 1024, b_nm)
	-- The pocketed balls
	if(b_GameType == BILLIARD_GAMETYPE_8BALL) then
		if(b_Objective == "OpenTable" && PocketedBalls["OpenBalls"] != nil) then
			surface.SetTexture(billiard_subGUI_tex)
			surface.DrawTexturedRect(ScrW() / 2 - 256, 74, 512, 64)
			draw.SimpleText("Open Balls", "HUDPoolText", ScrW() / 2 - 86, 92, white, 1, 1)
			b_c = 0
			for k,v in pairs(PocketedBalls["OpenBalls"]) do
				if(b_c >= 7) then break end
				b_c = b_c + 1
				surface.SetTexture(billiard_ball_tex[v])
				surface.DrawTexturedRect(ScrW() / 2 - 60 + (22 * k), 75, 32, 32)
			end
		end
	end
	for i,t in pairs(PocketedBalls) do
		if(b_GameType == BILLIARD_GAMETYPE_8BALL && b_Objective == "OpenTable") then break end
		if(!t || type(t) != "table") then continue end
		b_c = 0
		for k,v in pairs(t) do
			if(b_c >= 8) then break end
			b_px = ScrW() / 2 + 65 + (22 * k)
			if(i == constObjective || i == "me") then
				b_px = ScrW() / 2 - 96 - (22 * k)
			end
			b_c = b_c + 1
			surface.SetTexture(billiard_ball_tex[v])
			surface.DrawTexturedRect(b_px, 2, 32, 32)
		end
	end
	-- The infos, such as timeleft, objective, etc
	b_obj = b_Objective
	if(b_GameType == BILLIARD_GAMETYPE_9BALL || b_GameType == BILLIARD_GAMETYPE_ROTATION) then
		tonumber(b_Objective)
		if(b_GameType == BILLIARD_GAMETYPE_9BALL && b_Objective == 9) then b_obj = "9-Ball"
		else b_obj = string.format("Ball: %d", b_Objective) end
	end
	b_px, b_py = ScrW() / 2 - 203, 55
	local onmX, onmY = ScrW() / 2 + 203, 55
	b_nm = LocalPlayer():GetName()
	b_onm = opponentName or "N/A"
	if(b_GameType == BILLIARD_GAMETYPE_SNOOKER || b_GameType == BILLIARD_GAMETYPE_ROTATION ||
		b_GameType == BILLIARD_GAMETYPE_CARAMBOL) then
		b_px, b_py = ScrW() / 2 - 190, 18
		onmX, onmY = ScrW() / 2 + 190, 18
		if(b_GameType == BILLIARD_GAMETYPE_CARAMBOL) then
			b_px = ScrW() / 2 - 169
			onmX = ScrW() / 2 + 169
		end
		b_nm = string.format("%s :: %d", b_nm, b_CScore or 0)
		b_onm = string.format("%d :: %s", b_OScore or 0, b_onm)
	end
	b_w, b_h = ScrW() / 2, ScrH() / 2
	local tpos = b_w
	if(b_GameType != BILLIARD_GAMETYPE_CARAMBOL) then
		tpos = b_w + 42
		draw.SimpleText(b_obj or "", "HUDPoolText", b_w - 42, 18, white, 1, 1)
	end
	draw.SimpleText(GetTimeLeft(), "HUDPoolText", tpos, 18, white, 1, 1)
	draw.SimpleText(b_BarInfo or "", "HUDPoolText", b_w, 55, white, 1, 1)
	draw.SimpleText(b_nm, "HUDPoolText", b_px, b_py, white, 1, 1)
	draw.SimpleText(b_onm, "HUDPoolText", onmX, onmY, white, 1, 1)
	if(b_FoulReason != nil) then
		b_py = 75
		if(b_Objective == "OpenTable" && PocketedBalls["OpenBalls"] != nil) then b_py = 111 end
		draw.GradientBox(b_w - 160, b_py, 64 , 25, 0, Color(0,0,0,0), Color(0,0,0,160))
		draw.GradientBox(b_w + 96, b_py, 64 , 25, 0, Color(0,0,0,160), Color(0,0,0,0))
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(b_w - 95, b_py, 192, 25)
		draw.SimpleText(b_FoulReason, "HUDPoolText", b_w, b_py + 12, white, 1, 1)
	end
	if(!b_FPerson) then
		b_c = (150 / 400) * -b_ShotForce
		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(billiard_meter_tex)
		surface.DrawTexturedRect(b_w - 128, ScrH() - 128, 256, 128)
		surface.SetTexture(billiard_needle_tex)
		surface.DrawTexturedRectRotated(b_w, ScrH() - 2, 128, 64, math.Clamp(b_c, -150, 0))
	end
end

------------------------------------------------------------
-- USERMESSAGES FUNCTIONS
------------------------------------------------------------
usermessage.Hook("billiard_toggleHUD", function(um)
	local c_b = um:ReadBool()
	b_GameType = um:ReadShort()
	b_FPerson = um:ReadBool()
	b_BarInfo = nil
	b_FoulReason = nil
	b_CScore = nil
	b_OScore = nil
	PocketedBalls = {}
	PocketedBalls_tmp = {}
	if(c_b) then
		if(hook.Exist("PoolHUDWinner")) then
			hook.RemoveAll("PoolHUDWinner")
		end
		if(hook.Exist("CBilliardHUD")) then return end
		hook.Add("HUDPaint", "CBilliardHUD", BilliardHUDPaint)
		return
	end
	if(!hook.Exist("CBilliardHUD")) then return end
	hook.RemoveAll("CBilliardHUD")
	hook.RemoveAll("CBilliardMouseLock")
	opponentName = nil
end)

usermessage.Hook("billiard_setObjective", function(um)
	b_Objective = um:ReadString()
	PocketedBalls_tmp["OpenBalls"] = nil
	PocketedBalls["OpenBalls"] = nil
	if(b_Objective != "8-Ball" && b_Objective != "OpenTable") then
		constObjective = b_Objective
	end
end)

usermessage.Hook("billiard_syncTime", function(um)
	b_RunTime = um:ReadBool()
	PocketedBalls = table.Copy(PocketedBalls_tmp)
	if(!b_RunTime) then return end
	b_BilliardTime = CurTime() + um:ReadShort() - (LocalPlayer():Ping() / 1000)
end)

usermessage.Hook("billiard_sendSMsg", function(um)
	local title = um:ReadString()
	local fReason = um:ReadString()
	if(!title) then
		b_BarInfo = nil
		b_FoulReason = nil
		return
	end
	if(fReason == "") then fReason = nil end
	b_BarInfo = title
	b_FoulReason = fReason
end)

usermessage.Hook("billiard_pocketBall", function(um)
	local nBall = um:ReadShort()
	local uID = um:ReadString()
	if(b_GameType == BILLIARD_GAMETYPE_8BALL) then
		local bType = nil
		if(nBall <= 7) then bType = "Solids" else bType = "Stripes" end
		if(b_Objective == "OpenTable") then
			if(!PocketedBalls_tmp["OpenBalls"]) then
				PocketedBalls_tmp["OpenBalls"] = {}
			end
			table.insert(PocketedBalls_tmp["OpenBalls"], nBall)
		end
		if(!PocketedBalls_tmp[bType]) then
			PocketedBalls_tmp[bType] = {}
		end
		table.insert(PocketedBalls_tmp[bType], nBall)
	elseif(b_GameType == BILLIARD_GAMETYPE_9BALL) then
		if(LocalPlayer():UniqueID() == uID) then
			if(!PocketedBalls_tmp["me"]) then
				PocketedBalls_tmp["me"] = {}
			end
			table.insert(PocketedBalls_tmp["me"], nBall)
		else
			if(!PocketedBalls_tmp["opp"]) then
				PocketedBalls_tmp["opp"] = {}
			end
			table.insert(PocketedBalls_tmp["opp"], nBall)
		end
	end
end)

usermessage.Hook("billiard_updateScore", function(um)
	b_CScore = um:ReadShort()
	b_OScore = um:ReadShort()
end)

usermessage.Hook("billiard_sendRequest", function(um)
	local plyid = um:ReadString()
	local name = um:ReadString()
	local player = {}
	player.ID = plyid
	player.Name = name --player.GetByUniqueID(plyid):GetName()
	table.insert(RequestedPlayers, player)
	if(type(b_requests_panel) == "Panel") then b_requests_panel:Remove() end
	guiRequestPlayer()
end)

usermessage.Hook("billiard_removeRequest", function(um)
	local plyid = um:ReadString()
	for i = 1, table.Count(RequestedPlayers) do
		if(RequestedPlayers[i].ID != plyid) then continue end
		RequestedPlayers[i] = nil
	end
	if(type(b_requests_panel) == "Panel") then
		b_requests_panel:Remove()
		if(table.Count(RequestedPlayers) >= 1) then guiRequestPlayer() end
	end
end)

usermessage.Hook("billiard_spectate", function(um)
	local c_b = um:ReadBool()
	local c_e = um:ReadShort()
	local c_cb = um:ReadShort() or nil
	
	// to disable legs and do alpha test
	LocalPlayer().IsPlayingBilliards = c_b
	LocalPlayer().ShouldDisableLegs = c_b
	
	if(c_b) then
		b_SpecEnt = c_e
		b_SpecBaseEnt = c_cb
		if(!b_LastAngles) then
			b_LastAngles = LocalPlayer():GetAimVector()
		end
		if(hook.Exist("CBilliardSpectate")) then return end
		hook.Add("CalcView", "CBilliardSpectate", BilliardSpectate)
		return
	end
	if(!hook.Exist("CBilliardSpectate")) then return end
	hook.RemoveAll("CBilliardSpectate")
	LocalPlayer():SetEyeAngles(b_LastAngles:Angle())
	b_LastAngles = nil
end)

usermessage.Hook("billiard_mouseLock", function(um)
	local c_b = um:ReadBool()
	if(c_b) then
		if(hook.Exist("CBilliardMouseLock")) then return end
		hook.Add("InputMouseApply", "CBilliardMouseLock", BilliardInputMouseApply)
		return
	end
	if(!hook.Exist("CBilliardMouseLock")) then return end
	hook.RemoveAll("CBilliardMouseLock")
end)

usermessage.Hook("billiard_updateInfo", function(um)
	local id = um:ReadString()
	--if(!id || !player.GetByUniqueID(id)) then opponentName = nil return end
	--opponentName = player.GetByUniqueID(id):GetName()
	opponentName = id or nil
end)

usermessage.Hook("billiard_resetInfos", function(um)
	PocketedBalls = {}
	PocketedBalls_tmp = {}
	b_CScore = 0
	b_OScore = 0
end)

------------------------------------------------------------
--	BILLIARD TABLE CLIENT CONFIGURATION GUI
------------------------------------------------------------
function guiBilliardClientConfig()
	if(type(b_client_panel) == "Panel") then b_client_panel:Remove() end
	b_client_panel = vgui.Create("DFrame")
	b_client_panel:SetSize(200, 265)
	b_client_panel:Center()
	b_client_panel:SetTitle("MBilliard Client Configuration")
	b_client_panel:SetVisible(true)
	b_client_panel:SetDraggable(false)
	b_client_panel:ShowCloseButton(false)
	b_client_panel:MakePopup()
	
	------------------------------------------------------------
	local MSPanel = vgui.Create("DPanel", b_client_panel)
	MSPanel:SetPos(10, 27)
	MSPanel:SetSize(180, 50)
	
	local cfSen = math.Clamp(b_MouseSensitivity:GetFloat(), 0.5, 10)
	local mSen = vgui.Create("DNumSlider", MSPanel)
	mSen:SetText("Mouse Sensitivity")
	mSen:SetPos(5, 5)
	mSen:SetWide(170)
	mSen:SetMin(0.5)
	mSen:SetMax(10)
	mSen:SetDecimals(1)
	mSen:SetValue(math.Clamp(b_MouseSensitivity:GetFloat(), 0.5, 10))
	mSen.ValueChanged = function(panel, val)
		cfSen = val
	end

	------------------------------------------------------------
	local CIHPanel = vgui.Create("DPanel", b_client_panel)
	CIHPanel:SetPos(10, 85)
	CIHPanel:SetSize(180, 25)
	
	local cfCIH = b_InvCueMouseX:GetInt()
	local mCInvH = vgui.Create("DCheckBoxLabel", CIHPanel)
	mCInvH:SetText("Cue Invert Mouse Horizontally")
	mCInvH:SetPos(5, 5)
	mCInvH:SetValue(cfCIH)
	mCInvH:SizeToContents()
	mCInvH.OnChange = function()
		if(mCInvH:GetChecked()) then cfCIH = 1
		else cfCIH = 0 end
	end
	
	------------------------------------------------------------
	local CIVPanel = vgui.Create("DPanel", b_client_panel)
	CIVPanel:SetPos(10, 115)
	CIVPanel:SetSize(180, 25)
	
	local cfCIV = b_InvCueMouseY:GetInt()
	local mCInvV = vgui.Create("DCheckBoxLabel", CIVPanel)
	mCInvV:SetText("Cue Invert Mouse Vertically")
	mCInvV:SetPos(5, 5)
	mCInvV:SetValue(cfCIV)
	mCInvV:SizeToContents()
	mCInvV.OnChange = function()
		if(mCInvV:GetChecked()) then cfCIV = 1
		else cfCIV = 0 end
	end
	
	------------------------------------------------------------
	local IHPanel = vgui.Create("DPanel", b_client_panel)
	IHPanel:SetPos(10, 145)
	IHPanel:SetSize(180, 25)

	local cfIH = b_InvMouseX:GetInt()
	local mInvH = vgui.Create("DCheckBoxLabel", IHPanel)
	mInvH:SetText("Invert Mouse Horizontally")
	mInvH:SetPos(5, 5)
	mInvH:SetValue(cfIH)
	mInvH:SizeToContents()
	mInvH.OnChange = function()
		if(mInvH:GetChecked()) then cfIH = 1
		else cfIH = 0 end
	end
	
	------------------------------------------------------------
	local IVPanel = vgui.Create("DPanel", b_client_panel)
	IVPanel:SetPos(10, 175)
	IVPanel:SetSize(180, 25)
	
	local cfIV = b_InvMouseY:GetInt()
	local mInvV = vgui.Create("DCheckBoxLabel", IVPanel)
	mInvV:SetText("Invert Mouse Vertically")
	mInvV:SetPos(5, 5)
	mInvV:SetValue(cfIV)
	mInvV:SizeToContents()
	mInvV.OnChange = function()
		if(mInvV:GetChecked()) then cfIV = 1
		else cfIV = 0 end
	end
	
	------------------------------------------------------------
	local OKBtn = vgui.Create("DButton", b_client_panel)
	OKBtn:SetPos(10, 205)
	OKBtn:SetSize(180, 25)
	OKBtn:SetText("Save Settings")
	OKBtn.DoClick = function()
		RunConsoleCommand("billiard_cl_mouse_sensitivity", tostring(cfSen))
		RunConsoleCommand("billiard_cl_cue_invmouse_h", tostring(cfCIH))
		RunConsoleCommand("billiard_cl_cue_invmouse_v", tostring(cfCIV))
		RunConsoleCommand("billiard_cl_invmouse_h", tostring(cfIH))
		RunConsoleCommand("billiard_cl_invmouse_v", tostring(cfIV))
		b_keyf7_pressed = nil
		b_client_panel:Remove()
	end
	
	------------------------------------------------------------
	local CancelBtn = vgui.Create("DButton", b_client_panel)
	CancelBtn:SetPos(10, 235)
	CancelBtn:SetSize(180, 25)
	CancelBtn:SetText("Cancel")
	CancelBtn.DoClick = function()
		b_keyf7_pressed = nil
		b_client_panel:Remove()
	end
end

------------------------------------------------------------
--	BILLIARD TABLE CONFIGURATION GUI
------------------------------------------------------------
usermessage.Hook("billiard_setConfig", function(um)
	local bid = um:ReadShort()
	local gmtype = um:ReadShort()
	local rdtime = um:ReadShort()
	local abmet = um:ReadShort()
	local skin = um:ReadShort()
	local fpcue = um:ReadBool()
	local trn = um:ReadBool()
	local sc = um:ReadBool()
	local mgp = um:ReadBool()
	local MainFrame = vgui.Create("DFrame")
	MainFrame:SetSize(424, 212)
	MainFrame:Center()
	MainFrame:SetTitle("Billiard Table Options")
	MainFrame:SetVisible(true)
	MainFrame:SetDraggable(false)
	MainFrame:ShowCloseButton(false)
	MainFrame:MakePopup()
	
	local BPanel = vgui.Create("DPanel", MainFrame)
	BPanel:SetPos(148, 30)
	BPanel:SetSize(266, 62)
	
	local BPanelTitle = vgui.Create("DLabel", BPanel)
	BPanelTitle:SetPos(10, 5)
	BPanelTitle:SetText("Advanced Options")
	BPanelTitle:SetFont("TabLarge")
	BPanelTitle:SizeToContents()
	
	local abkMethod = 0
	local abkMultiChoice = vgui.Create("DMultiChoice", BPanel)
	abkMultiChoice:SetPos(140, 33)
	abkMultiChoice:SetSize(116, 20)
	abkMultiChoice:AddChoice("Method 1")
	abkMultiChoice:AddChoice("Method 2")
	abkMultiChoice.OnSelect = function(panel, id, text)
		abkMethod = id
	end
	if(abmet != 0) then
		abkMultiChoice:ChooseOptionID(abmet)
	end
	
	local AbModeBox = vgui.Create("DCheckBoxLabel", BPanel)
	AbModeBox:SetPos(10, 35)
	AbModeBox:SetText("Enable Anti BFH")
	AbModeBox:SetTextColor(Color(230, 230, 230))
	if(abmet == 0) then
		AbModeBox:SetValue(0)
	else
		AbModeBox:SetValue(1)
	end
	AbModeBox:SizeToContents()
	AbModeBox.OnChange = function()
		if(AbModeBox:GetChecked()) then
			abkMethod = 1
			abkMultiChoice:SetVisible(true)
			abkMultiChoice:ChooseOptionID(1)
		else
			abkMethod = 0
			abkMultiChoice:SetVisible(false)
		end
	end
	
	-----------------------------------------------------
	-- SKIN BUTTON
	-----------------------------------------------------
	if(skin > 2) then skin = skin - 3 end
	local ImageSkin = vgui.Create("DImageButton", MainFrame)
	ImageSkin:SetPos(10, 30)
	ImageSkin:SetSize(128, 64)
	ImageSkin:SetMaterial("VGUI/panel/skin"..skin)
	ImageSkin.DoClick = function()
		if(skin >= 2) then skin = 0 else skin = skin + 1 end
		ImageSkin:SetMaterial(string.format("VGUI/panel/skin%d", skin))
	end
	ImageSkin.DoRightClick = function()
		if(skin <= 0) then skin = 2 else skin = skin - 1 end
		ImageSkin:SetMaterial(string.format("VGUI/panel/skin%d", skin))
	end
	
	-----------------------------------------------------
	-- GAME TYPE SELECTION BOX
	-----------------------------------------------------
	local gTPanel = vgui.Create("DPanel", MainFrame)
	gTPanel:SetPos(10, 100)
	gTPanel:SetSize(267, 24)
	
	local gTLabel = vgui.Create("DLabel", gTPanel)
	gTLabel:SetPos(5, 4)
	gTLabel:SetText("Game Type")
	gTLabel:SetTextColor(Color(230, 230, 230))
	--gTLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	--gTLabel:SetFont("DefaultBold")
	gTLabel:SizeToContents()
	
	local gtype = 0
	local gTMultiChoice = vgui.Create("DMultiChoice", gTPanel)
	gTMultiChoice:SetPos(140, 2)
	gTMultiChoice:SetSize(120, 20)
	gTMultiChoice:AddChoice("8 Ball")
	gTMultiChoice:AddChoice("9 Ball")
	gTMultiChoice:AddChoice("Snooker")
	gTMultiChoice:AddChoice("Rotation")
	gTMultiChoice:AddChoice("Carambol")
	gTMultiChoice.OnSelect = function(panel, id, text)
		gtype = id - 1
	end
	gTMultiChoice:ChooseOptionID(gmtype + 1)
	
	-----------------------------------------------------
	-- ROUND TIME SELECTION BOX
	-----------------------------------------------------
	local bTPanel = vgui.Create("DPanel", MainFrame)
	bTPanel:SetPos(10, 129)
	bTPanel:SetSize(267, 24)
	
	local bTLabel = vgui.Create("DLabel", bTPanel)
	bTLabel:SetPos(5, 4)
	bTLabel:SetText("Round Time")
	bTLabel:SetTextColor(Color(230, 230, 230))
	--bTLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	--bTLabel:SetFont("DefaultBold")
	bTLabel:SizeToContents()
	
	local rTime = 0
	local bTMultiChoice = vgui.Create("DMultiChoice", bTPanel)
	bTMultiChoice:SetPos(140, 2)
	bTMultiChoice:SetSize(120, 20)
	bTMultiChoice:AddChoice("15 sec")
	bTMultiChoice:AddChoice("30 sec")
	bTMultiChoice:AddChoice("45 sec")
	bTMultiChoice:AddChoice("60 sec")
	bTMultiChoice.OnSelect = function(panel, id, text)
		rTime = id
	end
	bTMultiChoice:ChooseOptionID(rdtime / 15)

	-----------------------------------------------------
	-- CUE FIRST PERSON CHECKBOX
	-----------------------------------------------------
	local FpPanel = vgui.Create("DPanel", MainFrame)
	FpPanel:SetPos(10, 158)
	FpPanel:SetSize(131, 20)
	
	local FpBoxCh = "false"
	if(fpcue) then FpBoxCh = "true" end
	local FpModeBox = vgui.Create("DCheckBoxLabel", FpPanel)
	FpModeBox:SetPos(5, 3)
	FpModeBox:SetText("Cue First Person")
	FpModeBox:SetTextColor(Color(230, 230, 230))
	FpModeBox:SetValue(fpcue)
	FpModeBox:SizeToContents()
	FpModeBox.OnChange = function()
		if(FpModeBox:GetChecked()) then
			FpBoxCh = "true"
		else
			FpBoxCh = "false"
		end
	end
	
	-----------------------------------------------------
	-- SMART CUE CHECKBOX
	-----------------------------------------------------
	local ScPanel = vgui.Create("DPanel", MainFrame)
	ScPanel:SetPos(146, 158)
	ScPanel:SetSize(131, 20)
	
	local scBoxCh = "true"
	if(!sc) then scBoxCh = "false" end
	ScModeBox = vgui.Create("DCheckBoxLabel", ScPanel)
	ScModeBox:SetPos(5, 3)
	ScModeBox:SetText("Enable SmartCue")
	ScModeBox:SetTextColor(Color(230, 230, 230))
	ScModeBox:SetValue(sc)
	ScModeBox:SizeToContents()
	ScModeBox.OnChange = function()
		if(ScModeBox:GetChecked()) then
			scBoxCh = "true"
		else
			scBoxCh = "false"
		end
	end
	
	-----------------------------------------------------
	-- TRAINING MODE CHECKBOX
	-----------------------------------------------------
	local TrPanel = vgui.Create("DPanel", MainFrame)
	TrPanel:SetPos(10, 183)
	TrPanel:SetSize(131, 20)
	
	local trBoxCh = "false"
	if(trn) then trBoxCh = "true" end
	local TrModeBox = vgui.Create("DCheckBoxLabel", TrPanel)
	TrModeBox:SetPos(5, 3)
	TrModeBox:SetText("Training mode")
	TrModeBox:SetTextColor(Color(230, 230, 230))
	TrModeBox:SetValue(trn)
	TrModeBox:SizeToContents()
	TrModeBox.OnChange = function()
		if(TrModeBox:GetChecked()) then
			trBoxCh = "true"
		else
			trBoxCh = "false"
		end
	end
	
	-----------------------------------------------------
	-- MINGEBAG PROTECTION CHECKBOX
	-----------------------------------------------------
	local MpPanel = vgui.Create("DPanel", MainFrame)
	MpPanel:SetPos(282, 158)
	MpPanel:SetSize(131, 20)
	
	local MpBoxCh = "true"
	if(!mgp) then MpBoxCh = "false" end
	local MpModeBox = vgui.Create("DCheckBoxLabel", MpPanel)
	MpModeBox:SetPos(5, 3)
	MpModeBox:SetText("MingeBag Protection")
	MpModeBox:SetTextColor(Color(230, 230, 230))
	MpModeBox:SetValue(mgp)
	MpModeBox:SizeToContents()
	MpModeBox.OnChange = function()
		if(MpModeBox:GetChecked()) then
			MpBoxCh = "true"
		else
			MpBoxCh = "false"
		end
	end
	
	local spButton = vgui.Create("DButton", MainFrame)
	spButton:SetPos(282, 100)
	spButton:SetSize(131, 24)
	spButton:SetText("OK")
	spButton.DoClick = function()
		RunConsoleCommand("billiard_config", bid, skin, gtype, rTime, trBoxCh, scBoxCh, abkMethod, MpBoxCh, FpBoxCh)
		MainFrame:Remove()
	end
	
	local CancelBtn = vgui.Create("DButton", MainFrame)
	CancelBtn:SetPos(282, 129)
	CancelBtn:SetSize(131, 24)
	CancelBtn:SetText("Cancel")
	CancelBtn.DoClick = function()
		MainFrame:Remove()
	end
end)

------------------------------------------------------------
--	BILLIARD TABLE REQUESTS LIST GUI
------------------------------------------------------------
function guiRequestPlayer()
	local width, height = ScrW() / 2, ScrH() / 2
	b_requests_panel = vgui.Create("DFrame")
	b_requests_panel:SetSize(width, height)
	b_requests_panel:Center()
	b_requests_panel:SetTitle("Billiard Requests")
	b_requests_panel:SetVisible(true)
	b_requests_panel:SetDraggable(false)
	b_requests_panel:ShowCloseButton(false)
	b_requests_panel:MakePopup()
	
	local offset = width * 0.05 -- 5% of margin
	local GridList = vgui.Create("DListView", b_requests_panel)
	GridList:SetSize(width * 0.7 - (offset * 3), height - 22 - (offset * 2))
	GridList:SetPos(offset, 22 + offset)
	GridList:AddColumn("Name")
	for i = 1, table.Count(RequestedPlayers) do
		GridList:AddLine(tostring(RequestedPlayers[i].Name))
	end
	
	local BWidth, BHeight = width * 0.3, height * 0.1
	local AccButn = vgui.Create("DButton", b_requests_panel)
	AccButn:SetSize(BWidth, BHeight)
	AccButn:SetPos(width - BWidth - offset, 22 + offset)
	AccButn:SetText("Accept Selected")
	AccButn.Think = function()
		local id = GridList:GetSelectedLine()
		if(GridList != nil && id != nil) then
			AccButn:SetEnabled(true)
			AccButn.DoClick = function()
				RunConsoleCommand("billiard_acc_ref", "true", RequestedPlayers[id].ID)
				RequestedPlayers = {}
				b_requests_panel:Remove()
			end
		else
			AccButn:SetEnabled(false)
			AccButn.DoClick = function() end
		end
	end
	
	local RefButn = vgui.Create("DButton", b_requests_panel)
	local b_offset = offset * 0.5
	RefButn:SetSize(BWidth, BHeight)
	RefButn:SetPos(width - BWidth - offset, 22 + offset + b_offset + BHeight)
	RefButn:SetText("Refuse Selected")
	RefButn.Think = function()
		local id = GridList:GetSelectedLine()
		if(GridList != nil && id != nil) then
			RefButn:SetEnabled(true)
			RefButn.DoClick = function()
				RunConsoleCommand("billiard_acc_ref", "false", RequestedPlayers[id].ID)
				RequestedPlayers[id] = nil
				b_requests_panel:Remove()
				if(table.Count(RequestedPlayers) >= 1) then
					return guiRequestPlayer()
				end
			end
		else
			RefButn:SetEnabled(false)
			RefButn.DoClick = function() end
		end
	end
	
	local RandButn = vgui.Create("DButton", b_requests_panel)
	RandButn:SetSize(BWidth, BHeight)
	RandButn:SetPos(width - BWidth - offset, 22 + offset + b_offset * 2 + BHeight * 2)
	RandButn:SetText("Random Accept")
	RandButn.DoClick = function()
		local num = math.Rand(1, table.Count(RequestedPlayers))
		RunConsoleCommand("billiard_acc_ref", "true", RequestedPlayers[num].ID)
		RequestedPlayers = {}
		b_requests_panel:Remove()
	end
	
	local RefAButn = vgui.Create("DButton", b_requests_panel)
	RefAButn:SetSize(BWidth, BHeight)
	RefAButn:SetPos(width - BWidth - offset, 22 + offset + b_offset * 3 + BHeight * 3)
	RefAButn:SetText("Refuse All")
	RefAButn.DoClick = function()
		for i = 1, table.Count(RequestedPlayers) do
			RunConsoleCommand("billiard_acc_ref", "false", RequestedPlayers[i].ID)
		end
		RequestedPlayers = {}
		b_requests_panel:Remove()
	end
	
	local ClButn = vgui.Create("DButton", b_requests_panel)
	ClButn:SetSize(BWidth, BHeight)
	ClButn:SetPos(width - BWidth - offset, 22 + offset + b_offset * 4 + BHeight * 4)
	ClButn:SetText("Close")
	ClButn.DoClick = function()
		b_requests_panel:Remove()
	end
end

------------------------------------------------------------
--	BILLIARD TABLE CREATION GUI
------------------------------------------------------------
usermessage.Hook("billiard_createMenu", function(um)
	local SpawnPos = um:ReadVector()
	local MainFrame = vgui.Create("DFrame")
	MainFrame:SetSize(424, 242)
	MainFrame:Center()
	MainFrame:SetTitle("Billiard Table Options")
	MainFrame:SetVisible(true)
	MainFrame:SetDraggable(false)
	MainFrame:ShowCloseButton(false)
	MainFrame:MakePopup()
	
	local BPanel = vgui.Create("DPanel", MainFrame)
	BPanel:SetPos(148, 30)
	BPanel:SetSize(266, 62)
	
	local BPanelTitle = vgui.Create("DLabel", BPanel)
	BPanelTitle:SetPos(10, 5)
	BPanelTitle:SetText("Advanced Options")
	BPanelTitle:SetFont("TabLarge")
	BPanelTitle:SizeToContents()
	
	local abkMethod = 0
	local abkMultiChoice = vgui.Create("DMultiChoice", BPanel)
	abkMultiChoice:SetPos(140, 33)
	abkMultiChoice:SetSize(116, 20)
	abkMultiChoice:AddChoice("Method 1")
	abkMultiChoice:AddChoice("Method 2")
	abkMultiChoice.OnSelect = function(panel, id, text)
		abkMethod = id
	end
	abkMultiChoice:ChooseOptionID(2)
	
	local AbModeBox = vgui.Create("DCheckBoxLabel", BPanel)
	AbModeBox:SetPos(10, 35)
	AbModeBox:SetText("Enable Anti BFH")
	AbModeBox:SetTextColor(Color(230, 230, 230))
	AbModeBox:SetValue(1)
	AbModeBox:SizeToContents()
	AbModeBox.OnChange = function()
		if(AbModeBox:GetChecked()) then
			abkMethod = 1
			abkMultiChoice:SetVisible(true)
			abkMultiChoice:ChooseOptionID(1)
		else
			abkMethod = 0
			abkMultiChoice:SetVisible(false)
		end
	end
	
	-----------------------------------------------------
	-- SKIN BUTTON
	-----------------------------------------------------
	local skin = 0
	local ImageSkin = vgui.Create("DImageButton", MainFrame)
	ImageSkin:SetPos(10, 30)
	ImageSkin:SetSize(128, 64)
	ImageSkin:SetMaterial("VGUI/panel/skin0")
	ImageSkin.DoClick = function()
		if(skin >= 2) then skin = 0 else skin = skin + 1 end
		ImageSkin:SetMaterial(string.format("VGUI/panel/skin%d", skin))
	end
	ImageSkin.DoRightClick = function()
		if(skin <= 0) then skin = 2 else skin = skin - 1 end
		ImageSkin:SetMaterial(string.format("VGUI/panel/skin%d", skin))
	end
	
	-----------------------------------------------------
	-- GAME TYPE SELECTION BOX
	-----------------------------------------------------
	local gTPanel = vgui.Create("DPanel", MainFrame)
	gTPanel:SetPos(10, 100)
	gTPanel:SetSize(267, 24)
	
	local gTLabel = vgui.Create("DLabel", gTPanel)
	gTLabel:SetPos(5, 4)
	gTLabel:SetText("Game Type")
	gTLabel:SetTextColor(Color(230, 230, 230))
	--gTLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	--gTLabel:SetFont("DefaultBold")
	gTLabel:SizeToContents()
	
	local gtype = 0
	local gTMultiChoice = vgui.Create("DMultiChoice", gTPanel)
	gTMultiChoice:SetPos(140, 2)
	gTMultiChoice:SetSize(120, 20)
	gTMultiChoice:AddChoice("8 Ball")
	gTMultiChoice:AddChoice("9 Ball")
	gTMultiChoice:AddChoice("Snooker")
	gTMultiChoice:AddChoice("Rotation")
	gTMultiChoice:AddChoice("Carambol")
	gTMultiChoice.OnSelect = function(panel, id, text)
		gtype = id - 1
	end
	gTMultiChoice:ChooseOptionID(1)
	
	-----------------------------------------------------
	-- ROUND TIME SELECTION BOX
	-----------------------------------------------------
	local bTPanel = vgui.Create("DPanel", MainFrame)
	bTPanel:SetPos(10, 129)
	bTPanel:SetSize(267, 24)
	
	local bTLabel = vgui.Create("DLabel", bTPanel)
	bTLabel:SetPos(5, 4)
	bTLabel:SetText("Round Time")
	bTLabel:SetTextColor(Color(230, 230, 230))
	--bTLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	--bTLabel:SetFont("DefaultBold")
	bTLabel:SizeToContents()
	
	local rTime = 0
	local bTMultiChoice = vgui.Create("DMultiChoice", bTPanel)
	bTMultiChoice:SetPos(140, 2)
	bTMultiChoice:SetSize(120, 20)
	bTMultiChoice:AddChoice("15 sec")
	bTMultiChoice:AddChoice("30 sec")
	bTMultiChoice:AddChoice("45 sec")
	bTMultiChoice:AddChoice("60 sec")
	bTMultiChoice.OnSelect = function(panel, id, text)
		rTime = id
	end
	bTMultiChoice:ChooseOptionID(2)
	
	-----------------------------------------------------
	-- TABLE SIZE SELECTION BOX
	-----------------------------------------------------
	local szPanel = vgui.Create("DPanel", MainFrame)
	szPanel:SetPos(10, 158)
	szPanel:SetSize(267, 24)
	
	local szLabel = vgui.Create("DLabel", szPanel)
	szLabel:SetPos(5, 4)
	szLabel:SetText("Table Size")
	szLabel:SetTextColor(Color(230, 230, 230))
	--szLabel:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	--szLabel:SetFont("DefaultBold")
	szLabel:SizeToContents()
	
	local size = 9
	local szMultiChoice = vgui.Create("DMultiChoice", szPanel)
	szMultiChoice:SetPos(140, 2)
	szMultiChoice:SetSize(120, 20)
	szMultiChoice:AddChoice("9 Feet")
	szMultiChoice:AddChoice("10 Feet")
	szMultiChoice:AddChoice("12 Feet")
	szMultiChoice.OnSelect = function(panel, id, text)
		local select = {}
		select[1] = 9
		select[2] = 10
		select[3] = 12
		size = select[id]
	end
	szMultiChoice:ChooseOptionID(1)

	-----------------------------------------------------
	-- TRAINING MODE CHECKBOX
	-----------------------------------------------------
	local TrPanel = vgui.Create("DPanel", MainFrame)
	TrPanel:SetPos(10, 187)
	TrPanel:SetSize(131, 20)
	
	local trBoxCh = "false"
	local TrModeBox = vgui.Create("DCheckBoxLabel", TrPanel)
	TrModeBox:SetPos(5, 3)
	TrModeBox:SetText("Training mode")
	TrModeBox:SetTextColor(Color(230, 230, 230))
	TrModeBox:SetValue(0)
	TrModeBox:SizeToContents()
	TrModeBox.OnChange = function()
		if(TrModeBox:GetChecked()) then
			trBoxCh = "true"
		else
			trBoxCh = "false"
		end
	end
	
	-----------------------------------------------------
	-- SMART CUE CHECKBOX
	-----------------------------------------------------
	local ScPanel = vgui.Create("DPanel", MainFrame)
	ScPanel:SetPos(146, 187)
	ScPanel:SetSize(131, 20)
	
	local scBoxCh = "true"
	ScModeBox = vgui.Create("DCheckBoxLabel", ScPanel)
	ScModeBox:SetPos(5, 3)
	ScModeBox:SetText("Enable SmartCue")
	ScModeBox:SetTextColor(Color(230, 230, 230))
	ScModeBox:SetValue(1)
	ScModeBox:SizeToContents()
	ScModeBox.OnChange = function()
		if(ScModeBox:GetChecked()) then
			scBoxCh = "true"
		else
			scBoxCh = "false"
		end
	end
	
	-----------------------------------------------------
	-- MINGEBAG PROTECTION CHECKBOX
	-----------------------------------------------------
	local MpPanel = vgui.Create("DPanel", MainFrame)
	MpPanel:SetPos(282, 187)
	MpPanel:SetSize(131, 20)
	
	local MpBoxCh = "true"
	local MpModeBox = vgui.Create("DCheckBoxLabel", MpPanel)
	MpModeBox:SetPos(5, 3)
	MpModeBox:SetText("MingeBag Protection")
	MpModeBox:SetTextColor(Color(230, 230, 230))
	MpModeBox:SetValue(1)
	MpModeBox:SizeToContents()
	MpModeBox.OnChange = function()
		if(MpModeBox:GetChecked()) then
			MpBoxCh = "true"
		else
			MpBoxCh = "false"
		end
	end
	
	-----------------------------------------------------
	-- CUE FIRST PERSON CHECKBOX
	-----------------------------------------------------
	local FpPanel = vgui.Create("DPanel", MainFrame)
	FpPanel:SetPos(10, 212)
	FpPanel:SetSize(131, 20)
	
	local FpBoxCh = "true"
	local FpModeBox = vgui.Create("DCheckBoxLabel", FpPanel)
	FpModeBox:SetPos(5, 3)
	FpModeBox:SetText("Cue First Person")
	FpModeBox:SetTextColor(Color(230, 230, 230))
	FpModeBox:SetValue(1)
	FpModeBox:SizeToContents()
	FpModeBox.OnChange = function()
		if(FpModeBox:GetChecked()) then
			FpBoxCh = "true"
		else
			FpBoxCh = "false"
		end
	end
	
	local dfButton = vgui.Create("DButton", MainFrame)
	dfButton:SetPos(282, 100)
	dfButton:SetSize(131, 24)
	dfButton:SetText("Default")
	dfButton.DoClick = function()
		AbModeBox:SetValue(1)
		abkMultiChoice:ChooseOptionID(2)
		ScModeBox:SetValue(1)
		TrModeBox:SetValue(0)
		MpModeBox:SetValue(1)
		FpModeBox:SetValue(1)
	end
	
	local spButton = vgui.Create("DButton", MainFrame)
	spButton:SetPos(282, 129)
	spButton:SetSize(131, 24)
	spButton:SetText("Create")
	spButton.DoClick = function()
		RunConsoleCommand("billiard_create", SpawnPos[1], SpawnPos[2], SpawnPos[3], size, skin, gtype, rTime, trBoxCh, scBoxCh, abkMethod, MpBoxCh, FpBoxCh)
		MainFrame:Remove()
	end
	
	local CancelBtn = vgui.Create("DButton", MainFrame)
	CancelBtn:SetPos(282, 158)
	CancelBtn:SetSize(131, 24)
	CancelBtn:SetText("Cancel")
	CancelBtn.DoClick = function()
		MainFrame:Remove()
	end
end)

------------------------------------------------------------
--	BILLIARD TABLE EXIT QUESTION GUI
------------------------------------------------------------
usermessage.Hook("billiard_promptExit", function(um)
	Msg( "omg")
	local width, height = ScrW() / 3, ScrH() / 4 -- 260, 150
	local MainFrame = vgui.Create("DFrame")
	MainFrame:SetSize(width, height)
	MainFrame:Center()
	MainFrame:SetTitle("Are you sure?")
	MainFrame:SetVisible(true)
	MainFrame:SetDraggable(false)
	MainFrame:ShowCloseButton(false)
	MainFrame:MakePopup()
	MainFrame:DoModal()
	
	local Woffset, Hoffset = width * 0.1, height * 0.1
	local Label = vgui.Create("DLabel", MainFrame)
	Label:SetSize(width - Woffset, height / 2)
	Label:SetPos(Woffset / 2, 22 + Hoffset / 2)
	Label:SetWrap(true)
	Label:SetText("Are you sure do you want to exit? You will lose the game.")
	Label:SetContentAlignment(7)
	
	local BWidth, BHeight = width / 2, height / 4
	BWidth = BWidth - Woffset * 1.5
	BHeight = BHeight - Hoffset
	local ExitButn = vgui.Create("DButton", MainFrame)
	ExitButn:SetSize(BWidth, BHeight)
	ExitButn:SetPos(Woffset, height - BHeight - Hoffset)
	ExitButn:SetText("Exit")
	ExitButn.DoClick = function()
		RunConsoleCommand("billiard_quit")
		MainFrame:Remove()
	end
	
	local CButn = vgui.Create("DButton", MainFrame)
	CButn:SetSize(BWidth, BHeight)
	CButn:SetPos(width - BWidth - Woffset, height - BHeight - Hoffset)
	CButn:SetText("Cancel")
	CButn.DoClick = function()
		MainFrame:Remove()
	end
end)