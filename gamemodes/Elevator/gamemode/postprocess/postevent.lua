--[[
 	Post-Processing Event Handlers

	by PackRat ( packrat (at) plebsquad (dot) com )

	Version 1.0, 19th Feb 2007

	Because PostMan is entirely clientside, 
	the server does not have direct access 
	to the postman library. Post Events 
	allow preset post-processing effects
	to be created and triggered by the 
	server, similar to util.Effect.
]]--



function PostEvent( ply, name, mul, time )
  
	if ( !ply || !ply:IsValid() ) then return end
	if ( !name || name == "" ) then return end
 	if ( !umsg ) then return end -- Wierd that this happens sometimes...
 	
 	mul = mul or 1
 	time = time or 0
 	
	umsg.Start( "postevent", ply )
		umsg.String( name )
		umsg.Float( mul )
		umsg.Float( time )
	umsg.End()

end
