--[[
	"The PostMan"
	Post-Processing Management Library
	
	by PackRat ( packrat (at) plebsquad (dot) com )
	
	Version 1.3, 21st Feb 2007
	
	-- 1.3
	    - Added: Material Overlay support
		
	-- 1.2
	    - Added: Force*****Fade() to force a layer fade to instantly reach its destination
	    - Fixed: Missing pman.*****.gotlayers checks
	    - Fixed: Flicker on fadein transferring to layers
	    
	-- 1.1
	    - Added: Bloom support
	    - Fixed: Motionblur flickering on layer update
	    - Fixed: (accidentally) Whatever the hell was causing it to explode intermittently

	-- 1.0
	    - Repackaged code as 'postman' library
	    - Added: Sharpen and Motionblur support
		- Fixed: Now uses Draw******() instead of stupid 'pp' cvars
	    - Fixed: Rebuilt fader code
				
	-- 0.1
	    - Added: Colormod supports separate layers
		- Added: Layer fading
]]--



-- Public PostMan library
postman = {}

function postman.NewColorLayer() 						return pman.color:NewLayer() end
function postman.NewSharpenLayer() 						return pman.sharp:NewLayer() end
function postman.NewMotionBlurLayer() 					return pman.mblur:NewLayer() end
function postman.NewBloomLayer() 						return pman.bloom:NewLayer() end
function postman.NewMaterialLayer() 					return pman.ovrly:NewLayer() end

function postman.AddColorLayer( name, tbl ) 			pman.color:AddLayer( name, tbl ) end
function postman.AddSharpenLayer( name, tbl ) 			pman.sharp:AddLayer( name, tbl ) end
function postman.AddMotionBlurLayer( name, tbl ) 		pman.mblur:AddLayer( name, tbl ) end
function postman.AddBloomLayer( name, tbl ) 			pman.bloom:AddLayer( name, tbl ) end
function postman.AddMaterialLayer( name, tbl ) 			pman.ovrly:AddLayer( name, tbl ) end

function postman.RemoveColorLayer( name ) 				pman.color:RemoveLayer( name ) end
function postman.RemoveSharpenLayer( name ) 			pman.sharp:RemoveLayer( name ) end
function postman.RemoveMotionBlurLayer( name ) 			pman.mblur:RemoveLayer( name ) end
function postman.RemoveBloomLayer( name ) 				pman.bloom:RemoveLayer( name ) end
function postman.RemoveMaterialLayer( name ) 			pman.ovrly:RemoveLayer( name ) end

function postman.FadeColorIn( name, tbl, time ) 		pman.color:FadeIn( name, tbl, time ) end
function postman.FadeSharpenIn( name, tbl, time ) 		pman.sharp:FadeIn( name, tbl, time ) end
function postman.FadeMotionBlurIn( name, tbl, time ) 	pman.mblur:FadeIn( name, tbl, time ) end
function postman.FadeBloomIn( name, tbl, time ) 		pman.bloom:FadeIn( name, tbl, time ) end
function postman.FadeMaterialIn( name, tbl, time ) 		pman.ovrly:FadeIn( name, tbl, time ) end

function postman.FadeColorOut( name, time ) 			pman.color:FadeOut( name, time ) end
function postman.FadeSharpenOut( name, time ) 			pman.sharp:FadeOut( name, time ) end
function postman.FadeMotionBlurOut( name, time ) 		pman.mblur:FadeOut( name, time ) end
function postman.FadeBloomOut( name, time ) 			pman.bloom:FadeOut( name, time ) end
function postman.FadeMaterialOut( name, time ) 			pman.ovrly:FadeOut( name, time ) end

function postman.ForceColorFade( name ) 				pman.color:ForceFade( name ) end
function postman.ForceSharpenFade( name ) 				pman.sharp:ForceFade( name ) end
function postman.ForceMotionBlurFade( name ) 			pman.mblur:ForceFade( name ) end
function postman.ForceBloomFade( name ) 				pman.bloom:ForceFade( name ) end
function postman.ForceMaterialFade( name ) 				pman.ovrly:ForceFade( name ) end

function postman.SetFrameRate( rate )					pman.framerate = Math.Clamp( rate, 0, 100 ) end



--------------------------------------------------
-- Internal library structure below this point
-- Leave this shit alone - all interaction
-- is done thru the 'postman' library above

pman = {}
pman.lastthink 	= CurTime()
pman.framerate	= 0.025
pman.color 		= {}
pman.sharp 		= {}
pman.mblur 		= {}
pman.bloom      = {}
pman.ovrly      = {}

pman.color.active 		= false
pman.color.gotlayers 	= false
pman.color.gotfades 	= false
pman.color.final 		= nil
pman.color.merged		= nil
pman.color.layers 		= {}
pman.color.fades 		= {}
pman.color.ADDR 		= 0
pman.color.ADDG 		= 0
pman.color.ADDB 		= 0
pman.color.MULR 		= 0
pman.color.MULG 		= 0
pman.color.MULB 		= 0
pman.color.COLOR 		= 1
pman.color.CONTRAST 	= 1
pman.color.BRIGHTNESS 	= 0
pman.color.translated 	= {}
pman.color.translated[ "$pp_colour_addr" ] 			= pman.color.ADDR
pman.color.translated[ "$pp_colour_addg" ] 			= pman.color.ADDG
pman.color.translated[ "$pp_colour_addb" ] 			= pman.color.ADDB
pman.color.translated[ "$pp_colour_brightness" ] 	= pman.color.BRIGHTNESS
pman.color.translated[ "$pp_colour_contrast" ] 		= pman.color.CONTRAST
pman.color.translated[ "$pp_colour_colour" ] 		= pman.color.COLOR
pman.color.translated[ "$pp_colour_mulr" ] 			= pman.color.MULR
pman.color.translated[ "$pp_colour_mulg" ] 			= pman.color.MULG
pman.color.translated[ "$pp_colour_mulb" ] 			= pman.color.MULB

pman.sharp.active 		= false
pman.sharp.gotlayers 	= false
pman.sharp.gotfades 	= false
pman.sharp.final 		= nil
pman.sharp.merged		= nil
pman.sharp.layers 		= {}
pman.sharp.fades 		= {}
pman.sharp.CONTRAST 	= 0
pman.sharp.DISTANCE 	= 0

pman.mblur.active 		= false
pman.mblur.gotlayers 	= false
pman.mblur.gotfades 	= false
pman.mblur.final 		= nil
pman.mblur.merged		= nil
pman.mblur.layers 		= {}
pman.mblur.fades 		= {}
pman.mblur.ADDALPHA 	= 1
pman.mblur.DRAWALPHA 	= 1
pman.mblur.DELAY 		= 0

pman.bloom.active 		= false
pman.bloom.gotlayers 	= false
pman.bloom.gotfades 	= false
pman.bloom.final 		= nil
pman.bloom.merged		= nil
pman.bloom.layers 		= {}
pman.bloom.fades 		= {}
pman.bloom.DARKEN 		= 0
pman.bloom.MULTIPLY 	= 0
pman.bloom.SIZEX 		= 0
pman.bloom.SIZEY 		= 0
pman.bloom.PASSES 		= 1
pman.bloom.COLOR 		= 1
pman.bloom.COLR 		= 1
pman.bloom.COLG 		= 1
pman.bloom.COLB 		= 1

pman.ovrly.active 		= false
pman.ovrly.gotlayers 	= false
pman.ovrly.gotfades 	= false
pman.ovrly.layers 		= {}
pman.ovrly.fades 		= {}
pman.ovrly.MATERIAL 	= "models/shadertest/shader3"
pman.ovrly.ALPHA	 	= 0
pman.ovrly.REFRACT 		= 0
pman.ovrly.BLUR 		= 0 

        
-- Get a table with default colormod values
function pman.color:NewLayer()

	local tbl 		= {}
	tbl.addr 		= self.ADDR
	tbl.addg 		= self.ADDG
	tbl.addb 		= self.ADDB
	tbl.mulr 		= self.MULR
	tbl.mulg 		= self.MULG
	tbl.mulb 		= self.MULB
	tbl.color 		= self.COLOR
	tbl.contrast 	= self.CONTRAST
	tbl.brightness 	= self.BRIGHTNESS
	return tbl

end

-- Get a table with default sharpen values
function pman.sharp:NewLayer()

	local tbl 		= {}
	tbl.contrast 	= self.CONTRAST
	tbl.distance 	= self.DISTANCE
	return tbl

end

-- Get a table with default motionblur values
function pman.mblur:NewLayer()

	local tbl 		= {}
	tbl.addalpha 	= self.ADDALPHA
	tbl.drawalpha 	= self.DRAWALPHA
	tbl.delay		= self.DELAY
	return tbl

end

-- Get a table with default bloom values
function pman.bloom:NewLayer()

	local tbl 		= {}
	tbl.darken 		= self.DARKEN
	tbl.multiply 	= self.MULTIPLY
	tbl.sizex		= self.SIZEX
	tbl.sizey 		= self.SIZEY
	tbl.passes 		= self.PASSES
	tbl.color		= self.COLOR
	tbl.colr 		= self.COLR
	tbl.colg 		= self.COLG
	tbl.colb		= self.COLB
	return tbl

end

-- Get a table with default overlay values
function pman.ovrly:NewLayer()

	local tbl 		= {}
	tbl.material 	= self.MATERIAL
	tbl.alpha 		= self.ALPHA
	tbl.refract		= self.REFRACT
	tbl.blur		= self.BLUR
	return tbl

end



-- Merge two color layers into the first
function pman.color:MergeLayers( tbl1, tbl2, mul )

	mul = mul or 1
	tbl1.addr 		= tbl1.addr + ( tbl2.addr - self.ADDR ) * mul
	tbl1.addg 		= tbl1.addg + ( tbl2.addg - self.ADDG ) * mul
	tbl1.addb 		= tbl1.addb + ( tbl2.addb - self.ADDB ) * mul
	tbl1.mulr 		= tbl1.mulr + ( tbl2.mulr - self.MULR ) * mul
	tbl1.mulg 		= tbl1.mulg + ( tbl2.mulg - self.MULG ) * mul
	tbl1.mulb 		= tbl1.mulb + ( tbl2.mulb - self.MULB ) * mul
	tbl1.color 		= tbl1.color + ( tbl2.color - self.COLOR ) * mul
	tbl1.brightness = tbl1.brightness + ( tbl2.brightness - self.BRIGHTNESS ) * mul
	tbl1.contrast 	= tbl1.contrast + ( tbl2.contrast - self.CONTRAST ) * mul
	
end

-- Merge two sharpen layers into the first
function pman.sharp:MergeLayers( tbl1, tbl2, mul )

	mul = mul or 1
	tbl1.contrast = tbl1.contrast + ( tbl2.contrast - self.CONTRAST ) * mul
	tbl1.distance = tbl1.distance + ( tbl2.distance - self.DISTANCE ) * mul
		
end

-- Merge two motionblur layers into the first
function pman.mblur:MergeLayers( tbl1, tbl2, mul )

	mul = mul or 1
	tbl1.addalpha 	= tbl1.addalpha + ( tbl2.addalpha - self.ADDALPHA ) * mul
	tbl1.drawalpha 	= tbl1.drawalpha + ( tbl2.drawalpha - self.DRAWALPHA ) * mul
	tbl1.delay 		= tbl1.delay + ( tbl2.delay - self.DELAY ) * mul
		
end

-- Merge two bloom layers into the first
function pman.bloom:MergeLayers( tbl1, tbl2, mul )

	mul = mul or 1
	tbl1.multiply 	= tbl1.multiply + ( tbl2.multiply - self.MULTIPLY ) * mul
	tbl1.darken 	= tbl1.darken + ( tbl2.darken - self.DARKEN ) * mul
	tbl1.sizex 		= tbl1.sizex + ( tbl2.sizex - self.SIZEX ) * mul
	tbl1.sizey 		= tbl1.sizey + ( tbl2.sizey - self.SIZEY ) * mul
	tbl1.color 		= tbl1.color + ( tbl2.color - self.COLOR ) * mul
	tbl1.colr 		= tbl1.colr + ( tbl2.colr - self.COLR ) * mul
	tbl1.colg 		= tbl1.colg + ( tbl2.colg - self.COLG ) * mul
	tbl1.colb 		= tbl1.colb + ( tbl2.colb - self.COLB ) * mul
	if ( tbl2.passes > tbl1.passes ) then
	    tbl1.passes = tbl2.passes
	end

end



-- Add a color layer to postman
function pman.color:AddLayer( name, tbl )

	if ( !name || name == "" ) then return end
	if ( !tbl ) then return end

	self.layers[name] = tbl
	self:UpdateLayers()
		
end

-- Add a sharpen layer to postman
pman.sharp.AddLayer = pman.color.AddLayer

-- Add a mblur layer to postman
pman.mblur.AddLayer = pman.color.AddLayer

-- Add a bloom layer to postman
pman.bloom.AddLayer = pman.color.AddLayer

-- Add an overlay to postman
function pman.ovrly:AddLayer( name, tbl )

	if ( !name || name == "" ) then return end
	if ( !tbl ) then return end

    tbl.mat = Material( tbl.material )
	tbl.mat:SetFloat("$envmap",	0)
	tbl.mat:SetFloat("$envmaptint",	0)
	tbl.mat:SetInt("$ignorez", 1)
	tbl.mat:SetFloat("$refractamount", tbl.refract)
	tbl.mat:SetFloat("$alpha", tbl.alpha)
	tbl.mat:SetFloat("$bluramount", tbl.blur)

    self.layers[name] = tbl
	self:UpdateLayers()
		
end



-- Remove a color layer
function pman.color:RemoveLayer( name )

	if ( !name || name == "" ) then return end
	
	self.layers[name] = nil
	self:UpdateLayers()
	
end

-- remove a sharpen layer
pman.sharp.RemoveLayer = pman.color.RemoveLayer

-- remove a mblur layer
pman.mblur.RemoveLayer = pman.color.RemoveLayer

-- remove a bloom layer
pman.bloom.RemoveLayer = pman.color.RemoveLayer

-- remove an overlay
pman.ovrly.RemoveLayer = pman.color.RemoveLayer



-- Update color layers
function pman.color:UpdateLayers()

 	self.merged = self:NewLayer()

	if ( table.Count( self.layers ) < 1 ) then
		self.gotlayers = false
		if ( !self.gotfades ) then
			self.active = false
		end
		return
	end
	
	for i, x in pairs( self.layers ) do
		self:MergeLayers( self.merged, x )
	end

    self.gotlayers = true
	self.active = true

end

-- Update sharpen layers
pman.sharp.UpdateLayers = pman.color.UpdateLayers

-- Update motionblur layers
pman.mblur.UpdateLayers = pman.color.UpdateLayers

-- Update bloom layers
pman.bloom.UpdateLayers = pman.color.UpdateLayers

-- Update overlays
function pman.ovrly:UpdateLayers()

	if ( table.Count( self.layers ) < 1 ) then
		self.gotlayers = false
		if ( !self.gotfades ) then
			self.active = false
		end
	else
	    self.gotlayers = true
		self.active = true
	end
	
end



-- Add a color layer by fading it in
function pman.color:FadeIn( name, tbl, delay )

	local fade = {}

	fade.layer = tbl
	fade.value = 0
	fade.delay = delay
	fade.fadein = true
	
	self.fades[name] = fade
	self:UpdateFades()

end

-- Add a sharpen layer by fading it in
pman.sharp.FadeIn = pman.color.FadeIn

-- Add a mblur layer by fading it in
pman.mblur.FadeIn = pman.color.FadeIn

-- Add a bloom layer by fading it in
pman.bloom.FadeIn = pman.color.FadeIn

-- Add an overlay by fading it in
function pman.ovrly:FadeIn( name, tbl, delay )

	if ( !name || name == "" ) then return end
	
	tbl.mat = Material( tbl.material )
	tbl.mat:SetFloat( "$envmap", 0 )
	tbl.mat:SetFloat( "$envmaptint", 0 )
	tbl.mat:SetInt( "$ignorez",	1 )
	
	local fade = {}
	fade.layer = tbl
	fade.value = 0
	fade.delay = delay
	fade.fadein = true
	
	self.fades[name] = fade
	self:UpdateFades()

end



-- Remove a color layer by fading it out
function pman.color:FadeOut( name, delay )

	if ( !name || name == "" ) then return end
	if ( !self.layers[name] ) then return end
	
	local fade = {}
	fade.layer = self.layers[name]
	fade.value = 1
	fade.delay = delay
	fade.fadein = false
	
	self:RemoveLayer( name )
	
    self.fades[name] = fade
	self:UpdateFades()

end

-- Remove a sharpen layer by fading it out
pman.sharp.FadeOut = pman.color.FadeOut

-- Remove a mblur layer by fading it out
pman.mblur.FadeOut = pman.color.FadeOut

-- Remove a bloom layer by fading it out
pman.bloom.FadeOut = pman.color.FadeOut

-- Remove an overlay by fading it out
pman.ovrly.FadeOut = pman.color.FadeOut



-- remove a color fade from postman
function pman.color:RemoveFade( name )

	if ( !name || name == "" ) then return end
	
	self.fades[name] = nil
	self:UpdateFades()
	
end

-- remove a sharpen layer
pman.sharp.RemoveFade = pman.color.RemoveFade

-- remove a mblur layer
pman.mblur.RemoveFade = pman.color.RemoveFade

-- remove a bloom layer
pman.bloom.RemoveFade = pman.color.RemoveFade

-- remove an overlay
pman.ovrly.RemoveFade = pman.color.RemoveFade



-- Update color fades
function pman.color:UpdateFades()

	if ( table.Count( self.fades ) < 1 ) then
		self.gotfades = false
		if ( !self.gotlayers ) then
			self.active = false
		end
		return
	end
	
	self.gotfades = true
    self.active = true

end

-- Update sharpen fades
pman.sharp.UpdateFades = pman.color.UpdateFades

-- Update motionblur fades
pman.mblur.UpdateFades = pman.color.UpdateFades

-- Update bloom fades
pman.bloom.UpdateFades = pman.color.UpdateFades

-- Update overlay fades
pman.ovrly.UpdateFades = pman.color.UpdateFades



-- Force a color fade to instantly reach its destination
-- Works for both fade-in and fade-out
function pman.color:ForceFade( name )

	if ( !name || name == "" ) then return end
	if ( !self.fades[name] ) then return end
	
	if ( self.fades[name].fadein ) then
		self:AddLayer( name, self.fades[name].layer )
	end
	self:RemoveFade( name )

end

-- Force a sharp fade to instantly reach its destination
pman.sharp.ForceFade = pman.color.ForceFade

-- Force a mblur fade to instantly reach its destination
pman.mblur.ForceFade = pman.color.ForceFade

-- Force a bloom fade to instantly reach its destination
pman.bloom.ForceFade = pman.color.ForceFade

-- Force an overlay fade to instantly reach its destination
pman.ovrly.ForceFade = pman.color.ForceFade



-- Process color fades for a frame
function pman.color:ProcessFades( tbl, diff )

	for i, x in pairs( self.fades ) do
		if ( x.fadein ) then
			x.value = x.value + ( diff / x.delay )
			if ( x.value > 1 ) then
				self:MergeLayers( tbl, x.layer )
				self:AddLayer( i, x.layer )
				self:RemoveFade( i )
			else
				self:MergeLayers( tbl, x.layer, x.value )
			end
		else
			x.value = x.value - ( diff / x.delay )
			if ( x.value < 0 ) then
				self:RemoveFade( i )
			else
				self:MergeLayers( tbl, x.layer, x.value )
			end
		end
	end

end

-- Process sharpen fades
pman.sharp.ProcessFades = pman.color.ProcessFades

-- Process motionblur fades
pman.mblur.ProcessFades = pman.color.ProcessFades

-- Process bloom fades
pman.bloom.ProcessFades = pman.color.ProcessFades

-- Process overlay fades for a frame
function pman.ovrly:ProcessFades( diff )

	for i, x in pairs( self.fades ) do
		if ( x.fadein ) then
			x.value = x.value + ( diff / x.delay )
			if ( x.value > 1 ) then
				self:AddLayer( i, x.layer )
				self:RemoveFade( i )
			end
		else
			x.value = x.value - ( diff / x.delay )
			if ( x.value < 0 ) then
				self:RemoveFade( i )
			end
		end
	end

end



-- Update pman effects
function pmanThink()

	local time = CurTime()
	local diff = time - pman.lastthink
	
	if ( diff > pman.framerate ) then
		pman.lastthink = time
		
		-- process color modifications
		if ( pman.color.active ) then

			local color = pman.color
			local tempcolor = color:NewLayer()
			local translated = color.translated
		    
			if ( color.gotlayers ) then
		    	color:MergeLayers( tempcolor, color.merged )
		    end
		    
			if ( color.gotfades ) then
    			color:ProcessFades( tempcolor, diff )
			end			
	
			translated[ "$pp_colour_addr" ] 		= tempcolor.addr
			translated[ "$pp_colour_addg" ] 		= tempcolor.addg
			translated[ "$pp_colour_addb" ] 		= tempcolor.addb
			translated[ "$pp_colour_brightness" ] 	= tempcolor.brightness
			translated[ "$pp_colour_contrast" ] 	= tempcolor.contrast
			translated[ "$pp_colour_colour" ] 		= tempcolor.color
			translated[ "$pp_colour_mulr" ] 		= tempcolor.mulr
			translated[ "$pp_colour_mulg" ] 		= tempcolor.mulg
			translated[ "$pp_colour_mulb" ] 		= tempcolor.mulb
			
			color.final = tempcolor
			
		end
		
		-- process sharpen
		if ( pman.sharp.active ) then

			local sharp = pman.sharp
			local tempsharp = sharp:NewLayer()

            if ( sharp.gotlayers ) then
		    	sharp:MergeLayers( tempsharp, sharp.merged )
			end
			
			if ( sharp.gotfades ) then
				sharp:ProcessFades( tempsharp, diff )
			end			

			sharp.final = tempsharp

		end
		
		-- process motion blur
		if ( pman.mblur.active ) then

			local mblur = pman.mblur
			local tempmblur = mblur:NewLayer()
		    
		    if ( mblur.gotlayers ) then
		    	mblur:MergeLayers( tempmblur, mblur.merged )
			end
			
			if ( mblur.gotfades ) then
				mblur:ProcessFades( tempmblur, diff )
			end			
			
			tempmblur.addalpha = math.Clamp( tempmblur.addalpha, 0.015, 1 )
			tempmblur.drawalpha = math.Clamp( tempmblur.drawalpha, 0.015, 1 )
			tempmblur.delay = math.Clamp( tempmblur.delay, 0, 1 )
			
			pman.mblur.final = tempmblur
			
		end

		-- process bloom
		if ( pman.bloom.active ) then

			local bloom = pman.bloom
			local tempbloom = bloom:NewLayer()

            if ( bloom.gotlayers ) then
				bloom:MergeLayers( tempbloom, bloom.merged )
			end
			
			if ( bloom.gotfades ) then
				bloom:ProcessFades( tempbloom, diff )
			end

			tempbloom.passes = math.Clamp( tempbloom.passes, 0, 30 )

			bloom.final = tempbloom

		end
		
		-- process overlays
		if ( pman.ovrly.active ) then

			if ( pman.ovrly.gotfades ) then
				pman.ovrly:ProcessFades( diff )
			end

		end

	end

end
hook.Add( "Think", "pmanThink", pmanThink )        



-- Render postman effects
local function pmanRender()

	local mblur = pman.mblur
	local final = mblur.final
	if ( mblur.active && final ) then
		DrawMotionBlur( final.addalpha,
						final.drawalpha,
						final.delay )
	end

	local ovrly = pman.ovrly
	if ( ovrly.active ) then
		if ( ovrly.gotlayers ) then
			for i, x in pairs( ovrly.layers ) do
	        	if ( x.mat ) then
					render.UpdateScreenEffectTexture()
					render.SetMaterial( x.mat )
					render.DrawScreenQuad()
				end	
			end
		end
		if ( ovrly.gotfades ) then
			for i, x in pairs( ovrly.fades ) do
	        	if ( x.layer.mat ) then
	        	    local layer = x.layer
	        	    local mat = layer.mat
	        		mat:SetFloat("$refractamount", layer.refract * x.value )
					mat:SetFloat("$alpha", layer.alpha * x.value )
					mat:SetFloat("$bluramount", layer.blur * x.value )
					render.UpdateScreenEffectTexture()
					render.SetMaterial( mat )
					render.DrawScreenQuad()
				end	
			end
		end
	end
		                                              
	local color = pman.color
	if ( color.active ) then
		DrawColorModify( color.translated )
	end	

	local sharp = pman.sharp
	final = sharp.final
	if ( sharp.active && final ) then
		DrawSharpen( final.contrast,
					 final.distance )
	end                                          
	
	local bloom = pman.bloom
	final = bloom.final
	if ( bloom.active && final ) then
		DrawBloom( final.darken,
				   final.multiply,
				   final.sizex,
				   final.sizey,
				   final.passes,
				   final.color,
				   final.colr,
				   final.colg,
				   final.colb )
	end

end
hook.Add( "RenderScreenspaceEffects", "pmanRender", pmanRender )




