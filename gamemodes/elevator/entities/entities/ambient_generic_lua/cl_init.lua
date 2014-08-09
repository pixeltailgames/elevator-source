usermessage.Hook( "ambient_generic_lua_play", function( um )

	// Gather networked data
	local entid = um:ReadChar()
	local soundfile = um:ReadString()
	local volume = um:ReadChar()
	local emit = um:ReadBool()

	// CreateSound
	if ( !emit ) then

		// Create list of ambients
		if ( !LocalPlayer().Ambients ) then
			LocalPlayer().Ambients = {}
		end

		// Only create if needed
		if ( !LocalPlayer().Ambients[ entid ] ) then
			LocalPlayer().Ambients[ entid ] = CreateSound( LocalPlayer(), soundfile )
		end

		LocalPlayer().Ambients[ entid ]:PlayEx( volume, 100 )

	else // Standard emit
	
		self:EmitSound( soundfile, volume * 100 )

	end

end )

usermessage.Hook( "ambient_generic_lua_stop", function( um )

	// Gather networked data
	local entid = um:ReadChar()
	local fade = um:ReadBool()
	local fadetime = um:ReadChar()

	if ( !LocalPlayer().Ambients || !LocalPlayer().Ambients[ entid ] ) then return end // sound isnt there
	
	if ( fade ) then
		LocalPlayer().Ambients[ entid ]:FadeOut( fadetime )
	else
		LocalPlayer().Ambients[ entid ]:StopSound()
	end

	table.remove( LocalPlayer().Ambients, entid )

end )

usermessage.Hook( "ambient_generic_lua_update", function( um )

	// Gather networked data
	local entid = um:ReadChar()
	local volume = um:ReadChar()

	if ( !LocalPlayer().Ambients || !LocalPlayer().Ambients[ entid ] ) then return end // sound isnt there

	LocalPlayer().Ambients[ entid ]:ChangeVolume( volume )

end )