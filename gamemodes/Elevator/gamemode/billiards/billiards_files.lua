------------------------------------------------------------
-- MBilliards by Athos Arantes Pereira
-- Contact: athosarantes@hotmail.com
------------------------------------------------------------
-- LUA Files
AddCSLuaFile("cl_billiards.lua")

-- Sounds
for i = 0, 6 do
	local wav = string.format("sound/billiards/hit_%02d.wav", i)
	util.PrecacheSound(wav)
	resource.AddFile(wav)
	if(i >= 6) then continue end
	wav = string.format("sound/billiards/cuehit_%02d.wav", i)
	util.PrecacheSound(wav)
	resource.AddFile(wav)
	wav = string.format("sound/billiards/tablehit_%02d.wav", i)
	util.PrecacheSound(wav)
	resource.AddFile(wav)
end