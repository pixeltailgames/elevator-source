--[[
 	Post-Processing Events

	Put the code for your PostEvents
	in here.
]]--

local function playerDeath( mul, time )

	local layer = postman.NewColorLayer()
	layer.color = 0.2
	postman.FadeColorIn( "pdeath", layer, 2 )

	layer = postman.NewColorLayer()
	layer.contrast = .05
	postman.FadeColorIn( "pdeathslow", layer, 8 )

end
AddPostEvent( "pdeath", playerDeath )

local function playerSpawn( mul, time )

	-- Undo death effects
	postman.ForceColorFade( "pdeath" )
    postman.RemoveColorLayer( "pdeath" )

	postman.ForceColorFade( "pdeathslow" )
	postman.FadeColorOut( "pdeathslow", 2 )

end
AddPostEvent( "pspawn", playerSpawn )


local function playerBWOn( mul, time )

	local layer = postman.NewColorLayer()
	layer.color = 0
	postman.FadeColorIn( "pBW", layer, 4 )

end
AddPostEvent( "pBWOn", playerBWOn )

local function playerBWOff( mul, time )

	postman.ForceColorFade( "pBW" )
    postman.FadeColorOut( "pBW", 4 )

end
AddPostEvent( "pBWOff", playerBWOff )

local function playerDamage( mul, time )

	-- Red fade
	local layer = postman.NewColorLayer()
	layer.addr = mul
	layer.addg = mul
	postman.AddColorLayer( "pdamage", layer )
	postman.FadeColorOut( "pdamage", mul * 3 )

	-- Motionblur fade
	layer = postman.NewMotionBlurLayer()
	layer.addalpha = 0.02
	postman.AddMotionBlurLayer( "pdamage", layer )
	postman.FadeMotionBlurOut( "pdamage", mul * 3 )

end
AddPostEvent( "pdamage", playerDamage )


local function timeOn( mul, time )
	layer = postman.NewBloomLayer()
	layer.sizex = 15.0
	layer.sizey = 0.0
	layer.multiply = 2.0
	layer.color = 0.0
	layer.passes = 1.0
	layer.darken = 0.3
	postman.FadeBloomIn( "ptime_on", layer, 1 )
	
	local layer = postman.NewColorLayer()
	layer.color = 0.5
	postman.FadeColorIn( "ptime_on", layer, 1 )
end
AddPostEvent( "ptime_on", timeOn )

local function timeOff( mul, time )
	postman.ForceColorFade( "ptime_on" )
	postman.FadeColorOut( "ptime_on", 1 )
	
	postman.ForceBloomFade( "ptime_on" )
    postman.FadeBloomOut( "ptime_on", 1 )
end
AddPostEvent( "ptime_off", timeOff )


local function coloredOn( mul, time )
	local layer = postman.NewColorLayer()
	layer.contrast = 1.15
	layer.color = 4.0
	postman.FadeColorIn( "pcolored_on", layer, 0.2 )
	
	layer = postman.NewBloomLayer()
	layer.sizex = 9.0
	layer.sizey = 9.0
	layer.multiply = 0.45
	layer.color = 1.0
	layer.passes = 0.0
	layer.darken = 0.0
	postman.FadeBloomIn( "pcolored_on", layer, 1 )
	
	layer = postman.NewSharpenLayer()
	layer.contrast = .20
	layer.distance = 3
	postman.FadeSharpenIn( "pcolored_on", layer, 1.5 )
end
AddPostEvent( "pcolored_on", coloredOn )

local function coloredOff( mul, time )
	postman.ForceColorFade( "pcolored_on" )
	postman.FadeColorOut( "pcolored_on", 1 )
	
	postman.ForceBloomFade( "pcolored_on" )
    postman.FadeBloomOut( "pcolored_on", 1 )
	
	postman.ForceSharpenFade( "pcolored_on" )
    postman.FadeSharpenOut( "pcolored_on", 1 )
end
AddPostEvent( "pcolored_off", coloredOff )

local function bone_On( mul, time )
	layer = postman.NewMotionBlurLayer()
	layer.addalpha = 0.11
	layer.drawalpha = 0.36
	postman.AddMotionBlurLayer( "pbone_on", layer )
	
	local layer = postman.NewColorLayer()
	layer.color = 0.0
	layer.brightness = -0.02
	layer.contrast = 0.98
	postman.FadeColorIn( "pbone_on", layer, 1 )
	
	layer = postman.NewSharpenLayer()
	layer.contrast = -0.55
	layer.distance = 1.75
	postman.FadeSharpenIn( "pbone_on", layer, 2 )
end
AddPostEvent( "pbone_on", bone_On )

local function bone_Off( mul, time )
	postman.FadeMotionBlurOut( "pbone_on", mul * 3 )
	
	postman.ForceColorFade( "pbone_on" )
	postman.FadeColorOut( "pbone_on", 1 )
	
	postman.ForceSharpenFade( "pbone_on" )
    postman.FadeSharpenOut( "pbone_on", 1 )
end
AddPostEvent( "pbone_off", bone_Off )